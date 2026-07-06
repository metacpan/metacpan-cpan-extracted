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

my $parser = HTML::Object::DOM->new(
    onload => sub{
        diag( "Document '", overload::StrVal( $_ ), "' has been loaded." ) if( $DEBUG );
    },
);
isa_ok( $parser, 'HTML::Object::DOM' );
my $doc = $parser->parse( $test );
isa_ok( $doc, 'HTML::Object::DOM::Document' );

my $body = $doc->body;
my $head = $doc->head;
my $div  = $doc->getElementById( 'hello' );
isa_ok( $div => 'HTML::Object::DOM::Element', 'getElementById' );

SKIP:
{
    if( !defined( $div ) )
    {
        skip( "unable to find the div with id 'hello'", 4 );
    }
    ok( $body->contains( $div ), 'contains' );
    my $sig  = $doc->getElementById( 'signature' );
    ok( $body->contains( $sig ), 'contains deep' );

    my $results = $doc->find( 'script' );
    isa_ok( $results => 'Module::Generic::Array' );
    is( $results->length, 2, '2 script elements found' );
    my $h1 = $doc->find( 'h1' )->first;
    my $span = $doc->getElementById( 'title' );
    is( $h1->firstChild, $span, 'firstChild' );
    is( $div->getRootNode, $doc, 'getRootNode' );
    ok( $h1->hasChildNodes, 'hasChildNodes' );
    my $div3 = $doc->createElement( 'div' );
    ok( $h1->parentNode->insertBefore( $div3, $h1 ), 'insertBefore' );
    ok( !$div3->isAttributeNode, 'isAttributeNode' );
    ok( !$div3->isCommentNode, 'isCommentNode' );
    ok( $div3->isConnected, 'isConnected' );
    my $script = $results->first;
    my $clone_script = $script->clone;
    ok( $script->isEqualNode( $clone_script ), 'isEqualNode' );
    ok( $div->isElementNode, 'isElementNode' );
    ok( !$div->isNamespaceNode, 'isNamespaceNode' );
    ok( !$div->isPINode, 'isPINode' );
    ok( !$div->isProcessingInstructionNode, 'isProcessingInstructionNode' );
    ok( $div->isSameNode( $div ), 'isSameNode' );
    ok( !$div->isSameNode( $div3 ), '! isSameNode' );
    ok( !$div->isTextNode, 'isTextNode' );
    is( $h1->lastChild, $span, 'lastChild' );
    is( $div->lookupNamespaceURI, '', 'lookupNamespaceURI' );
    is( $div->lookupPrefix, undef, 'lookupPrefix' );
    isa_ok( $h1->nextSibling, 'HTML::Object::DOM::Space', 'nextSibling' );
    is( $h1->nextSibling->nextSibling, $div, 'nextSibling' );
    is( $div->nodeName, 'div', 'nodeName' );

    # NOTE: Parse a separate document to test nodeName across all node types
    my $nodeNameTest = <<EOT;
<!DOCTYPE html>
<html lang="en-GB">
    <head>
        <meta charset="utf-8" />
        <title>Demo nodeName</title>
    </head>
    <body>
        This is some html:
        <div id="d1">Hello world</div>
        <!-- Example of comment -->
        Text <span>Text</span>
        Text<br/>
        <svg height="20" width="20">
            <circle cx="10" cy="10" r="5" stroke="black" stroke-width="1" fill="red" />
        </svg>
        <hr />
        <output id="result">Not calculated yet.</output>
    </body>
</html>
EOT
    my $parser3 = HTML::Object::DOM->new;
    my $doc3 = $parser3->parse_data( $nodeNameTest ) || BAIL_OUT( "Unable to parse HTML data: " . $parser3->error );
    my $node = $doc3->getElementsByTagName( 'body')->first->firstChild;
    my $result = "Node names are:\n";
    while( $node )
    {
        $result .= $node->nodeName . "\n";
        $node = $node->nextSibling;
    }
    my $nodeNameExpected = <<EOT;
Node names are:
#text
div
#space
#comment
#text
span
#text
br
#space
svg
#space
hr
#space
output
#space
EOT
    is( $result, $nodeNameExpected, 'nodeName (with a tree)' );
    is( $div->nodeType, ELEMENT_NODE, 'nodeType -> ELEMENT_NODE' );
    my $idAttr = $div->getAttributeNode( 'id' );
    isa_ok( $idAttr => 'HTML::Object::DOM::Attribute' );
    if( defined( $idAttr ) )
    {
        is( $idAttr->nodeType, ATTRIBUTE_NODE, 'nodeType -> ATTRIBUTE_NODE' );
    }
    else
    {
        fail( 'nodeType -> ATTRIBUTE_NODE. $idAttr is not defined.' );
    }
    is( $doc->getElementById( 'title' )->firstChild->nodeType, TEXT_NODE, 'nodeType -> TEXT_NODE' );
    my $comment = $doc->getElementsByTagName( 'footer' )->first->previousSibling->previousSibling;
    is( $comment->nodeType, COMMENT_NODE, 'nodeType -> COMMENT_NODE' );
    is( $doc->nodeType, DOCUMENT_NODE, 'nodeType -> DOCUMENT_NODE' );
    is( $doc->doctype->nodeType, DOCUMENT_TYPE_NODE, 'nodeType -> DOCUMENT_TYPE_NODE' );
    my $frag = $doc->createDocumentFragment();
    is( $frag->nodeType, DOCUMENT_FRAGMENT_NODE, 'nodeType -> DOCUMENT_FRAGMENT_NODE' );
    is( $doc->nodeValue, undef, 'document->nodeValue' );
    is( $doc->doctype->nodeValue, undef, 'doctype->nodeValue' );
    is( $frag->nodeValue, undef, 'documentFragment->nodeValue' );
    is( $div->nodeValue, undef, 'element->nodeValue' );
    is( $span->firstChild->nodeValue, 'Demo', 'text->nodeValue' );
    is( $idAttr->nodeValue, 'hello', 'attribute->nodeValue' );
    is( $comment->nodeValue, ' section footer here ', 'comment->nodeValue' );

    # normalize
    my $para = $doc->createElement( 'p' );
    $para->children->push(
        $para->new_text( value => 'Bonjour ' ),
        $para->new_text( value => 'tout le monde !' ),
        $para->new_space( value => "\n" ),
        $para->new_text( value => 'Au revoir.' ),
    );
    is( $para->children->length, 4, 'createElement -> p' );
    is( $para->as_text, "Bonjour tout le monde !\nAu revoir.", 'paragraph before normalization' );
    $para->normalize;
    is( $para->children->length, 3, 'normalize' );
    is( $para->as_text, "Bonjour tout le monde !\nAu revoir.", 'paragraph after normalization' );
    is( $div->ownerDocument, $doc, 'ownerDocument' );
    is( $div->parent, $body, 'parent' );
    is( $div->parentNode, $body, 'parentNode' );
    is( $div->parentElement, $body, 'parentElement' );
    is( $para->parentElement, undef, '! parentElement' );
    is( $div->previousSibling->previousSibling, $h1, 'previousSibling' );
    is( $body->removeChild( $para ), undef, '! removeChild' );
    $para->setAttribute( id => 'aurevoir' );
    # $para has been cloned before being appended to the footer; we need to get the new object
    my $newPara = $sig->parentElement->append( $para )->first;
    my $footerExpectedBefore = <<EOT;
<footer>
            <p id="signature">Copyright (c) Example, Inc 2021</p>
        <p id="aurevoir">Bonjour tout le monde !
Au revoir.</p></footer>
EOT
    my $footerExpectedAfter = <<EOT;
<footer>
            <p id="signature">Copyright (c) Example, Inc 2021</p>
        </footer>
EOT
    chomp( $footerExpectedBefore );
    chomp( $footerExpectedAfter );
    my $footer = $sig->parentElement;
    is( $footer->as_string, $footerExpectedBefore, 'before removeChild' );
    $footer->removeChild( $newPara );
    is( $footer->as_string, $footerExpectedAfter, 'removeChild' );
    $newPara = $footer->append( $newPara )->first;
    my $h3 = $doc->createElement( 'h3' );
    $h3->append( 'Salut les amis !' );
    $footer->replaceChild( $h3, $newPara );
    my $replaceChildExpected = <<EOT;
<footer>
            <p id="signature">Copyright (c) Example, Inc 2021</p>
        <h3>Salut les amis !</h3></footer>
EOT
    chomp( $replaceChildExpected );
    is( $footer->as_string, $replaceChildExpected, 'replaceChild' );
    $comment->textContent = "No comment";
    is( $comment->as_string, q{<!--No comment-->}, 'comment->textContent' );
    my $title = $span->firstChild;
    $title->textContent = 'Node Demo';
    is( $title->as_string, 'Node Demo', 'text->textContent' );
    $span->textContent = 'Super Node Demo';
    is( $span->as_string, q{<span id="title">Super Node Demo</span>}, 'element->textContent' );
};

done_testing();

__END__
