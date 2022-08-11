##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Pool.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/27
## Modified 2022/03/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Pool;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use Nice::Try;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{host} = undef;
    $self->{port} = undef;
    $self->{sock} = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub host { return( shift->_set_get_scalar_as_object( 'host', @_ ) ); }

sub host_port
{
    my $self = shift( @_ );
    my $host = $self->host || '';
    my $port = $self->port || '';
    return( join( ':', $host, $port ) ) if( length( $host ) && length( $port ) );
    return( $host ) if( length( $host ) );
    return;
}

sub port { return( shift->_set_get_number( 'port', @_ ) ); }

sub push
{
    my $self = shift( @_ );
    my( $host, $port, $sock ) = @_;
    $self->host( $host );
    $self->port( $port );
    $self->sock( $sock );
    return( $self );
}

sub reset
{
    my $self = shift( @_ );
    $self->{host} = undef;
    $self->{port} = undef;
    return( $self );
}

sub steal
{
    my $self = shift( @_ );
    my( $host, $port ) = @_;
    my $host_port = $self->host_port;
    if( defined( $host_port ) && 
        $host_port eq "${host}:${port}" )
    {
        $self->reset;
        return( $host_port );
    }
    else
    {
        return;
    }
}

sub FREEZE
{
    my $self = CORE::shift( @_ );
    my $serialiser = CORE::shift( @_ ) // '';
    my $class = CORE::ref( $self );
    my %hash  = %$self;
    CORE::delete( @hash{ qw( sock ) } );
    # Return an array reference rather than a list so this works with Sereal and CBOR
    CORE::return( [$class, \%hash] ) if( $serialiser eq 'Sereal' || $serialiser eq 'CBOR' );
    # But Storable want a list with the first element being the serialised element
    CORE::return( $class, \%hash );
}

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Pool - HTTP Connections Cache

=head1 SYNOPSIS

    use HTTP::Promise::Pool;
    my $this = HTTP::Promise::Pool->new ||
        die( HTTP::Promise::Pool->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This modules managed a cache of HTTP connections.

=head1 METHODS

=head2 host

=head2 host_port

=head2 port

=head2 push

=head2 reset

=head2 steal

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
