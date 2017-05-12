use strict;

use Test::More;
use Lingua::TL::Numbers qw(num2tl num2tl_ordinal);


subtest 'ordinal numbers in "ika-" formation' => sub {
    is(num2tl_ordinal(1, ika => 1), 'una');
    is(num2tl_ordinal(2, ika => 1), 'ikalawa');
    is(num2tl_ordinal(3, ika => 1), 'ikatlo');
    is(num2tl_ordinal(4, ika => 1), 'ika-apat');
    is(num2tl_ordinal(5, ika => 1), 'ikalima');
    is(num2tl_ordinal(6, ika => 1), 'ika-anim');
    is(num2tl_ordinal(7, ika => 1), 'ikapito');
    is(num2tl_ordinal(8, ika => 1), 'ikawalo');
    is(num2tl_ordinal(9, ika => 1), 'ikasiyam');
    is(num2tl_ordinal(10, ika => 1), 'ikasampu');
    is(num2tl_ordinal(11, ika => 1), 'ikalabing-isa');
    is(num2tl_ordinal(12, ika => 1), 'ikalabindalawa');
    is(num2tl_ordinal(20, ika => 1), 'ikadalawampu');
    is(num2tl_ordinal(100, ika => 1), 'ika-isang daan');
    is(num2tl_ordinal(100, ika => 1, hypen => 1), 'ika-isang-daan');
    done_testing();
};

subtest 'ordinal numbers in "pang-" formation' => sub {
    is(num2tl_ordinal(1), 'panguna');
    is(num2tl_ordinal(2), 'pangalawa');
    is(num2tl_ordinal(3), 'pangatlo');
    is(num2tl_ordinal(4), 'pang-apat');
    is(num2tl_ordinal(5), 'panlima');
    is(num2tl_ordinal(6), 'pang-anim');
    is(num2tl_ordinal(7), 'pampito');
    is(num2tl_ordinal(8), 'pangwalo');
    is(num2tl_ordinal(9), 'pansiyam');
    is(num2tl_ordinal(10), 'pansampu');
    is(num2tl_ordinal(11), 'panlabing-isa');
    is(num2tl_ordinal(12), 'panlabindalawa');
    is(num2tl_ordinal(20), 'pandalawampu');
    is(num2tl_ordinal(100), 'pang-isang daan');
    is(num2tl_ordinal(100, hypen => 1), 'pang-isang-daan');
    done_testing();
};

done_testing();
