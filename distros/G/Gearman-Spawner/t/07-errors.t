use strict;
use warnings;

# test that spawner dies if a supervisor fails

use Test::More tests => 4;

use FindBin '$Bin';
use lib "$Bin/lib";

use Gearman::Spawner;
use Gearman::Spawner::Server;

my $server = Gearman::Spawner::Server->address;

eval {
    Gearman::Spawner->new(
        servers => [$server],
        workers => {
            CompileErrorWorker => { },
        },
    );
};

ok($@, "CompileErrorWorker failed");
like($@, qr/compile error/, 'CompileErrorWorker error message');

eval {
    Gearman::Spawner->new(
        servers => [$server],
        workers => {
            BadImportWorker => { },
        },
    );
};
ok($@, "BadImportWorker failed");
like($@, qr/Can't locate NonexistentModule\.pm/, 'BadImportWorker error message');
