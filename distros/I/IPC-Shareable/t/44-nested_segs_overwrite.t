use warnings;
use strict;

use Data::Dumper;
use IPC::Shareable;
IPC::Shareable->testing_set('IPC::Shareable');
use Test::More;

use FindBin;
use lib $FindBin::Bin;
use IPCShareableTest qw(unique_glue assert_clean live_seg_count);

# Verify that overwriting a tied child value with a new reference removes
# the old child segment (no leak for flat overwrites; nested children of
# the overwritten value are a known limitation tracked by the count checks).

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
        my $glue = unique_glue("nested_av_$serializer");

        tie my @a, 'IPC::Shareable', {
            key        => $glue,
            create     => 1,
            destroy    => 1,
            serializer => $serializer,
        };

        my $initial = live_seg_count();

        $a[0] = [3];
        my $after_first = live_seg_count();
        is $after_first, $initial + 1, "first child adds one segment";

        $a[0] = [1, 2];
        my $after_overwrite = live_seg_count();
        is $after_overwrite, $after_first,
            "flat overwrite replaces, no leak";

        $a[0] = [1, 2, 3];
        is live_seg_count(), $after_first, "flat overwrite again, no leak";

        $a[0] = [1, 2, 3, [26, [30, 31]]];
        is live_seg_count(), $initial + 3,
            "nested overwrite adds only net-new children";

        my $data = untie_deep([@a]);
        IPC::Shareable->clean_up_all;

        is_deeply $data, \@test_data, "data matches expected";
    };

    subtest "$serializer: hash nested overwrite" => sub {
        my $glue = unique_glue("nested_hv_$serializer");

        tie my %h, 'IPC::Shareable', {
            key        => $glue,
            create     => 1,
            destroy    => 1,
            serializer => $serializer,
        };

        my $initial = live_seg_count();

        $h{a} = {a => 1};
        my $after_first = live_seg_count();
        is $after_first, $initial + 1, "first child adds one segment";

        $h{a} = {a => 1, b => 2};
        is live_seg_count(), $after_first, "flat overwrite replaces, no leak";

        $h{a} = {a => 1, b => 2, c => 3};
        is live_seg_count(), $after_first, "flat overwrite again, no leak";

        $h{a} = {a => 1, b => 2, c => 3, d => {z => 26}};
        my $after_nested1 = live_seg_count();
        is $after_nested1, $initial + 2,
            "one-level nested adds only net-new children";

        $h{a} = {a => 1, b => 2, c => 3, d => {z => 26, y => {yy => 25}}};
        my $after_nested2 = live_seg_count();
        is $after_nested2, $initial + 4,
            "deeper nested adds only net-new children";

        my $data = untie_deep({ %h });
        IPC::Shareable->clean_up_all;

        is_deeply $data, \%test_data, "data matches expected";
    };
}

IPC::Shareable::_end;

assert_clean(
    unique_glue('nested_av_storable'), unique_glue('nested_hv_storable'),
    unique_glue('nested_av_json'),     unique_glue('nested_hv_json'),
);

done_testing;