use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsMulti;
use Test::More;
use Test::Deep;
use autohashUtil;

#$VERBOSE=1;			# cause sub-tests to print passes
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsMulti;
is(ref $avp,'Hash::AutoHash::AVPairsMulti',
   "class is Hash::AutoHash::AVPairsMulti - sanity check");

################################################################################
# test basic initialization and set/get
$avp=new Hash::AutoHash::AVPairsMulti(key1=>'value11');
cmp_autohash("initialize one key. single value",$avp,{key1=>[qw(value11)]});
$avp=new Hash::AutoHash::AVPairsMulti(key1=>'value11',
				   key2=>'value21',key2=>'value22',
				   key3=>[qw(value31 value32 value33)],
				   key4=>[qw(value41)]);
cmp_autohash("initialize multiple keys. single and multiple values",$avp,
	     {key1=>[qw(value11)],
	      key2=>[qw(value21 value22)],
	      key3=>[qw(value31 value32 value33)],
	      key4=>[qw(value41)]});

$avp->key1('value12');
$avp->key2('value23');
$avp->key3('value34','value35');
$avp->key4([qw(value42 value43)]);
cmp_autohash("update single and multiple values",$avp,
	     {key1=>[qw(value11 value12)],
	      key2=>[qw(value21 value22 value23)],
	      key3=>[qw(value31 value32 value33 value34 value35)],
	      key4=>[qw(value41 value42 value43)]});

$avp->key5('value51');
cmp_autohash("create new key",$avp,
	     {key1=>[qw(value11 value12)],
	      key2=>[qw(value21 value22 value23)],
	      key3=>[qw(value31 value32 value33 value34 value35)],
	      key4=>[qw(value41 value42 value43)],
	      key5=>[qw(value51)]});

# args passed as ARRAY and HASH
$avp=new Hash::AutoHash::AVPairsMulti([key1=>'value11',
				    key2=>'value21',key2=>'value22',
				    key3=>[qw(value31 value32 value33)],
				    key4=>[qw(value41)]]);
cmp_autohash("args passed as ARRAY",$avp,
	     {key1=>[qw(value11)],
	      key2=>[qw(value21 value22)],
	      key3=>[qw(value31 value32 value33)],
	      key4=>[qw(value41)]});
$avp=new Hash::AutoHash::AVPairsMulti({key1=>'value11',
				    key2=>['value21','value22'],
				    key3=>[qw(value31 value32 value33)],
				    key4=>[qw(value41)]});
cmp_autohash("args passed as HASH",$avp,
	     {key1=>[qw(value11)],
	      key2=>[qw(value21 value22)],
	      key3=>[qw(value31 value32 value33)],
	      key4=>[qw(value41)]});

# illegal (reference) values
eval {$avp=new Hash::AutoHash::AVPairsMulti key1=>{key11=>'value11'}};
ok($@=~/Trying to store reference/,'ILLEGAL. setting top-level reference via new');
eval {$avp=new Hash::AutoHash::AVPairsMulti key1=>[['value11','value12']]};
ok($@=~/Trying to store reference/,'ILLEGAL. setting nested ARRAY reference via new');
eval {$avp=new Hash::AutoHash::AVPairsMulti key1=>[{key11=>'value11'}]};
ok($@=~/Trying to store reference/,'ILLEGAL. setting nested HASH reference via new');
$avp=new Hash::AutoHash::AVPairsMulti;
eval {$avp->key1({key11=>'value11'})};
ok($@=~/Trying to store reference/,'ILLEGAL. setting  top-level reference via method');
eval {$avp->key1([['value11','value12']])};
ok($@=~/Trying to store reference/,'ILLEGAL. setting  nested ARRAY reference via method');
eval {$avp->key1([{key11=>'value11'}])};
ok($@=~/Trying to store reference/,'ILLEGAL. setting  nested HASH reference via method');

# non-existent key should return nothing. (not undef);
$avp=new Hash::AutoHash::AVPairsMulti(key1=>'value11');
@list=($avp->key0);
is(scalar @list,0,"non-existent key");
# non-existent key should return nothing (not undef) but Perl doesn't do it this way!
$avp=new Hash::AutoHash::AVPairsMulti(key1=>'value11');
@list=($avp->{key0});
is(scalar @list,1,"$label non-existent key via hash");

################################################################################
# test unique & filter
$avp=new Hash::AutoHash::AVPairsMulti(key1=>[qw(value11 value11)]);
cmp_autohash("initialize key with duplicate",$avp,{key1=>[qw(value11 value11)]});
ok(!tied(%$avp)->unique,"unique initially false");
ok(tied(%$avp)->unique(1),"set unique to true");
cmp_autohash("key now unique",$avp,{key1=>[qw(value11)]});
$avp->key1('value11');
cmp_autohash("key still unique after storing duplicate",$avp,{key1=>[qw(value11)]});
$avp=new Hash::AutoHash::AVPairsMulti(key1=>[qw(value10 value11 VALUE11 value12)]);
ok(tied(%$avp)->unique(sub {lc($_[0]) eq lc($_[1])}),"set unique to sub");
cmp_autohash("key now unique",$avp,{key1=>[qw(value10 value11 value12)]});

$avp=new Hash::AutoHash::AVPairsMulti(key1=>[qw(value11 value11)]);
cmp_autohash("initialize key with duplicate",$avp,{key1=>[qw(value11 value11)]});
ok(!tied(%$avp)->filter,"filter initially false");
ok(tied(%$avp)->filter(1),"set filter to true");
cmp_autohash("key now unique",$avp,{key1=>[qw(value11)]});
$avp->key1('value11');
cmp_autohash("key not unique after storing duplicate",$avp,{key1=>[qw(value11 value11)]});

$avp=new Hash::AutoHash::AVPairsMulti(key1=>[qw(value11 value11)]);
ok(tied(%$avp)->filter(sub {map {uc $_} @_}),"set filter to sub");
cmp_autohash("values transformed by filter",$avp,{key1=>[qw(VALUE11 VALUE11)]});

done_testing();
