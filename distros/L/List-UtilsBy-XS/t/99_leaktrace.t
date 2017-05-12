#!perl
use strict;
use warnings;

BEGIN {
    use Test::More;

    eval "use Test::LeakTrace";
    plan skip_all => "Test::LeakTrace required for memory leak testing" if $@;

    use List::UtilsBy::XS qw(:all);
};

no_leaks_ok {
    my @a = sort_by { $_ } 1 .. 10;
} 'sort_by';

no_leaks_ok {
    my @a = nsort_by { $_ } 1 .. 10;
} 'nsort_by';

no_leaks_ok {
    my @a = max_by { $_ } 1 .. 10;
} 'max_by';

no_leaks_ok {
    my @a = uniq_by { $_ } 1 .. 10;
} 'uniq_by';

no_leaks_ok {
    my %a = partition_by { $_ } 1 .. 10;
} 'partition_by';

no_leaks_ok {
    my %a = count_by { $_ } 1 .. 10;
} 'count_by';

no_leaks_ok {
    my @a = zip_by { $_ } [1..10], [1..10];
} 'zip_by';

no_leaks_ok {
    my @a = unzip_by { $_ } 1..10;
} 'unzip_by';

my @array = (1..10);
no_leaks_ok {
    my @a = extract_by { $_ } @array;
} 'extract_by';

my @array2 = (1..10);
no_leaks_ok {
    my $a = extract_by { $_ } @array2;
} 'extract_by with scalar context';

no_leaks_ok {
    my @a = weighted_shuffle_by { $_ } 1..10;
} 'weighted_shuffle_by';

no_leaks_ok {
    my @a = bundle_by { $_ } 1..10;
} 'bundle_by';

done_testing;
