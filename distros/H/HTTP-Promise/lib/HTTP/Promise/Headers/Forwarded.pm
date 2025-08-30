##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Forwarded.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/08
## Modified 2022/05/08
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::Forwarded;
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
    $self->{params} = [];
    $self->{properties} = {};
    # Works like HTTP::Promise::Headers::CacheControl
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->_is_array( $this ) ? $this : [split( /(?<!\\)\;[[:blank:]\h]*/, "$this" )];
        my $params = $self->params;
        my $props = $self->properties;
        foreach my $pair ( @$ref )
        {
            my( $prop, $val ) = split( /=/, $pair, 2 );
            $props->{ $prop } = $val;
            $params->push( $prop );
        }
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Forwarded' );
    return( $self );
}

sub as_string { return( shift->_set_get_properties_as_string( sep => ';' ) ); }

sub by { return( shift->_set_get_property_value( 'by', @_ ) ); }

sub for { return( shift->_set_get_property_value( 'for', @_ ) ); }

sub host { return( shift->_set_get_property_value( 'host', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub proto { return( shift->_set_get_property_value( 'proto', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Forwarded - Forwarded Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::Forwarded;
    my $fwd = HTTP::Promise::Headers::Forwarded->new || 
        die( HTTP::Promise::Headers::Forwarded->error, "\n" );
    $h->by( 'secret' );
    $h->for( '192.0.2.43' );
    $h->host( 'example.com' );
    $h->proto( 'https' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The C<Forwarded> request header contains information that may be added by reverse proxy servers (load balancers, CDNs, and so on) that would otherwise be altered or lost when proxy servers are involved in the path of the request.

For example:

    Forwarded: for=192.0.2.60;proto=http;by=203.0.113.43
    # Values from multiple proxy servers can be appended using a comma
    Forwarded: for=192.0.2.43, for=198.51.100.17

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Forwarded> object.

=head2 by

This is optional.

The interface where the request came in to the proxy server. The identifier can be: 

=head2 for

This is optional.

The client that initiated the request and subsequent proxies in a chain of proxies. The identifier has the same possible values as the by directive.

=head2 host

This is optional.

The Host request header field as received by the proxy.

=head2 params

Sets or gets the L<array object|Module::Generic::Array> containing all the parameters in their proper order.

=head2 properties

Sets or gets an hash or hash reference ot property-value pairs.

=head2 proto

This is optional.

Indicates which protocol was used to make the request (typically "http" or "https").

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc7239, section 4|https://tools.ietf.org/html/rfc7239#section-4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Forwarded>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
