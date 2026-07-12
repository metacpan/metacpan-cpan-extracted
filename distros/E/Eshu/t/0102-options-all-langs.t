use strict;
use warnings;
use Test::More tests => 19;
use Eshu;

# ── indent_char / indent_width for each language ──────────────────────────

# Perl — 2-space
{
    my $in  = "sub f {\nmy \$x = 1;\n}\n";
    my $exp = "sub f {\n  my \$x = 1;\n}\n";
    is(Eshu->indent_pl($in, indent_char => ' ', indent_width => 2),
        $exp, 'indent_pl: 2-space indent');
}

# Perl — 4-space
{
    my $in  = "sub f {\nmy \$x = 1;\n}\n";
    my $exp = "sub f {\n    my \$x = 1;\n}\n";
    is(Eshu->indent_pl($in, indent_char => ' ', indent_width => 4),
        $exp, 'indent_pl: 4-space indent');
}

# XS — 2-space
{
    my $in = "MODULE = T  PACKAGE = T\n\nvoid\nhello()\nCODE:\nprintf(\"hi\");\nOUTPUT:\nRETVAL\n";
    my $out = Eshu->indent_xs($in, indent_char => ' ', indent_width => 2);
    like($out, qr/^  CODE:/m,    'indent_xs: CODE label at 2 spaces');
    like($out, qr/^    printf/m, 'indent_xs: code body at 4 spaces');
}

# XS — indent_pp enabled
{
    my $xs_c = "int x;\n#ifdef FOO\nint y;\n#endif\n\nMODULE = T  PACKAGE = T\n";
    my $out = Eshu->indent_xs($xs_c, indent_pp => 1);
    is($out, $xs_c, 'indent_xs with indent_pp: C section preserved');
}

# XML — 2-space
{
    my $in  = "<root>\n<a>\n<b/>\n</a>\n</root>\n";
    my $exp = "<root>\n  <a>\n    <b/>\n  </a>\n</root>\n";
    is(Eshu->indent_xml($in, indent_char => ' ', indent_width => 2),
        $exp, 'indent_xml: 2-space indent');
}

# HTML — 4-space
{
    my $in  = "<html>\n<body>\n<p>hi</p>\n</body>\n</html>\n";
    my $exp = "<html>\n    <body>\n        <p>hi</p>\n    </body>\n</html>\n";
    is(Eshu->indent_html($in, indent_char => ' ', indent_width => 4),
        $exp, 'indent_html: 4-space indent');
}

# CSS — 2-space
{
    my $in  = ".a {\ncolor: red;\n}\n";
    my $exp = ".a {\n  color: red;\n}\n";
    is(Eshu->indent_css($in, indent_char => ' ', indent_width => 2),
        $exp, 'indent_css: 2-space indent');
}

# JS — 2-space
{
    my $in  = "function f() {\nreturn 1;\n}\n";
    my $exp = "function f() {\n  return 1;\n}\n";
    is(Eshu->indent_js($in, indent_char => ' ', indent_width => 2),
        $exp, 'indent_js: 2-space indent');
}

# POD — 2-space (verbatim blocks)
{
    my $in  = "=head1 NAME\n\nFoo\n\n    example();\n\n=cut\n";
    my $out = Eshu->indent_pod($in, indent_char => ' ', indent_width => 2);
    like($out, qr/^  example/m, 'indent_pod: 2-space verbatim indent');
}

# ── range_start / range_end for additional languages ─────────────────────

# XML range — targeted line gets correct depth indentation
{
    my $in = "<root>\n<a/>\n<b/>\n</root>\n";
    my $out = Eshu->indent_xml($in, range_start => 2, range_end => 2);
    my @lines = split /\n/, $out;
    is($lines[0], '<root>', 'XML range: line 1 outside range unchanged');
    is($lines[1], "\t<a/>", 'XML range: line 2 in range reindented at depth 1');
}

# CSS range — targeted line gets correct depth indentation
{
    my $in = ".x {\ncolor: red;\nmargin: 0;\n}\n";
    my $out = Eshu->indent_css($in, range_start => 2, range_end => 2);
    my @lines = split /\n/, $out;
    is($lines[0], '.x {',          'CSS range: line 1 outside range unchanged');
    is($lines[1], "\tcolor: red;", 'CSS range: line 2 in range reindented at depth 1');
}

# JS range
{
    my $in = "function f() {\nreturn 1;\nreturn 2;\n}\n";
    my $out = Eshu->indent_js($in, range_start => 2, range_end => 2);
    my @lines = split /\n/, $out;
    is($lines[0], 'function f() {', 'JS range: line 1 unchanged');
    is($lines[1], "\treturn 1;",    'JS range: line 2 reindented');
    is($lines[2], 'return 2;',      'JS range: line 3 unchanged');
}

# POD range
{
    my $in = "=head1 NAME\n\nFoo\n\n    example();\n\n=cut\n";
    my $out = Eshu->indent_pod($in, range_start => 5, range_end => 5);
    like($out, qr/^\texample/m, 'POD range: verbatim line in range reindented');
}

# ── indent_string inherits options ───────────────────────────────────────

{
    my $in  = "sub f {\nmy \$x;\n}\n";
    my $exp = "sub f {\n    my \$x;\n}\n";
    is(Eshu->indent_string($in, lang => 'perl', indent_char => ' ', indent_width => 4),
        $exp, 'indent_string passes indent options through to engine');
}
