use strict;
use warnings;

use Test::More;
use Kelp::Module::Symbiosis;

can_ok 'Kelp::Module::Symbiosis', 'run_all';
isa_ok(Kelp::Module::Symbiosis->run_all, 'CODE');

done_testing;
