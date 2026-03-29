use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use_ok('Litavis');

# ── Simple minified output ───────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.card { color: red; font-size: 16px; }');
    is($d->compile(), '.card{color:red;font-size:16px;}', 'minified: simple rule');
}

# ── Multiple rules ──────────────────────────────────────────

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.a { color: red; } .b { color: blue; }');
    is($d->compile(), '.a{color:red;}.b{color:blue;}', 'minified: multiple rules');
}

# ── Pretty-printed output ──────────────────────────────────

{
    my $d = Litavis->new(pretty => 1);
    $d->parse('.card { color: red; font-size: 16px; }');
    my $expected = ".card {\n  color: red;\n  font-size: 16px;\n}\n";
    is($d->compile(), $expected, 'pretty: simple rule');
}

# ── Pretty with custom indent ──────────────────────────────

{
    my $d = Litavis->new(pretty => 1, indent => "\t");
    $d->parse('.card { color: red; }');
    my $expected = ".card {\n\tcolor: red;\n}\n";
    is($d->compile(), $expected, 'pretty: tab indent');
}

# ── Pretty with multiple rules ─────────────────────────────

{
    my $d = Litavis->new(pretty => 1, dedupe => 0);
    $d->parse('.a { color: red; } .b { color: blue; }');
    my $expected = ".a {\n  color: red;\n}\n.b {\n  color: blue;\n}\n";
    is($d->compile(), $expected, 'pretty: multiple rules');
}

# ── Empty rule omitted ─────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.empty { } .filled { color: red; }');
    is($d->compile(), '.filled{color:red;}', 'empty rules omitted');
}

# ── Hex shorthand ──────────────────────────────────────────

{
    my $d = Litavis->new(shorthand_hex => 1);
    $d->parse('.a { color: #ffffff; }');
    is($d->compile(), '.a{color:#fff;}', 'hex shorthand: #ffffff → #fff');
}

{
    my $d = Litavis->new(shorthand_hex => 1);
    $d->parse('.a { color: #aabbcc; }');
    is($d->compile(), '.a{color:#abc;}', 'hex shorthand: #aabbcc → #abc');
}

{
    my $d = Litavis->new(shorthand_hex => 1);
    $d->parse('.a { color: #aabbcd; }');
    is($d->compile(), '.a{color:#aabbcd;}', 'hex shorthand: #aabbcd stays long');
}

{
    my $d = Litavis->new(shorthand_hex => 0);
    $d->parse('.a { color: #ffffff; }');
    is($d->compile(), '.a{color:#ffffff;}', 'hex shorthand disabled: stays long');
}

# ── Property sorting ────────────────────────────────────────

{
    my $d = Litavis->new(sort_props => 1);
    $d->parse('.a { z-index: 1; color: red; background: blue; }');
    is($d->compile(), '.a{background:blue;color:red;z-index:1;}', 'sort props: alphabetical');
}

{
    my $d = Litavis->new(sort_props => 0);
    $d->parse('.a { z-index: 1; color: red; background: blue; }');
    is($d->compile(), '.a{z-index:1;color:red;background:blue;}', 'sort props off: source order');
}

# ── Variable resolution through compile ─────────────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red; .a { color: $color; }');
    is($d->compile(), '.a{color:red;}', 'compile: variable resolution');
}

# ── Colour function through compile ─────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: lighten(#000, 50%); }');
    my $css = $d->compile();
    unlike($css, qr/lighten/, 'compile: colour function evaluated');
    like($css, qr/#/, 'compile: colour function produces hex');
}

# ── Var + colour through compile ────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('$base: #ff0000; .a { color: lighten($base, 20%); }');
    my $css = $d->compile();
    unlike($css, qr/lighten/, 'compile: var+colour evaluated');
    unlike($css, qr/\$base/, 'compile: var resolved before colour');
}

# ── Deduplication through compile ───────────────────────────

{
    my $d = Litavis->new(dedupe => 1);
    $d->parse('.a { color: red; } .a { font-size: 16px; }');
    is($d->compile(), '.a{color:red;font-size:16px;}', 'compile: dedup merges same selector');
}

