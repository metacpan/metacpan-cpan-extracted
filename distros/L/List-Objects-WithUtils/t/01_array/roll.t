use Test::More;
use strict; use warnings;

use List::Objects::WithUtils 'array';

my $arr = array('a' .. 'f');
my %as_hash = (map {; $_ => 1 } $arr->all );

my $rolled = $arr->roll(3);
ok $rolled->count == 3, 'rolled three items';
for my $item ($rolled->all) {
  ok exists $as_hash{$item}, "rolled item '$item' ok";
}

$rolled = $arr->roll(8);
ok $rolled->count == 8, 'rolled more than size of array';
for my $item ($rolled->all) {
  ok exists $as_hash{$item}, "rolled item '$item' ok";
}

$rolled = array->roll(3);
ok $rolled->grep(sub { !defined }) && $rolled->count == 3,
  'roll on empty array ok'
  or diag explain $rolled;


done_testing
