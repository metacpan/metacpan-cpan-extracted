use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Litavis');

# ── Simple rule parsing ──────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.card { color: red; font-size: 16px; }');
    is($d->_ast_rule_count, 1, 'simple rule: one rule');
    ok($d->_ast_has_rule('.card'), 'simple rule: selector .card');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'simple rule: color is red');
    is($d->_ast_get_prop('.card', 'font-size'), '16px', 'simple rule: font-size');
}

# ── Multiple rules ───────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .alpha { color: red; }
        .beta  { color: blue; }
        .gamma { color: green; }
    ');
    is($d->_ast_rule_count, 3, 'multiple rules: count');
    is($d->_ast_rule_selector(0), '.alpha', 'multiple rules: order 0');
    is($d->_ast_rule_selector(1), '.beta',  'multiple rules: order 1');
    is($d->_ast_rule_selector(2), '.gamma', 'multiple rules: order 2');
}

# ── Nesting with descendant selector ─────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .card {
            color: red;
            .title {
                font-size: 16px;
            }
        }
    ');
    ok($d->_ast_has_rule('.card'), 'nesting: parent rule');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'nesting: parent prop');
    ok($d->_ast_has_rule('.card .title'), 'nesting: child flattened to .card .title');
    is($d->_ast_get_prop('.card .title', 'font-size'), '16px', 'nesting: child prop');
}

# ── Nesting with & parent reference ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .card {
            color: red;
            &:hover {
                color: blue;
            }
            &.active {
                color: green;
            }
        }
    ');
    ok($d->_ast_has_rule('.card'), 'ampersand: parent');
    ok($d->_ast_has_rule('.card:hover'), 'ampersand: &:hover flattened');
    is($d->_ast_get_prop('.card:hover', 'color'), 'blue', 'ampersand: hover color');
    ok($d->_ast_has_rule('.card.active'), 'ampersand: &.active flattened');
    is($d->_ast_get_prop('.card.active', 'color'), 'green', 'ampersand: active color');
}

# ── Deep nesting ─────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .a {
            color: red;
            .b {
                color: blue;
                .c {
                    color: green;
                }
            }
        }
    ');
    ok($d->_ast_has_rule('.a'), 'deep nesting: .a');
    ok($d->_ast_has_rule('.a .b'), 'deep nesting: .a .b');
    ok($d->_ast_has_rule('.a .b .c'), 'deep nesting: .a .b .c');
    is($d->_ast_get_prop('.a .b .c', 'color'), 'green', 'deep nesting: deepest prop');
}

# ── Block comments ────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        /* This is a comment */
        .card {
            color: red; /* inline comment */
        }
    ');
    is($d->_ast_rule_count, 1, 'block comments: stripped');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'block comments: value correct');
}

# ── Line comments ─────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        // This is a line comment
        .card {
            color: red; // inline line comment
            font-size: 16px;
        }
    ');
    is($d->_ast_rule_count, 1, 'line comments: stripped');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'line comments: value correct');
    is($d->_ast_get_prop('.card', 'font-size'), '16px', 'line comments: next prop correct');
}

# ── @media rule ───────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        @media (max-width: 768px) {
            .card {
                font-size: 14px;
            }
        }
    ');
    ok($d->_ast_has_rule('@media (max-width: 768px)'), 'at-rule: @media parsed');
}

# ── @import rule ──────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('@import url("style.css");');
    ok($d->_ast_has_rule('@import url("style.css")'), 'at-rule: @import parsed');
}

# ── @keyframes ────────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
    ');
    ok($d->_ast_has_rule('@keyframes fadeIn'), 'at-rule: @keyframes parsed');
}

# ── Complex values with functions ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .card {
            width: calc(100% - 20px);
            color: rgba(255, 0, 0, 0.5);
            background: linear-gradient(to right, red, blue);
        }
    ');
    is($d->_ast_get_prop('.card', 'width'), 'calc(100% - 20px)', 'functions: calc()');
    is($d->_ast_get_prop('.card', 'color'), 'rgba(255, 0, 0, 0.5)', 'functions: rgba()');
    is($d->_ast_get_prop('.card', 'background'), 'linear-gradient(to right, red, blue)', 'functions: linear-gradient()');
}

# ── CSS custom properties ─────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        :root {
            --primary-color: #ff0000;
            --spacing: 8px;
        }
        .card {
            color: var(--primary-color);
            margin: var(--spacing);
        }
    ');
    ok($d->_ast_has_rule(':root'), 'css vars: :root parsed');
    is($d->_ast_get_prop(':root', '--primary-color'), '#ff0000', 'css vars: custom prop value');
    is($d->_ast_get_prop('.card', 'color'), 'var(--primary-color)', 'css vars: var() reference');
}

# ── Comma selectors ──────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        h1, h2, h3 {
            font-weight: bold;
        }
    ');
    ok($d->_ast_has_rule('h1, h2, h3'), 'comma selectors: grouped');
    is($d->_ast_get_prop('h1, h2, h3', 'font-weight'), 'bold', 'comma selectors: prop');
}

