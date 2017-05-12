use Test::More tests => 3;
use utf8;

BEGIN {
    use_ok 'Encode::Arabic::Franco';
}

is 'عربي', (decode 'franco-arabic', '3rby'), 'Canonical name Franco-Arabic recognized';
is 'عربي', (decode 'arabizy', '3rby'), 'Canonical name Arabizy recognized';
