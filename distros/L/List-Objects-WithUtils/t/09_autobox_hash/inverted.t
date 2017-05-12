use Test::More;
use strict; use warnings FATAL => 'all';

use Lowu;

my $hr = +{
  a => 1,
  b => 1,
  c => 2,
  d => 3,
};

my $inv = $hr->inverted;
ok $inv->keys->count == 3, 'boxed inverted hash has 3 keys'
  or diag explain $hr;
for my $idx (1,2,3) {
  ok $inv->get($idx)->does('List::Objects::WithUtils::Role::Array'),
    "key $idx isa array obj";
  ok $inv->get($idx)->has_any, "key $idx has elements";
}

done_testing
