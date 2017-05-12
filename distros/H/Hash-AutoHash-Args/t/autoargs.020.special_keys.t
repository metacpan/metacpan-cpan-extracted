use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash::Args;
use Hash::AutoHash::Args::V0;

sub test_special_keys {
  my($V,@keys)=@_;
  my $args_class=$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0';
  my $label=$V? 'V1': 'V0';
  # test object class for sanity sake
  my $args=new $args_class;
  is(ref $args,$V? 'Hash::AutoHash::Args': 'Hash::AutoHash::Args::V0',
     "$label class is $args_class - sanity check");

  my $args=new $args_class;
  my(@ok,@fail);
  for my $key (@keys) {
    my $value="value_$key";
    $args->$key($value);	# set value
    my $actual=$args->$key;	# get value
#    ($actual eq $value)? push(@ok,$key): push(@fail,$key);
    is($actual,$value,"$label key=$key");
  }
#   # like 'report'
#   $label.=' special keys';
#   unless (@fail) {
# #     pass("$label. keys=@keys");
#     pass($label);
#   } else {
#     fail($label);
#     diag(scalar(@ok)." keys have correct values: @ok");
#     diag(scalar(@fail)." keys have wrong values: @fail");
#   }
}
my @keys=
  (@COMMON_SPECIAL_KEYS,
   map {my $copy=$_; $copy=~s/^autohash/autoargs/; $copy} @Hash::AutoHash::SUBCLASS_EXPORT_OK);
test_special_keys(0,@keys);

my @keys=
  (@COMMON_SPECIAL_KEYS,
   qw(get_args getall_args set_args fix_args fix_keyword fix_keywords is_keyword is_positional),
   map {my $copy=$_; $copy=~s/^autohash/autoargs/; $copy} @Hash::AutoHash::SUBCLASS_EXPORT_OK);
test_special_keys(1,@keys);

done_testing();
