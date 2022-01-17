##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Root.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/22
## Modified 2021/08/23
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Root;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::Document );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{root} = '';
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# added to provide element-like methods to root, for use by cmp
sub lineage
{
    my $self = shift( @_ );
    return( $self->new_array( [ $self ] ) );
}

sub root { return( shift->_set_get_object( 'root', 'HTML::Object::Element', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Root - HTML Object

=head1 SYNOPSIS

    use HTML::Object::Root;
    my $root = HTML::Object::Root->new || 
        die( HTML::Object::Root->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represent a C<Root> element. It inherits fron L<HTML::Object::Document>

=head1 INHERITANCE

    +-----------------------+     +------------------------+     +--------------------+
    | HTML::Object::Element | --> | HTML::Object::Document | --> | HTML::Object::Root |
    +-----------------------+     +------------------------+     +--------------------+

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 cmp

Provided with an element and this returns true if this element is a L<Root element|HTML::Object::Root>, or false otherwise.

=head2 getAttributes

Returns a new empty L<array object|Module::Generic::Array>

=head2 getChildNodes

Returns the value returned by L</root>

=head2 getName

Returns C<undef> if scalar context and an empty list in list context.

=head2 getNextSibling

Returns C<undef> if scalar context and an empty list in list context.

=head2 getParentNode

Returns C<undef> if scalar context and an empty list in list context.

=head2 getPreviousSibling

Returns C<undef> if scalar context and an empty list in list context.

=head2 getRootNode

Returns the current object since there is no higher element than itself.

=head2 is_inside

Returns C<0>, i.e. false.

=head2 isDocumentNode

Returns C<1>, i.e. true.

=head2 lineage

Returns a new L<array object|Module::Generic::Array> with the current object as its sole element.

=head2 root

Returns the L<element object|HTML::Object::Element> representing the actual root element.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
