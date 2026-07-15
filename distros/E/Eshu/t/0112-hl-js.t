use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'js') }

# ── keywords ──────────────────────────────────────────────────────

{
    my $got = hl("const x = 1;");
    like($got, qr{<span class="esh-k">const</span>}, 'JS keyword: const');
}

{
    my $got = hl("let y = 2;");
    like($got, qr{<span class="esh-k">let</span>}, 'JS keyword: let');
}

{
    my $got = hl("var z = 3;");
    like($got, qr{<span class="esh-k">var</span>}, 'JS keyword: var');
}

{
    my $got = hl("function foo() { return null; }");
    like($got, qr{<span class="esh-k">function</span>}, 'JS keyword: function');
    like($got, qr{<span class="esh-k">return</span>},   'JS keyword: return');
    like($got, qr{<span class="esh-k">null</span>},     'JS keyword: null');
}

{
    my $got = hl("if (x) { } else { }");
    like($got, qr{<span class="esh-k">if</span>},   'JS keyword: if');
    like($got, qr{<span class="esh-k">else</span>}, 'JS keyword: else');
}

{
    my $got = hl("for (let i = 0; i < n; i++) { }");
    like($got, qr{<span class="esh-k">for</span>}, 'JS keyword: for');
    like($got, qr{<span class="esh-k">let</span>}, 'JS keyword: let in for');
}

{
    my $got = hl("class Foo extends Bar { }");
    like($got, qr{<span class="esh-k">class</span>},   'JS keyword: class');
    like($got, qr{<span class="esh-k">extends</span>}, 'JS keyword: extends');
}

{
    my $got = hl("import { x } from './foo';");
    like($got,   qr{<span class="esh-k">import</span>}, 'JS keyword: import');
    unlike($got, qr{<span class="esh-k">from</span>},   'from is not a keyword');
}

{
    my $got = hl("export default function() { }");
    like($got, qr{<span class="esh-k">export</span>},   'JS keyword: export');
    like($got, qr{<span class="esh-k">default</span>},  'JS keyword: default');
    like($got, qr{<span class="esh-k">function</span>}, 'JS keyword: function after default');
}

{
    my $got = hl("async function foo() { await bar(); }");
    like($got, qr{<span class="esh-k">async</span>}, 'JS keyword: async');
    like($got, qr{<span class="esh-k">await</span>}, 'JS keyword: await');
}

{
    my $got = hl("try { } catch (e) { } finally { }");
    like($got, qr{<span class="esh-k">try</span>},     'JS keyword: try');
    like($got, qr{<span class="esh-k">catch</span>},   'JS keyword: catch');
    like($got, qr{<span class="esh-k">finally</span>}, 'JS keyword: finally');
}

{
    my $got = hl("x instanceof Array");
    like($got, qr{<span class="esh-k">instanceof</span>}, 'JS keyword: instanceof');
}

{
    my $got = hl("typeof x");
    like($got, qr{<span class="esh-k">typeof</span>}, 'JS keyword: typeof');
}

# ── comments ──────────────────────────────────────────────────────

