# Various error case tests

use Test::More tests => 11;
BEGIN { use_ok('List::MRU') };

my ($lm, @list);

# Fatals
ok(eval { $lm = List::MRU->new(max => 3) }, 'standard constructor ok');
ok(! defined eval { List::MRU->new() }, 'die on missing max arg');
ok(! defined eval { List::MRU->new(max => 'abc') }, 'die on non-numeric max arg');
ok(! defined eval { List::MRU->new(max => 2.3) }, 'die on non-integer max arg');
ok(! defined eval { List::MRU->new(max => -5) }, 'die on negative max');

ok(! defined eval { $lm->add }, 'die on add with no item');
ok(! defined eval { $lm->delete }, 'die on delete with no item');

# Corner cases
ok($lm = eval { List::MRU->new(max => 0) }, 'zero sized constructor ok');
$lm->add('abc');
is($lm->count,0,'add 1, count zero');
@list = $lm->list;
is(scalar(@list),0,'list returns ()');

