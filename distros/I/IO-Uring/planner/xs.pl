#! perl

use strict;
use warnings;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Alien');
add_xs(
	alien => [ 'liburing' ],
);
