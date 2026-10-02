use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw( tempdir );
use IO::Socket::IP;
use YAML::PP;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();

# End-to-end smoketest: fork a child that runs a real hall ACP
# adapter on an ephemeral port, then drive it from the parent with
# Langertha::Raider::ACP::Client. Covers the full JSON-RPC round-trip over
# a real TCP socket.

# Pick a free port by binding + closing.
my $probe = IO::Socket::IP->new(
  LocalHost => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
) or plan skip_all => "cannot bind local TCP socket: $!";
my $port = $probe->sockport;
close $probe;

my $tmp = tempdir(CLEANUP => 1);
path("$tmp/.raider-hall.yml")->spew_utf8(YAML::PP->new->dump_string({
  raiders => {
    Testie => { engine => 'anthropic', persona => 'caveman', packs => [], mcp => [], isolated => 0 },
  },
  acp => { port => $port, host => '127.0.0.1' },
}));

my $pid = fork();
die "fork: $!" unless defined $pid;

if ($pid == 0) {
  # Child: start the hall and block on the event loop. Dies cleanly on
  # SIGTERM from the parent.
  require Langertha::Raider::Hall;
  my $hall = Langertha::Raider::Hall->new(root => path($tmp));
  $SIG{TERM} = sub { $hall->shutdown };
  eval { $hall->run };
  exit 0;
}

# Parent: wait until the port accepts connections (up to 5s), then run
# the client flow.
my $deadline = time + 5;
my $up;
while (time < $deadline) {
  $up = IO::Socket::IP->new(PeerHost => '127.0.0.1', PeerPort => $port, Timeout => 1);
  last if $up;
  select undef, undef, undef, 0.1;
}
ok($up, "server accepting connections on port $port") or do {
  kill 'TERM', $pid; waitpid $pid, 0;
  done_testing; exit 1;
};
close $up;

require Langertha::Raider::ACP::Client;
my $c = Langertha::Raider::ACP::Client->new(host => '127.0.0.1', port => $port);

my $init = $c->initialize;
is(ref $init, 'HASH', 'initialize returned a hashref');
ok(defined $init->{protocolVersion}, 'protocolVersion present');
ok($init->{agentCapabilities}, 'agentCapabilities present');

my $sess = $c->new_session;
like($sess->{sessionId}, qr/^acp-/, 'session created');

# Unknown method should surface as a die with the server's message.
eval { $c->_call('does/not/exist', {}) };
like($@, qr/method not found/, 'unknown method returns JSON-RPC error');

$c->close;

kill 'TERM', $pid;

# Bounded wait: Perl's waitpid second arg is flags, not a timeout — poll
# with WNOHANG up to 10s, then SIGKILL if the child is still around.
use POSIX qw( WNOHANG );
my $reaped;
for (1..50) {
  if (waitpid($pid, WNOHANG) > 0) { $reaped = 1; last }
  select undef, undef, undef, 0.2;
}
if (!$reaped) {
  kill 'KILL', $pid;
  waitpid $pid, 0;
}

done_testing;
