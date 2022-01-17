##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Declaration.pm
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
package HTML::Object::Declaration;
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
    $self->{name} = 'html' unless( CORE::exists( $self->{name} ) && CORE::length( $self->{name} ) );
    $self->{_init_strict_use_sub} = 1;
    $this->{_exception_class} = 'HTML::Object::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = '_declaration';
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    if( !$self->original->is_empty )
    {
        return( $self->original );
    }
    else
    {
        my $name = $self->name;
        return( $self->new_scalar( "<!DOCTYPE" . ( ( defined( $name ) && CORE::length( "$name" ) ) ? " ${name}" : '' ) . '>' ) );
    }
}

sub as_xml { return( shift->as_string( @_ ) ); }

sub checksum { return( '' ); }

sub name
{
    my $self = shift( @_ );
    if( my $rv = $self->original->match( qr/^<!DOCTYPE[[:blank:]\h]+(\w+)/ ) )
    {
        return( lc( $rv->capture->first ) );
    }
    return( '' );
}

sub set_checksum {}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Declaration - HTML Object

=head1 SYNOPSIS

    use HTML::Object::Declaration;
    my $this = HTML::Object::Declaration->new || die( HTML::Object::Declaration->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This module represents a document declaration element.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+
    | HTML::Object::Element | --> | HTML::Object::Declaration |
    +-----------------------+     +---------------------------+

=head1 PROPERTIES

=head2 internalSubset

Read-only.

Returns an empty L<string object|Module::Generic::Scalar>

=head2 name

Read-only.

A DOMString, eg C<html> for <!DOCTYPE HTML>.

=head2 notations

Read-only.

A NamedNodeMap with notations declared in the DTD.

=head2 publicId

Read-only.

A DOMString, eg "-//W3C//DTD HTML 4.01//EN", empty string for HTML5.

For example, with a doctype such as:

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
        "http://www.w3.org/TR/html4/strict.dtd">

or

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/html4/loose.dtd">

=head2 systemId

Read-only.

A DOMString, eg "http://www.w3.org/TR/html4/strict.dtd", empty string for HTML5.

=head1 METHODS

=head2 after

This method is listed here for standard compliance, but actually does nothing.

Normally, in JavaScript, it would insert a set of Node or DOMString objects in the children list of the DocumentType's parent, just after the DocumentType object. 

=head2 as_string

Returns a string representation of this element.

=head2 as_xml

Returns a xml representation of this element. This is actually an alias for L</as_string>

=head2 before

This method is listed here for standard compliance, but actually does nothing.

Normally, in JavaScript, it would insert a set of Node or DOMString objects in the children list of the DocumentType's parent, just before the DocumentType object.

=head2 checksum

Returns an empty string.

=head2 set_checksum

Returns nothing.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<https://html.spec.whatwg.org/multipage/syntax.html#the-doctype>

L<https://developer.mozilla.org/en-US/docs/Web/HTML/Quirks_Mode_and_Standards_Mode>

L<https://developer.mozilla.org/en-US/docs/Web/API/DocumentType>

L<HTML::Object>, L<HTML::Object::Attribute>, L<HTML::Object::Boolean>, L<HTML::Object::Closing>, L<HTML::Object::Collection>, L<HTML::Object::Comment>, L<HTML::Object::Declaration>, L<HTML::Object::Document>, L<HTML::Object::Element>, L<HTML::Object::Exception>, L<HTML::Object::Literal>, L<HTML::Object::Number>, L<HTML::Object::Root>, L<HTML::Object::Space>, L<HTML::Object::Text>, L<HTML::Object::XQuery>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
