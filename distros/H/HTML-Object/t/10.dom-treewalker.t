#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM', qw( :node ) ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::TreeWalker' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::TreeWalker' );
    use_ok( 'HTML::Object::DOM::NodeFilter', ':all' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::NodeFilter' );
};

can_ok( 'HTML::Object::DOM::TreeWalker', 'currentNode' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'expandEntityReferences' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'filter' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'firstChild' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'lastChild' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'nextNode' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'nextSibling' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'parentNode' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'pos' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'previousNode' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'previousSibling' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'root' );
can_ok( 'HTML::Object::DOM::TreeWalker', 'whatToShow' );

ok( defined( &FILTER_ACCEPT ), 'constant FILTER_ACCEPT' );
ok( defined( &FILTER_REJECT ), 'constant FILTER_REJECT' );
ok( defined( &FILTER_SKIP ), 'constant FILTER_SKIP' );

ok( defined( &ELEMENT_NODE ), 'constant ELEMENT_NODE' );
ok( defined( &ATTRIBUTE_NODE ), 'constant ATTRIBUTE_NODE' );
ok( defined( &TEXT_NODE ), 'constant TEXT_NODE' );
ok( defined( &CDATA_SECTION_NODE ), 'constant CDATA_SECTION_NODE' );
ok( defined( &PROCESSING_INSTRUCTION_NODE ), 'constant PROCESSING_INSTRUCTION_NODE' );
ok( defined( &COMMENT_NODE ), 'constant COMMENT_NODE' );
ok( defined( &DOCUMENT_NODE ), 'constant DOCUMENT_NODE' );
ok( defined( &DOCUMENT_TYPE_NODE ), 'constant DOCUMENT_TYPE_NODE' );
ok( defined( &DOCUMENT_FRAGMENT_NODE ), 'constant DOCUMENT_FRAGMENT_NODE' );
ok( defined( &DOCUMENT_FRAGMENT_NODE ), 'constant NOTATION_NODE' );
ok( defined( &DOCUMENT_FRAGMENT_NODE ), 'constant SPACE_NODE' );

my $p = HTML::Object::DOM->new;
# my $p = HTML::Object::DOM->new( debug => $DEBUG );
my $doc = $p->parse_file( './t/test.html' ) || BAIL_OUT( $p->error );
isa_ok( $doc => 'HTML::Object::DOM::Document' );
ok( $doc->can( 'createTreeWalker' ), 'document->createTreeWalker' ) || BAIL_OUT( "Document object has no method createTreeWalker" );
my $elements = [
    body    => undef,
    div     => 'container',
    div     => 'plop pouec',
    div     => 'plop truc',
    div     => 'inner first',
    div     => 'inner second',
    div     => 'inner third',
    div     => 'coucou',
];
my $pos = 0;
my $it = $doc->createTreeWalker( $doc->body, SHOW_ELEMENT, sub
{
    my $tag = $_->nodeName;
    my $class = $_->getAttribute( 'class' );
    diag( "Processing element with tag '", $_->getName, "' with class '$class'." ) if( $DEBUG );
    $pos += 2;
    is( $elements->[ $pos ], $tag, "element at offset $pos is a $tag" );
    is( $elements->[ $pos + 1 ], $class, "element at offset $pos has class " . ( defined( $class ) ? $class : 'undef' ) );
    return( FILTER_ACCEPT );
}, debug => $DEBUG ) || BAIL_OUT( "Unable to instantiate a TreeWalker object: ", $doc->error );

is( $it->whatToShow, SHOW_ELEMENT, 'whatToShow' );
isa_ok( $it->root, 'HTML::Object::DOM::Element', 'root' );

diag( "Doing initial filtering." ) if( $DEBUG );
while( my $e = $it->nextNode )
{
    diag( "Checking element with tag '", $e->getName, "' and parent '", $e->parent->tagName, "'." ) if( $DEBUG );
    my $ref = $it->currentNode;
    is( $ref->eid, $e->eid, 'currentNode' );
}

