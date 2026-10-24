package Langertha::Skeid::Protocol::Realtime;
our $VERSION = '0.004';
# ABSTRACT: The OpenAI realtime route -- what a session's handshake and frames say, relayed untranslated
use strict;
use warnings;
use JSON::MaybeXS ();
use Mojo::URL;
use Scalar::Util qw( looks_like_number );


my $ROUTE         = '/v1/realtime';
my $UPSTREAM_PATH = '/realtime';
my $KEY_PREFIX    = 'openai-insecure-api-key.';
my $SUBPROTOCOL   = 'realtime';
my $MODEL_MAX     = 1024;

my $COMPLETED = 'conversation.item.input_audio_transcription.completed';
my $DELTA     = 'conversation.item.input_audio_transcription.delta';

# What Skeid decodes with, and what it encodes the frames it forwards with. Strict on duplicate
# keys where the decoder is: a document with two readings is not forwarded, because Skeid and
# the node could take different ones.
my $JSON = JSON::MaybeXS->new(utf8 => 1, canonical => 1, convert_blessed => 1);


sub route         { return $ROUTE }
sub upstream_path { return $UPSTREAM_PATH }


sub query_model {
  my ($class, $query) = @_;
  my @models = @{ $query->every_param('model') };
  return (undef, "The 'model' query parameter is required") unless @models;
  return (undef, "The 'model' query parameter may be given only once") if @models > 1;
  my $model = $models[0];
  return (undef, "The 'model' query parameter is empty or too long")
    unless defined($model) && length($model) && length($model) <= $MODEL_MAX;
  return ($model, undef);
}


