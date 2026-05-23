use warnings;
use strict;

use IPC::Shareable;
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# non-graceful
{
    tie my $sv, 'IPC::Shareable', {
        key     => 'lock',
        create  => 1,
        exclusive => 1,
        destroy => 1,
        serializer => 'storable',
    };

    my $catch = eval {
        tie my $sv2, 'IPC::Shareable', {
            key     => 'lock',
            create  => 1,
            exclusive => 1,
            destroy => 1,
            serializer => 'storable',
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
        destroy => 1,
        serializer => 'storable',
    };

    tie my $sv2, 'IPC::Shareable', {
        key     => 'DONE',
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1,
        serializer => 'storable',
    };
}

END {
    is
        $@,
        '',
        "with 'graceful', we silently exit if two attempts made on same exclusive seg";

    IPC::Shareable::_end;

    my $segs_after = IPC::Shareable::seg_count();
    warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
    is $segs_after, $segs_before, "All segs cleaned up ok";
    my $sems_after = IPC::Shareable::sem_count();
    is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

    done_testing;
};
