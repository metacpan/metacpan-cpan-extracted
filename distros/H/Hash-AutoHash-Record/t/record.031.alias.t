use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_alias);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test alias. can't be tested in 030.functions because it has to be imported at
# compile-time for prototype to work
#################################################################################
# test object class for sanity sake
my $record=new Hash::AutoHash::Record;
is(ref $record,'Hash::AutoHash::Record',
   "class is Hash::AutoHash::Record - sanity check");

my %hash;
my $record=new Hash::AutoHash::Record (key1=>'value11',key2=>'value21');
autohash_alias($record,%hash);
cmp_record('autohash_alias initial values',$record,
	   {key1=>'value11',key2=>'value21'},
	   \%hash);

$hash{'key2'}='value22';
$hash{'key3'}='value31';
cmp_record('autohash_alias after update hash',$record,
	   {key1=>'value11',key2=>'value22',key3=>'value31'},
	   \%hash);

$record->key3('value32');
$record->key4('value41');
cmp_record('autohash_alias after update mvhhash',$record,
	   {key1=>'value11',key2=>'value22',
	    key3=>'value32',key4=>'value41'},
	   \%hash);

done_testing();
