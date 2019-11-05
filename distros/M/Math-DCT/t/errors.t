use Test2::Tools::Exception qw/dies/;
use Test2::V0;

use Math::DCT ':all';

is(dct2d([]), [], 'dct2d does not die on empty');

like(
    dies { dct2d() },
    qr/undef/,
    "Undef array - exception"
);

like(
    dies { dct() },
    qr/Expect/,
    "Undef array - exception"
);

like(
    dies { dct(1) },
    qr/Expect/,
    "No array - exception"
);

like(
    dies { dct([]) },
    qr/Expect/,
    "Empty array - exception"
);


like(
    dies { dct([1, 2, 3]) },
    qr/Expect/,
    "No array of arrays - exception"
);

like(
    dies { dct([[1, 2, 3], [2, 3, 4]]) },
    qr/Expect 1d or NxN/,
    "Not NxN array - exception"
);

done_testing();