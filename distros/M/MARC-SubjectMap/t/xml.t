use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::SubjectMap::XML qw( element esc );

is( esc('&'), '&amp;', '&' );
is( esc('foo&bar'), 'foo&amp;bar', '&amp;' );
is( esc('foo&amp;bar'), 'foo&amp;bar', '&amp; in orignial' );
is( esc('foo&apos;bar'), 'foo&apos;bar', '&apos; in original' );
is( esc('foo&lt;bar'), 'foo&lt;bar', '&lt; in original' );
is( esc('foo&gt;bar'), 'foo&gt;bar', '&gt; in original' );
is( esc('><'), '&gt;&lt;', '><' );

is( element('tag','content'), '<tag>content</tag>', 'element()' );
is( element('tag','foo&bar'), '<tag>foo&amp;bar</tag>', 'element() w/ &' );
is( element('tag','content', foo=>'bar'), '<tag foo="bar">content</tag>', 
    'attribute' );
is( element('tag','cheeze', foo=>'bar',bez=>'bar' ),
    '<tag foo="bar" bez="bar">cheeze</tag>', 'multiple attribtues' );
