use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
require 'autohash.TieMV.pm';	# example tied hash class
use autohashUtil;
use Hash::AutoHash qw(autohash_new autohash_hash autohash_tie 
			      autohash_wrap autohash_wraptie autohash_wrapobj);
use Hash::AutoHash qw(autohash_each);

my @INITIAL_VALUES=(key0=>'value01',key1=>'value11',key2=>'value21');
my %INITIAL_VALUES=@INITIAL_VALUES;
my $VALUES_SV=[qw(value01 value11 value21)];
my $VALUES_MV=[['value01'],['value11'],['value21']];

sub test_each {
  my($label,$how_many,$values,$ok_hash,$ok_object)=@_;
  my(@ok,@fail);
  $label.=' with'.($how_many==1? ' 1 keys:': " $how_many keys:");
  my %correct;
  @correct{map {'key'.$_} (0..$how_many-1)}=@$values[0..$how_many-1];
  my @correct=keys %correct;

  # list context. gets key=>value pairs
  # via function
  my %actual;
  while(my($key,$value)=autohash_each($autohash)) {$actual{$key}=$value;}
  cmp_deeply(\%actual,\%correct,"$label each list context 1st loop via function");
  # do it again to make sure iterator resets correctly
  my %actual;
  while(my($key,$value)=autohash_each($autohash)) {$actual{$key}=$value;}
  cmp_deeply(\%actual,\%correct,"$label each list context 2nd loop via function");
  #
  # as hash
  my %actual;
  while(my($key,$value)=each %$autohash) {$actual{$key}=$value;}
  cmp_deeply(\%actual,\%correct,"$label each list context 1st loop as hash");
  # do it again to make sure iterator resets correctly
  my %actual;
  while(my($key,$value)=each %$autohash) {$actual{$key}=$value;}
  cmp_deeply(\%actual,\%correct,"$label each list context 2nd loop as hash");
  #
  # external hash
  if ($ok_hash) {
    my %actual;
    while(my($key,$value)=each %hash) {$actual{$key}=$value;}
    cmp_deeply(\%actual,\%correct,"$label each list context 1st loop external hash");
    # do it again to make sure iterator resets correctly
    my %actual;
    while(my($key,$value)=each %hash) {$actual{$key}=$value;}
    cmp_deeply(\%actual,\%correct,"$label each list context 2nd loop external hash");
  } else {			# should be empty
    ok(!%hash,"$label each list context external hash empty");
  }
  # 
  # external object
  if ($ok_object) {
    my %actual;
    while(my($key,$value)=each_obj($object)) {$actual{$key}=$value;}
    cmp_deeply(\%actual,\%correct,"$label each list context 1st loop external object");
    # do it again to make sure iterator resets correctly
    my %actual;
    while(my($key,$value)=each_obj($object)) {$actual{$key}=$value;}
    cmp_deeply(\%actual,\%correct,"$label each list context 2nd loop external object");
  } else {			# should be undef
    is($object,undef,"$label each list context external object undef");
  }

  # scalar context. gets key
  # via function
  my @actual;
  while(my $key=autohash_each($autohash)) {push(@actual,$key);}
  cmp_set(\@actual,\@correct,"$label each scalar context 1st loop via function");
  # do it again to make sure iterator resets correctly
  my @actual;
  while(my $key=autohash_each($autohash)) {push(@actual,$key);}
  cmp_set(\@actual,\@correct,"$label each scalar context 2nd loop via function");
  #
  # as hash
  my @actual;
  while(my $key=each %$autohash) {push(@actual,$key);}
  # cmp_deeply(\@actual,\@correct,"$label each scalar context 1st loop as hash");
  cmp_set(\@actual,\@correct,"$label each scalar context 1st loop as hash");
  # do it again to make sure iterator resets correctly
  my @actual;
  while(my $key=each %$autohash) {push(@actual,$key);}
  # cmp_deeply(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
  cmp_set(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
  #
  # external hash
  if ($ok_hash) {
    my @actual;
    while(my $key=each %hash) {push(@actual,$key);}
    # cmp_deeply(\@actual,\@correct,"$label each scalar context 1st loop as hash");
    cmp_set(\@actual,\@correct,"$label each scalar context 1st loop as hash");
    # do it again to make sure iterator resets correctly
    my @actual;
    while(my $key=each %hash) {push(@actual,$key);}
    # cmp_deeply(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
    cmp_set(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
  } else {			# should be empty
    ok(!%hash,"$label each scalar context external hash empty");
  }
  #
  # external object
  if ($ok_object) {
    my @actual;
    while(my $key=each_obj($object)) {push(@actual,$key);}
    # cmp_deeply(\@actual,\@correct,"$label each scalar context 1st loop as hash");
    cmp_set(\@actual,\@correct,"$label each scalar context 1st loop as hash");
    # do it again to make sure iterator resets correctly
    my @actual;
    while(my $key=each %hash) {push(@actual,$key);}
    # cmp_deeply(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
    cmp_set(\@actual,\@correct,"$label each scalar context 2nd loop as hash");
  } else {			# should be empty
    is($object,undef,"$label each scalar context external object undef");
  }
}

my $constructor='autohash_new (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new @initial_values;
  test_each($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_new (tie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new ['TieMV'],@initial_values;
  test_each($constructor,$i,$VALUES_MV);
}
my $constructor='autohash_new (wrap real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new \%hash,@initial_values;
  test_each($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_new (wrap tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new \%hash,@initial_values;
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wrap object)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_new $object,@initial_values;
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_new (wraptie)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_new [\%hash,'TieMV'],@initial_values;
  $object=tied(%hash);
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}

my $constructor='autohash_hash';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_hash @initial_values;
  test_each($constructor,$i,$VALUES_SV);
}
my $constructor='autohash_tie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_tie TieMV,@initial_values;
  test_each($constructor,$i,$VALUES_MV);
}
my $constructor='autohash_wrap (real)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wrap %hash,@initial_values;
  test_each($constructor,$i,$VALUES_SV,'hash',undef);
}
my $constructor='autohash_wrap (tied)';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrap %hash,@initial_values;
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wrapobj';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $object=tie %hash,'TieMV';
  $autohash=autohash_wrapobj $object,@initial_values;
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}
my $constructor='autohash_wraptie';
for(my $i=0; $i<=3; $i++) {
  undef $autohash; undef $object; untie %hash; undef %hash;
  my @initial_values=(map {'key'.$_=>$INITIAL_VALUES{'key'.$_}} (0..$i-1));
  $autohash=autohash_wraptie %hash,TieMV,@initial_values;
  $object=tied(%hash);
  test_each($constructor,$i,$VALUES_MV,'hash','object');
}

done_testing();
