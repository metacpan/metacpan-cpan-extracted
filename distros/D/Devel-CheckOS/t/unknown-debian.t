use strict;
use warnings;

use Test::More;
plan skip_all => "This isn't Debian-ish"  unless os_is('Linux::Debian');

use Devel::CheckOS qw(os_is list_family_members);

ok(
    (os_is(grep { $_ ne 'Linux::UnknownDebianLike' } list_family_members('Linux::Debian')) ? 1 : 0) +
    (os_is('Linux::UnknownDebianLike')                                                     ? 1 : 0) == 1,
    "OS isn't both UnknownDebianLike and some known Debian variant"
);

done_testing();
