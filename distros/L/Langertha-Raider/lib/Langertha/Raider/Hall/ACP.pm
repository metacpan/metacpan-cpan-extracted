package Langertha::Raider::Hall::ACP;
our $VERSION = '0.503';
# ABSTRACT: Internal ACP (Agent Client Protocol) adapter that exposes the hall over TCP

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use IO::Async::Listener;
use IO::Async::Stream;
use IO::Socket::IP;
use JSON::MaybeXS;
use Langertha::Raider::Hall::ACP::SubStream;


has hall => (
  is => 'ro',
  isa => 'Langertha::Raider::Hall',
  required => 1,
  weak_ref => 1,
);

has port => (
  is => 'ro',
  isa => 'Int',
  default => 0,
);

has host => (
  is => 'ro',
  isa => 'Str',
  default => '127.0.0.1',
);

has _sessions => (
  is => 'ro',
  default => sub { {} },
);

has _listener => (
  is => 'rw',
);

our $PROTOCOL_VERSION = 1;

sub start {
  my ($self) = @_;
  my $loop = $self->hall->loop;

  my $sock = IO::Socket::IP->new(
    LocalHost => $self->host,
    LocalPort => $self->port,
    Listen    => 10,
    ReuseAddr => 1,
  ) or die "ACP: cannot listen on " . $self->host . ":" . $self->port . ": $!";

  my $listener = IO::Async::Listener->new(
    on_accept => sub {
      my ($l, $client) = @_;
      $self->_handle_client($client);
    },
  );
  $loop->add($listener);
  $listener->listen(handle => $sock);
  $self->_listener($listener);

  my ($port) = $sock->sockport;
  $self->hall->_emit('acp.started', {
    host => $self->host, port => $port,
  });
  return $port;
}

sub stop {
  my ($self) = @_;
  my $l = $self->_listener or return;
  eval { $self->hall->loop->remove($l) };
  $self->_listener(undef);
}

sub _handle_client {
  my ($self, $sock) = @_;
  my $stream = IO::Async::Stream->new(
    handle  => $sock,
    on_read => sub {
      my ($stream, $bufref, $eof) = @_;
      while ($$bufref =~ s/^(.*?)\r?\n//) {
        $self->_dispatch($stream, $1);
      }
      return 0;
    },
    on_closed => sub {
      my ($stream) = @_;
      # Clean up any sessions bound to this stream.
      for my $sid (keys %{$self->_sessions}) {
        my $s = $self->_sessions->{$sid};
        $self->_forget_session($sid)
          if $s && $s->{stream} && $s->{stream} == $stream;
      }
    },
  );
  $self->hall->loop->add($stream);
}

sub _dispatch {
  my ($self, $stream, $line) = @_;
  return unless length $line;

  my $msg = eval { JSON::MaybeXS->new->decode($line) };
  if ($@ || ref $msg ne 'HASH') {
    return $self->_reply_err($stream, undef, -32700, 'parse error');
  }

  my $method = $msg->{method};
  my $id     = $msg->{id};
  my $params = $msg->{params} // {};

  if (!defined $method) {
    # It's a response to something we sent — ignore, we don't call out
    # mid-stream in this minimal adapter.
    return;
  }

  if ($method eq 'initialize') {
    return $self->_reply($stream, $id, {
      protocolVersion => $PROTOCOL_VERSION,
      agentCapabilities => {
        loadSession => JSON::MaybeXS::false(),
        promptCapabilities => {
          image           => JSON::MaybeXS::false(),
          audio           => JSON::MaybeXS::false(),
          embeddedContext => JSON::MaybeXS::false(),
        },
      },
    });
  }

  if ($method eq 'session/new') {
    return $self->_session_new($stream, $id, $params);
  }

  if ($method eq 'session/prompt') {
    return $self->_session_prompt($stream, $id, $params);
  }

  if ($method eq 'session/cancel') {
    return $self->_session_cancel($stream, $id, $params);
  }

  return $self->_reply_err($stream, $id, -32601, "method not found: $method");
}

