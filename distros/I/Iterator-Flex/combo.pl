#! perl
use latest;
use experimentals;
use Data::Dump;
my ( $n, $k ) = @ARGV;
my @A = ( 0..$k-1 );
    dd @A;
while ( next_combination( \@A, $n ) ) {
    dd @A;
}

sub  next_combination ($A, $n) {

    my \@A = $A;
    my $k = @A;

    for ( my $i = $k - 1; $i >= 0 ; $i-- ) {
        if ( $A[$i] < $n - $k + $i ) {
        $A[$i]++;
        for my $j ($i + 1 .. $k -1 ) {
            $A[$j] = $A[$j - 1] + 1;
        }
        return !!1;
    }
    }
    return !!0;
}
