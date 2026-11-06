package LinkedList::Single::Examples v2.0.1;
use v5.40;

1
__END__

=head1 NAME

LinkedList::Single::Examples - worked examples of LinkedList::Single, each with an array twin, tests and measurements

=head1 SYNOPSIS

    perl Makefile.PL
    make -wk all test

    # the same tests without make, from version/v5.40:
    prove -r t

    # one example, its application and its benchmarks:
    prove -r t/70-Timer
    perl app/70-Timer/timer-queue
    perl benchmarks/70-Timer/compare

=head1 DESCRIPTION

Each example is an application of L<LinkedList::Single> (v2), written
beside an implementation of the same thing with arrays, hashes or both.
Each is compared on code, time and memory, and each comes with tests that
check the list and its twin against one another. The comparison is the
point: the documents state where the list wins and where it does not.

The examples are in their own package space, C<LinkedList::Single::Example>
(C<::LRU>, C<::SlidingWindow>, C<::Handoff>, C<::SortedMerge>,
C<::Ordered>, C<::Timer>), to keep them apart from modules meant for
general use. Each is documented in the stub module C<LinkedList::Single::Example::Name::POD>
(C<package ...; use v5.40; 1; __END__> and then the POD), so that the
documentation can be looked up as a module on MetaCPAN.

An overview of the examples, why these six were chosen and what each
illustrates is in L<LinkedList::Single::Example::POD>.

=head2 Layout

Three trees are numbered alike, one number and name per example; the
number is the example's:

    version/v5.40/
        lib/LinkedList/Single/Example/      the modules and their documentation
            Bench.pm Latency.pm Probe.pm        shared by the examples
            LRU.pm LRU/{Array,Lazy,Order,POD}.pm ...
        app/NN-Name/        programs that use the modules
        benchmarks/NN-Name/ time, memory and code compared with the twin
        t/NN-Name/          the tests
        t/00-Example/       tests of the shared modules
        t/00-syntax/        generated: perl -wc of every module and program
        t/00-pod/           generated: podchecker of every POD.pm
        t/lib/              (optional) test-only overrides
        t/bin/              the generator (install-unit) and its templates

Programs have no F<.pl> extension: they are run as C<perl app/NN-Name/name>
or directly, and nothing needs the extension to be found or installed.

=head2 LinkedList::Single

The examples are installed separately from L<LinkedList::Single> and do
not carry a copy of it: each one has C<use LinkedList::Single qw( v2 )> and
gets the module from the installed copy, which is a prerequisite
(version 2.1.0 or later). Every program, benchmark and test has C<use FindBin::libs>, which adds
the C<lib> directories above it to C<@INC>, nearest first: for a test,
C<t/lib> (test-only overrides, which the programs do not see), then the
examples' C<lib>, and, in the source tree, the module's own C<lib> further
up, so that the examples can be run there before anything is installed.

The tests run in the source tree after C<t/bin/install-unit> has made the
generated tiers: C<prove -r t> from C<version/v5.40>.

=head2 Installing

Only this module is installed by C<make install>; the examples are not
code to be loaded by other programs and are left in the scratch space.

=head1 SEE ALSO

L<LinkedList::Single>, the module the examples are built with.

The examples, each with a twin that uses an array or a hash, a paper that
compares them, a program, a benchmark and tests:

=over 4

=item L<LinkedList::Single::Example::LRU>

A least-recently-used cache with its order in a list. Illustrates stored
cursors as handles, and moving an entry to the front with C<detach> and
C<append_to>.

=item L<LinkedList::Single::Example::SlidingWindow>

Events kept for a period of time. Illustrates the array's best case as a
control, a tail cursor, and memory that returns as a burst expires.

=item L<LinkedList::Single::Example::Handoff>

A work queue passed to a consumer, with cancel by handle and a batch given
back unfinished. Illustrates C<drop> against placeholders, and hand-over of
the whole queue or a batch.

=item L<LinkedList::Single::Example::SortedMerge>

Merge and merge sort on lists. Illustrates relinking nodes against copying
them, and where the public interface is slower than the module's own sort.

=item L<LinkedList::Single::Example::Ordered>

A map in key order, held in a list with an index of markers. Illustrates the
list as the building block of a larger structure, and cutting whole buckets
out as Fragments.

=item L<LinkedList::Single::Example::Timer>

Messages dispatched when their start time has passed. Illustrates cutting a
batch off as a Fragment, C<consume> with a time limit, and putting the
unfinished rest back at the front.

=item L<LinkedList::Single::Example::POD>

An overview of the examples: why these were chosen, what each paper covers,
and what the results show in short, with references.

=back

Each example has a paper, in the C<::POD> module under its name (for
example L<LinkedList::Single::Example::LRU::POD>).
