use warnings;
use strict;

use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

# non-graceful
{
    tie my $sv, 'IPC::Shareable', {
        key     => 'lock',
        create  => 1,
        exclusive => 1,
        destroy => 1
    };

    my $catch = eval {
        tie my $sv2, 'IPC::Shareable', {
            key     => 'lock',
            create  => 1,
            exclusive => 1,
            destroy => 1
        };
        1;
    };

    is
        $catch,
        undef,
        "without 'graceful', we croak if two attemps made on same exclusive seg";

    like
        $@,
        qr/using exclusive/,
        "...and error message is sane";
}

# graceful
my $catch;

{
    tie my $sv, 'IPC::Shareable', {
        key     => 'DONE',
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1
    };

    tie my $sv2, 'IPC::Shareable', {
        key     => 'DONE',
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1
    };
}

END {
    is
        $@,
        '',
        "with 'graceful', we silently exit if two attempts made on same exclusive seg";

    IPC::Shareable::_end;
    warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

    done_testing;
};
