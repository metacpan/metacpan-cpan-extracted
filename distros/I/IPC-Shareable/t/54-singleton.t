use warnings;
use strict;

use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# bad param

my $ok = eval { IPC::Shareable->singleton(); 1 };
is $ok, undef, "singleton() croaks if no GLUE param sent in";
like $@, qr/GLUE parameter/, "...and error is sane";

# singleton no exit notice

my ($proc, $warning);

{
    local $SIG{__WARN__} = sub {$warning = shift;};

    $proc = IPC::Shareable->singleton('LOCK');

    is $proc, $$, "process ID $$ returned from singleton() ok on first call";

    $proc = -1;

    is $proc, -1, "\$proc set to -1 ok";

    $proc = IPC::Shareable->singleton('LOCK');
}

END {
    is $proc, -1, "singleton() on second call doesn't return anything ok";
    is $warning, undef, "singleton outputs no warnings by default";

    IPC::Shareable::_end;

    my $segs_after = IPC::Shareable::seg_count();
    warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
    is $segs_after, $segs_before, "All segs cleaned up ok";
    my $sems_after = IPC::Shareable::sem_count();
    is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

    done_testing;
};
