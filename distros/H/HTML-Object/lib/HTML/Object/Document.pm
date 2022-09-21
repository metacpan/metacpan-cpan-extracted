##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/Document.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/04/19
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::Document;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTML::Object::Element );
    use vars qw( $VERSION );
    use Scalar::Util ();
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{is_empty} = 0;
    $self->{tag} = '_document';
    $self->{declaration} = undef;
    $self->{referrer} = undef;
    $self->{uri} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTML::Object::Exception';
    $self->{_last_modified}   = undef;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub append
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Nothing to append was provided." ) ) if( !defined( $this ) || !CORE::length( $this ) );
    if( !ref( $this ) || overload::Method( $this, '""' ) )
    {
        my $p = HTML::Object->new;
        my $doc = $p->parse( "$this" ) || return( $self->pass_error( $p->error ) );
        return( $self->error( "No element could be found from parsing html text provided." ) ) if( !$doc->children->length );
        $this = $doc->children->first;
    }
    if( !$self->_is_a( $this, 'HTML::Object::Element' ) || $self->_is_a( $this, 'HTML::Object::Collection' ) )
    {
        return( $self->error( "Element object provided is not an HTML::Object::Element object." ) );
    }
    if( $this->tag eq 'html' && $self->children->length && $self->children->first->tag eq 'html' )
    {
        require HTML::Object::Exception;
        return( $self->error({
            class => 'HTML::Object::HierarchyRequestError',
            code  => 403,
            message => "You are atttempting to add an html tag, but there is already one.",
        }) );
    }
    $this->parent( $self );
    $this->children->push( $this );
    return( $this );
}

sub as_string
{
    my $self = shift( @_ );
#     if( $self->isa( 'HTML::Object::Collection' ) )
#     {
#         return( '' ) if( !$self->children->length );
#         my $first = $self->children->first;
#         return( '' ) if( !$self->_is_a( $first, 'HTML::Object::Element' ) );
#         return( $self->error( "as_string() called on a Collection object, but its first children element is also a collection. Stopping before starting an infinite recursion." ) ) if( $self->_is_a( $first, 'HTML::Object::Collection' ) );
#         return( $first->as_string );
#     }
    my $a = $self->new_array;
    $a->push( $self->declaration->as_string ) if( $self->declaration );
    $self->children->foreach(sub
    {
        my $e = shift( @_ );
        my $v = $e->as_string;
        $a->push( defined( $v ) ? $v->scalar : $v );
    });
    return( $a->join( '' ) );
}

sub as_xml
{
    my $self = shift( @_ );
    my $a = $self->new_array;
    $self->children->foreach(sub
    {
        my $e = shift( @_ );
        my $v = $e->as_xml;
        $a->push( defined( $v ) ? $v->scalar : $v );
    });
    return( $a->join( '' ) );
}

sub declaration { return( shift->_set_get_object_without_init( 'declaration', 'HTML::Object::Declaration', @_ ) ); }

sub uri { return( shift->_set_get_uri( 'uri', @_ ) ); }

sub _last_modified { return( shift->_set_get_datetime( '_last_modified', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::Document - HTML Object Document Class

=head1 SYNOPSIS

    use HTML::Object::Document;
    my $doc = HTML::Object::Document->new || 
        die( HTML::Object::Document->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This module represents an HTML document and is instantiated by L<HTML::Object>. It is the top of the objects hierarchy.

=head1 INHERITANCE

    +-----------------------+     +------------------------+
    | HTML::Object::Element | --> | HTML::Object::Document |
    +-----------------------+     +------------------------+

=head1 METHODS

=head2 append

L</append> inserts a set of element objects or HTML string after the last child of the document.

This method appends a child to a L<Document|HTML::Object::Document>. To append to an arbitrary element in the tree, see L<HTML::Object::XQuery/append>.

An L<HTML::Object::HierarchyRequestError> exception is thrown when the element cannot be inserted at the specified point in the hierarchy.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/Document/append>

=head2 as_string

Returns the html document as a string, and in its original format except for the parts you modified.

=head2 as_xml

Returns the document as an xml document, which is kind of an old way to present html document.

=head2 declaration

Sets or gets the document L<DTD object|HTML::Object::Declaration>

=head2 uri

Because this is a perl framework, there is no URI associated with this object by default, but you can set L<one|URI> yourself, or it will be set automatically for you when you use L<HTML::Object/parse_url>

=head1 EVENT & EVENT HANDLERS

No event or event handlers are implemented for L<HTML::Object::Document>. If you want event handlers, use L<HTML::Object::DOM> objects instead.

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
