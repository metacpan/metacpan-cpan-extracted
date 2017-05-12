use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use ClientTest;

use Test::More;

if (eval "use Gearman::Spawner::Client::Sync; 1") {
    plan tests => 15;
}
else {
    plan skip_all => 'synchronous client not available';
}

my $tester = eval { ClientTest->new };
SKIP: {
$@ && skip $@, 15;

my @tests = $tester->tests;

my $client = Gearman::Spawner::Client::Sync->new(job_servers => [$tester->server]);
for my $test (@tests) {
    my $ret = $client->run_method(
        class  => $tester->class,
        method => $test->[0],
        data   => $test->[1],
    );
    $test->[2]->($ret);
};

}
