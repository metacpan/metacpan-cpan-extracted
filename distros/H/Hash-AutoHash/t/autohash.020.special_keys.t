use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
require 'autohash.TieMV.pm';	# example tied hash class
my $autohash;
use Hash::AutoHash qw(autohash_new autohash_tie);

test_special_keys(autohash_new,1,undef,'not tied');
test_special_keys(autohash_tie(TieMV),2,sub {[$_[0],$_[0]]},'tied');

# sub test_special_keys ($$) {
#   my($key,$value)=@_;
#   $autohash=autohash_new;
#   $autohash->$key($value);	# set value
#   my $actual=$autohash->$key;	# get value
#   my $correct=$value;
#   cmp_deeply($actual,$correct,"not tied. key=$key");
#   $autohash=autohash_tie TieMV;
#   $autohash->$key($value);	# set value
#   $autohash->$key($value);	# set value
#   my $actual=$autohash->$key;	# get value
#   my $correct=[$value,$value];
#   cmp_deeply($actual,$correct,"tied. key=$key");
# }

# our @keys=(@COMMON_SPECIAL_KEYS,@Hash::AutoHash::EXPORT_OK);
# # my @values=map {"value_$_"} @keys;
# for my $key (@keys) {
#   my $value="value_$key";
#   test_special_keys($key,$value);
# }

done_testing();
