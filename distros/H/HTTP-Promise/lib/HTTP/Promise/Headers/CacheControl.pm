##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/CacheControl.pm
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
package HTTP::Promise::Headers::CacheControl;
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
    $self->{_needs_quotes} = {};
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->new_array( $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*(?<!\\)\,[[:blank:]\h]*/, "$this" )] );
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
    $self->_field_name( 'Cache-Control' );
    return( $self );
}

sub as_string { return( shift->_set_get_properties_as_string ); }

sub immutable { return( shift->_set_get_property_boolean( 'immutable', @_ ) ); }

sub max_age { return( shift->_set_get_property_number( 'max-age', @_ ) ); }

sub max_stale { return( shift->_set_get_property_number( 'max-stale', @_ ) ); }

sub min_fresh { return( shift->_set_get_property_number( 'min-fresh', @_ ) ); }

sub must_revalidate { return( shift->_set_get_property_boolean( 'must-revalidate', @_ ) ); }

sub must_understand { return( shift->_set_get_property_boolean( 'must-understand', @_ ) ); }

sub no_cache { return( shift->_set_get_property_boolean( 'no-cache', @_ ) ); }

sub no_store { return( shift->_set_get_property_boolean( 'no-store', @_ ) ); }

sub no_transform { return( shift->_set_get_property_boolean( 'no-transform', @_ ) ); }

sub only_if_cached { return( shift->_set_get_property_boolean( 'only-if-cached', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub property { return( shift->_set_get_property_value( @_, ( @_ > 1 ? { needs_quotes => 1 } : () ) ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub private { return( shift->_set_get_property_boolean( 'private', @_ ) ); }

sub proxy_revalidate { return( shift->_set_get_property_boolean( 'proxy-revalidate', @_ ) ); }

sub public { return( shift->_set_get_property_boolean( 'public', @_ ) ); }

sub s_maxage { return( shift->_set_get_property_number( 's-maxage', @_ ) ); }

sub stale_if_error { return( shift->_set_get_property_number( 'stale-if-error', @_ ) ); }

sub stale_while_revalidate { return( shift->_set_get_property_number( 'stale-while-revalidate', @_ ) ); }

sub _needs_quotes { return( shift->_set_get_hash_as_mix_object( '_needs_quotes', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::CacheControl - Cache-Control Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::CacheControl;
    my $cc = HTTP::Promise::Headers::CacheControl->new || 
        die( HTTP::Promise::Headers::CacheControl->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The C<Cache-Control> HTTP header field holds directives (instructions) — in both requests and responses — that control caching in browsers and shared caches (e.g. Proxies, CDNs).

=head1 METHODS

The following known properties can be set with those methods. If you want to remove a property, simply set a value of C<undef>.

When you set a new property, it will be added at the end.

If you want to set or get non-standard property, use the L</property> method

This class keeps track of the order of the properties set to ensure repeatability and predictability.

=head2 as_string

Returns a string representation of the C<Cache-Control> object.

=head2 immutable

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<immutable> response directive indicates that the response will not be updated while it's fresh.

    Cache-Control: public, max-age=604800, immutable

=head2 max_age

If a value is provided, this takes an integer, and set the property to that value. If it exists already, it simply change the property value, otherwise it adds it at the end.

When no value is provided, this returns the numeric value of that property if it exists, or an empty string otherwise.

The max-age=N response directive indicates that the response remains fresh until N seconds after the response is generated.

    Cache-Control: max-age=604800

This is used in request and in response.

=head2 max_stale

If a value is provided, this takes an integer, and set the property to that value. If it exists already, it simply change the property value, otherwise it adds it at the end.

When no value is provided, this returns the numeric value of that property if it exists, or an empty string otherwise.

The C<max-stale=N> request directive indicates that the client allows a stored response that is stale within N seconds.

    Cache-Control: max-stale=3600

=head2 min_fresh

The C<min-fresh=N> request directive indicates that the client allows a stored response that is fresh for at least N seconds.

    Cache-Control: min-fresh=600

=head2 must_revalidate

If a value is provided, this takes an integer, and set the property to that value. If it exists already, it simply change the property value, otherwise it adds it at the end.

When no value is provided, this returns the numeric value of that property if it exists, or an empty string otherwise.

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<must-revalidate> response directive indicates that the response can be stored in caches and can be reused while fresh. If the response becomes stale, it must be validated with the origin server before reuse.

Typically, C<must-revalidate> is used with max-age.

    Cache-Control: max-age=604800, must-revalidate

=head2 must_understand

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The must-understand response directive indicates that a cache should store the response only if it understands the requirements for caching based on status code.

must-understand should be coupled with no-store for fallback behavior.

    Cache-Control: must-understand, no-store

=head2 no_cache

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<no-cache> response directive indicates that the response can be stored in caches, but the response must be validated with the origin server before each reuse, even when the cache is disconnected from the origin server.

    Cache-Control: no-cache

This is used in request and in response.

=head2 no_store

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<no-store> response directive indicates that any caches of any kind (private or shared) should not store this response.

    Cache-Control: no-store

This is used in request and in response.

=head2 no_transform

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

Some intermediaries transform content for various reasons. For example, some convert images to reduce transfer size. In some cases, this is undesirable for the content provider.

C<no-transform> indicates that any intermediary (regardless of whether it implements a cache) shouldn't transform the response contents.

=head2 only_if_cached

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The client indicates that cache should obtain an already-cached response. If a cache has stored a response, it's reused.

=head2 params

Returns the L<array object|Module::Generic::Array> used by this header field object containing all the properties set.

=head2 private

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<private> response directive indicates that the response can be stored only in a private cache (e.g. local caches in browsers).

    Cache-Control: private

=head2 property

Sets or gets an arbitrary property.

    $h->property( community => 'UCI' );
    my $val = $h->property( 'community' );

See also L<rfc7234, section 5.2.3|https://httpwg.org/specs/rfc7234.html#rfc.section.5.2.3>

=head2 properties

Returns the L<hash object|Module::Generic::hash> used as a repository of properties.

=head2 proxy_revalidate

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<proxy-revalidate> response directive is the equivalent of must-revalidate, but specifically for shared caches only.

=head2 public

This takes a boolean value. When the value is true, this property is set if it does not already exist, and if false, it is removed.

If no value is provided, it returns true if the property is already set and false if it is not.

The C<public> response directive indicates that the response can be stored in a shared cache. Responses for requests with Authorization header fields must not be stored in a shared cache; however, the public directive will cause such responses to be stored in a shared cache.

    Cache-Control: public

=head2 s_maxage

The C<s-maxage> response directive also indicates how long the response is fresh for (similar to max-age) — but it is specific to shared caches, and they will ignore max-age when it is present.

    Cache-Control: s-maxage=604800

=head2 stale_if_error

The C<stale-if-error> response directive indicates that the cache can reuse a stale response when an origin server responds with an error (500, 502, 503, or 504).

    Cache-Control: max-age=604800, stale-if-error=86400

=head2 stale_while_revalidate

The C<stale-while-revalidate> response directive indicates that the cache could reuse a stale response while it revalidates it to a cache.

    Cache-Control: max-age=604800, stale-while-revalidate=86400

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See L<rfc7234, section 5.2|https://tools.ietf.org/html/rfc7234#section-5.2>, L<rfc8246, section 2|https://tools.ietf.org/html/rfc8246#section-2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
