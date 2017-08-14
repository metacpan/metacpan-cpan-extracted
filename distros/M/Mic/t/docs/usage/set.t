use strict;
use Test::Lib;
use Test::More tests => 2;
use Example::Usage::Set;

my $set = Example::Usage::Set::->new;

ok ! $set->has(1);

$set->add(1);
ok $set->has(1);
