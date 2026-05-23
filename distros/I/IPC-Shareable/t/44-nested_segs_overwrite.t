use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
use Test::More;

# Verify that overwriting a tied child value with a new reference removes
# the old child segment (no leak for flat overwrites; nested children of
# the overwritten value are a known limitation tracked by the count checks).

my $segs_before = IPC::Shareable::seg_count();
my $sems_before = IPC::Shareable::sem_count();
warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};

# Recursively dereference tied IPC::Shareable refs into plain Perl structures
# so we can run clean_up_all without destroying data we want to compare.
sub untie_deep {
    my ($val) = @_;
    my $type = Scalar::Util::reftype($val) or return $val;

    if ($type eq 'HASH') {
        my %copy;
        for my $k (keys %$val) {
            $copy{$k} = untie_deep($val->{$k});
        }
        return \%copy;
    }
    elsif ($type eq 'ARRAY') {
        return [ map { untie_deep($_) } @$val ];
    }
    elsif ($type eq 'SCALAR') {
        return \ untie_deep($$val);
    }
    return $val;
}

my @test_data = (
    [ 1, 2, 3, [ 26, [ 30, 31 ] ] ],
);
my %test_data = (
    a => {
        a => 1, b => 2, c => 3,
        d => { z => 26, y => { yy => 25 } },
    },
);

for my $serializer ('storable', 'json') {
    subtest "$serializer: array nested overwrite" => sub {
        tie my @a, 'IPC::Shareable', {
            create     => 1,
            destroy    => 1,
            serializer => $serializer,
        };

        my $initial = seg_count();

        $a[0] = [3];
        my $after_first = seg_count();
        is $after_first, $initial + 1, "first child adds one segment";

        $a[0] = [1, 2];
        my $after_overwrite = seg_count();
        is $after_overwrite, $after_first,
            "flat overwrite replaces, no leak";

        $a[0] = [1, 2, 3];
        is seg_count(), $after_first, "flat overwrite again, no leak";

        $a[0] = [1, 2, 3, [26, [30, 31]]];
        is seg_count(), $initial + 3,
            "nested overwrite adds only net-new children";

        my $data = untie_deep([@a]);
        IPC::Shareable->clean_up_all;

        is_deeply $data, \@test_data, "data matches expected";
    };

    subtest "$serializer: hash nested overwrite" => sub {
        tie my %h, 'IPC::Shareable', {
            create     => 1,
            destroy    => 1,
            serializer => $serializer,
        };

        my $initial = seg_count();

        $h{a} = {a => 1};
        my $after_first = seg_count();
        is $after_first, $initial + 1, "first child adds one segment";

        $h{a} = {a => 1, b => 2};
        is seg_count(), $after_first, "flat overwrite replaces, no leak";

        $h{a} = {a => 1, b => 2, c => 3};
        is seg_count(), $after_first, "flat overwrite again, no leak";

        $h{a} = {a => 1, b => 2, c => 3, d => {z => 26}};
        my $after_nested1 = seg_count();
        is $after_nested1, $initial + 2,
            "one-level nested adds only net-new children";

        $h{a} = {a => 1, b => 2, c => 3, d => {z => 26, y => {yy => 25}}};
        my $after_nested2 = seg_count();
        is $after_nested2, $initial + 4,
            "deeper nested adds only net-new children";

        my $data = untie_deep({ %h });
        IPC::Shareable->clean_up_all;

        is_deeply $data, \%test_data, "data matches expected";
    };
}

IPC::Shareable::_end;

my $segs_after = IPC::Shareable::seg_count();
warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
is $segs_after, $segs_before, "All segs cleaned up ok";
my $sems_after = IPC::Shareable::sem_count();
is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

done_testing;

sub seg_count {
    return IPC::Shareable::seg_count();
}