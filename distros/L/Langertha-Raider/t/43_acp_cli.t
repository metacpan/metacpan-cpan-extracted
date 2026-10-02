#!/usr/bin/env perl
# ABSTRACT: Langertha::Raider::ACP::CLI — client-side dispatcher (t/40-42 cover
# the server/transport; this covers argument parsing and dispatch, with
# Langertha::Raider::ACP::Client faked so nothing touches a real socket)

use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS ();
use Langertha::Raider::ACP::CLI;
use Langertha::Raider::ACP::Client;

sub capture {
  my ($code) = @_;
  my ($out, $err) = ('', '');
  local *STDOUT;
  local *STDERR;
  open STDOUT, '>', \$out or die $!;
  open STDERR, '>', \$err or die $!;
  my $rv = $code->();
  return ( $rv, $out, $err );
}

# --- _parse_endpoint ---

subtest '_parse_endpoint' => sub {
  is( [ Langertha::Raider::ACP::CLI::_parse_endpoint('example.org:4711') ],
    ['example.org', '4711'], 'HOST:PORT' );
  is( [ Langertha::Raider::ACP::CLI::_parse_endpoint('4711') ],
    ['127.0.0.1', '4711'], 'bare PORT defaults host to 127.0.0.1' );
  like( dies { Langertha::Raider::ACP::CLI::_parse_endpoint() },
    qr/^endpoint required/, 'missing endpoint dies' );
  like( dies { Langertha::Raider::ACP::CLI::_parse_endpoint('not-an-endpoint') },
    qr/^bad endpoint 'not-an-endpoint' \(want HOST:PORT or PORT\)/, 'unparsable endpoint dies' );
};

# --- usage ---

subtest 'usage' => sub {
  like( Langertha::Raider::ACP::CLI::usage(), qr/^Usage: raider acp <subcommand>/, 'usage banner' );
};

# --- main: dispatch ---

subtest 'main: unknown subcommand dies with usage appended' => sub {
  my $err = dies { Langertha::Raider::ACP::CLI->main('bogus') };
  like( $err, qr/^Unknown subcommand: bogus/, 'names the bad subcommand' );
  like( $err, qr/Usage: raider acp <subcommand>/, 'usage appended' );
};

# --- run_ping ---

subtest 'main ping: prints the handshake result as JSON' => sub {
  my @new_args;
  no warnings 'redefine';
  local *Langertha::Raider::ACP::Client::new = sub {
    my ($class, %a) = @_;
    @new_args = %a;
    return bless {}, $class;
  };
  local *Langertha::Raider::ACP::Client::initialize = sub {
    return { protocolVersion => '1', agentCapabilities => { promptCapabilities => {} } };
  };

  my ( $rv, $out, $err ) = capture(sub { Langertha::Raider::ACP::CLI->main('ping', 'example.org:4711') });
  is( $rv, 0, 'returns 0' );
  is( $err, '', 'nothing on stderr' );
  is( { @new_args }, { host => 'example.org', port => '4711' }, 'client built for the parsed endpoint' );
  is( JSON::MaybeXS->new->decode($out),
    { protocolVersion => '1', agentCapabilities => { promptCapabilities => {} } },
    'handshake result printed as JSON' );
};

subtest 'main ping: no endpoint dies with usage' => sub {
  like( dies { Langertha::Raider::ACP::CLI->main('ping') },
    qr/^Usage: raider acp ping HOST:PORT/, 'usage message' );
};

# --- run_prompt ---

subtest 'main prompt: one-shot session, text joined, streams updates' => sub {
  my ( @init_calls, @session_args, @prompt_calls );
  no warnings 'redefine';
  local *Langertha::Raider::ACP::Client::new = sub { bless {}, $_[0] };
  local *Langertha::Raider::ACP::Client::initialize = sub { push @init_calls, 1; return {} };
  local *Langertha::Raider::ACP::Client::new_session = sub {
    my ($self, $params) = @_;
    push @session_args, $params;
    return { sessionId => 'acp-test' };
  };
  local *Langertha::Raider::ACP::Client::prompt_stream = sub {
    my ($self, $sid, $text, $on_update) = @_;
    push @prompt_calls, [$sid, $text];
    $on_update->({ update => { content => { text => 'partial ' } } });
    $on_update->({ update => { content => { text => 'answer' } } });
    return { stopReason => 'end_turn' };
  };

  my ( $rv, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI->main('prompt', 'example.org:4711', '--raider', 'bjorn', 'say', 'hi');
  });
  is( $rv, 0, 'returns 0' );
  is( scalar @init_calls, 1, 'handshake performed' );
  is( $session_args[0], { raiderName => 'bjorn' }, '--raider becomes raiderName on session/new' );
  is( $prompt_calls[0], ['acp-test', 'say hi'], 'trailing args joined into one prompt text' );
  like( $out, qr/partial answer/, 'streamed update chunks printed as they arrive' );
  like( $out, qr/-- stopReason: end_turn$/m, 'final stopReason line printed' );
};

