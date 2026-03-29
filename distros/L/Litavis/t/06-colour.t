use strict;
use warnings;
use Test::More;

use_ok('Litavis');

# ── lighten ───────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: lighten(#000, 50%); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    ok(defined $v && $v =~ /^#/, 'lighten: produces hex colour');
    isnt($v, 'lighten(#000, 50%)', 'lighten: was evaluated');
}

# ── darken ────────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: darken(#fff, 50%); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    ok(defined $v && $v =~ /^#/, 'darken: produces hex colour');
    isnt($v, 'darken(#fff, 50%)', 'darken: was evaluated');
}

# ── mix ───────────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: mix(#fff, #000, 50); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    ok(defined $v && $v =~ /^#/, 'mix: produces hex colour');
    isnt($v, 'mix(#fff, #000, 50)', 'mix: was evaluated');
}

# ── greyscale ─────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: greyscale(#ff0000); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    ok(defined $v && $v =~ /^#/, 'greyscale: produces hex colour');
    isnt($v, 'greyscale(#ff0000)', 'greyscale: was evaluated');
}

# ── saturate ──────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: saturate(#808080, 50%); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'saturate(#808080, 50%)', 'saturate: was evaluated');
}

# ── desaturate ────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: desaturate(#ff0000, 50%); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'desaturate(#ff0000, 50%)', 'desaturate: was evaluated');
}

# ── tint ──────────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: tint(#000000, 50); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'tint(#000000, 50)', 'tint: was evaluated');
}

# ── shade ─────────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: shade(#ffffff, 50); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    isnt($v, 'shade(#ffffff, 50)', 'shade: was evaluated');
}

# ── fade ──────────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: fade(#ff0000, 50%); }');
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    like($v, qr/rgba/, 'fade: produces rgba (alpha < 1)');
}

# ── Non-colour functions pass through ─────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { width: calc(100% - 20px); }');
    $d->_resolve_colours;
    is($d->_ast_get_prop('.a', 'width'), 'calc(100% - 20px)', 'calc: passthrough');
}

{
    my $d = Litavis->new;
    $d->parse('.a { color: var(--primary); }');
    $d->_resolve_colours;
    is($d->_ast_get_prop('.a', 'color'), 'var(--primary)', 'var(): passthrough');
}

{
    my $d = Litavis->new;
    $d->parse('.a { background: linear-gradient(to right, red, blue); }');
    $d->_resolve_colours;
    is($d->_ast_get_prop('.a', 'background'), 'linear-gradient(to right, red, blue)', 'linear-gradient: passthrough');
}

# ── Colour function with variable resolution ─────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $base: #ff0000;
        .a { color: lighten($base, 20%); }
    ');
    $d->_resolve_vars;
    $d->_resolve_colours;
    my $v = $d->_ast_get_prop('.a', 'color');
    ok(defined $v && $v =~ /^#/, 'var + colour: resolved together');
}

# ── Multiple colour functions in one rule ─────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a {
            color: lighten(#000, 50%);
            background: darken(#fff, 20%);
        }
    ');
    $d->_resolve_colours;
    my $c = $d->_ast_get_prop('.a', 'color');
    my $b = $d->_ast_get_prop('.a', 'background');
    ok($c =~ /^#/ && $c ne 'lighten(#000, 50%)', 'multi: color resolved');
    ok($b =~ /^#/ && $b ne 'darken(#fff, 20%)', 'multi: background resolved');
}

# ── Value without colour function untouched ───────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; font-size: 16px; }');
    $d->_resolve_colours;
    is($d->_ast_get_prop('.a', 'color'), 'red', 'plain value: untouched');
    is($d->_ast_get_prop('.a', 'font-size'), '16px', 'plain value: untouched');
}

done_testing;
