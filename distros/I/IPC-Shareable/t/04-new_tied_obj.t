use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

my $ph = $mod->new(
    key => 'hash',
    create => 1,
    destroy => 1
);

my $k = tied %$ph;

is ref $k, 'IPC::Shareable', "tied() returns a proper IPC::Shareable object ok";
is exists $k->{attributes}, 1, "...and it has proper attributes ok";

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();
