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
    use_ok( 'HTML::Object::DOM', qw( :all ) ) || BAIL_OUT( 'Unable to load HTML::Object::DOM' );
};

HTML::Object::DOM->import( ':all' );

my $constants = [
    DOCUMENT_POSITION_IDENTICAL     => 0,
    DOCUMENT_POSITION_DISCONNECTED  => 1,
    DOCUMENT_POSITION_PRECEDING     => 2,
    DOCUMENT_POSITION_FOLLOWING     => 4,
    DOCUMENT_POSITION_CONTAINS      => 8,
    DOCUMENT_POSITION_CONTAINED_BY  => 16,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC => 32,
    
    ELEMENT_NODE                    => 1,
    ATTRIBUTE_NODE                  => 2,
    TEXT_NODE                       => 3,
    CDATA_SECTION_NODE              => 4,
    PROCESSING_INSTRUCTION_NODE     => 7,
    COMMENT_NODE                    => 8,
    DOCUMENT_NODE                   => 9,
    DOCUMENT_TYPE_NODE              => 10,
    DOCUMENT_FRAGMENT_NODE          => 11,
    
    NETWORK_EMPTY       => 0,
    NETWORK_IDLE        => 1,
    NETWORK_LOADING     => 2,
    NETWORK_NO_SOURCE   => 3,
    
    NONE                => 0,
    LOADING             => 1,
    LOADED              => 2,
    ERROR               => 3,
    
    CAPTURING_PHASE     => 1,
    AT_TARGET           => 2,
    BUBBLING_PHASE      => 3,
    
    CANCEL_PROPAGATION  => 1,
    CANCEL_IMMEDIATE_PROPAGATION => 2,
    
    SHOW_ALL                    => 4294967295,
    SHOW_ELEMENT                => 1,
    SHOW_ATTRIBUTE              => 2,
    SHOW_TEXT                   => 4,
    SHOW_CDATA_SECTION          => 8,
    SHOW_ENTITY_REFERENCE 	    => 16,
    SHOW_ENTITY                 => 32,
    SHOW_PROCESSING_INSTRUCTION => 64,
    SHOW_COMMENT                => 128,
    SHOW_DOCUMENT               => 256,
    SHOW_DOCUMENT_TYPE          => 512,
    SHOW_DOCUMENT_FRAGMENT 	    => 1024,
    SHOW_NOTATION               => 2048,
    
    FILTER_ACCEPT               => 1,
    FILTER_REJECT               => 2,
    FILTER_SKIP                 => 3,
    
    ANY_TYPE                        => 0,
    NUMBER_TYPE                     => 1,
    STRING_TYPE                     => 2,
    BOOLEAN_TYPE                    => 3,
    UNORDERED_NODE_ITERATOR_TYPE    => 4,
    ORDERED_NODE_ITERATOR_TYPE      => 5,
    UNORDERED_NODE_SNAPSHOT_TYPE    => 6,
    ORDERED_NODE_SNAPSHOT_TYPE      => 7,
    ANY_UNORDERED_NODE_TYPE         => 8,
    FIRST_ORDERED_NODE_TYPE         => 9,
];

for( my $i = 0; $i < scalar( @$constants ); $i += 2 )
{
    my $const = $constants->[$i];
    my $value = $constants->[$i + 1];
    ok( defined( &$const ), "constant $const defined" );
    if( defined( &$const ) )
    {
        is( &$const, $value, "constant $const value" );
    }
    else
    {
        fail( "constant $const value" );
    }
    # ok( scalar( grep( /^$const$/, @HTML::Object::DOM::EXPORT_OK ) ), "$const exists in EXPORT_OK" );
    # is( $value, &{"HTML::Object::DOM:\:${const}"}, "matches HTML::Object::DOM::${const}" );
}

done_testing();

__END__

