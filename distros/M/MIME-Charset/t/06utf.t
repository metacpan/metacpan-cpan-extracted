use strict;
use Test::More;

BEGIN {
    if ($] < 5.007003) {
	plan skip_all => 'Unicode/multibyte support is not enabled';
    } else {
	plan tests => 16;
    }
}

use MIME::Charset;

my $utf16 = MIME::Charset->new('utf-16');
my $utf16be = MIME::Charset->new('utf-16be');
my $utf16le = MIME::Charset->new('utf-16le');

ok($utf16->decode("\xD8\x08\xDF\x45") eq "\x{12345}");
ok($utf16be->decode("\xD8\x08\xDF\x45") eq "\x{12345}");
ok($utf16->decode("\xFE\xFF\xD8\x08\xDF\x45") eq "\x{12345}");
ok($utf16le->decode("\x08\xD8\x45\xDF") eq "\x{12345}");
ok($utf16->decode("\xFF\xFE\x08\xD8\x45\xDF") eq "\x{12345}");

ok($utf16->encode("\x{12345}") eq "\xFE\xFF\xD8\x08\xDF\x45");
ok($utf16be->encode("\x{12345}") eq "\xD8\x08\xDF\x45");
ok($utf16le->encode("\x{12345}") eq "\x08\xD8\x45\xDF");

my $utf32 = MIME::Charset->new('utf-32');
my $utf32be = MIME::Charset->new('utf-32be');
my $utf32le = MIME::Charset->new('utf-32le');

ok($utf32->decode("\x00\x01\x23\x45") eq "\x{12345}");
ok($utf32be->decode("\x00\x01\x23\x45") eq "\x{12345}");
ok($utf32->decode("\0\0\xFE\xFF\x00\x01\x23\x45") eq "\x{12345}");
ok($utf32le->decode("\x45\x23\x01\x00") eq "\x{12345}");
ok($utf32->decode("\xFF\xFE\0\0\x45\x23\x01\x00") eq "\x{12345}");

ok($utf32->encode("\x{12345}") eq "\0\0\xFE\xFF\x00\x01\x23\x45");
ok($utf32be->encode("\x{12345}") eq "\x00\x01\x23\x45");
ok($utf32le->encode("\x{12345}") eq "\x45\x23\x01\x00");
