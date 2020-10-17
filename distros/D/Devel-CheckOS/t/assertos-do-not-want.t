use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;
END { done_testing }

eval "use Devel::AssertOS qw/ -NotAnOperatingSystem /";

is $@ => '', "do not want, not our OS, all is good";

eval "use Devel::AssertOS qw/ -AnOperatingSystem /";

like $@ => qr/OS unsupported/, "do not want our OS => dying";

$@ = undef;

eval "use Devel::AssertOS qw/ -NotAnOperatingSystem AnOperatingSystem /";

is $@ => '', 'negative + positive assertions successful';

eval "use Devel::AssertOS qw/ NotAnOperatingSystem -AnOperatingSystem /";

like $@ => qr/OS unsupported/, 'negative + positive assertions failing';
