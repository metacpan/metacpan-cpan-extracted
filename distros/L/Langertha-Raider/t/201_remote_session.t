#!/usr/bin/env perl
# ABSTRACT: A session started on another agent: ACP client -> hall -> spawned raider on the scripted engine
use strict;
use warnings;
use utf8;
use Test2::V0;
use Path::Tiny;
use YAML::PP;
use IO::Socket::IP;
use POSIX qw( WNOHANG );
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Raider::Env qw( isolate_home );
BEGIN {
  eval { require Langertha::Engine::Virtual; 1 }
    or plan skip_all => 'needs Langertha::Engine::Virtual (Langertha 0.504 or later)';
}
isolate_home();

# The setup we run in practice: an agent (the hall) on another machine, a
# client that opens a session on it and hands it a prompt. Here "another
# machine" is a hall in its own process on a free local port; the client is
# Langertha::Raider::ACP::Client over a real TCP socket. The hall spawns a real
# raider process for the prompt, and that raider answers from rules instead of a
# model (-e mock), with its real tools working in the hall's root.

my $probe = IO::Socket::IP->new( LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1 )
  or plan skip_all => "cannot bind local TCP socket: $!";
my $port = $probe->sockport;
close $probe;

my $root = Path::Tiny->tempdir;
$root->child('.raider-hall.yml')->spew_utf8( YAML::PP->new->dump_string({
  raiders => { Testie => { engine => 'mock', packs => [], mcp => [], isolated => 0, permission_mode => 'acceptEdits' } },
  acp     => { port => $port, host => '127.0.0.1' },
}));
$root->child('rules.yml')->spew_utf8(<<'YAML');
rules:
  Write a note.:
    tool_calls:
      - [ write_file, { path: notes/remote.txt, content: "from the remote agent\n" } ]
  Hello: { answer: "Hi from the other side." }
after:
  write_file: { answer: "Notiz geschrieben." }
fallback: { answer: "Das kenne ich nicht." }
YAML
$root->child('.raider.yml')->spew_utf8(<<"YAML");
engine: mock
rules_file: $root/rules.yml
langfuse_enabled: 0
YAML

my $pid = fork() // die "fork: $!";
if ( !$pid ) {
  require Langertha::Raider::Hall;
  my $hall = Langertha::Raider::Hall->new( root => $root );
  $SIG{TERM} = sub { $hall->shutdown };
  eval { $hall->run };
  exit 0;
}

my $up;
for ( 1 .. 50 ) {
  $up = IO::Socket::IP->new( PeerHost => '127.0.0.1', PeerPort => $port, Timeout => 1 ) and last;
  select undef, undef, undef, 0.1;
}
ok( $up, 'the hall accepts connections' ) or do { kill 'TERM', $pid; waitpid $pid, 0; done_testing; exit 1 };
close $up;

require Langertha::Raider::ACP::Client;
my $client = Langertha::Raider::ACP::Client->new( host => '127.0.0.1', port => $port );
$client->initialize;

# Runs one prompt in a fresh session; returns the result and the text the hall streamed.
sub ask {
  my ($text) = @_;
  my $session = $client->new_session({ raiderName => 'Testie' });
  my $streamed = '';
  my $result = eval { $client->prompt_stream( $session->{sessionId}, $text, sub {
    my ($p) = @_;
    my $u = $p->{update} // {};
    $streamed .= $u->{content}{text} // '' if ref $u->{content} eq 'HASH';
  }) };
  return ( $result, $streamed, $@ );
}

subtest 'a prompt gets the answer of the agent on the other side' => sub {
  my ( $result, $streamed, $err ) = ask('Hello');
  is( $err, '', 'the prompt finishes' );
  is( $result->{stopReason}, 'end_turn', 'stop reason' );
  like( $streamed, qr/Hi from the other side\./, 'the answer was streamed back' );
};

subtest 'the remote agent runs its tools in its own root' => sub {
  my ( $result, $streamed, $err ) = ask('Write a note.');
  is( $err, '', 'the prompt finishes' );
  like( $streamed, qr/Notiz geschrieben\./, 'the answer after the tool call' );
  is( $root->child('notes/remote.txt')->slurp_utf8, "from the remote agent\n", 'the file is on the remote side' );
};

$client->close;
kill 'TERM', $pid;
my $reaped;
for ( 1 .. 50 ) {
  if ( waitpid( $pid, WNOHANG ) > 0 ) { $reaped = 1; last }
  select undef, undef, undef, 0.2;
}
if ( !$reaped ) { kill 'KILL', $pid; waitpid $pid, 0 }

done_testing;
