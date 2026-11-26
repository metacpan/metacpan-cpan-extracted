#!perl

# Field values arrive from the network, so the interesting property is not
# that any particular string parses, but that no string can do anything worse
# than return a structure or throw. This walks random and deliberately
# awkward inputs through all three functions and insists on surviving.
#
# The seed is fixed so a failure is reproducible, and the counts are kept
# small enough to be polite in a test suite.

use strict;
use warnings;

use Test2::V0;

use HTTP::libsfparse qw( parse_item parse_list parse_dictionary );

my @alpha = (
    split( //, q{abcAB019 ,;=()":\\*%@?.-_/!#$&'+^`|~} ),
    "\t", "\0", "\xff", "\xc3", "\xa9", "\x7f",
);

sub random_field {
    my ($max) = @_;
    return join '', map { $alpha[ rand @alpha ] } 1 .. int( rand $max );
}

# --- random input ---------------------------------------------------------

{
    srand 20260101;

    my ( $parsed, $rejected, $surprises ) = ( 0, 0, 0 );

    for ( 1 .. 3000 ) {
        my $field = random_field(30);

        for my $parse ( \&parse_item, \&parse_list, \&parse_dictionary ) {
            my $result = eval { $parse->($field) };

            if ($@) {
                $rejected++;
                $surprises++ unless $@ =~ /^HTTP::libsfparse: parse error/;
            }
            else {
                $parsed++;
                $surprises++ unless ref $result eq 'ARRAY';
            }
        }
    }

    ok $parsed > 0,   "random input: $parsed field values parsed";
    ok $rejected > 0, "random input: $rejected field values rejected";
    is $surprises, 0, 'every outcome was either a structure or a parse error';
}

# --- shapes that stress the recursion and the buffers ---------------------

{
    my @pathological = (
        '(' x 60,
        ')' x 60,
        '(' . ( '1 ' x 500 ) . ')',
        join( ';', 'a', map { "p$_=1" } 1 .. 500 ),
        join( ',', map { "k$_=(1 2);p=1" } 1 .. 500 ),
        '"' . ( '\\\\' x 200 ) . '"',
        ':' . ( 'A' x 400 ) . ':',
        '%"' . ( '%c3%a9' x 200 ) . '"',
        'a' x 20000,
        '@' . ( '9' x 25 ),
        'a=(1 2);p=1,' x 500,
    );

    for my $field (@pathological) {
        for my $parse ( \&parse_item, \&parse_list, \&parse_dictionary ) {
            eval { $parse->($field) };
        }
    }

    ok 1, 'pathological shapes survived';
}

done_testing;
