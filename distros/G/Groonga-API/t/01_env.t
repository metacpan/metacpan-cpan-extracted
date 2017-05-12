use strict;
use warnings;
use Groonga::API;
use Test::More;

diag "Groonga version: " . Groonga::API::get_version();

eval { diag `groonga --version`; };

ok 1;

done_testing;
