use strict;
use warnings;
use Test::More;

use_ok('Litavis');

# ── Simple variable substitution ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $color: red;
        .card { color: $color; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'red', 'simple var: $color resolved');
}

# ── Multiple variables ───────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $fg: white;
        $bg: black;
        .card { color: $fg; background: $bg; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'white', 'multi var: $fg');
    is($d->_ast_get_prop('.card', 'background'), 'black', 'multi var: $bg');
}

# ── Variable in compound value ───────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $size: 16px;
        .card { font: $size Arial; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'font'), '16px Arial', 'compound value: var in middle');
}

# ── Forward reference (hoisting) ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .card { color: $color; }
        $color: blue;
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'blue', 'forward reference: hoisted');
}

# ── Variable definitions removed from AST ────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $color: red;
        .card { color: $color; }
    ');
    $d->_resolve_vars;
    ok(!$d->_ast_has_rule('$color'), 'var def removed from AST');
    is($d->_ast_rule_count, 1, 'only .card rule remains');
}

# ── CSS custom properties passed through ─────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        :root { --primary: #ff0000; }
        .card { color: var(--primary); }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop(':root', '--primary'), '#ff0000', 'css var: --primary untouched');
    is($d->_ast_get_prop('.card', 'color'), 'var(--primary)', 'css var: var() untouched');
}

# ── Preprocessor var in CSS custom property value ────────────

{
    my $d = Litavis->new;
    $d->parse('
        $brand: #3498db;
        :root { --primary: $brand; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop(':root', '--primary'), '#3498db', 'preproc var in css custom prop value resolved');
}

# ── calc() and other CSS functions passed through ────────────

{
    my $d = Litavis->new;
    $d->parse('.card { width: calc(100% - 20px); }');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'width'), 'calc(100% - 20px)', 'calc() passthrough');
}

# ── Mixin definition and expansion ───────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %border: (
            border-top: dotted 1px black;
            border-bottom: solid 2px black;
        );
        .card { background: white; %border; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'background'), 'white', 'mixin: own prop kept');
    is($d->_ast_get_prop('.card', 'border-top'), 'dotted 1px black', 'mixin: border-top expanded');
    is($d->_ast_get_prop('.card', 'border-bottom'), 'solid 2px black', 'mixin: border-bottom expanded');
}

# ── Mixin definition removed from AST ────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %border: (border: 1px solid;);
        .card { %border; }
    ');
    $d->_resolve_vars;
    ok(!$d->_ast_has_rule('%border'), 'mixin def removed from AST');
}

# ── Map variable definition and access ───────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %colors: (
            primary: blue;
            secondary: green;
        );
        .btn { color: $colors{primary}; border: 1px solid $colors{secondary}; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.btn', 'color'), 'blue', 'map var: primary');
    is($d->_ast_get_prop('.btn', 'border'), '1px solid green', 'map var: secondary in compound');
}

# ── Undefined variable left as-is ────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.card { color: $undefined; }');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), '$undefined', 'undefined var: left as-is');
}

# ── Multiple parse calls with shared scope ───────────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red;');
    $d->parse('.card { color: $color; }');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'red', 'cross-parse var resolution');
}

# ── Reset clears variable scope ──────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red;');
    $d->reset;
    $d->parse('.card { color: $color; }');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), '$color', 'reset: clears var scope');
}

# ── Variable in variable ─────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $base: red;
        $primary: $base;
        .card { color: $primary; }
    ');
    $d->_resolve_vars;
    # Note: single-pass resolution — $primary gets "$base" which is then resolved
    # In the two-pass approach, $primary = "$base" after collection,
    # and during resolution "$base" in the value gets resolved to "red"
    is($d->_ast_get_prop('.card', 'color'), 'red', 'var in var: chained resolution');
}

done_testing;
