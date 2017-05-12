use Test::More;
use strict; use warnings;

use List::Objects::WithUtils 'array';

my $arr = array('a' .. 'f');
my %as_hash = ( map {; $_ => 1 } $arr->all );

my $picked = $arr->pick(4);
ok $picked->count == 4, 'picked 3 items';
ok $picked->uniq->count == 4, 'items are unique';
for my $item ($picked->all) {
  ok exists $as_hash{$item}, "picked item '$item' ok";
}

my $all = $arr->pick(6);
is_deeply
  +{ map {; $_ => 1 } $all->all },
  \%as_hash,
  'pick (exact element count) ok';

$all = $arr->pick(7);
is_deeply
  +{ map {; $_ => 1 } $all->all },
  \%as_hash,
  'pick (gt element count) ok';

ok array->pick(3)->is_empty, 'pick on empty array ok';

done_testing
