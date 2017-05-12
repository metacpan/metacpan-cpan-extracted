use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_keys);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my %INITIAL_VALUES=@INITIAL_VALUES;
sub test_keys {
  my($label,$how_many,$ok_hash,$ok_object)=@_;
  $label.=' with'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my @correct=@KEYS[0..$how_many-1];
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

my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new @initial_values;
  test_keys($constructor,$i);
}
my $constructor='autohash_new (tie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new ['TieMV'],@initial_values;
  test_keys($constructor,$i);
}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new \%hash,@initial_values;
  test_keys($constructor,$i,'hash',undef);
}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new \%hash,@initial_values;
  test_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new $object,@initial_values;
  test_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new [\%hash,'TieMV'],@initial_values;
  $object=tied(%hash);
  test_keys($constructor,$i,'hash','object');
}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_hash @initial_values;
  test_keys($constructor,$i);
}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_tie TieMV,@initial_values;
  test_keys($constructor,$i);
}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wrap %hash,@initial_values;
  test_keys($constructor,$i,'hash',undef);
}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrap %hash,@initial_values;
  test_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrapobj $object,@initial_values;
  test_keys($constructor,$i,'hash','object');
}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wraptie %hash,TieMV,@initial_values;
  $object=tied(%hash);
  test_keys($constructor,$i,'hash','object');
}

done_testing();
