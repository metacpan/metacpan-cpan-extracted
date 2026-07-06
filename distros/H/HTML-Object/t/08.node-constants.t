#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test::More;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::Node' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Node" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $test = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title>document demo</title>
        <base href="https://www.example.com/" />
        <link rel="stylesheet" type="text/css" href="/some/sheet.css" crossorigin="anonymous" />
        <link rel="stylesheet" type="text/css" href="/some/other.css" crossorigin="anonymous" />
        <script type="text/javascript" src="/public/jquery-3.3.1.min.js" integrity="sha384-tsQFqpEReu7ZLhBV2VZlAu7zcOV+rXbYlF2cqB8txI/8aZajjp4Bqd+V6D5IgvKT"></script>
        <script type="text/javascript" src="/public/jquery-ui-1.11.4.js" integrity="sha384-YwCdhNQ2IwiYajqT/nGCj0FiU5SR4oIkzYP3ffzNWtu39GKBddP0M0waDU7Zwco0"></script>
    </head>
    <body>
        <h1><span id="title">Demo</span></h1>
        <div id="hello">Hello world!</div>
        <img src="/some/where.png" alt="Image" />
        <a href="/some/where.html" target="_new">Click me</a>
        <!-- section footer here -->
        <footer>
            <p id="signature">Copyright (c) Example, Inc 2021</p>
        </footer>
    </body>
</html>
EOT

my $test2 = <<EOT;
<!DOCTYPE html>
<html lang="en">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>document demo2</title>
    </head>
    <body>
        <div id="hello">Hello world!</div>
    </body>
</html>
EOT

my $parser  = HTML::Object::DOM->new(
    onload => sub{
        diag( "Document '", overload::StrVal( $_ ), "' has been loaded." ) if( $DEBUG );
    },
);
isa_ok( $parser, 'HTML::Object::DOM' );
my $doc = $parser->parse( $test );
isa_ok( $doc, 'HTML::Object::DOM::Document' );

my $parser2 = HTML::Object::DOM->new;
isa_ok( $parser2, 'HTML::Object::DOM' );
my $doc2 = $parser2->parse( $test2 );

# constants
ok( defined( &DOCUMENT_POSITION_IDENTICAL ), 'constant DOCUMENT_POSITION_IDENTICAL' );
ok( defined( &DOCUMENT_POSITION_DISCONNECTED ), 'constant DOCUMENT_POSITION_DISCONNECTED' );
ok( defined( &DOCUMENT_POSITION_PRECEDING ), 'constant DOCUMENT_POSITION_PRECEDING' );
ok( defined( &DOCUMENT_POSITION_FOLLOWING ), 'constant DOCUMENT_POSITION_FOLLOWING' );
ok( defined( &DOCUMENT_POSITION_CONTAINS ), 'constant DOCUMENT_POSITION_CONTAINS' );
ok( defined( &DOCUMENT_POSITION_CONTAINED_BY ), 'constant DOCUMENT_POSITION_CONTAINED_BY' );
ok( defined( &DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC ), 'constant DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC' );
ok( defined( &ELEMENT_NODE ), 'constant ELEMENT_NODE' );
ok( defined( &ATTRIBUTE_NODE ), 'constant ATTRIBUTE_NODE' );
ok( defined( &TEXT_NODE ), 'constant TEXT_NODE' );
ok( defined( &CDATA_SECTION_NODE ), 'constant CDATA_SECTION_NODE' );
ok( defined( &PROCESSING_INSTRUCTION_NODE ), 'constant PROCESSING_INSTRUCTION_NODE' );
ok( defined( &COMMENT_NODE ), 'constant COMMENT_NODE' );
ok( defined( &DOCUMENT_NODE ), 'constant DOCUMENT_NODE' );
ok( defined( &DOCUMENT_TYPE_NODE ), 'constant DOCUMENT_TYPE_NODE' );
ok( defined( &DOCUMENT_FRAGMENT_NODE ), 'constant DOCUMENT_FRAGMENT_NODE' );

is( $doc->baseURI, 'https://www.example.com/', 'baseURI' );
my $body = $doc->body;
is( $body->getName, 'body', 'body' );
my $head = $doc->head;
is( $head->getName, 'head', 'head' );
my $kids = $body->childNodes;
is( $kids->length, 13, 'childNodes' );
my $div = $doc->getElementById( 'hello' );
isa_ok( $div => 'HTML::Object::DOM::Element', 'getElementById' );
SKIP:
{
    if( !defined( $div ) )
    {
        skip( "unable to find the div with id 'hello'", 1 );
    }
    my $clone = $div->cloneNode;
    is( $div->as_string, $clone->as_string, 'cloneNode' );
};

