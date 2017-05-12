use Test::More tests => 16;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal;

do 'funcs.pl';

$matrix = Math::MatrixReal->new_from_string(<<MATRIX);

   [ 1 4 7 ]
   [ 2 5 8 ]
   [ 3 6 9 ]

MATRIX

$vector = Math::MatrixReal->new_from_string(<<MATRIX);

   [ 1 9 4 7 ]

MATRIX

## scalar context
is_deeply( scalar($matrix->maximum()   ), [3, 6, 9], "Max test 1 (scalar context)");
is_deeply( scalar((~$matrix)->maximum()), [7, 8, 9], "Max test 2 (scalar context)");

is_deeply( scalar($vector->maximum()   ), 9, "Max test 3 (scalar context)");
is_deeply( scalar((~$vector)->maximum()), 9, "Max test 4 (scalar context)");

is_deeply( scalar($matrix->minimum()   ), [1, 4, 7], "Min test 1 (scalar context)");
is_deeply( scalar((~$matrix)->minimum()), [1, 2, 3], "Min test 2 (scalar context)");

is_deeply( scalar($vector->minimum()   ), 1, "Min test 3 (scalar context)");
is_deeply( scalar((~$vector)->minimum()), 1, "Min test 4 (scalar context)");

## list context
is_deeply( [ $matrix->maximum()    ], [[3, 6, 9], [3, 3, 3]], "Max test 1 (list context)");
is_deeply( [ (~$matrix)->maximum() ], [[7, 8, 9], [3, 3, 3]], "Max test 2 (list context)");

is_deeply( [ $vector->maximum()    ], [9, 2], "Max test 3 (list context)");
is_deeply( [ (~$vector)->maximum() ], [9, 2], "Max test 4 (list context)");

is_deeply( [ $matrix->minimum()    ], [[1, 4, 7], [1, 1, 1]], "Min test 1 (list context)");
is_deeply( [ (~$matrix)->minimum() ], [[1, 2, 3], [1, 1, 1]], "Min test 2 (list context)");

is_deeply( [ $vector->minimum()    ], [1, 1], "Min test 3 (list context)");
is_deeply( [ (~$vector)->minimum() ], [1, 1], "Min test 4 (list context)");