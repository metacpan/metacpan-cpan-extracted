use strict;
use Test::Lib;
use Test::More tests => 2;
use Example::Synopsis::Set;

my $set = Example::Synopsis::Set::->new;

ok ! $set->has(1);
$set->add(1);
ok $set->has(1);
