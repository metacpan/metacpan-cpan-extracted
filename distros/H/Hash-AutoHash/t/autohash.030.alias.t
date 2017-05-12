################################################################################
# test all constructor functions except autohash_new
################################################################################
use lib qw(t);
use strict;
use Carp;
use Test::More;
# use Test::More qw/no_plan/;
# use Test::Deep;
use autohashUtil;
require 'autohash.01x.constructors.pm';
require 'autohash.TieMV.pm';	# example tied hash class
use Hash::AutoHash qw(autohash_hash autohash_tie 
			      autohash_wrap autohash_wrapobj autohash_wraptie);
use Hash::AutoHash qw(autohash_alias);

# autohash_alias (wrap real)
my $constructor='autohash_alias (wrap real)';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
autohash_alias $autohash,%hash;
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_SV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);

# autohash_alias (wrap tied)
my $constructor='autohash_alias (wrap tied)';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

# autohash_hash
my $constructor='autohash_alias autohash_hash';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
$autohash=autohash_hash;
autohash_alias $autohash,%hash;
cmp_types($label,undef,undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_SV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
$autohash=autohash_hash (key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_types($label,undef,undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor alias with initial values";
$autohash=autohash_hash;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,undef,undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);

# autohash_tie
my $constructor='autohash_alias autohash_tie';
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor without initial values";
$autohash=autohash_tie TieMV;
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor with initial values";
$autohash=autohash_tie TieMV,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash;
my $label="$constructor alias with initial values";
$autohash=autohash_tie TieMV;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'TieMV',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_MV);

# autohash_wrap (real)
my $constructor='autohash_alias autohash_wrap (real)';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash;
cmp_types($label,'Hash::AutoHash::alias',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_SV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$autohash=autohash_wrap %source,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_types($label,'Hash::AutoHash::alias',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'Hash::AutoHash::alias',undef,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);

# autohash_wrap (tied)
my $constructor='autohash_alias autohash_wrap (tied)';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrap %source,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrap %source;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

# autohash_wrapobj
my $constructor='autohash_alias autohash_wrapobj';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrapobj $object;
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrapobj $object,(key1=>'value11',key2=>'value21');
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$object=tie %source,'TieMV';
$autohash=autohash_wrapobj $object;
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

# autohash_wraptie
my $constructor='autohash_alias autohash_wraptie';
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor without initial values";
$autohash=autohash_wraptie %source,TieMV;
$object=tied(%source);
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor with initial values";
$autohash=autohash_wraptie %source,TieMV,(key1=>'value11',key2=>'value21');
$object=tied(%source);
autohash_alias $autohash,%hash;
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
undef $autohash; undef $object; untie %hash; undef %hash; my %source;
my $label="$constructor alias with initial values";
$autohash=autohash_wraptie %source,TieMV;
$object=tied(%source);
autohash_alias $autohash,%hash,key1=>'value11',key2=>'value21';
cmp_types($label,'TieMV','TieMV','Hash::AutoHash::alias');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

done_testing();
