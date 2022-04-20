use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;

eval "use Devel::AssertOS 'NotAnOperatingSystem'";

like $@, qr/OS unsupported/i;

done_testing;
