use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use File::Temp qw(tempdir);
use EV;
use EV::Nats;

my $bin = nats_bin_or_skip();
my $port = free_port();
my $dir = tempdir(CLEANUP => 1);
open my $conf, '>', "$dir/nats.conf" or die $!;
print $conf <<"CONF";
host: 127.0.0.1
port: $port
authorization {
    users: [{ user: app, password: secret,
        permissions: { publish: [allowed], subscribe: [allowed] } }]
}
CONF
close $conf;
my $pid = spawn_nats($bin, '-c', "$dir/nats.conf");
END { if ($pid) { local $?; kill 'TERM', $pid; waitpid $pid, 0; } }

plan tests => 5;
my ($nats, $got, $flushed, @errors);
my ($connects, $disconnects) = (0, 0);
$nats = EV::Nats->new(
    host => '127.0.0.1', port => $port, user => 'app', pass => 'secret',
    on_error => sub { push @errors, $_[0] },
    on_disconnect => sub { $disconnects++ },
    on_connect => sub {
        $connects++;
        $nats->subscribe('allowed', sub { $got = $_[1] });
        $nats->subscribe('denied', sub {});
        $nats->publish('denied', 'rejected');
        $nats->publish('allowed', 'delivered');
        $nats->flush(sub { $flushed = !defined $_[0]; EV::break });
    },
);
my $guard = EV::timer(5, 0, sub { EV::break });
EV::run;
is scalar @errors, 2, 'denied subscription and publish each reported an error';
like join('\n', @errors), qr/Permissions Violation for Subscription.*Permissions Violation for Publish/s,
    'permission errors identify both failed operations';
is $got, 'delivered', 'allowed publish still delivered on the same connection';
ok $flushed && $nats->is_connected, 'connection remains usable after permission errors';
is_deeply [$connects, $disconnects], [1, 0], 'recoverable errors cause no disconnect';
$nats->disconnect;
