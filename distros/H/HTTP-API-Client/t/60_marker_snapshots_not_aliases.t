=head1 NAME

60_marker_snapshots_not_aliases.t - HAC-077: xCSV()/xBOOLEAN() both
blessed \@_ directly - a reference to Perl's actual arguments array,
which aliases the caller's variables rather than copying their values.
Perl's calling convention makes @_ elements live aliases to whatever
variables were passed (when passed as bare scalars, not literals), so a
marker built from a reused loop variable silently changed value later
whenever that variable was reassigned - e.g. building one xBOOLEAN/xCSV
marker per loop iteration from a shared "my $x;" declared outside the
loop produced markers that all ended up holding the LAST iteration's
value, not the value at the time each marker was created. Both
constructors now bless a fresh array (bless [ @_ ], ...) which copies
each argument's value at call time instead of aliasing it - explicitly
passing a scalar ref (xBOOLEAN(\$x)) still tracks live, since that's a
copy of the reference itself, not of what it points to, which is the
documented, intentional way to opt into live-tracking.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::DataTypeMarker;

{
    my $enabled;
    my @markers;
    for my $i ( 1, 0 ) {
        $enabled = $i;
        push @markers, xBOOLEAN($enabled);
    }

    is $markers[0][0], 1, "first xBOOLEAN(\$var) marker keeps the value \$var had when it was created";
    is $markers[1][0], 0, "second marker independently keeps its own value";
}

{
    my ( $x, $y ) = ( 1, 2 );
    my $csv = xCSV( $x, $y, 3 );
    $x = 99;
    $y = 88;

    is_deeply [@$csv], [ 1, 2, 3 ],
        "xCSV(\$x, \$y, ...) snapshots each value at call time - later reassigning \$x/\$y doesn't change it";
}

{
    # Explicitly passing a scalar ref is the documented way to opt into
    # live tracking - that must still work.
    my $flag = 1;
    my $marker = xBOOLEAN( \$flag );
    $flag = 0;

    is ${ $marker->[0] }, 0,
        "an explicitly-passed scalar ref still tracks live, unlike a plain scalar argument";
}

done_testing;
