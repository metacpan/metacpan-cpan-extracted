#!/usr/bin/env perl

use Test::More;
use Game::Entities;
use Time::HiRes 'time';

use  experimental 'signatures';

*A::new = *B::new = *C::new = sub ($class, %args) { bless \%args, $class };

subtest 'Stress tests' => sub {
    my $outer;
    my$R = Game::Entities->new;
    for ( 1 .. 5 ) {
        $outer = time;
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

        my $start;
        for (
            [     $n,     qw( A     ) ],
            [ 2 * $n / 3, qw( A B   ) ],
            [     $n / 3, qw(   B C ) ],
            [     $n / 3, qw( A   C ) ],
            [     $n / 3, qw( A B C ) ],
        ) {
            $start = time;
            my ( $want, @components ) = @$_;

            my $n;
            $R->view(@components)->each( sub { $n++ } );
            is $n, $want;

            diag sprintf '    Testing %s took %.3fs', join( '-', @components ), time - $start;
        }

        diag 'Took ' . ( time - $outer );
    }
};

done_testing;
