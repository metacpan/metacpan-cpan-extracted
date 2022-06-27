##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/Cookie.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/07
## Modified 2022/05/07
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::Cookie;
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
    $self->{cookies} = [];
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->_is_array( $this ) ? $this : [split( /(?<!\\)\;[[:blank:]\h]*/, $this )];
        $self->cookies( $ref );
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Cookie' );
    return( $self );
}

sub as_string { return( shift->cookies->join( '; ' )->scalar ); }

sub cookies { return( shift->_set_get_array_as_object( 'cookies', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::Cookie - Cookie Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::Cookie;
    my $c = HTTP::Promise::Headers::Cookie->new( 'name=value; name2=value2; name3=value3' ) || 
        die( HTTP::Promise::Headers::Cookie->error, "\n" );
    # or
    my $c = HTTP::Promise::Headers::Cookie->new( [qw( name=value name2=value2 name3=value3 )] );
    $c->cookies->push( 'name4=value4' );
    $c->cookies->remove( 'name2=value2' );
    say "$c";
    # This would return: name=value; name3=value3; name4=value4

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

L<HTTP::Promise::Headers::Cookie> implements a simple interface to store the cookie name-value pairs sent by the user agent to the server. It uses L</cookies> which returns a L<Module::Generic::Array> to manage and contain all the cookie name-value pairs. It is up to you to provide the right cookie string.

You can and maybe should use L<Cookie::Jar> to help you manage a cookie jar and format cookies.

=head1 CONSTRUCTOR

=head2 new

Provided with an optional string or array reference and this will instantiate a new object and return it.

If a string is provided, it is expected to be properly formatted, such as:

    name=value; name2=value2; name3=value3

It will be properly split and added to L</cookies>. If an array is provided, it will be directly added to L</cookies>.

=head1 METHODS

=head2 as_string

Returns a string representation for this C<Cookie> header field.

=head2 cookies

Returns an L<array object|Module::Generic::Array> object used to contain all the cookies.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Cookie>, L<Cookie::Jar>, L<rfc6265, section 5.4|https://tools.ietf.org/html/rfc6265#section-5.4> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cookie>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
