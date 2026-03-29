use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);

use_ok('Litavis');

# Helper
sub compile_css {
    my ($css, %opts) = @_;
    my $d = Litavis->new(%opts);
    $d->parse($css);
    return $d->compile();
}

# ── _ast_add_prop on non-existent rule croaks ─────────────────

{
    my $d = Litavis->new;
    eval { $d->_ast_add_prop('.nonexistent', 'color', 'red') };
    like($@, qr/no rule with selector/, '_ast_add_prop: croak on missing rule');
}

# ── _ast_merge_props croaks when dst missing ─────────────────

{
    my $d = Litavis->new;
    $d->_ast_add_rule('.a');
    eval { $d->_ast_merge_props('.nonexistent', '.a') };
    like($@, qr/rule not found for merge/, '_ast_merge_props: croak on missing dst');
}

# ── _ast_merge_props croaks when src missing ─────────────────

{
    my $d = Litavis->new;
    $d->_ast_add_rule('.a');
    eval { $d->_ast_merge_props('.a', '.nonexistent') };
    like($@, qr/rule not found for merge/, '_ast_merge_props: croak on missing src');
}

# ── _ast_merge_props croaks when both missing ────────────────

{
    my $d = Litavis->new;
    eval { $d->_ast_merge_props('.x', '.y') };
    like($@, qr/rule not found for merge/, '_ast_merge_props: croak on both missing');
}

# ── _ast_get_prop returns undef for missing rule ─────────────

{
    my $d = Litavis->new;
    my $v = $d->_ast_get_prop('.nonexistent', 'color');
    ok(!defined $v, '_ast_get_prop: undef for missing rule');
}

# ── _ast_get_prop returns undef for missing prop ─────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    my $v = $d->_ast_get_prop('.a', 'nonexistent');
    ok(!defined $v, '_ast_get_prop: undef for missing prop');
}

# ── _ast_has_prop returns 0 for missing rule ─────────────────

{
    my $d = Litavis->new;
    is($d->_ast_has_prop('.nonexistent', 'color'), 0, '_ast_has_prop: 0 for missing rule');
}

# ── _ast_prop_count returns 0 for missing rule ──────────────

{
    my $d = Litavis->new;
    is($d->_ast_prop_count('.nonexistent'), 0, '_ast_prop_count: 0 for missing rule');
}

# ── _ast_rules_props_equal returns 0 for missing rules ──────

{
    my $d = Litavis->new;
    $d->_ast_add_rule('.a');
    is($d->_ast_rules_props_equal('.a', '.nonexistent'), 0, 'props_equal: 0 when right missing');
    is($d->_ast_rules_props_equal('.nonexistent', '.a'), 0, 'props_equal: 0 when left missing');
    is($d->_ast_rules_props_equal('.x', '.y'), 0, 'props_equal: 0 when both missing');
}

# ── _ast_rule_selector returns undef for out-of-bounds index ─

{
    my $d = Litavis->new;
    $d->_ast_add_rule('.a');
    my $s = $d->_ast_rule_selector(99);
    ok(!defined $s, '_ast_rule_selector: undef for index too large');

    my $s2 = $d->_ast_rule_selector(-1);
    ok(!defined $s2, '_ast_rule_selector: undef for negative index');
}

# ── parse_file with non-existent file ────────────────────────

{
    my $d = Litavis->new;
    # Should not die, just silently skip (C fopen returns NULL)
    eval { $d->parse_file('/tmp/__litavis_no_such_file_12345.css') };
    # Check it didn't crash — either no error or a controlled error
    ok(1, 'parse_file: non-existent file does not crash');
}

# ── parse_dir with non-existent directory ────────────────────

{
    my $d = Litavis->new;
    eval { $d->parse_dir('/tmp/__litavis_no_such_dir_12345/') };
    ok(1, 'parse_dir: non-existent dir does not crash');
}

