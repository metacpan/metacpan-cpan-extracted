use strict;
use warnings;

use Data::Dumper;
use Test::More;
use IPC::Shareable;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

my $knot = tie my %hv, $mod, {
    create     => 1,
    key        => 1234,
    destroy    => 1,
};

my $seg = $knot->seg;

my $stats = $seg->stats;

my @stat_list = IPC::Shareable::SharedMem::stat_list();

for (@stat_list) {
    my $data = $seg->stat->$_;

    like $data, qr/^\d+$/, "$_ segment stat returned an integer properly";

    is $data, $stats->{$_}, "stats() and stat $_ method data lines up ok";
}

# Verify segsz matches what we requested (catches platform-specific
# shmid_ds unpack bugs like the 64-bit Solaris/illumos offset fix).
cmp_ok $seg->stat->segsz, '>=', IPC::Shareable::SHM_BUFSIZ,
    'segsz from stat() is at least the requested segment size';

$hv{a} = {b => {c => 1}};

# print Dumper \%hv;
# print Dumper $knot->seg->stats;
#print Dumper $stats;
#print Dumper $knot;
#print Dumper $seg;

{
    # nattch tracks processes currently holding a shmat() attachment.
    # Perl's shmread/shmwrite are atomic at the C level (shmat -> op -> shmdt),
    # so nattch is always 0 by the time control returns to Perl -- there is no
    # Perl-visible moment where the segment is "still attached".

    my $knot2 = tie my %hv2, $mod, { create => 1, key => 5678, destroy => 1 };
    my $seg2  = $knot2->seg;

    is $seg2->stat->nattch, 0, 'nattch is 0 before any I/O';

    $hv2{a} = 1;
    $hv2{b} = 2;
    my $val = $hv2{a};

    is $seg2->stat->nattch, 0,
        'nattch is 0 after writes+read complete: shmat+shmdt finish inside shmread/shmwrite before Perl sees the result';

    is $seg2->stat->cpid, $$, 'cpid matches current PID';
    is $seg2->stat->lpid, $$, 'lpid matches current PID after I/O';
}

SKIP: {
    skip 'nattch > 0 test requires RELEASE_TESTING=1', 2 unless $ENV{RELEASE_TESTING};

    # To observe nattch > 0 we must hold an shmat() attachment open at the
    # Perl level, which requires calling shmat(2) directly via Inline::C.
    # Perl's own shmread/shmwrite complete the full shmat->op->shmdt cycle
    # inside a single C function, so nattch is never > 0 from pure Perl.

    require Inline;
    Inline->import(C => <<'END_C');
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
void* shmat_hold(int id) {
    return shmat(id, NULL, 0);
}
void shmdt_release(void* addr) {
    shmdt(addr);
}
END_C

    my $knot3 = tie my %hv3, $mod, { create => 1, key => 9012, destroy => 1 };
    my $seg3  = $knot3->seg;

    my $addr = shmat_hold($seg3->id);
    is $seg3->stat->nattch, 1, 'nattch is 1 while shmat() attachment is held open via Inline::C';

    shmdt_release($addr);
    is $seg3->stat->nattch, 0, 'nattch drops back to 0 after shmdt()';
}

IPC::Shareable->clean_up_all;

is %hv, '', "hash deleted after clean_up()";

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();


