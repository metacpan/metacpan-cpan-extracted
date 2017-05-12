use strict;
use warnings;
use utf8;

use Encode;
use Test::More tests => 2;

BEGIN {
    use_ok('Encode::compat::MIME::Header::ISO_2022_JP');
};

is(
    encode('MIME-Header-ISO_2022_JP', 'こんにちは'),
    '=?ISO-2022-JP?B?GyRCJDMkcyRLJEEkTxsoQg==?=',
);
