use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'c') }

# ── keywords ──────────────────────────────────────────────────────

{
    my $got = hl("int x;");
    like($got, qr{<span class="esh-k">int</span>}, 'C keyword: int');
    like($got, qr{x;}, 'plain identifier and punctuation preserved');
}

{
    my $got = hl("if (x) { return 0; }");
    like($got, qr{<span class="esh-k">if</span>},     'C keyword: if');
    like($got, qr{<span class="esh-k">return</span>}, 'C keyword: return');
}

{
    my $got = hl("void foo(void) { }");
    like($got, qr{<span class="esh-k">void</span>},   'C keyword: void (twice)');
}

{
    my $got = hl("static const char *s;");
    like($got, qr{<span class="esh-k">static</span>}, 'C keyword: static');
    like($got, qr{<span class="esh-k">const</span>},  'C keyword: const');
    like($got, qr{<span class="esh-k">char</span>},   'C keyword: char');
}

{
    my $got = hl("typedef struct { int x; } foo_t;");
    like($got, qr{<span class="esh-k">typedef</span>}, 'C keyword: typedef');
    like($got, qr{<span class="esh-k">struct</span>},  'C keyword: struct');
}

{
    my $got = hl("switch (x) { case 1: break; default: break; }");
    like($got, qr{<span class="esh-k">switch</span>},  'C keyword: switch');
    like($got, qr{<span class="esh-k">case</span>},    'C keyword: case');
    like($got, qr{<span class="esh-k">break</span>},   'C keyword: break');
    like($got, qr{<span class="esh-k">default</span>}, 'C keyword: default');
}

# non-keywords should NOT get a keyword span
{
    my $got = hl("foo(bar);");
    unlike($got, qr{esh-k}, 'identifiers are not keywords');
}

# ── comments ──────────────────────────────────────────────────────

