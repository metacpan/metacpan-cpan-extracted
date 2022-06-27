##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ContentType.pm
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
package HTTP::Promise::Headers::ContentType;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Headers::Generic );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $str = shift( @_ );
        return( $self->error( "No value was provided for Content-Type field." ) ) if( !defined( $str ) || !length( "$str" ) );
        my $params = $self->_get_args_as_hash( @_ );
        my $hv = $self->_parse_header_value( $str ) ||
            return( $self->pass_error );
        $hv->param( $_ => $params->{ $_ } ) for( keys( %$params ) );
        $self->_hv( $hv );
    }
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Type' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( @_ ) ); }

sub boundary { return( shift->_set_get_param( boundary => @_ ) ); }

sub charset { return( shift->_set_get_param( charset => @_ ) ); }

sub make_boundary { return( shift->_make_boundary ); }

sub param { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $mime = shift( @_ ) || return( $self->error( "No mime type was provided." ) );
        my $hv = $self->_new_hv( $mime ) || return( $self->pass_error );
        $self->_hv( $hv );
        return( $mime );
    }
    else
    {
        # No header value object, means there is just nothing set yet
        my $hv = $self->_hv || return( '' );
        return( $hv->value_data );
    }
}

# Basically same thing as type()
sub value { return( shift->_set_get_value( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ContentType - Content-Type Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ContentType;
    my $ct = HTTP::Promise::Headers::ContentType->new || 
        die( HTTP::Promise::Headers::ContentType->error, "\n" );
    $ct->value( 'text/plain' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

    Content-Type: text/html; charset=UTF-8
    Content-Type: application/octet-stream
    Content-Type: multipart/form-data; boundary=something
    Content-Type: application/x-www-form-urlencoded
    # Used with 206 Partial Content; rfc7233, section 5.4.1
    Content-Type: multipart/byteranges

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Content-Type> object.

=head2 boundary

Sets or gets the boundary used for C<multipart/form-data>.

If the value is C<undef>, it will be removed.

=head2 charset

Sets or gets the charset associated with this C<Content-Type>

=head2 make_boundary

Returns a unique auto-generated boundary. Such auto-generated boundary is actually an uuid.

=head2 param

Set or get an arbitrary name-value pair attribute.

=head2 params

Set or get multiple name-value parameters.

Calling this without any parameters, retrieves the associated L<hash object|Module::Generic::Hash>

=head2 type

Sets or gets the mime-type for this field.

=head2 value

Sets or gets the mime-type for this C<Content-Type>. This is effectively the same as L</type>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc7233, section 4.1|https://tools.ietf.org/html/rfc7233#section-4.1>, L<rfc7231, section 3.1.1.5|https://tools.ietf.org/html/rfc7231#section-3.1.1.5> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types>, and L<this Mozilla documentation too|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

L<HTTP::Promise>, L<HTTP::Promise::Headers>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
