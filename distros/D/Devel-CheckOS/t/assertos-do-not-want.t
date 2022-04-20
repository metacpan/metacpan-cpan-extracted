use strict;
$^W = 1;

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

use Test::More;

eval "use Devel::AssertOS qw/ -NotAnOperatingSystem /";
is $@ => '', "do not want, not our OS, all is good";

eval "use Devel::AssertOS qw/ -notanoperatingsystem /";
is $@ => '', "do not want, not our OS, case-insensitively, all is good";

eval "use Devel::AssertOS qw/ -AnOperatingSystem /";
like $@ => qr/OS unsupported/, "do not want our OS => dying";

eval "use Devel::AssertOS qw/ -anoperatingsystem /";
like $@ => qr/OS unsupported/, "do not want our OS case-insensitively => dying";

eval "use Devel::AssertOS qw/ -NotAnOperatingSystem AnOperatingSystem /";
is $@ => '', 'negative + positive assertions successful';

eval "use Devel::AssertOS qw/ NotAnOperatingSystem -AnOperatingSystem /";
like $@ => qr/OS unsupported/, 'negative + positive assertions failing';

done_testing;
