use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_delete);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my $UNDEFS=[undef,undef,undef];
my %VALUES_SV=(0=>['value01','value11','value21'],
	       1=>[undef,'value11','value21'],
	       2=>[undef,undef,'value21'],
	       3=>[undef,undef,undef]);
my %VALUES_MV=(0=>[['value01'],['value11'],['value21']],
	       1=>[undef,['value11'],['value21']],
	       2=>[undef,undef,['value21']],
	       3=>[undef,undef,undef]);

sub test_delete_func {
  my($label,$how_many,$correct,$ok_hash,$ok_object)=@_;
  $label.=' after delete via function'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my $values=$correct->{$how_many} || $UNDEFS;
  my @deletes=map {"key$_"} (0..$how_many-1);
  autohash_delete($autohash,@deletes);
  cmp_autohash($label,$values,$ok_hash,$ok_object); # tests values of keys
  # also test which keys are present
  my @correct=map {"key$_"} ($how_many..2);
  cmp_set([keys %$autohash],\@correct,"$label remaining keys");
}
sub test_delete_ashash {
  my($label,$how_many,$correct,$ok_hash,$ok_object)=@_;
  $label.=' after delete as hash'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my $values=$correct->{$how_many} || $UNDEFS;
  my @deletes=map {"key$_"} (0..$how_many-1);
  delete @$autohash{@deletes};
  cmp_autohash($label,$values,$ok_hash,$ok_object); # tests values of keys
  # also test which keys are present
  my @correct=map {"key$_"} ($how_many..2);
  cmp_set([keys %$autohash],\@correct,"$label remaining keys");
}
sub test_delete_exthash {
  my($label,$how_many,$correct,$ok_hash,$ok_object)=@_;
  $label.=' after delete external hash'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my $values=$correct->{$how_many} || $UNDEFS;
  my @deletes=map {"key$_"} (0..$how_many-1);
  delete @hash{@deletes};
  cmp_autohash($label,$values,$ok_hash,$ok_object); # tests values of keys
  # also test which keys are present
  my @correct=map {"key$_"} ($how_many..2);
  cmp_set([keys %$autohash],\@correct,"$label remaining keys");
}
sub test_delete_extobj {
  my($label,$how_many,$correct,$ok_hash,$ok_object)=@_;
  $label.=' after delete external object'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my $values=$correct->{$how_many} || $UNDEFS;
  my @deletes=map {"key$_"} (0..$how_many-1);
  map {$object->DELETE($_)} @deletes;
  cmp_autohash($label,$values,$ok_hash,$ok_object); # tests values of keys
  # also test which keys are present
  my @correct=map {"key$_"} ($how_many..2);
  cmp_set([keys %$autohash],\@correct,"$label remaining keys");
}

my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_new @INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_SV);
  }}
my $constructor='autohash_new (tie)';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_new ['TieMV'],@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_MV);
  }}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash exthash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_new \%hash,@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_SV,'hash',undef);
  }}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $object=tie %hash,'TieMV';
    $autohash=autohash_new \%hash,@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_MV,'hash','object');
  }}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $object=tie %hash,'TieMV';
    $autohash=autohash_new $object,@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_MV,'hash','object');
  }}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_new [\%hash,'TieMV'],@INITIAL_VALUES;
    $object=tied(%hash);
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_MV,'hash','object');
  }}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_hash @INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_SV);
  }}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_tie TieMV,@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_MV);
  }}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  for my $test(qw(func ashash exthash)) {
    undef $autohash; undef $object; untie %hash; undef %hash;
    my $sub="test_delete_$test";
    $autohash=autohash_wrap %hash,@INITIAL_VALUES;
    no strict 'refs';
    &$sub($constructor,$i,\%VALUES_SV,'hash',undef);
  }}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
     undef $autohash; undef $object; untie %hash; undef %hash;
     my $sub="test_delete_$test";
     $object=tie %hash,'TieMV';
     $autohash=autohash_wrap %hash,@INITIAL_VALUES;
     no strict 'refs';
     &$sub($constructor,$i,\%VALUES_MV,'hash','object');
  }}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
     undef $autohash; undef $object; untie %hash; undef %hash;
     my $sub="test_delete_$test";
     $object=tie %hash,'TieMV';
     $autohash=autohash_wrapobj $object,@INITIAL_VALUES;
     no strict 'refs';
     &$sub($constructor,$i,\%VALUES_MV,'hash','object');
   }}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
   for my $test(qw(func ashash exthash extobj)) {
     undef $autohash; undef $object; untie %hash; undef %hash;
     my $sub="test_delete_$test";
     $autohash=autohash_wraptie %hash,TieMV,@INITIAL_VALUES;
     $object=tied(%hash);
     no strict 'refs';
     &$sub($constructor,$i,\%VALUES_MV,'hash','object');
   }}

done_testing();
