use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash::AVPairsSingle;

my @keys=(@COMMON_SPECIAL_KEYS,@Hash::AutoHash::SUBCLASS_EXPORT_OK);

# test object class for sanity sake
my $avp=new Hash::AutoHash::AVPairsSingle;
is(ref $avp,'Hash::AutoHash::AVPairsSingle',
   "class is Hash::AutoHash::AVPairsSingle - sanity check");

my $avp=new Hash::AutoHash::AVPairsSingle;
my(@ok,@fail);
for my $key (@keys) {
  my $value="value_$key";
  $avp->$key($value);	        # set value
  my $actual=$avp->$key;	# get value
  cmp_deeply($actual,$value,"$label key=$key");
}

done_testing();