{
    my $got = hl("x = 1; // line comment\n");
    like($got, qr{<span class="esh-c">// line comment</span>}, 'C line comment');
    unlike($got, qr{esh-k}, 'no keyword spans in comment context');
}

{
    my $got = hl("/* block comment */");
    like($got, qr{<span class="esh-c">/\* block comment \*/</span>}, 'C block comment');
}

{
    my $got = hl("/* multi\n   line\n   comment */");
    like($got, qr{<span class="esh-c">}, 'multi-line block comment opens span');
    like($got, qr{</span>},              'multi-line block comment closes span');
}

{
    my $got = hl("x /= 2;");
    unlike($got, qr{esh-c}, 'division-assign is not a comment');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $got = hl('"hello world"');
    like($got, qr{<span class="esh-s">&quot;hello world&quot;</span>}, 'double-quoted string');
}

{
    my $got = hl("'A'");
    like($got, qr{<span class="esh-s">'A'</span>}, 'char literal');
}

{
    my $got = hl('"escape \\"quote\\""');
    like($got, qr{<span class="esh-s">}, 'string with escaped quotes opens span');
}

{
    my $got = hl('"<html>"');
    like($got, qr{<span class="esh-s">&quot;&lt;html&gt;&quot;</span>},
        'angle brackets inside string are HTML-escaped');
}

{
    my $got = hl('"a&b"');
    like($got, qr{<span class="esh-s">&quot;a&amp;b&quot;</span>},
        'ampersand inside string is HTML-escaped');
}

# ── numbers ───────────────────────────────────────────────────────

{
    my $got = hl("int x = 42;");
    like($got, qr{<span class="esh-n">42</span>}, 'decimal integer');
}

{
    my $got = hl("0xFF");
    like($got, qr{<span class="esh-n">0xFF</span>}, 'hex number');
}

{
    my $got = hl("3.14f");
    like($got, qr{<span class="esh-n">3\.14f</span>}, 'float with suffix');
}

{
    my $got = hl("1e10");
    like($got, qr{<span class="esh-n">1e10</span>}, 'scientific notation');
}

{
    my $got = hl("0b1010");
    like($got, qr{<span class="esh-n">0b1010</span>}, 'binary literal');
}

{
    my $got = hl("1UL");
    like($got, qr{<span class="esh-n">1UL</span>}, 'number with suffix UL');
}

# ── preprocessor ──────────────────────────────────────────────────

{
    my $got = hl("#include <stdio.h>\n");
    like($got, qr{<span class="esh-p">#include}, 'preprocessor #include');
}

{
    my $got = hl("#define FOO 1\n");
    like($got, qr{<span class="esh-p">#define}, 'preprocessor #define');
}

{
    my $got = hl("#ifdef DEBUG\n");
    like($got, qr{<span class="esh-p">#ifdef}, 'preprocessor #ifdef');
}

{
    my $got = hl("  x = 1;\n#define X 1\n");
    like($got, qr{<span class="esh-p">#define}, '#define after non-pp line');
}

# NOT a preprocessor when '#' is mid-line (e.g. inside a // comment is fine
# because comment wins first; a bare '#' mid-line is unusual but shouldn't crash)
{
    my $got = hl("int x; // # not a pp\n");
    like($got, qr{<span class="esh-c">// # not a pp</span>}, '# inside comment is comment');
}

# ── HTML safety ───────────────────────────────────────────────────

{
    my $got = hl("x < y && y > z;");
    like($got, qr{&lt;}, 'less-than is escaped in plain code');
    like($got, qr{&gt;}, 'greater-than is escaped in plain code');
    like($got, qr{&amp;&amp;}, 'ampersand is escaped in plain code');
}

# ── overall structure ─────────────────────────────────────────────

{
    my $src = <<'END';
#include <string.h>
/* copy n bytes */
static void mycopy(char *dst, const char *src, int n) {
    int i;
    for (i = 0; i < n; i++) {
        dst[i] = src[i];
    }
}
END
    my $got = hl($src);
    like($got, qr{<span class="esh-p">#include},      'include in full example');
    like($got, qr{<span class="esh-c">/\* copy},      'block comment in full example');
    like($got, qr{<span class="esh-k">static</span>}, 'static in full example');
    like($got, qr{<span class="esh-k">void</span>},   'void in full example');
    like($got, qr{<span class="esh-k">int</span>},    'int in full example');
    like($got, qr{<span class="esh-k">for</span>},    'for in full example');
    like($got, qr{&lt;string\.h&gt;},                'header in angle brackets escaped');
    unlike($got, qr{<span class="esh-k">n</span>},   'single-char var is not a keyword');
}


# ── more keywords ─────────────────────────────────────────────────

{
    my $got = hl("for (;;) { continue; }");
    like($got, qr{<span class="esh-k">for</span>},      'C keyword: for');
    like($got, qr{<span class="esh-k">continue</span>}, 'C keyword: continue');
}

{
    my $got = hl("while (x) { } do { } while (x);");
    like($got, qr{<span class="esh-k">while</span>}, 'C keyword: while');
    like($got, qr{<span class="esh-k">do</span>},    'C keyword: do');
}

{
    my $got = hl("else { goto end; }");
    like($got, qr{<span class="esh-k">else</span>}, 'C keyword: else');
    like($got, qr{<span class="esh-k">goto</span>}, 'C keyword: goto');
}

{
    my $got = hl("enum Color { RED, GREEN, BLUE };");
    like($got, qr{<span class="esh-k">enum</span>}, 'C keyword: enum');
}

{
    my $got = hl("union Data { int i; float f; };");
    like($got, qr{<span class="esh-k">union</span>},  'C keyword: union');
    like($got, qr{<span class="esh-k">float</span>}, 'C keyword: float');
}

{
    my $got = hl("extern long double x;");
    like($got, qr{<span class="esh-k">extern</span>}, 'C keyword: extern');
    like($got, qr{<span class="esh-k">long</span>},   'C keyword: long');
    like($got, qr{<span class="esh-k">double</span>}, 'C keyword: double');
}

{
    my $got = hl("unsigned short int n; signed char c;");
    like($got, qr{<span class="esh-k">unsigned</span>}, 'C keyword: unsigned');
    like($got, qr{<span class="esh-k">short</span>},    'C keyword: short');
    like($got, qr{<span class="esh-k">signed</span>},   'C keyword: signed');
}

{
    my $got = hl("volatile register auto x;");
    like($got, qr{<span class="esh-k">volatile</span>}, 'C keyword: volatile');
    like($got, qr{<span class="esh-k">register</span>}, 'C keyword: register');
    like($got, qr{<span class="esh-k">auto</span>},     'C keyword: auto');
}

{
    my $got = hl("n = sizeof(int);");
    like($got, qr{<span class="esh-k">sizeof</span>}, 'C keyword: sizeof');
}

{
    my $got = hl("inline restrict void f(int * restrict p);");
    like($got, qr{<span class="esh-k">inline</span>},   'C keyword: inline');
    like($got, qr{<span class="esh-k">restrict</span>}, 'C keyword: restrict');
}

{
    my $got = hl("_Bool b; _Atomic int a;");
    like($got, qr{<span class="esh-k">_Bool</span>},   'C keyword: _Bool');
    like($got, qr{<span class="esh-k">_Atomic</span>}, 'C keyword: _Atomic');
}

{
    my $got = hl("NULL != ptr && true || false");
    like($got, qr{<span class="esh-k">NULL</span>},  'C macro: NULL');
    like($got, qr{<span class="esh-k">true</span>},  'C macro: true');
    like($got, qr{<span class="esh-k">false</span>}, 'C macro: false');
}

# partial keyword must not match inside a longer identifier
{
    my $got = hl("int2 integer do_something;");
    unlike($got, qr{<span class="esh-k">int</span>}, 'int not matched inside int2');
    unlike($got, qr{<span class="esh-k">do</span>},  'do not matched inside do_something');
}

# ── more preprocessor ─────────────────────────────────────────────

{
    my $got = hl("#ifndef HEADER_H\n");
    like($got, qr{<span class="esh-p">#ifndef}, '#ifndef preprocessor');
}

{
    my $got = hl("#endif\n");
    like($got, qr{<span class="esh-p">#endif}, '#endif preprocessor');
}

{
    my $got = hl("#pragma once\n");
    like($got, qr{<span class="esh-p">#pragma}, '#pragma preprocessor');
}

{
    my $got = hl("#undef FOO\n");
    like($got, qr{<span class="esh-p">#undef}, '#undef preprocessor');
}

{
    my $got = hl("#elif defined(BAR)\n");
    like($got, qr{<span class="esh-p">#elif}, '#elif preprocessor');
}

{
    my $got = hl("#if 0\n");
    like($got, qr{<span class="esh-p">#if}, '#if preprocessor');
}

# ── more numbers ──────────────────────────────────────────────────

{
    my $got = hl("0755");
    like($got, qr{<span class="esh-n">0755</span>}, 'octal literal');
}

{
    my $got = hl("100LL");
    like($got, qr{<span class="esh-n">100LL</span>}, 'long long suffix');
}

{
    my $got = hl("0ULL");
    like($got, qr{<span class="esh-n">0ULL</span>}, 'unsigned long long suffix');
}

{
    my $got = hl("1e-3");
    like($got, qr{<span class="esh-n">1e-3</span>}, 'negative exponent');
}

# ── more strings ──────────────────────────────────────────────────

{
    my $got = hl('""');
    like($got, qr{<span class="esh-s">&quot;&quot;</span>}, 'empty string');
}

{
    my $got = hl("'\\n'");
    like($got, qr{<span class="esh-s">}, 'char literal with escape sequence');
}

# ── lang=h alias same as lang=c ───────────────────────────────────

{
    my $got_c = hl("int x;");
    my $got_h = Eshu->highlight_string("int x;", lang => 'h');
    is($got_c, $got_h, 'lang=h gives same output as lang=c');
}

# ── keyword not highlighted inside block comment ───────────────────

{
    my $got = hl("/* if (x) return; */");
    unlike($got, qr{<span class="esh-k">if</span>},     'if inside block comment not highlighted');
    unlike($got, qr{<span class="esh-k">return</span>}, 'return inside block comment not highlighted');
}

done_testing;
