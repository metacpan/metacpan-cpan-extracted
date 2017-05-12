######################################################################
# Test suite for Device::MAS345
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Device::MAS345;
use Log::Log4perl qw(:easy);

plan tests => 4;

ok(1);

#Log::Log4perl->easy_init($DEBUG);

SKIP: {
  if(! $ENV{ "LIVE_TEST" } ) {
      skip "No live test by default", 3;
  }

  my $mas = Device::MAS345->new( port => "/dev/ttyS0" );
  my($val, $unit, $mode) = $mas->read();
  is($mode, "TE", "Temperature Mode");
  like($val, qr/00\d\d/, "Temperature Value");
  is($unit, "C", "Celsius");
};