# ── Mixin expansion through compile ─────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        %border: (
            border-top: dotted 1px black;
            border-bottom: solid 2px black;
        );
        .card { background: white; %border; }
    ');
    my $css = $d->compile();
    like($css, qr/border-top:dotted 1px black/, 'compile: mixin expanded');
    like($css, qr/background:white/, 'compile: own props kept');
}

# ── Nested rules ────────────────────────────────────────────

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.card { color: red; &:hover { color: blue; } }');
    my $css = $d->compile();
    like($css, qr/\.card\{color:red;\}/, 'nested: parent rule');
    like($css, qr/\.card:hover\{color:blue;\}/, 'nested: child rule flattened');
}

# ── @media rule ─────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('@media (max-width: 768px) { .card { color: red; } }');
    my $css = $d->compile();
    like($css, qr/\@media.*\{/, 'at-rule: @media present');
    like($css, qr/\.card\{color:red;\}/, 'at-rule: nested rule');
}

# ── @media pretty ──────────────────────────────────────────

{
    my $d = Litavis->new(pretty => 1);
    $d->parse('@media (max-width: 768px) { .card { color: red; } }');
    my $css = $d->compile();
    like($css, qr/\@media \(max-width: 768px\) \{\n/, 'at-rule pretty: opening');
    like($css, qr/  \.card \{\n    color: red;\n  \}\n/, 'at-rule pretty: nested indented');
}

# ── @import hoisting ───────────────────────────────────────

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.a { color: red; }');
    $d->parse('@import url("base.css");');
    my $css = $d->compile();
    ok($css =~ /^\@import/, 'hoisting: @import appears first');
    like($css, qr/\@import.*\.a\{/, 'hoisting: @import before .a');
}

# ── @charset hoisting ─────────────────────────────────────

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.a { color: red; }');
    $d->parse('@charset "UTF-8";');
    my $css = $d->compile();
    ok($css =~ /^\@charset/, 'hoisting: @charset appears first');
}

# ── compile_file ───────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.css', UNLINK => 1);
    close $fh;
    $d->compile_file($tmpfile);
    open my $rfh, '<', $tmpfile or die "Cannot open $tmpfile: $!";
    my $content = do { local $/; <$rfh> };
    close $rfh;
    is($content, '.a{color:red;}', 'compile_file: writes correct CSS');
    unlink $tmpfile;
}

# ── compile is non-destructive ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red; .a { color: $color; }');
    my $css1 = $d->compile();
    my $css2 = $d->compile();
    is($css1, $css2, 'compile: non-destructive (same result twice)');
}

# ── Multiple parse + compile ───────────────────────────────

{
    my $d = Litavis->new(dedupe => 0);
    $d->parse('.a { color: red; }');
    $d->parse('.b { color: blue; }');
    is($d->compile(), '.a{color:red;}.b{color:blue;}', 'multi parse + compile');
}

# ── Reset between compilations ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->compile();
    $d->reset;
    $d->parse('.b { color: blue; }');
    is($d->compile(), '.b{color:blue;}', 'reset: clears between compilations');
}

# ── CSS custom properties passthrough ──────────────────────

{
    my $d = Litavis->new;
    $d->parse(':root { --primary: #ff0000; } .a { color: var(--primary); }');
    my $css = $d->compile();
    like($css, qr/--primary:#f00/, 'css vars: custom property preserved');
    like($css, qr/var\(--primary\)/, 'css vars: var() preserved');
}

# ── Compound values ────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { border: 1px solid red; margin: 0 auto; }');
    is($d->compile(), '.a{border:1px solid red;margin:0 auto;}', 'compound values preserved');
}

# ── Multiple properties same rule ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; background: blue; font-size: 14px; padding: 8px; }');
    is($d->compile(),
       '.a{color:red;background:blue;font-size:14px;padding:8px;}',
       'multiple props: all emitted in order');
}

# ── Pretty with sort ───────────────────────────────────────

{
    my $d = Litavis->new(pretty => 1, sort_props => 1);
    $d->parse('.a { z-index: 1; color: red; }');
    my $expected = ".a {\n  color: red;\n  z-index: 1;\n}\n";
    is($d->compile(), $expected, 'pretty + sort: combined');
}

done_testing;
