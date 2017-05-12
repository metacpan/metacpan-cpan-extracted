use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_delete autohash_keys);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');

sub test_delete_keys {
  my($label,$how_many,$ok_hash,$ok_object)=@_;
  $label.=' after delete'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my @deletes=map {"key$_"} (0..$how_many-1); # keys to delete
  my @correct=map {"key$_"} ($how_many..2);   # keys to keep
  autohash_delete($autohash,@deletes);
  my @actual=autohash_keys($autohash);
  cmp_set(\@actual,\@correct,"$label keys via function");
  my @actual=keys %$autohash;
  cmp_set(\@actual,\@correct,"$label keys as hash");
  my @actual=keys %hash;
  cmp_set(\@actual,($ok_hash? \@correct: []),"$label keys external hash");
  if ($ok_object) {
    my @actual=keys_obj($object);
    cmp_set(\@actual,\@correct,"$label keys external object");
  } else {			# object should be undef
    is($object,undef,"$label keys external object");
  }
}

################################################################################
# test keys after deletion
################################################################################
my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new @INITIAL_VALUES;
  test_delete_keys($constructor,$i);
}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new \%hash,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash',undef);
}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_new \%hash,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_new $object,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_new [\%hash,'TieMV'],@INITIAL_VALUES;
  $object=tied(%hash);
  test_delete_keys($constructor,$i,'hash','object');
}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_hash @INITIAL_VALUES;
  test_delete_keys($constructor,$i);
}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_tie TieMV,@INITIAL_VALUES;
  test_delete_keys($constructor,$i);
}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_wrap %hash,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash',undef);
}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrap %hash,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrapobj $object,@INITIAL_VALUES;
  test_delete_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  $autohash=autohash_wraptie %hash,TieMV,@INITIAL_VALUES;
  $object=tied(%hash);
  test_delete_keys($constructor,$i,'hash','object');
}

done_testing();
