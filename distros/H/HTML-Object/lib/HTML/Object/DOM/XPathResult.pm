##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/XPathResult.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/01
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::XPathResult;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( @EXPORT %EXPORT_TAGS $VERSION );
    use HTML::Object::Exception;
    use constant {
        # A result set containing whatever type naturally results from evaluation of the expression. Note that if the result is a node-set then UNORDERED_NODE_ITERATOR_TYPE is always the resulting type.
        ANY_TYPE                        => 0,
        # A result containing a single number. This is useful for example, in an XPath expression using the count() function.
        NUMBER_TYPE                     => 1,
        # A result containing a single string.
        STRING_TYPE                     => 2,
        # A result containing a single boolean value. This is useful for example, in an XPath expression using the not() function.
        BOOLEAN_TYPE                    => 3,
        # A result node-set containing all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.
        UNORDERED_NODE_ITERATOR_TYPE    => 4,
        # A result node-set containing all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.
        ORDERED_NODE_ITERATOR_TYPE      => 5,
        # A result node-set containing snapshots of all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.
        UNORDERED_NODE_SNAPSHOT_TYPE    => 6,
        # A result node-set containing snapshots of all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.
        ORDERED_NODE_SNAPSHOT_TYPE      => 7,
        # A result node-set containing any single node that matches the expression. The node is not necessarily the first node in the document that matches the expression.
        ANY_UNORDERED_NODE_TYPE         => 8,
        # A result node-set containing the first node in the document that matches the expression.
        FIRST_ORDERED_NODE_TYPE         => 9,
    };
    our @EXPORT = qw(
        ANY_TYPE NUMBER_TYPE STRING_TYPE BOOLEAN_TYPE
        UNORDERED_NODE_ITERATOR_TYPE ORDERED_NODE_ITERATOR_TYPE
        UNORDERED_NODE_SNAPSHOT_TYPE ORDERED_NODE_SNAPSHOT_TYPE
        ANY_UNORDERED_NODE_TYPE FIRST_ORDERED_NODE_TYPE
    );
    our %EXPORT_TAGS = (
        all => [qw(
            ANY_TYPE NUMBER_TYPE STRING_TYPE BOOLEAN_TYPE
            UNORDERED_NODE_ITERATOR_TYPE ORDERED_NODE_ITERATOR_TYPE
            UNORDERED_NODE_SNAPSHOT_TYPE ORDERED_NODE_SNAPSHOT_TYPE
            ANY_UNORDERED_NODE_TYPE FIRST_ORDERED_NODE_TYPE
        )]
    );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{result} = undef;
    # Any type, by default
    $self->{resulttype} = 0;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{_pos} = 0;
    return( $self );
}

