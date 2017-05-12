# uuid tests

use Test::More tests => 22;
BEGIN { use_ok('List::MRU') };

my $MAX = 3;

my ($list, $item, $uuid);

# Constructor
ok(my $lm = List::MRU->new(max => $MAX, uuid => 1), 'constructor okay');
is($lm->max,$MAX,'max ok');
is($lm->uuid,1,'uuid ok');
is($lm->count,0,'count ok');

# add()
$lm->add('abc', 'abc');
is($lm->count,1,'add 1, count ok');
$lm->add('def', 'def');
is($lm->count,2,'add 2, count ok');
$lm->add('ghi', 'ghi');
is($lm->count,3,'add 3, count ok');
$lm->add('jkl', 'jkl');
is($lm->count,$MAX,'add 4, count max');

# list()
is(join(',',$lm->list()),'jkl,ghi,def','list ok');

my $count = 0;
while (($item, $uuid) = $lm->each) {
  $count++;
}
is($lm->count,$MAX,'each count ok');

# permute adds via uuid
$lm->add('GHI', 'ghi');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'GHI,jkl,def','list ok');
$lm->add('ghia', 'ghi');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'ghia,jkl,def','list ok');
$lm->add('DEF', 'def');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'DEF,ghia,jkl','list ok');
$lm->add('JKL', 'jkl');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'JKL,DEF,ghia','list ok');

# Delete
is($lm->delete(uuid => 'jkl'),'JKL','delete returns item');
is($lm->count,2,'count 2 after delete');
is(join(',',$lm->list()),'DEF,ghia','list ok');

# Dump
while (($item, $uuid) = $lm->each) {
  print "$item, $uuid\n";
}

