##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Attribute.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Attribute;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Attribute HTML::Object::DOM::Node );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init { return( shift->HTML::Object::Attribute::init( @_ ) ); }

sub getAttributes
{
    my $self = shift( @_ );
    my $elem = $self->element;
    my $a = $self->new_array;
    return( wantarray() ? $a->list : $a ) if( !$elem );
    return( $elem->getAttributes );
}

sub getChildNodes { return( wantarray() ? () : [] ); }

sub getElementById { return; }

sub getFirstChild { return; }

sub getLastChild { return; }

sub getLocalName
{
    my $self = shift( @_ );
    ( my $name = $self->name ) =~ s{^.*:}{};
    return( $name );
}

sub getName { return( shift->name ); }

sub getNextSibling
{
    my $self = shift( @_ );
    my $elem = $self->element;
    return if( !$elem );
    my $pos  = $elem->attributes_sequence->pos( $self->name );
    return if( $pos == $elem->attributes_sequence->size );
    my $key = $elem->attributes_sequence->get( $pos - 1 );
    my $val = $elem->attributes->get( $key );
    return( $self->new(
        element => $elem,
        name    => $key,
        rank    => ( $pos + 1 ),
        value   => $val,
    ) );
}

sub getParentNode { return( shift->element ); }

# awfully inefficient, but hopefully this is called only for weird (read test-case) queries
sub getPreviousSibling
{
    my $self = shift( @_ );
    my $elem = $self->element;
    return if( !$elem );
    my $pos  = $elem->attributes_sequence->pos( $self->name );
    return if( !$pos );
    my $key = $elem->attributes_sequence->get( $pos - 1 );
    my $val = $elem->attributes->get( $key );
    return( $self->new(
        element => $elem,
        name    => $key,
        rank    => ( $pos - 1 ),
        value   => $val,
    ) );
}

sub getRootNode { return( shift->parent->getRootNode ); }

sub getValue { return( shift->value ); }

sub isAttributeNode { 1 }

sub isCommentNode   { return(0); }

sub isElementNode   { return(0); }

sub isNamespaceNode { return(0); }

sub isPINode        { return(0); }

sub isProcessingInstructionNode { return(0); }

sub isTextNode      { return(0); }

sub is_inside
{
    my( $self, $node ) = @_;
    my $e = $self->element;
    return( ( $e == $node ) || $e->is_inside( $node ) );
}

# Updated version from HTML::Object::Element's one because HTML::Object::DOM::Attribute 
# is considered a child of its associated element
# This is used in HTML::Object::DOM::Node->compareDocumentPosition
sub lineage 
{
    my $self = shift( @_ );
    my $e = $self->element;
    return( $self->new_array ) if( !$e );
    return( $e->lineage->unshift( $e ) );
}

sub localName { return( shift->getName ); }

sub namespaceURI { return; }

# "The value of Attr.name, that is the qualified name of the attribute."
# <https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeName>
sub nodeName { return( shift->name ); }

# Note: Property
sub nodeValue : lvalue { return( shift->_set_get_lvalue( 'value', @_ ) ); }

sub ownerElement { return( shift->element ); }

sub parent { return( shift->element ); }

sub prefix { return; }

sub string_value { return( shift->value ); }

sub to_boolean { return( shift->value->scalar ? HTML::Object::Boolean->True : HTML::Object::Boolean->False ); }

sub to_literal { return( HTML::Object::Literal->new( shift->value ) ); }

sub to_number { return( HTML::Object::Number->new( shift->value ) ); }

sub toString
{
    my $self = shift( @_ );
    return( sprintf( '%s="%s"', $self->name, $self->value ) );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Attribute - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::Attribute;
    my $this = HTML::Object::DOM::Attribute->new || die( HTML::Object::DOM::Attribute->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module implements a DOM node attribute. It inherits from L<HTML::Object::Attribute> and from L<HTML::Object::DOM::Node>

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Closing |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+
      |                                                                                               ^
      |                                                                                               |
      v                                                                                               |
    +-----------------------+                                                                         |
    | HTML::Object::Closing | ------------------------------------------------------------------------+
    +-----------------------+

=head1 PROPERTIES

=head2 nodeValue

Returns the attribute value as a L<scalar object|Module::Generic::Scalar>

=head1 METHODS

=head2 getAttributes

If this attribute has no associated element, this returns an empty list in list context or an empty array reference in scalar context.

Otherwise, this returns an L<array object|Module::Generic::Array> of attribute objects for the associated element.

=head2 getChildNodes

Returns an empty list in list context, or an empty array reference in scalar context.

=head2 getElementById

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getFirstChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getLastChild

Returns an empty list in list context, or C<undef> in scalar context.

=head2 getLocalName

Returns the attribute name.

=head2 getName

Returns the attribute name.

=head2 getNextSibling

Returns the next attribute object for the associated element, or C<undef> if there are no associated element, or if this attribute is the last one of the associated element.

=head2 getParentNode

Returns the associated element, if any.

=head2 getPreviousSibling

Returns the previous attribute object for the associated element, or C<undef> if there are no associated element, or if this attribute is the first one of the associated element.

=head2 getRootNode

Returns the root node by calling C<getRootNode> on this attribute parent.

=head2 getValue

Returns the attribute value.

=head2 isAttributeNode

Returns true.

=head2 isCommentNode

Returns false.

=head2 isElementNode

Returns false.

=head2 isEqualNode

Provided with another attribute object, and this returns true if both attribute object have the same value, or false otherwise.

=head2 isNamespaceNode

Returns false.

=head2 isPINode

Returns false.

=head2 isProcessingInstructionNode

Returns false.

=head2 isTextNode

Returns false.

=head2 is_inside

Provided with a node and this returns true if this attribute associated element is the same, or if the associated element is inside the provided element.

=head2 lineage

Returns the value provided by calling C<lineage> on the associated element and adding it to the lineage, or an empty L<array object> if there is no associated element.

=head2 localName

This is just an alias for L</getName>

=head2 namespaceURI

Always returns C<undef>

=head2 nodeName

Returns the qualified name of the attribute. This actually calls L<HTML::Object::Attribute/name>

=head2 ownerElement

This returns the attribute associated element, if any.

=head2 parent

This returns the attribute associated element, if any.

=head2 prefix

Always returns C<undef>

=head2 string_value

Returns the attribute value.

=head2 to_boolean

Returns a L<true boolean object|HTML::Object::Boolean> if the attribute value is true, or a L<false boolean object|HTML::Object::Boolean> otherwise.

=head2 to_literal

Returns the attribute value.

=head2 to_number

Returns a new L<HTML::Object::Number> object based on the attribute value.

=head2 toString

Returns a string, such as: C<name="value">

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla reference|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes>

L<W3C standard on attributes|https://html.spec.whatwg.org/multipage/syntax.html#attributes-2>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
