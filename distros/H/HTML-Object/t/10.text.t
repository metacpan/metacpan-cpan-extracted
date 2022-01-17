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
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
    use_ok( 'HTML::Object::DOM::Text' ) || BAIL_OUT( 'Unable to load HTML::Object::DOM::Text' );
};

can_ok( 'HTML::Object::DOM::Text', 'assignedSlot' );
can_ok( 'HTML::Object::DOM::Text', 'getAttributes' );
can_ok( 'HTML::Object::DOM::Text', 'getChildNodes' );
can_ok( 'HTML::Object::DOM::Text', 'getElementById' );
can_ok( 'HTML::Object::DOM::Text', 'getFirstChild' );
can_ok( 'HTML::Object::DOM::Text', 'getLastChild' );
can_ok( 'HTML::Object::DOM::Text', 'getParentNode' );
can_ok( 'HTML::Object::DOM::Text', 'getRootNode' );
can_ok( 'HTML::Object::DOM::Text', 'getValue' );
can_ok( 'HTML::Object::DOM::Text', 'is_inside' );
can_ok( 'HTML::Object::DOM::Text', 'isEqualNode' );
can_ok( 'HTML::Object::DOM::Text', 'isAttributeNode' );
can_ok( 'HTML::Object::DOM::Text', 'isCommentNode' );
can_ok( 'HTML::Object::DOM::Text', 'isElementNode' );
can_ok( 'HTML::Object::DOM::Text', 'isNamespaceNode' );
can_ok( 'HTML::Object::DOM::Text', 'isPINode' );
can_ok( 'HTML::Object::DOM::Text', 'isProcessingInstructionNode' );
can_ok( 'HTML::Object::DOM::Text', 'isTextNode' );
can_ok( 'HTML::Object::DOM::Text', 'nodeValue' );
can_ok( 'HTML::Object::DOM::Text', 'parent' );
can_ok( 'HTML::Object::DOM::Text', 'replaceWholeText' );
can_ok( 'HTML::Object::DOM::Text', 'splitText' );
can_ok( 'HTML::Object::DOM::Text', 'string_value' );
can_ok( 'HTML::Object::DOM::Text', 'toString' );
can_ok( 'HTML::Object::DOM::Text', 'wholeText' );

my $html = <<EOT;
<p>foobar</p>
EOT
my $p = HTML::Object::DOM->new;
my $doc = $p->parse_data( $html ) || BAIl_OUT( $p->error );
my $p = $doc->getElementsByTagName('p')->first;
# Get contents of <p> as a text node
my $foobar = $p->firstChild;
isa_ok( $foobar, 'HTML::Object::DOM::Text' );
# $foobar->debug( $DEBUG );
# Split 'foobar' into two text nodes, 'foo' and 'bar',
# and save 'bar' as a const
my $bar = $foobar->splitText(3);
isa_ok( $bar => 'HTML::Object::DOM::Text' );
is( $bar->value, 'bar', 'new Text node' );

# Create a <u> element containing ' new content '
my $u = $doc->createElement('u');
$u->appendChild( $doc->createTextNode( ' new content ' ) );
# Add <u> before 'bar'
# $p->debug( $DEBUG );
$p->insertBefore( $u, $bar ) || do
{
    diag( "Error: ", $p->error ) if( $DEBUG );
};
# The result is: <p>foo<u> new content </u>bar</p>
is( $p->as_string, q{<p>foo<u> new content </u>bar</p>}, 'splitText' );

$html = <<EOT;
<p id="favy">I like apple,<span class="and"> and</span> orange,<span class="and"> and</span> kaki</p>
EOT
chomp( $html );
$p = HTML::Object::DOM->new;
$doc = $p->parse_data( $html ) || BAIl_OUT( $p->error );
$doc->getElementsByTagName('span')->foreach(sub
{
    $_->remove;
});
# diag( "HTML is now: '", $doc->as_string, "' with ", $doc->getElementById( 'favy' )->getChildNodes->length, " nodes." ) if( $DEBUG );
my $elem = $doc->getElementById('favy')->getChildNodes->[1];
# $elem->debug( $DEBUG ) if( $DEBUG );
# $elem->parent->debug( $DEBUG ) if( $DEBUG );
# Now text is: I like apple, orange, kaki
# which are 3 text nodes
# Take the 2nd one (for example) and set a new text for it and its adjacent siblings
$elem->replaceWholeText( 'I like fruits' ) || do
{
    diag( "Error with replaceWholeText: ", $elem->error ) if( $DEBUG );
};
# diag( "Result for element parent '", $elem->parent, "' with tag '", $elem->parent->tag, ": ", $elem->parent->as_string ) if( $DEBUG );
# Now the whole chunk has become:
# <p id="favy">I like fruits</p>
is( $doc->as_string, q{<p id="favy">I like fruits</p>}, 'replaceWholeText' );


$html = <<EOT;
<p id="favy">I like <span class="maybe-not">Shochu</span>, Dorayaki and Natto-gohan.</p>
EOT
$p = HTML::Object::DOM->new;
$doc = $p->parse_data( $html ) || BAIl_OUT( $p->error );
# my $spans = $doc->getElementsByTagName('span');
# diag( "Found ", $spans->length, " span elements." ) if( $DEBUG );
$doc->getElementsByTagName('span')->[0]->remove;
# Now paragraph contains 2 text nodes:
# 'I like '
# ', Dorayaki and Natto-gohan.'
my $text = $doc->getElementById('favy')->getFirstChild->wholeText;
# my $elem = $doc->getElementById('favy')->getFirstChild;
# $elem->debug( $DEBUG );
# my $text = $elem->wholeText;
# I like , Dorayaki and Natto-gohan.
is( $text, 'I like , Dorayaki and Natto-gohan.', 'wholeText' );

done_testing();

__END__

