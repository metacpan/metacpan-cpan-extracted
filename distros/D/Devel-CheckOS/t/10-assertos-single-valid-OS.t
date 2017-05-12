use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;
END { done_testing }

use_ok('Devel::AssertOS', 'AnOperatingSystem');
