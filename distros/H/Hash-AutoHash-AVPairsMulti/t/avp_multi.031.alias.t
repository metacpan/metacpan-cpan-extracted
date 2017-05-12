use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsMulti qw(autohash_alias);
use Test::More;
use Test::Deep;
use autohashUtil;

#################################################################################
# test alias. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsMulti;
is(ref $avp,'Hash::AutoHash::AVPairsMulti',
   "class is Hash::AutoHash::MultiValued - sanity check");

my %hash;
my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21');
autohash_alias($avp,%hash);
cmp_autohash('autohash_alias initial values',$avp,
	   {key1=>[qw(value11)],key2=>[qw(value21)]},
	   'hash',undef,\%hash);

$hash{'key2'}='value22';
$hash{'key3'}='value31';
cmp_autohash('autohash_alias after update hash',$avp,
	   {key1=>[qw(value11)],key2=>[qw(value21 value22)],key3=>[qw(value31)]},
	   'hash',undef,\%hash);

$avp->key3('value32');
$avp->key4('value41');
cmp_autohash('autohash_alias after update mvhhash',$avp,
	   {key1=>[qw(value11)],key2=>[qw(value21 value22)],
	    key3=>[qw(value31 value32)],key4=>[qw(value41)]},
	   'hash',undef,\%hash);

done_testing();
