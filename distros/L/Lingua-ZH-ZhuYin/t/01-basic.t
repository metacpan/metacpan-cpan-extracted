#!perl -T

use Test::More tests => 2;
use Lingua::ZH::ZhuYin;

BEGIN {
    my $zh = Lingua::ZH::ZhuYin->new(dictfile => 'examples/moedict_short.db');
    is(
	$zh->zhuyin('木訥')->[0],
	'ㄇㄨˋ  ㄋㄜˋ'
    );
    is(
	$zh->zhuyin('樸訥誠篤')->[0],
	'ㄆㄨˊ  ㄋㄚˋ  ㄔㄥˊ  ㄉㄨˇ'
    );
}

diag( "Testing Lingua::ZH::ZhuYin Basic funcion zhuyin()" );
