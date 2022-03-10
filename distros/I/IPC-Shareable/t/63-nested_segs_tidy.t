use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use IPC::Shareable;
use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a legit CI platform...";
    }
}

warn "Segs Before: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

# array
{
    my @test_data = (
        [
            1,
            2,
            3,
            [
                26,
                [
                    30,
                    31,
                ],
            ],
        ],
    );

    tie my @a, 'IPC::Shareable', {create => 1, destroy => 1, tidy => 1};

    my $initial_seg_count = seg_count();

    is seg_count(), $initial_seg_count, "Initial array seg count ok";

    $a[0] = [3];
    is seg_count(), $initial_seg_count+1, "After initial aref add, seg count ok";

    $a[0] = [1, 2];
    is seg_count(), $initial_seg_count+1, "Adding a new aref to an existing element doesn't create a new seg ok";

    $a[0] = [1, 2, 3];
    is seg_count(), $initial_seg_count+1, "Same with repurposing the aref again";

    $a[0] = [1, 2, 3, [26, [30, 31]]];
    is seg_count(), $initial_seg_count+3, "Same with repurposing the aref again with nested";

    is_deeply \@a, \@test_data, "Nested arrays compare ok";

    IPC::Shareable->clean_up_all;
}

# hash
{
    my %test_data = (
        a => {
            a => 1,
            b => 2,
            c => 3,
            d => {
                z => 26,
                y => {
                    yy => 25,
                },
            },
        }
    );

    tie my %h, 'IPC::Shareable', {create => 1, destroy => 1, tidy => 1};

    my $initial_seg_count = seg_count();

    is seg_count(), $initial_seg_count, "Initial href seg count ok";

    $h{a} = {a => 1};
    is seg_count(), $initial_seg_count+1, "After initial href add, seg count ok";

    $h{a} = {a => 1, b => 2};
    is seg_count(), $initial_seg_count+1, "Adding a new href to an existing key doesn't create a new seg ok";

    $h{a} = {a => 1, b => 2, c => 3};
    is seg_count(), $initial_seg_count+1, "Same with repurposing the href again";

    $h{a} = {a => 1, b => 2, c => 3, d => {z => 26}};
    is seg_count(), $initial_seg_count+2, "Adding a new hash inside of existing does bump seg count";

    $h{a} = {a => 1, b => 2, c => 3, d => {z => 26, y => {yy => 25}}};
    is seg_count(), $initial_seg_count+4, "Adding a new hash inside of two level existing does bump seg count";

    $h{a} = {a => 1, b => 2, c => 3, d => {z => 26, y => {yy => 25}}};
    is seg_count(), $initial_seg_count+6, "Adding a new hash inside of two level existing twice does bump seg count";

    is_deeply \%h, \%test_data, "Shared memory hash matches test data ok";

    IPC::Shareable->clean_up_all;
}

IPC::Shareable::_end;
warn "Segs After: " . IPC::Shareable::ipcs() . "\n" if $ENV{PRINT_SEGS};

done_testing;

sub seg_count {
    my $count = `ipcs -m | wc -l`;
    chomp $count;
    $count =~ s/\s+//g;
    return $count;
}