sub _session_new {
  my ($self, $stream, $id, $params) = @_;

  my $raider_name = $params->{raiderName};
  if (!$raider_name) {
    my $raiders = $self->hall->config->{raiders} // {};
    ($raider_name) = sort keys %$raiders;
  }
  if (!$raider_name) {
    return $self->_reply_err($stream, $id, -32602,
      'no raiders configured and none specified');
  }

  my $session_id = 'acp-' . sprintf('%08x', int(rand(2**32)));
  $self->_sessions->{$session_id} = {
    stream => $stream,
    raider_name => $raider_name,
    current_raider_id => undef,
  };

  $self->_reply($stream, $id, { sessionId => $session_id });
}

# The hall session binding of an ACP session: its prompts continue one
# raider session; it ends with the ACP session, the journal stays.
sub _binding_of { 'acp:'.$_[1] }

sub _forget_session {
  my ($self, $session_id) = @_;
  my $session = delete $self->_sessions->{$session_id};
  if ($session) {
    $self->_end_run_subscription($session);
    if (my $watch = delete $session->{_spawn_watch}) { $watch->close }
  }
  my $hall = $self->hall or return;
  # Prompts still waiting for the session have no client left to answer.
  $hall->drop_queued($self->_binding_of($session_id));
  $hall->unbind_session($self->_binding_of($session_id));
  return;
}