# Note: property booleanValue read-only
sub booleanValue
{
    my $self = shift( @_ );
    my $res = $self->result;
    return( $self->error({
        message => 'Result is not a boolean',
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $res => 'HTML::Object::XPath::Boolean' ) );
    return( $res );
}

# Note: property invalidIteratorState read-only
sub invalidIteratorState : lvalue { return( shift->_set_get_property( 'invaliditeratorstate', @_ ) ); }

sub iterateNext
{
    my $self = shift( @_ );
    my $res = $self->result;
    return( $self->error({
        message => 'Result is not a NodeSet',
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $res => 'HTML::Object::XPath::NodeSet' ) );
    return if( $self->{_pos} >= $res->size );
    my $node = $res->index( $self->{_pos} );
    $self->{_pos}++;
    return( $node );
}

# Note: property numberValue read-only
sub numberValue
{
    my $self = shift( @_ );
    my $res = $self->result;
    return( $self->error({
        message => 'Result is not a number',
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $res => 'HTML::Object::XPath::Number' ) );
    return( $res );
}

# Note: method to store the result, which is an object of various class, so we use _set_get
sub result { return( shift->_set_get( 'result', @_ ) ); }

# Note: property resultType read-only
sub resultType : lvalue { return( shift->_set_get_number( 'resulttype', @_ ) ); }

# Note: property singleNodeValue read-only
sub singleNodeValue
{
    my $self = shift( @_ );
    my $res = $self->result;
    return( $self->error({
        message => 'Result is not a node (HTML::Object::DOM::Node)',
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $res => 'HTML::Object::DOM::Node' ) );
    return( $res );
}

sub snapshotItem
{
    my $self = shift( @_ );
    my $res = $self->result;
    if( $self->_is_a( $res => 'HTML::Object::XPath::NodeSet' ) )
    {
        return( $res->[ $self->{_pos} ] );
    }
    else
    {
        return( $res );
    }
}

# Note: property snapshotLength read-only
sub snapshotLength
{
    my $self = shift( @_ );
    my $res = $self->result;
    if( $self->_is_a( $res => 'HTML::Object::XPath::NodeSet' ) )
    {
        return( $res->size );
    }
    else
    {
        return( ref( $res ) ? 1 : 0 );
    }
}

# Note: property stringValue read-only
sub stringValue
{
    my $self = shift( @_ );
    my $res = $self->result;
    return( $self->error({
        message => 'Result is not a string (HTML::Object::XPath::Literal)',
        class => 'HTML::Object::TypeError',
    }) ) if( !$self->_is_a( $res => 'HTML::Object::XPath::Literal' ) );
    return( $res );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::XPathResult - HTML Object DOM XPath Result Class

=head1 SYNOPSIS

    use HTML::Object::DOM::XPathResult;
    my $result = HTML::Object::DOM::XPathResult->new ||
         die( HTML::Object::DOM::XPathResult->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<XPathResult> interface represents the results generated by evaluating an XPath expression within the context of a given L<node|HTML::Object::DOM::Node>.

The method you can access vary depending on the type of results returned. The XPath evaluation can return a L<boolean|HTML::Object::XPath::Boolean>, a L<number|HTML::Object::XPath::Number>, a L<string|HTML::Object::XPath::Literal>, or a L<node set|HTML::Object::XPath::NodeSet>

=head1 PROPERTIES

All properties are read-only, but you can change their returned value by changing the value of L</result>, which contains the result from the XPath search.

=head2 booleanValue

A boolean representing the value of the result if resultType is C<BOOLEAN_TYPE>, i.e. if the result is a boolean.

Example:

    <div>XPath example</div>
    <p>Text is 'XPath example': <output></output></p>

    my $xpath = "//div/text() = 'XPath example'";
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent = $result->booleanValue;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/booleanValue>

=head2 invalidIteratorState

This always return C<undef> under perl, but you can change the value of this boolean to whatever boolean value you want.

Normally, under JavaScript, this signifies that the iterator has become invalid. It is true if resultType is UNORDERED_NODE_ITERATOR_TYPE or ORDERED_NODE_ITERATOR_TYPE and the document has been modified since this result was returned.

Example:

    <div>XPath example</div>
    <p>Iterator state: <output></output></p>

    my $xpath = '//div';
    my $result = $doc->evaluate( $xpath, $doc );
    # Invalidates the iterator state
    $doc->querySelector( 'div' )->remove();
    $doc->querySelector( 'output' )->textContent = $result->invalidIteratorState ? 'invalid' : 'valid';

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/invalidIteratorState>

=head2 numberValue

A number representing the value of the result if resultType is C<NUMBER_TYPE>, i.e. if the result is a number.

Example:

    <div>XPath example</div>
    <div>Number of &lt;div&gt;s: <output></output></div>

    my $xpath = 'count(//div)';
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent = $result->numberValue;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/numberValue>

=head2 result

Sets or gets the resulting object from the XPath search. This could be a L<node|HTML::Object::DOM::Node>, a L<boolean|HTML::Object::XPath::Boolean>, a L<number|HTML::Object::XPath::Number>, a L<string|HTML::Object::XPath::Literal>, or a L<set of nodes|HTML::Object::XPath::NodeSet>

=head2 resultType

A number code representing the type of the result, as defined by the type constants. See L</CONSTANTS>

Example:

    <div>XPath example</div>
    <div>Is XPath result a node set: <output></output></div>

    use HTML::Object::DOM::XPathResult;
    # or
    use HTML::Object::DOM qw( :xpath );
    my $xpath = '//div';
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent =
        $result->resultType >= UNORDERED_NODE_ITERATOR_TYPE &&
        $result->resultType <= FIRST_ORDERED_NODE_TYPE;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/resultType>

=head2 singleNodeValue

A Node representing the value of the single node result, which may be C<undef>. This is set when the result is a single L<node|HTML::Object::DOM::Node>.

Example:

    <div>XPath example</div>
    <div>Tag name of the element having the text content 'XPath example': <output></output></div>

    my $xpath = q{//*[text()='XPath example']};
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent = $result->singleNodeValue->localName;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/singleNodeValue>

=head2 snapshotLength

The number of nodes in the result snapshot. As a divergence from the standard, this also applies to the number of elements in the L<NodeSet|HTML::Object::XPath::NodeSet> returned.

Example:

    <div>XPath example</div>
    <div>Number of matched nodes: <output></output></div>

    my $xpath = '//div';
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent = $result->snapshotLength;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/snapshotLength>

=head2 stringValue

A string representing the value of the result if resultType is C<STRING_TYPE>, i.e. when the result is a string.

Example:

    <div>XPath example</div>
    <div>Text content of the &lt;div&gt; above: <output></output></div>

    my $xpath = '//div/text()';
    my $result = $doc->evaluate( $xpath, $doc );
    $doc->querySelector( 'output' )->textContent = $result->stringValue;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/stringValue>

=head1 METHODS

=head2 iterateNext

If the result is a L<node set|HTML::Object::XPath::NodeSet>, this method iterates over it and returns the next node from it or C<undef> if there are no more nodes.

Example:

    <div>XPath example</div>
    <div>Tag names of the matched nodes: <output></output></div>

    use Module::Generic::Array;
    my $xpath = '//div';
    my $result = $doc->evaluate( $xpath, $doc );
    my $node;
    my $tagNames = Module::Generic::Array->new;
    while( $node = $result->iterateNext() )
    {
        $tagNames->push( $node->localName );
    }
    $doc->querySelector( 'output' )->textContent = $tagNames->join( ', ' );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/iterateNext>

=head2 snapshotItem

Returns an item of the snapshot collection or C<undef> in case the index is not within the range of nodes.

Normally, under JavaScript, unlike the iterator result, the snapshot does not become invalid, but may not correspond to the current document if it is mutated.

Example:

    <div>XPath example</div>
    <div>Tag names of the matched nodes: <output></output></div>

    use Module::Generic::Array;
    my $xpath = '//div';
    my $result = $doc->evaluate( $xpath, $doc );
    my $node;
    my $tagNames = Module::Generic::Array->new;
    for( my $i = 0; $i < $result->snapshotLength; $i++ )
    {
        my $node = $result->snapshotItem( $i );
        $tagNames->push( $node->localName );
    }
    $doc->querySelector( 'output' )->textContent = $tagNames->join( ', ' );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult/snapshotItem>

=head1 CONSTANTS

The following constants are exported by default:

=over 4

=item ANY_TYPE (0)

A result set containing whatever type naturally results from evaluation of the expression. Note that if the result is a node-set then C<UNORDERED_NODE_ITERATOR_TYPE> is always the resulting type.

=item NUMBER_TYPE (1)

A result containing a single number. This is useful for example, in an XPath expression using the count() function.

=item STRING_TYPE (2)

A result containing a single string.

=item BOOLEAN_TYPE (3)

A result containing a single boolean value. This is useful for example, in an XPath expression using the not() function.

=item UNORDERED_NODE_ITERATOR_TYPE (4)

A result node-set containing all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.

=item ORDERED_NODE_ITERATOR_TYPE (5)

A result node-set containing all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.

=item UNORDERED_NODE_SNAPSHOT_TYPE (6)

A result node-set containing snapshots of all the nodes matching the expression. The nodes may not necessarily be in the same order that they appear in the document.

=item ORDERED_NODE_SNAPSHOT_TYPE (7)

A result node-set containing snapshots of all the nodes matching the expression. The nodes in the result set are in the same order that they appear in the document.

=item ANY_UNORDERED_NODE_TYPE (8)

A result node-set containing any single node that matches the expression. The node is not necessarily the first node in the document that matches the expression.

=item FIRST_ORDERED_NODE_TYPE (9)

A result node-set containing the first node in the document that matches the expression. 

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/XPathResult>, L<W3C specifications|https://dom.spec.whatwg.org/#interface-xpathresult>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
