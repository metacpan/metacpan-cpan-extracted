# command_timeout firing. No gearmand needed: a fake server accepts the
# connection but never replies, so a sent request must trip the command
# timer. The connection is then torn down — the request callback sees
# "disconnected" (queue drained) while on_error reports the specific
# "command timeout" reason.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $srv = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 1, ReuseAddr => 1,
) or plan skip_all => "cannot bind a listener: $!";
my $port = $srv->sockport;
$srv->blocking(0);

# Accept incoming connections and then do nothing with them.
my @conns;
my $accept_w = EV::io fileno($srv), EV::READ, sub {
    while (my $c = $srv->accept) { push @conns, $c }   # hold open, stay silent
};

my @errs;
my ($req_err, $req_called);
my $g = EV::Gearman->new(
    host            => '127.0.0.1',
    port            => $port,
    command_timeout => 250,    # ms
    on_error => sub {
        push @errs, $_[0];
        EV::break if $_[0] eq 'command timeout';
    },
);
$g->on_connect(sub {
    $g->echo('ping', sub { $req_called = 1; $req_err = $_[1] });
});

my $guard = EV::timer 5, 0, sub { fail 'command-timeout never fired'; EV::break };
EV::run;

ok( (grep { $_ eq 'command timeout' } @errs),
    'on_error reports "command timeout"' );
ok $req_called, 'in-flight request callback was invoked';
is $req_err, 'disconnected',
    'in-flight request drained with "disconnected" on teardown';
ok !$g->is_connected, 'connection torn down after command timeout';

done_testing;
