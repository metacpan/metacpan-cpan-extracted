#!/usr/bin/env perl
# ABSTRACT: Langertha::Raider::HallTools — hall_status/hall_spawn tools and the
# _call transport (telegram_reply is covered by t/33_hall_telegram_reply_target.t)

use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use File::Temp qw( tempdir );
use JSON::MaybeXS ();
use POSIX qw( WNOHANG );
use IO::Socket::UNIX;
use Langertha::Raider::HallTools qw( build_hall_tools_server );

sub tool_named {
  my ( $server, $name ) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  return $tool;
}

# --- _call transport: a real (local, non-live) UNIX socket "hall" ---
#
# Each helper forks a one-shot fake hall that accepts a single connection
# and runs $responder against the decoded request frame, then exits. No
# live network, no live MCP server — just the local socket _call actually
# speaks over.

sub with_fake_hall {
  my ( $responder ) = @_;
  my $dir  = tempdir( CLEANUP => 1 );
  my $sock = "$dir/hall.sock";
  my $listener = IO::Socket::UNIX->new( Local => $sock, Listen => 5 )
    or die "listen on $sock: $!";

  my $pid = fork();
  die "fork: $!" unless defined $pid;
  if ( $pid == 0 ) {
    my $conn = $listener->accept;
    if ( $conn ) {
      my $line = <$conn>;
      $responder->( $conn, $line );
    }
    close $listener;
    exit 0;
  }
  return ( $sock, $pid );
}

sub reap {
  my ( $pid ) = @_;
  for ( 1 .. 50 ) {
    return if waitpid( $pid, WNOHANG ) > 0;
    select undef, undef, undef, 0.1;
  }
  kill 'KILL', $pid;
  waitpid $pid, 0;
}

subtest '_call: round-trips a command frame over the socket' => sub {
  my ( $sock, $pid ) = with_fake_hall( sub {
    my ( $conn, $line ) = @_;
    chomp $line;
    my $req = JSON::MaybeXS->new->decode($line);
    is( $req, { type => 'command', payload => { cmd => 'status' } },
      'frame shape sent by _call' );
    print $conn JSON::MaybeXS->new->encode({ raiders => 2 })."\n";
  } );
  my $result = Langertha::Raider::HallTools::_call( $sock, 'status' );
  reap($pid);
  is( $result, { raiders => 2 }, 'decoded reply returned' );
};

subtest '_call: extra payload keys are forwarded in the frame' => sub {
  my ( $sock, $pid ) = with_fake_hall( sub {
    my ( $conn, $line ) = @_;
    chomp $line;
    my $req = JSON::MaybeXS->new->decode($line);
    is( $req->{payload}, { cmd => 'spawn', name => 'Bjorn', mission => 'raid' },
      'name/mission carried through' );
    print $conn JSON::MaybeXS->new->encode({ id => 'r1' })."\n";
  } );
  my $result = Langertha::Raider::HallTools::_call( $sock, 'spawn', name => 'Bjorn', mission => 'raid' );
  reap($pid);
  is( $result, { id => 'r1' }, 'decoded reply returned' );
};

subtest '_call: cannot connect to a socket that does not exist' => sub {
  my $dir = tempdir( CLEANUP => 1 );
  my $result = Langertha::Raider::HallTools::_call( "$dir/nope.sock", 'status' );
  like( $result->{error}, qr/^cannot connect to hall socket /, 'connect error surfaced' );
};

subtest '_call: no response from the hall' => sub {
  my ( $sock, $pid ) = with_fake_hall( sub {
    my ( $conn, $line ) = @_;
    close $conn;    # accept, then hang up without writing anything
  } );
  my $result = Langertha::Raider::HallTools::_call( $sock, 'status' );
  reap($pid);
  is( $result, { error => 'no response from hall' }, 'no-response error' );
};

