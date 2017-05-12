# Base functionality tests

use Test::More tests => 21;
BEGIN { use_ok('List::MRU') };

my $MAX = 3;

my ($list);

# Constructor
ok(my $lm = List::MRU->new(max => $MAX), 'constructor okay');
is($lm->max,$MAX,'max ok');
is($lm->count,0,'count ok');

# add()
$lm->add('abc');
is($lm->count,1,'add 1, count ok');
$lm->add('def');
is($lm->count,2,'add 2, count ok');
$lm->add('ghi');
is($lm->count,3,'add 3, count ok');
$lm->add('jkl');
is($lm->count,$MAX,'add 4, count max');

# list()
is(join(',',$lm->list()),'jkl,ghi,def','list ok');

# additional permute adds
$lm->add('ghi');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'ghi,jkl,def','list ok');
$lm->add('ghi');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'ghi,jkl,def','list ok');
$lm->add('def');
is($lm->count,$MAX,'add, count max');
is(join(',',$lm->list()),'def,ghi,jkl','list ok');

# delete()
is($lm->delete('ghi'),'ghi','delete returns item');
is($lm->count,2,'count 2 after delete');
is(join(',',$lm->list()),'def,jkl','list ok');
is($lm->delete(item => 'def'),'def','delete via item returns item');
is($lm->count,1,'count 1 after delete');
is(join(',',$lm->list()),'jkl','list ok');

