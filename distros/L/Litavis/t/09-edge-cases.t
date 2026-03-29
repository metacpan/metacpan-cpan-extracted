use strict;
use warnings;
use Test::More;

use_ok('Litavis');

# Helper
sub compile_css {
    my ($css, %opts) = @_;
    my $d = Litavis->new(%opts);
    $d->parse($css);
    return $d->compile();
}

# ── Deep nesting (5 levels) ───────────────────────────────────

{
    my $css = compile_css('
        .a {
            .b {
                .c {
                    .d {
                        .e {
                            color: red;
                        }
                    }
                }
            }
        }
    ');
    like($css, qr/\.a \.b \.c \.d \.e\{color:red;\}/, 'deep nesting: 5 levels flattened');
}

# ── Deep nesting with & at each level ─────────────────────────

{
    my $css = compile_css('
        .btn {
            &:hover {
                &:focus {
                    &:active {
                        color: red;
                    }
                }
            }
        }
    ');
    like($css, qr/\.btn:hover:focus:active\{color:red;\}/, 'deep &: chained pseudo-classes');
}

# ── Empty input ────────────────────────────────────────────────

{
    my $css = compile_css('');
    is($css, '', 'empty input: empty output');
}

{
    my $css = compile_css('   ');
    is($css, '', 'whitespace only: empty output');
}

{
    my $css = compile_css('/* just a comment */');
    is($css, '', 'comment only: empty output');
}

# ── Only variable definitions, no rules ────────────────────────

{
    my $css = compile_css('$x: red; $y: blue;');
    is($css, '', 'vars only: empty output (no rules)');
}

# ── Single property rule ──────────────────────────────────────

{
    my $css = compile_css('.a { color: red; }');
    is($css, '.a{color:red;}', 'single prop: works');
}

# ── Many properties in one rule ───────────────────────────────

{
    my @props;
    for my $i (1..20) {
        push @props, "prop-$i: value-$i";
    }
    my $input = '.a { ' . join('; ', @props) . '; }';
    my $css = compile_css($input);
    like($css, qr/^\.a\{/, 'many props: rule opens');
    for my $i (1, 10, 20) {
        like($css, qr/prop-$i:value-$i/, "many props: prop-$i present");
    }
}

# ── Special characters in selectors ───────────────────────────

{
    my $css = compile_css('.foo\:bar { color: red; }');
    like($css, qr/foo/, 'escaped colon in selector: parsed');
}

{
    my $css = compile_css('[data-value="test"] { color: red; }');
    like($css, qr/\[data-value="test"\]\{color:red;\}/, 'attribute selector: preserved');
}

{
    my $css = compile_css('[data-value~="test"] { color: red; }');
    like($css, qr/\[data-value~="test"\]/, 'attribute selector ~=: preserved');
}

# ── Values with special characters ────────────────────────────

{
    my $css = compile_css('.a { content: "hello world"; }');
    like($css, qr/content:"hello world"/, 'quoted string value: preserved');
}

{
    my $css = compile_css('.a { content: "{braces}"; }');
    like($css, qr/content:"\{braces\}"/, 'braces in string: preserved');
}

{
    my $css = compile_css(q|.a { content: 'single quotes'; }|);
    like($css, qr/content:/, 'single quoted value: parsed');
}

# ── url() values ──────────────────────────────────────────────

{
    my $css = compile_css('.a { background: url("image.png"); }');
    like($css, qr/url\("image\.png"\)/, 'url(): preserved');
}

{
    my $css = compile_css('.a { background: url(image.png); }');
    like($css, qr/url\(image\.png\)/, 'url() without quotes: preserved');
}

# ── Multiple values (shorthand properties) ────────────────────

{
    my $css = compile_css('.a { border: 1px solid rgba(0, 0, 0, 0.5); }');
    like($css, qr/border:1px solid rgba\(0, 0, 0, 0\.5\)/, 'shorthand with rgba: preserved');
}

{
    my $css = compile_css('.a { transition: all 0.3s ease-in-out; }');
    like($css, qr/transition:all 0\.3s ease-in-out/, 'transition shorthand: preserved');
}

# ── Large number of selectors ─────────────────────────────────

{
    my @rules;
    for my $i (1..100) {
        push @rules, ".rule-$i { prop-$i: val-$i; }";
    }
    my $d = Litavis->new(dedupe => 0);
    $d->parse(join("\n", @rules));
    my $css = $d->compile();

    # Check first, middle, and last
    like($css, qr/\.rule-1\{prop-1:val-1;\}/, '100 rules: first present');
    like($css, qr/\.rule-50\{prop-50:val-50;\}/, '100 rules: middle present');
    like($css, qr/\.rule-100\{prop-100:val-100;\}/, '100 rules: last present');

    # Verify order preserved
    my @positions;
    for my $i (1, 50, 100) {
        if ($css =~ /\.rule-$i/) {
            push @positions, $-[0];
        }
    }
    ok($positions[0] < $positions[1] && $positions[1] < $positions[2],
        '100 rules: order preserved');
}

# ── Comma selectors with nesting ──────────────────────────────

{
    my $css = compile_css('
        .a, .b {
            .c, .d {
                color: red;
            }
        }
    ', dedupe => 0);
    like($css, qr/\.a \.c/, 'comma+nest: .a .c');
    like($css, qr/\.a \.d/, 'comma+nest: .a .d');
    like($css, qr/\.b \.c/, 'comma+nest: .b .c');
    like($css, qr/\.b \.d/, 'comma+nest: .b .d');
}

# ── Multiple @media blocks ───────────────────────────────────

{
    my $css = compile_css('
        .a { color: red; }
        @media (max-width: 768px) { .b { color: blue; } }
        @media (max-width: 480px) { .c { color: green; } }
    ', dedupe => 0);
    like($css, qr/\.a/, 'multi media: base rule present');
    like($css, qr/max-width: 768px/, 'multi media: first query');
    like($css, qr/max-width: 480px/, 'multi media: second query');
}

# ── @keyframes preserved ─────────────────────────────────────

{
    my $css = compile_css('
        @keyframes spin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
        }
    ');
    like($css, qr/\@keyframes spin/, 'keyframes: name preserved');
    like($css, qr/rotate\(0deg\)/, 'keyframes: from value');
    like($css, qr/rotate\(360deg\)/, 'keyframes: to value');
}

# ── Negative values ───────────────────────────────────────────

{
    my $css = compile_css('.a { margin: -10px; z-index: -1; }');
    like($css, qr/margin:-10px/, 'negative value: margin');
    like($css, qr/z-index:-1/, 'negative value: z-index');
}

# ── !important ────────────────────────────────────────────────

{
    my $css = compile_css('.a { color: red !important; }');
    like($css, qr/color:red !important/, '!important: preserved');
}

# ── Unicode in values ─────────────────────────────────────────

{
    my $css = compile_css('.a { content: "→"; }');
    like($css, qr/content:"→"/, 'unicode: arrow preserved');
}

# ── Vendor prefixes ───────────────────────────────────────────

{
    my $css = compile_css('.a { -webkit-transform: rotate(45deg); -moz-transform: rotate(45deg); }');
    like($css, qr/-webkit-transform:rotate\(45deg\)/, 'vendor prefix: -webkit-');
    like($css, qr/-moz-transform:rotate\(45deg\)/, 'vendor prefix: -moz-');
}

# ── calc() with complex expressions ───────────────────────────

{
    my $css = compile_css('.a { width: calc(100% - 2 * 20px); }');
    like($css, qr/calc\(100% - 2 \* 20px\)/, 'calc: complex expression preserved');
}

# ── Multiple compile calls with accumulation ──────────────────

{
    my $d = Litavis->new(dedupe => 0);
    for my $i (1..10) {
        $d->parse(".item-$i { order: $i; }");
    }
    my $css = $d->compile();
    for my $i (1, 5, 10) {
        like($css, qr/\.item-$i\{order:$i;\}/, "accumulate 10: item-$i present");
    }
}

done_testing;
