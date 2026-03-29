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

my $base_css = '
    .a { color: #aabbcc; z-index: 2; background: blue; }
    .b { font-size: 16px; }
    .a { padding: 8px; }
';

# ── pretty + shorthand_hex ────────────────────────────────────

{
    my $css = compile_css($base_css, pretty => 1, shorthand_hex => 1);
    like($css, qr/#abc/, 'pretty+shorthand_hex: hex shortened');
    like($css, qr/\n/, 'pretty+shorthand_hex: has newlines');
    like($css, qr/  color: #abc;/, 'pretty+shorthand_hex: indented + shortened');
}

# ── pretty + sort_props ───────────────────────────────────────

{
    my $css = compile_css('.a { z-index: 1; color: red; background: blue; }',
        pretty => 1, sort_props => 1);
    like($css, qr/\n/, 'pretty+sort: has newlines');
    # Props should be alphabetical
    my $expected = ".a {\n  background: blue;\n  color: red;\n  z-index: 1;\n}\n";
    is($css, $expected, 'pretty+sort: alphabetical order with pretty format');
}

# ── pretty + dedupe (conservative) ────────────────────────────

{
    my $css = compile_css('
        .a { color: red; }
        .b { font-size: 16px; }
        .a { background: blue; }
    ', pretty => 1, dedupe => 1);
    like($css, qr/\.a \{\n/, 'pretty+dedupe: merged rule pretty-printed');
    like($css, qr/color: red/, 'pretty+dedupe: first prop');
    like($css, qr/background: blue/, 'pretty+dedupe: merged prop');
}

# ── shorthand_hex + sort_props ────────────────────────────────

{
    my $css = compile_css('.a { z-index: 1; color: #aabbcc; background: #ffffff; }',
        shorthand_hex => 1, sort_props => 1);
    is($css, '.a{background:#fff;color:#abc;z-index:1;}', 'shorthand+sort: both applied');
}

# ── shorthand_hex + dedupe ────────────────────────────────────

{
    my $css = compile_css('
        .a { color: #aabbcc; }
        .a { background: #ffffff; }
    ', shorthand_hex => 1, dedupe => 1);
    is($css, '.a{color:#abc;background:#fff;}', 'shorthand+dedupe: both applied');
}

# ── sort_props + dedupe ───────────────────────────────────────

{
    my $css = compile_css('
        .a { z-index: 1; color: red; }
        .a { background: blue; }
    ', sort_props => 1, dedupe => 1);
    is($css, '.a{background:blue;color:red;z-index:1;}', 'sort+dedupe: sorted after merge');
}

# ── All options combined: pretty + shorthand_hex + sort_props + dedupe ─

{
    my $css = compile_css('
        .a { z-index: 1; color: #aabbcc; }
        .b { font-size: 16px; }
        .a { background: #ffffff; }
    ', pretty => 1, shorthand_hex => 1, sort_props => 1, dedupe => 1);
    like($css, qr/\n/, 'all opts: pretty newlines');
    like($css, qr/#abc/, 'all opts: hex shortened');
    like($css, qr/#fff/, 'all opts: hex shortened bg');
    # .a should be merged and sorted
    like($css, qr/\.a \{/, 'all opts: .a present');
    like($css, qr/\.b \{/, 'all opts: .b present');
    # Inside .a, props should be alphabetical
    my ($a_block) = $css =~ /(\.a \{[^}]+\})/s;
    like($a_block, qr/background.*color.*z-index/s, 'all opts: .a props sorted');
}

# ── Custom indent string (4 spaces) ──────────────────────────

{
    my $css = compile_css('.a { color: red; }', pretty => 1, indent => '    ');
    my $expected = ".a {\n    color: red;\n}\n";
    is($css, $expected, 'indent 4 spaces: correct');
}

# ── Custom indent string (tab) ───────────────────────────────

{
    my $css = compile_css('.a { color: red; }', pretty => 1, indent => "\t");
    my $expected = ".a {\n\tcolor: red;\n}\n";
    is($css, $expected, 'indent tab: correct');
}

# ── Custom indent with sort_props ─────────────────────────────

{
    my $css = compile_css('.a { z-index: 1; color: red; }', 
        pretty => 1, indent => "\t", sort_props => 1);
    my $expected = ".a {\n\tcolor: red;\n\tz-index: 1;\n}\n";
    is($css, $expected, 'tab indent + sort: combined');
}

# ── dedupe strategy 0 (off) with other options ───────────────

{
    my $css = compile_css('
        .a { color: red; }
        .b { color: red; }
    ', dedupe => 0, sort_props => 1);
    like($css, qr/\.a\{color:red;\}\.b\{color:red;\}/, 'dedupe off: different selectors not merged');
}

# ── dedupe aggressive (2) with sort_props ─────────────────────

{
    my $d = Litavis->new(dedupe => 2, sort_props => 1);
    $d->parse('
        .a { z-index: 1; color: red; }
        .b { color: blue; }
        .c { z-index: 1; color: red; }
    ');
    my $css = $d->compile();
    # Aggressive should merge .a and .c despite .b in between
    like($css, qr/\.a, \.c/, 'aggressive+sort: merged selectors');
}

# ── Toggling pretty after construction ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    
    # Default (minified)
    my $min = $d->compile();
    unlike($min, qr/\n/, 'default: minified');
    
    # Toggle to pretty
    $d->pretty(1);
    my $pretty = $d->compile();
    like($pretty, qr/\n/, 'toggled pretty: has newlines');
    
    # Toggle back
    $d->pretty(0);
    my $min2 = $d->compile();
    is($min2, $min, 'toggled back: same as original minified');
}

# ── Toggling dedupe after construction ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; } .a { background: blue; }');
    
    # With dedupe off — same-selector merging still happens
    $d->dedupe(0);
    my $no_dedup = $d->compile();
    is($no_dedup, '.a{color:red;background:blue;}', 'dedupe off: same-sel still merged');
    
    # With dedupe on
    $d->dedupe(1);
    my $deduped = $d->compile();
    is($deduped, '.a{color:red;background:blue;}', 'dedupe on: merged');
}

# ── pretty + @media nesting ──────────────────────────────────

{
    my $css = compile_css('
        @media (max-width: 768px) {
            .a { color: red; }
        }
    ', pretty => 1);
    like($css, qr/\@media \(max-width: 768px\) \{\n/, 'pretty media: opens');
    like($css, qr/  \.a \{\n/, 'pretty media: nested rule indented');
    like($css, qr/    color: red;/, 'pretty media: prop double-indented');
}

# ── sort_props with vendor prefixes ───────────────────────────

{
    my $css = compile_css('
        .a { 
            -webkit-transform: rotate(45deg);
            transform: rotate(45deg);
            -moz-transform: rotate(45deg);
            color: red;
        }
    ', sort_props => 1);
    # Vendor-prefixed and unprefixed should sort alphabetically
    like($css, qr/-moz-transform.*-webkit-transform.*color.*transform/,
        'sort: vendor prefixes sorted alphabetically');
}

# ── shorthand_hex does not alter non-shorthandable ────────────

{
    my $css = compile_css('.a { color: #abcdef; }', shorthand_hex => 1);
    is($css, '.a{color:#abcdef;}', 'shorthand_hex: non-shorthandable unchanged');
}

# ── shorthand_hex with 3-char hex already ─────────────────────

{
    my $css = compile_css('.a { color: #abc; }', shorthand_hex => 1);
    is($css, '.a{color:#abc;}', 'shorthand_hex: 3-char hex stays 3-char');
}

# ── Variables + all output options ────────────────────────────

{
    my $css = compile_css('
        $color: #aabbcc;
        .a { z-index: 1; color: $color; }
    ', pretty => 1, shorthand_hex => 1, sort_props => 1);
    like($css, qr/#abc/, 'vars+all-opts: var resolved then hex shortened');
    like($css, qr/\n/, 'vars+all-opts: pretty');
    my ($block) = $css =~ /(\.a \{[^}]+\})/s;
    like($block, qr/color.*z-index/s, 'vars+all-opts: sorted');
}

# ── Mixins + dedupe + pretty ─────────────────────────────────

{
    my $css = compile_css('
        %box: (
            padding: 8px;
            margin: 4px;
        );
        .a { color: red; %box; }
        .a { font-size: 16px; }
    ', pretty => 1, dedupe => 1);
    like($css, qr/padding: 8px/, 'mixin+dedupe+pretty: mixin expanded');
    like($css, qr/font-size: 16px/, 'mixin+dedupe+pretty: deduped prop');
    like($css, qr/\n/, 'mixin+dedupe+pretty: pretty format');
}

# ── Colour functions + shorthand_hex ──────────────────────────

{
    my $css = compile_css('.a { color: lighten(#000000, 50%); }', shorthand_hex => 1);
    # lighten #000 by 50% should give a grey, check it's resolved and possibly shortened
    unlike($css, qr/lighten/, 'colour+shorthand: function resolved');
    like($css, qr/#/, 'colour+shorthand: hex in output');
}

done_testing;
