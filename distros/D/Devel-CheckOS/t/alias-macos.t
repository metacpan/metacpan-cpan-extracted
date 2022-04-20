use strict;
use warnings;

use Devel::CheckOS qw(os_is os_isnt list_family_members);

use Test::More;

if(os_is('MacOSX')) {
    ok(os_is('MacOS'), "the alias works");
    ok(os_is('MACOS'), "... case-insensitively");
} else {
    ok(os_isnt('MacOS'), "the alias doesn't work because you're not on a Mac");
    ok(os_isnt('MACOS'), "... case-insensitively");
}

done_testing();
