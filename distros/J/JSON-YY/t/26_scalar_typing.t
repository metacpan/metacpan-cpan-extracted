use strict;
use warnings;
use Test::More;
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

# A scalar can hold a string and a number at once. Deciding on the numeric slot
# alone rewrote "007" to 7 and $! to its errno; a scalar carrying both now stays
# a string unless the number's text is exactly the string.

sub enc { JSON::YY->new(utf8 => 1, allow_nonref => 1)->encode($_[0]) }

# --- the corruption this fixes ---
{
    my $id = "007";
    my $matches = ($id == 7);            # gives the SV an integer slot
    is encode_json([$id]), '["007"]', 'zero-padded id stays a string';

    my $zip = "01234";
    my $n = $zip + 0;
    is encode_json([$zip]), '["01234"]', 'leading-zero zip stays a string';

    my $ver = "1.10";
    my $cmp = ($ver > 1);
    is encode_json([$ver]), '["1.10"]', 'trailing-zero version stays a string';

    my $line = "42\n";
    my $sum  = $line + 0;
    is encode_json([$line]), qq{["42\\n"]}, 'unchomped number stays a string';

    $! = 2;
    like encode_json([ "$!" ]), qr/^\["No such file/, 'dualvar keeps its string side';
}

# --- values that really are numbers must stay numbers ---
{
    my $s = "42";
    my $n = $s + 0;
    is encode_json([$s]), '[42]', 'numeric string whose text is its number';

    my $i = 42;
    my $str = "$i";                       # leaves only the private POK flag
    is encode_json([$i]), '[42]', 'stringified integer stays a number';

    my $f = 3.14;
    my $fs = "$f";
    is encode_json([$f]), '[3.14]', 'stringified float stays a number';

    my $fromstr = "3.14";
    my $fn = $fromstr + 0;
    is encode_json([$fromstr]), '[3.14]', 'float string whose text is its number';

    is encode_json([42]), '[42]', 'plain integer';
    is encode_json([-7]), '[-7]', 'negative integer';
    is encode_json([0]),  '[0]',  'zero';
    is encode_json(["42"]), '["42"]', 'untouched string stays a string';
}

# --- booleans keep the documented 1/0 form ---
{
    is encode_json([!!1, !!0]), '[1,0]', 'boolean literals encode as 1 and 0';
    is encode_json(decode_json('[true,false]')), '[1,0]',
        'documented roundtrip: true/false -> 1/0';
    my $t = !!1; my $f = !!0;
    is encode_json([$t, $f]), '[1,0]', 'copies of booleans encode as 1 and 0';
    is encode_json([1 == 1, 1 == 2]), '[1,0]', 'comparison results';
}

# --- NaN/Inf still refused, even once stringified ---
{
    my $inf = 9**9**9;
    eval { encode_json([$inf]) };
    like $@, qr/NaN|Inf/i, 'Inf croaks';
    my $s = "$inf";                        # now has both slots
    eval { encode_json([$inf]) };
    like $@, qr/NaN|Inf/i, 'stringified Inf still croaks';
    eval { encode_json([9**9**9 - 9**9**9]) };
    like $@, qr/NaN|Inf/i, 'NaN croaks';
    is encode_json(["Inf"]), '["Inf"]', 'the plain string "Inf" is just a string';
}

# --- the same rule applies to the OO, pretty and Doc encoders ---
{
    my $id = "007"; my $m = ($id == 7);
    is enc([$id]), '["007"]', 'OO encode';
    my $pretty = JSON::YY->new(utf8 => 1, pretty => 1)->encode([$id]);
    is_deeply decode_json($pretty), ['007'], 'pretty (yyjson) encode';
    is "" . (jfrom [$id]), '["007"]', 'jfrom';

    my $doc = jfrom {};
    jset $doc, "/id", $id;
    is +(jgetp $doc, "/id"), '007', 'jset keeps the string';

    my $num = "42"; my $n2 = $num + 0;
    is "" . (jfrom [$num]), '[42]', 'jfrom still emits real numbers';
}

# --- hash keys and nesting ---
{
    my $k = "007"; my $m = ($k == 7);
    is_deeply decode_json(encode_json({ list => [$k], n => 5 })),
        { list => ['007'], n => 5 }, 'nested structure';
}

done_testing;
