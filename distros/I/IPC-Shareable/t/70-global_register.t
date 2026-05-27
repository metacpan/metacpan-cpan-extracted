use strict;
use warnings;

use Data::Dumper;
use Test::More;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $mod = 'IPC::Shareable';

# Bug 38: Ensure global register populates before access to the underlying
# data
{
    # Global register
    {
        my ($knot, %hv);

        {
            $knot = tie my %hv, $mod, {
                create  => 1,
                key     => 'testing123',
                destroy => 1,
            };

            my $id = $knot->seg->id;
            my $key = $knot->seg->key;

            my $dump = Dumper tied(%hv)->global_register;

            is grep(/\s+'$id'\s+/, $dump), 1, "Segment ID is in the global_register Dumper output ok";
            is grep(/'_key' => $key/, $dump), 1, "So is the key in global_register output";
        }

        is % hv, 0, "hash deleted after we go out of scope";
    }
    # Process register
    {
        my ($knot, %hv);

        {
            $knot = tie my %hv, $mod, {
                create  => 1,
                key     => 'testing123',
                destroy => 1,
            };

            my $id = $knot->seg->id;
            my $key = $knot->seg->key;

            my $dump = Dumper tied(%hv)->process_register;

            is grep(/\s+'$id'\s+/, $dump), 1, "Segment ID is in the process_register Dumper output ok";
            is grep(/'_key' => $key/, $dump), 1, "So is the key in process_register output";
        }

        is % hv, 0, "hash deleted after we go out of scope";
    }
}

IPC::Shareable->clean_up_all;
IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};

is $segs_after, $segs_before, "All segs, even those created in separate procs, cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();


