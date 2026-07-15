use strict;
use warnings;
use Test::More;
use Eshu;

sub hl  { Eshu->highlight_string($_[0], lang => 'json')  }
sub hlc { Eshu->highlight_string($_[0], lang => 'jsonc') }

# ── object key → esh-a ───────────────────────────────────────────

{
    my $out = hl('{"name":"Alice"}');
    like($out, qr{<span class="esh-a">&quot;name&quot;</span>},
         'object key wrapped as esh-a');
}

# ── string value → esh-s ─────────────────────────────────────────

{
    my $out = hl('{"name":"Alice"}');
    like($out, qr{<span class="esh-s">&quot;Alice&quot;</span>},
         'string value wrapped as esh-s');
}

# ── key vs value distinction ─────────────────────────────────────

{
    my $out = hl('{"a":"b"}');
    like($out, qr{esh-a.*esh-s}s, 'key comes before value in output');
    unlike($out, qr{<span class="esh-s">&quot;a&quot;</span>},
           '"a" is a key, not a value');
    unlike($out, qr{<span class="esh-a">&quot;b&quot;</span>},
           '"b" is a value, not a key');
}

# ── number → esh-n ───────────────────────────────────────────────

{
    my $out = hl('{"n":42}');
    like($out, qr{<span class="esh-n">42</span>}, 'integer wrapped as esh-n');
}

{
    my $out = hl('{"x":3.14}');
    like($out, qr{<span class="esh-n">3\.14</span>}, 'float wrapped as esh-n');
}

{
    my $out = hl('{"n":-7}');
    like($out, qr{<span class="esh-n">-7</span>}, 'negative number wrapped as esh-n');
}

{
    my $out = hl('{"n":1e10}');
    like($out, qr{<span class="esh-n">1e10</span>}, 'scientific notation wrapped as esh-n');
}

# ── null / true / false → esh-k ──────────────────────────────────

{
    my $out = hl('{"a":null}');
    like($out, qr{<span class="esh-k">null</span>}, 'null wrapped as esh-k');
}

{
    my $out = hl('{"b":true}');
    like($out, qr{<span class="esh-k">true</span>}, 'true wrapped as esh-k');
}

{
    my $out = hl('{"c":false}');
    like($out, qr{<span class="esh-k">false</span>}, 'false wrapped as esh-k');
}

# ── structural chars are plain ────────────────────────────────────

{
    my $out = hl('{"a":1,"b":2}');
    # { } , : should appear unspanned in the output
    like($out, qr/\{/, 'open brace is plain');
    like($out, qr/\}/, 'close brace is plain');
    like($out, qr/,/,  'comma is plain');
    like($out, qr/:/,  'colon is plain');
}

# ── array values ─────────────────────────────────────────────────

{
    my $out = hl('[1,"hello",true,null]');
    like($out, qr{<span class="esh-n">1</span>},            'array: number');
    like($out, qr{<span class="esh-s">&quot;hello&quot;</span>}, 'array: string value (esh-s)');
    like($out, qr{<span class="esh-k">true</span>},         'array: true');
    like($out, qr{<span class="esh-k">null</span>},         'array: null');
}

# ── HTML escaping ─────────────────────────────────────────────────

{
    my $out = hl('{"lt":"a<b"}');
    like($out, qr/&lt;/, 'less-than HTML-escaped');
}

{
    my $out = hl('{"amp":"a&b"}');
    like($out, qr/&amp;/, 'ampersand HTML-escaped');
}

# ── key with escaped quote ────────────────────────────────────────

{
    my $out = hl('{"a\\"b":1}');
    like($out, qr{esh-a}, 'key with escaped quote still tagged esh-a');
}

# ── JSONC // comment → esh-c ─────────────────────────────────────

