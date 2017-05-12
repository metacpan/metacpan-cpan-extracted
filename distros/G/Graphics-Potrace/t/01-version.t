# vim: filetype=perl :
use strict;
use warnings;

use Test::More tests => 1; # last test to print
#use Test::More 'no_plan';  # substitute with previous line when done

use Graphics::Potrace;
like Graphics::Potrace::version(), qr{potracelib \d};

