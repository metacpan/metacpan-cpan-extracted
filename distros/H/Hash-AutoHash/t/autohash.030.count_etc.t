use lib qw(t);
use strict;
use Carp;
use Test::More;
# use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_count autohash_empty autohash_notempty);

my @INITIAL_VALUES=(key1=>'value11',key2=>'value21');

sub test_count_etc {
  my($label,$correct,$ok_hash,$ok_object)=@_;
  $correct? $label.=' not empty': $label.=' empty';
  is(autohash_count($autohash),$correct,"$label: count via function");
  is(scalar(keys %$autohash),$correct,"$label: count as hash");
  is(scalar(keys %hash),$correct,"$label: count external hash") if $ok_hash;
  is(scalar(keys_obj $object)||0,$correct,"$label: count external object") if $ok_object;

  is(autohash_empty($autohash),as_bool(!$correct),"$label: empty via function");
  is(autohash_notempty($autohash),as_bool($correct),"$label: notempty via function");
}

my $constructor='autohash_new (real)';
$autohash=autohash_new;
test_count_etc($constructor,0);
$autohash=autohash_new @INITIAL_VALUES;
test_count_etc($constructor,2);

my $constructor='autohash_new (tie)';
$autohash=autohash_new ['TieMV'];
test_count_etc($constructor,0);
$autohash=autohash_new ['TieMV'],@INITIAL_VALUES;
test_count_etc($constructor,2);

my $constructor='autohash_new (wrap real)';
undef %hash;
$autohash=autohash_new \%hash;
test_count_etc($constructor,0,'hash');
$autohash=autohash_new \%hash,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash');

my $constructor='autohash_new (wrap tied)';
$object=tie %hash,'TieMV';
$autohash=autohash_new \%hash;
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_new \%hash,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash','object');

my $constructor='autohash_new (wrap object)';
$object=tie %hash,'TieMV';
$autohash=autohash_new $object;
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_new $object,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash','object');

my $constructor='autohash_new (wraptie)';
$autohash=autohash_new [\%hash,'TieMV'];
$object=tied(%hash);
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_new [\%hash,'TieMV'],@INITIAL_VALUES;
$object=tied(%hash);
test_count_etc($constructor,2,'hash','object');

undef $autohash; undef $object; untie %hash; undef %hash;

my $constructor='autohash_hash';
$autohash=autohash_hash;
test_count_etc($constructor,0);
$autohash=autohash_hash @INITIAL_VALUES;
test_count_etc($constructor,2);

my $constructor='autohash_tie';
$autohash=autohash_tie TieMV;
test_count_etc($constructor,0);
$autohash=autohash_tie TieMV,@INITIAL_VALUES;
test_count_etc($constructor,2);

my $constructor='autohash_wrap (real)';
$autohash=autohash_wrap %hash;
test_count_etc($constructor,0,'hash');
$autohash=autohash_wrap %hash,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash');

my $constructor='autohash_wrap (tied)';
$object=tie %hash,'TieMV';
$autohash=autohash_wrap %hash;
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_wrap %hash,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash','object');

my $constructor='autohash_wrapobj';
$object=tie %hash,'TieMV';
$autohash=autohash_wrapobj $object;
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_wrapobj $object,@INITIAL_VALUES;
test_count_etc($constructor,2,'hash','object');

my $constructor='autohash_wraptie';
$autohash=autohash_wraptie %hash,TieMV;
$object=tied(%hash);
test_count_etc($constructor,0,'hash','object');
$autohash=autohash_wraptie %hash,TieMV,@INITIAL_VALUES;
$object=tied(%hash);
test_count_etc($constructor,2,'hash','object');

done_testing();
