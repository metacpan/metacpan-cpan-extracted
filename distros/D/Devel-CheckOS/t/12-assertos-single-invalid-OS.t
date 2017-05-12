use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;
END { done_testing }

eval "use Devel::AssertOS 'NotAnOperatingSystem'";

like $@, qr/OS unsupported/i;