sub upstream_url {
  my ($class, $endpoint, $served_model, $query) = @_;
  my $url = Mojo::URL->new($endpoint);
  my $scheme = lc($url->scheme // 'http');
  $url->scheme($scheme eq 'https' || $scheme eq 'wss' ? 'wss' : 'ws');
  my @pairs = ('model', $served_model);
  if ($query) {
    my $all = $query->pairs;
    for (my $i = 0; $i < @$all; $i += 2) {
      next if $all->[$i] eq 'model';
      push @pairs, $all->[$i], $all->[$i + 1];
    }
  }
  $url->query(\@pairs);
  return $url->to_string;
}


sub subprotocol_key {
  my ($class, $header) = @_;
  return unless defined($header) && length($header);
  for my $entry (split /,/, $header) {
    $entry =~ s/\A\s+//;
    $entry =~ s/\s+\z//;
    next unless index($entry, $KEY_PREFIX) == 0;
    my $key = substr($entry, length $KEY_PREFIX);
    return $key if length $key;
  }
  return;
}


sub subprotocol { return $SUBPROTOCOL }


sub client_frame {
  my ($class, $bytes, $requested, $served) = @_;
  my $data = eval { $JSON->decode($bytes) };
  return { action => 'close', code => 1003, reason => 'frames must be JSON objects' }
    unless ref($data) eq 'HASH';

  my ($rewritten, $foreign) = (0, 0);
  my $walk;
  $walk = sub {
    my ($node, $depth) = @_;
    return if $depth > 64;
    if (ref($node) eq 'HASH') {
      for my $key (keys %$node) {
        my $value = $node->{$key};
        if ($key eq 'model' && defined($value) && !ref($value)) {
          if ("$value" eq $requested) {
            if ($served ne $requested) {
              $node->{$key} = $served;
              $rewritten = 1;
            }
          }
          else { $foreign = 1 }
        }
        elsif (ref $value) { $walk->($value, $depth + 1) }
      }
    }
    elsif (ref($node) eq 'ARRAY') {
      ref($_) && $walk->($_, $depth + 1) for @$node;
    }
    return;
  };
  $walk->($data, 0);
  undef $walk;

  if ($foreign) {
    my $client_event = $data->{event_id};
    return {
      action => 'refuse',
      text   => $class->error_event(
        'invalid_request_error', 'model_not_allowed',
        "The model of a session cannot be changed; this session runs '$requested'",
        (defined($client_event) && !ref($client_event) ? $client_event : undef),
      ),
    };
  }
  return { action => 'forward', text => $JSON->encode($data), rewritten => $rewritten };
}


sub error_event {
  my ($class, $type, $code, $message, $client_event_id) = @_;
  return $JSON->encode({
    type     => 'error',
    event_id => 'event_skeid_' . join('', map { sprintf '%02x', int rand 256 } 1 .. 8),
    error    => {
      type    => $type,
      code    => $code,
      message => $message,
      param   => undef,
      event_id => $client_event_id,
    },
  });
}


sub server_frame {
  my ($class, $bytes) = @_;
  my $data = eval { $JSON->decode($bytes) };
  return { type => undef, usage => undef, delta_text => undef, error => 0 }
    unless ref($data) eq 'HASH';
  my $type = $data->{type};
  $type = undef if ref $type;
  my $usage = (defined($type) && $type eq $COMPLETED && ref($data->{usage}) eq 'HASH')
    ? $data->{usage} : undef;
  my $text = (defined($type) && $type eq $DELTA && defined($data->{delta}) && !ref($data->{delta}))
    ? $data->{delta} : undef;
  return {
    type       => $type,
    usage      => $usage,
    delta_text => $text,
    error      => (defined($type) && $type eq 'error') ? 1 : 0,
  };
}


sub add_usage {
  my ($class, $sum, $block) = @_;
  $sum = {} unless ref($sum) eq 'HASH';
  return $sum unless ref($block) eq 'HASH';
  for my $key (keys %$block) {
    my $value = $block->{$key};
    if (ref($value) eq 'HASH') {
      $sum->{$key} = $class->add_usage(ref($sum->{$key}) eq 'HASH' ? $sum->{$key} : {}, $value);
    }
    elsif (!ref($value) && defined($value) && looks_like_number($value)
      && $value == $value && $value != 9**9**9 && $value != -9**9**9) {
      $sum->{$key} = ($sum->{$key} // 0) + $value;
    }
    elsif (!ref($value) && defined($value) && !exists $sum->{$key}) {
      $sum->{$key} = $value;
    }
  }
  return $sum;
}


sub seconds {
  my ($class, $block) = @_;
  return unless ref($block) eq 'HASH' && ($block->{type} // '') eq 'duration';
  my $s = $block->{seconds};
  return unless defined($s) && !ref($s) && looks_like_number($s) && $s >= 0 && $s != 9**9**9
    && $s == $s;
  return 0 + $s;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Realtime - The OpenAI realtime route -- what a session's handshake and frames say, relayed untranslated

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Serves C<GET /v1/realtime>, the realtime route of the OpenAI face, used here for live
transcription. It is a B<relayed route> (ADR 0021, ADR 0029): a WebSocket the client keeps open
is joined to a WebSocket Skeid opens to the node's realtime endpoint, and the frames go across
as they are. This module translates nothing -- the beta dialect (C<transcription_session.update>)
and the GA dialect (C<session.update> with a C<transcription> session) are relayed as the client
speaks them -- and it is the only place that knows the wire: the query parameters, the
subprotocol that carries a browser's key, the event names, the places a client frame can name a
model, and where a server frame reports its usage.

It holds three things Skeid has to know all the same.

=over 4

=item * B<The model of the session.> A key's policy (ADR 0008) was applied to the model of the
handshake. A frame that names another model would switch the session to one the key was never
granted, so every client frame is decoded (never pre-filtered by substring: JSON spells the same
text many ways, and the node decodes the frame again -- ADR 0021's two-parsers hazard) and every
string C<model> in it is compared: the session's own model is rewritten to the served one, any
other is refused. What Skeid forwards is the document it inspected, encoded again, so Skeid and
the node read one thing.

=item * B<The key of a browser.> A page cannot set C<Authorization>; OpenAI's convention is a
subprotocol entry C<openai-insecure-api-key.E<lt>keyE<gt>> beside C<realtime>. It is read, and
never answered: the subprotocol Skeid selects is C<realtime> or none.

=item * B<Usage.> The C<usage> block of each
C<conversation.item.input_audio_transcription.completed> event is one transcription's. A
session's usage is their sum.

=back

Everything here is a class method.

=head2 route

  my $path = Langertha::Skeid::Protocol::Realtime->route;   # '/v1/realtime'

The client path of the realtime route.

=head2 upstream_path

The path below a node's URL it is relayed to, C</realtime>.

=head2 query_model

  my ($model, $problem) = Langertha::Skeid::Protocol::Realtime->query_model($c->req->url->query);

The C<model> of a handshake: exactly one non-empty C<model> query parameter of at most 1024
bytes. Otherwise C<undef> and a message for the client. C<intent=transcription> alone names no
model and is refused (ADR 0029): a slot is promised to a client that has said what it wants.

=head2 upstream_url

  my $url = Langertha::Skeid::Protocol::Realtime->upstream_url(
    'http://node:8000/v1/realtime', 'whisper-large', $c->req->url->query);
  # ws://node:8000/v1/realtime?model=whisper-large&intent=transcription

The WebSocket URL of the node's realtime endpoint: C<http> becomes C<ws>, C<https> C<wss>, the
C<model> is the one that was served, and every other query parameter of the client goes on as it
was sent.

=head2 subprotocol_key

  my $key = Langertha::Skeid::Protocol::Realtime->subprotocol_key($c->req->headers->sec_websocket_protocol);

The API key a browser put in the C<Sec-WebSocket-Protocol> header as
C<openai-insecure-api-key.E<lt>keyE<gt>>, or C<undef>. The first such entry counts.

=head2 subprotocol

The one subprotocol Skeid ever selects in its answer, C<realtime>. Never an entry that carries a
key.

=head2 client_frame

  my $frame = Langertha::Skeid::Protocol::Realtime->client_frame($bytes, $requested, $served);

What to do with one text frame of the client, given the model the session asked for and the one
it is served. C<$bytes> are the frame's raw bytes. The answer is a hashref with an C<action>:

=over 4

=item * C<forward> with C<text> -- the frame to send to the node, the decoded document encoded
again with the model rewritten to C<$served> where it named C<$requested>. C<rewritten> is true
when a model was changed.

=item * C<refuse> with C<text> -- an C<error> event for the client; the frame is not forwarded and
the session goes on, on the model it started with. A frame names another model.

=item * C<close> with C<code> and C<reason> -- a frame that is no JSON object (C<1003>).

=back

Every string C<model> anywhere in the document counts, whatever the event: the dialects keep it
in different places (C<session.model>, C<session.input_audio_transcription.model>,
C<session.audio.input.transcription.model>), and a place a node could read that Skeid does not is
a bypass. An C<input_audio_buffer.append> carries none; it is decoded like the rest, because
the decoding is what makes Skeid and the node read the same document.

=head2 error_event

  my $text = Langertha::Skeid::Protocol::Realtime->error_event($type, $code, $message, $client_event_id);

An C<error> server event as the realtime protocol shapes it, as JSON text.

=head2 server_frame

  my $info = Langertha::Skeid::Protocol::Realtime->server_frame($bytes);
  # { type => '...', usage => {...}|undef, delta_text => '...'|undef, error => 0|1 }

What Skeid reads off one text frame of the node, for metering: the C<usage> block of a
C<...input_audio_transcription.completed> event, the text of a C<...input_audio_transcription.delta>
event, and whether it is an C<error> event. A frame that does not decode is an empty answer; it
is relayed all the same, as the bytes it came in.

=head2 add_usage

  $sum = Langertha::Skeid::Protocol::Realtime->add_usage($sum, $block);

Adds the usage block of one completed transcription to a session's total, number by number
(nested blocks such as C<input_token_details> likewise). A value that is not a number is not
added: C<type> keeps the first one seen. Unlike the running totals of a stream
(C<_merge_usage>), each block is its own transcription's, so they are summed.

=head2 seconds

  my $seconds = Langertha::Skeid::Protocol::Realtime->seconds($block);

The seconds of audio a usage block reports -- C<< { type => 'duration', seconds => N } >> -- or
C<undef> when it does not say.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy/Realtime route>, L<Langertha::Skeid::Proxy::Realtime>,
L<Langertha::Skeid::Protocol::Audio>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
