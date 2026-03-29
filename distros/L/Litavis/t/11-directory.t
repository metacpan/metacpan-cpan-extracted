use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Litavis');

# Helper to write a file
sub write_css {
    my ($dir, $name, $content) = @_;
    my $path = File::Spec->catfile($dir, $name);
    open my $fh, '>', $path or die "Cannot write $path: $!";
    print $fh $content;
    close $fh;
    return $path;
}

# ── Basic directory parsing ───────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '.a { color: red; }');
    write_css($dir, '02-theme.css', '.b { color: blue; }');

    my $d = Litavis->new(dedupe => 0);
    $d->parse_dir($dir);
    my $css = $d->compile();

    like($css, qr/\.a\{color:red;\}/, 'dir basic: .a from 01-base.css');
    like($css, qr/\.b\{color:blue;\}/, 'dir basic: .b from 02-theme.css');
}

# ── Sorted order: files processed alphabetically ──────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '02-theme.css', '.b { color: blue; }');
    write_css($dir, '01-base.css', '.a { color: red; }');
    write_css($dir, '03-extra.css', '.c { color: green; }');

    my $d = Litavis->new(dedupe => 0);
    $d->parse_dir($dir);
    my $css = $d->compile();

    # 01-base.css should be parsed first (sorted), then 02, then 03
    like($css, qr/\.a.*\.b.*\.c/s, 'dir sorted: files processed in alphabetical order');
}

# ── Only .css files processed ─────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '.a { color: red; }');
    write_css($dir, 'readme.txt', '.ignored { color: black; }');
    write_css($dir, 'data.json', '{"not": "css"}');
    write_css($dir, 'style.scss', '.also-ignored { color: grey; }');
    write_css($dir, '02-theme.css', '.b { color: blue; }');

    my $d = Litavis->new(dedupe => 0);
    $d->parse_dir($dir);
    my $css = $d->compile();

    like($css, qr/\.a/, 'dir filter: .css files included');
    like($css, qr/\.b/, 'dir filter: second .css file included');
    unlike($css, qr/ignored/, 'dir filter: .txt ignored');
    unlike($css, qr/also-ignored/, 'dir filter: .scss ignored');
}

# ── Variables shared across files in directory ─────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-vars.css', '$color: red; $bg: white;');
    write_css($dir, '02-use.css', '.card { color: $color; background: $bg; }');

    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();

    like($css, qr/color:red/, 'dir vars: $color resolved across files');
    like($css, qr/background:white/, 'dir vars: $bg resolved across files');
}

# ── Variable override in later file ───────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '$color: red; body { color: $color; }');
    write_css($dir, '02-override.css', '$color: blue; body { background: $color; }');

    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();

    # The same-selector merge combines the two body rules
    # Later file's $color (blue) should apply to its own scope
    like($css, qr/body/, 'dir override: body present');
}

# ── Dedup across files ────────────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '.btn { padding: 8px; color: white; }');
    write_css($dir, '02-theme.css', '.link { padding: 8px; color: white; }');

    my $d = Litavis->new(dedupe => 1);
    $d->parse_dir($dir);
    my $css = $d->compile();

    # Identical properties, no conflict → should merge
    like($css, qr/\.btn/, 'dir dedup: .btn present');
    like($css, qr/\.link/, 'dir dedup: .link present');
    my @braces = ($css =~ /\{/g);
    is(scalar @braces, 1, 'dir dedup: merged into one rule');
}

# ── Empty directory ───────────────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);

    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();

    is($css, '', 'dir empty: no files → empty output');
}

# ── Directory with only non-CSS files ─────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, 'readme.md', '# Title');
    write_css($dir, 'config.json', '{}');

    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();

    is($css, '', 'dir no css: only non-CSS files → empty output');
}

# ── Directory + additional parse call ──────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '.a { color: red; }');

    my $d = Litavis->new(dedupe => 0);
    $d->parse_dir($dir);
    $d->parse('.b { color: blue; }');
    my $css = $d->compile();

    like($css, qr/\.a.*\.b/s, 'dir + parse: both sources included');
}

# ── parse_file works ──────────────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    my $file = write_css($dir, 'single.css', '$x: green; .test { color: $x; }');

    my $d = Litavis->new;
    $d->parse_file($file);
    my $css = $d->compile();

    like($css, qr/\.test\{color:green;\}/, 'parse_file: single file with var');
}

# ── Non-recursive: subdirectories ignored ──────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, 'base.css', '.a { color: red; }');
    my $subdir = File::Spec->catdir($dir, 'sub');
    mkdir $subdir;
    write_css($subdir, 'nested.css', '.b { color: blue; }');

    my $d = Litavis->new(dedupe => 0);
    $d->parse_dir($dir);
    my $css = $d->compile();

    like($css, qr/\.a/, 'non-recursive: top-level file included');
    unlike($css, qr/\.b/, 'non-recursive: subdirectory file ignored');
}

# ── Crayon directory compat: overlapping body rules ────────────

{
    my $dir = tempdir(CLEANUP => 1);
    write_css($dir, '01-base.css', '
        $color: red;
        $background: black;
        body {
            margin: 10px;
            padding: 10px;
            color: $color;
            background: $background;
        }
    ');
    write_css($dir, '02-overide.css', '
        $color: black;
        $background: red;
        body {
            padding: 1em;
            color: $color;
            background: $background;
        }
    ');

    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();

    like($css, qr/body/, 'crayon dir: body present');
    like($css, qr/margin:10px/, 'crayon dir: margin from base');
    # After same-selector merge, later values win
    like($css, qr/color:black/, 'crayon dir: color overridden');
    like($css, qr/background:red/, 'crayon dir: background overridden');
    like($css, qr/padding:1em/, 'crayon dir: padding overridden');
}

done_testing;
