#!/usr/bin/env perl
use strict;
use warnings;

use List::UtilsBy;
use List::UtilsBy::XS;

use Benchmark qw(cmpthese);
use String::Random;

my $generator = String::Random->new;
my @array;
for my $i (1..100) {
    push @array, {
        number => int(rand(100)),
        name   => $generator->randregex('[A-Za-z0-9]{8}'),
    };
}

print "Benchmarking List::Util and List::UtilsBy::XS\n";

# sort_by
print "Bench: sort_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::sort_by { $_->{name} } @array },
    xs => sub { List::UtilsBy::XS::sort_by { $_->{name} } @array },
});
print "\n";

# nsort_by
print "Bench: nsort_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::nsort_by { $_->{number} } @array },
    xs => sub { List::UtilsBy::XS::nsort_by { $_->{number} } @array },
});
print "\n";

# rev_sort_by
print "Bench: rev_sort_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::rev_sort_by { $_->{name} } @array },
    xs => sub { List::UtilsBy::XS::rev_sort_by { $_->{name} } @array },
});
print "\n";

# rev_nsort_by
print "Bench: rev_nsort_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::rev_nsort_by { $_->{number} } @array },
    xs => sub { List::UtilsBy::XS::rev_nsort_by { $_->{number} } @array },
});
print "\n";

# max_by
print "Bench: max_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::max_by { $_->{number} } @array },
    xs => sub { List::UtilsBy::XS::max_by { $_->{number} } @array },
});
print "\n";

# min_by
print "Bench: min_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::min_by { $_->{number} } @array },
    xs => sub { List::UtilsBy::XS::min_by { $_->{number} } @array },
});
print "\n";

# uniq_by
print "Bench: uniq_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::uniq_by { $_->{name} } @array },
    xs => sub { List::UtilsBy::XS::uniq_by { $_->{name} } @array },
});
print "\n";

# partition_by
print "Bench: partition_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::partition_by { $_->{name} } @array },
    xs => sub { List::UtilsBy::XS::partition_by { $_->{name} } @array },
});
print "\n";

# count_by
print "Bench: count_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::count_by { $_->{name} } @array },
    xs => sub { List::UtilsBy::XS::count_by { $_->{name} } @array },
});
print "\n";

# zip_by
print "Bench: zip_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::zip_by { $_[0] + $_[1] } [0..100], [100..200] },
    xs => sub { List::UtilsBy::XS::zip_by { $_[0] + $_[1] } [0..100], [100..200] },
});
print "\n";

# unzip_by
print "Bench: unzip_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::unzip_by { ($_, $_) } (0..100) },
    xs => sub { List::UtilsBy::XS::unzip_by { ($_, $_) } (0..100) },
});
print "\n";

# extract_by
print "Bench: zip_by\n";
cmpthese(-1, {
    pp => sub {
        my @array = 1..10;
        List::UtilsBy::extract_by { $_ % 3 } @array;
    },
    xs => sub {
        my @array = 1..10;
        List::UtilsBy::XS::extract_by { $_ % 3 } @array;
    },
});
print "\n";

# weighted_shuffle_by
print "Bench: weighted_shuffle_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::weighted_shuffle_by { 1 } 1..100 },
    xs => sub { List::UtilsBy::XS::weighted_shuffle_by { 1 } 1..100 },
});
print "\n";

# bundle_by
print "Bench: bundle_by\n";
cmpthese(-1, {
    pp => sub { List::UtilsBy::bundle_by { $_[0] + $_[1] } 2, 1..100 },
    xs => sub { List::UtilsBy::XS::bundle_by { $_[0] + $_[1] } 2, 1..100 },
});
print "\n";
