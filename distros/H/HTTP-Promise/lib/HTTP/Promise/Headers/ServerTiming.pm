##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ServerTiming.pm
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
package HTTP::Promise::Headers::ServerTiming;
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
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $hv;
        if( index( $this, ';' ) != -1 )
        {
            $hv = $self->_parse_header_value( $this );
        }
        else
        {
            $hv = $self->_new_hv( $this );
        }
        return( $self->pass_error ) if( !defined( $hv ) );
        my $opts = $self->_get_args_as_hash( @_ );
        $hv->param( $_ => $opts->{ $_ } ) for( keys( %$opts ) );
        $self->_hv( $hv );
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Server-Timing' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( @_ ) ); }

sub desc { return( shift->_set_get_param( 'desc', @_ ) ); }

sub dur { return( shift->_set_get_param( 'dur', @_ ) ); }

sub name
{
    my $self = shift( @_ );
    my $hv = $self->_hv;
    if( @_ )
    {
        my $this = shift( @_ );
        if( $hv )
        {
            $hv->value( $this );
        }
        else
        {
            $hv = $self->_new_hv( $this );
            $self->_hv( $hv );
        }
        return( $this);
    }
    else
    {
        return( '' ) if( !$hv );
        return( $hv->value_data );
    }
}

sub param { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ServerTiming - Server-Timing Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ServerTiming;
    my $srv = HTTP::Promise::Headers::ServerTiming->new || 
        die( HTTP::Promise::Headers::ServerTiming->error, "\n" );
    $srv->name( 'cache' );
    $srv->dur(2.4);
    $srv->desc( 'Cache Read' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The Server-Timing header communicates one or more metrics and descriptions for a given request-response cycle.

Example:

    # Single metric without value
    Server-Timing: missedCache

    # Single metric with value
    Server-Timing: cpu;dur=2.4

    # Single metric with description and value
    Server-Timing: cache;desc="Cache Read";dur=23.2

    # Two metrics with value
    Server-Timing: db;dur=53, app;dur=47.2

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Server-Timing> object.

=head2 desc

Sets or gets the server timing description.

=head2 dur

Sets or gets the duration

=head2 name

Sets or gets the server timing metrics name.

=head2 param

Set or get an arbitrary name-value pair attribute.

=head2 params

Set or get multiple name-value parameters.

Calling this without any parameters, retrieves the associated L<hash object|Module::Generic::Hash>

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Server-Timing>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
