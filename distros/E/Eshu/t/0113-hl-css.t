use strict;
use warnings;
use Test::More;
use Eshu;

sub hl { Eshu->highlight_string($_[0], lang => 'css') }

# ── comments ──────────────────────────────────────────────────────

{
    my $got = hl("/* a comment */");
    like($got, qr{<span class="esh-c">/\* a comment \*/</span>}, 'CSS block comment');
}

{
    my $got = hl("/* multi\nline\ncomment */");
    like($got, qr{<span class="esh-c">/\* multi}, 'multi-line CSS comment opens span');
    like($got, qr{comment \*/</span>},            'multi-line CSS comment closes span');
}

# ── strings ───────────────────────────────────────────────────────

{
    my $got = hl('content: "hello";');
    like($got, qr{<span class="esh-s">&quot;hello&quot;</span>}, 'double-quoted CSS string');
}

{
    my $got = hl("content: 'world';");
    like($got, qr{<span class="esh-s">'world'</span>}, 'single-quoted CSS string');
}

{
    my $got = hl('font-family: "Helvetica Neue", sans-serif;');
    like($got, qr{<span class="esh-s">&quot;Helvetica Neue&quot;</span>}, 'font-family string');
}

# ── at-rules ──────────────────────────────────────────────────────

{
    my $got = hl("\@media screen { }");
    like($got, qr{<span class="esh-p">\@media</span>}, '@media at-rule');
}

{
    my $got = hl("\@keyframes slide { }");
    like($got, qr{<span class="esh-p">\@keyframes</span>}, '@keyframes at-rule');
}

{
    my $got = hl("\@import url('foo.css');");
    like($got, qr{<span class="esh-p">\@import</span>}, '@import at-rule');
}

{
    my $got = hl("\@charset \"UTF-8\";");
    like($got, qr{<span class="esh-p">\@charset</span>}, '@charset at-rule');
}

# ── numbers and units ─────────────────────────────────────────────

{
    my $got = hl("p { margin: 10px; }");
    like($got, qr{<span class="esh-n">10px</span>}, 'px measurement');
}

{
    my $got = hl("p { font-size: 1.5em; }");
    like($got, qr{<span class="esh-n">1\.5em</span>}, 'em measurement');
}

{
    my $got = hl("p { width: 100%; }");
    like($got, qr{<span class="esh-n">100%</span>}, 'percentage');
}

{
    my $got = hl("p { opacity: 0.5; }");
    like($got, qr{<span class="esh-n">0\.5</span>}, 'decimal without unit');
}

{
    my $got = hl("p { z-index: -1; }");
    like($got, qr{<span class="esh-n">-1</span>}, 'negative integer');
}

# ── color hex values ──────────────────────────────────────────────

