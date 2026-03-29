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

sub resolve_colour {
    my ($css) = @_;
    my $d = Litavis->new;
    $d->parse($css);
    $d->_resolve_colours;
    return $d;
}

# ── lighten boundary: 0% ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: lighten(#ff0000, 0%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'lighten 0%: produces hex');
    # 0% lighten should return approximately the same colour
}

# ── lighten boundary: 100% ────────────────────────────────────

{
    my $d = resolve_colour('.a { color: lighten(#000000, 100%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'lighten 100%: produces hex');
    # 100% lighten from black should approach white
}

# ── darken boundary: 0% ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: darken(#ff0000, 0%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'darken 0%: produces hex');
}

# ── darken boundary: 100% ────────────────────────────────────

{
    my $d = resolve_colour('.a { color: darken(#ffffff, 100%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'darken 100%: produces hex');
}

# ── mix with weight 0 ────────────────────────────────────────

{
    my $d = resolve_colour('.a { color: mix(#ff0000, #0000ff, 0); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'mix weight 0: produces hex');
}

# ── mix with weight 100 ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: mix(#ff0000, #0000ff, 100); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'mix weight 100: produces hex');
}

# ── mix with weight 50 ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: mix(#ff0000, #0000ff, 50); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'mix weight 50: produces hex');
}

# ── saturate boundary: 0% ────────────────────────────────────

{
    my $d = resolve_colour('.a { color: saturate(#808080, 0%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'saturate(#808080, 0%)', 'saturate 0%: was evaluated');
}

# ── desaturate boundary: 100% ────────────────────────────────

{
    my $d = resolve_colour('.a { color: desaturate(#ff0000, 100%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'desaturate(#ff0000, 100%)', 'desaturate 100%: was evaluated');
}

# ── fade boundary: 0% ────────────────────────────────────────

{
    my $d = resolve_colour('.a { color: fade(#ff0000, 0%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/rgba/, 'fade 0%: produces rgba');
}

# ── fade boundary: 100% ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: fade(#ff0000, 100%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'fade(#ff0000, 100%)', 'fade 100%: was evaluated');
}

# ── tint boundary: 0 ─────────────────────────────────────────

{
    my $d = resolve_colour('.a { color: tint(#ff0000, 0); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'tint(#ff0000, 0)', 'tint 0: was evaluated');
}

# ── tint boundary: 100 ───────────────────────────────────────

{
    my $d = resolve_colour('.a { color: tint(#ff0000, 100); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'tint(#ff0000, 100)', 'tint 100: was evaluated');
}

# ── shade boundary: 0 ────────────────────────────────────────

{
    my $d = resolve_colour('.a { color: shade(#ff0000, 0); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'shade(#ff0000, 0)', 'shade 0: was evaluated');
}

# ── shade boundary: 100 ──────────────────────────────────────

{
    my $d = resolve_colour('.a { color: shade(#ff0000, 100); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'shade(#ff0000, 100)', 'shade 100: was evaluated');
}

# ── greyscale with already grey colour ────────────────────────

{
    my $d = resolve_colour('.a { color: greyscale(#808080); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'greyscale grey: produces hex');
}

# ── greyscale with white ─────────────────────────────────────

{
    my $d = resolve_colour('.a { color: greyscale(#ffffff); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'greyscale white: produces hex');
}

# ── greyscale with black ─────────────────────────────────────

{
    my $d = resolve_colour('.a { color: greyscale(#000000); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'greyscale black: produces hex');
}

# ── Multiple colour functions in compound value ──────────────

{
    my $d = resolve_colour('.a { border: 1px solid darken(#fff, 20%); }');
    my $v = $d->_ast_get_prop('.a', 'border');
    unlike($v, qr/darken/, 'colour in compound: function resolved');
    like($v, qr/1px solid #/, 'colour in compound: rest preserved');
}

# ── Colour function with 3-char hex ──────────────────────────

{
    my $d = resolve_colour('.a { color: lighten(#f00, 20%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/^#/, 'lighten 3-char hex: produces hex');
    isnt($v, 'lighten(#f00, 20%)', 'lighten 3-char hex: was evaluated');
}

# ── Colour function with named colour ────────────────────────

{
    my $d = resolve_colour('.a { color: lighten(red, 20%); }');
    my $v = $d->_ast_get_prop('.a', 'color');
    # May or may not support named colours — check it doesn't crash
    ok(defined $v, 'lighten named colour: does not crash');
}

# ── Multiple properties with colour functions ─────────────────

{
    my $d = resolve_colour('
        .a {
            color: lighten(#000, 50%);
            background: darken(#fff, 20%);
            border-color: mix(#f00, #00f, 50);
        }
    ');
    my $c = $d->_ast_get_prop('.a', 'color');
    my $b = $d->_ast_get_prop('.a', 'background');
    my $bc = $d->_ast_get_prop('.a', 'border-color');
    like($c, qr/^#/, 'multi colour: color resolved');
    like($b, qr/^#/, 'multi colour: background resolved');
    like($bc, qr/^#/, 'multi colour: border-color resolved');
}

# ── Colour functions untouched when inside string ─────────────

{
    my $d = resolve_colour('.a { content: "lighten(#000, 50%)"; }');
    my $v = $d->_ast_get_prop('.a', 'content');
    # Strings should be preserved as-is
    ok(defined $v, 'colour in string: does not crash');
}

# ── Background with colour function + gradient passthrough ───

{
    my $d = resolve_colour('.a { background: linear-gradient(lighten(#000, 50%), darken(#fff, 50%)); }');
    my $v = $d->_ast_get_prop('.a', 'background');
    ok(defined $v, 'colour in gradient: does not crash');
}

# ── Colour functions through full compile pipeline ───────────

{
    my $css = compile_css('
        $base: #3498db;
        .primary { color: $base; }
        .light { color: lighten(#3498db, 20%); }
        .dark { color: darken(#3498db, 20%); }
    ');
    unlike($css, qr/lighten/, 'full pipeline: lighten resolved');
    unlike($css, qr/darken/, 'full pipeline: darken resolved');
    unlike($css, qr/\$base/, 'full pipeline: var resolved');
    like($css, qr/\.primary\{color:#/, 'full pipeline: primary has colour');
    like($css, qr/\.light\{color:#/, 'full pipeline: light has colour');
    like($css, qr/\.dark\{color:#/, 'full pipeline: dark has colour');
}

# ── Multiple rules with same colour function ─────────────────

{
    my $d = resolve_colour('
        .a { color: lighten(#000, 50%); }
        .b { color: lighten(#000, 50%); }
    ');
    my $a = $d->_ast_get_prop('.a', 'color');
    my $b = $d->_ast_get_prop('.b', 'color');
    is($a, $b, 'same function: produces same result');
}

# ── lighten and darken are inverse-ish ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .light { color: lighten(#808080, 20%); }
        .dark { color: darken(#808080, 20%); }
    ');
    $d->_resolve_colours;
    my $light = $d->_ast_get_prop('.light', 'color');
    my $dark = $d->_ast_get_prop('.dark', 'color');
    isnt($light, $dark, 'lighten vs darken: different results');
}

# ── Colours stay resolved after compile ───────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: lighten(#000, 50%); }');
    my $css1 = $d->compile();
    my $css2 = $d->compile();
    is($css1, $css2, 'colour compile idempotent');
    unlike($css1, qr/lighten/, 'colour resolved in output');
}

done_testing;