{
    my $out = hlc('// this is a comment');
    like($out, qr{<span class="esh-c">// this is a comment</span>},
         'JSONC // comment wrapped as esh-c');
}

{
    my $out = hlc("// line one\n{\"a\":1}");
    like($out, qr{esh-c}, '// comment on first line tagged esh-c');
    like($out, qr{esh-a}, 'key after comment tagged esh-a');
}

# ── JSONC block comment → esh-c ──────────────────────────────────

{
    my $out = hlc('/* block comment */');
    like($out, qr{<span class="esh-c">/\* block comment \*/</span>},
         'JSONC block comment wrapped as esh-c');
}

# ── lang alias "jsonc" same result as "json" for non-comment input ─

{
    my $src = '{"a":1}';
    my $j  = hl($src);
    my $jc = hlc($src);
    is($j, $jc, '"json" and "jsonc" give same output for plain JSON');
}

# ── nested structure highlights correctly ─────────────────────────

{
    my $src = '{"user":{"name":"Bob","age":30}}';
    my $out = hl($src);
    # outer key
    like($out, qr{<span class="esh-a">&quot;user&quot;</span>}, 'outer key esh-a');
    # inner keys
    like($out, qr{<span class="esh-a">&quot;name&quot;</span>}, 'inner key name esh-a');
    like($out, qr{<span class="esh-a">&quot;age&quot;</span>},  'inner key age esh-a');
    # values
    like($out, qr{<span class="esh-s">&quot;Bob&quot;</span>},  'string value Bob esh-s');
    like($out, qr{<span class="esh-n">30</span>},               'number 30 esh-n');
}


# ── more number formats ───────────────────────────────────────────

{
    my $out = hl('{"n":1.5e+3}');
    like($out, qr{<span class="esh-n">1\.5e\+3</span>}, 'exponent with + tagged esh-n');
}

{
    my $out = hl('{"n":2.0E-10}');
    like($out, qr{<span class="esh-n">2\.0E-10</span>}, 'exponent with E- tagged esh-n');
}

{
    my $out = hl('{"n":0}');
    like($out, qr{<span class="esh-n">0</span>}, 'zero tagged esh-n');
}

# ── true/false/null in arrays ─────────────────────────────────────

{
    my $out = hl('[true,false,null]');
    like($out, qr{<span class="esh-k">true</span>},  'true in array esh-k');
    like($out, qr{<span class="esh-k">false</span>}, 'false in array esh-k');
    like($out, qr{<span class="esh-k">null</span>},  'null in array esh-k');
}

# ── multiple keys in same object ──────────────────────────────────

{
    my $out = hl('{"x":1,"y":2,"z":3}');
    like($out, qr{<span class="esh-a">&quot;x&quot;</span>}, 'first key esh-a');
    like($out, qr{<span class="esh-a">&quot;y&quot;</span>}, 'second key esh-a');
    like($out, qr{<span class="esh-a">&quot;z&quot;</span>}, 'third key esh-a');
    like($out, qr{<span class="esh-n">1</span>},            'first value esh-n');
    like($out, qr{<span class="esh-n">2</span>},            'second value esh-n');
    like($out, qr{<span class="esh-n">3</span>},            'third value esh-n');
}

# ── nested arrays ─────────────────────────────────────────────────

{
    my $out = hl('[[1,2],[3,4]]');
    like($out, qr{<span class="esh-n">1</span>}, 'nested array: first element');
    like($out, qr{<span class="esh-n">4</span>}, 'nested array: last element');
}

# ── empty object and array ────────────────────────────────────────

{
    my $out = hl('{}');
    like($out, qr/\{\}/, 'empty object no spans');
    unlike($out, qr/esh-k|esh-a|esh-s|esh-n/, 'no spans in empty object');
}

{
    my $out = hl('[]');
    like($out, qr/\[\]/, 'empty array no spans');
    unlike($out, qr/esh-k|esh-a|esh-s|esh-n/, 'no spans in empty array');
}

# ── string with unicode escape ────────────────────────────────────

{
    my $out = hl('{"k":"\\u0041"}');
    like($out, qr{esh-s}, 'string with \\u escape tagged esh-s');
}

# ── multiline JSON (keys on separate lines) ───────────────────────

{
    my $src = "{\n\"a\": 1,\n\"b\": 2\n}";
    my $out = hl($src);
    like($out, qr{<span class="esh-a">&quot;a&quot;</span>}, 'multiline: key a esh-a');
    like($out, qr{<span class="esh-a">&quot;b&quot;</span>}, 'multiline: key b esh-a');
}

# ── JSONC trailing comma tolerated (no crash) ─────────────────────

{
    my $out = eval { hlc('{"a":1,}') };
    ok(defined $out, 'JSONC with trailing comma does not die');
}

# ── JSONC block comment not treated as key ────────────────────────

{
    my $out = hlc('/* key: value */');
    unlike($out, qr{esh-a}, 'block comment content not tagged esh-a');
    like($out,   qr{esh-c}, 'block comment tagged esh-c');
}

# ── key with spaces ───────────────────────────────────────────────

{
    my $out = hl('{"my key": 1}');
    like($out, qr{<span class="esh-a">&quot;my key&quot;</span>}, 'key with space tagged esh-a');
}

# ── value string with embedded quote already tested; test gt ──────

{
    my $out = hl('{"gt":"a>b"}');
    like($out, qr/&gt;/, 'greater-than in string HTML-escaped');
}

done_testing;
