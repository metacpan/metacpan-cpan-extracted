##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Text.pm
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
package HTML::Object::Text;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTML::Object::Element );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{tag} = '_text';
    $self->{value} = '';
    $self->{is_empty} = 1;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    # We need to remove the reset flag, otherwise if there are any subsequent change that need to be propagated to this text parent, HTML::Object::Element::reset will not propagate it
    $self->_remove_reset;
    return( $self->value->length ? $self->value : $self->original );
}

# There is nothing to encode because we have not touched the text in the first place.
# Especially in the script tag section !
# If the user wants to, he can and should go ahead, but it is way too dangerous for us to make assumptions
sub as_xml { return( shift->as_string( @_ ) ); }

# added to provide element-like methods to text nodes, for use by cmp
sub lineage 
{
    my $node = shift( @_ );
    my $parent = $node->parent;
    return( $parent, $parent->lineage );
}

sub set_checksum
{
    my $self = shift( @_ );
    return( $self->_get_md5_hash( $self->value->scalar ) );
}

sub value : lvalue { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Text - HTML Object

=head1 SYNOPSIS

    use HTML::Object::Text;
    my $txt = HTML::Object::Text->new || 
        die( HTML::Object::Text->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module represents a text. It inherits from L<HTML::Object::Element>

=head1 INHERITANCE

    +-----------------------+     +--------------------+
    | HTML::Object::Element | --> | HTML::Object::Text |
    +-----------------------+     +--------------------+

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 as_string

Returns the original value or the value assigned with L</value>

=head2 as_xml

This is an alias for L</as_string>

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 lineage

Returns an L<array object|Module::Generic::Array> of all the text element's ancestors.

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

L<https://html.spec.whatwg.org/multipage/syntax.html#the-doctype>

L<https://developer.mozilla.org/en-US/docs/Web/HTML/Quirks_Mode_and_Standards_Mode>

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