{
    my $got = hl("p { color: #ff0000; }");
    like($got, qr{<span class="esh-n">#ff0000</span>}, 'full hex color');
}

{
    my $got = hl("p { color: #abc; }");
    like($got, qr{<span class="esh-n">#abc</span>}, 'short hex color');
}

# ── properties (inside rule block) ───────────────────────────────

{
    my $got = hl("p { color: red; }");
    like($got, qr{<span class="esh-k">color</span>}, 'CSS property: color');
}

{
    my $got = hl("div { font-size: 14px; }");
    like($got, qr{<span class="esh-k">font-size</span>}, 'CSS property: font-size');
}

{
    my $got = hl("div { background-color: blue; }");
    like($got, qr{<span class="esh-k">background-color</span>},
        'CSS property: background-color');
}

{
    my $got = hl("div { margin: 0; padding: 0; }");
    like($got, qr{<span class="esh-k">margin</span>},  'CSS property: margin');
    like($got, qr{<span class="esh-k">padding</span>}, 'CSS property: padding');
}

# ── HTML safety ──────────────────────────────────────────────────

{
    my $got = hl("/* <b>bold</b> */");
    like($got, qr{<span class="esh-c">.*&lt;b&gt;.*</span>},
        'angle brackets in comment are HTML-escaped');
}

# ── combined example ─────────────────────────────────────────────

{
    my $src = <<'END';
/* Reset */
*, *::before { box-sizing: border-box; }

@media (max-width: 768px) {
    .container {
        width: 100%;
        padding: 16px;
        font-size: 0.9rem;
        color: #333;
    }
}
END
    my $got = hl($src);
    like($got, qr{<span class="esh-c">/\* Reset \*/</span>}, 'comment in full example');
    like($got, qr{<span class="esh-p">\@media</span>},       '@media in full example');
    like($got, qr{<span class="esh-n">768px</span>},         '768px in full example');
    like($got, qr{<span class="esh-k">width</span>},         'width property in full example');
    like($got, qr{<span class="esh-n">100%</span>},          '100% in full example');
    like($got, qr{<span class="esh-k">padding</span>},       'padding in full example');
    like($got, qr{<span class="esh-n">16px</span>},          '16px in full example');
    like($got, qr{<span class="esh-k">color</span>},         'color in full example');
    like($got, qr{<span class="esh-n">#333</span>},          '#333 in full example');
}


# ── more at-rules ─────────────────────────────────────────────────

{
    my $got = hl("\@font-face { font-family: 'X'; }");
    like($got, qr{<span class="esh-p">\@font-face</span>}, '@font-face at-rule');
}

{
    my $got = hl("\@supports (display: grid) { }");
    like($got, qr{<span class="esh-p">\@supports</span>}, '@supports at-rule');
}

{
    my $got = hl("\@layer utilities { }");
    like($got, qr{<span class="esh-p">\@layer</span>}, '@layer at-rule');
}

{
    my $got = hl("\@counter-style thumbs { }");
    like($got, qr{<span class="esh-p">\@counter-style</span>}, '@counter-style at-rule');
}

# ── more properties ───────────────────────────────────────────────

{
    my $got = hl("a { display: flex; }");
    like($got, qr{<span class="esh-k">display</span>}, 'property: display');
}

{
    my $got = hl("a { border: 1px solid; }");
    like($got, qr{<span class="esh-k">border</span>}, 'property: border');
}

{
    my $got = hl("a { top: 0; left: 0; right: 0; bottom: 0; }");
    like($got, qr{<span class="esh-k">top</span>},    'property: top');
    like($got, qr{<span class="esh-k">left</span>},   'property: left');
    like($got, qr{<span class="esh-k">right</span>},  'property: right');
    like($got, qr{<span class="esh-k">bottom</span>}, 'property: bottom');
}

{
    my $got = hl("a { position: absolute; overflow: hidden; }");
    like($got, qr{<span class="esh-k">position</span>},  'property: position');
    like($got, qr{<span class="esh-k">overflow</span>},  'property: overflow');
}

{
    my $got = hl("a { flex-direction: row; flex-wrap: wrap; }");
    like($got, qr{<span class="esh-k">flex-direction</span>}, 'property: flex-direction');
    like($got, qr{<span class="esh-k">flex-wrap</span>},      'property: flex-wrap');
}

{
    my $got = hl("a { line-height: 1.5; letter-spacing: 0.05em; }");
    like($got, qr{<span class="esh-k">line-height</span>},    'property: line-height');
    like($got, qr{<span class="esh-k">letter-spacing</span>}, 'property: letter-spacing');
}

{
    my $got = hl("a { transform: rotate(45deg); }");
    like($got, qr{<span class="esh-k">transform</span>}, 'property: transform');
}

{
    my $got = hl("a { transition: all 0.3s ease; }");
    like($got, qr{<span class="esh-k">transition</span>}, 'property: transition');
}

{
    my $got = hl("a { z-index: 100; }");
    like($got, qr{<span class="esh-k">z-index</span>}, 'property: z-index');
}

# ── more numbers / units ──────────────────────────────────────────

{
    my $got = hl("a { height: 100vh; }");
    like($got, qr{<span class="esh-n">100vh</span>}, 'vh unit');
}

{
    my $got = hl("a { gap: 1.5rem; }");
    like($got, qr{<span class="esh-n">1\.5rem</span>}, 'rem unit');
}

{
    my $got = hl("a { animation-duration: 200ms; }");
    like($got, qr{<span class="esh-n">200ms</span>}, 'ms unit');
}

{
    my $got = hl("a { rotate: 90deg; }");
    like($got, qr{<span class="esh-n">90deg</span>}, 'deg unit');
}

# ── 8-digit hex colour ────────────────────────────────────────────

{
    my $got = hl("a { color: #ff000080; }");
    like($got, qr{<span class="esh-n">#ff000080</span>}, '8-digit hex colour with alpha');
}

# ── lang aliases ──────────────────────────────────────────────────

{
    my $got = Eshu->highlight_string("a { color: red; }", lang => 'scss');
    like($got, qr{<span class="esh-k">color</span>}, 'lang=scss dispatches to CSS highlighter');
}

{
    my $got = Eshu->highlight_string("a { color: red; }", lang => 'less');
    like($got, qr{<span class="esh-k">color</span>}, 'lang=less dispatches to CSS highlighter');
}

done_testing;
