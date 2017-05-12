use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_tied autohash_set);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test unique.
#################################################################################
my $generic_defaults_new=
  {single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record};
my $generic_defaults=
  {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested};
my $sub=sub {my($a,$b)=@_; lc($a) eq lc($b)};

# $start, $update should contain no duplicates
# code will dupify any multi-valued fields that start with 'dupify'
sub test_unique {
  my($label,$start,$update)=@_;
  my $start_dups=dupify_hash($start);
  my $start_dups_mixed=dupify_hash($start,'mixed');
  my $update_dups=dupify_hash($update);
  my $update_dups_mixed=dupify_hash($update,'mixed');
  my $end=merge_hash($start,$update);

  # start no dups, update no dups
  my $pass=1;			# assume success
  my $case="$label start no  dups. update no  dups.";
  $pass=_test_unique($case,'unique',$start,$start,$update,$end) && $pass;
  $pass=_test_unique($case,$sub,$start,$start,$update,$end) && $pass;
  $pass=_test_unique($case,undef,$start,$start,$update,$end) && $pass;
  pass($case) if $pass;

  # start yes dups, update no dups
  my $pass=1;			# assume success
  my $case="$label start yes dups. update no  dups.";
  $pass=_test_unique($case,'unique',$start_dups,$start,$update,$end) && $pass;
  $pass=_test_unique($case,$sub,$start_dups_mixed,$start,$update,$end) && $pass;
  $pass=_test_unique($case,undef,$start_dups,$start_dups,$update,merge_hash($start_dups,$update))
    && $pass;
  pass($case) if $pass;

  # start no dups, update yes dups
  my $pass=1;			# assume success
  my $case="$label start no  dups. update yes dups.";
  $pass=_test_unique($case,'unique',$start,$start,$update_dups,$end) && $pass;
  $pass=_test_unique($case,$sub,$start,$start,$update_dups_mixed,$end) && $pass;
  $pass=_test_unique($case,undef,$start,$start,
		     $update_dups_mixed,merge_hash($start,$update_dups_mixed)) && $pass;
  pass($case) if $pass;

  # start yes dups, update yes dups
  my $pass=1;			# assume success
  my $case="$label start yes dups. update yes dups.";
  $pass=_test_unique($case,'unique',$start_dups,$start,$update_dups,$end) && $pass;
  $pass=_test_unique($case,$sub,$start_dups_mixed,$start,$update_dups_mixed,$end) && $pass;
  $pass=_test_unique($case,undef,$start_dups,$start_dups,
		     $update_dups,merge_hash($start_dups,$update_dups)) && $pass;
  pass($case) if $pass;

  # start no dups, update=start
  my $pass=1;			# assume success
  my $case="$label start no  dups. update=start.";
  $pass=_test_unique($case,'unique',$start,$start,$start,$start) && $pass;
  $pass=_test_unique($case,$sub,$start,$start,$start,$start) && $pass;
  $pass=_test_unique($case,undef,$start,$start,$start,merge_hash($start,$start)) && $pass;
  pass($case) if $pass;

  # start yes dups, update=start w/o dups
  my $pass=1;			# assume success
  my $case="$label start yes dups. update=start w/o dups.";
  $pass=_test_unique($case,'unique',$start_dups,$start,$start,$start) && $pass;
  $pass=_test_unique($case,$sub,$start_dups_mixed,$start,$start,$start) && $pass;
  $pass=_test_unique($case,undef,$start_dups,$start_dups,$start,merge_hash($start_dups,$start))
    && $pass;
  pass($case) if $pass;

  # start no dups, update=start w/dups
  my $pass=1;			# assume success
  my $case="$label start no  dups. update=start w/ dups.";
  $pass=_test_unique($case,'unique',$start,$start,$start_dups,$start) && $pass;
  $pass=_test_unique($case,$sub,$start,$start,$start_dups_mixed,$start) && $pass;
  $pass=_test_unique($case,undef,$start,$start,$start_dups,merge_hash($start,$start_dups)) 
    && $pass;
  pass($case) if $pass;

  # start yes dups, update=start
  my $pass=1;			# assume success
  my $case="$label start yes dups. update=start.";
  $pass=_test_unique($case,'unique',$start_dups,$start,$start_dups,$start) && $pass;
  $pass=_test_unique($case,$sub,$start_dups_mixed,$start,$start_dups_mixed,$start) && $pass;
  $pass=_test_unique($case,undef,$start_dups,$start_dups,$start_dups,
		     merge_hash($start_dups,$start_dups)) && $pass;
  pass($case) if $pass;

  $pass;
}