subtest '_call: invalid JSON in the reply' => sub {
  my ( $sock, $pid ) = with_fake_hall( sub {
    my ( $conn, $line ) = @_;
    print $conn "not json at all\n";
  } );
  my $result = Langertha::Raider::HallTools::_call( $sock, 'status' );
  reap($pid);
  like( $result->{error}, qr/^invalid hall response: /, 'decode error surfaced' );
};

# --- build_hall_tools_server: socket param required ---

subtest 'build_hall_tools_server requires a socket' => sub {
  like( dies { build_hall_tools_server() }, qr/socket param required/, 'dies without socket' );
};

# --- hall_status / hall_spawn tools: exercised via a faked _call, like
# t/33 does for telegram_reply, so the tool logic (schema, success/error
# text_result shape) is tested independently of the transport above. ---

my @calls;
{
  no warnings 'redefine';
  *Langertha::Raider::HallTools::_call = sub {
    my ( $sock, $cmd, %payload ) = @_;
    push @calls, { cmd => $cmd, %payload };
    return { ok => 1 };
  };
}

subtest 'hall_status: schema takes no arguments' => sub {
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_status' );
  is( $tool->input_schema, { type => 'object', properties => {} }, 'empty schema' );
};

subtest 'hall_status: success returns the hall reply as JSON' => sub {
  @calls = ();
  no warnings 'redefine';
  local *Langertha::Raider::HallTools::_call = sub {
    my ( $sock, $cmd, %payload ) = @_;
    push @calls, { cmd => $cmd, %payload };
    return { raiders => 3, uptime => 42 };
  };
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_status' );
  my $r = $tool->code->( $tool, {} );
  ok( !$r->{isError}, 'not an error' );
  is( \@calls, [ { cmd => 'status' } ], 'status command sent, no extra payload' );
  is( JSON::MaybeXS->new->decode( $r->{content}[0]{text} ), { raiders => 3, uptime => 42 },
    'hall reply encoded as the text result' );
};

subtest 'hall_status: hall error surfaces as an error result' => sub {
  @calls = ();
  no warnings 'redefine';
  local *Langertha::Raider::HallTools::_call = sub { return { error => 'hall unreachable' } };
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_status' );
  my $r = $tool->code->( $tool, {} );
  ok( $r->{isError}, 'isError set' );
  is( $r->{content}[0]{text}, 'Error: hall unreachable', 'error text' );
};

subtest 'hall_spawn: schema requires name and mission' => sub {
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_spawn' );
  is( $tool->input_schema->{required}, [qw( name mission )], 'both required' );
};

subtest 'hall_spawn: success sends the spawn command and returns the reply' => sub {
  @calls = ();
  no warnings 'redefine';
  local *Langertha::Raider::HallTools::_call = sub {
    my ( $sock, $cmd, %payload ) = @_;
    push @calls, { cmd => $cmd, %payload };
    return { id => 'r7', pid => 4242, slot => 'bjorn' };
  };
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_spawn' );
  my $r = $tool->code->( $tool, { name => 'Bjorn', mission => 'raid the coast' } );
  ok( !$r->{isError}, 'not an error' );
  is( \@calls, [ { cmd => 'spawn', name => 'Bjorn', mission => 'raid the coast' } ], 'spawn command sent' );
  is( JSON::MaybeXS->new->decode( $r->{content}[0]{text} ), { id => 'r7', pid => 4242, slot => 'bjorn' },
    'hall reply encoded as the text result' );
};

subtest 'hall_spawn: hall error surfaces as an error result' => sub {
  @calls = ();
  no warnings 'redefine';
  local *Langertha::Raider::HallTools::_call = sub { return { error => 'name in use' } };
  my $tool = tool_named( build_hall_tools_server( socket => '/nonexistent' ), 'hall_spawn' );
  my $r = $tool->code->( $tool, { name => 'Bjorn', mission => 'raid' } );
  ok( $r->{isError}, 'isError set' );
  is( $r->{content}[0]{text}, 'Error: name in use', 'error text' );
};

done_testing;
