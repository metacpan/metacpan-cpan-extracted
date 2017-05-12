use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsSingle qw(autohash_alias);
use Test::More;
use Test::Deep;
use autohashUtil;

#################################################################################
# test alias. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsSingle;
is(ref $avp,'Hash::AutoHash::AVPairsSingle',
   "class is Hash::AutoHash::AVPairsSingle - sanity check");

my %hash;
my $avp=new Hash::AutoHash::AVPairsSingle (key1=>'value11',key2=>'value21');
autohash_alias($avp,%hash);
cmp_autohash('autohash_alias initial values',$avp,
	   {key1=>'value11',key2=>'value21'},'hash',undef,\%hash);

$hash{'key2'}='value22';
$hash{'key3'}='value31';
cmp_autohash('autohash_alias after update hash',$avp,
	   {key1=>'value11',key2=>'value22',key3=>'value31'},'hash',undef,\%hash);

$avp->key3('value32');
$avp->key4('value41');
cmp_autohash('autohash_alias after update mvhhash',$avp,
	   {key1=>'value11',key2=>'value22',
	    key3=>'value32',key4=>'value41'},'hash',undef,\%hash);

done_testing();
