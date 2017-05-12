use lib qw(t);
use Carp;
use Hash::AutoHash::AVPairsMulti;
use Test::More;
use Test::Deep;
use autohashUtil;

#################################################################################
# test exported functions
#################################################################################
# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsMulti;
is(ref $avp,'Hash::AutoHash::AVPairsMulti',
   "class is Hash::AutoHash::AVPairsMulti - sanity check");

my @imports=@Hash::AutoHash::AVPairsMulti::EXPORT_OK;
import Hash::AutoHash::AVPairsMulti @imports;
pass("import all functions");

my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21'); 
my($actual)=autohash_get($avp,qw(key1));
cmp_deeply($actual,['value11'],"autohash_get 1 key");
my @actual=autohash_get($avp,qw(key1 key2));
cmp_deeply(\@actual,[[qw(value11)],[qw(value21)]],"autohash_get 2 keys");
my @actual=autohash_get($avp,qw(key1 key3));
cmp_deeply(\@actual,[[qw(value11)],undef],"autohash_get 2 keys, 1 non-existant");

autohash_set($avp,key2=>'value22');
cmp_autohash('autohash_set existing key, single value',$avp,
	   {key1=>[qw(value11)],key2=>[qw(value21 value22)]});
autohash_set($avp,key1=>'value12',key1=>'value13');
cmp_autohash('autohash_set existing key, multiple values (repeated key form)',$avp,
	   {key1=>[qw(value11 value12 value13)],key2=>[qw(value21 value22)]});
autohash_set($avp,key2=>[qw(value23 value24)]);
cmp_autohash('autohash_set existing key, multiple values (ARRAY form)',$avp,
	   {key1=>[qw(value11 value12 value13)],key2=>[qw(value21 value22 value23 value24)]});
autohash_set($avp,key3=>[qw(value31)]);
cmp_autohash('autohash_set new key',$avp,
	   {key1=>[qw(value11 value12 value13)],key2=>[qw(value21 value22 value23 value24)],
	    key3=>[qw(value31)]});

autohash_set($avp,[qw(key3 key4)],[[qw(value32)],[qw(value41 value42)]]);
cmp_autohash('autohash_set (separate ARRAYs form)',$avp,
	   {key1=>[qw(value11 value12 value13)],key2=>[qw(value21 value22 value23 value24)],
	    key3=>[qw(value31 value32)],
	    key4=>[qw(value41 value42)]});

autohash_clear($avp);
cmp_autohash('autohash_clear',$avp,{});

my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21');
autohash_delete($avp,qw(key2));
cmp_autohash('autohash_delete 1 key',$avp,{key1=>[qw(value11)]});
my $avp=new Hash::AutoHash::AVPairsMulti (key0=>'value01',key1=>'value11',key2=>'value21');
autohash_delete($avp,qw(key0 key2));
cmp_autohash('autohash_delete 2 keys',$avp,{key1=>[qw(value11)]});
my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21');
autohash_delete($avp,qw(key2));
cmp_autohash('autohash_delete 2 keys, 1 non-existant',$avp,{key1=>[qw(value11)]});

my $actual1=autohash_exists($avp,'key1');
my $actual2=autohash_exists($avp,'key2');
ok($actual1,"autohash_exists: true");
ok(!$actual2,"autohash_exists: false");

my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21');
my %actual;
while (my($key,$value)=autohash_each($avp)) {
  $actual{$key}=$value;
}
cmp_deeply(\%actual,{key1=>[qw(value11)],key2=>[qw(value21)]},"autohash_each list context");
my @actual;
while (my $key=autohash_each($avp)) {
  push(@actual,$key);
}
cmp_set(\@actual,[qw(key1 key2)],"autohash_each scalar context");

my $avp=new Hash::AutoHash::AVPairsMulti (key1=>'value11',key2=>'value21');
my @actual=autohash_keys($avp);
cmp_set(\@actual,[qw(key1 key2)],"autohash_keys");

my @actual=autohash_values($avp);
cmp_set(\@actual,[[qw(value11)],[qw(value21)]],"autohash_values");

my $actual=autohash_count($avp);
is($actual,2,"autohash_count");

my $actual=autohash_empty($avp);
ok(!$actual,"autohash_empty: false");
my $actual=autohash_notempty($avp);
ok($actual,"autohash_notempty: true");

autohash_clear($avp);
my $actual=autohash_empty($avp);
ok($actual,"autohash_empty: true");
my $actual=autohash_notempty($avp);
ok(!$actual,"autohash_notempty: false");

# cannot test autohash_alias or autohash_tied here.
# must be imported at compile-time for prototype to work

done_testing();
