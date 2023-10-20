use 5.010;
use strict;
use warnings;
use rlib;
use Scalar::Util qw /refaddr/;

use Test::More;
use List::Unique::DeterministicOrder;

my @keys = qw /a z b y c x/;

my $obj = List::Unique::DeterministicOrder->new (data => \@keys);

foreach my $key (@keys) {
    ok ($obj->exists ($key), "Contains $key"); 
}
foreach my $key (qw /d e f g/) {
    ok (!$obj->exists ($key), "Does not contain $key"); 
}

my $key_count = $obj->keys;
is ($key_count, 6, "Got correct key count");

my @got_keys = $obj->keys;
is_deeply \@got_keys, \@keys, 'Got expected key order';

eval {$obj->_paranoia};
my $e = $@;
ok !$e, 'no errors from paranoia check';

my $last_key = pop @keys;
my $popper = $obj->pop;
is $popper, $last_key, "Popped $last_key";

for my $i (0 .. $#keys) {
    is $obj->get_key_at_pos($i), $keys[$i], "got correct key at pos $i";
}

$key_count = $obj->keys;
is ($key_count, 5, "Got correct key count after pop");

#  now we delete some keys by index
my $deletion = $obj->delete_key_at_pos (1);
is $deletion, $keys[1], "key deletion of position returned $keys[1]";
ok (!$obj->exists ($keys[1]), "no $keys[1] in the hash");
$key_count = $obj->keys;
is ($key_count, 4, "Got correct key count after delete_key_at_pos");

eval {$obj->_paranoia};
note $@ if $@;

#  update @keys
splice @keys, 1;

#  now delete by name
$deletion = $obj->delete ('c');
is $deletion, 'c', "got deleted key c";
$key_count = $obj->keys;
is ($key_count, 3, "Got correct key count after delete");
ok (!$obj->exists ('c'), 'no c in the hash');

#note "Keys are now " . join ' ', $obj->keys;

#  add some keys that are already there
foreach my $new_key (qw /a y b/) {
    $obj->push ($new_key);
}
$key_count = $obj->keys;
is ($key_count, 3, 'adding existing keys has no effect');


#  now add some new keys
foreach my $new_key (qw /aa yy bb/) {
    $obj->push ($new_key);
}
$key_count = $obj->keys;
is ($key_count, 6, 'adding new keys has an effect');

#note "Keys are now " . join ' ', $obj->keys;

#  check the last key is moved into the deleted key's position
my $pos_b = $obj->get_key_pos ('b');
$obj->delete ('b');
is $obj->get_key_pos ('bb'), $pos_b, 'key bb is now where b was';
$obj->delete ('bb');
is $obj->get_key_pos ('yy'), $pos_b, 'key yy is now where b was';

is  $obj->delete ('fnorbleyorble'),
    undef,
    'deletion of non-existent key returns undef';

is $obj->get_key_at_pos (1000),
   undef,
   'got undef for positive out of bounds position call';

is $obj->get_key_at_pos (-20),
   undef,
   'got undef for negative out of bounds position call';

my $one_item = List::Unique::DeterministicOrder->new (
    data => ['a_key'],
);
$one_item->delete_key_at_pos (0);

is (scalar $one_item->keys, 0, 'empty list');

#  delete last entry
my $one_item_mk2 = List::Unique::DeterministicOrder->new (
    data => ['a_key'],
);
$one_item_mk2->delete ('a_key');
is (scalar $one_item_mk2->keys, 0, 'empty list');


#  boolean overload
ok (!$one_item, 'false boolean');
$one_item->push ('bazza');
$one_item->push ('shazza');
$one_item->push ('gazza');
ok ($one_item, 'true boolean');


#  clone
my $orig = List::Unique::DeterministicOrder->new(data => ['a' .. 'z']);
my $cloned = $orig->clone;
is_deeply $cloned, $orig, "Clone matches original";
isnt refaddr $cloned->[0], refaddr $orig->[0], "Cloned and original refs differ";
is blessed $cloned, blessed $orig, "Same package";

done_testing();
