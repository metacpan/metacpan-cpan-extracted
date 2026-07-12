use strict;
use warnings;
use Test::More tests => 23;
use Eshu;

my $c_src   = "void f() {\nint x;\n}\n";
my $c_fixed = "void f() {\n\tint x;\n}\n";
my $pl_src  = "sub f {\nmy \$x;\n}\n";
my $pl_fixed = "sub f {\n\tmy \$x;\n}\n";
my $xml_src  = "<root>\n<child/>\n</root>\n";
my $xml_fixed = "<root>\n\t<child/>\n</root>\n";
my $css_src  = ".a {\ncolor: red;\n}\n";
my $css_fixed = ".a {\n\tcolor: red;\n}\n";
my $js_src   = "function f() {\nreturn 1;\n}\n";
my $js_fixed = "function f() {\n\treturn 1;\n}\n";

# 1. lang => 'c' (explicit)
is(Eshu->indent_string($c_src, lang => 'c'), $c_fixed, 'lang=c');

# 2. lang => 'perl'
is(Eshu->indent_string($pl_src, lang => 'perl'), $pl_fixed, 'lang=perl');

# 3. lang => 'pl' alias
is(Eshu->indent_string($pl_src, lang => 'pl'), $pl_fixed, 'lang=pl alias');

# 4. lang => 'xs'
{
    my $xs = "MODULE = T  PACKAGE = T\n\nvoid\nhello()\nCODE:\nprintf(\"hi\");\n";
    my $out = Eshu->indent_string($xs, lang => 'xs');
    like($out, qr/\tCODE:/, 'lang=xs indents CODE label');
}

# 5-6. lang => 'xml' and 'svg' alias (both map to XML mode)
is(Eshu->indent_string($xml_src, lang => 'xml'), $xml_fixed, 'lang=xml');
is(Eshu->indent_string($xml_src, lang => 'svg'), $xml_fixed, 'lang=svg -> xml mode');

# 7-8. lang => 'html' and 'htm' alias
is(Eshu->indent_string($xml_src, lang => 'html'), $xml_fixed, 'lang=html');
is(Eshu->indent_string($xml_src, lang => 'htm'),  $xml_fixed, 'lang=htm alias');

# 9-11. lang => 'css', 'scss', 'less'
is(Eshu->indent_string($css_src, lang => 'css'),  $css_fixed, 'lang=css');
is(Eshu->indent_string($css_src, lang => 'scss'), $css_fixed, 'lang=scss alias');
is(Eshu->indent_string($css_src, lang => 'less'), $css_fixed, 'lang=less alias');

# 12-20. lang => 'js' and all JS/TS aliases
is(Eshu->indent_string($js_src, lang => 'js'),         $js_fixed, 'lang=js');
is(Eshu->indent_string($js_src, lang => 'javascript'), $js_fixed, 'lang=javascript alias');
is(Eshu->indent_string($js_src, lang => 'jsx'),        $js_fixed, 'lang=jsx alias');
is(Eshu->indent_string($js_src, lang => 'ts'),         $js_fixed, 'lang=ts alias');
is(Eshu->indent_string($js_src, lang => 'typescript'), $js_fixed, 'lang=typescript alias');
is(Eshu->indent_string($js_src, lang => 'tsx'),        $js_fixed, 'lang=tsx alias');
is(Eshu->indent_string($js_src, lang => 'mjs'),        $js_fixed, 'lang=mjs alias');
is(Eshu->indent_string($js_src, lang => 'cjs'),        $js_fixed, 'lang=cjs alias');
is(Eshu->indent_string($js_src, lang => 'mts'),        $js_fixed, 'lang=mts alias');

# 21. lang => 'pod'
{
    my $pod = "=head1 NAME\n\nFoo\n\n    example code\n\n=cut\n";
    my $out = Eshu->indent_string($pod, lang => 'pod');
    like($out, qr/^=head1 NAME/m, 'lang=pod preserves directive at col 0');
}

# 22-23. Unknown lang — should croak with a useful message
eval { Eshu->indent_string($c_src, lang => 'brainfuck') };
like($@, qr/unsupported language/i, 'unknown lang croaks');
like($@, qr/brainfuck/,             'croak message names the bad lang');
