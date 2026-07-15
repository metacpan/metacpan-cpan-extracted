use strict;
use warnings;
use Test::More;
use Eshu;

sub j { Eshu->indent_java($_[0], indent_char => ' ', indent_width => 4) }

# ── basic text block ──────────────────────────────────────────────

{
    my $src = 'class Foo {' . "\n" .
              'void go() {' . "\n" .
              'String s = """' . "\n" .
              '    hello' . "\n" .
              '    world' . "\n" .
              '    """;' . "\n" .
              'use(s);' . "\n" .
              '}' . "\n" .
              '}' . "\n";
    my $out = j($src);
    # Content inside text block should be preserved verbatim
    like($out, qr/String s = """/, 'text block opening preserved');
    like($out, qr/    hello/,       'text block content preserved');
    like($out, qr/    world/,       'text block content 2 preserved');
    # Code after text block should be indented correctly
    like($out, qr/^        use\(s\);$/m, 'code after text block at depth 2');
}

# ── text block in field initialiser ──────────────────────────────

{
    my $src = 'class Foo {' . "\n" .
              'static final String SQL = """' . "\n" .
              '    SELECT *' . "\n" .
              '    FROM users' . "\n" .
              '    WHERE id = ?;' . "\n" .
              '    """;' . "\n" .
              'void run() {' . "\n" .
              'exec(SQL);' . "\n" .
              '}' . "\n" .
              '}' . "\n";
    my $out = j($src);
    like($out, qr/    SELECT \*/,     'SQL in text block preserved');
    like($out, qr/    FROM users/,    'SQL line 2 preserved');
    like($out, qr/^    void run/m,   'method after text block at depth 1');
    like($out, qr/^        exec/m,   'method body at depth 2');
}

# ── multiple text blocks ──────────────────────────────────────────

{
    my $src = 'class Foo {' . "\n" .
              'void go() {' . "\n" .
              'String a = """' . "\n" .
              '    first' . "\n" .
              '    """;' . "\n" .
              'String b = """' . "\n" .
              '    second' . "\n" .
              '    """;' . "\n" .
              'use(a, b);' . "\n" .
              '}' . "\n" .
              '}' . "\n";
    my $out = j($src);
    like($out, qr/    first/,             'first text block content');
    like($out, qr/    second/,            'second text block content');
    like($out, qr/^        use\(a, b\)/m, 'code after both text blocks');
}

# ── text block does not affect brace depth ────────────────────────

{
    my $src = 'class Foo {' . "\n" .
              'void go() {' . "\n" .
              'String j = """' . "\n" .
              '    {' . "\n" .
              '      "key": "value"' . "\n" .
              '    }' . "\n" .
              '    """;' . "\n" .
              'done();' . "\n" .
              '}' . "\n" .
              '}' . "\n";
    my $out = j($src);
    like($out, qr/^        done\(\);$/m, 'code after JSON text block correct depth');
}

done_testing;
