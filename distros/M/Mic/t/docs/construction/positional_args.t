use strict;
use Test::Lib;
use Test::More tests => 3;
use Example::Construction::Set_v2;

my $set = Example::Construction::Set_v2::->new(1 .. 4);

ok $set->has(1);
ok ! $set->has(5);
$set->add(5);
ok $set->has(5);
