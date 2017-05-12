use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use recordUtil;
use Hash::AutoHash::Record;

my @keys=(@COMMON_SPECIAL_KEYS,@Hash::AutoHash::SUBCLASS_EXPORT_OK);

# test object class for sanity sake
my $record=new Hash::AutoHash::Record;
is(ref $record,'Hash::AutoHash::Record',
   "class is Hash::AutoHash::Record - sanity check");

my $record=new Hash::AutoHash::Record;
my(@ok,@fail);
for my $key (@keys) {
  my $value="value_$key";
  $record->$key($value);	# set value
  my $actual=$record->$key;	# get value
  cmp_deeply($actual,$value,"$label key=$key");
}

done_testing();
