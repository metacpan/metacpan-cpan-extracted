use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsSingle;
use Test::More;
use Test::Deep;
use autohashUtil;

#$VERBOSE=1;			# cause sub-tests to print passes
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsSingle;
is(ref $avp,'Hash::AutoHash::AVPairsSingle',
   "class is Hash::AutoHash::AVPairsSingle - sanity check");

################################################################################
# test basic initialization and set/get
$avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11');
cmp_autohash("initialize one key",$avp,{key1=>'value11'});
$avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11',key2=>'value21');
cmp_autohash("initialize two keys",$avp,{key1=>'value11',key2=>'value21'});
$avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11',key1=>'value12',key1=>'value13');
cmp_autohash("initialize one key multiple times",$avp,{key1=>'value13'});

$avp->key1('value14');
cmp_autohash("update key via method",$avp,{key1=>'value14'});
$avp->key2('value21');
cmp_autohash("create key via method",$avp,{key1=>'value14',key2=>'value21'});

$avp->{key2}='value22';
cmp_autohash("update key via hash",$avp,{key1=>'value14',key2=>'value22'});
$avp->{key3}='value31';
cmp_autohash("create key via hash",$avp,{key1=>'value14',key2=>'value22',key3=>'value31'});

# args passed as ARRAY and HASH
$avp=new Hash::AutoHash::AVPairsSingle([key1=>'value11',key2=>'value21']);
cmp_autohash("args passed as ARRAY",$avp,{key1=>'value11',key2=>'value21'});
$avp=new Hash::AutoHash::AVPairsSingle({key1=>'value11',key2=>'value21'});
cmp_autohash("args passed via hash",$avp,{key1=>'value11',key2=>'value21'});

# NG 09-10-12: tests below were holdover from MultiValued.  Not correct here
# # non-existent key should return nothing. (not undef);
# $avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11');
# @list=($avp->key0);
# is(scalar @list,0,"non-existent key");
# # non-existent key should return nothing (not undef) but Perl doesn't do it this way!
# $avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11');
# @list=($avp->{key0});
# is(scalar @list,1,"$label non-existent key via hash");

# non-existent key should return undef
$avp=new Hash::AutoHash::AVPairsSingle(key1=>'value11');
my $value=$avp->key0;
is($value,undef,"non-existent key via method: scalar context");
my @list=($avp->key0);
is(scalar @list,1,"non-existent key via method: array context");
my $value=$avp->{key0};
is($value,undef,"non-existent key via hash: scalar context");
my @list=($avp->{key0});
is(scalar @list,1,"non-existent key via hash: array context");

done_testing();
