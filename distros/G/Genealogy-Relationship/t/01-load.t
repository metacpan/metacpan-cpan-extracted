use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'Genealogy::Relationship' }

ok(my $obj = Genealogy::Relationship->new, 'Got an object');
isa_ok($obj, 'Genealogy::Relationship');

done_testing;
