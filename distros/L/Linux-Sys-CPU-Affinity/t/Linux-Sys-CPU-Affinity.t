package main;

use utf8;
use strict;
use warnings;

use Test::LeakTrace qw/ no_leaks_ok /;
use Test::Deep qw/ cmp_deeply /;
use Test::More ('import' => [qw/ isa_ok is ok use_ok done_testing plan diag /]);
BEGIN { use_ok('Linux::Sys::CPU::Affinity') };

my $MIN_CPU_CORES = 4;

if (Linux::Sys::CPU::Affinity::get_nprocs() < $MIN_CPU_CORES) {
    my $msg = "Too low amount of CPU cores. At least test requires ${MIN_CPU_CORES} CPU cores.";
    #plan('skip_all' => $msg);
    diag("Skipping test. ${msg}");
} else {

    my $ca;
    my @cpus;

    # check the empty constructor
    $ca = Linux::Sys::CPU::Affinity->new();
    is($ca->cpu_count(), 0, "Checking the CPU_COUNT for empty set in the constructor");
    isa_ok($ca, 'Linux::Sys::CPU::Affinity', 'Checking the class name');

    # check the non-empty constructor
    @cpus = (0 .. 1);
    $ca = Linux::Sys::CPU::Affinity->new(\@cpus);
    is($ca->cpu_count(), scalar(@cpus), "Checking the CPU_COUNT for non-empty set in the constructor");
    ok($ca->cpu_isset(1), "Checking the CPU_ISSET for existing CPU in the set");
    ok(! $ca->cpu_isset(21), "Checking the CPU_ISSET for non-existing CPU in the set");

    is($ca->cpu_clr(1), undef, "Checking the return value for CPU_CLR method");
    ok(! $ca->cpu_isset(1), "Checking the CPU_CLR result in the set by using CPU_ISSET");
    is($ca->cpu_count(), scalar(@cpus) - 1, "Checking the CPU_CLR result in the set by using CPU_COUNT");
    cmp_deeply($ca->get_cpus(), [0], "Checking the return value for 'get_cpus' method");

    is($ca->cpu_set(1), undef, "Checking the return value for CPU_SET method");
    ok($ca->cpu_isset(1), "Checking the CPU_SET result in the set by using CPU_ISSET");
    is($ca->cpu_count(), scalar(@cpus), "Checking the CPU_CLR result in the set by using CPU_COUNT");
    cmp_deeply($ca->get_cpus(), [0, 1], "Checking the return value for 'get_cpus' method");

    is($ca->cpu_zero(), undef, "Checking the return value for CPU_ZERO method");
    is($ca->cpu_count(), 0, "Checking the CPU_ZERO result in the set by using CPU_COUNT");

    @cpus = (1 .. 3);
    is($ca->reset(\@cpus), undef, "Checking the return value for 'reset' method with non-empty list");
    is($ca->cpu_count(), scalar(@cpus), "Checking the non-empty 'reset' result in the set by using CPU_COUNT");

    is($ca->reset(), undef, "Checking the return value for 'reset' method with empty list");
    is($ca->cpu_count(), 0, "Checking the empty 'reset' result in the set by using CPU_COUNT");

    $ca->reset(\@cpus);

    is($ca->set_affinity($$), 0, "Checking the return value for 'set_affinity' method");
    cmp_deeply($ca->get_affinity($$), \@cpus, "Checking the return value for 'get_affinity' method");

    # Check cloning

    $ca->reset(\@cpus);

    my $clone = $ca->clone();

    ok($ca->cpu_equal($clone), "Checking the similarity of cloned and original objects");
    cmp_deeply($ca->get_cpus(), $clone->get_cpus(), "Checking the similarity of cloned and original objects");

    $ca->cpu_clr(1);

    ok(!$ca->cpu_equal($clone), "Checking the differencies of cloned and original objects");
    cmp_deeply($ca->get_cpus(), [2..3], "Checking the cpuset set of original objects");
    cmp_deeply($clone->get_cpus(), [1..3], "Checking the cpuset set of cloned objects (it shouldn be changed)");

    # check logical methods
    # xor
    
    my $xor = $ca->cpu_xor($ca->clone());
    cmp_deeply($xor->get_cpus(), [], "Checking the emptiness of cpuset");

    $xor = $ca->cpu_xor($clone);
    cmp_deeply($xor->get_cpus(), [1], "Checking the content of cpuset");

    # and    
    my $and = $ca->cpu_and($clone);
    cmp_deeply($and->get_cpus(), [2..3], "Checking the intersection of cpusets");

    # or
    my $or = $ca->cpu_or($clone);
    cmp_deeply($or->get_cpus(), [1..3], "Checking the union of cpusets");

    undef($ca);

    # check for memory leaks
    no_leaks_ok {

        $ca = Linux::Sys::CPU::Affinity->new([0 .. 1]);

        $ca->clone();
        
        $ca->set_affinity($$);
        $ca->get_affinity($$);

        $ca->get_cpus();

        $ca->cpu_count();
        $ca->cpu_isset(0);
        $ca->cpu_equal( $ca->clone() );
        $ca->cpu_clr(1);
        $ca->cpu_set(1);
        $ca->cpu_and( $ca->clone() );
        $ca->cpu_xor( $ca->clone() );
        $ca->cpu_or( $ca->clone() );

        $ca->cpu_zero();

        $ca->reset([0]);

        Linux::Sys::CPU::Affinity::get_nprocs();

    } 'no memory leaks';
}

done_testing();

1;
__END__
