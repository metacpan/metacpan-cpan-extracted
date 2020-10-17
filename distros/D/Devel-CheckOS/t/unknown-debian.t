use strict;
use warnings;

use Test::More;

use Devel::CheckOS qw(os_is);

SKIP: {
    skip "This isn't Debian-ish", 1 unless os_is('Debian');
    ok(
        (os_is(map { "Linux::$_" } qw(Raspbian Ubuntu RealDebian)) ? 1 : 0) +
        (os_is('Linux::UnknownDebianLike')                         ? 1 : 0) == 1,
        "OS isn't both UnknownDebianLike and some known Debian variant"
    );
}

done_testing();
