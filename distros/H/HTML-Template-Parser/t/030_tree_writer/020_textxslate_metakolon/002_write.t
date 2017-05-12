use strict;
use warnings;
use Test::More tests => 30;

use HTML::Template::Parser;
use HTML::Template::Parser::TreeWriter::TextXslate::Metakolon;

write_test('<tmpl_var expr=foo>', '[% $foo | mark_raw %]');
write_test('plain text', 'plain text');
write_test("plain\ntext\nabc\t\b", "plain\ntext\nabc\t\b");

write_test('<tmpl_var name=foo>', q{[% $foo | mark_raw %]});
write_test('<tmpl_var name=foo default="abc">', q{[% $foo || "abc" | mark_raw %]});
write_test('<tmpl_var name=foo escape=html>', q{[% $foo %]});
write_test('<tmpl_var name=foo escape=html default="def">', q{[% $foo || "def" %]});

write_test('<tmpl_var expr=foo>', q{[% $foo | mark_raw %]});

write_test('<tmpl_var expr=1>', q{[% 1 | mark_raw %]});
write_test('<tmpl_var expr="1">', q{[% 1 | mark_raw %]});
write_test('<tmpl_var expr="1+1">', q{[% (1 + 1) | mark_raw %]});
write_test('<tmpl_var expr="1+2*3-4/5">', q{[% ((1 + (2 * 3)) - (4 / 5)) | mark_raw %]});
write_test('<tmpl_var expr="1/2/3/4/5">', q{[% ((((1 / 2) / 3) / 4) / 5) | mark_raw %]});


write_test('<tmpl_var expr=foo(bar)>', q{[% $foo($bar) | mark_raw %]});
write_test('<tmpl_var expr=" foo( bar, baz )">', q{[% $foo($bar,$baz) | mark_raw %]});

write_test('<tmpl_var expr=foo(bar+1*2+3/baz(4*5-6/3))>', q{[% $foo((($bar + (1 * 2)) + (3 / $baz(((4 * 5) - (6 / 3)))))) | mark_raw %]});

write_test('<tmpl_var expr="foo(bar) =~ /abc/">', q{[% ($foo($bar) =~ /abc/) | mark_raw %]});

write_test(<<'END;', <<'END;');
line 1.
<ul>
<TMPL_LOOP NAME="list">
<li><TMPL_VAR EXPR="html(name)">
</TMPL_LOOP>
</ul>
END;
line 1.
<ul>
[% for $list->$_item_1 { %]
<li>[% _choise_var('name', $name, $_item_1) %]
[% } %]
</ul>
END;

write_test(<<'END;', <<'END;');
line 1.
<TMPL_IF expr="1">
2
<TMPL_ELSIF expr=foo(bar)>
3
<TMPL_ELSE>
4
</TMPL_IF>
5
END;
line 1.
[% if(_has_value(1)){ %]
2
[% }elsif(_has_value($foo($bar))){ %]
3
[% }else{ %]
4
[% } %]
5
END;

write_test(q{<TMPL_IF EXPR="(not 1)">x</TMPL_IF>}, '[% if(_has_value((not 1))){ %]x[% } %]');
write_test(q{<TMPL_IF EXPR="(! 1)">x</TMPL_IF>}, '[% if(_has_value((!1))){ %]x[% } %]');

write_test(<<'END;', <<'END;');
<TMPL_LOOP NAME="loop_A">
<TMPL_VAR NAME=id>
<TMPL_LOOP NAME="loop_B">
<TMPL_VAR NAME=id>
<TMPL_LOOP NAME="loop_C">
<TMPL_VAR NAME=id>
<TMPL_LOOP NAME="loop_D">
<TMPL_VAR NAME=id>
</TMPL_LOOP>
</TMPL_LOOP>
</TMPL_LOOP>
</TMPL_LOOP>
END;
[% for $loop_A->$_item_1 { %]
[% _choise_var('id', $id, $_item_1) | mark_raw %]
[% for _choise_var('loop_B', $loop_B, $_item_1)->$_item_2 { %]
[% _choise_var('id', $id, $_item_2,$_item_1) | mark_raw %]
[% for _choise_var('loop_C', $loop_C, $_item_2,$_item_1)->$_item_3 { %]
[% _choise_var('id', $id, $_item_3,$_item_2,$_item_1) | mark_raw %]
[% for _choise_var('loop_D', $loop_D, $_item_3,$_item_2,$_item_1)->$_item_4 { %]
[% _choise_var('id', $id, $_item_4,$_item_3,$_item_2,$_item_1) | mark_raw %]
[% } %]
[% } %]
[% } %]
[% } %]
END;

