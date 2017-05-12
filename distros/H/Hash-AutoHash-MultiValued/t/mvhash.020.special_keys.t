use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use mvhashUtil;
use Hash::AutoHash::MultiValued;

my @keys=(@COMMON_SPECIAL_KEYS,@Hash::AutoHash::SUBCLASS_EXPORT_OK);

# test object class for sanity sake
my $mvhash=new Hash::AutoHash::MultiValued;
is(ref $mvhash,'Hash::AutoHash::MultiValued',
   "class is Hash::AutoHash::MultiValued - sanity check");

my $mvhash=new Hash::AutoHash::MultiValued;
my(@ok,@fail);
for my $key (@keys) {
  my $value="value_$key";
  $mvhash->$key($value);	# set value
  my $actual=$mvhash->$key;	# get value
  cmp_deeply($actual,[$value],"$label key=$key");
}

done_testing();
