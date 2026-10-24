package Langertha::Skeid::Proxy::Realtime;
our $VERSION = '0.004';
# ABSTRACT: One realtime session -- two WebSockets joined, bounded, ended once
use Moo;
use Scalar::Util qw( weaken );
use Time::HiRes qw( time );
use Mojo::IOLoop;
use Encode ();
use Mojo::Util qw( encode );
use Langertha::Skeid::Protocol::Realtime;
use namespace::clean;


has skeid => (is => 'ro', required => 1);
has log   => (is => 'ro');

# The sessions that are open, by id, so a shutdown can close them.
has sessions => (is => 'ro', default => sub { {} });

# The process whose event loop the shutdown listener is registered on: a forked worker has its
# own loop and must register again.
has _watching => (is => 'rw');
has _seq      => (is => 'rw', default => sub { 0 });

sub protocol { return 'Langertha::Skeid::Protocol::Realtime' }


sub start_session {
  my ($self, %a) = @_;
  my $limits = $a{limits};
  my $id = $self->_seq + 1;
  $self->_seq($id);
  my $s = {
    %a,
    id      => $id,
    queued  => { up => 0, down => 0 },
    last    => time,
    ended   => 0,
    count   => 0,
  };
  $self->sessions->{ $s->{id} } = $s;
  $self->_watch_shutdown;

  weaken(my $weak = $self);
  my ($client, $up) = @a{qw( client upstream )};

  # The transaction's own message limit, per session, both ways; and the connections' own idle
  # timeouts as a backstop a little behind the timer that closes with a reason.
  $_->max_websocket_size($limits->{max_message_bytes}) for $client, $up;
  for my $tx ($client, $up) {
    my $stream = Mojo::IOLoop->stream($tx->connection // '') or next;
    $stream->timeout($limits->{idle_timeout} + 5);
  }

  $client->on(text => sub {
    my (undef, $bytes) = @_;
    $weak->_from_client($s, $bytes) if $weak;
  });
  $client->on(binary => sub {
    $weak->_end($s, code => 1003, reason => 'binary frames are not supported',
      ok => 0, status_code => 400, rejected => 1, error_type => 'invalid_request_error',
      error_message => 'A binary frame was sent on a realtime session') if $weak;
  });
  $client->on(finish => sub {
    my (undef, $code, $reason) = @_;
    $weak->_peer_closed($s, 'client', $code, $reason) if $weak;
  });

  $up->on(text => sub {
    my (undef, $bytes) = @_;
    $weak->_from_upstream($s, $bytes) if $weak;
  });
  $up->on(binary => sub {
    my (undef, $bytes) = @_;
    return unless $weak;
    $s->{last} = time;
    $weak->_send($s, 'down', { binary => $bytes }, length $bytes) unless $s->{ended};
  });
  $up->on(finish => sub {
    my (undef, $code, $reason) = @_;
    $weak->_peer_closed($s, 'upstream', $code, $reason) if $weak;
  });

  $s->{idle_timer} = Mojo::IOLoop->timer($limits->{idle_timeout} => sub { $weak->_idle($s) if $weak });
  $s->{life_timer} = Mojo::IOLoop->timer($limits->{max_session_seconds} => sub {
    $weak->_end($s, code => 1000, reason => 'session time limit') if $weak;
  });
  return $s->{id};
}


sub open_count { return scalar keys %{ $_[0]->sessions } }

sub shutdown {
  my ($self) = @_;
  $self->_end($_, code => 1001, reason => 'server shutdown') for values %{ $self->sessions };
  return;
}

sub _watch_shutdown {
  my ($self) = @_;
  return if ($self->_watching // 0) == $$;
  $self->_watching($$);
  weaken(my $weak = $self);
  Mojo::IOLoop->singleton->on(finish => sub { $weak->shutdown if $weak });
  return;
}

sub _from_client {
  my ($self, $s, $bytes) = @_;
  return if $s->{ended};
  $s->{last} = time;
  my $frame = $self->protocol->client_frame($bytes, $s->{requested_model}, $s->{served_model});
  if ($frame->{action} eq 'forward') {
    # The protocol module's text is encoded already (UTF-8 bytes).
    $self->_send($s, 'up', { text => $frame->{text} }, length $frame->{text});
  }
  elsif ($frame->{action} eq 'refuse') {
    $self->_send($s, 'down', { text => $frame->{text} }, length $frame->{text});
  }
  else {
    $self->_end($s, code => $frame->{code}, reason => $frame->{reason},
      ok => 0, status_code => 400, rejected => 1, error_type => 'invalid_request_error',
      error_message => 'A frame of a realtime session was not a JSON object');
  }
  return;
}

sub _from_upstream {
  my ($self, $s, $bytes) = @_;
  return if $s->{ended};
  $s->{last} = time;
  my $info = $self->protocol->server_frame($bytes);
  if ($info->{usage}) {
    $s->{usage} = $self->protocol->add_usage($s->{usage}, $info->{usage});
    my $seconds = $self->protocol->seconds($info->{usage});
    $s->{seconds} = ($s->{seconds} // 0) + $seconds if defined $seconds;
    $s->{count}++;
  }
  if (defined $info->{delta_text}) {
    $s->{content_bytes} = ($s->{content_bytes} // 0) + length encode('UTF-8', $info->{delta_text});
  }
  $s->{error_seen} = 1 if $info->{error};
  $self->_send($s, 'down', { text => $bytes }, length $bytes);
  return;
}

# One frame towards a peer. The bytes are counted until the transaction has written them out
# (its drain event), so a peer that does not read is a number, not a leak.
sub _send {
  my ($self, $s, $direction, $frame, $length) = @_;
  return if $s->{ended};
  my $max = $s->{limits}{max_queued_bytes};
  if ($s->{queued}{$direction} + $length > $max) {
    $self->_end($s, code => 1013, reason => 'try again later',
      ok => 0, status_code => 503, error_type => 'realtime_queue_overflow',
      error_message => 'A peer of the realtime session did not read what was sent to it');
    return;
  }
  $s->{queued}{$direction} += $length;
  my $tx = $direction eq 'up' ? $s->{upstream} : $s->{client};
  return unless $tx;
  $tx->send($frame => sub { $s->{queued}{$direction} -= $length });
  return;
}

sub _idle {
  my ($self, $s) = @_;
  return if $s->{ended};
  my $left = $s->{last} + $s->{limits}{idle_timeout} - time;
  if ($left > 0.001) {
    weaken(my $weak = $self);
    $s->{idle_timer} = Mojo::IOLoop->timer($left => sub { $weak->_idle($s) if $weak });
    return;
  }
  $self->_end($s, code => 1000, reason => 'idle timeout');
  return;
}

# A close code that may be put on the wire (RFC 6455, 7.4): 1005, 1006 and 1015 may not.
sub _sendable {
  my ($code) = @_;
  return 0 unless defined $code;
  return ($code >= 1000 && $code <= 1003) || ($code >= 1007 && $code <= 1014)
    || ($code >= 3000 && $code <= 4999) ? 1 : 0;
}

sub _peer_closed {
  my ($self, $s, $who, $code, $reason) = @_;
  return if $s->{ended};
  my $vanished = !defined($code) || $code == 1006 || $code == 1015;
  my $send = _sendable($code) ? $code : 1000;

  if ($who eq 'client') {
    # A client that left without a close frame abandoned the session (the usage event says so,
    # as it does for a request); one that closed it properly is not a failure, whatever the code.
    return $self->_end($s, code => 1000, reason => 'client went away',
      ok => 0, aborted => 1, status_code => 499, error_type => 'client_abort',
      error_message => 'Client closed the connection without closing the session')
      if $vanished;
    # 1009: a message above realtime.max_message_bytes -- the transaction closed the session
    # itself, the client sent more than it may.
    return $self->_end($s, code => 1009, reason => 'message too big',
      ok => 0, rejected => 1, status_code => 413, error_type => 'invalid_request_error',
      error_message => 'A message of the realtime session was larger than the limit')
      if $code == 1009;
    return $self->_end($s, code => $send, reason => $reason);
  }

  # The node sent a message above the limit (the transaction closed the session itself): the
  # client did nothing wrong and is told the node failed, not that its own message was big.
  return $self->_end($s, code => 1011, reason => 'upstream message too big',
    ok => 0, status_code => 502, error_type => 'upstream_error',
    error_message => 'The node sent a message larger than realtime.max_message_bytes')
    if $code == 1009;
  return $self->_end($s, code => 1011, reason => 'upstream connection lost',
    ok => 0, status_code => 502, error_type => 'upstream_error',
    error_message => 'The node closed the realtime connection without closing the session')
    if $vanished;
  return $self->_end($s, code => $send, reason => $reason,
    ok => 0, status_code => 502, error_type => 'upstream_error',
    error_message => 'The node sent an error and closed the realtime session')
    if $s->{error_seen} || $send != 1000 && $send != 1001;
  return $self->_end($s, code => $send, reason => $reason);
}

# The one end of a session. Whatever called it, the finish callback runs first and exactly once;
# then the sides still open are closed with the code and reason given.
sub _end {
  my ($self, $s, %o) = @_;
  return if $s->{ended}++;
  Mojo::IOLoop->remove($_) for grep { defined } delete @{$s}{qw( idle_timer life_timer )};
  delete $self->sessions->{ $s->{id} };

  my $ok = exists $o{ok} ? $o{ok} : 1;
  my $result = {
    ok            => $ok ? 1 : 0,
    status_code   => $o{status_code} // 200,
    error_type    => $o{error_type} // '',
    error_message => $o{error_message} // '',
    aborted       => $o{aborted} ? 1 : 0,
    rejected      => $o{rejected} ? 1 : 0,
    duration_ms   => int((time - $s->{started}) * 1000),
    usage         => $s->{usage},
    transcriptions => $s->{count},
    (defined $s->{seconds}       ? (audio_seconds => $s->{seconds}) : ()),
    (defined $s->{content_bytes} ? (content_bytes => $s->{content_bytes}) : ()),
  };
  my $done = eval { $s->{finish}->($result); 1 };
  unless ($done) {
    my $err = $@ || 'unknown error';
    $err =~ s/\s+\z//;
    $self->log->error('realtime session finish failed: ' . $err) if $self->log;
  }

  # A close reason travels in a control frame of at most 125 bytes, two of them the code.
  my $reason = $o{reason};
  if (defined $reason) {
    my $bytes = substr(encode('UTF-8', $reason), 0, 120);
    $reason = Encode::decode('UTF-8', $bytes, Encode::FB_QUIET);
  }
  my ($client, $up) = delete @{$s}{qw( client upstream )};
  for my $tx (grep { defined } $client, $up) {
    next if $tx->is_finished;
    $tx->finish($o{code} // 1000, $reason);
  }
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid::Proxy::Realtime - One realtime session -- two WebSockets joined, bounded, ended once

=head1 VERSION

version 0.004

=head1 DESCRIPTION

The relay of the realtime route (skeid k95, ADR 0029). C<Langertha::Skeid::Proxy> answers the
handshake -- the client gate, the model, routing, admission, the node's key, the upstream
WebSocket, the upgrade -- and then hands both open WebSockets to L</start_session>. From there a
B<session> is two transactions, the client's and the node's, and this module is everything that
happens until one of them ends:

=over 4

=item * Text frames go across both ways in order. The client's are decoded and checked first
(L<Langertha::Skeid::Protocol::Realtime/client_frame>: a model the key was not granted is
refused with an C<error> event, the session's own is rewritten to the served one); the node's are
read for usage and relayed as the bytes they came in. A binary frame from the client closes the
session C<1003>, like a frame that is no JSON object.

=item * Nothing grows without bound. A message above C<realtime.max_message_bytes> closes the
session C<1009> (the transaction's own limit, set per session); bytes written to a peer that has
not taken them yet are counted per direction, and past C<realtime.max_queued_bytes> the session
closes C<1013>. A session silent for C<realtime.idle_timeout> seconds and one older than
C<realtime.max_session_seconds> are closed C<1000>, by timers (ADR 0005).

=item * It ends once. Whichever side closes first, or a limit, the one finish callback runs --
C<request.finish>, the usage event -- and then the other side is closed with the mapped code.
Codes that cannot travel on the wire (C<1005>, C<1006>, C<1015>) are mapped: a client that went
away closes the node with C<1000>, a node that died closes the client with C<1011>.

=item * A graceful stop of the process (the event loop's C<finish> event, which the prefork
worker emits on C<SIGQUIT>) closes every open session C<1001> first, so its finish callback and
its usage event run before the worker exits.

=back

The module does I/O only through the two transactions and L<Mojo::IOLoop> timers, and knows no
routing and no usage store: the finish callback is the proxy's.

=head2 start_session

  my $session = $realtime->start_session(
    client          => $c->tx,            # established server WebSocket transaction
    upstream        => $up_tx,            # established client WebSocket transaction to the node
    requested_model => 'house-asr',
    served_model    => 'whisper-large',
    started         => time,              # when the handshake began
    limits          => { idle_timeout => 300, max_session_seconds => 3600,
                         max_message_bytes => 1048576, max_queued_bytes => 4194304 },
    finish          => sub { my ($result) = @_; ... },
  );

Starts the relay. C<finish> is called exactly once, with a hashref: C<ok>, C<status_code>,
C<error_type>, C<error_message> (empty for a session that ended well), C<aborted> and C<rejected>
(for C<request.finish>), C<duration_ms>, C<usage> (the summed usage blocks, or C<undef>),
C<audio_seconds> and C<content_bytes> (absent when nothing measured them) and C<transcriptions>.
Returns the number of the session.

=head2 open_count

How many sessions are open.

=head2 shutdown

  $realtime->shutdown;

Closes every open session C<1001> ("going away"); their finish callbacks run first. Called from
the event loop's C<finish> event.

=head1 SEE ALSO

L<Langertha::Skeid::Proxy/Realtime route>, L<Langertha::Skeid::Protocol::Realtime>

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