write_test(<<'END;', <<'END;');
<TMPL_LOOP NAME="loop_A">
<TMPL_VAR NAME=__counter__>
<TMPL_LOOP NAME="loop_B">
<TMPL_VAR NAME=__counter__>
</TMPL_LOOP>
</TMPL_LOOP>
END;
[% for $loop_A->$_item_1 { %]
[% $~_item_1.count | mark_raw %]
[% for _choise_var('loop_B', $loop_B, $_item_1)->$_item_2 { %]
[% $~_item_2.count | mark_raw %]
[% } %]
[% } %]
END;

write_test(<<'END;',<<'END;');
<TMPL_IF EXPR=expr>x</TMPL_IF>
END;
[% if(_has_value($expr)){ %]x[% } %]
END;

write_test(<<'END;',<<'END;');
<TMPL_IF expr>x</TMPL_IF>
END;
[% if(_has_value($expr)){ %]x[% } %]
END;

write_test(<<'END;',<<'END;');
<TMPL_INCLUDE foo.tmpl>
END;
[% include 'foo.tmpl' %]
END;

write_test(<<'END;',<<'END;');
<TMPL_LOOP NAME=loop>
<TMPL_INCLUDE foo.tmpl>
</TMPL_LOOP>
END;
[% for $loop->$_item_1 { %]
[% include 'foo.tmpl' { $_item_1 } %]
[% } %]
END;

write_test(<<'END;',<<'END;');
<TMPL_LOOP NAME=loop_1>
<TMPL_INCLUDE foo.tmpl>
<TMPL_LOOP NAME=loop_2>
<TMPL_INCLUDE foo.tmpl>
</TMPL_LOOP>
<TMPL_INCLUDE foo.tmpl>
</TMPL_LOOP>
END;
[% for $loop_1->$_item_1 { %]
[% include 'foo.tmpl' { $_item_1 } %]
[% for _choise_var('loop_2', $loop_2, $_item_1)->$_item_2 { %]
[% include 'foo.tmpl' { $_item_2 } %]
[% } %]
[% include 'foo.tmpl' { $_item_1 } %]
[% } %]
END;

write_test(<<'END;',<<'END;');
<TMPL_VAR NAME=a ESCAPE=0>
<TMPL_VAR NAME=a ESCAPE='0'>
<TMPL_VAR NAME=a ESCAPE="0">
<TMPL_VAR NAME=a ESCAPE=html>
<TMPL_VAR NAME=a ESCAPE='html'>
<TMPL_VAR NAME=a ESCAPE="html">
END;
[% $a | mark_raw %]
[% $a | mark_raw %]
[% $a | mark_raw %]
[% $a %]
[% $a %]
[% $a %]
END;

write_test(<<'END;', <<'END;');
<TMPL_VAR NAME="foo">
<TMPL_VAR NAME="foo" ESCAPE="HTML">
<TMPL_VAR NAME="foo" ESCAPE="0">
<TMPL_VAR EXPR="foo">
<TMPL_VAR EXPR="foo" ESCAPE="HTML">
<TMPL_VAR EXPR="foo" ESCAPE="0">
<TMPL_VAR EXPR="html(foo)">
<TMPL_VAR EXPR="form(foo)">
<TMPL_VAR EXPR="html(bar(foo, 1, 2, 3))">
<TMPL_VAR EXPR="form(baz(foo, 'a'))">
END;
[% $foo | mark_raw %]
[% $foo %]
[% $foo | mark_raw %]
[% $foo | mark_raw %]
[% $foo %]
[% $foo | mark_raw %]
[% $foo %]
[% $foo %]
[% $bar($foo,1,2,3) %]
[% $baz($foo,'a') %]
END;

sub write_test {
    my($template_string, $expected) = @_;

    my $parser = HTML::Template::Parser->new;
    my $writer = HTML::Template::Parser::TreeWriter::TextXslate::Metakolon->new;
    my $tree = $parser->parse($template_string);
    my $output = $writer->write($tree);

    is($output, $expected, "template_string is [$template_string]");
}

