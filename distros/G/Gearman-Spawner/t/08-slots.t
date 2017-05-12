use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner;
use Gearman::Spawner::Server;

use Test::More;

if (eval "use Gearman::Spawner::Client::Async; 1") {
    plan tests => 10;
}
else {
    plan skip_all => 'asynchronous client not available';
}

my $server = Gearman::Spawner::Server->address;
SKIP: {
$@ && skip $@, 15;

my $number = 10;

my $spawner = Gearman::Spawner->new(
    servers => [$server],
    workers => {
        SlotWorker => {
            count => $number,
        },
    },
);

my $terminate_loop = sub { Danga::Socket->SetPostLoopCallback(sub { 0 }) };

my $client = Gearman::Spawner::Client::Async->new(job_servers => [$server]);
my $returned = 0;
my @slots = (1 .. $number);
my %seen = map { $_ => 1 } @slots;
for my $test (@slots) {
    $client->run_method(
        class   => 'SlotWorker',
        method  => 'slot',
        success_cb => sub {
            my $slot = shift;
            delete $seen{$slot};
            return $terminate_loop->() if ++$returned >= $number;
        },
        error_cb => sub {
            return $terminate_loop->() if ++$returned >= $number;
        }
    );
};

Danga::Socket->EventLoop;

ok(!exists $seen{$_}, "saw worker $_") for @slots;

}
