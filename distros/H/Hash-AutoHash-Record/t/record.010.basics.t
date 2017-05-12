use lib qw(t);
use Carp;
use Hash::AutoHash::Record;
use Test::More;
use Test::Deep;
use recordUtil;

##### TBD: defaults, force
##### TBD: new avp stuff


#$VERBOSE=1;			# cause sub-tests to print passes
# test object class for sanity sake
my $record=new Hash::AutoHash::Record;
is(ref $record,'Hash::AutoHash::Record',"class is Hash::AutoHash::Record - sanity check");

################################################################################
### basic initialization, set/get, clear
$record=new Hash::AutoHash::Record(single=>'');
cmp_record("create empty single",$record,{single=>''},undef,undef,'types','values');
$record->single('value1');
cmp_record("set single",$record,{single=>'value1'},undef,undef,'types','values');
my $actual=$record->single;
is($actual,'value1','get single');
%$record=();
cmp_record("clear single",$record,{single=>''},undef,undef,'types','values');

$record=new Hash::AutoHash::Record(multi=>[]);
cmp_record("create empty multi",$record,{multi=>[]},undef,undef,'types','values');
$record->multi('value1');
cmp_record("set multi 1 value",$record,{multi=>['value1']},undef,undef,'types','values');
my $actual=$record->multi;
cmp_deeply($actual,['value1'],'get multi 1 value');
$record->multi('value2','value3');
cmp_record("set multi 2 values",$record,
	   {multi=>['value1','value2','value3']},
	   undef,undef,'types','values');
my $actual=$record->multi;
cmp_deeply($actual,['value1','value2','value3'],'get multi now 3 values');
$record->multi(['value4','value5','value6']);
cmp_record("set multi ARRAY 3 values",$record,
	   {multi=>['value1','value2','value3','value4','value5','value6']},
	   undef,undef,'types','values');
my $actual=$record->multi;
cmp_deeply($actual,['value1','value2','value3','value4','value5','value6'],
	   'get multi now 6 values');
%$record=();
cmp_record("clear multi",$record,{multi=>[]},undef,undef,'types','values');

$record=new Hash::AutoHash::Record(avp_single=>{});
cmp_record("create empty avp_single",$record,{avp_single=>new_SV},undef,undef,'types','values');
$record->avp_single(key1=>'value11');
cmp_record("set avp_single 1 avp",$record,
	   {avp_single=>new_SV(key1=>'value11')},
	   undef,undef,'types','values');
my $actual=$record->avp_single;
cmp_deeply($actual,new_SV(key1=>'value11'),'get avp_single 1 avp');
$record->avp_single(key1=>'value12',key2=>'value21');
cmp_record("set avp_single 2 avps",$record,
	   {avp_single=>new_SV(key1=>'value12',key2=>'value21')},
	   undef,undef,'types','values');
my $actual=$record->avp_single;
cmp_deeply($actual,new_SV(key1=>'value12',key2=>'value21'),'get avp_single 2 avps');
%$record=();
cmp_record("clear avp_single",$record,{avp_single=>new_SV},undef,undef,'types','values');

$record=new Hash::AutoHash::Record(avp_multi=>\{});
cmp_record("create empty avp_multi",$record,{avp_multi=>new_MV},undef,undef,'types','values');
$record->avp_multi(key1=>'value11');
cmp_record("set avp_multi 1 avp",$record,
	   {avp_multi=>new_MV(key1=>'value11')},
	   undef,undef,'types','values');
my $actual=$record->avp_multi;
cmp_deeply($actual,new_MV(key1=>'value11'),'get avp_multi 1 avp');
$record->avp_multi(key1=>'value12',key2=>'value21');
cmp_record("set avp_multi 2 avps",$record,
	   {avp_multi=>new_MV(key1=>['value11','value12'],key2=>'value21')},
	   undef,undef,'types','values');
my $actual=$record->avp_multi;
cmp_deeply($actual,new_MV(key1=>['value11','value12'],key2=>'value21'),'get avp_multi 2 avps');
$record->avp_multi(key1=>['value13'],key2=>['value22','value23'],
		   key3=>['value31','value32','value33']);
cmp_record("set avp_multi 3 avps ARRAY",$record,
	   {avp_multi=>new_MV(key1=>['value11','value12','value13'],
			      key2=>['value21','value22','value23'],
			      key3=>['value31','value32','value33'])},
	   undef,undef,'types','values');
my $actual=$record->avp_multi;
cmp_deeply($actual,new_MV(key1=>['value11','value12','value13'],
			  key2=>['value21','value22','value23'],
			  key3=>['value31','value32','value33']),
	   'get avp_multi 3 avps ARRAY');
%$record=();
cmp_record("clear avp_multi",$record,{avp_multi=>new_MV},undef,undef,'types','values');

