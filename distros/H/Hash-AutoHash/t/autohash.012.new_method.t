################################################################################
# test new method - front-end to other constructor functions
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
use Hash::AutoHash;

# new Hash::AutoHash (real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (real)';
my $label="$constructor without initial values";
$autohash=new Hash::AutoHash;
cmp_types($label);
test_autohash($label,0,@VALUES_SV);
my $label="$constructor with initial values";
$autohash=new Hash::AutoHash (key1=>'value11',key2=>'value21');
cmp_types($label);
test_autohash($label,1,@VALUES_SV);

# new Hash::AutoHash (tie)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (tie)';
my $label="$constructor without initial values";
$autohash=new Hash::AutoHash ['TieMV'];
cmp_types($label,'TieMV');
test_autohash($label,0,@VALUES_MV);
my $label="$constructor with initial values";
$autohash=new Hash::AutoHash ['TieMV',(key1=>'value11',key2=>'value21')];
cmp_types($label,'TieMV');
test_autohash($label,1,@VALUES_MV);

# new Hash::AutoHash (wrap real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (wrap real)';
my $label="$constructor without initial values";
$autohash=new Hash::AutoHash \%hash;
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_SV);
my $label="$constructor with initial values";
$autohash=new Hash::AutoHash \%hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);

# new Hash::AutoHash (wrap tied)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (wrap tied)';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=new Hash::AutoHash \%hash;
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=new Hash::AutoHash \%hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

# new Hash::AutoHash (wrap object)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (wrap object)';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=new Hash::AutoHash $object;
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=new Hash::AutoHash $object,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
undef $object;

# new Hash::AutoHash (wraptie)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='new Hash::AutoHash (wraptie)';
my $label="$constructor without initial values";
$autohash=new Hash::AutoHash [\%hash,'TieMV'];
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$autohash=new Hash::AutoHash [\%hash,'TieMV',(key1=>'value11',key2=>'value21')];
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

done_testing();
