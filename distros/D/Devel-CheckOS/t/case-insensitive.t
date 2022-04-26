use strict;
use warnings;

use File::Spec;
use lib; # no import yet!

use Test::More;

use Devel::CheckOS qw(list_platforms list_family_members os_is os_isnt);

my $platform = find_platform();

# some platforms have all-upper names, so check the lower-case version as well
ok(os_is(uc($platform)), "os_is('".uc($platform)."')");
ok(os_is(lc($platform)), "os_is('".lc($platform)."')");

lib->import(File::Spec->catdir(qw(t lib)));

ok(
    os_is(
        'anoperatingsystem',
        os_is('Linux') ? 'Irix' : 'Linux'
    ),
    "case-insensitive works for multiple targets"
);
ok(
    os_is(
        (os_is('Linux') ? 'Irix' : 'Linux'),
        'anoperatingsystem'
    ),
    "... regardless of order"
);
ok(
    !os_isnt(
        (os_is('Linux') ? 'Irix' : 'Linux'),
        'anoperatingsystem'
    ),
    "os_isnt is also case-insensitive"
);

done_testing;

sub find_platform {
    foreach my $platform (list_platforms()) {
        if(os_is($platform)) {
            return $platform;
        }
    }
}
