use strict;
use Test::Lib;
use Test::More tests => 2;
use Example::Construction::Set_v1;

my $set = Example::Construction::Set_v1::->new;

ok ! $set->has(1);
$set->add(1);
ok $set->has(1);