use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);

# The encoder's output buffer could be overrun: the escaped-string writer let
# SvCUR reach SvLEN, and buf_ensure() then underflowed and stopped growing.
# The trigger is an escaped string ending exactly on the buffer boundary, so
# sweep shapes rather than pinning one magic length.

# escapes first, then a plain tail (the tail's memcpy is what lands on the end)
{
    my $bad = 0;
    for my $esc (1 .. 40) {
        for my $tail (0 .. 200) {
            my $s = ("\x01" x $esc) . ("a" x $tail);
            my $j = encode_json([$s]);
            my $want = '["' . ('\\u0001' x $esc) . ('a' x $tail) . '"]';
            $bad++, next if $j ne $want;
        }
    }
    is $bad, 0, 'escaped string + plain tail: 8040 shapes encode correctly';
}

# with more structure after the string: once corrupted the writes keep going,
# turning the silent overflow into a segfault
{
    my $bad = 0;
    for my $esc (1 .. 12) {
        for my $tail (0 .. 120) {
            my $s = ("\x01" x $esc) . ("a" x $tail);
            my $j = encode_json([$s, "P" x 4096]);
            $bad++ unless decode_json($j)->[1] eq ("P" x 4096);
        }
    }
    is $bad, 0, 'trailing payload after an escaped string survives the append';
}

# the other escape widths (2-byte \\n and 6-byte \\u0000) hit different
# boundary arithmetic than \x01
{
    my $bad = 0;
    for my $ch ("\n", "\t", '"', "\\", "\x00", "\x1f") {
        for my $n (1 .. 60) {
            for my $tail (0 .. 40) {
                my $s = ($ch x $n) . ("z" x $tail);
                my $j = encode_json({ k => $s });
                $bad++ unless decode_json($j)->{k} eq $s;
            }
        }
    }
    is $bad, 0, 'every escape width round-trips at all boundary offsets';
}

# the OO encoder shares direct_encode_sv()
{
    my $c = JSON::YY->new(utf8 => 1);
    my $bad = 0;
    for my $esc (1 .. 12) {
        for my $tail (0 .. 120) {
            my $s = ("\x01" x $esc) . ("a" x $tail);
            my $j = $c->encode([$s, "P" x 4096]);
            $bad++ unless decode_json($j)->[1] eq ("P" x 4096);
        }
    }
    is $bad, 0, 'OO encode: same boundary shapes are safe';
}

# a string that is *only* escapes expands 6x and forces repeated mid-loop
# growth, exercising the re-grow path's out_end recomputation
{
    for my $n (1, 7, 8, 9, 63, 64, 65, 1000, 4096) {
        my $s = "\x01" x $n;
        is decode_json(encode_json([$s]))->[0], $s, "all-escape string, len $n";
    }
}

done_testing;
