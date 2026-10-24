package Langertha::Skeid::Protocol::Audio;
our $VERSION = '0.004';
# ABSTRACT: The OpenAI audio routes -- the upload form relayed, the answer's usage read
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);


# The client's path and the path below the node URL it is relayed to.
my %UPSTREAM_PATH = (
  '/v1/audio/transcriptions' => '/audio/transcriptions',
  '/v1/audio/translations'   => '/audio/translations',
);

# A form field Skeid reads itself -- model, stream -- is a short token. A longer one is not read
# into memory to find that out.
my $FIELD_MAX = 1024;

# What a boolean form field has to say to be on. A form has no booleans, only strings, and the
# nodes behind these routes read theirs through pydantic, which takes exactly these for true, in
# any case.
my %FORM_TRUE = map { $_ => 1 } qw(1 true on yes t y);


sub routes { return sort keys %UPSTREAM_PATH }


sub upstream_path {
  my ($class, $route) = @_;
  return $UPSTREAM_PATH{$route // ''};
}


sub form_fields {
  my ($class, $content) = @_;
  my %field;
  my $parts = $content->parts;
  for my $index (0 .. $#$parts) {
    my $part = $parts->[$index];
    return ({}, 'Nested multipart parts are not supported') if $part->is_multipart;
    my $disposition = $part->headers->content_disposition // next;
    my ($names, $is_file, $extended) = $class->disposition_names($disposition);
    return ({}, 'A form field name in the extended notation (name*) is not supported')
      if $extended;
    next if $is_file;
    my ($name) = grep { $_ eq 'model' || $_ eq 'stream' } @$names;
    next unless defined $name;
    my $asset = $part->asset;
    push @{$field{$name}}, {
      index => $index,
      value => ($asset->size > $FIELD_MAX ? undef : $asset->slurp),
    };
  }
  return (\%field, undef);
}


sub disposition_names {
  my ($class, $disposition) = @_;
  my (@names, $is_file, $extended);
  while ($disposition =~ /(?:\A|[;,])\s*([^\s=;,"]+)\s*=\s*(?:"((?:\\.|[^"\\])*)"|([^;,\s]*))/g) {
    my ($key, $value) = (lc($1), $2 // $3);
    if ($key eq 'name') {
      $value =~ s/\\(.)/$1/gs;
      push @names, $value;
    }
    $extended = 1 if $key =~ /\Aname\*/;
    $is_file  = 1 if $key =~ /\Afilename(?:\*|\z)/;
  }
  return (\@names, $is_file, $extended);
}


sub is_true {
  my ($class, $value) = @_;
  return $FORM_TRUE{lc($value // '')} ? 1 : 0;
}


sub upstream_parts {
  my ($class, $content, $replace) = @_;
  $replace ||= {};
  my $source = $content->parts;
  my @parts;
  for my $index (0 .. $#$source) {
    my $part = $source->[$index];
    my %headers = %{$part->headers->to_hash};
    if (exists $replace->{$index}) {
      delete @headers{ grep { lc($_) eq 'content-length' } keys %headers };
      push @parts, { %headers, content => $replace->{$index} };
      next;
    }
    push @parts, { %headers, file => $part->asset };
  }
  return \@parts;
}


sub usage_units {
  my ($class, $payload) = @_;
  return () unless ref($payload) eq 'HASH';
  my $usage = $payload->{usage};
  my $seconds = (ref($usage) eq 'HASH' && ($usage->{type} // '') eq 'duration')
    ? $usage->{seconds}
    : undef;
  $seconds = $payload->{duration} unless $class->_is_measure($seconds);
  return () unless $class->_is_measure($seconds);
  return (audio_seconds => 0 + $seconds);
}

# A finite number that is not negative: what a count or a duration off the wire has to be.
sub _is_measure {
  my ($class, $value) = @_;
  return 0 unless defined($value) && !ref($value) && looks_like_number($value);
  return ($value >= 0 && $value == $value && $value != 9**9**9) ? 1 : 0;
}


sub delta_text {
  my ($class, $frame) = @_;
  return unless ref($frame) eq 'HASH' && ($frame->{type} // '') eq 'transcript.text.delta';
  my $text = $frame->{delta};
  return unless defined($text) && !ref($text);
  return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Protocol::Audio - The OpenAI audio routes -- the upload form relayed, the answer's usage read

=head1 VERSION

version 0.004

=head1 DESCRIPTION

Serves C<POST /v1/audio/transcriptions> and C<POST /v1/audio/translations>, the audio routes of
the OpenAI face. They are B<relayed routes> (ADR 0021): there is one dialect for the request, a
C<multipart/form-data> upload, and the node's answer goes back as it came, so this module
translates nothing. It holds what Skeid has to know about that wire all the same, and it is the
only place that knows it: which form fields Skeid reads, how the upstream form is put together
from the parts the server parsed, and where an answer -- JSON or one frame of an event stream --
says what it cost.

The nodes behind these routes are vLLM (Whisper) and speaches (faster-whisper), which both
serve OpenAI's endpoints; what differs is the answer. vLLM's JSON carries
C<< usage => { type => 'duration', seconds => N } >>, its stream is C<transcription.chunk>
frames in the chat stream's shape, ending in C<[DONE]>. speaches' JSON carries no usage, its
stream is OpenAI's own C<transcript.text.delta> / C<transcript.text.done> events and ends
without C<[DONE]>. A C<verbose_json> answer of either has a top-level C<duration>. OpenAI itself
reports C<< usage => { type => 'tokens', ... } >> or the C<duration> block, depending on the
model.

Everything here is a class method.

=head2 routes

  my @paths = Langertha::Skeid::Protocol::Audio->routes;

The client paths of the audio routes, sorted: C</v1/audio/transcriptions> and
C</v1/audio/translations>.

=head2 upstream_path

  my $path = Langertha::Skeid::Protocol::Audio->upstream_path('/v1/audio/translations');
  # '/audio/translations'

The path below a node's URL that a client path is relayed to, or C<undef> for a path that is
not an audio route.

=head2 form_fields

  my ($fields, $problem) = Langertha::Skeid::Protocol::Audio->form_fields($req->content);
  # $fields = { model => [ { index => 0, value => 'whisper' } ], stream => [ ... ] }

The form fields Skeid reads off an upload itself, C<model> and C<stream>, from a parsed
L<Mojo::Content::MultiPart>: per name the parts that carry it, in form order, each with its
C<index> in the form and its C<value> as raw bytes -- C<undef> for a value above 1024 bytes,
which is neither a model name nor a boolean and is not read into memory. A part with a file
name is a file, whatever it is called, and is not a field.

The parts are read directly rather than through the request's parameters, which would load
every other field (a long C<prompt>) into memory and know only a quoted name. A part's name is
taken from its C<Content-Disposition> as liberally as any form parser a node may run takes it:
the parameter name in any case, white space around the C<=>, the value quoted or bare, every
C<name> of a header that repeats it. The form is parsed twice, here and by the node, and the two
must not disagree about which part is the C<model> -- Skeid routes, and applies the key's
policy, by the one it sees (ADR 0008). Whatever a node could take for the model field counts as
one here.

C<$problem> is a reason to refuse the whole form, else C<undef>: a part that is itself a
multipart, which cannot be relayed as one asset, and a field name in the extended notation of
RFC 2231 / RFC 5987 (C<name*>), which RFC 7578 rules out for a form and Skeid would have to
guess at.

=head2 disposition_names

  my ($names, $is_file, $extended) =
    Langertha::Skeid::Protocol::Audio->disposition_names($part->headers->content_disposition);

What a part's C<Content-Disposition> says the part is: every value of its C<name> parameter, read
as liberally as L</form_fields> says, whether it has a file name, and whether a name is given in
the extended notation (C<name*>, C<name*0>). The documents routes read their form with it too.

=head2 is_true

  my $streamed = Langertha::Skeid::Protocol::Audio->is_true($value);

Whether a boolean form field is on. A form has only strings; the nodes read theirs through
pydantic, for which C<1>, C<true>, C<on>, C<yes>, C<t> and C<y> are true, in any case. Skeid has
to agree with the node about C<stream>: read as off here and on there, the event stream would be
held back until it is complete and its usage never read.

=head2 upstream_parts

  my $parts = Langertha::Skeid::Protocol::Audio->upstream_parts($req->content, { 0 => $bytes });
  my $tx    = $ua->build_tx(POST => $url, \%headers, multipart => $parts);

The parts of the upstream form, for the C<multipart> generator of
L<Mojo::UserAgent::Transactor>: every part of the client's form with its own headers and its
own asset, in the client's order -- unknown and repeated fields included. A part is its headers
and an asset, and an upload above 256 KiB is an asset on disk, so the file is sent from there
and never copied into memory. C<\%replace> maps a part's index to the bytes it carries instead
(the served model of an alias tier); that part keeps its headers but for a C<Content-Length>
that no longer holds. The boundary is not set here: the upstream request carries the client's
C<Content-Type>, and the body is written with the boundary that names.

=head2 usage_units

  my %units = Langertha::Skeid::Protocol::Audio->usage_units($payload);
  # ( audio_seconds => 12 ), or ()

The usage unit of the audio routes off a decoded answer -- or off a hash holding only the
C<usage> block a stream carried: the seconds of audio the node worked on, as the event field
C<audio_seconds>. C<< usage => { type => 'duration', seconds => N } >> is what vLLM and
OpenAI's C<whisper-1> answer with; a C<verbose_json> answer carries a top-level C<duration>
instead. With neither, the node did not say, and nothing is returned: the event then has no
C<audio_seconds> rather than a zero nobody measured. A value that is not a finite number of at
least zero counts as not said.

Token usage is not read here; it goes through C<metrics.normalize> like every other answer's.
This reads a number off an answer Skeid already holds and translates nothing.

=head2 delta_text

  my $text = Langertha::Skeid::Protocol::Audio->delta_text($frame);

The text of one decoded frame of a transcription stream in OpenAI's own event dialect, which
speaches speaks too -- C<< { type => 'transcript.text.delta', delta => '...' } >> -- or
C<undef> for any other frame. The relay counts it into C<content_bytes>. vLLM streams
chat-shaped chunks (C<choices[0].delta.content>) instead, which the relay counts already.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy/Audio routes>, L<Langertha::Skeid::Protocol>,
L<Langertha::Skeid/Pluggable Usage Storage>

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
