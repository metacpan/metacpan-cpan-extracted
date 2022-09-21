##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Attribute.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/22
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Attribute;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use HTML::Object::Literal;
    use HTML::Object::Number;
    use Want;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    my $name;
    # HTML::Object::Attribute->new( 'id' );
    # HTML::Object::Attribute( 'id', value => 'hello', element => $e );
    # HTML::Object::Attribute( 'id', { value => 'hello', element => $e } );
    if( ( scalar( @_ ) == 1 && ( !ref( $_[0] ) || overload::Method( $_[0], '""' ) ) ) ||
        ( ( @_ % 2 ) && ( !ref( $_[0] ) || overload::Method( $_[0], '""' ) ) ) ||
        ( scalar( @_ ) == 2 && ( !ref( $_[0] ) || overload::Method( $_[0], '""' ) ) && ref( $_[1] ) eq 'HASH' ) )
    {
        $name = shift( @_ );
    }
    $self->{element} = '';
    $self->{name}    = $name;
    $self->{rank}    = '';
    $self->{value}   = '';
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub element { return( shift->_set_get_object_without_init( 'element', 'HTML::Object::Element', @_ ) ); }

sub name { return( shift->_set_get_scalar_as_object( 'name', @_ ) ); }

sub rank { return( shift->_set_get_number_as_object( 'rank', @_ ) ); }

# sub value { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }
sub value
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        $v =~ s/^[[:blank:]\h]+|[[:blank:]\h]+$//g;
        return( $self->_set_get_scalar_as_object( 'value', $v ) );
    }
    return( $self->_set_get_scalar_as_object( 'value' ) );
}


1;
# NOTE: POD
__END__

=encoding utf8

=head1 NAME

HTML::Object::Attribute - HTML Object Element Attribute Class

=head1 SYNOPSIS

    use HTML::Object::Attribute;
    my $attr = HTML::Object::Attribute->new( 'id' );
    $attr->value = "hello";

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This class represent an element attribute. it is used as part of L<HTML::Object>, and also contains methods to interface with L<HTML::Object::XPath>

=head1 CONSTRUCTOR

=head2 new

Creates a new C<HTML::Object::Attribute> objects.

It may also take an hash like arguments, that also are method of the same name.

    my $attr = HTML::Object::Attribute->new( 'id' );
    # or
    my $attr = HTML::Object::Attribute->new( name => 'id' );

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 element

Returns the L<HTML::Object::Element> object to which this attribute belongs.

=head2 getAttributes

Returns an L<array object|Module::Generic::Array> of the related element's attributes as L<HTML::Object::Attribute> objects.

=head2 getLocalName

Returns the attribute name.

=head2 getName

Returns the attribute name.

=head2 getNextSibling

Returns the next attribute object, or C<undef>.

=head2 getParentNode

Returns the parent L<HTML::Object::Element> object.

=head2 getPreviousSibling

Returns the previous attribute object, or C<undef>.

=head2 getValue

Returns the attribute value.

=head2 isAttributeNode

Always returns true.

=head2 is_inside

Provided with an L<HTML::Object::Element> and this will return true if this attribute is inside it, or false otherwise.

=head2 lineage

Add the parent element to our lineage. See L<HTML::Object::Element/lineage>

=head2 localName

Read-only.

A string representing the local part of the qualified name of the attribute.

This is the same as L</getName>, because this interface does not use xml C<prefix>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/localName>

=head2 name

Set or get the attribute name.

Normally, under JavaScript, this is read-only, but under perl you can change it. Still be careful.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/name>

=head2 namespaceURI

Read-only

A string representing the URI of the namespace of the attribute, or C<undef> if there is no namespace.

This actually always return C<undef>, because this interface does not use xml C<prefix>

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/namespaceURI>

=head2 nodeValue

This returns or sets the value of the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 ownerElement

Returns the L<element object|HTML::Object::Element> to which this attribute object belongs.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/ownerElement>

=head2 prefix

Read-only.

This always return C<undef>, because this interface does not use xml C<prefix>

Normally, under JavaScript, this would return a string representing the namespace prefix of the attribute, or c<undef> if a namespace without prefix or no namespace are specified.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/prefix>

=head2 rank

Set or get the attribute rank. This returns a L<number object|Module::Generic::Number>

=head2 string_value

This is an alias for L</value>

=head2 to_boolean

Returns the attribute value as a L<boolean|Module::Generic::Boolean>

=head2 to_literal

Returns the attribute value as a L<litteral|HTML::Object::Litteral>

=head2 to_number

Returns the attribute value as a L<number|Module::Generic::Number>

=head2 toString

Returns a stringification of this attribute such as C<attribute="value">

=head2 value

Set or get the value of this attribute as a L<scalar object|Module::Generic::Scalar>. For example:

    $attr->value( "hello" );

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Attr/value>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

L<https://developer.mozilla.org/en-US/docs/Web/API/Attr>

L<Mozilla reference|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes>

L<W3C standard on attributes|https://html.spec.whatwg.org/multipage/syntax.html#attributes-2>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
