##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/KeepAlive.pm
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
package HTTP::Promise::Headers::KeepAlive;
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
    $self->{params} = [];
    $self->{properties} = {};
    # Works like HTTP::Promise::Headers::CacheControl
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*\,[[:blank:]\h]*/, "$this" )];
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

sub as_string { return( shift->_set_get_properties_as_string ); }

sub max { return( shift->_set_get_property_number( 'max', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub timeout { return( shift->_set_get_property_number( 'timeout', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::KeepAlive - Keep Alive Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::KeepAlive;
    my $keep = HTTP::Promise::Headers::KeepAlive->new || 
        die( HTTP::Promise::Headers::KeepAlive->error, "\n" );
    $keep->max(1000);
    $keep->timeout(10);

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The Keep-Alive general header allows the sender to hint about how the connection may be used to set a timeout and a maximum amount of requests.

For example response containing a Keep-Alive header:

    HTTP/1.1 200 OK
    Connection: Keep-Alive
    Content-Encoding: gzip
    Content-Type: text/html; charset=utf-8
    Date: Thu, 11 Aug 2016 15:23:13 GMT
    Keep-Alive: timeout=5, max=1000
    Last-Modified: Mon, 25 Jul 2016 04:32:39 GMT
    Server: Apache

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Keep-Alive> object.

=head2 max

An integer that is the maximum number of requests that can be sent on this connection before closing it.

=head2 params

Returns the L<array object|Module::Generic::Array> used by this header field object containing all the properties set.

=head2 properties

Returns the L<hash object|Module::Generic::hash> used as a repository of properties.

=head2 timeout

An integer that is the time in seconds that the host will allow an idle connection to remain open before it is closed.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc7230, section A.1.2|https://tools.ietf.org/html/rfc7230#section-A.1.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
