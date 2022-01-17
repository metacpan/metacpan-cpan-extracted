##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Space.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/19
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Space;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTML::Object::Element );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{is_empty} = 1;
    $self->{tag} = '_space';
    $self->{value} = undef;
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    # We need to remove the reset flag, otherwise if there are any subsequent change that need to be propagated to this space parent, HTML::Object::Element::reset will not propagate it
    $self->_remove_reset;
    return( $self->value->length ? $self->value : $self->original );
}

sub as_xml { return( shift->as_string( @_ ) ); }

sub set_checksum
{
    my $self = shift( @_ );
    return( $self->_get_md5_hash( $self->value->scalar ) );
}

sub value : lvalue { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }
# {
#     my $self = shift( @_ );
#     if( @_ )
#     {
#         return( $self->_set_get_scalar_as_object( 'value', @_ ) );
#     }
#     my $val = $self->_set_get_scalar_as_object( 'value' );
#     return( $val ) if( defined( $val ) && $val->defined );
#     return( $self->original );
# }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Space - HTML Object

=head1 SYNOPSIS

    use HTML::Object::Space;
    my $sp = HTML::Object::Space->new || 
        die( HTML::Object::Space->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents or or more spaces. It is used to capture spaces between L<HTML elements|HTML::Object::Element>

=head1 INHERITANCE

    +-----------------------+     +---------------------+
    | HTML::Object::Element | --> | HTML::Object::Space |
    +-----------------------+     +---------------------+

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 as_string

Returns the space value enclosed.

=head2 as_xml

This is an alias for L</as_string>

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 nodeValue

This returns or sets the value of the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 set_checksum

Read-only method.

This returns the md5 checksum for the current value.

=head2 value

Returns the current value as a L<scalar object|Module::Generic::Scalar>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
