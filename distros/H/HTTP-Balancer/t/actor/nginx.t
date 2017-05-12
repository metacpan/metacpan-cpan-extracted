use Modern::Perl;
use Test::More;
use local::lib 'local';

use Proc::ProcessTable;
use Path::Tiny;

BEGIN {
    use_ok 'HTTP::Balancer::Actor::Nginx';
}

SKIP: {

skip "no nginx installed", 3
unless HTTP::Balancer::Actor::Nginx->executable;


my $pidfilename = "/tmp/http-balancer-test.pid";
path($pidfilename)->remove if path($pidfilename)->exists;

my $actor = HTTP::Balancer::Actor::Nginx->new;
$actor->start(
    pidfile => $pidfilename,
    hosts   => [
        {
            name     => "www",
            address  => "0.0.0.0",
            port     => 8080,
            fullname => "",
            backends => [
                "localhost:3000",
                "localhost:3001",
                "localhost:3002",
            ],
        }
    ]
);

while (1) {
    last if path($pidfilename)->exists;
}

my $pid = path($pidfilename)->slurp;

like (
    $pid,
    qr{\d+},
    "actor puts pid in pidfile",
);

is (
    scalar(grep {$_->pid == $pid} @{Proc::ProcessTable->new->table}),
    1,
    "process is running",
);

$actor->stop(pidfile => $pidfilename);

is (
    scalar(grep {$_->pid == $pid} @{Proc::ProcessTable->new->table}),
    0,
    "process is stopped",
);

};

done_testing;
