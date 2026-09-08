#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# Every rendering rule of Canonical XML section 2.3 that is not about
# namespaces, in text and in attribute values separately, and the
# document-level newline rules.

sub c14n { my ($xml, %o) = @_; file_xml_decode($xml)->c14n(mode => 'inclusive', %o) }

# text
is(c14n('<r>&amp;&lt;&gt;"\'</r>'),     q{<r>&amp;&lt;&gt;"'</r>},  'text: & < > escaped; " and \' not');
is(c14n("<r>a&#xD;b</r>"),              '<r>a&#xD;b</r>',            'text: a CR (only reachable by reference) renders as &#xD;');
is(c14n("<r>a\tb\nc</r>"),              "<r>a\tb\nc</r>",            'text: TAB and LF are literal');
is(c14n("<r>a\r\nb</r>"),               "<r>a\nb</r>",               'text: a literal CRLF was normalised to LF before rendering');
is(c14n('<r><![CDATA[<a>&b;]]&gt;]]></r>'), '<r>&lt;a&gt;&amp;b;]]&amp;gt;</r>', 'CDATA renders as escaped text, ]]&gt; included');
is(c14n("<r>\xE2\x82\xAC</r>"),          "<r>\xE2\x82\xAC</r>",       'text: non-ASCII is its UTF-8 octets, unescaped');

# attribute values
is(c14n(q{<r a="&amp;&lt;>&quot;'"/>}),  q{<r a="&amp;&lt;>&quot;'"></r>}, 'attribute: & < " escaped; > and \' not');
is(c14n(q{<r a="&#x9;&#xA;&#xD;"/>}),    '<r a="&#x9;&#xA;&#xD;"></r>',    'attribute: TAB LF CR (by reference) escaped as character references');
is(c14n(qq{<r a="x\ty\nz"/>}),           '<r a="x y z"></r>',               'attribute: literal TAB and LF became spaces at parse and render as spaces');
is(c14n(q{<r a='"'/>}),                  '<r a="&quot;"></r>',              'attribute: a single-quoted value is rendered double-quoted with " escaped');

# elements, comments, PIs
is(c14n('<r/>'),                 '<r></r>',                    'an empty element is a start and end tag');
is(c14n('<r><a/><b></b></r>'),   '<r><a></a><b></b></r>',      'in every position');
is(c14n('<r><!-- c --></r>'),    '<r></r>',                    'a comment is dropped by default');
is(c14n('<r><!-- c --></r>', comments => 1), '<r><!-- c --></r>', 'and kept when asked, body verbatim');
is(c14n('<r><!-- a&b<c --></r>', comments => 1), '<r><!-- a&b<c --></r>', 'a comment body is not escaped');
is(c14n('<r><?p data?></r>'),    '<r><?p data?></r>',          'a PI with data');
is(c14n('<r><?p?></r>'),         '<r><?p?></r>',               'a PI without data has no space');
is(c14n('<r><?p   spaced   ?></r>'), '<r><?p spaced   ?></r>', 'PI data begins after the whitespace run and keeps the rest');
is(c14n('<r><?p a&b<c?></r>'),   '<r><?p a&b<c?></r>',         'PI data is not escaped');
is(c14n(qq{<?xml version="1.0" encoding="UTF-8" standalone="yes"?><r/>}), '<r></r>', 'the XML declaration is never rendered');

# document level
is(c14n('<?a?><!-- c --><r/><!-- d --><?b?>'),
   "<?a?>\n<r></r>\n<?b?>",
   'top-level PIs: a newline after each before the root, before each after it; comments dropped');
is(c14n('<?a?><!-- c --><r/><!-- d --><?b?>', comments => 1),
   "<?a?>\n<!-- c -->\n<r></r>\n<!-- d -->\n<?b?>",
   'and with comments, the same rule for them');
is(c14n("\n\n<?a?>\n\n<r/>\n\n"), "<?a?>\n<r></r>", 'whitespace outside the root never appears');
is(c14n('<r/>'), '<r></r>', 'a document with nothing but a root has no newlines at all');

# an element apex renders no document-level newlines
{
    my $doc = file_xml_decode('<?a?><r><b/></r><?c?>');
    is($doc->root->c14n(mode => 'inclusive'), '<r><b></b></r>', 'the root as an element apex');
    my ($b) = $doc->root->elements;
    is($b->c14n(mode => 'inclusive'), '<b></b>', 'an inner element as the apex');
    my @kids = $doc->document->children;
    is($kids[0]->c14n(mode => 'inclusive'), '<?a?>', 'a PI as the apex');
}

done_testing;