# Start over, but we allow all elements and instead our callback will filter out
diag( "Doing callback side filtering, forward." ) if( $DEBUG );
$pos = 0;
$it = $doc->createTreeWalker( $doc->body, SHOW_ALL, sub
{
    diag( "Processing element with tag '", $_->tag, "' with type '", $_->nodeType, "' and with class '", ( $_->nodeType == ELEMENT_NODE ? $_->getAttribute( 'class' ) : '' ), "'." ) if( $DEBUG );
    return( $_->nodeType == ELEMENT_NODE ? FILTER_ACCEPT : FILTER_SKIP );
}, debug => $DEBUG ) || BAIL_OUT( "Unable to instantiate a TreeWalker object: ", $doc->error );
while( my $e = $it->nextNode )
{
    my $tag = $e->nodeName;
    my $class = $e->getAttribute( 'class' );
    $pos += 2;
    diag( "Checking element with tag '", $e->getName, "' and parent '", $e->parent->tagName, "'." ) if( $DEBUG );
    is( $elements->[ $pos ], $tag, "element at offset $pos is a $tag" );
    is( $elements->[ $pos + 1 ], $class, "element at offset $pos has class " . ( defined( $class ) ? $class : 'undef' ) );
}

# Now, going backward
diag( "Now, going backward." ) if( $DEBUG );
while( my $e = $it->previousNode )
{
    my $tag = $e->nodeName;
    my $class = $e->getAttribute( 'class' );
    $pos -= 2;
    diag( "Checking element with tag '", $e->getName, "' and parent '", $e->parent->tagName, "'." ) if( $DEBUG );
    is( $elements->[ $pos ], $tag, "element at offset $pos is a $tag" );
    is( $elements->[ $pos + 1 ], $class, "element at offset $pos has class " . ( defined( $class ) ? $class : 'undef' ) );
}
my $node = $it->currentNode;
$node = $e->nextNode while( $node->nodeType != ELEMENT_NODE );
isa_ok( $node, 'HTML::Object::DOM::Element' );
is( $node->nodeName, 'body', 'position at first element' );
$node = $it->nextSibling;
is( $node, undef, 'root element has no sibling' );
$node = $it->previousSibling;
is( $node, undef, 'root element has no sibling' );

# Test we get a space node when SHOW_ALL and an element when SHOW_ELEMENT
$it = $doc->createTreeWalker( $doc->body, SHOW_ALL );
$node = $it->firstChild;
is( $node->nodeName, '#space', 'SHOW_ALL -> first child is a space' );
$it = $doc->createTreeWalker( $doc->body, SHOW_ELEMENT );
$node = $it->firstChild;
is( $node->nodeName, 'div', 'SHOW_ELEMENT -> first child is a div' );

# Normally not possible to change whatToShow midway, but under our perl framework, we can
$it = $doc->createTreeWalker( $doc->body, SHOW_ALL );
$it->whatToShow = SHOW_ELEMENT;
$node = $it->firstChild;
is( $node->nodeName, 'div', 'change of value for whatToShow' );
$it = $doc->createTreeWalker( $doc->body, SHOW_ELEMENT );
$node = $it->lastChild;
is( $node->nodeName, 'div', 'lastChild' );
is( $node->getAttribute( 'id' ), 'testToggle', 'lastChild' );
$node = $it->parentNode;
is( $node->nodeName, 'body', 'parentNode' );

$it = $doc->createTreeWalker( $doc->body, SHOW_TEXT );
my $texts = [
'Jack',
'John',
'Hello',
'And',
'Goodbye',
'Bonjour tout le monde',
];
$pos = 0;
while( $node = $it->nextNode )
{
    is( $node->value, $texts->[ $pos ], "text at offset $pos" );
    $pos++;
}

$it = $doc->createTreeWalker( $doc->body, SHOW_COMMENT );
$node = $it->nextNode;
is( $node->nodeValue, ' Some comment here ', 'SHOW_COMMENT' );

done_testing();

__END__