# ── String values ─────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .card {
            content: "hello world";
            font-family: "Helvetica Neue", sans-serif;
        }
    ');
    is($d->_ast_get_prop('.card', 'content'), '"hello world"', 'strings: double quoted');
    is($d->_ast_get_prop('.card', 'font-family'), '"Helvetica Neue", sans-serif', 'strings: in font-family');
}

# ── Multiple parse calls accumulate ──────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    $d->parse('.b { color: blue; }');
    is($d->_ast_rule_count, 2, 'accumulate: two parse calls');
    ok($d->_ast_has_rule('.a'), 'accumulate: first');
    ok($d->_ast_has_rule('.b'), 'accumulate: second');
}

# ── Parse chaining ────────────────────────────────────────────

{
    my $d = Litavis->new;
    my $ret = $d->parse('.x { color: red; }');
    isa_ok($ret, 'Litavis', 'chaining: parse returns self');
}

# ── Reset clears parsed state ────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('.a { color: red; }');
    is($d->_ast_rule_count, 1, 'reset: before');
    $d->reset;
    is($d->_ast_rule_count, 0, 'reset: after');
}

# ── Pseudo-selectors with colons ─────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        a:hover { color: red; }
        a::before { content: "x"; }
        .btn:nth-child(2n+1) { color: blue; }
    ');
    ok($d->_ast_has_rule('a:hover'), 'pseudo: :hover');
    ok($d->_ast_has_rule('a::before'), 'pseudo: ::before');
    ok($d->_ast_has_rule('.btn:nth-child(2n+1)'), 'pseudo: :nth-child()');
}

# ── Attribute selectors ──────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        input[type="text"] { border: 1px solid; }
    ');
    ok($d->_ast_has_rule('input[type="text"]'), 'attr selector: parsed');
}

# ── File parsing ──────────────────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);
    my $file = File::Spec->catfile($dir, 'test.css');
    open my $fh, '>', $file or die "Cannot write $file: $!";
    print $fh ".from-file { color: red; font-size: 12px; }\n";
    close $fh;

    my $d = Litavis->new;
    $d->parse_file($file);
    ok($d->_ast_has_rule('.from-file'), 'parse_file: rule found');
    is($d->_ast_get_prop('.from-file', 'color'), 'red', 'parse_file: prop');
}

# ── Directory parsing ─────────────────────────────────────────

{
    my $dir = tempdir(CLEANUP => 1);

    # Write files in reverse alphabetical order to test sorting
    for my $name (qw(c.css b.css a.css)) {
        my $file = File::Spec->catfile($dir, $name);
        (my $class = $name) =~ s/\.css$//;
        open my $fh, '>', $file or die "Cannot write $file: $!";
        print $fh ".$class { content: '$class'; }\n";
        close $fh;
    }

    # Also add a non-.css file to ensure it's ignored
    open my $fh, '>', File::Spec->catfile($dir, 'skip.txt');
    print $fh "not css\n";
    close $fh;

    my $d = Litavis->new;
    $d->parse_dir($dir);
    is($d->_ast_rule_count, 3, 'parse_dir: 3 css files');
    # Sorted alphabetical order: a.css, b.css, c.css
    is($d->_ast_rule_selector(0), '.a', 'parse_dir: first is .a');
    is($d->_ast_rule_selector(1), '.b', 'parse_dir: second is .b');
    is($d->_ast_rule_selector(2), '.c', 'parse_dir: third is .c');
}

# ── Empty input ───────────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('');
    is($d->_ast_rule_count, 0, 'empty input: no rules');
}

# ── Whitespace only ──────────────────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('   \n\t  \n  ');
    is($d->_ast_rule_count, 0, 'whitespace only: no rules');
}

# ── Complex selector combinators ──────────────────────────────

{
    my $d = Litavis->new;
    $d->parse('
        .parent > .child { color: red; }
        .a + .b { color: blue; }
        .a ~ .b { color: green; }
    ');
    ok($d->_ast_has_rule('.parent > .child'), 'combinators: child >');
    ok($d->_ast_has_rule('.a + .b'), 'combinators: adjacent +');
    ok($d->_ast_has_rule('.a ~ .b'), 'combinators: sibling ~');
}

# ── Property without trailing semicolon before } ──────────────

{
    my $d = Litavis->new;
    $d->parse('.card { color: red }');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'no trailing semicolon: works');
}

# ── Multiple properties, last without semicolon ───────────────

{
    my $d = Litavis->new;
    $d->parse('.card { color: red; font-size: 16px }');
    is($d->_ast_get_prop('.card', 'color'), 'red', 'no trailing semi multi: color');
    is($d->_ast_get_prop('.card', 'font-size'), '16px', 'no trailing semi multi: font-size');
}

done_testing;
