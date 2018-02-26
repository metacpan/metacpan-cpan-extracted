use strict;
use warnings;
use Encode::Simple qw(encode decode encode_lax decode_lax);
use Test::More;

# valid encode/decode
my $characters = "\N{U+2603}\N{U+2764}\N{U+1F366}";
my $bytes = "\xe2\x98\x83\xe2\x9d\xa4\xf0\x9f\x8d\xa6";

is encode('UTF-8', my $copy = $characters), $bytes, 'encoded to UTF-8';
is $characters, $copy, 'original string unmodified';
is decode('UTF-8', $copy = $bytes), $characters, 'decoded from UTF-8';
is $bytes, $copy, 'original bytes unmodified';

# valid lax encode/decode
is encode_lax('UTF-8', $copy = $characters), $bytes, 'encoded to UTF-8';
is $characters, $copy, 'original string unmodified';
is decode_lax('UTF-8', $copy = $bytes), $characters, 'decoded from UTF-8';
is $bytes, $copy, 'original bytes unmodified';

# invalid encode/decode
my $invalid_characters = "\N{U+D800}\N{U+DFFF}\N{U+110000}\N{U+2603}";
ok !eval { encode('UTF-8', $copy = $invalid_characters); 1 }, 'invalid encode errored';
is $invalid_characters, $copy, 'original string unmodified';

my $invalid_bytes = "\x60\xe2\x98\x83\xf0";
ok !eval { decode('UTF-8', $copy = $invalid_bytes); 1 }, 'invalid decode errored';
is $invalid_bytes, $copy, 'original string unmodified';

# invalid lax encode/decode
my $replacement_bytes = "\xef\xbf\xbd\xef\xbf\xbd\xef\xbf\xbd\xe2\x98\x83";
is encode_lax('UTF-8', $copy = $invalid_characters), $replacement_bytes, 'invalid lax encode';
is $invalid_characters, $copy, 'original string unmodified';

my $replacement_characters = "\N{U+0060}\N{U+2603}\N{U+FFFD}";
is decode_lax('UTF-8', $copy = $invalid_bytes), $replacement_characters, 'invalid lax decode';
is $invalid_bytes, $copy, 'original string unmodified';

# invalid ascii characters
my $invalid_ascii = "a\N{U+2603}b\N{U+1F366}";
ok !eval { encode('ASCII', $copy = $invalid_ascii); 1 }, 'invalid ascii errored';
is $invalid_ascii, $copy, 'original string unmodified';

my $replacement_ascii = 'a?b?';
is encode_lax('ASCII', $copy = $invalid_ascii, 1), $replacement_ascii, 'invalid lax ascii';
is $invalid_ascii, $copy, 'original string unmodified';

# Encode::Unicode
my $surrogate_characters = "\N{U+D800}\N{U+DFFF}\N{U+2603}";
my $surrogate_bytes = "\x00\x00\x00\x00\x26\x03";

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
  is encode_lax('UTF-16BE', $copy = $surrogate_characters), $surrogate_bytes, 'surrogate characters lax encode to UTF-16';
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
