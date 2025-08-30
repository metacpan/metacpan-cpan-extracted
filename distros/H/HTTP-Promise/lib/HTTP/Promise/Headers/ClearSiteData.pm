##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ClearSiteData.pm
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
package HTTP::Promise::Headers::ClearSiteData;
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
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->new_array( $self->_is_array( $this ) ? $this : [$self->_qstring_split( "$this" )] );
        $self->params( $ref );
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Clear-Site-Data' );
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $params = $self->params;
    return( $params->is_empty ? '' : $self->_qstring_join( @$params ) );
}

sub cache { return( shift->_set_get_property_boolean( 'cache', @_ ) ); }

sub cookies { return( shift->_set_get_property_boolean( 'cookies', @_ ) ); }

sub execution_contexts { return( shift->_set_get_property_boolean( 'executionContexts', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub storage { return( shift->_set_get_property_boolean( 'storage', @_ ) ); }

sub wildcard { return( shift->_set_get_property_boolean( '*', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ClearSiteData - Clear-Site-Data Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ClearSiteData;
    my $csd = HTTP::Promise::Headers::ClearSiteData->new || 
        die( HTTP::Promise::Headers::ClearSiteData->error, "\n" );
    my $h = HTTP::Promise::Headers::ClearSiteData->new;
    # Single directive
    # Clear-Site-Data: "cache"
    $h->cache(1);

    # Multiple directives (comma separated)
    # Clear-Site-Data: "cache", "cookies"
    $h->cache(1);
    $h->cookies(1);

    # Wild card
    # Clear-Site-Data: "*"
    $h->params('*');

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following is an extract from Mozilla documentation.

The C<Clear-Site-Data> header clears browsing data (cookies, storage, cache) associated with the requesting website. It allows web developers to have more control over the data stored by a client browser for their origins.

Example:

    Clear-Site-Data: "cache", "cookies", "storage", "executionContexts"

=head1 METHODS

=head2 cache

Sets or gets the property C<cache>

Indicates that the server wishes to remove locally cached data (the browser cache, see HTTP caching) for the origin of the response URL. Depending on the browser, this might also clear out things like pre-rendered pages, script caches, WebGL shader caches, or address bar suggestions.

=head2 cookies

Sets or gets the property C<cookies>

Indicates that the server wishes to remove all cookies for the origin of the response URL. HTTP authentication credentials are also cleared out. This affects the entire registered domain, including subdomains. So https://example.com as well as https://stage.example.com, will have cookies cleared.

=head2 execution_contexts

Sets or gets the property C<executionContexts>

Indicates that the server wishes to reload all browsing contexts for the origin of the response (Location.reload).

=head2 params

Returns the L<array object|Module::Generic::Array> used by this header field object containing all the properties set.

=head2 properties

Returns the L<hash object|Module::Generic::hash> used as a repository of properties.

=head2 storage

Sets or gets the property C<storage>

Indicates that the server wishes to remove all DOM storage for the origin of the response URL. 

=head2 wildcard

Sets or gets the special property C<*> (wildcard)

Indicates that the server wishes to clear all types of data for the origin of the response. If more data types are added in future versions of this header, they will also be covered by it.

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
