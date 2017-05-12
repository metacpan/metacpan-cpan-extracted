use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_values);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my %INITIAL_VALUES=@INITIAL_VALUES;
my $VALUES_SV=[qw(value01 value11 value21)];
my $VALUES_MV=[['value01'],['value11'],['value21']];

sub test_values {
  my($label,$how_many,$values,$ok_hash,$ok_object)=@_;
  $label.=' with'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my @correct=@$values[0..$how_many-1];
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

my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new @initial_values;
  test_values($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_new (tie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new ['TieMV'],@initial_values;
  test_values($constructor,$i,$VALUES_MV);
}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new \%hash,@initial_values;
  test_values($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new \%hash,@initial_values;
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new $object,@initial_values;
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new [\%hash,'TieMV'],@initial_values;
  $object=tied(%hash);
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_hash @initial_values;
  test_values($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_tie TieMV,@initial_values;
  test_values($constructor,$i,$VALUES_MV);
}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wrap %hash,@initial_values;
  test_values($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrap %hash,@initial_values;
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrapobj $object,@initial_values;
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wraptie %hash,TieMV,@initial_values;
  $object=tied(%hash);
  test_values($constructor,$i,$VALUES_MV,'hash','object');
}

done_testing();
