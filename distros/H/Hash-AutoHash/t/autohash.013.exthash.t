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
use Hash::AutoHash qw(autohash_hash autohash_tie autohash_wrap autohash_wrapobj autohash_wraptie);

# autohash_wrap (real)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrap (real)';
my $label="$constructor without initial values";
$autohash=autohash_wrap %hash;
cmp_types($label,'Hash::AutoHash::alias');
test_exthash_more($label,'hash',undef,0,@VALUES_SV);
my $label="$constructor with initial values";
$autohash=autohash_wrap %hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'Hash::AutoHash::alias');
test_exthash_more($label,'hash',undef,1,@VALUES_SV);

# autohash_wrap (tied)
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrap (tied)';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_wrap %hash;
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_wrap %hash,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',1,@VALUES_MV);

# autohash_wrapobj
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wrapobj';
my $label="$constructor without initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_wrapobj $object;
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$object=tie %hash,'TieMV';
$autohash=autohash_wrapobj $object,(key1=>'value11',key2=>'value21');
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',1,@VALUES_MV);

# autohash_wraptie
undef $autohash; undef $object; untie %hash; undef %hash;
my $constructor='autohash_wraptie';
my $label="$constructor without initial values";
$autohash=autohash_wraptie %hash,TieMV;
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',0,@VALUES_MV);
my $label="$constructor with initial values";
$autohash=autohash_wraptie %hash,TieMV,(key1=>'value11',key2=>'value21');
$object=tied(%hash);
cmp_types($label,'TieMV','TieMV','TieMV');
test_exthash_more($label,'hash','object',1,@VALUES_MV);

done_testing();
