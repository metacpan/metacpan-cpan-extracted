use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;

use utf8;
use Lingua::JA::Alphabet::Yomi qw( alphabet2yomi );

is alphabet2yomi('USA'), 'ユーエスエー';

is alphabet2yomi('APC', 'fr'), 'アーペーセー';

is alphabet2yomi('セリエＡ', 'it'), 'セリエアー';

is alphabet2yomi('AMG', 'de'), 'アーエムゲー';

throws_ok { alphabet2yomi('Test', 'xx') } qr/^lang:xx is not supported/;

{
    local $Lingua::JA::Alphabet::Yomi::alphabet2yomi->{it}{J} = 'ヨータ';
    is alphabet2yomi('ていうか、だろ JK', 'it'), 'ていうか、だろ ヨータカッパ';
}
