use strict;
use warnings;
use Test::Without::Module 'Unicode::UTF8';
use Encode::Simple qw(encode decode encode_lax decode_lax
  encode_utf8 decode_utf8 encode_utf8_lax decode_utf8_lax);
use Test::More;

# valid encode/decode
my $characters = "\N{U+2603}\N{U+2764}\N{U+1F366}";
my $bytes = "\xe2\x98\x83\xe2\x9d\xa4\xf0\x9f\x8d\xa6";

is encode('UTF-8', my $copy = $characters), $bytes, 'strict encode to UTF-8';
is $characters, $copy, 'original string unmodified';
is decode('UTF-8', $copy = $bytes), $characters, 'strict decode from UTF-8';
is $bytes, $copy, 'original bytes unmodified';

is encode_utf8($copy = $characters), $bytes, 'encode_utf8';
is $characters, $copy, 'original string unmodified';
is decode_utf8($copy = $bytes), $characters, 'decode_utf8';
is $bytes, $copy, 'original bytes unmodified';

# valid lax encode/decode
is encode_lax('UTF-8', $copy = $characters), $bytes, 'lax encode to UTF-8';
is $characters, $copy, 'original string unmodified';
is decode_lax('UTF-8', $copy = $bytes), $characters, 'lax decode from UTF-8';
is $bytes, $copy, 'original bytes unmodified';

is encode_utf8_lax($copy = $characters), $bytes, 'encode_utf8_lax';
is $characters, $copy, 'original string unmodified';
is decode_utf8_lax($copy = $bytes), $characters, 'decode_utf8_lax';
is $bytes, $copy, 'original bytes unmodified';

# invalid encode/decode
my $invalid_characters = do { no warnings 'utf8'; "\N{U+D800}\N{U+DFFF}\N{U+110000}\N{U+2603}\N{U+FDD0}\N{U+1FFFF}" };

ok !eval { encode('UTF-8', $copy = $invalid_characters); 1 }, 'invalid encode errored';
is $invalid_characters, $copy, 'original string unmodified';

ok !eval { encode_utf8($copy = $invalid_characters); 1 }, 'invalid encode_utf8 errored';
is $invalid_characters, $copy, 'original string unmodified';

my $invalid_bytes = "\x60\xe2\x98\x83\xf0";

ok !eval { decode('UTF-8', $copy = $invalid_bytes); 1 }, 'invalid decode errored';
is $invalid_bytes, $copy, 'original string unmodified';

ok !eval { decode_utf8($copy = $invalid_bytes); 1 }, 'invalid decode_utf8 errored';
is $invalid_bytes, $copy, 'original string unmodified';

# invalid lax encode/decode
my $replacement_bytes = "\xef\xbf\xbd\xef\xbf\xbd\xef\xbf\xbd\xe2\x98\x83\xef\xbf\xbd\xef\xbf\xbd";

is encode_lax('UTF-8', $copy = $invalid_characters), $replacement_bytes, 'invalid lax encode';
is $invalid_characters, $copy, 'original string unmodified';

is encode_utf8_lax($copy = $invalid_characters), $replacement_bytes, 'invalid encode_utf8_lax';
is $invalid_characters, $copy, 'original string unmodified';

my $replacement_characters = "\N{U+0060}\N{U+2603}\N{U+FFFD}";

is decode_lax('UTF-8', $copy = $invalid_bytes), $replacement_characters, 'invalid lax decode';
is $invalid_bytes, $copy, 'original string unmodified';

is decode_utf8_lax($copy = $invalid_bytes), $replacement_characters, 'invalid decode_utf8_lax';
is $invalid_bytes, $copy, 'original string unmodified';

# invalid ascii characters
my $invalid_ascii = "a\N{U+2603}b\N{U+1F366}";
my $replacement_ascii = 'a?b?';

ok !eval { encode('ASCII', $copy = $invalid_ascii); 1 }, 'invalid ascii errored';
is $invalid_ascii, $copy, 'original string unmodified';

is encode_lax('ASCII', $copy = $invalid_ascii, 1), $replacement_ascii, 'invalid lax ascii';
is $invalid_ascii, $copy, 'original string unmodified';

# Encode::Unicode
my $surrogate_characters = do { no warnings 'utf8'; "\N{U+D800}\N{U+DFFF}\N{U+2603}" };
my $surrogate_bytes = qr/\A....\x26\x03\z/;

my $warnings;
{
  local $SIG{__WARN__} = sub { $warnings = shift };
  ok !eval { encode('UTF-16BE', $copy = $surrogate_characters); 1 }, 'surrogate characters encode to UTF-16';
}
is $surrogate_characters, $copy, 'original string unmodified';
is $warnings, undef, 'no warnings';

undef $warnings;
{
  local $SIG{__WARN__} = sub { $warnings = shift };
  like encode_lax('UTF-16BE', $copy = $surrogate_characters), $surrogate_bytes, 'surrogate characters lax encode to UTF-16';
}
is $surrogate_characters, $copy, 'original string unmodified';
is $warnings, undef, 'no warnings';

undef $warnings;
{
  local $SIG{__WARN__} = sub { $warnings = shift };
  ok !eval { encode('UTF-16BE', $copy = $invalid_characters); 1 }, 'invalid encode to UTF-16';
}
is $invalid_characters, $copy, 'original string unmodified';
is $warnings, undef, 'no warnings';

done_testing;
