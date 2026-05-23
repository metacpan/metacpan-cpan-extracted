use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

# locking

my $pid = fork;
defined $pid or die "Cannot fork: $!\n";

if ($pid == 0) {
    # child

    sleep unless $awake;

    my $ch = $mod->new(key => 'hash2');
    $ch->{child} = 'child';

    my $ca = $mod->new(key => 'array2', var => 'ARRAY');
    $ca->[1] = 'child';

    my $cs = $mod->new(key => 'scalar2', var => 'SCALAR');
    $$cs = 'child';

} else {
    # parent

    my $ph = $mod->new(key => 'hash2', create => 1, destroy => 1);
    like tied(%$ph), qr/IPC::Shareable/, "new() tied hash is proper object ok";
    like tied(%$ph)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    my $pa = $mod->new(key => 'array2', create => 1, destroy => 1, var => 'ARRAY');
    like tied(@$pa), qr/IPC::Shareable/, "new() tied array is proper object ok";
    like tied(@$pa)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    my $ps = $mod->new(key => 'scalar2', create => 1, destroy => 1, var => 'SCALAR');
    like tied($$ps), qr/IPC::Shareable/, "new() tied scalar is proper object ok";
    like tied($$ps)->can('seg_count'), qr/CODE/, "...and it can call its methods ok";

    kill ALRM => $pid;
    waitpid($pid, 0);

    is $ph->{child}, 'child', 'child set the hash value ok';
    is $pa->[1], 'child', 'child set the array value ok';
    is $$ps, 'child', 'child set the scalar value ok';

    $ph->{parent} = 'parent';
    is $ph->{parent}, 'parent', 'parent set the hash value ok';

    $pa->[0] = 'parent';
    is $pa->[0], 'parent', 'parent set the array value ok';

    $$ps = "parent";
    is $$ps, 'parent', 'parent set the scalar value ok';

    IPC::Shareable->clean_up_all;

    my $segs_after = IPC::Shareable::seg_count();
    warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
    is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
    my $sems_after = IPC::Shareable::sem_count();
    is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

    done_testing();
}