sub _session_prompt {
  my ($self, $stream, $id, $params) = @_;

  my $session_id = $params->{sessionId}
    or return $self->_reply_err($stream, $id, -32602, 'missing sessionId');
  my $session = $self->_sessions->{$session_id}
    or return $self->_reply_err($stream, $id, -32602, "unknown session: $session_id");

  # Flatten the prompt content into text.
  my @blocks = @{ $params->{prompt} // [] };
  my $text = join("\n", map {
    my $b = $_;
    ref $b eq 'HASH' && defined $b->{text} ? $b->{text} : ''
  } @blocks);
  $text =~ s/^\s+|\s+$//g;
  return $self->_reply_err($stream, $id, -32602, 'empty prompt') unless length $text;

  my $spawn = $self->hall->spawn(
    name => $session->{raider_name},
    mission => $text,
    binding => $self->_binding_of($session_id),
  );
  if ($spawn->{error}) {
    return $self->_reply_err($stream, $id, -32000, "spawn failed: $spawn->{error}");
  }

  # Queued (1name or the session busy): ACP has no stop reason for a turn
  # that has not started, so the request stays open until the queued run
  # starts and ends, and is answered like any other.
  if ($spawn->{queued}) {
    push @{ $session->{waiting} //= [] }, $id;
    $self->_watch_spawns($session, $session_id, $stream);
    return;
  }

  my $raider_id = $spawn->{id};
  $session->{current_raider_id} = $raider_id;
  $session->{pending_request_id} = $id;

  # Subscribe this session's stream to hall events for this raider.
  # We reuse the hall's subscriber list but filter in _on_hall_event.
  $self->_attach_subscription($session, $raider_id, $stream);
}

# Waiting prompts start in order on the session's binding: each
# raider.spawned there takes the oldest one and streams its run to it. So
# does a hall.session_error there, for the run it started unbound.
sub _watch_spawns {
  my ($self, $session, $session_id, $stream) = @_;
  return if $session->{_spawn_watch};
  my $binding = $self->_binding_of($session_id);
  $session->{_spawn_watch} = $self->_subscribe('', sub {
    my ($evt) = @_;
    my $t = $evt->{type} // '';
    return unless $t eq 'raider.spawned' || $t eq 'hall.session_error';
    return unless ($evt->{binding} // '') eq $binding && defined $evt->{id};
    my $rid = shift @{ $session->{waiting} // [] };
    return unless defined $rid;
    $session->{current_raider_id} = $evt->{id};
    $session->{pending_request_id} = $rid;
    $self->_attach_subscription($session, $evt->{id}, $stream);
  });
}

# A callback on the hall event bus: the hall writes each event as a JSON
# line into the stream of a subscriber, so the callback sits behind a
# SubStream. Closing that stream ends the subscription.
sub _subscribe {
  my ($self, $filter, $cb) = @_;
  my $sub_stream = Langertha::Raider::Hall::ACP::SubStream->new(cb => sub {
    my ($json_line) = @_;
    my $evt = eval { JSON::MaybeXS->new->decode($json_line) };
    return if $@;
    $cb->($evt);
  });
  push @{ $self->hall->{_subscribers} ||= [] }, {
    stream => $sub_stream, filter => $filter,
  };
  return $sub_stream;
}

sub _attach_subscription {
  my ($self, $session, $raider_id, $stream) = @_;

  my $handler = sub {
    my ($evt) = @_;
    my $t = $evt->{type} // '';
    return unless $t =~ /^raider\./;
    return unless ($evt->{id} // '') eq $raider_id;

    if ($t eq 'raider.done') {
      # The hall reports every finished run as raider.done, carrying the
      # outcome from its run.finished event: status plus a response, or an
      # error when the run failed or ended without one.
      my $status = $evt->{status} // '';
      my $cancelled = $evt->{signaled}
        || $status =~ /^(?:cancelled|interrupted)$/;

      # A failed run is a run error, not a model answer: end the turn as a
      # JSON-RPC error and do NOT stream its error text as an
      # agent_message_chunk — an editor would render that as a normal
      # reply and, with stopReason end_turn, never learn the run broke.
      if (!$cancelled && $status ne 'completed') {
        return $self->_fail_run($session, $stream,
          $evt->{error} // 'run ended without a result');
      }

      # Completed (or cancelled): forward the outcome text as a final
      # agent_message_chunk before closing the turn — otherwise the client
      # only ever sees status events.
      my $body = $evt->{response} // ($cancelled ? $evt->{error} : undef);
      if (defined $body && length $body) {
        $self->_notify($stream, 'session/update', {
          sessionId => $self->_session_id_for($session),
          update => {
            sessionUpdate => 'agent_message_chunk',
            content => { type => 'text', text => $body },
          },
        });
      }
      $self->_end_run_subscription($session);
      my $rid = delete $session->{pending_request_id};
      $self->_reply($stream, $rid, {
        stopReason => $cancelled ? 'cancelled' : 'end_turn',
      }) if defined $rid;
    }
    elsif ($t eq 'raider.failed') {
      # A run failure the hall might report out of band: treat it exactly
      # like a failed raider.done — a JSON-RPC error, never 'refusal'.
      # 'refusal' in ACP means the *model* declined, not that the run broke.
      $self->_fail_run($session, $stream,
        $evt->{error} // 'raider run failed');
    }
    else {
      # Forward other raider.* events as plaintext chunks so clients get
      # *some* streaming. A richer mapping (tool_call → tool_use update
      # etc.) can grow from here.
      my $chunk = JSON::MaybeXS->new(canonical => 1)->encode({
        type => $t, ($evt->{data} ? (data => $evt->{data}) : ()),
      });
      $self->_notify($stream, 'session/update', {
        sessionId => $self->_session_id_for($session),
        update => {
          sessionUpdate => 'agent_message_chunk',
          content => { type => 'text', text => $chunk },
        },
      });
    }
  };

  $session->{_sub_stream} = $self->_subscribe('raider.', $handler);
}

# A failed run ends session/prompt as a JSON-RPC error, so an editor can
# tell a broken run apart from a normal answer. The failure text rides in
# the JSON-RPC error message, never as an agent_message_chunk.
sub _fail_run {
  my ($self, $session, $stream, $error) = @_;
  $self->_end_run_subscription($session);
  my $rid = delete $session->{pending_request_id};
  $self->_reply_err($stream, $rid, -32000, "raider run failed: $error")
    if defined $rid;
  return;
}

# The run of the session's current prompt ended: stop listening to it.
sub _end_run_subscription {
  my ($self, $session) = @_;
  my $sub_stream = delete $session->{_sub_stream} or return;
  $sub_stream->close;
}

sub _session_id_for {
  my ($self, $session) = @_;
  for my $sid (keys %{$self->_sessions}) {
    return $sid if $self->_sessions->{$sid} == $session;
  }
  return '';
}

sub _session_cancel {
  my ($self, $stream, $id, $params) = @_;
  my $session_id = $params->{sessionId}
    or return $self->_reply_err($stream, $id, -32602, 'missing sessionId');
  my $session = $self->_sessions->{$session_id}
    or return $self->_reply_err($stream, $id, -32602, "unknown session: $session_id");

  # Prompts still waiting end cancelled, without running.
  $self->hall->drop_queued($self->_binding_of($session_id));
  for my $rid (splice @{ $session->{waiting} // [] }) {
    $self->_reply($stream, $rid, { stopReason => 'cancelled' });
  }
  if (my $rid = $session->{current_raider_id}) {
    $self->hall->cancel_raider($rid);
  }
  $self->_reply($stream, $id, {});
}

sub _reply {
  my ($self, $stream, $id, $result) = @_;
  return unless defined $id;
  my $msg = { jsonrpc => '2.0', id => $id, result => $result };
  $stream->write(JSON::MaybeXS->new->encode($msg) . "\n");
}

sub _reply_err {
  my ($self, $stream, $id, $code, $message) = @_;
  return unless defined $id;
  my $msg = { jsonrpc => '2.0', id => $id, error => { code => $code, message => $message } };
  $stream->write(JSON::MaybeXS->new->encode($msg) . "\n");
}

sub _notify {
  my ($self, $stream, $method, $params) = @_;
  my $msg = { jsonrpc => '2.0', method => $method, params => $params };
  $stream->write(JSON::MaybeXS->new->encode($msg) . "\n");
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::ACP - Internal ACP (Agent Client Protocol) adapter that exposes the hall over TCP

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Minimal ACP server. Speaks JSON-RPC 2.0 line-framed over TCP. Clients
that speak ACP over TCP (C<raider acp>, L<Langertha::Raider::ACP::Client>)
connect to the configured port and drive raiders through the hall. An
editor that starts its agent as a command over stdio needs the stdio
server of ADR 0010, which does not exist yet.

=head2 Supported methods

=over

=item * C<initialize> — handshake. Returns C<protocolVersion> and
C<agentCapabilities> (promptCapabilities: image=false, audio=false,
embeddedContext=false).

=item * C<session/new> — create a session bound to a raider slot.
Params: C<{ cwd, mcpServers?, raiderName? }>. If C<raiderName> is given
it selects the configured raider; otherwise the first entry in
C<.raider-hall.yml> is used.

=item * C<session/prompt> — spawn the raider with the user turn's text
content, stream C<session/update> notifications from the hall event bus,
return C<{ stopReason }> when the raider finishes. A run that
B<completes> ends C<end_turn>, a B<cancelled> run ends C<cancelled>, and a
B<failed> run (an engine error, a crash, a run that ended without a
result) ends C<session/prompt> as a JSON-RPC error (code C<-32000>),
not as a normal answer: its error text rides in the JSON-RPC error
message and is never streamed as an C<agent_message_chunk>, so an editor
tells a broken run apart from a reply. All prompts of an ACP
session run in one raider session, bound as C<acp:SESSION> until the
client disconnects (see L<Langertha::Raider::Hall/session_bindings>).
A prompt that has to wait -- its C<1name> slot or its session is busy --
gets no answer until its run has started and ended; then it is answered
like any other -- C<end_turn>, C<cancelled> or a JSON-RPC error -- also
when the hall had to start that run without the session
(C<hall.session_error>).

=item * C<session/cancel> — cancel the running raider's run with a
C<SIGINT> (L<Langertha::Raider::Hall/cancel_raider>): it ends the run as
C<cancelled>, and its prompt is answered C<cancelled>. A raider the
signal does not end gets C<SIGTERM>, then C<SIGKILL>, each after the
hall's C<cancel_grace>. Prompts still
waiting are answered C<cancelled> and never run.

=back

Features intentionally omitted in this first cut: authentication,
filesystem push-edits, embedded context resources, audio/image content
blocks. Calls unknown to this adapter return JSON-RPC error
C<-32601 method not found>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

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
