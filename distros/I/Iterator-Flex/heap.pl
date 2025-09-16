#! perl

use latest;
use Data::Dump;
use experimental 'signatures', 'declared_refs';

my $n = shift @ARGV;

permutations( [ 0..$n-1 ] );

sub permutations ( $A ) {

    my \@A = $A;
    my @c = ( (0) x @A );
    my $n = @A;

    my $l = 0;
    dd \@A, $l++ ;
                # say "\n";

    my $i = 1;
    while ( $i < $n ) {
        # dd { i => $i, c => \@c };
        if ( $c[$i] < $i ) {

                if ( 0 == ($i % 2 ) ) {
                    my $t = $A[$i];
                    $A[$i] = $A[0];
                    $A[0] = $t;
                }
                else {
                    my $t = $A[$i];
                    $A[$i] = $A[ $c[$i] ];
                    $A[ $c[$i] ] = $t;
                }

                # say "\n";
                dd \@A, $i, $l++;
                # say "\n";

            # Swap has occurred ending the while-loop. Simulate the
            # increment of the while-loop counter
            $c[$i] += 1;
            # Simulate recursive call reaching the base case by
            # bringing the pointer to the base case analog in the
            # array
            $i = 1;
        }
        else {
            # Calling permutations(i+1, A) has ended as the
            # while-loop terminated. Reset the state and simulate
            # popping the stack by incrementing the pointer.
            $c[$i] = 0;
            $i++;
        }
    }

}


sub k_permutations ( $k, $A ) {

    my \@A = $A;
    my @c = ( (0) x @A );
    my $n = @A;

    dd \@A;

    my $i = 1;
    while ( $i < $n ) {
        if ( $c[$i] < $i ) {

                if ( 0 == ($i % 2 ) ) {
                    my $t = $A[$i];
                    $A[$i] = $A[0];
                    $A[0] = $t;
                }
                else {
                    my $t = $A[$i];
                    $A[$i] = $A[ $c[$i] ];
                    $A[ $c[$i] ] = $t;
                }

                dd \@A;

            # Swap has occurred ending the while-loop. Simulate the
            # increment of the while-loop counter
            $c[$i] += 1;
            # Simulate recursive call reaching the base case by
            # bringing the pointer to the base case analog in the
            # array
            $i = 1;
        }
        else {
            # Calling permutations(i+1, A) has ended as the
            # while-loop terminated. Reset the state and simulate
            # popping the stack by incrementing the pointer.
            $c[$i] = 0;
            $i++;
        }
    }

}


