use lib qw(t);
use Carp;
use Hash::AutoHash::Record;
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test exported functions
#################################################################################
# test object class for sanity sake
my $record=new Hash::AutoHash::Record;
is(ref $record,'Hash::AutoHash::Record',
   "class is Hash::AutoHash::Record - sanity check");

my @imports=@Hash::AutoHash::Record::EXPORT_OK;
import Hash::AutoHash::Record @imports;
pass("import all functions");

my $record=new Hash::AutoHash::Record (single=>'value11',multi=>['value21']); 
my($actual)=autohash_get($record,qw(single));
cmp_deeply($actual,'value11',"autohash_get 1 key");
my @actual=autohash_get($record,qw(single multi));
cmp_deeply(\@actual,['value11',[qw(value21)]],"autohash_get 2 keys");
my @actual=autohash_get($record,qw(single key3));
cmp_deeply(\@actual,['value11',undef],"autohash_get 2 keys, 1 non-existant");

autohash_set($record,multi=>'value22');
cmp_record('autohash_set existing key, single value',$record,
	   {single=>'value11',multi=>[qw(value21 value22)]});
autohash_set($record,multi=>'value23',multi=>'value24');
cmp_record('autohash_set existing key, multiple values (repeated key form)',$record,
	   {single=>'value11',multi=>[qw(value21 value22 value23 value24)]});
autohash_set($record,multi=>[qw(value25 value26)]);
cmp_record('autohash_set existing key, multiple values (ARRAY form)',$record,
	   {single=>'value11',multi=>[qw(value21 value22 value23 value24 value25 value26)]});
autohash_set($record,avp_single=>{attr31=>'value311'});
cmp_record('autohash_set new key',$record,
	   {single=>'value11',multi=>[qw(value21 value22 value23 value24 value25 value26)],
	    avp_single=>new_SV(attr31=>'value311')});

autohash_set($record,[qw(avp_single avp_multi)],
	     [[attr31=>'value312',attr32=>'value32'],
	      {attr4=>[qw(value41 value42)]}]);
cmp_record('autohash_set (separate ARRAYs form)',$record,
	   {single=>'value11',multi=>[qw(value21 value22 value23 value24 value25 value26)],
	    avp_single=>new_SV(attr31=>'value312',attr32=>'value32'),
	    avp_multi=>new_MV(attr4=>[qw(value41 value42)])});
autohash_clear($record);
cmp_record('autohash_clear restores initial value',$record,
	   {single=>'value11',multi=>['value21']});
# test clearing of specific keys.
my $record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record);
autohash_set($record,
	     new_single=>'new_value',
	     single=>'value1',multi=>['value1'],
	     avp_single=>{key1=>'value1'},avp_multi=>{key1=>'value1'},
             nested=>[key1=>'value1']);
cmp_record("autohash_set all fields + 1 new field ",$record,
	   {new_single=>'new_value',
	    single=>'value1',multi=>['value1'],
	    avp_single=>new_SV(key1=>'value1'),avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');
autohash_clear($record,qw(single));
cmp_record('autohash_clear 1 key',$record,
	   {new_single=>'new_value',
	    single=>'',multi=>['value1'],
	    avp_single=>new_SV(key1=>'value1'),avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');
autohash_clear($record,qw(multi avp_single));
cmp_record('autohash_clear 2 keys',$record,
	   {new_single=>'new_value',
	    single=>'',multi=>[],avp_single=>new_SV,
	    avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');
autohash_clear($record,qw(new_single));
cmp_record('autohash_clear key w/o default',$record,
	   {new_single=>undef,
	    single=>'',multi=>[],avp_single=>new_SV,
	    avp_multi=>new_MV(key1=>'value1'),
	    nested=>new_Nested(key1=>'value1')},
	   undef,undef,'types');

my $record=new Hash::AutoHash::Record (single=>'value11',multi=>'value21');
autohash_delete($record,qw(multi));
cmp_record('autohash_delete 1 key',$record,{single=>'value11'});
my $record=new Hash::AutoHash::Record (key0=>'value01',single=>'value11',multi=>'value21');
autohash_delete($record,qw(key0 multi));
cmp_record('autohash_delete 2 keys',$record,{single=>'value11'});
my $record=new Hash::AutoHash::Record (single=>'value11',multi=>'value21');
autohash_delete($record,qw(key1 multi));
cmp_record('autohash_delete 2 keys, 1 non-existant',$record,{single=>'value11'});

my $actual1=autohash_exists($record,'single');
my $actual2=autohash_exists($record,'multi');
ok($actual1,"autohash_exists: true");
ok(!$actual2,"autohash_exists: false");

my $record=new Hash::AutoHash::Record (single=>'value11',multi=>['value21']);
my %actual;
while (my($key,$value)=autohash_each($record)) {
  $actual{$key}=$value;
}
cmp_deeply(\%actual,{single=>'value11',multi=>[qw(value21)]},"autohash_each list context");
my @actual;
while (my $key=autohash_each($record)) {
  push(@actual,$key);
}
cmp_set(\@actual,[qw(single multi)],"autohash_each scalar context");

my $record=new Hash::AutoHash::Record (single=>'value11',multi=>['value21']);
my @actual=autohash_keys($record);
cmp_set(\@actual,[qw(single multi)],"autohash_keys");

my @actual=autohash_values($record);
cmp_set(\@actual,['value11',[qw(value21)]],"autohash_values");

my $actual=autohash_count($record);
is($actual,2,"autohash_count");

my $actual=autohash_empty($record);
ok(!$actual,"autohash_empty: false");
my $actual=autohash_notempty($record);
ok($actual,"autohash_notempty: true");

autohash_delete($record,autohash_keys($record));
my $actual=autohash_empty($record);
ok($actual,"autohash_empty: true");
my $actual=autohash_notempty($record);
ok(!$actual,"autohash_notempty: false");

# cannot test autohash_alias or autohash_tied here.
# must be imported at compile-time for prototype to work

done_testing();
