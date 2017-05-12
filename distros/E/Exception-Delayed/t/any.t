#!perl -w

use Test::More tests => 2;

use Exception::Delayed;

sub xxx {
    return Exception::Delayed->wantany(
        wantarray,
        sub {
            if (wantarray) {
                return map { $_ * 2 } @_;
            }
            else {
                my $sum = 0;
                map { $sum += $_ } @_;
                return $sum;
            }
        },
        @_
    )->result;
}

subtest(
    scalar => sub {
        plan( tests => 1 );

        my $x = xxx( 10, 20, 30 );

        is( $x, 10 + 20 + 30, "scalar context detected" );
    }
);

subtest(
    list => sub {
        plan( tests => 1 );

        my @x = xxx( 10, 20, 30 );

        is_deeply( \@x, [ 20, 40, 60 ], "list context detected" );
    }
);

done_testing;