sub _test_unique {
  my($label,$unique,$start,$after_unique,$update,$after_update)=@_;
  my $pass=1;			# assume success
  # test params as given. no defaults
  $pass=_test_unique1($label,$unique,{},$start,$after_unique,$update,$after_update,{}) && $pass;
  # use params as defaults
  $pass=_test_unique1("$label start   defaults",$unique,
		      $start,{},$after_unique,$update,$after_update,$after_unique) && $pass;
  # use generic params
  $pass=_test_unique1("$label generic defaults",$unique,$generic_defaults_new,
		      $start,{%$generic_defaults,%$after_unique},
		      $update,{%$generic_defaults,%$after_update},
		      $generic_defaults) && $pass;
}

sub _test_unique1 {
  my($label,$unique,$defaults,$start,$after_unique,$update,$after_update,$after_clear)=@_;
  $label=label_unique($label,$unique);
  my $pass=1;			# assume success

  my $record=new Hash::AutoHash::Record $defaults;
  autohash_set($record,%$start);
  autohash_tied($record)->unique($unique);
  $pass=_cmp_record("$label after unique",$record,$after_unique) && $pass;
 # update via methods
  while(my($key,$value)=each %$update) {
    $record->$key($value);
  }
  $pass=_cmp_record("$label after update via methods",$record,$after_update) && $pass;

  my $record=new Hash::AutoHash::Record $defaults; # reset record for next test
  autohash_set($record,%$start);
  autohash_tied($record)->unique($unique);
  $pass=_cmp_record("$label after unique",$record,$after_unique) && $pass;
 # update via hash operations
  @$record{keys %$update}=values %$update;
  $pass=_cmp_record("$label after update via hash operations",$record,$after_update) && $pass;

  my $record=new Hash::AutoHash::Record $defaults; # reset record for next test
  autohash_set($record,%$start);
  autohash_tied($record)->unique($unique);
  $pass=_cmp_record("$label after unique",$record,$after_unique) && $pass;
  # update via set function
  autohash_set($record,%$update);
  $pass=_cmp_record("$label after update via autohash_set",$record,$after_update) && $pass;

  my $record=new Hash::AutoHash::Record $defaults; # reset record for next test
  autohash_set($record,%$start);
  autohash_tied($record)->unique($unique);
  $pass=_cmp_record("$label after unique",$record,$after_unique) && $pass;
  # update via set function (to better ensure state is no longer default)
  autohash_set($record,%$update);
  # restore defaults by clearing record
  %$record=();
  $pass=_cmp_record("$label after clear",$record,$after_clear) && $pass;
}
sub label_unique {
  my($label,$unique)=@_;
  return "unique sub: $label" if 'CODE' eq ref $unique;
  return "unique  on: $label" if $unique;
  return "unique off: $label";
}
sub merge_hash {
  my($hash1,$hash2)=@_;
  my $hash_out={};
  # initialize $hash_out to ARRAY elements of $hash1
  while(my($key,$value)=each %$hash1) {
    next unless 'ARRAY' eq ref $value;
    $hash_out->{$key}=[@$value]; # copy the element, since may be updated in next loop
  }
  # add to $hash_out ARRAY elements of $hash2, appending values for common keys
  while(my($key,$value)=each %$hash2) {
    next unless 'ARRAY' eq ref $value;
    $hash_out->{$key} or $hash_out->{$key}=[];
    push(@{$hash_out->{$key}},@$value);
  }
  $hash_out;
}

sub dupify_hash {
  my($hash,$mixed)=@_;
  my $hash_out={};
  while(my($key,$value)=each %$hash) {
    if ('ARRAY' eq ref $value && $key=~/^dupify/) {
      $hash_out->{$key}=$mixed? dupify_mixed($value): dupify($value);
    } else {
      $hash_out->{$key}=$value;
    }
  }
  $hash_out;
}
sub dupify {			# convert unique list into one with dups
  my $in=shift;
  my $out=[];
  for(my $i=0; $i<@$in; $i++) {
    push(@$out,($in->[$i])x($i+1));
  }
  $out;
}
sub dupify_mixed {		# convert unique list into one with mixed-case dups
  my $in=shift;
  my $out=[];
  for(my $i=0; $i<@$in; $i++) {
    push(@$out,lc $in->[$i],(uc $in->[$i])x($i+1));
  }
  $out;
}

