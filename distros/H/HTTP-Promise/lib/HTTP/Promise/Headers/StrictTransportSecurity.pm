##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/StrictTransportSecurity.pm
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
package HTTP::Promise::Headers::StrictTransportSecurity;
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
    $self->{properties} = {};
    $self->{params} = [];
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->new_array( $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*(?<!\\)\;[[:blank:]\h]*/, "$this" )] );
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
    $self->_field_name( 'Strict-Transport-Security' );
    return( $self );
}

sub as_string { return( shift->_set_get_properties_as_string( sep => ';' ) ); }

sub include_subdomains { return( shift->_set_get_property_boolean( 'includeSubDomains', @_ ) ); }

sub max_age { return( shift->_set_get_property_number( 'max-age', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub property { return( shift->_set_get_property_value( @_, ( @_ > 1 ? { needs_quotes => 1 } : () ) ) ); }

sub property_boolean { return( shift->_set_get_property_boolean( @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub preload { return( shift->_set_get_property_boolean( 'preload', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::StrictTransportSecurity - Strict-Transport-Security Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::StrictTransportSecurity;
    my $sts = HTTP::Promise::Headers::StrictTransportSecurity->new || 
        die( HTTP::Promise::Headers::StrictTransportSecurity->error, "\n" );
    $sts->include_subdomains(1);
    $sts->max_age(63072000);
    $sts->preload(1);
    say "$sts";
    # same thing
    say $sts->as_string;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The HTTP Strict-Transport-Security response header (often abbreviated as HSTS) informs browsers that the site should only be accessed using HTTPS, and that any future attempts to access it using HTTP should automatically be converted to HTTPS.

Example:

    Strict-Transport-Security: max-age=63072000; includeSubDomains; preload

=head1 METHODS

=head2 as_string

Returns a string representation of the C<Strict-Transport-Security> object.

=head2 include_subdomains

Boolean, optional. If provided with a true value, the parameter C<includeSubDomains> will be added.

If this optional parameter is enabled, this means that this rule applies to all of the site's subdomains as well.

=head2 max_age

Integer, required value (but not enforced).

The time, in seconds, that the browser should remember that a site is only to be accessed using HTTPS.

=head2 param

Set or get an arbitrary name-value pair attribute.

=head2 params

Set or get multiple name-value parameters.

Calling this without any parameters, retrieves the associated L<hash object|Module::Generic::Hash>

=head2 preload

Boolean, optional. If provided with a true value, the parameter C<preload> will be added.

=head2 property

Sets or gets an arbitrary property.

    $h->property( community => 'UCI' );
    my $val = $h->property( 'community' );

See also L<rfc7234, section 5.2.3|https://httpwg.org/specs/rfc7234.html#rfc.section.5.2.3>

=head2 property_boolean

Sets or gets an arbitrary boolean property.

    $h->property_boolean( private_property => 1 );

=head2 properties

Returns the L<hash object|Module::Generic::hash> used as a repository of properties.

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc6797, section 6.1|https://tools.ietf.org/html/rfc6797#section-6.1> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Strict-Transport-Security>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
