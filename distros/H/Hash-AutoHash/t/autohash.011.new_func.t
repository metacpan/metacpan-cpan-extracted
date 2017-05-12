################################################################################
# test autohash_new function - front-end to other constructor functions
################################################################################
use lib qw(t);
use strict;
use Carp;
use Test::More;
# use Test::Deep;
use autohashUtil;
require 'autohash.01x.constructors.pm';
require 'autohash.TieMV.pm';	# example tied hash class
use Hash::AutoHash qw(autohash_new);

# autohash_new (real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (real)';
my $label="$constructor without initial values";
$autohash=autohash_new;
cmp_types($label);
test_autohash($label,0,@VALUES_SV);
my $label="$constructor with initial values";
$autohash=autohash_new (key1=>'value11',key2=>'value21');
cmp_types($label);
test_autohash($label,1,@VALUES_SV);

# autohash_new (tie)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (tie)';
my $label="$constructor without initial values";
$autohash=autohash_new ['TieMV'];
cmp_types($label,'TieMV');
test_autohash($label,0,@VALUES_MV);
my $label="$constructor with TIEHASH param and no initial values";
is($TieMV::TIEHASH_PARAM,undef,"$label: TIEHASH param before test");
$autohash=autohash_new ['TieMV','tiehash_param1'];
cmp_types($label,'TieMV');
is($TieMV::TIEHASH_PARAM,'tiehash_param1',"$label: TIEHASH param");
test_autohash($label,0,@VALUES_MV);
my $label="$constructor with initial values passed to TIEHASH";
$autohash=autohash_new ['TieMV',(key1=>'value11',key2=>'value21')];
cmp_types($label,'TieMV');
test_autohash($label,1,@VALUES_MV);
my $label="$constructor with initial values set by autohash_new";
$autohash=autohash_new ['TieMV'],(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV');
test_autohash($label,1,@VALUES_MV);
my $label="$constructor with TIEHASH param and initial values set by autohash_new";
$autohash=autohash_new ['TieMV','tiehash_param2'],(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV');
is($TieMV::TIEHASH_PARAM,'tiehash_param2',"$label: TIEHASH param");
test_autohash($label,1,@VALUES_MV);

# autohash_new (wrap real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (wrap real)';
my $label="$constructor without initial values";
$autohash=autohash_new \%hash;
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,0,@VALUES_SV);
my $label="$constructor with initial values";
$autohash=autohash_new \%hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'Hash::AutoHash::alias');
test_autohash_more($label,'hash',undef,1,@VALUES_SV);

# autohash_new (wrap tied)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (wrap tied)';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_new \%hash;
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_new \%hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);

# autohash_new (wrap object)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (wrap object)';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_new $object;
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_new $object,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
undef $object;

# autohash_new (wraptie)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_new (wraptie)';
my $label="$constructor without initial values";
$autohash=autohash_new [\%hash,'TieMV'];
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with TIEHASH param and no initial values";
$TieMV::TIEHASH_PARAM=undef;
is($TieMV::TIEHASH_PARAM,undef,"$label: TIEHASH param before test");
$autohash=autohash_new [\%hash,'TieMV','tiehash_param1'];
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
is($TieMV::TIEHASH_PARAM,'tiehash_param1',"$label: TIEHASH param");
test_autohash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values passed to TIEHASH";
$autohash=autohash_new [\%hash,'TieMV',(key1=>'value11',key2=>'value21')];
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
my $label="$constructor with initial values set by autohash_new";
$autohash=autohash_new [\%hash,'TieMV'],(key1=>'value11',key2=>'value21');
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_autohash_more($label,'hash','object',1,@VALUES_MV);
my $label="$constructor with TIEHASH param and initial values set by autohash_new";
$autohash=autohash_new [\%hash,'TieMV','tiehash_param2'],(key1=>'value11',key2=>'value21');
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
is($TieMV::TIEHASH_PARAM,'tiehash_param2',"$label: TIEHASH param");
test_autohash_more($label,'hash','object',1,@VALUES_MV);

done_testing();
