##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Accept.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/06
## Modified 2022/05/06
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::Accept;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( HTTP::Promise::Headers::Generic );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_qv_elements} = [];
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $val = shift( @_ );
        return( $self->error( "No value was provided." ) ) if( !defined( $val ) || !length( $val ) );
        my $choices = $self->_parse_quality_value( $val ) ||
            return( $self->pass_error );
        $self->elements( $choices );
    }   
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Accept' );
    return( $self );
}

sub add { return( shift->_qv_add( @_ ) ); }

sub as_string { return( shift->_qv_as_string( @_ ) ); }

sub elements { return( shift->_qv_elements( @_ ) ); }

sub get { return( shift->_qv_get( @_ ) ); }

sub match { return( shift->_qv_match( @_ ) ); }

sub remove { return( shift->_qv_remove( @_ ) ); }

sub sort { return( shift->_qv_sort( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Accept - Accept Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::Accept;
    my $ac = HTTP::Promise::Headers::Accept->new || 
        die( HTTP::Promise::Headers::Accept->error, "\n" );
    my $ac = HTTP::Promise::Headers::Accept->new( 'text/html, application/json, application/xml;q=0.9, */*;q=0.8' ) || 
        die( HTTP::Promise::Headers::Accept->error, "\n" );
    $ac->add( 'text/html' );
    $ac->add( 'application/json' => 0.7 );
    $h->accept( $ac->as_string ); Accept: text/html, application/json;q=0.7
    # or
    $h->accept( "$ac" );
    my $qv_elements = $ac->elements;
    my $obj = $ac->get( 'text/html' );
    # change the weight
    $obj->value( 0.3 );
    $ac->remove( 'text/html' );
    my $sorted_objects = $ac->sort;
    my $asc_sorted = $ac->sort(1);
    # Returns a Module::Generic::Array object
    my $ok = $ac->match( [qw( application/json text/html )] );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

    Accept: image/*
    Accept: text/html
    Accept: */*
    Accept: text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8

See L<rfc7231 section 5.3.2|https://tools.ietf.org/html/rfc7231#section-5.3.2> and L<rfc7231, section 5.3.5|https://tools.ietf.org/html/rfc7231#section-5.3.5>

=head1 METHODS

=head2 add

Provided with a mime type and a quality weight (q-value), and this will push a new C<HTTP::Promise::Field::QualityValue> object to the stack of elements.

=head2 as_string

Returns a string representation of the C<Accept> object.

=head2 elements

Retrieve an L<array object|Module::Generic::Array> of C<HTTP::Promise::Field::QualityValue> objects.

=head2 get

Provided with a mime type and this returns its C<HTTP::Promise::Field::QualityValue> object entry, if any. If nothing corresponding was found, it returns an empty string (false, but not C<undef>)

=head2 match

Provided with a either an array reference of proposed values, or a string, or something that stringifies, and this will return an L<array object|Module::Generic::Array> of values that match the supported one and in the order of preference.

For example, consider:

    Accept: text/html;q=0.3, application/json;q=0.7; text/plain;q=0.2

    # We prefer text/html first and application/json second
    my $ok = $ac->match( [qw( text/html application/json )] );

C<$ok> would contain 2 entries: C<application/json> and C<text/html>

    # Only take the first one
    my $mime_type = $ac->match( [qw( text/html application/json )] )->first;
    # or get it as a list
    my @ok_types = $ac->match( [qw( text/html application/json )] )->list;

=head2 remove

Provided with a mime type and this removes its C<HTTP::Promise::Field::QualityValue> object from the list of elements.

=head2 sort

This returns a sorted L<array object|Module::Generic::Array> of C<HTTP::Promise::Field::QualityValue> objects, based on their weight factor. If the option C<reverse> is provided and true, this will sort the elements in reverse order, that is in incremental order, from smallest to biggest quality factor.

For example, the following:

    text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8

will be sorted as:

    text/html, application/xhtml+xml, image/webp, application/xml;q=0.9, */*;q=0.8

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<HTTP::Accept>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