### manually constructed test cases
$record=new Hash::AutoHash::Record(multi1=>[qw(value11 value11)]);
cmp_record("initialize key with duplicate",$record,{multi1=>[qw(value11 value11)]});
ok(!tied(%$record)->unique,"unique initially false");
ok(tied(%$record)->unique(1),"set unique to true");
cmp_record("key now unique",$record,{multi1=>[qw(value11)]});
$record->multi1('value11');
cmp_record("key still unique after storing duplicate",$record,{multi1=>[qw(value11)]});
$record->multi1('value12');
cmp_record("storing non-duplicate still works",$record,{multi1=>[qw(value11 value12)]});
my $defaults=tied(%$record)->defaults;
cmp_deeply($defaults,{multi1=>[qw(value11 value11)]},"unique leaves defaults unchanged");
%$record=();
cmp_record("duplicates removed when set via defaults",$record,{multi1=>[qw(value11)]});

$record=new Hash::AutoHash::Record(multi1=>[qw(value10 value11 VALUE11 value12)]);
ok(tied(%$record)->unique(sub {lc($_[0]) eq lc($_[1])}),"set unique to sub");
cmp_record("key now unique using sub",$record,{multi1=>[qw(value10 value11 value12)]});
$record->multi1('value13');
cmp_record("storing non-duplicate still works with unique sub",$record,
	   {multi1=>[qw(value10 value11 value12 value13)]});
my $defaults=tied(%$record)->defaults;
cmp_deeply($defaults,
	   {multi1=>[qw(value10 value11 VALUE11 value12)]},
	   "unique sub leaves defaults unchanged");
%$record=();
cmp_record("duplicates removed when set via defaults with unique sub",$record,
	   {multi1=>[qw(value10 value11 value12)]});

$record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record,
  multi1=>[qw(value11 value11)],multi2=>[qw(value21 value21)]);
cmp_record("initialize many keys. 2 with duplicates",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11 value11)],multi2=>[qw(value21 value21)]});
ok(tied(%$record)->unique(1),"set unique to true");
cmp_record("duplicate keys now unique. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11)],multi2=>[qw(value21)]});
$record->multi1('value11');
cmp_record("key still unique after storing duplicate",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11)],multi2=>[qw(value21)]});
$record->multi1('value12');
cmp_record("storing non-duplicate still works",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11 value12)],multi2=>[qw(value21)]});
%$record=();
cmp_record("duplicate removed when set via defaults. others restored unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11)],multi2=>[qw(value21)]});

$record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record,
  multi1=>[qw(value10 value11 VALUE11 value12)]);
ok(tied(%$record)->unique(sub {lc($_[0]) eq lc($_[1])}),"set unique to sub");
cmp_record("duplicate key now unique using sub. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value10 value11 value12)]});
$record->multi1('VALUE11');
cmp_record("key still unique after storing duplicate using sub. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value10 value11 value12)]});
$record->multi1('value13');
cmp_record("storing non-duplicate still works using sub. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value10 value11 value12 value13)]});
%$record=();
cmp_record("duplicate removed when set via defaults using sub. others restored unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value10 value11 value12)]});

### systematic test cases
# too slow for installation testing with these values...
# my $max_keys=3;
# my $max_min_values=2;
my $max_keys=2;
my $max_min_values=0;

for (my $min_values=0; $min_values<=$max_min_values; $min_values++) {
  for (my $num_keys=1; $num_keys<=$max_keys; $num_keys++) {
    my $max_values=$min_values+$num_keys-1;
    my $label="$num_keys keys, $min_values to $max_values values.";
    my $start={};
    for (my $i=0; $i<$num_keys; $i++) {
      my @values;
      for (my $j=0; $j<$min_values+$i; $j++) {
	push(@values,"value$i$j");
      }
      $start->{"dupify$i"}=[@values];
    }
    my $update={};
    for (my $i=0; $i<$num_keys; $i++) {
      my @values;
      for (my $j=0; $j<$min_values+$i; $j++) {
	push(@values,value.($i+$num_keys).$j);
      }
      $update->{"dupify$i"}=[@values];
    }
     test_unique($label,$start,$update);
  }
}

done_testing();
