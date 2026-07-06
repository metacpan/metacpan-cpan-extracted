##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Attribute.pm
## Version v0.3.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/22
## Modified 2025/10/16
## All rights reserved.
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
    warnings::register_categories( 'HTML::Object' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    use HTML::Object::Literal;
    use HTML::Object::Number;
    use Wanted;
    our $VERSION = 'v0.3.0';
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

    # Attribute name only
    my $attr = HTML::Object::Attribute->new( 'id' );

    # Name with properties as key-value pairs
    my $attr = HTML::Object::Attribute->new( 'id', value => 'hello', element => $e );

    # Name with properties as a hash reference
    my $attr = HTML::Object::Attribute->new( 'id', { value => 'hello', element => $e } );

    # Properties only, via SUPER::init key-value dispatch
    my $attr = HTML::Object::Attribute->new( name => 'id', value => 'hello' );

    $attr->value( 'hello' );
    print $attr->name;   # id
    print $attr->value;  # hello

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

This class represents an HTML element attribute. It is the base class used throughout the L<HTML::Object> framework to store an attribute name, its associated value, the element it belongs to, and its rank (position) within that element's attribute list.

The DOM-oriented interface (node traversal, XPath coercions, stringification, and so on) is provided by the subclass L<HTML::Object::DOM::Attribute>, which extends this class.

=head1 CONSTRUCTOR

=head2 new

    my $attr = HTML::Object::Attribute->new( 'id' );
    my $attr = HTML::Object::Attribute->new( 'id', value => 'hello', element => $e );
    my $attr = HTML::Object::Attribute->new( 'id', { value => 'hello', element => $e } );
    my $attr = HTML::Object::Attribute->new( name => 'id', value => 'hello' );

Creates and returns a new C<HTML::Object::Attribute> object.

The constructor accepts the attribute name as an optional leading positional argument (a plain string or any object that overloads stringification), followed by either a flat list of key-value pairs or a hash reference of properties. When no positional name is given, the name may be supplied via the C<name> key in the property list.

Returns the new object on success, or sets an error and returns C<undef> on failure.

=head1 METHODS

=head2 element

    my $element = $attr->element;
    $attr->element( $element );

Gets or sets the L<HTML::Object::Element> object to which this attribute belongs. Accepts an C<HTML::Object::Element> instance or C<undef> to clear the association.

=head2 name

    my $name = $attr->name;
    $attr->name( 'class' );

Gets or sets the attribute name. Returns a L<scalar object|Module::Generic::Scalar>.

Normally, under JavaScript, this is read-only, but under perl you can change it. Still be careful.

See also L<https://developer.mozilla.org/en-US/docs/Web/API/Attr/name>

=head2 rank

    my $rank = $attr->rank;
    $attr->rank(3);

Gets or sets the position (rank) of this attribute within its parent element's attribute list. Returns a L<number object|Module::Generic::Number>.

=head2 value

    my $val = $attr->value;
    $attr->value( 'hello' );

Gets or sets the attribute value. Leading and trailing horizontal whitespace is stripped automatically when a value is set. Returns a L<scalar object|Module::Generic::Scalar>.

See also L<https://developer.mozilla.org/en-US/docs/Web/API/Attr/value>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object::DOM::Attribute>, the DOM subclass that adds node traversal, XPath coercion, C<toString>, C<nodeValue>, and the full attribute node interface.

L<HTML::Object>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

L<https://developer.mozilla.org/en-US/docs/Web/API/Attr>

L<Mozilla HTML attributes reference|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes>

L<W3C attributes specification|https://html.spec.whatwg.org/multipage/syntax.html#attributes-2>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
