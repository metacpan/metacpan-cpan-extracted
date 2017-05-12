use lib qw(t);
use Carp;
use Hash::AutoHash::MultiValued qw(autohash_tied autohash_set);
use Test::More;
use Test::Deep;
use mvhashUtil;

#################################################################################
# test unique. not tested in 030.functions because it relies on autohash_tied
# which is tested separately
#################################################################################

sub test_unique {
  my($label,$unique,$initial_value,$after_unique,$update,$after_update)=@_;
  $label=label_unique($label,$unique);
  my $mvhash=new Hash::AutoHash::MultiValued %$initial_value;
#  cmp_mvhash("$label initial value",$mvhash,$initial_value);
  autohash_tied($mvhash)->unique($unique);
  cmp_mvhash("$label after unique",$mvhash,$after_unique);
 # update via methods
  while(my($key,$value)=each %$update) {
    $mvhash->$key($value);
  }
  cmp_mvhash("$label after update via methods",$mvhash,$after_update);

  # reset mvhash for next test
  my $mvhash=new Hash::AutoHash::MultiValued %$initial_value;
#  cmp_mvhash("$label restore initial value",$mvhash,$initial_value);
  autohash_tied($mvhash)->unique($unique);
  cmp_mvhash("$label after unique",$mvhash,$after_unique);
 # update via hash operations
  @$mvhash{keys %$update}=values %$update;
  cmp_mvhash("$label after update via hash operations",$mvhash,$after_update);

  # reset mvhash for next test
  my $mvhash=new Hash::AutoHash::MultiValued %$initial_value;
#  cmp_mvhash("$label restore initial value",$mvhash,$initial_value);
  autohash_tied($mvhash)->unique($unique);
  cmp_mvhash("$label after unique",$mvhash,$after_unique);
  # update via set function
  autohash_set($mvhash,%$update);
  cmp_mvhash("$label after update via autohash_set",$mvhash,$after_update);
}
sub label_unique {
  my($label,$unique)=@_;
  return "unique sub: $label" if 'CODE' eq ref $unique;
  return "unique  on: $label" if $unique;
  return "unique off: $label";
}
my $sub=sub {my($a,$b)=@_; lc($a) eq lc($b)};

test_unique('0 keys. no dups','unique',
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('0 keys. no dups.',$sub,
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('0 keys. no dups.',undef,
	    {},
	    {},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});

test_unique('2 keys. 0 values.','unique',
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('2 keys. 0 values. no dups.',$sub,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('2 keys. 0 values. no dups.',undef,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});

test_unique('2 keys. 0 values. dup update','unique',
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('2 keys. 0 values. dup update',$sub,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 VALUE11)],key2=>[qw(value21 VALUE21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]});
test_unique('2 keys. 0 values. dup update',undef,
	    {key1=>[],key2=>[]},
	    {key1=>[],key2=>[]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11 value11)],key2=>[qw(value21 value21)]});

test_unique('2 keys. single values. no dups.','unique',
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. single values. no dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. single values. no dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});

test_unique('2 keys. multiple values. dup update.','unique',
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. multiple values. dup update.',$sub,
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value12)],key2=>[qw(VALUE22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. multiple values. dup update.',undef,
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]},
	    {key1=>[qw(value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value22 value22)]});

test_unique('2 keys. 1 with dups.','unique',
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. 1 with dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21 VALUE21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21)]},
	    {key1=>[qw(value12 VALUE12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22)]});
test_unique('2 keys. 1 with dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value21)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22)]},
	    {key1=>[qw(value11 value12 value12)],key2=>[qw(value21 value21 value22)]});

test_unique('2 keys. mixed unique & dups.','unique',
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value23)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22 value23 value24)]},
	    {key1=>[qw(value11 value12)],key2=>[qw(value21 value22 value23 value24)]});
test_unique('2 keys. mixed unique & dups.',$sub,
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 VALUE22 value23)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value23)]},
	    {key1=>[qw(VALUE12 value12)],key2=>[qw(VALUE22 value23 value24)]},
	    {key1=>[qw(value11 VALUE12)],key2=>[qw(value21 value22 value23 value24)]});
test_unique('2 keys. mixed unique & dups.',undef,
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value11)],key2=>[qw(value21 value22 value22 value23)]},
	    {key1=>[qw(value12 value12)],key2=>[qw(value22 value23 value24)]},
	    {key1=>[qw(value11 value12 value12)],
	     key2=>[qw(value21 value22 value22 value23 value22 value23 value24)]});

done_testing();
