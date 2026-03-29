use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);

use_ok('Litavis');

# Helper: parse + compile in one shot
sub compile_css {
    my ($css, %opts) = @_;
    my $d = Litavis->new(%opts);
    $d->parse($css);
    return $d->compile();
}

# ── Full pipeline: nested selectors + variables + dedup ────────

{
    my $css = compile_css('
        $brand: #3498db;
        .card {
            color: $brand;
            .title {
                font-size: 18px;
            }
            &:hover {
                color: darken($brand, 20%);
            }
        }
    ');
    like($css, qr/\.card\{color:#3498db;\}/, 'pipeline: var resolved in parent');
    like($css, qr/\.card \.title\{font-size:18px;\}/, 'pipeline: nested child flattened');
    like($css, qr/\.card:hover\{color:#/, 'pipeline: & flattened + colour resolved');
    unlike($css, qr/\$brand/, 'pipeline: no unresolved vars');
    unlike($css, qr/darken/, 'pipeline: no unresolved colour functions');
}

# ── Full pipeline: multiple parse calls accumulate ─────────────

{
    my $d = Litavis->new;
    $d->parse('$color: red;');
    $d->parse('.a { color: $color; }');
    $d->parse('.b { color: $color; font-size: 16px; }');
    my $css = $d->compile();
    like($css, qr/\.a\{color:red;\}/, 'accumulate: .a resolved');
    like($css, qr/\.b\{color:red;font-size:16px;\}/, 'accumulate: .b resolved');
}

# ── Full pipeline: mixin + dedup ───────────────────────────────

{
    my $css = compile_css('
        %box: (
            padding: 8px;
            margin: 0;
        );
        .card { %box; color: red; }
        .panel { %box; color: blue; }
    ');
    like($css, qr/padding:8px/, 'mixin: padding expanded');
    like($css, qr/margin:0/, 'mixin: margin present');
    like($css, qr/\.card.*color:red/, 'mixin: card props');
    like($css, qr/\.panel.*color:blue/, 'mixin: panel props');
}

# ── Full pipeline: @media presence ─────────────────────────────

{
    my $css = compile_css('
        .container { max-width: 1200px; }
        @media (max-width: 768px) {
            .container { max-width: 100%; }
        }
    ', dedupe => 0);
    like($css, qr/\.container/, 'media: container rule present');
    like($css, qr/\@media/, 'media: @media present in output');
}

# ── Full pipeline: pretty mode end-to-end ──────────────────────

{
    my $css = compile_css('
        $color: blue;
        .btn {
            color: $color;
            padding: 8px 16px;
            &:hover {
                color: red;
            }
        }
    ', pretty => 1, dedupe => 0);
    like($css, qr/\.btn \{\n/, 'pretty e2e: opening brace');
    like($css, qr/color: blue;/, 'pretty e2e: var resolved');
    like($css, qr/\.btn:hover \{\n/, 'pretty e2e: hover flattened');
}

# ── Full pipeline: reset between independent compilations ──────

{
    my $d = Litavis->new;
    $d->parse('$x: red; .a { color: $x; }');
    my $first = $d->compile();
    like($first, qr/\.a\{color:red;\}/, 'reset e2e: first compile');

    $d->reset;
    $d->parse('$x: blue; .b { color: $x; }');
    my $second = $d->compile();
    like($second, qr/\.b\{color:blue;\}/, 'reset e2e: second compile');
    unlike($second, qr/\.a/, 'reset e2e: first rules gone');
}

# ── Full pipeline: chaining API ────────────────────────────────

{
    my $css = Litavis->new->parse('.a { color: red; }')->compile();
    is($css, '.a{color:red;}', 'chaining: parse->compile');
}

# ── Full pipeline: @import hoisting with variables ─────────────

{
    my $css = compile_css('
        $color: red;
        .a { color: $color; }
        @import url("reset.css");
    ', dedupe => 0);
    ok($css =~ /^\@import/, 'hoist e2e: @import first');
    like($css, qr/\.a\{color:red;\}/, 'hoist e2e: var still resolved');
}

# ── Full pipeline: CSS custom properties passthrough ───────────

{
    my $css = compile_css('
        $brand: #3498db;
        :root {
            --primary: $brand;
            --spacing: 8px;
        }
        .btn {
            color: var(--primary);
            padding: var(--spacing);
        }
    ');
    like($css, qr/--primary:#3498db/, 'css vars e2e: preproc var resolved in custom prop');
    like($css, qr/--spacing:8px/, 'css vars e2e: plain custom prop');
    like($css, qr/var\(--primary\)/, 'css vars e2e: var() reference passthrough');
    like($css, qr/var\(--spacing\)/, 'css vars e2e: var() spacing passthrough');
}

# ── Full pipeline: parse_file + compile ────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    my $file = "$dir/test.css";
    open my $fh, '>', $file or die "Cannot write $file: $!";
    print $fh '$color: green; .test { color: $color; }';
    close $fh;

    my $d = Litavis->new;
    $d->parse_file($file);
    my $css = $d->compile();
    like($css, qr/\.test\{color:green;\}/, 'parse_file e2e: var resolved from file');
}

# ── Full pipeline: compile is idempotent ───────────────────────

{
    my $d = Litavis->new;
    $d->parse('$x: red; .a { color: $x; } .b { color: $x; }');
    my $first = $d->compile();
    my $second = $d->compile();
    my $third = $d->compile();
    is($first, $second, 'idempotent: 1st == 2nd');
    is($second, $third, 'idempotent: 2nd == 3rd');
}

# ── Full pipeline: dedup + same-selector merge combined ────────

{
    my $css = compile_css('
        .a { color: red; }
        .a { background: blue; }
        .b { font-size: 16px; }
        .c { color: red; background: blue; }
    ');
    like($css, qr/\.a.*\.c/, 'combined dedup: .a and .c merged (same props after same-sel merge)');
}

# ── Full pipeline: map variable + colour function ──────────────

{
    my $css = compile_css('
        %palette: (
            primary: #3498db;
            dark: #2c3e50;
        );
        .header {
            background: $palette{primary};
            color: lighten($palette{dark}, 30%);
        }
    ');
    like($css, qr/background:#3498db/, 'map+colour: map var resolved');
    unlike($css, qr/lighten/, 'map+colour: colour function evaluated');
    like($css, qr/color:#/, 'map+colour: produces hex');
}

# ── Full pipeline: shorthand_hex through pipeline ──────────────

{
    my $css = compile_css('.a { color: #ffffff; background: #aabbcc; border: 1px solid #aabbcd; }',
        shorthand_hex => 1);
    like($css, qr/color:#fff;/, 'shorthand hex e2e: #ffffff -> #fff');
    like($css, qr/background:#abc;/, 'shorthand hex e2e: #aabbcc -> #abc');
    like($css, qr/border:1px solid #aabbcd;/, 'shorthand hex e2e: #aabbcd unchanged');
}

# ── Full pipeline: sort_props through pipeline ─────────────────

{
    my $css = compile_css('.a { z-index: 1; color: red; background: blue; }',
        sort_props => 1);
    is($css, '.a{background:blue;color:red;z-index:1;}', 'sort props e2e: alphabetical');
}

# ── Full pipeline: empty rules stripped ────────────────────────

{
    my $css = compile_css('
        .empty {}
        .also-empty { }
        .filled { color: red; }
    ');
    unlike($css, qr/empty/, 'empty rules e2e: stripped');
    like($css, qr/\.filled\{color:red;\}/, 'empty rules e2e: filled kept');
}

done_testing;