# ── compile_file writes output to a real file ────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.css');
    close $fh;
    $d->compile_file($filename);
    open my $in, '<', $filename or die "Can't read $filename: $!";
    my $content = do { local $/; <$in> };
    close $in;
    like($content, qr/\.a\{color:red;\}/, 'compile_file: output written to file');
}

# ── Malformed CSS: unclosed brace ─────────────────────────────

{
    my $css = compile_css('.a { color: red;');
    # Should produce something (may be empty or partial) but not crash
    ok(defined $css, 'unclosed brace: does not crash');
}

# ── Malformed CSS: extra closing brace ────────────────────────

{
    my $css = compile_css('.a { color: red; } }');
    ok(defined $css, 'extra closing brace: does not crash');
    like($css, qr/\.a\{color:red;\}/, 'extra closing brace: rule still parsed');
}

# ── Malformed CSS: missing property value ─────────────────────

{
    my $css = compile_css('.a { color: ; }');
    ok(defined $css, 'empty property value: does not crash');
}

# ── Malformed CSS: missing colon ──────────────────────────────

{
    my $css = compile_css('.a { color red; }');
    ok(defined $css, 'missing colon: does not crash');
}

# ── Malformed CSS: no selector ────────────────────────────────

{
    my $css = compile_css('{ color: red; }');
    ok(defined $css, 'no selector: does not crash');
}

# ── Malformed CSS: nested unclosed braces ─────────────────────

{
    my $css = compile_css('.a { .b { color: red; }');
    ok(defined $css, 'nested unclosed brace: does not crash');
}

# ── Malformed CSS: only closing brace ─────────────────────────

{
    my $css = compile_css('}');
    ok(defined $css, 'only closing brace: does not crash');
}

# ── Empty rule compiles to nothing ────────────────────────────

{
    my $css = compile_css('.a { }');
    is($css, '', 'empty rule: produces empty output');
}

# ── Multiple empty rules ─────────────────────────────────────

{
    my $css = compile_css('.a { } .b { } .c { }');
    is($css, '', 'multiple empty rules: produces empty output');
}

# ── Reset then compile ───────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->reset;
    my $css = $d->compile();
    is($css, '', 'reset then compile: empty output');
}

# ── Double reset ──────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->reset;
    $d->reset;
    my $css = $d->compile();
    is($css, '', 'double reset: does not crash');
}

# ── Compile on fresh new() with no parse ─────────────────────

{
    my $d = Litavis->new;
    my $css = $d->compile();
    is($css, '', 'compile without parse: empty output');
}

# ── _resolve_vars on empty AST ───────────────────────────────

{
    my $d = Litavis->new;
    eval { $d->_resolve_vars };
    ok(!$@, '_resolve_vars on empty AST: does not crash');
}

# ── _resolve_colours on empty AST ────────────────────────────

{
    my $d = Litavis->new;
    eval { $d->_resolve_colours };
    ok(!$@, '_resolve_colours on empty AST: does not crash');
}

# ── _dedupe on empty AST ─────────────────────────────────────

{
    my $d = Litavis->new;
    eval { $d->_dedupe(1) };
    ok(!$@, '_dedupe on empty AST: does not crash');
}

# ── parse_file with empty file ────────────────────────────────

{
    my ($fh, $filename) = tempfile(UNLINK => 1, SUFFIX => '.css');
    print $fh '';
    close $fh;
    my $d = Litavis->new;
    $d->parse_file($filename);
    my $css = $d->compile();
    is($css, '', 'parse_file empty file: empty output');
}

# ── parse_dir with empty directory ────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();
    is($css, '', 'parse_dir empty dir: empty output');
}

# ── parse_dir with non-CSS files ─────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    # Create a non-CSS file
    open my $fh, '>', "$dir/readme.txt" or die $!;
    print $fh "This is not CSS";
    close $fh;
    my $d = Litavis->new;
    $d->parse_dir($dir);
    my $css = $d->compile();
    is($css, '', 'parse_dir non-CSS files: ignored');
}

done_testing;
