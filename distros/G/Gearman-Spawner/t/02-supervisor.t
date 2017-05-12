use strict;
use warnings;

use Test::More tests => 2;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner;
use Gearman::Spawner::Server;
use IO::Socket::INET;

my $class = 'MethodWorker';

my $spawner = Gearman::Spawner->new(
    servers => [Gearman::Spawner::Server->address],
    workers => { },
);

my $pid = $spawner->pid;
ok(kill(0, $pid), 'supervisor is alive');

my $timed_out = 0;
$SIG{ALRM} = sub { $timed_out++ };
alarm 1;
undef $spawner;
waitpid $pid, 0;
ok(!$timed_out, 'supervisor dies on object destruction');
