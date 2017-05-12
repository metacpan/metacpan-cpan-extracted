use strict;
use warnings;

use Test::More tests => 4;

use_ok('Gearman::Spawner');

eval { require Gearman::Spawner::Client::Sync };
ok(!$@ || $@ =~ m{Can't lo(cate|ad)}, 'Gearman::Spawner::Client::Sync') || diag $@;

eval { require Gearman::Spawner::Client::Async };
ok(!$@ || $@ =~ m{Can't lo(cate|ad)}, 'Gearman::Spawner::Client::Async') || diag $@;

eval { require Gearman::Spawner::Client::AnyEvent };
ok(!$@ || $@ =~ m{Can't lo(cate|ad)}, 'Gearman::Spawner::Client::AnyEvent') || diag $@;
