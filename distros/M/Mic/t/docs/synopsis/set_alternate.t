use strict;
use Scalar::Util qw( reftype );
use Test::Lib;
use Test::More tests => 3;
use Mic::Bind 'Example::Synopsis::Set' => 'Example::Synopsis::HashSet';

use Example::Synopsis::Set;

my $set = Example::Synopsis::Set::->new;

is reftype $set->{$Example::Synopsis::HashSet::SET} => 'HASH';

ok ! $set->has(1);
$set->add(1);
ok $set->has(1);
