use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw( tempdir );
use IO::Socket::IP;
use JSON::MaybeXS;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::Hall;
no warnings 'once';  # PROTOCOL_VERSION imported from the ACP package

# Full adapter lifecycle: spin up a hall in a tempdir, listen on an
# ephemeral ACP port, send initialize and session/new frames, assert
# well-formed JSON-RPC responses, then shut down.

my $tmp = tempdir(CLEANUP => 1);
path("$tmp/.raider-hall.yml")->spew_utf8(YAML::PP->new->dump_string({
  raiders => {
    Testie => { engine => 'anthropic', persona => 'caveman', packs => [], mcp => [], isolated => 0 },
  },
  acp => { port => 0, host => '127.0.0.1' },
}));

my $hall = Langertha::Raider::Hall->new(root => path($tmp));
require Langertha::Raider::Hall::ACP;

# We don't want the hall's own IO loop to block — poke start manually
# and drive a single client synchronously against the accepted socket.
my $acp = Langertha::Raider::Hall::ACP->new(
  hall => $hall,
  port => 0,
  host => '127.0.0.1',
);

# Manually create the listener socket so we control the port binding
# without relying on the full ->start path (which registers with the
# hall's loop that isn't running in this test).
my $listen = IO::Socket::IP->new(
  LocalHost => '127.0.0.1',
  LocalPort => 0,
  Listen    => 1,
  ReuseAddr => 1,
) or plan skip_all => "cannot bind local TCP socket: $!";

my $port = $listen->sockport;
ok($port > 0, "listener bound to port $port");

# Fork-free: we open a client socket, then accept it on the same
# process, and drive both ends with non-blocking reads. The ACP
# adapter's _dispatch function is what we want to exercise end-to-end,
# so we feed lines through it directly.
my $client = IO::Socket::IP->new(
  PeerHost => '127.0.0.1',
  PeerPort => $port,
) or die "cannot connect: $!";
my $server_side = $listen->accept or die "accept: $!";
$server_side->blocking(0);

# Build a minimal pseudo-stream that our adapter can write to. We just
# need ->write; the adapter never reads back through it.
{
  package TestStream;
  sub new { my ($c, $sock) = @_; bless { sock => $sock }, $c }
  sub write { my ($self, $data) = @_; syswrite $self->{sock}, $data }
}
my $stream = TestStream->new($server_side);

# initialize
$acp->_dispatch($stream, JSON::MaybeXS->new->encode({
  jsonrpc => '2.0', id => 1, method => 'initialize', params => {},
}));
my $line = '';
while (1) {
  my $chunk;
  my $n = sysread $client, $chunk, 4096;
  last unless defined $n && $n > 0;
  $line .= $chunk;
  last if $line =~ /\n/;
}
my ($initline) = split /\n/, $line, 2;
my $init = JSON::MaybeXS->new->decode($initline);
is($init->{jsonrpc}, '2.0', 'jsonrpc version');
is($init->{id}, 1, 'id echoed');
is($init->{result}{protocolVersion}, $Langertha::Raider::Hall::ACP::PROTOCOL_VERSION,
   'protocol version reported');
ok($init->{result}{agentCapabilities}, 'agentCapabilities present');

# session/new
$acp->_dispatch($stream, JSON::MaybeXS->new->encode({
  jsonrpc => '2.0', id => 2, method => 'session/new', params => { cwd => $tmp },
}));
$line = '';
while (1) {
  my $chunk;
  my $n = sysread $client, $chunk, 4096;
  last unless defined $n && $n > 0;
  $line .= $chunk;
  last if $line =~ /\n/;
}
my ($sline) = split /\n/, $line, 2;
my $sresp = JSON::MaybeXS->new->decode($sline);
is($sresp->{id}, 2, 'session/new id echoed');
like($sresp->{result}{sessionId}, qr/^acp-/, 'sessionId format');

# unknown method
$acp->_dispatch($stream, JSON::MaybeXS->new->encode({
  jsonrpc => '2.0', id => 3, method => 'does/not/exist',
}));
$line = '';
while (1) {
  my $chunk;
  my $n = sysread $client, $chunk, 4096;
  last unless defined $n && $n > 0;
  $line .= $chunk;
  last if $line =~ /\n/;
}
my ($eline) = split /\n/, $line, 2;
my $eresp = JSON::MaybeXS->new->decode($eline);
is($eresp->{id}, 3, 'error reply id echoed');
is($eresp->{error}{code}, -32601, 'method not found code');

close $client;
close $server_side;
close $listen;

done_testing;