subtest 'main prompt: --json also dumps raw frames to stderr' => sub {
  no warnings 'redefine';
  local *Langertha::Raider::ACP::Client::new = sub { bless {}, $_[0] };
  local *Langertha::Raider::ACP::Client::initialize = sub { {} };
  local *Langertha::Raider::ACP::Client::new_session = sub { { sessionId => 'acp-test' } };
  local *Langertha::Raider::ACP::Client::prompt_stream = sub {
    my ($self, $sid, $text, $on_update) = @_;
    $on_update->({ update => { content => { text => 'hi' } }, extra => 'frame' });
    return { stopReason => 'end_turn' };
  };

  my ( $rv, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI->main('prompt', '--json', 'example.org:4711', 'hi');
  });
  is( $rv, 0, 'returns 0' );
  my $frame = JSON::MaybeXS->new->decode($err);
  is( $frame->{extra}, 'frame', 'raw update params dumped to stderr under --json' );
};

subtest 'main prompt: no text after the endpoint dies' => sub {
  no warnings 'redefine';
  local *Langertha::Raider::ACP::Client::new = sub { bless {}, $_[0] };
  local *Langertha::Raider::ACP::Client::initialize = sub { {} };
  local *Langertha::Raider::ACP::Client::new_session = sub { { sessionId => 'acp-test' } };
  like( dies { Langertha::Raider::ACP::CLI->main('prompt', 'example.org:4711') },
    qr/^No prompt text given\./, 'dies without text' );
};

subtest 'main prompt: no endpoint dies with usage' => sub {
  like( dies { Langertha::Raider::ACP::CLI->main('prompt') },
    qr/^Usage: raider acp prompt HOST:PORT TEXT\.\.\./, 'usage message' );
};

# --- _print_update ---

subtest '_print_update prints text chunks and, under --json, raw frames to stderr' => sub {
  my ( undef, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI::_print_update({ update => { content => { text => 'chunk' } } }, 0);
    return;
  });
  is( $out, 'chunk', 'text chunk printed to stdout' );
  is( $err, '', 'no stderr without --json' );

  ( undef, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI::_print_update({ update => { content => { text => 'chunk' } } }, 1);
    return;
  });
  is( $out, 'chunk', 'text chunk still printed to stdout' );
  like( $err, qr/"text":"chunk"/, 'raw frame also dumped to stderr under --json' );

  ( undef, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI::_print_update({ update => { content => { } } }, 0);
    return;
  });
  is( $out, '', 'no output for an update without text' );

  ( undef, $out, $err ) = capture(sub {
    Langertha::Raider::ACP::CLI::_print_update({ }, 0);
    return;
  });
  is( $out, '', 'no output, no crash, for a frame without an update at all' );
};

# --- run_connect: interactive REPL, driven by a faked Term::ReadLine ---

subtest 'main connect: prompts, /cancel, an error mid-loop, and /quit' => sub {
  my @lines = ('hello there', 'boom', '/cancel', '/quit');
  my ( @prompt_calls, @cancel_calls );
  no warnings qw( redefine once );
  local *Term::ReadLine::new = sub { bless { lines => [@lines] }, 'Term::ReadLine' };
  local *Term::ReadLine::ornaments = sub {};
  local *Term::ReadLine::readline = sub { shift @{ $_[0]{lines} } };

  local *Langertha::Raider::ACP::Client::new = sub { bless {}, $_[0] };
  local *Langertha::Raider::ACP::Client::initialize = sub { { protocolVersion => '1' } };
  local *Langertha::Raider::ACP::Client::new_session = sub { { sessionId => 'acp-test' } };
  local *Langertha::Raider::ACP::Client::cancel = sub {
    my ($self, $sid) = @_;
    push @cancel_calls, $sid;
    return {};
  };
  local *Langertha::Raider::ACP::Client::prompt_stream = sub {
    my ($self, $sid, $text, $on_update) = @_;
    push @prompt_calls, $text;
    die "boom happened\n" if $text eq 'boom';
    $on_update->({ update => { content => { text => 'Hi!' } } });
    return { stopReason => 'end_turn' };
  };

  my ( $rv, $out, $err ) = capture(sub { Langertha::Raider::ACP::CLI->main('connect', 'example.org:4711') });
  is( $rv, 0, 'returns 0, no bare exit in the REPL body' );
  is( \@prompt_calls, ['hello there', 'boom'], 'plain lines sent as prompts, commands are not' );
  is( \@cancel_calls, ['acp-test'], '/cancel sends session/cancel for the current session' );
  like( $out, qr/connected to example\.org:4711/, 'connected banner' );
  like( $out, qr/Hi!/, 'streamed update text printed' );
  like( $out, qr/error: boom happened/, 'a prompt_stream death is caught and reported, loop continues' );
  like( $out, qr/\[cancel sent\]/, '/cancel acknowledged' );
  like( $out, qr/bye\.$/, '/quit ends the loop and prints bye' );
};

done_testing;
