use lib qw(t);
use Carp;
use Hash::AutoHash::MultiValued qw(autohash_alias);
use Test::More;
use Test::Deep;
use mvhashUtil;

#################################################################################
# test alias. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $mvhash=new Hash::AutoHash::MultiValued;
is(ref $mvhash,'Hash::AutoHash::MultiValued',
   "class is Hash::AutoHash::MultiValued - sanity check");

my %hash;
my $mvhash=new Hash::AutoHash::MultiValued (key1=>'value11',key2=>'value21');
autohash_alias($mvhash,%hash);
cmp_mvhash('autohash_alias initial values',$mvhash,
	   {key1=>[qw(value11)],key2=>[qw(value21)]},
	   'hash',undef,\%hash);

$hash{'key2'}='value22';
$hash{'key3'}='value31';
cmp_mvhash('autohash_alias after update hash',$mvhash,
	   {key1=>[qw(value11)],key2=>[qw(value21 value22)],key3=>[qw(value31)]},
	   'hash',undef,\%hash);

$mvhash->key3('value32');
$mvhash->key4('value41');
cmp_mvhash('autohash_alias after update mvhhash',$mvhash,
	   {key1=>[qw(value11)],key2=>[qw(value21 value22)],
	    key3=>[qw(value31 value32)],key4=>[qw(value41)]},
	   'hash',undef,\%hash);

done_testing();
