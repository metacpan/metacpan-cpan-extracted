use lib qw(t);
use Carp;
use Hash::AutoHash::MultiValued;
use Test::More;
use Test::Deep;
use mvhashUtil;

#$VERBOSE=1;			# cause sub-tests to print passes
# test object class for sanity sake
my $mvhash=new Hash::AutoHash::MultiValued;
is(ref $mvhash,'Hash::AutoHash::MultiValued',
   "class is Hash::AutoHash::MultiValued - sanity check");

################################################################################
# test basic initialization and set/get
$mvhash=new Hash::AutoHash::MultiValued(key1=>'value11');
cmp_mvhash("initialize one key. single value",$mvhash,{key1=>[qw(value11)]});
$mvhash=new Hash::AutoHash::MultiValued(key1=>'value11',
					key2=>'value21',key2=>'value22',
					key3=>[qw(value31 value32 value33)],
					key4=>[qw(value41)]);
cmp_mvhash("initialize multiple keys. single and multiple values",$mvhash,
	   {key1=>[qw(value11)],
	    key2=>[qw(value21 value22)],
	    key3=>[qw(value31 value32 value33)],
	    key4=>[qw(value41)]});

$mvhash->key1('value12');
$mvhash->key2('value23');
$mvhash->key3('value34','value35');
$mvhash->key4([qw(value42 value43)]);
cmp_mvhash("update single and multiple values",$mvhash,
	   {key1=>[qw(value11 value12)],
	    key2=>[qw(value21 value22 value23)],
	    key3=>[qw(value31 value32 value33 value34 value35)],
	    key4=>[qw(value41 value42 value43)]});

$mvhash->key5('value51');
cmp_mvhash("create new key",$mvhash,
	   {key1=>[qw(value11 value12)],
	    key2=>[qw(value21 value22 value23)],
	    key3=>[qw(value31 value32 value33 value34 value35)],
	    key4=>[qw(value41 value42 value43)],
	    key5=>[qw(value51)]});

# args passed as ARRAY and HASH
$mvhash=new Hash::AutoHash::MultiValued([key1=>'value11',
					 key2=>'value21',key2=>'value22',
					 key3=>[qw(value31 value32 value33)],
					 key4=>[qw(value41)]]);
cmp_mvhash("args passed as ARRAY",$mvhash,
	   {key1=>[qw(value11)],
	    key2=>[qw(value21 value22)],
	    key3=>[qw(value31 value32 value33)],
	    key4=>[qw(value41)]});
$mvhash=new Hash::AutoHash::MultiValued({key1=>'value11',
					 key2=>['value21','value22'],
					 key3=>[qw(value31 value32 value33)],
					 key4=>[qw(value41)]});
cmp_mvhash("args passed as HASH",$mvhash,
	   {key1=>[qw(value11)],
	    key2=>[qw(value21 value22)],
	    key3=>[qw(value31 value32 value33)],
	    key4=>[qw(value41)]});


# non-existent key should return nothing. (not undef);
$mvhash=new Hash::AutoHash::MultiValued(key1=>'value11');
@list=($mvhash->key0);
is(scalar @list,0,"non-existent key");
# non-existent key should return nothing (not undef) but Perl doesn't do it this way!
$mvhash=new Hash::AutoHash::MultiValued(key1=>'value11');
@list=($mvhash->{key0});
is(scalar @list,1,"$label non-existent key via hash");

################################################################################
# test unique & filter
$mvhash=new Hash::AutoHash::MultiValued(key1=>[qw(value11 value11)]);
cmp_mvhash("initialize key with duplicate",$mvhash,{key1=>[qw(value11 value11)]});
ok(!tied(%$mvhash)->unique,"unique initially false");
ok(tied(%$mvhash)->unique(1),"set unique to true");
cmp_mvhash("key now unique",$mvhash,{key1=>[qw(value11)]});
$mvhash->key1('value11');
cmp_mvhash("key still unique after storing duplicate",$mvhash,{key1=>[qw(value11)]});
$mvhash=new Hash::AutoHash::MultiValued(key1=>[qw(value10 value11 VALUE11 value12)]);
ok(tied(%$mvhash)->unique(sub {lc($_[0]) eq lc($_[1])}),"set unique to sub");
cmp_mvhash("key now unique",$mvhash,{key1=>[qw(value10 value11 value12)]});

$mvhash=new Hash::AutoHash::MultiValued(key1=>[qw(value11 value11)]);
cmp_mvhash("initialize key with duplicate",$mvhash,{key1=>[qw(value11 value11)]});
ok(!tied(%$mvhash)->filter,"filter initially false");
ok(tied(%$mvhash)->filter(1),"set filter to true");
cmp_mvhash("key now unique",$mvhash,{key1=>[qw(value11)]});
$mvhash->key1('value11');
cmp_mvhash("key not unique after storing duplicate",$mvhash,{key1=>[qw(value11 value11)]});

$mvhash=new Hash::AutoHash::MultiValued(key1=>[qw(value11 value11)]);
ok(tied(%$mvhash)->filter(sub {map {uc $_} @_}),"set filter to sub");
cmp_mvhash("values transformed by filter",$mvhash,{key1=>[qw(VALUE11 VALUE11)]});

done_testing();
