use strict;
use warnings;
use Test::More;
use Markdown::Simple;

# Phase 09: UTF-8 validator must accept well-formed UTF-8 and reject
# every category of malformed sequence, with bit-identical results
# between the active SIMD backend and the scalar reference.

# ---- well-formed UTF-8 ------------------------------------------------
my @valid = (
    ''                                  ,  # empty
    'a'                                 ,  # 1-byte
    "Hello, world!\n"                   ,  # ASCII
    "Caf\xC3\xA9"                       ,  # 2-byte (é)
    "\xE2\x98\x83 snowman"              ,  # 3-byte (☃)
    "\xF0\x9F\x98\x80 grin"             ,  # 4-byte (😀)
    "\xC2\x80"                          ,  # U+0080 (smallest 2-byte)
    "\xDF\xBF"                          ,  # U+07FF (largest 2-byte)
    "\xE0\xA0\x80"                      ,  # U+0800 (smallest 3-byte)
    "\xEF\xBF\xBD"                      ,  # U+FFFD replacement char
    "\xF0\x90\x80\x80"                  ,  # U+10000 (smallest 4-byte)
    "\xF4\x8F\xBF\xBF"                  ,  # U+10FFFF (largest valid)
    ("\xF0\x9F\x98\x80" x 100)          ,  # repeated 4-byte
    ("a" x 1024) . "\xC3\xA9" . ("b" x 1024), # straddles SIMD chunk boundary
);

for my $i (0 .. $#valid) {
    my $bytes = $valid[$i];
    is Markdown::Simple::_validate_utf8($bytes), 1,
        "active backend: valid sample $i (len " . length($bytes) . ")";
    is Markdown::Simple::_validate_utf8_scalar($bytes), 1,
        "scalar backend: valid sample $i (len " . length($bytes) . ")";
}

# ---- malformed (Markus Kuhn stress-test categories) -------------------
my @invalid = (
    "\x80"                              ,  # lone continuation
    "\xBF"                              ,  # lone continuation
    "\xC0\x80"                          ,  # overlong NUL
    "\xC1\xBF"                          ,  # overlong
    "\xE0\x9F\xBF"                      ,  # overlong 3-byte
    "\xF0\x8F\xBF\xBF"                  ,  # overlong 4-byte
    "\xED\xA0\x80"                      ,  # U+D800 surrogate
    "\xED\xBF\xBF"                      ,  # U+DFFF surrogate
    "\xF4\x90\x80\x80"                  ,  # > U+10FFFF
    "\xF5\x80\x80\x80"                  ,  # > U+10FFFF leading byte
    "\xFE"                              ,  # invalid leading byte
    "\xFF"                              ,  # invalid leading byte
    "\xC3"                              ,  # truncated 2-byte
    "\xE2\x98"                          ,  # truncated 3-byte
    "\xF0\x9F\x98"                      ,  # truncated 4-byte
    "valid then bad: \xC3"              ,  # mid-stream truncation
);

for my $i (0 .. $#invalid) {
    my $bytes = $invalid[$i];
    is Markdown::Simple::_validate_utf8($bytes), 0,
        "active backend: invalid sample $i";
    is Markdown::Simple::_validate_utf8_scalar($bytes), 0,
        "scalar backend: invalid sample $i";
}

# ---- fuzz: random ASCII is always valid -------------------------------
srand(0xCAFE);
for my $k (1 .. 50) {
    my $n = 1 + int(rand 8192);
    my $s = join '', map { chr int rand 128 } 1 .. $n;
    my $a = Markdown::Simple::_validate_utf8($s);
    my $b = Markdown::Simple::_validate_utf8_scalar($s);
    is $a, 1, "fuzz ASCII iter $k: active says valid";
    is $b, 1, "fuzz ASCII iter $k: scalar says valid";
}

# ---- fuzz: random bytes — active must agree with scalar ---------------
my $mismatches = 0;
for my $k (1 .. 200) {
    my $n = 1 + int(rand 4096);
    my $s = join '', map { chr int rand 256 } 1 .. $n;
    my $a = Markdown::Simple::_validate_utf8($s);
    my $b = Markdown::Simple::_validate_utf8_scalar($s);
    if ($a != $b) {
        diag "mismatch iter=$k len=$n active=$a scalar=$b";
        diag "first 64 bytes hex: ", unpack('H*', substr($s,0,64));
        $mismatches++;
        last if $mismatches > 3;
    }
}
is $mismatches, 0, "fuzz random bytes: active matches scalar";

# ---- strict_utf8 option ------------------------------------------------
{
    my $h = Markdown::Simple::markdown_to_html("Caf\xC3\xA9\n",
                                                { strict_utf8 => 1 });
    like $h, qr/Caf/, 'strict_utf8 accepts valid UTF-8 input';
}
{
    my $h = eval {
        Markdown::Simple::markdown_to_html("bad: \xFF\xFF\n",
                                            { strict_utf8 => 1 });
    };
    ok $@, 'strict_utf8 rejects malformed input';
    like $@, qr/UTF-8/, 'rejection mentions UTF-8';
}

done_testing;
