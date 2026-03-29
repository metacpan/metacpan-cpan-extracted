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

# ── Nested mixin in mixin (not recursively expanded) ────

{
    my $d = Litavis->new;
    $d->parse('
        %inner: (
            border: 1px solid;
        );
        %outer: (
            padding: 8px;
            %inner;
        );
        .card { %outer; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'padding'), '8px', 'nested mixin: outer prop');
    is($d->_ast_get_prop('.card', 'border'), '1px solid', 'nested mixin: inner prop expanded');
}

# ── Mixin redefinition ───────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %box: (padding: 4px;);
        %box: (padding: 8px;);
        .card { %box; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'padding'), '8px', 'mixin redef: later definition wins');
}

# ── Variable redefinition ────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $color: red;
        $color: blue;
        .a { color: $color; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.a', 'color'), 'blue', 'var redef: later value wins');
}

# ── Variable used in mixin value ─────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $border-color: #333;
        %border: (
            border: 1px solid $border-color;
        );
        .card { %border; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'border'), '1px solid #333',
        'var in mixin: resolved');
}

# ── Multiple mixins in one rule ──────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %spacing: (padding: 8px; margin: 4px;);
        %font: (font-size: 14px; font-weight: bold;);
        .card { color: red; %spacing; %font; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'red', 'multi mixin: own prop');
    is($d->_ast_get_prop('.card', 'padding'), '8px', 'multi mixin: from spacing');
    is($d->_ast_get_prop('.card', 'font-size'), '14px', 'multi mixin: from font');
    is($d->_ast_get_prop('.card', 'font-weight'), 'bold', 'multi mixin: font-weight');
}

# ── Mixin with many properties ───────────────────────────────

{
    my @props;
    for my $i (1..15) {
        push @props, "prop-$i: val-$i";
    }
    my $mixin_body = join('; ', @props) . ';';
    my $d = Litavis->new;
    $d->parse("%big: ($mixin_body); .card { %big; }");
    $d->_resolve_vars;
    for my $i (1, 8, 15) {
        is($d->_ast_get_prop('.card', "prop-$i"), "val-$i", "big mixin: prop-$i");
    }
}

# ── Variable chain: a -> b -> c ──────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $a: red;
        $b: $a;
        $c: $b;
        .card { color: $c; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'color'), 'red', 'var chain: a->b->c resolved');
}

# ── Variable in multiple properties ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $size: 16px;
        .card { font-size: $size; line-height: $size; padding: $size; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'font-size'), '16px', 'var multi-use: font-size');
    is($d->_ast_get_prop('.card', 'line-height'), '16px', 'var multi-use: line-height');
    is($d->_ast_get_prop('.card', 'padding'), '16px', 'var multi-use: padding');
}

# ── Variable with complex value ──────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
        .card { box-shadow: $shadow; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.card', 'box-shadow'), '0 2px 4px rgba(0, 0, 0, 0.3)', 'var complex value: rgba preserved');
}

# ── Variable at start, middle, end of compound value ─────────

{
    my $d = Litavis->new;
    $d->parse('
        $start: 1px;
        $mid: solid;
        $end: black;
        .a { border: $start $mid $end; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.a', 'border'), '1px solid black', 'vars in compound: all resolved');
}

# ── Escaped dollar sign (literal $) ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { content: "Price: $5"; }');
    $d->_resolve_vars;
    like($d->_ast_get_prop('.a', 'content'), qr/\$5/, 'dollar in string: not treated as var');
}

# ── Map variable with multiple keys ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %sizes: (
            sm: 12px;
            md: 16px;
            lg: 24px;
            xl: 32px;
        );
        .small { font-size: $sizes{sm}; }
        .medium { font-size: $sizes{md}; }
        .large { font-size: $sizes{lg}; }
        .xlarge { font-size: $sizes{xl}; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.small', 'font-size'), '12px', 'map: sm');
    is($d->_ast_get_prop('.medium', 'font-size'), '16px', 'map: md');
    is($d->_ast_get_prop('.large', 'font-size'), '24px', 'map: lg');
    is($d->_ast_get_prop('.xlarge', 'font-size'), '32px', 'map: xl');
}

# ── Undefined map key left as-is ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %sizes: (sm: 12px;);
        .a { font-size: $sizes{nonexistent}; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.a', 'font-size'), '$sizes{nonexistent}', 'undefined map key: left as-is');
}

# ── Mixin definitions removed from output ────────────────────

{
    my $css = compile_css('
        %box: (padding: 8px;);
        .card { %box; color: red; }
    ');
    unlike($css, qr/%box/, 'mixin def not in compiled output');
    like($css, qr/padding:8px/, 'mixin props in compiled output');
}

# ── Variable definitions removed from output ─────────────────

{
    my $css = compile_css('
        $color: red;
        .a { color: $color; }
    ');
    unlike($css, qr/\$color/, 'var def not in compiled output');
    is($css, '.a{color:red;}', 'var resolved in compiled output');
}

# ── Variables across multiple parse calls ─────────────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red; $size: 16px;');
    $d->parse('.card { color: $color; font-size: $size; }');
    $d->parse('.link { color: $color; }');
    my $css = $d->compile();
    like($css, qr/\.card\{color:red;font-size:16px;\}/, 'cross-parse: card resolved');
    like($css, qr/\.link\{color:red;\}/, 'cross-parse: link resolved');
}

# ── Reset clears mixins too ──────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('%box: (padding: 8px;);');
    $d->reset;
    $d->parse('.card { %box; }');
    $d->_resolve_vars;
    # %box should not be expanded since it was defined before reset
    ok(!$d->_ast_has_prop('.card', 'padding'), 'reset: clears mixin scope');
}

# ── Variable with CSS function value ─────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $width: calc(100% - 20px);
        .a { width: $width; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.a', 'width'), 'calc(100% - 20px)', 'var with calc(): resolved');
}

# ── Variable with var() CSS custom property ──────────────────

{
    my $d = Litavis->new;
    $d->parse('
        $fallback: var(--primary, blue);
        .a { color: $fallback; }
    ');
    $d->_resolve_vars;
    is($d->_ast_get_prop('.a', 'color'), 'var(--primary, blue)', 'var with var(): resolved');
}

# ── Mixin used in nested rule ────────────────────────────────

{
    my $css = compile_css('
        %text: (font-size: 14px; color: black;);
        .card {
            background: white;
            .title { %text; }
        }
    ');
    like($css, qr/\.card\{background:white;\}/, 'mixin in nested: parent ok');
    like($css, qr/\.card \.title\{font-size:14px;color:black;\}/, 'mixin in nested: child expanded');
}

# ── Variables in nested rules ─────────────────────────────────

{
    my $css = compile_css('
        $color: red;
        $hover-color: blue;
        .btn {
            color: $color;
            &:hover {
                color: $hover-color;
            }
        }
    ', dedupe => 0);
    like($css, qr/\.btn\{color:red;\}/, 'var in nested: parent');
    like($css, qr/\.btn:hover\{color:blue;\}/, 'var in nested: child');
}

# ── Same variable name in different parse calls ──────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red;');
    $d->parse('$color: blue;');
    $d->parse('.a { color: $color; }');
    my $css = $d->compile();
    is($css, '.a{color:blue;}', 'var overwrite across parse: later wins');
}

done_testing;
