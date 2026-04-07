#! perl

use strict;
use warnings;

use POSIX 'uname';

my ($os, $release) = (uname)[0, 2];
print "Running $os $release\n";
my ($version) = $release =~ /^(\d+\.\d+)/;
die "No support for OS\n" if $version < 6.0;

load_extension('Dist::Build::XS');
load_extension('Dist::Build::XS::Alien');
add_xs(
	alien => [ 'liburing' ],
);
