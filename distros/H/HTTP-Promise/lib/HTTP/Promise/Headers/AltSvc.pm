##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/AltSvc.pm
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
package HTTP::Promise::Headers::AltSvc;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Headers::Generic );
    use URI::Escape::XS ();
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
        my $this = shift( @_ );
        my $params = $self->_get_args_as_hash( @_ );
        unless( ( $self->_is_array( $this ) && scalar( @$this ) == 2 ) ||
                !ref( $this ) ||
                overload::Method( $this, "''" ) )
        {
            return( $self->error( "Wrong alternate server name-value provided '$this'. I was expecting either a name=value string or an array reference with 2 elements." ) );
        }
        my $hv = $self->_is_array( $this ) ? $self->_new_hv( $this ) : $self->_parse_header_value( $this );
        return( $self->pass_error ) if( !defined( $hv ) );
        $hv->_set_get_params( $params ) if( scalar( keys( %$params ) ) );
        $hv->encode(1);
        $self->_hv( $hv );
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Alt-Svc' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( @_ ) ); }

sub alternative
{
    my $self = shift( @_ );
    if( @_ )
    {
        return( $self->error( "Bad arguments provided. Usage: \$h->alternative( \$proto, \$auth )" ) ) if( @_ > 2 );
        my( $proto, $auth ) = @_ > 1 ? @_[0,1] : $_[0];
        # need escaping?
        if( @_ == 1 )
        {
            return( $self->error( "Bad argument provided. You need to provide a protocol=authority." ) ) if( index( $proto, '=' ) == -1 );
            ( $proto, $auth ) = split( /=/, $proto, 2 );
            $proto = $self->_unescape( $proto ) if( $proto =~ /\%(?=\d{2})/ );
        }
        my $hv;
        if( $hv = $self->_hv )
        {
            $hv->value( [ $proto, $auth ] );
        }
        else
        {
            $hv = $self->_new_hv( [ $proto, $auth ] );
            $hv->encode(1);
            $self->_hv( $hv );
        }
    }
    else
    {
        my $hv = $self->_hv || return( '' );
        my $ref = $hv->value;
        return( wantarray() ? () : '' ) if( $ref->is_empty );
        return( $ref->list ) if( wantarray() );
        my( $proto, $auth ) = $ref->list;
        # $proto = $self->_escape( $proto );
        $proto = $hv->token_escape( $proto );
        return( join( '=', $proto, $auth ) );
    }
}

# This needs a protocol to be set first
sub authority { return( shift->_hv->value_data( @_ ) ); }

sub ma { return( shift->_set_get_param( ma => @_ ) ); }

sub param { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

sub persist { return( shift->_set_get_param( persist => @_ ) ); }

sub protocol
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $proto = shift( @_ );
        return( $self->error( "Value provided for protocol is empty." ) ) if( !defined( $proto ) || !length( "$proto" ) );
        my $hv = $self->_hv;
        if( $hv )
        {
            $hv->value_name( $proto );
        }
        else
        {
            $hv = $self->_new_hv( $proto );
            $self->_hv( $hv );
        }
    }
    else
    {
        my $hv = $self->_hv || return( '' );
        return( $hv->value_name );
    }
}

# As per rfc7838, section 3: <https://tools.ietf.org/html/rfc7838#section-3>
# sub _escape
# {
#     my $self = shift( @_ );
#     my $v = shift( @_ );
#     $v =~ s/([=:%]+)/sprintf("%%%02X", ord($1))/ge;
#     return( $v );
# }
sub _escape { return( URI::Escape::XS::uri_escape( $_[1] ) ); }

