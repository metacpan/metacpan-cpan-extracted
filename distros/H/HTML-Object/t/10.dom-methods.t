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
    use_ok( 'HTML::Object::DOM::Element' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Element" );
    use_ok( 'HTML::Object::DOM::Attribute' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Attribute" );
    use_ok( 'HTML::Object::DOM::Root' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Root" );
    use_ok( 'HTML::Object::DOM::Text' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Text" );
};

use strict;
use warnings;

subtest 'element methods' => sub
{
    can_ok( 'HTML::Object::DOM::Element', 'as_xml' );
    can_ok( 'HTML::Object::DOM::Element', 'cmp' );
    can_ok( 'HTML::Object::DOM::Element', 'string_value' );
    can_ok( 'HTML::Object::DOM::Element', 'getAttributes' );
    can_ok( 'HTML::Object::DOM::Element', 'getChildNodes' );
    can_ok( 'HTML::Object::DOM::Element', 'getElementById' );
    can_ok( 'HTML::Object::DOM::Element', 'getFirstChild' );
    can_ok( 'HTML::Object::DOM::Element', 'getLastChild' );
    can_ok( 'HTML::Object::DOM::Element', 'getLocalName' );
    can_ok( 'HTML::Object::DOM::Element', 'getName' );
    can_ok( 'HTML::Object::DOM::Element', 'getNextSibling' );
    can_ok( 'HTML::Object::DOM::Element', 'getParentNode' );
    can_ok( 'HTML::Object::DOM::Element', 'getPreviousSibling' );
    can_ok( 'HTML::Object::DOM::Element', 'getRootNode' );
    can_ok( 'HTML::Object::DOM::Element', 'getValue' );
    can_ok( 'HTML::Object::DOM::Element', 'is_inside' );
    can_ok( 'HTML::Object::DOM::Element', 'isAttributeNode' );
    can_ok( 'HTML::Object::DOM::Element', 'isElementNode' );
    can_ok( 'HTML::Object::DOM::Element', 'isNamespaceNode' );
    can_ok( 'HTML::Object::DOM::Element', 'isTextNode' );
    can_ok( 'HTML::Object::DOM::Element', 'isProcessingInstructionNode' );
    can_ok( 'HTML::Object::DOM::Element', 'isPINode' );
    can_ok( 'HTML::Object::DOM::Element', 'isCommentNode' );
    can_ok( 'HTML::Object::DOM::Element', 'lineage' );
    can_ok( 'HTML::Object::DOM::Element', 'string_value' );
    can_ok( 'HTML::Object::DOM::Element', 'to_number' );
    can_ok( 'HTML::Object::DOM::Element', 'toString' );

};

subtest 'attribute methods' => sub
{
    can_ok( 'HTML::Object::DOM::Attribute', 'name' );
    can_ok( 'HTML::Object::DOM::Attribute', 'value' );
    can_ok( 'HTML::Object::DOM::Attribute', 'string_value' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getChildNodes' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getElementById' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getName' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getParentNode' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getRootNode' );
    can_ok( 'HTML::Object::DOM::Attribute', 'getValue' );
    can_ok( 'HTML::Object::DOM::Attribute', 'isAttributeNode' );
};

subtest 'text methods' => sub
{
    can_ok( 'HTML::Object::DOM::Text', 'getAttributes' );
    can_ok( 'HTML::Object::DOM::Text', 'getElementById' );
    can_ok( 'HTML::Object::DOM::Text', 'getParentNode' );
    can_ok( 'HTML::Object::DOM::Text', 'getPreviousSibling' );
    can_ok( 'HTML::Object::DOM::Text', 'getValue' );
    can_ok( 'HTML::Object::DOM::Text', 'isTextNode' );
    can_ok( 'HTML::Object::DOM::Text', 'getNextSibling' );
    can_ok( 'HTML::Object::DOM::Text', 'getRootNode' );
    can_ok( 'HTML::Object::DOM::Text', 'string_value' );
    can_ok( 'HTML::Object::DOM::Text', 'toString' );
    can_ok( 'HTML::Object::DOM::Text', 'lineage' );
    can_ok( 'HTML::Object::DOM::Text', 'is_inside' );
};

subtest 'root methods' => sub
{
    can_ok( 'HTML::Object::DOM::Root', 'getParentNode' );
    can_ok( 'HTML::Object::DOM::Root', 'getChildNodes' );
    can_ok( 'HTML::Object::DOM::Root', 'getAttributes' );
    
    can_ok( 'HTML::Object::DOM::Root', 'isDocumentNode' );
    can_ok( 'HTML::Object::DOM::Root', 'getRootNode' );
    can_ok( 'HTML::Object::DOM::Root', 'getName' );
    
    can_ok( 'HTML::Object::DOM::Root', 'getNextSibling' );
    can_ok( 'HTML::Object::DOM::Root', 'getPreviousSibling' );
    
    can_ok( 'HTML::Object::DOM::Root', 'cmp' );
    can_ok( 'HTML::Object::DOM::Root', 'lineage' );
    can_ok( 'HTML::Object::DOM::Root', 'is_inside' );
};

done_testing();

__END__

