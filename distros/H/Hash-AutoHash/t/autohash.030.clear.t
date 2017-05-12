use lib qw(t);
use strict;
use Carp;
use Test::More;
# use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_clear);

my @INITIAL_VALUES=(key1=>'value11',key2=>'value21');

sub ok_autohash_empty {
  my($label,$ok_hash,$ok_object)=@_;
  ok(!keys %$autohash,"$label: autohash empty");
  ok(!keys %hash,"$label: external hash empty");
  if ($ok_object) {
    my @pair=$object->FIRSTKEY();
    ok(!@pair,"$label: external object empty");
  } else {
    is($object,undef,"$label: external object empty");
  }
}
my $constructor='autohash_new (real)';
$autohash=autohash_new @INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_SV[1]);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear");

my $constructor='autohash_new (tie)';
$autohash=autohash_new ['TieMV'],@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1]);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear");

my $constructor='autohash_new (wrap real)';
undef %hash;
$autohash=autohash_new \%hash,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_SV[1],'hash',undef);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash');

my $constructor='autohash_new (wrap tied)';
$object=tie %hash,'TieMV';
$autohash=autohash_new \%hash,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

my $constructor='autohash_new (wrap object)';
$object=tie %hash,'TieMV';
$autohash=autohash_new $object,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

my $constructor='autohash_new (wraptie)';
my $label="$constructor without initial values";
$autohash=autohash_new [\%hash,'TieMV'],@INITIAL_VALUES;
$object=tied(%hash);
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

undef $autohash; undef $object; untie %hash; undef %hash;

my $constructor='autohash_hash';
$autohash=autohash_hash @INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_SV[1]);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear");

my $constructor='autohash_tie';
$autohash=autohash_tie TieMV,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1]);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear");

my $constructor='autohash_wrap (real)';
$autohash=autohash_wrap %hash,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_SV[1],'hash',undef);
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash');

my $constructor='autohash_wrap (tied)';
$object=tie %hash,'TieMV';
$autohash=autohash_wrap %hash,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

my $constructor='autohash_wrapobj';
$object=tie %hash,'TieMV';
$autohash=autohash_wrapobj $object,@INITIAL_VALUES;
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

my $constructor='autohash_wraptie';
$autohash=autohash_wraptie %hash,TieMV,@INITIAL_VALUES;
$object=tied(%hash);
cmp_autohash("$constructor before clear:",$VALUES_MV[1],'hash','object');
autohash_clear($autohash);
ok_autohash_empty("$constructor after clear",'hash','object');

done_testing();
