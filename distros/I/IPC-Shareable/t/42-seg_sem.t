use warnings;
use strict;

use Carp;
use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

my $k = tie my %hv, 'IPC::Shareable', 'test', { create => 1, destroy => 1 , serializer => 'storable' };

# seg()

my @seg_keys = qw(
    id
    key
    key_hex
    flags
    mode
    type
    size
);

my $knot_seg = $k->seg;
my $tied_seg = (tied %hv)->seg;

is ref $knot_seg, 'IPC::Shareable::SharedMem', "knot seg() is the proper object";
is ref $tied_seg, 'IPC::Shareable::SharedMem', "tied seg() is the proper object";

is keys %$knot_seg, scalar @seg_keys, "knot hash has the proper number of keys";
is keys %$tied_seg, scalar @seg_keys, "tied hash has the proper number of keys";

for (@seg_keys) {
    is exists $knot_seg->{$_}, 1, "$_ key exists in knot hash ok";
    is exists $tied_seg->{$_}, 1, "$_ key exists in tied hash ok";
}

is $knot_seg->id, $tied_seg->id, "knot and tied seg() hashes have the same id";

$hv{a}->{b}{c} = 143;

my $top_level_seg = tied(%hv)->seg;
my $bot_level_seg = tied(%{ $hv{a}->{b} })->seg;

isnt $top_level_seg->id, $bot_level_seg->id, "top level and bot level seg() hashes have different ids";

# sem()

my $knot_sem = $k->sem();
my $tied_sem = (tied %hv)->sem;

is ref $knot_sem, 'IPC::Semaphore', "knot sem() is the proper object";
is ref $tied_sem, 'IPC::Semaphore', "tied sem() is the proper object";

is $knot_sem->id, $tied_sem->id, "knot and tied sem() hashes have the same id";

my $top_level_sem = tied(%hv)->sem;
my $bot_level_sem = tied(%{ $hv{a}->{b} })->sem;

print Dumper $top_level_sem;
isnt $top_level_sem->id, $bot_level_sem->id, "top level and bot level sem() hashes have different ids";

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing();

