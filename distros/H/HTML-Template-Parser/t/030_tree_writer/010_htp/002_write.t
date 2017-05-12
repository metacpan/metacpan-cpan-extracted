use strict;
use warnings;
use Test::More tests => 17;

use HTML::Template::Parser;
use HTML::Template::Parser::TreeWriter::HTP;

write_test('<tmpl_var expr=foo>', '<TMPL_VAR EXPR="foo">');
write_test('plain text', 'plain text');
write_test("plain\ntext\nabc\t\b", "plain\ntext\nabc\t\b");

write_test('<tmpl_var name=foo>', q{<TMPL_VAR NAME="foo">});
write_test('<tmpl_var name=foo default="abc">', q{<TMPL_VAR NAME="foo" DEFAULT="abc">});
write_test('<tmpl_var name=foo escape=html>', q{<TMPL_VAR NAME="foo" ESCAPE=html>});
write_test('<tmpl_var name=foo escape=html default="def">', q{<TMPL_VAR NAME="foo" ESCAPE=html DEFAULT="def">});

write_test('<tmpl_var expr=foo>', q{<TMPL_VAR EXPR="foo">});

write_test('<tmpl_var expr=1>', q{<TMPL_VAR EXPR="1">});
write_test('<tmpl_var expr="1">', q{<TMPL_VAR EXPR="1">});
write_test('<tmpl_var expr="1+1">', q{<TMPL_VAR EXPR="(1+1)">});
write_test('<tmpl_var expr="1+2*3-4/5">', q{<TMPL_VAR EXPR="((1+(2*3))-(4/5))">});
write_test('<tmpl_var expr="1/2/3/4/5">', q{<TMPL_VAR EXPR="((((1/2)/3)/4)/5)">});


write_test('<tmpl_var expr=foo(bar)>', q{<TMPL_VAR EXPR="foo(bar)">});
write_test('<tmpl_var expr=" foo( bar, baz )">', q{<TMPL_VAR EXPR="foo(bar,baz)">});

write_test('<tmpl_var expr=foo(bar+1*2+3/baz(4*5-6/3))>', q{<TMPL_VAR EXPR="foo(((bar+(1*2))+(3/baz(((4*5)-(6/3))))))">});

write_test('<tmpl_var expr="foo(bar) =~ /abc/">', q{<TMPL_VAR EXPR="(foo(bar)=~/abc/)">});

sub write_test {
    my($template_string, $expected) = @_;

    my $parser = HTML::Template::Parser->new;
    my $writer = HTML::Template::Parser::TreeWriter::HTP->new;
    my $tree = $parser->parse($template_string);
    my $output = $writer->write($tree);

    is($output, $expected, "template_string is [$template_string]");
}

