use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# A string without the UTF8 flag holds latin-1 characters. Emitting its high
# bytes verbatim produced invalid UTF-8 that decode_json itself rejects, and in
# character mode a malformed SV. Both must widen, matching JSON::XS.

sub bytes { join ' ', map { sprintf '%02x', ord } split //, $_[0] }

my $latin = "caf\xe9";                   # 4 bytes, no UTF8 flag
my $chars = "caf\x{e9}"; utf8::upgrade($chars);   # same 4 characters, flagged
ok !utf8::is_utf8($latin), 'fixture: downgraded string has no UTF8 flag';
ok  utf8::is_utf8($chars), 'fixture: upgraded string has the UTF8 flag';

# --- encode_json (always UTF-8 bytes) ---
{
    my $j = encode_json({ k => $latin });
    is bytes($j), '7b 22 6b 22 3a 22 63 61 66 c3 a9 22 7d',
        'encode_json widens latin-1 to UTF-8';
    ok !utf8::is_utf8($j), 'encode_json returns bytes';
    my $copy = $j;
    ok utf8::decode($copy), 'encode_json output is valid UTF-8';
    is decode_json($j)->{k}, $chars, 'output round-trips through decode_json';

    is encode_json({ k => $latin }), encode_json({ k => $chars }),
        'downgraded and upgraded forms of the same string encode identically';
}

# --- hash keys ---
{
    my %h = ("k\xe9y" => 1);
    my $j = encode_json(\%h);
    my $copy = $j;
    ok utf8::decode($copy), 'latin-1 hash key encodes as valid UTF-8';
    is_deeply [keys %{ decode_json($j) }], ["k\x{e9}y"], 'key round-trips';
}

# --- OO character mode: flagged result must be well-formed ---
{
    my $out = JSON::YY->new->encode({ k => $latin });
    ok utf8::is_utf8($out), 'character mode sets the UTF8 flag';
    is length($out), 12, 'character mode length counts characters, not bytes';
    is $out, '{"k":"' . $chars . '"}', 'character mode text is correct';
}

# --- OO utf8 mode and the pretty (yyjson) path ---
{
    my $out = JSON::YY->new(utf8 => 1)->encode({ k => $latin });
    is bytes($out), '7b 22 6b 22 3a 22 63 61 66 c3 a9 22 7d', 'utf8 mode: bytes';

    my $pretty = JSON::YY->new(utf8 => 1, pretty => 1)->encode({ k => $latin });
    is decode_json($pretty)->{k}, $chars, 'pretty path widens latin-1 too';

    my $pchars = JSON::YY->new(pretty => 1)->encode({ k => $latin });
    ok utf8::is_utf8($pchars), 'pretty character mode sets the UTF8 flag';
}

# --- Doc API: used to poison the document and croak on write ---
{
    my $doc = jfrom { "k\xe9y" => "v\xe9l" };
    my $enc = eval { jencode $doc, "" };
    is $@, '', 'jfrom with latin-1 key and value serialises';
    is_deeply decode_json($enc), { "k\x{e9}y" => "v\x{e9}l" }, 'jfrom round-trips';

    my $d2 = jfrom {};
    jset $d2, "/z", "na\xefve";
    is +(jgetp $d2, "/z"), "na\x{ef}ve", 'jset widens a latin-1 value';
    is +(jencode $d2, ""), encode_json({ z => "na\x{ef}ve" }), 'jset matches encode_json';
}

# --- mixed structure, and every byte 0x80-0xff ---
{
    my $mixed = { plain => 'ascii', latin => $latin, wide => "\x{263a}" };
    is_deeply decode_json(encode_json($mixed)),
        { plain => 'ascii', latin => $chars, wide => "\x{263a}" },
        'ascii, latin-1 and wide characters in one structure';

    my $all = join '', map { chr } 0x80 .. 0xff;
    my $j   = encode_json([$all]);
    my $copy = $j;
    ok utf8::decode($copy), 'every latin-1 high byte encodes as valid UTF-8';
    is decode_json($j)->[0], (join '', map { chr } 0x80 .. 0xff),
        'every latin-1 high byte round-trips';
}

# --- escapes interleaved with high bytes (the widening slow path) ---
{
    for my $n (1, 2, 7, 8, 9, 40, 300) {
        my $s = join '', map { "\x01\xe9\"a\\\xff\n" } 1 .. $n;
        my $rt = decode_json(encode_json([$s]))->[0];
        my $want = $s; utf8::upgrade($want);
        is $rt, $want, "escapes mixed with latin-1 high bytes, $n reps";
    }
}

# --- ASCII and pre-flagged input must be untouched ---
{
    is encode_json({ a => 'plain ascii' }), '{"a":"plain ascii"}', 'ascii unchanged';
    is encode_json(["\x{1f600}"]), "[\"\xf0\x9f\x98\x80\"]", 'wide char unchanged';
}

# --- the Doc keywords must not rewrite the scalars they are handed ---
# SvPVutf8() upgrades in place, so `jdoc $body` turned $body into a character
# string and a later decode_json($body) silently double-encoded.
{
    my $bytes = qq({"name":"caf\xc3\xa9"});          # UTF-8 bytes, as off a socket
    my $want  = "caf\x{e9}";

    is decode_json($bytes)->{name}, $want, 'decode_json reads UTF-8 bytes correctly';
    ok !utf8::is_utf8($bytes), 'fixture starts as a byte string';

    my $doc = jdoc $bytes;                            # Doc API peek at the same scalar
    ok !utf8::is_utf8($bytes), 'jdoc leaves the caller scalar a byte string';
    is decode_json($bytes)->{name}, $want,
        'decode_json still correct on that scalar after jdoc';

    # every keyword that takes a path or a value goes through the same helper
    my $path = "/caf\xc3\xa9";
    my $d2 = jfrom { "caf\x{e9}" => 1 };
    jhas $d2, $path;
    ok !utf8::is_utf8($path), 'a path argument is not upgraded in place';

    my $val = "caf\xe9";
    jstr $val;
    ok !utf8::is_utf8($val), 'jstr does not upgrade its argument in place';

    my $frag = qq(["caf\xe9"]);
    my $d3 = jfrom {};
    jraw $d3, "/x", $frag;
    ok !utf8::is_utf8($frag), 'jraw does not upgrade its JSON fragment in place';
}

# --- the Doc API reads its JSON as characters (unchanged contract) ---
{
    # a character string is the intended input and round-trips
    is +(jgetp jdoc(qq({"k":"caf\x{e9}"})), "/k"), "caf\x{e9}",
        'jdoc takes character strings';
    # latin-1 bytes are characters too, and mean the same thing
    is +(jgetp jdoc(qq({"k":"caf\xe9"})), "/k"), "caf\x{e9}",
        'jdoc treats a byte string as latin-1 characters';
}

done_testing;
