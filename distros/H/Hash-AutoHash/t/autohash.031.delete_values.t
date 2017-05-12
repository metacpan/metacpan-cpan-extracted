use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_delete autohash_values);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my $VALUES_SV=[qw(value01 value11 value21)];
my $VALUES_MV=[['value01'],['value11'],['value21']];

sub test_delete_values {
  my($label,$how_many,$values,$ok_hash,$ok_object)=@_;
  $label.=' after delete'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my @deletes=map {"key$_"} (0..$how_many-1); # keys to delete
  my @correct=@$values[$how_many..2];   # values of remaining keys
  autohash_delete($autohash,@deletes);
  my @actual=autohash_values($autohash);
  cmp_set(\@actual,\@correct,"$label values via function");
  my @actual=values %$autohash;
  cmp_set(\@actual,\@correct,"$label values as hash");
  my @actual=values %hash;
  cmp_set(\@actual,($ok_hash? \@correct: []),"$label values external hash");
  if ($ok_object) {
    my @actual=values_obj($object);
    cmp_set(\@actual,\@correct,"$label values external object");
  } else {			# object should be undef
    is($object,undef,"$label values external object");
  }
}

################################################################################
# test values after deletion
################################################################################
my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new @INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new \%hash,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_new \%hash,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_new $object,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new [\%hash,'TieMV'],@INITIAL_VALUES;
  $object=tied(%hash);
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_hash @INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_tie TieMV,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_MV);
}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_wrap %hash,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrap %hash,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrapobj $object,@INITIAL_VALUES;
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_wraptie %hash,TieMV,@INITIAL_VALUES;
  $object=tied(%hash);
  test_delete_values($constructor,$i,$VALUES_MV,'hash','object');
}

done_testing();
