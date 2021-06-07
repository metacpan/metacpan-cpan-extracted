#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Game::Entities;
use Time::HiRes 'time';
use List::Util 'pairs';

use  experimental 'signatures';

package A { sub new ($class, %args) { bless \%args, $class } }
@B::ISA = @C::ISA = 'A';

my $sets = 3;

subtest 'Baseline' => sub {
    my $start;
    my $R = Game::Entities->new;
    my $iterations = 10_000;

    diag '';
    diag 'Baseline: using an array ref directly';
    for ( 1 ..$sets ) {
        $start = time;
        my $n = 10 ** $_ - 1;
        diag "Testing $n entities";

        $R->clear;

        my $entities = [ map { $_ => [] } 0 .. ( $n - 1 ) ];

        my $elems;
        for ( 0 .. $iterations ) {
            $elems = 0;
            $elems++ for List::Util::pairs @$entities;
        }

        is $elems, $n;

        diag sprintf '    Testing %s iterations took %.3fs',
            $iterations, time - $start;
    }
};

subtest 'Short loops' => sub {
    my $R = Game::Entities->new;
    my $iterations = 10_000;

    diag '';
    diag 'Test: using a view of components';
    for ( 1 .. $sets ) {
        my $n = 10 ** $_ - 1;
        diag "Testing $n entities";

        $R->clear;

        for ( 0 .. ( $n - 1 ) ) {
            my $mod = $_ % 3;
            $R->create(
                              A->new,
                $mod      ? ( B->new ) : (),
                $mod == 2 ? ( C->new ) : (),
            );
        }

        for (
            [     $n,     qw( A     ) ],
            [ 2 * $n / 3, qw( A B   ) ],
            [     $n / 3, qw(   B C ) ],
            [     $n / 3, qw( A   C ) ],
            [     $n / 3, qw( A B C ) ],
        ) {
            my $start = time;
            my ( $want, @components ) = @$_;

            my $elems;
            for ( 0 .. $iterations ) {
                $elems = 0;
                $elems++ for @{ $R->view(@components) };
            }

            is $elems, $want;

            diag sprintf '    Testing %s iterations with %s took %.3fs',
                $iterations, join( '-', @components ), time - $start;
        }
    }
};

done_testing;
