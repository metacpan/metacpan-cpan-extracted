use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
unless ($probe) {
    plan skip_all => "no gearmand at $host:$port (set TEST_GEARMAN_HOST/PORT)";
}
close $probe;

# Construction without connect
my $g = EV::Gearman->new;
isa_ok $g, 'EV::Gearman';
ok !$g->is_connected, 'not connected';

# Bad host: synchronous error
my $bad = EV::Gearman->new(host => '127.0.0.1', port => 1);  # closed port
ok defined $bad, 'constructed with bad target';

# Connect to live server
my $g2 = EV::Gearman->new(host => $host, port => $port);
my $connected;
$g2->on_connect(sub { $connected = 1; EV::break });
my $w = EV::timer 3, 0, sub { EV::break };
EV::run;
ok $connected, "got on_connect to $host:$port";
ok $g2->is_connected, 'is_connected reports true';

# Echo round-trip
my ($echo_r, $echo_e);
$g2->echo("ping-$$", sub { ($echo_r, $echo_e) = @_; EV::break });
$w = EV::timer 3, 0, sub { EV::break };
EV::run;
is $echo_r, "ping-$$", 'echo result matches';
is $echo_e, undef, 'echo no error';

# Disconnect
my $disconnected;
$g2->on_disconnect(sub { $disconnected = 1; EV::break });
$g2->disconnect;
$w = EV::timer 1, 0, sub { EV::break };
EV::run;
ok $disconnected, 'on_disconnect fired';
ok !$g2->is_connected, 'no longer connected';

done_testing;
