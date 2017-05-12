use strict;
use warnings;

use Test::More tests => 8;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner;
use Gearman::Spawner::Server;
use IO::Socket::INET;

my $server = Gearman::Spawner::Server->address;

my $class = 'MethodWorker';

my $spawner = Gearman::Spawner->new(
    servers => [$server],
    workers => {
        $class => { },
    },
);
sleep 1; # give workers a chance to register

my $pid = $spawner->pid;
ok(kill(0, $pid), 'spawner is alive');

sub check_workers {
    my $mgmt = IO::Socket::INET->new($server);
    ok($mgmt, 'can connect to server');

    ok($mgmt->print("workers\n"), "can send workers command to server");
    $mgmt->shutdown(1);
    my $buf = '';
    while (<$mgmt>) {
        last if /^\./;
        $buf .= $_;
    }

    return $buf;
}

my $status = check_workers();
like($status, qr/$class/, "$class worker is registered") || diag $status;

my $timed_out = 0;
$SIG{ALRM} = sub { $timed_out++ };
alarm 1;
undef $spawner;
waitpid $pid, 0;
ok(!$timed_out, 'spawner dies on object destruction');

sleep 1;

$status = check_workers();
unlike($status, qr/$class/, "$class worker is no longer registered") || diag $status;
