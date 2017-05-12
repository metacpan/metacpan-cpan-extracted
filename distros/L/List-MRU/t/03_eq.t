# Test eq sub support

use Test::More tests => 9;
BEGIN { use_ok('List::MRU') };

my $MAX = 3;

my ($lm, $list);

# Fatals
ok(! defined eval { $lm = List::MRU->new(max => $MAX, eq => 123) }, 
  "die on bogus 'eq' (scalar)");
ok(! defined eval { $lm = List::MRU->new(max => $MAX, eq => []) },
  "die on bogus 'eq' (arrayref)");

# Constructor
ok($lm = List::MRU->new(max => $MAX, eq => sub { lc $_[0] eq lc $_[1] }), 
  'constructor with lc eq ok');

$lm->add('abc');
is($lm->count,1,'add 1, count ok');
$lm->add('def');
is($lm->count,2,'add 2, count ok');
is(join(',',$lm->list()),'def,abc','list ok');
$lm->add('ABC');
is($lm->count,2,'add uc variant, count still 2');
is(join(',',$lm->list()),'ABC,def','list ok');

