#!/usr/bin/perl

# Benchmark run on my laptop:
#
# $ ./tools/bench.pl
# Running benchmark for 100 args
# Math::Utils: Ran 23 iterations (3 outliers).
# Math::Utils: Rounded run time per iteration: 3.100e+00 +/- 1.4e-02 (0.5%)
# Math::Utils::XS: Ran 39 iterations (5 outliers).
# Math::Utils::XS: Rounded run time per iteration: 6.686e-02 +/- 3.1e-04 (0.5%)
# Perl: Ran 31 iterations (3 outliers).
# Perl: Rounded run time per iteration: 5.043e-01 +/- 2.5e-03 (0.5%)
#
# So it seems the XS implementation is:
#
# * two orders of magnitude faster than the non-XS one
# * one order of magnitude faster than Perl
use strict;
use warnings;
use blib;
use Dumbbench;
use Data::Dumper;
use Math::Utils       ();
use Math::Utils::XS   ();

exit main();

sub main {
    push @ARGV, 100 unless @ARGV;

    foreach my $arg (@ARGV) {
        run_benchmark($arg);
    }
    return 0;
}

sub run_benchmark {
    my ($top) = @_;

    my @data;
    for (1..$top) {
        push @data, rand(1_000_000 + $_);
    }
    printf("Running benchmark for %d args\n", $top);

    my $iterations = 1e5;
    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 20,
    );

    $bench->add_instances(
        Dumbbench::Instance::PerlSub->new(
            name => 'Math::Utils',
            code => sub {
                for(1..$iterations){
                    Math::Utils::fsum(@data);
                }
            },
        ),
        Dumbbench::Instance::PerlSub->new(
            name => 'Math::Utils::XS',
            code => sub {
                for(1..$iterations){
                    Math::Utils::XS::fsum(@data);
                }
            },
        ),
        Dumbbench::Instance::PerlSub->new(
            name => 'Perl',
            code => sub {
                for(1..$iterations){
                    my $sum = 0;
                    map { $sum += $_ } @data;
                }
            },
        ),
    );

    $bench->run;
    $bench->report;
}
