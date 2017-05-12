# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-TreeBuilder-XPath.t'

#########################

use Test::More tests => 31;
BEGIN { use_ok('HTML::TreeBuilder::XPath') };
use HTML::TreeBuilder::LibXML;
HTML::TreeBuilder::LibXML->replace_original;

#########################

my $doc='<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
        <html>
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
TODO: {
    local $TODO = "I don't know, this order is required for xpath spec, or not??";
    is( $html->findvalue( '//*[@id="foo"]/@*'), 'myspanfoo', '2 atts on same element');
    is( $html->findvalue( '//*[@id="foo"]/@id|//*[@id="foo"]/@class'), 'myspanfoo', '2 atts on same element');
    is( $html->findvalue( '//*[@id="foo"]/@class|//*[@id="foo"]/@id'), 'myspanfoo', '2 atts on same element (unsorted)');

    is( $html->findvalue( '//b'), 'boldall', '2 texts');
    is( $html->findvalue( '//p[@id="toto"]/a'), 'linksmore links', '2 siblings');
    is( $html->findvalue( '//p[@id="toto"]/a[1]|//p[@id="toto"]/a[2]'), 'linksmore links', '2 siblings');

    is( $html->findvalue( '//@id[.="toto"]|//*[@id="bar"]|/html/body/h1|//@id[.="toto"]/../a[1]|//*[@id="foo"]'), 'Example headertotolinksspansseveral',
                        'query on various types of nodes');
};

is( $html->findvalue( './/*[@bgcolor="0"]'),'0', 'one child has a value of "0"');

{
my $p= $html->findnodes( '//p[@id="toto"]')->[0];
is( $p->findvalue( './a'), 'linksmore links', 'query on siblings of an element');
is( $p->findvalue( './a[1]|./a[2]'), 'linksmore links', 'query on siblings of an element (ordered)');
is( $p->findvalue( './a[2]|./a[1]'), 'linksmore links', 'query on siblings of an element (not ordered)');

is( $html->findvalue('id("foo")'), 'spans', 'id function');
is( $html->findvalue('id("foo")/@id'), 'foo', 'id function (attribute)');
}

is( $html->exists( '//p[@id]/@id'  ) , 1 , 'does exist');
is( $html->exists( '//p[@id]/@id2' ) , 0 , 'does not exist' );

{
my @p = $html->find( 'p' );
is( scalar @p , 4 , '4 <p>');
is( $p[0]->getValue , 'Intro p1' , '<p>1');

my( $bq ) = $html->find( 'blockquote' );
is( $bq->getValue , 0 , 'bq' );
}

{
my @val = $html->findvalues('//span[@class="myspan"]');
is_deeply( \@val , [ qw/ spans several / ] , 'findvalues on multi element');

my( $val2 ) = $html->findvalues('//*[@id="bq"]');
is( $val2 , 0 , 'findvalues on unique element')
}

{
my @children = $html->findnodes( '//p[@id="toto"]')->[0]->childNodes;
is( scalar @children , 11 , 'child count');
is( $children[1]->getValue , 'links' , 'first child');
}

{
my @filter_nodes = $html->findnodes_filter( '//p' , sub { shift->getValue =~ /Intro / } );
is( scalar @filter_nodes , 3 , '3 <p>' );
}

{
my ($div ) = $html->findnodes( '//div[@class="intro"]' );
my $left = $div->left;
is( $left->tag , 'h1' );
my $right = $div->right;
is( $right->tag , 'p' );
}

__END__
/html/body/h1            1 Example header
//@id[.="toto"]          2 toto
//@id[.="toto"]/../a[1]  3 links
//*[@id="foo"]           4 spans
//*[@id="bar"]           5 several
