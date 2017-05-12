use lib qw(t);
use Carp;
use Hash::AutoHash::Record qw(autohash_tied autohash_set);
use Test::More;
use Test::Deep;
use recordUtil;

#################################################################################
# test filter.
#################################################################################

sub test_filter {
  my($label,$filter,$initial_value,$after_filter,$update,$after_update)=@_;
  $label=label_filter($label,$filter);
  my $record=new Hash::AutoHash::Record %$initial_value;
#  cmp_record("$label initial value",$record,$initial_value);
  autohash_tied($record)->filter($filter);
  cmp_record("$label after filter",$record,$after_filter);
 # update via methods
  while(my($key,$value)=each %$update) {
    $record->$key($value);
  }
  cmp_record("$label after update via methods",$record,$after_update);

  # reset record for next test
  my $record=new Hash::AutoHash::Record %$initial_value;
#  cmp_record("$label restore initial value",$record,$initial_value);
  autohash_tied($record)->filter($filter);
  cmp_record("$label after filter",$record,$after_filter);
 # update via hash operations
  @$record{keys %$update}=values %$update;
  cmp_record("$label after update via hash operations",$record,$after_update);

  # reset record for next test
  my $record=new Hash::AutoHash::Record %$initial_value;
#  cmp_record("$label restore initial value",$record,$initial_value);
  autohash_tied($record)->filter($filter);
  cmp_record("$label after filter",$record,$after_filter);
  # update via set function
  autohash_set($record,%$update);
  cmp_record("$label after update via autohash_set",$record,$after_update);

  # clear should restore intial value
  %$record=();
  cmp_record("$label after clear: initial value restored",$record,$initial_value);

}
sub label_filter {
  my($label,$filter)=@_;
  return "filter sub: $label" if 'CODE' eq ref $filter;
  return "filter  on: $label" if $filter;
  return "filter off: $label";
}
my $sub=sub {map {uc $_} @_};

test_filter('0 keys','filter',
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_filter('0 keys. no dups.',$sub,
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_filter('0 keys. no dups.',undef,
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});

test_filter('2 keys. 0 values.','filter',
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_filter('2 keys. 0 values.',$sub,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_filter('2 keys. 0 values.',undef,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});

test_filter('2 keys. 0 values. dup update','filter',
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]});
test_filter('2 keys. 0 values. dup update',$sub,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]});
test_filter('2 keys. 0 values. dup update',undef,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]});

test_filter('2 keys. single values. no dups.','filter',
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_filter('2 keys. single values. no dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(VALUE11)],key2=>[qw(VALUE21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(VALUE11 value12)],key2=>[qw(VALUE21 value22)]});
test_filter('2 keys. single values. no dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});

test_filter('2 keys. multiple values. dup update.','filter',
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value22 value22)]});
test_filter('2 keys. multiple values. dup update.',$sub,
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(VALUE11 VALUE12)],key2=>[qw(VALUE21 VALUE22)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(VALUE11 VALUE12 value12)],key2=>[qw(VALUE21 VALUE22 value22)]});
test_filter('2 keys. multiple values. dup update.',undef,
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value22 value22)]});

test_filter('2 keys. 1 with dups.','filter',
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value22)]});
test_filter('2 keys. 1 with dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21 VALUE21)]},
	    {key1=>[qw(VALUE11)],key2=>[qw(VALUE21 VALUE21)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22)]},
	    {key1=>[qw(VALUE11 value12 value12)],key2=>[qw(VALUE21 VALUE21 value22)]});
test_filter('2 keys. 1 with dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value21 value22)]});

test_filter('2 keys. mixed unique & dups.','filter',
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value23)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22 value23 value24)]},
	    {key1=>[qw(value11 value12 value12)],
	     key2=>[qw(value21 value22 value23 value22 value23 value24)]});
test_filter('2 keys. mixed unique & dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 VALUE22 value23)]},
	    {key1=>[qw(VALUE11)],key2=>[qw(VALUE21 VALUE22 VALUE22 VALUE23)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22 value23 value24)]},
	    {key1=>[qw(VALUE11 value12 value12)],
	     key2=>[qw(VALUE21 VALUE22 VALUE22 VALUE23 value22 value23 value24)]});
test_filter('2 keys. mixed unique & dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22 value23 value24)]},
	    {key1=>[qw(value11 value12 value12)],
	     key2=>[qw(value21 value22 value22 value23 value22 value23 value24)]});

### less systematic tests formerly in basics
$record=new Hash::AutoHash::Record(multi1=>[qw(value11 value11)]);
cmp_record("initialize key with duplicate",$record,{multi1=>[qw(value11 value11)]});
ok(!tied(%$record)->filter,"filter initially false");
ok(tied(%$record)->filter(1),"set filter to true");
cmp_record("key now unique",$record,{multi1=>[qw(value11)]});
$record->multi1('value11');
cmp_record("key not unique after storing duplicate",$record,{multi1=>[qw(value11 value11)]});

$record=new Hash::AutoHash::Record(multi1=>[qw(value11 value11)]);
ok(tied(%$record)->filter(sub {map {uc $_} @_}),"set filter to sub");
cmp_record("values transformed by filter",$record,{multi1=>[qw(VALUE11 VALUE11)]});

$record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record,
  multi1=>[qw(value11 value11)],multi2=>[qw(value21 value21)]);
cmp_record("initialize many keys. 2 with duplicates",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11 value11)],multi2=>[qw(value21 value21)]});
ok(tied(%$record)->filter(1),"set filter to true");
cmp_record("duplicate keys now unique. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11)],multi2=>[qw(value21)]});
$record->multi1('value11');
cmp_record("key not unique after storing duplicate",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    multi1=>[qw(value11 value11)],multi2=>[qw(value21)]});

$record=new Hash::AutoHash::Record
  (single=>'',multi=>[],avp_single=>{},avp_multi=>\{},nested=>new Hash::AutoHash::Record,
   single1=>'value1',avp_single1=>{key1=>'value1'},avp_multi1=>\{key1=>'value1'},
   avp_nested1=>new Hash::AutoHash::Record(multi2=>['value2']),
   multi1=>[qw(value11 value11)],multi2=>[qw(value21 value21)]);
ok(tied(%$record)->filter(sub {map {uc $_} @_}),"set filter to sub");
cmp_record("multi-values transformed by filter. others unchanged",$record,
	   {single=>'',multi=>[],avp_single=>new_SV,avp_multi=>new_MV,nested=>new_Nested,
	    single1=>'value1',
	    avp_single1=>new_SV(key1=>'value1'),avp_multi1=>new_MV(key1=>'value1'),
	    avp_nested1=>new_Nested(multi2=>['value2']),
	    multi1=>[qw(VALUE11 VALUE11)],multi2=>[qw(VALUE21 VALUE21)]});

done_testing();