{
    my $got = hl("x = 1; // line comment\n");
    like($got, qr{<span class="esh-c">// line comment</span>}, 'JS line comment');
}

{
    my $got = hl("/* block comment */");
    like($got, qr{<span class="esh-c">/\* block comment \*/</span>}, 'JS block comment');
}

{
    my $got = hl("/* multi\nline\ncomment */");
    like($got, qr{<span class="esh-c">}, 'multi-line block comment');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $got = hl('"hello world"');
    like($got, qr{<span class="esh-s">&quot;hello world&quot;</span>}, 'double-quoted string');
}

{
    my $got = hl("'single quoted'");
    like($got, qr{<span class="esh-s">'single quoted'</span>}, 'single-quoted string');
}

{
    my $got = hl('`template ${x} literal`');
    like($got, qr{<span class="esh-s">`template \$\{x\} literal`</span>},
        'template literal');
}

{
    my $got = hl('"<div>"');
    like($got, qr{<span class="esh-s">&quot;&lt;div&gt;&quot;</span>},
        'angle brackets in string are HTML-escaped');
}

{
    my $got = hl('"a&b"');
    like($got, qr{<span class="esh-s">&quot;a&amp;b&quot;</span>},
        'ampersand in string is HTML-escaped');
}

# ── numbers ───────────────────────────────────────────────────────

{
    my $got = hl("42");
    like($got, qr{<span class="esh-n">42</span>}, 'integer');
}

{
    my $got = hl("3.14");
    like($got, qr{<span class="esh-n">3\.14</span>}, 'float');
}

{
    my $got = hl("0xFF");
    like($got, qr{<span class="esh-n">0xFF</span>}, 'hex');
}

{
    my $got = hl("0b1010");
    like($got, qr{<span class="esh-n">0b1010</span>}, 'binary');
}

{
    my $got = hl("0o755");
    like($got, qr{<span class="esh-n">0o755</span>}, 'octal');
}

{
    my $got = hl("1_000_000n");
    like($got, qr{<span class="esh-n">1_000_000n</span>}, 'bigint literal');
}

{
    my $got = hl("2.5e-3");
    like($got, qr{<span class="esh-n">2\.5e-3</span>}, 'scientific notation');
}

# ── regex ─────────────────────────────────────────────────────────

{
    my $got = hl("const r = /foo/gi;");
    like($got, qr{<span class="esh-r">/foo/gi</span>}, 'regex literal with flags');
}

{
    my $got = hl("if (/bar/.test(x)) { }");
    like($got, qr{<span class="esh-r">/bar/</span>}, 'regex in if condition');
}

{
    my $got = hl("/[a-z]+/i");
    like($got, qr{<span class="esh-r">/\[a-z\]\+/i</span>}, 'regex with char class');
}

# division should NOT be a regex
{
    my $got = hl("const x = 10 / 2;");
    unlike($got, qr{<span class="esh-r">}, 'division is not a regex');
}

# Note: x++ / 2 cannot be distinguished from a regex with a single-char
# context heuristic (++ sets last_val=0 on the final '+'), so we skip this case.

# ── HTML safety ──────────────────────────────────────────────────

{
    my $got = hl("x < y && y > z;");
    like($got, qr{&lt;}, 'less-than is HTML-escaped');
    like($got, qr{&gt;}, 'greater-than is HTML-escaped');
    like($got, qr{&amp;&amp;}, 'double ampersand is HTML-escaped');
}

# ── combined example ─────────────────────────────────────────────

{
    my $src = <<'END';
// Greeting module
const greet = async (name) => {
    if (!name) throw new Error("no name");
    return `Hello, ${name}!`;
};

export default greet;
END
    my $got = hl($src);
    like($got, qr{<span class="esh-c">// Greeting module</span>}, 'comment in full example');
    like($got, qr{<span class="esh-k">const</span>},               'const in full example');
    like($got, qr{<span class="esh-k">async</span>},               'async in full example');
    like($got, qr{<span class="esh-k">if</span>},                   'if in full example');
    like($got, qr{<span class="esh-k">throw</span>},               'throw in full example');
    like($got, qr{<span class="esh-k">new</span>},                 'new in full example');
    like($got, qr{<span class="esh-k">return</span>},             'return in full example');
    like($got, qr{<span class="esh-s">},                           'template literal in full example');
    like($got, qr{<span class="esh-k">export</span>},             'export in full example');
    like($got, qr{<span class="esh-k">default</span>},            'default in full example');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $got = hl("while (x) { break; continue; }");
    like($got, qr{<span class="esh-k">while</span>},    'JS keyword: while');
    like($got, qr{<span class="esh-k">break</span>},    'JS keyword: break');
    like($got, qr{<span class="esh-k">continue</span>}, 'JS keyword: continue');
}

{
    my $got = hl("do { x++; } while (x < 10);");
    like($got, qr{<span class="esh-k">do</span>}, 'JS keyword: do');
}

{
    my $got = hl("switch (x) { case 1: break; }");
    like($got, qr{<span class="esh-k">switch</span>}, 'JS keyword: switch');
    like($got, qr{<span class="esh-k">case</span>},   'JS keyword: case');
}

{
    my $got = hl("delete obj.key; void 0;");
    like($got, qr{<span class="esh-k">delete</span>}, 'JS keyword: delete');
    like($got, qr{<span class="esh-k">void</span>},   'JS keyword: void');
}

{
    my $got = hl("this.x = super.x;");
    like($got, qr{<span class="esh-k">this</span>},  'JS keyword: this');
    like($got, qr{<span class="esh-k">super</span>}, 'JS keyword: super');
}

{
    my $got = hl("for (const x of arr) { }");
    like($got, qr{<span class="esh-k">of</span>},    'JS keyword: of');
}

{
    my $got = hl("for (const x in obj) { }");
    like($got, qr{<span class="esh-k">in</span>},    'JS keyword: in');
}

{
    my $got = hl("const x = new Map();");
    like($got, qr{<span class="esh-k">new</span>}, 'JS keyword: new');
}

{
    my $got = hl("function* gen() { yield 1; }");
    like($got, qr{<span class="esh-k">function</span>}, 'JS keyword: function (generator)');
    like($got, qr{<span class="esh-k">yield</span>},    'JS keyword: yield');
}

{
    my $got = hl("if (x) throw new Error('oops');");
    like($got, qr{<span class="esh-k">throw</span>}, 'JS keyword: throw');
}

{
    my $got = hl("with (obj) { }");
    like($got, qr{<span class="esh-k">with</span>}, 'JS keyword: with');
}

{
    my $got = hl("debugger;");
    like($got, qr{<span class="esh-k">debugger</span>}, 'JS keyword: debugger');
}

{
    my $got = hl("const x = undefined;");
    like($got, qr{<span class="esh-k">undefined</span>}, 'JS keyword: undefined');
}

{
    my $got = hl("x = Infinity + NaN;");
    like($got, qr{<span class="esh-k">Infinity</span>}, 'JS keyword: Infinity');
    like($got, qr{<span class="esh-k">NaN</span>},      'JS keyword: NaN');
}

# ── static getter/setter (contextual keywords) ─────────────────────

{
    my $got = hl("class A { static get foo() {} set bar(v) {} }");
    like($got, qr{<span class="esh-k">static</span>}, 'JS keyword: static');
    like($got, qr{<span class="esh-k">get</span>},    'JS keyword: get');
    like($got, qr{<span class="esh-k">set</span>},    'JS keyword: set');
}

# ── more numbers ──────────────────────────────────────────────────

{
    my $got = hl("const n = -42;");
    like($got, qr{<span class="esh-n">42</span>}, 'negative integer (the digits)');
}

{
    my $got = hl("1.5e+3");
    like($got, qr{<span class="esh-n">1\.5e\+3</span>}, 'scientific with + exponent');
}

# ── HTML safety ───────────────────────────────────────────────────

{
    my $got = hl('"a & b"');
    like($got, qr{&amp;}, 'ampersand in string is HTML-escaped');
}

# ── partial keyword non-match ──────────────────────────────────────

{
    my $got = hl("constant lettuce newInstance");
    unlike($got, qr{<span class="esh-k">const</span>}, 'const not matched inside constant');
    unlike($got, qr{<span class="esh-k">let</span>},   'let not matched inside lettuce');
    unlike($got, qr{<span class="esh-k">new</span>},   'new not matched inside newInstance');
}

# ── highlight_string lang aliases ──────────────────────────────────

{
    my $got = Eshu->highlight_string("const x = 1;", lang => 'javascript');
    like($got, qr{<span class="esh-k">const</span>}, 'lang=javascript dispatches correctly');
}

{
    my $got = Eshu->highlight_string("const x = 1;", lang => 'jsx');
    like($got, qr{<span class="esh-k">const</span>}, 'lang=jsx dispatches correctly');
}

done_testing;
