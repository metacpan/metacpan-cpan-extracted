use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use Hash::AutoHash;
# use autohashUtil;

################################################################################
# @EXPORT_OK, @SUBCLASS_EXPORT_OK are hard-coded, but make sure they aren't
#  messed up by computation used for subclasses
# %EXPORT_OK computed in all cases
################################################################################
my @constructors_export_ok=
  qw(autohash_new autohash_hash autohash_tie autohash_wrap autohash_wraptie autohash_wrapobj);
my @subclass_export_ok=
  qw(autohash_clear autohash_delete autohash_each autohash_exists autohash_keys autohash_values 
     autohash_get autohash_set autohash_count autohash_empty autohash_notempty 
     autohash_alias autohash_tied autohash_destroy autohash_untie);
my @export_ok=(@constructors_export_ok,@subclass_export_ok);
my %export_ok=map {$_=>"Hash::AutoHash::helper::$_"} @export_ok;

cmp_set(\@Hash::AutoHash::EXPORT_OK,\@export_ok,'@EXPORT_OK');
cmp_set(\@Hash::AutoHash::SUBCLASS_EXPORT_OK,\@subclass_export_ok,'@SUBCLASS_EXPORT_OK');
cmp_deeply(\%Hash::AutoHash::EXPORT_OK,\%export_ok,'%EXPORT_OK');

done_testing();
