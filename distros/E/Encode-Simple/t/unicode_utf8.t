use strict;
use warnings;
use Test::Requires 'Unicode::UTF8';
use Encode::Simple qw(encode_utf8 decode_utf8 encode_utf8_lax decode_utf8_lax);
use Test::More;

# valid encode/decode
my $characters = "\N{U+2603}\N{U+2764}\N{U+1F366}";
my $bytes = "\xe2\x98\x83\xe2\x9d\xa4\xf0\x9f\x8d\xa6";

is encode_utf8(my $copy = $characters), $bytes, 'encode_utf8';
is $characters, $copy, 'original string unmodified';
is decode_utf8($copy = $bytes), $characters, 'decode_utf8';
is $bytes, $copy, 'original bytes unmodified';

# valid lax encode/decode
is encode_utf8_lax($copy = $characters), $bytes, 'encode_utf8_lax';
is $characters, $copy, 'original string unmodified';
is decode_utf8_lax($copy = $bytes), $characters, 'decode_utf8_lax';
is $bytes, $copy, 'original bytes unmodified';

# invalid encode/decode
my $invalid_characters = do { no warnings 'utf8'; "\N{U+D800}\N{U+DFFF}\N{U+110000}\N{U+2603}\N{U+FDD0}\N{U+1FFFF}" };
my $invalid_bytes = "\x60\xe2\x98\x83\xf0";

ok !eval { encode_utf8($copy = $invalid_characters); 1 }, 'invalid encode_utf8 errored';
is $invalid_characters, $copy, 'original string unmodified';

ok !eval { decode_utf8($copy = $invalid_bytes); 1 }, 'invalid decode_utf8 errored';
is $invalid_bytes, $copy, 'original string unmodified';

# invalid lax encode/decode
my $replacement_bytes = "\xef\xbf\xbd\xef\xbf\xbd\xef\xbf\xbd\xe2\x98\x83\xef\xbf\xbd\xef\xbf\xbd";
my $replacement_characters = "\N{U+0060}\N{U+2603}\N{U+FFFD}";

is encode_utf8_lax($copy = $invalid_characters), $replacement_bytes, 'invalid encode_utf8_lax';
is $invalid_characters, $copy, 'original string unmodified';

is decode_utf8_lax($copy = $invalid_bytes), $replacement_characters, 'invalid decode_utf8_lax';
is $invalid_bytes, $copy, 'original string unmodified';

done_testing;
