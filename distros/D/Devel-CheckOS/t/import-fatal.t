use strict;
$^W = 1;

use Test::More;
END { done_testing }

use Devel::CheckOS ':fatal';

use File::Spec;
use lib File::Spec->catdir(qw(t lib));

eval { die_if_os_isnt('AnOperatingSystem') };
ok(!$@, "die_if_os_isnt imported");
eval { die_if_os_is('AnOperatingSystem') };
ok($@ =~ /OS unsupported/i, "die_if_os_is imported");
