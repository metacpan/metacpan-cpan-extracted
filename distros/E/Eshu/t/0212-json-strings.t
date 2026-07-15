use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_json($_[0], indent_char => ' ', indent_width => 2) }

# ── escaped double quote ─────────────────────────────────────────

{
    my $src = '{"q":"say \"hi\""}';
    my $out = j($src);
    like($out, qr/"q": "say \\"hi\\""/m, 'escaped double quote in string value');
}

# ── escaped backslash ─────────────────────────────────────────────

{
    my $src = '{"path":"C:\\\\Users"}';
    my $out = j($src);
    like($out, qr/"path": "C:\\\\Users"/m, 'escaped backslash in string value');
}

# ── escaped newline and tab ───────────────────────────────────────

{
    my $src = '{"nl":"a\\nb","tab":"x\\ty"}';
    my $out = j($src);
    like($out, qr/"nl": "a\\nb"/m,  'escaped newline in string');
    like($out, qr/"tab": "x\\ty"/m, 'escaped tab in string');
}

# ── unicode escape ────────────────────────────────────────────────

{
    my $src = '{"sym":"\\u00e9"}';
    my $out = j($src);
    like($out, qr/"sym": "\\u00e9"/m, 'unicode escape \\uXXXX in string');
}

# ── braces inside string are not structural ───────────────────────

{
    my $src = '{"t":"{not a brace}"}';
    my $expected = <<'END';
{
  "t": "{not a brace}"
}
END
    is(j($src), $expected, 'curly braces inside string are not structural');
}

# ── brackets inside string are not structural ─────────────────────

{
    my $src = '{"t":"[not an array]"}';
    my $expected = <<'END';
{
  "t": "[not an array]"
}
END
    is(j($src), $expected, 'square brackets inside string are not structural');
}

# ── colon inside string not a key separator ───────────────────────

{
    my $src = '{"t":"key:value"}';
    my $expected = <<'END';
{
  "t": "key:value"
}
END
    is(j($src), $expected, 'colon inside string not treated as separator');
}

# ── comma inside string not an element separator ──────────────────

{
    my $src = '{"t":"a,b,c"}';
    my $expected = <<'END';
{
  "t": "a,b,c"
}
END
    is(j($src), $expected, 'comma inside string not treated as separator');
}

# ── slash escape \/  ─────────────────────────────────────────────

{
    my $src = '{"url":"http:\\/\\/example.com"}';
    my $out = j($src);
    like($out, qr/"url": "http:\\\/\\\/example\.com"/m,
         'escaped forward slash \\/ in string');
}

# ── empty string value ────────────────────────────────────────────

{
    my $src = '{"empty":""}';
    my $expected = <<'END';
{
  "empty": ""
}
END
    is(j($src), $expected, 'empty string value');
}

# ── string with only whitespace ───────────────────────────────────

{
    my $src = '{"ws":"   "}';
    my $out = j($src);
    like($out, qr/"ws": "   "/m, 'string of whitespace preserved verbatim');
}

# ── multi-word string value ───────────────────────────────────────

{
    my $src = '{"msg":"hello world"}';
    my $expected = <<'END';
{
  "msg": "hello world"
}
END
    is(j($src), $expected, 'multi-word string value');
}

done_testing;
