##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Comment.pm
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
package HTML::Object::Comment;
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
    $self->{open_seq} = '<!--';
    $self->{close_seq} = '-->';
    $self->{tag} = '_comment';
    $self->{value} = '';
    $self->{is_empty} = 1;
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    # We need to remove the reset flag, otherwise if there are any subsequent change that need to be propagated to this comment parent, HTML::Object::Element::reset will not propagate it
    $self->_remove_reset;
    return(
        $self->value->length
            ? $self->new_scalar( join( '', '<!--', $self->value->scalar, '-->' ) )
            : $self->original
    );
}

sub as_xml
{
    my $self = shift( @_ );
    my $txt = $self->value->length
        ? $self->new_scalar( join( '', '<!--', $self->value->scalar, '-->' ) )
        : $self->original;
    # HTML::Element says there cannot be double --'s in XML comments
    $txt->replace( qr/--/, '-&#45;' );
    return( $txt );
}

sub close_seq { return( shift->_set_get_scalar_as_object( 'close_seq', @_ ) ); }

sub open_seq { return( shift->_set_get_scalar_as_object( 'open_seq', @_ ) ); }

sub set_checksum
{
    my $self = shift( @_ );
    return( $self->_get_md5_hash( $self->value->scalar ) );
}

sub value : lvalue { return( shift->_set_get_scalar_as_object( 'value', @_ ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Comment - HTML Object Comment Element Class

=head1 SYNOPSIS

    use HTML::Object::Comment;
    my $this = HTML::Object::Comment->new || 
        die( HTML::Object::Comment->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents an HTML comment

=head1 INHERITANCE

    +-----------------------+     +-----------------------+
    | HTML::Object::Element | --> | HTML::Object::Comment |
    +-----------------------+     +-----------------------+

=head1 PROPERTIES

=head2 nodeValue

This returns or sets the value of the current node.

For document, element or collection, this returns C<undef> and for attribute, text or comment, this returns the objct value.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head1 METHODS

=head2 as_string

Returns the HTML comment as a string.

=head2 as_xml

Returns the comment as an XML string., which is almost the same format as with L</as_string>

=head2 close_seq

Set or get the string used as a close sequence.

=head2 isEqualNode

Returns a boolean value which indicates whether or not two elements are of the same type and all their defining data points match.

Two elements are equal when they have the same type, defining characteristics (this would be their ID, number of children, and so forth), its attributes match, and so on. The specific set of data points that must match varies depending on the types of the elements. 

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/isEqualNode>

=head2 nodeValue

This returns or sets the value of the current element.

See L<for more information|https://developer.mozilla.org/en-US/docs/Web/API/Node/nodeValue>

=head2 open_seq

Set or get the string used as an open sequence.

=head2 set_checksum

Read-only.

Get the element md5 checksum for the current value.

=head2 value

Set or get the comment inner value, i.e. the text within, as a L<scalar object|Module::Generic::Scalar>

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
