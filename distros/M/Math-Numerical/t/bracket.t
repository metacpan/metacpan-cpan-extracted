use strict;
use warnings;
use utf8;

use Test2::V0;

use Readonly;
use Math::Numerical 'bracket';

use Carp;
use Test2::Tools::Compare 'validator', 'D', 'U';

#$Carp::Verbose = 1;

sub float_lt {
  my ($val) = @_;
  return validator('<', $val, sub { $_ < $val });
}
sub float_gt {
  my ($val) = @_;
  return validator('>', $val, sub { $_ > $val });
}

Readonly my $PI => 4 * atan2(1, 1);

is([bracket(\&CORE::cos, 0, 1)], [float_lt($PI / 2), float_gt($PI / 2), D(), D()]);

is([bracket(\&CORE::cos, 0, 0)], [float_lt($PI / 2), float_gt($PI / 2), D(), D()]);
is([bracket(\&CORE::cos, 0)], [float_lt($PI / 2), float_gt($PI / 2), D(), D()]);

like(scalar(eval { bracket(\&CORE::cos, 0, 0, do_inward => 0, do_outward => 0)}, $@),
     qr/One of do_outward and do_inward at least must be true/);

like(scalar(eval { bracket(\&CORE::cos, 0, 0, max_iterations => 0)}, $@),
     qr/max_iterations must be positive/);

like(scalar(eval { bracket(\&CORE::cos, 0, 0, outward_factor => 1)}, $@),
     qr/outward_factor must be larger than 1/);

like(scalar(eval { bracket(\&CORE::cos, 0, 0, inward_factor => 1.9)}, $@),
     qr/inward_factor must be at least 2/);

like(scalar(eval { bracket(\&CORE::cos, 0, 0, inward_split => 1.9)}, $@),
     qr/inward_split must be at least 2/);

{
  sub f { abs($_[0] - 3) - 1 }  # zeroes in 2 and 4.
  is(bracket(\&f, 0, 1, do_outward => 0), U());
  is([bracket(\&f, 0, 1, do_outward => 1)], [float_lt(2), float_gt(2), D(), D()]);
  is(bracket(\&f, 1, 5, do_inward => 0), U());
  is([bracket(\&f, 1, 5, do_inward => 1)], [float_lt(2), float_gt(2), D(), D()]);

  {
    my ($a, $b, $fa, $fb) = bracket(\&f, 0, 1);
    is($fa, f($a));
    is($fb, f($b));
  }

  {
    my ($a, $b, $fa, $fb) = bracket(\&f, 1, 5);
    is($fa, f($a));
    is($fb, f($b));
  }
}

done_testing;
