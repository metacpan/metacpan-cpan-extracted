# Error found when using Mojolicious with this application - in a pre-forking
# environment, or a non threaded environment, the filehandle for DATA is opened
# once, and then a reference is passed to all sub references. Obviously, after
# that the first one to read from it will have moved the seek position in the
# file, and so when another process reads from the file it will continue where
# the previous one left off.
#
# As the contents of %OUTCODES depends on reading the DATA correctly every
# time, this test makes sure that on subsequent reads of the data, the file is
# read consistently from the same place.

use Test::More;

use strict;
use warnings;

use Geo::UK::Postcode::Regex;

my $pkg = 'Geo::UK::Postcode::Regex';

note "checking validation - block 1";
is_deeply $pkg->parse( 'AB11 1AA' ), {
  area => "AB",
  district => 11,
  incode => "1AA",
  outcode => "AB11",
  partial => 0,
  sector => 1,
  strict => 1,
  subdistrict => undef,
  unit => "AA",
  valid => 1,
}, 'Valid Geo Postcode';
is_deeply $pkg->parse( 'BX12 1AA' ), {
  area => "BX",
  district => 12,
  incode => "1AA",
  non_geographical => 1,
  outcode => "BX12",
  partial => 0,
  sector => 1,
  strict => 1,
  subdistrict => undef,
  unit => "AA",
  valid => 1
}, 'Valid Non-Geo Postcode';

# Empty Outcodes cache - this emulates running in a preforking, non-threaded
# environment where one of the forks has read the open filehandle, and another
# has not.
my $outcodes = Geo::UK::Postcode::Regex->outcodes_lookup;
delete Geo::UK::Postcode::Regex->outcodes_lookup->{$_} for keys %$outcodes;

note "checking validation - block 2";
is_deeply $pkg->parse( 'AB11 1AA' ), {
  area => "AB",
  district => 11,
  incode => "1AA",
  outcode => "AB11",
  partial => 0,
  sector => 1,
  strict => 1,
  subdistrict => undef,
  unit => "AA",
  valid => 1,
}, 'Valid Geo Postcode';
is_deeply $pkg->parse( 'BX12 1AA' ), {
  area => "BX",
  district => 12,
  incode => "1AA",
  non_geographical => 1,
  outcode => "BX12",
  partial => 0,
  sector => 1,
  strict => 1,
  subdistrict => undef,
  unit => "AA",
  valid => 1
}, 'Valid Non-Geo Postcode';

done_testing();