# sub _unescape
# {
#     my $self = shift( @_ );
#     my $v = shift( @_ );
#     $v =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
#     return( $v );
# }
sub _unescape { return( URI::Escape::XS::uri_unescape( $_[1] ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::AltSvc - AltSvc Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::AltSvc;
    my $alt = HTTP::Promise::Headers::AltSvc->new || 
        die( HTTP::Promise::Headers::AltSvc->error, "\n" );
    $alt->alternative( q{h2="new.example.org:80"} );
    $alt->alternative( 'h2', 'new.example.org:80' );
    my $def = $alt->alternative; # h2="new.example.org:80"
    $alt->ma(2592000);
    $alt->persist(1);
    $alt->authority( 'new.example.org:443' );
    $alt->protocol( 'h2' );
    say "$alt"; # stringifies
    say $alt->as_string; # same

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

    Alt-Svc: clear
    Alt-Svc: <protocol-id>=<alt-authority>

The special value clear indicates that the origin requests all alternative services for that origin to be invalidated.

C<protocol-id> is the C<ALPN> protocol identifier. Examples include h2 for HTTP/2 and h3-25 for draft 25 of the HTTP/3 protocol.

C<alt-authority> is the quoted string specifying the alternative authority which consists of an optional host override, a colon, and a mandatory port number.

    Alt-Svc: h2=":443"; ma=2592000;
    Alt-Svc: h2=":443"; ma=2592000; persist=1
    Alt-Svc: h2="alt.example.com:443", h2=":443"
    Alt-Svc: h3-25=":443"; ma=3600, h2=":443"; ma=3600

Multiple entries can be specified in a single C<Alt-Svc> header using comma as separator. In that case, early entries are considered more preferable.

You can achieve this the following way:

    my $alt1 = HTTP::Promise::Headers::AltSvc->new( q{h2="alt.example.com:443"} );
    $alt1->ma(3600);
    $alt1->persist(1);
    my $alt2 = HTTP::Promise::Headers::AltSvc->new( q{h2=":443"} );
    $alt2->ma(3600);
    my $headers = HTTP::Promise::Headers->new;
    $headers->push_header( alt_svc => "$alt1", alt_svc => "$alt2" );

=head1 CONSTRUCTOR

=head2 new

You can create a new instance of this class without passing any parameter, and set them afterward.

If you want to set parameters upon object instantiation, this takes either an array reference with 2 values (C<protocol> and C<authority>), or a string (or something that stringifies, and an optional hash or hash reference of parameters and it returns a new object.

If you provide a string, it will be parsed, so be careful what you provide, and make sure that non-ascii characters are escaped first. For example:

    my $alt = HTTP::Promise::Headers::AltSvc->new( 'w=x:y#z' );

It will be interpreted, wrongly, as C<w> being the protocol and C<x:y#z>, so instead you would need to either escape it before (with L<URI::Escape::XS> for example), or provide it as an array of 2 elements (protocol and authority), such as:

    my $alt = HTTP::Promise::Headers::AltSvc->new( ['w=x:y#z', 'new.example.org:443'] );

=head1 METHODS

=head2 alternative

Sets or gets the alternative protocol and authority.

For example:

    $h->alternative( $proto, $auth );
    my $alt = $h->alternative; # h2="alt.example.com:443"

=head2 authority

Sets or gets the authority, which is the value in the equal assignment, such as:

    h2="alt.example.com:443"

Here the authority would be C<alt.example.com:443>

    my $u = URI->new( 'https://alt.example.com' );
    $h->authority( $u->host_port );

=head2 ma

This is optional and takes a number.

The number of seconds for which the alternative service is considered fresh. If omitted, it defaults to 24 hours. Alternative service entries can be cached for up to <max-age> seconds, minus the age of the response (from the Age header). Once the cached entry expires, the client can no longer use this alternative service for new connections.

=head2 param

Set or get an arbitrary name-value pair attribute.

=head2 params

Set or get multiple name-value parameters.

Calling this without any parameters, retrieves the associated L<hash object|Module::Generic::Hash>

=head2 persist

This is optional and takes a number.

Usually cached alternative service entries are cleared on network configuration changes. Use of the persist=1 parameter requests that the entry not be deleted by such changes.

=head2 protocol

Sets or gets the protocol. For example:

    $alt->protocol( 'h2' );

Here, C<h2> is the protocol and means HTTP/2. C<h3-25> would be for draft 25 of the HTTP/3 protocol.

You can even pass unsafe characters. They will be encoded upon stringification:

    $alt->protocol( 'w=x:y#z' ); # example from rfc7838

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Alt-Svc>, L<rfc7838, section 3|https://tools.ietf.org/html/rfc7838#section-3>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
