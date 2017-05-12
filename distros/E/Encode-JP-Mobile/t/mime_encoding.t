use strict;
use warnings;
use Test::More tests => 10;

use Encode;
use Encode::JP::Mobile;
use utf8;

is(
    Encode::encode('MIME-Header-JP-Mobile-DoCoMo-SJIS', "\x{E63E}です"),
    '=?SHIFT_JIS?B?+J+CxYK3?=',
    'docomo mime encode'
);
is(
    Encode::decode('MIME-Header-JP-Mobile-DoCoMo', '=?SHIFT_JIS?B?+J+CxYK3?='),
    "\x{E63E}です",
    'docomo mime decode'
);

is(
    Encode::encode('MIME-Header-JP-Mobile-KDDI-SJIS', "\x{E63E}です"),
    "\xF6\x60\x82\xC5\x82\xB7",
    'kddi mime encode'
);
is(
    Encode::decode('MIME-Header-JP-Mobile-KDDI', "\xF6\x60\x82\xC5\x82\xB7"),
    "\x{EF60}です",
    'kddi mime decode (raw)'
);
is(
    Encode::decode('MIME-Header-JP-Mobile-KDDI', '=?iso-2022-jp?B?GyRCdUEkRyQ5GyhC?='),
    "\x{EF60}です",
    'kddi mime decode (iso-2022-jp)'
);

is(
    Encode::encode('MIME-Header-JP-Mobile-SoftBank-UTF8', "\x{E63E}です"),
    '=?UTF-8?B?7oGK44Gn44GZ?=',
    'softbank mime encode'
);
is(
    Encode::encode('MIME-Header-JP-Mobile-SoftBank-SJIS', "\x{E63E}です"),
    '=?SHIFT_JIS?B?GyRHag+CxYK3?=',
    'softbank mime encode (shift_jis)'
);
is(
    Encode::decode('MIME-Header-JP-Mobile-SoftBank', '=?UTF-8?B?7oGK44Gn44GZ?='),
    "\x{E04A}です",
    'softbank mime decode (utf-8)'
);

# このtestはx-iso-2022-jp-softbankというencodingを作ろうかとしていた時の名残です。
# この文字列はsoftbankから送ってgmailから転送された時の晴れ(昼)なんだけど
# encodingはx-iso-2022-jp-kddiになってて、これは恐らくgmail依存な動作なので
# MIME-Header-JP-Mobile-SoftBankのdecodeでこれを正しく晴れに戻せるのは
# 若干おかしい気がする。なのでdecodeサポートは無しでいいんじゃないかなぁと。
# というわけでコメントアウトにしとく。
# MIME-Header-JP-Mobile-Softbank-Gmailとかを作ってもいいかもだけど
# ref: http://mobilehacker.g.hatena.ne.jp/nihen/20090104/1231081872
# is(
#     Encode::decode('MIME-Header-JP-Mobile-SoftBank', '=?ISO-2022-JP?B?GyRCdUEbKEIbJEIkRyQ5GyhC?='),
#     "\x{E04A}です",
#     'softbank mime decode (iso-2022-jp)'
# );

is(
    Encode::encode('MIME-Header-JP-Mobile-Airedge-SJIS', "\x{E63E}です"),
    '=?SHIFT_JIS?B?+J+CxYK3?=',
    'willcom mime encode'
);
is(
    Encode::decode('MIME-Header-JP-Mobile-Airedge', '=?SHIFT_JIS?B?+J+CxYK3?='),
    "\x{E63E}です",
    'willcom mime decode'
);
