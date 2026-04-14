use strict;
use warnings;
use Test::More;

use Enum::Declare::Common::Encoding;

subtest 'unicode encodings' => sub {
	is(UTF8,    'utf-8',    'UTF8');
	is(UTF16LE, 'utf-16le', 'UTF16LE');
	is(UTF16BE, 'utf-16be', 'UTF16BE');
	is(UTF32LE, 'utf-32le', 'UTF32LE');
	is(UTF32BE, 'utf-32be', 'UTF32BE');
};

subtest 'legacy encodings' => sub {
	is(ASCII,  'ascii',      'ASCII');
	is(Latin1, 'iso-8859-1', 'Latin1');
	is(Windows1252, 'windows-1252', 'Windows1252');
	is(KOI8R,  'koi8-r',    'KOI8R');
};

subtest 'cjk encodings' => sub {
	is(ShiftJIS,  'shift_jis',   'ShiftJIS');
	is(EUCJP,     'euc-jp',      'EUCJP');
	is(ISO2022JP, 'iso-2022-jp', 'ISO2022JP');
	is(GB2312,    'gb2312',      'GB2312');
	is(GBK,       'gbk',         'GBK');
	is(GB18030,   'gb18030',     'GB18030');
	is(Big5,      'big5',        'Big5');
	is(EUCKR,     'euc-kr',      'EUCKR');
};

subtest 'meta accessor' => sub {
	my $meta = Type();
	ok($meta->count >= 30, 'at least 30 encodings');
	ok($meta->valid('utf-8'),    'utf-8 is valid');
	ok($meta->valid('ascii'),    'ascii is valid');
	ok(!$meta->valid('utf-99'),  'utf-99 is not valid');
	is($meta->name('utf-8'), 'UTF8', 'name of utf-8 is UTF8');
};

done_testing;
