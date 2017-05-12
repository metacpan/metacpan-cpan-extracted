# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-TreeBuilder-XPath.t'

#########################

use Test::More tests => 29;
BEGIN { use_ok('HTML::TreeBuilder::XPath') };

#########################

my $doc='<html>
           <head><title>Example</title></head>
           <body><h1>Example header</h1>
             <div class="intro"><p>Intro p1</p><p>Intro p2</p><p>Intro p3 with <b>bold</b> text</p></div>
             <p id="toto">para including <a href="http://foo.com/">links</a>, <a href="/bar/">more links</a>,
             and even <span id="foo" class="myspan">spans</span>, <span class="myspan" id="bar">several</span>,
             and that is <b>all</b> folks.</p>
             <!-- a commented line break --><br>
             <blockquote id="bq" bgcolor="0">0</blockquote>
           </body>
         </html>
        ';

my $html= HTML::TreeBuilder::XPath->new_from_content( $doc);


is( $html->findvalue( '//p[@id]/@id'), 'toto', 'attribute value');
is( $html->findvalue( '//title'), 'Example', 'element text');
is( $html->findvalue( '//span[1]'), 'spans', '[1]');
is( $html->findvalue( '/html/body//p[@id="toto"]/*[@id="bar"]/@class'), 'myspan', 'attribute');
is( $html->findvalue( '//p[@id="toto"]/text()[2]'), ', ', 'text node');

# test sorting
is( $html->findvalue( '//*[@id="foo"]/@*'), 'myspanfoo', '2 atts on same element');
is( $html->findvalue( '//*[@id="foo"]/@id|//*[@id="foo"]/@class'), 'myspanfoo', '2 atts on same element');
is( $html->findvalue( '//*[@id="foo"]/@class|//*[@id="foo"]/@id'), 'myspanfoo', '2 atts on same element (unsorted)');

is( $html->findvalue( '//b'), 'boldall', '2 texts');
is( join( '|', $html->findvalues( '//b')), 'bold|all', '2 texts with findvalues');
is( join( '|', $html->findnodes_as_strings( '//b')), 'bold|all', '2 texts with findnodes_as_strings');
is( join( '|', $html->findvalues( '//a/@href')), 'http://foo.com/|/bar/', '2 texts with findvalues');
is( join( '|', $html->findnodes_as_strings( '//a/@href')), 'http://foo.com/|/bar/', '2 texts with findnodes_as_strings');
is( $html->findvalue( '//p[@id="toto"]/a'), 'linksmore links', '2 siblings');
is( $html->findvalue( '//p[@id="toto"]/a[1]|//p[@id="toto"]/a[2]'), 'linksmore links', '2 siblings');

is( $html->findvalue( '//@id[.="toto"]|//*[@id="bar"]|/html/body/h1|//@id[.="toto"]/../a[1]|//*[@id="foo"]'), 'Example headertotolinksspansseveral', 
                      'query on various types of nodes');


is( $html->findvalue( './/*[@bgcolor="0"]'),'0', 'one child has a value of "0"'); 

{
my $p= $html->findnodes( '//p[@id="toto"]')->[0];
is( $p->findvalue( './a'), 'linksmore links', 'query on siblings of an element');
is( $p->findvalue( './a[1]|./a[2]'), 'linksmore links', 'query on siblings of an element (ordered)');
is( $p->findvalue( './a[2]|./a[1]'), 'linksmore links', 'query on siblings of an element (not ordered)');

is( $html->findvalue('id("foo")'), 'spans', 'id function');
is( $html->findvalue('id("foo")/@id'), 'foo', 'id function (attribute)');
}


{
# test for root
my ($fake_root)=$html->findnodes('/');
ok( !$fake_root->getParentNode => "fake root does not have a parent");
is( $fake_root->getRootNode, $fake_root, "fake root is its own root");
ok( !@{$fake_root->getAttributes} => "fake root has no attributes");
ok( !defined($fake_root->getName) => "fake root does not have a name");
ok( !defined($fake_root->getNextSibling) => "fake root does not have a next sibling");
ok( !defined($fake_root->getPreviousSibling) => "fake root does not have a prev sibling");

}

__END__
/html/body/h1            1 Example header
//@id[.="toto"]          2 toto
//@id[.="toto"]/../a[1]  3 links
//*[@id="foo"]           4 spans
//*[@id="bar"]           5 several