subtest 'compareDocumentPosition' => sub
{
    SKIP:
    {
        my $div2 = $doc2->getElementById( 'hello' );
        if( !defined( $div ) )
        {
            skip( "unable to find the div with id 'hello'", 8 );
        }
        if( !defined( $div2 ) )
        {
            skip( "unable to find the other div with id 'hello'", 8 );
        }
        my $bit;
        $bit = $div->compareDocumentPosition( $div );
        is( $bit, DOCUMENT_POSITION_IDENTICAL, 'compareDocumentPosition -> 0 (same node)' );
        $bit = $div->compareDocumentPosition( $div2 );
        is( $bit & DOCUMENT_POSITION_DISCONNECTED, DOCUMENT_POSITION_DISCONNECTED, 'compareDocumentPosition -> 1 (not same document)' );
        $bit = $body->compareDocumentPosition( $head );
        diag( "comparing body with head results in bit '$bit'" ) if( $DEBUG );
        is( $bit & DOCUMENT_POSITION_PRECEDING, DOCUMENT_POSITION_PRECEDING, 'compareDocumentPosition -> 2 (preceding)' );
        $bit = $head->compareDocumentPosition( $body );
        diag( "comparing head with body results in bit '$bit'" ) if( $DEBUG );
        is( $bit & DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_FOLLOWING, 'compareDocumentPosition -> 4 (following)' );

        # $body->debug( $DEBUG );
        # $div->debug( $DEBUG );
        my $id = $div->getAttributeNode( 'id' );
        isa_ok( $id => 'HTML::Object::DOM::Attribute', 'getAttribute(id)' );
        $bit = $div->compareDocumentPosition( $id );
        is( $bit & DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_FOLLOWING, 'attribute following its element' );

        $bit = $div->compareDocumentPosition( $body );
        is( $bit & (DOCUMENT_POSITION_CONTAINS | DOCUMENT_POSITION_PRECEDING), (DOCUMENT_POSITION_CONTAINS | DOCUMENT_POSITION_PRECEDING), 'compareDocumentPosition -> 10 (contains and precedes)' );
        $bit = $body->compareDocumentPosition( $div );
        is( $bit & (DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING), (DOCUMENT_POSITION_CONTAINED_BY | DOCUMENT_POSITION_FOLLOWING), 'compareDocumentPosition -> 20 (is contained and follows)' );
    };

    SKIP:
    {
        my $rels = $doc->getElementsByTagName( 'link' );
        is( $rels->length, 2, 'number of links' );
        my $link = $rels->first;
        isa_ok( $link => 'HTML::Object::DOM::Element', 'link found is an element' );
        # TODO Set the correct number of tests to skip
        if( !defined( $link ) )
        {
            skip( 'no link found', 1 );
        }
        my $rel = $link->getAttributeNode( 'rel' );
        my $type = $link->getAttributeNode( 'type' );
        my $bit = $rel->compareDocumentPosition( $type );
        is( $bit & DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC, DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC, 'compareDocumentPosition -> 32 (2 attributes of the same node)' );
    };

    SKIP:
    {
        if( !defined( $div ) )
        {
            skip( "unable to find the div with id 'hello'", 4 );
        }
        my $span = $doc->getElementById( 'title' );
        my $sig  = $doc->getElementById( 'signature' );
        isa_ok( $span => 'HTML::Object::DOM::Element' );
        isa_ok( $sig => 'HTML::Object::DOM::Element' );
        my $bit;
        # span is a child of a previous sibling -> DOCUMENT_POSITION_PRECEDING
        $bit = $div->compareDocumentPosition( $span );
        is( $bit & DOCUMENT_POSITION_PRECEDING, DOCUMENT_POSITION_PRECEDING, 'compareDocumentPosition -> 2 (child of previous sibling)' );
        # footer is a child of a following sibling -> DOCUMENT_POSITION_FOLLOWING
        $bit = $div->compareDocumentPosition( $sig );
        is( $bit & DOCUMENT_POSITION_FOLLOWING, DOCUMENT_POSITION_FOLLOWING, 'compareDocumentPosition -> 4 (child of following sibling)' );
    };
};

done_testing();

__END__
