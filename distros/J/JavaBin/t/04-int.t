use strict;
use warnings;

use JavaBin;
use Test::More;

my @ints;

{
    use integer;

    # Min and max of each array type (byte, short, int, long).
    # Sort. Throw in each value plus and minus one.
    # Knock of the two wrapped around values.
    @ints = map { $_ - 1, $_, $_ + 1 }
           sort { $a <=> $b }
            map { -(2 ** $_), 2 ** $_ - 1 }
                ( 7, 15, 31, 63 );

    pop @ints;
    shift @ints;
}

for (@ints) {
    my $i = eval; # Stringify $_ to a PVIV, create a new IV in $i.

    my $javabin =           -129 < $i && $i <           128 ? "\2\3" . pack 'c' , $i
                :        -32_769 < $i && $i <        32_768 ? "\2\4" . pack 's>', $i
                : -2_147_483_649 < $i && $i < 2_147_483_648 ? "\2\6" . pack 'l>', $i
                :                                             "\2\7" . pack 'q>', $i;

    is to_javabin($i), $javabin, "  to_javabin $_";

    is from_javabin($javabin), $i, "from_javabin $_";

    $javabin = "\2" . chr( 32 | length ) . $_;

    is to_javabin($_), $javabin, qq/  to_javabin "$_"/;

    is from_javabin($javabin), $i, qq/from_javabin "$_"/;
}

done_testing;