$record=new Hash::AutoHash::Record(nested=>new Hash::AutoHash::Record);
cmp_record("create empty nested",$record,{nested=>new_Nested},undef,undef,'types','values');
$record->nested(key1=>'value1');
cmp_record("set nested 1 key",$record,
	   {nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types','values');
my $actual=$record->nested;
cmp_deeply($actual,new_Nested(key1=>'value1'),'get nested 1 key');
$record->nested(key2=>'value2',key3=>'value3');
cmp_record("set nested 2 keys",$record,
	   {nested=>new_Nested(key1=>'value1',key2=>'value2',key3=>'value3')},
	   undef,undef,'types','values');
my $actual=$record->nested;
cmp_deeply($actual,new_Nested(key1=>'value1',key2=>'value2',key3=>'value3'),
	   'get nested now 3 keys');
%$record=();
cmp_record("clear nested",$record,{nested=>new_Nested},undef,undef,'types','values');

$record=new Hash::AutoHash::Record(hash_normal=>{key=>\'value1'});
cmp_record("create hash_normal",$record,{hash_normal=>{key=>\'value1'}},undef,undef,'types');
$record->hash_normal({key=>'value2'});
cmp_record("set hash_normal",$record,{hash_normal=>{key=>'value2'}},undef,undef,'types');
my $actual=$record->hash_normal;
cmp_deeply($actual,{key=>'value2'},'get hash_normal');
%$record=();
cmp_record("clear hash_normal",$record,{hash_normal=>{key=>\'value1'}},undef,undef,'types');

$record=new Hash::AutoHash::Record(hash_workaround=>bless({key=>'value1'}));
cmp_record("create hash_workaround",$record,
	   {hash_workaround=>bless({key=>'value1'})},undef,undef,'types');
$record->hash_workaround({key=>'value2'});
cmp_record("set hash_workaround",$record,{hash_workaround=>{key=>'value2'}},undef,undef,'types');
my $actual=$record->hash_workaround;
cmp_deeply($actual,{key=>'value2'},'get hash_workaround');
%$record=();
cmp_record("clear hash_workaround",$record,
	   {hash_workaround=>bless({key=>'value1'})},undef,undef,'types');

$record=new Hash::AutoHash::Record(refhash=>\bless({key=>'value1'}));
cmp_record("create refhash",$record,
	   {refhash=>\bless({key=>'value1'})},undef,undef,'types');
$record->refhash(\{key=>'value2'});
cmp_record("set refhash",$record,{refhash=>\{key=>'value2'}},undef,undef,'types');
my $actual=$record->refhash;
cmp_deeply($actual,\{key=>'value2'},'get refhash');
%$record=();
cmp_record("clear refhash",$record,
	   {refhash=>\bless({key=>'value1'})},undef,undef,'types');

$record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record);
cmp_record("create empty all usual types",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested},
	   undef,undef,'types','values');
$record->single('value1');
$record->multi('value1');
$record->avp_single(key1=>'value1');
$record->avp_multi(key1=>'value1');
$record->nested(key1=>'value1');
cmp_record("set all usual types",$record,
	   {single=>'value1',multi=>['value1'],
	    avp_single=>new_SV(key1=>'value1'),avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types','values');
%$record=();
cmp_record("clear all usual types",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested},
	   undef,undef,'types','values');

$record=new Hash::AutoHash::Record
  (single=>'value1',multi=>['value1'],
   avp_single=>{key1=>'value1'},avp_multi=>\{key1=>'value1'},
  nested=>new Hash::AutoHash::Record(key1=>'value1'));
cmp_record("create all usual types non-empty defaults",$record,
	   {single=>'value1',multi=>['value1'],
	    avp_single=>new_SV(key1=>'value1'),avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');
$record->single('value2');
$record->multi('value2');
$record->avp_single(key1=>'value2');
$record->avp_multi(key1=>'value2');
$record->nested(key1=>'value2');
cmp_record("set all usual types non-empty default",$record,
	   {single=>'value2',multi=>['value1','value2'],
	    avp_single=>new_SV(key1=>'value2'),avp_multi=>new_MV(key1=>['value1','value2']),
	    nested=>new_Nested(key1=>'value2')},
	   undef,undef,'types');
%$record=();
cmp_record("clear all usual types non-empty default",$record,
	   {single=>'value1',multi=>['value1'],
	    avp_single=>new_SV(key1=>'value1'),avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');

# avp_multi set as HASH
$record=new Hash::AutoHash::Record (avp_multi=>{key1=>['value1']});
cmp_record("create avp_multi as HASH",$record,{avp_multi=>new_MV(key1=>'value1')},
	   undef,undef,'types');
%$record=();
cmp_record("clear avp_multi as HASH",$record,{avp_multi=>new_MV(key1=>'value1')},
	   undef,undef,'types');

## args passed as ARRAY and HASH
$record=new Hash::AutoHash::Record
  ([single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record]);
cmp_record("args passed as ARRAY",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested},
	   undef,undef,'types','values');
$record=new Hash::AutoHash::Record
  ({single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record});
cmp_record("args passed as HASH",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested},
	   undef,undef,'types','values');

# NG 09-10-12: tests below were holdover from MultiValued.  Not correct here
# # non-existent key should return nothing. (not undef);
# $record=new Hash::AutoHash::Record(key1=>'value11');
# @list=($record->key0);
# is(scalar @list,0,"non-existent key");
# # non-existent key should return nothing (not undef) but Perl doesn't do it this way!
# @list=($record->{key0});
# is(scalar @list,1,"non-existent key via hash");

# non-existent key should return undef;
$record=new Hash::AutoHash::Record(key1=>'value11');
my $value=$record->key0;
is($value,undef,"non-existent key via method: scalar context");
my @list=($record->key0);
is(scalar @list,1,"non-existent key via method");
my $value=$record->{key0};
is($value,undef,"non-existent key via hash: scalar context");
my @list=($record->{key0});
is(scalar @list,1,"non-existent key via hash");

done_testing();
