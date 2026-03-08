##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/Generic.pm
## Version v0.1.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/02
## All rights reserved.
##
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Headers::Generic;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use Encode ();
    use Mail::Make::Exception;
    use URI::Escape::XS ();
    use overload (
        '""'   => 'as_string',
        'bool' => sub{1},
    );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( @_ ) ); }

sub field_name { return( shift->_set_get_scalar( '_field_name', @_ ) ); }

sub param  { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

sub value  { return( shift->_set_get_scalar( '_value', @_ ) ); }

sub _field_name { return( shift->_set_get_scalar( '_field_name', @_ ) ); }

# rfc2231 filename decoding
# Accepts UTF-8'lang'encoded or plain value
# Returns decoded string
sub _filename_decode
{
    my $self  = shift( @_ );
    my $fname = shift( @_ );
    return( $fname ) if( !defined( $fname ) || !length( $fname ) );
    # rfc2231 extended notation: charset'language'encoded
    if( $fname =~ /^([A-Za-z0-9\-]+)'([^']*)'(.+)$/ )
    {
        my( $charset, $lang, $encoded ) = ( $1, $2, $3 );
        my $decoded = URI::Escape::XS::uri_unescape( $encoded );
        # try-catch
        local $@;
        eval
        {
            $decoded = Encode::decode( $charset, $decoded );
        };
        if( $@ )
        {
            return( $fname );
        }
        return( wantarray() ? ( $decoded, $charset, $lang ) : $decoded );
    }
    return( wantarray() ? ( $fname, undef, undef ) : $fname );
}

# rfc2231 / rfc5987 filename encoding
# Returns encoded string such as UTF-8''Yamato%2CInc-Logo.png
# Returns undef if no encoding needed (pure ASCII, no special chars)
sub _filename_encode
{
    my $self  = shift( @_ );
    my $fname = shift( @_ );
    my $lang  = shift( @_ );
    # Contains non-ASCII or RFC 2045 special chars that require quoting/encoding
    if( $fname =~ /[^\x20-\x7E]/ || $fname =~ /[()<>@,;:\\"\/\[\]?=]/ )
    {
        $lang = '' if( !defined( $lang ) );
        my $encoded = URI::Escape::XS::uri_escape( Encode::encode( 'UTF-8', $fname ) );
        return( sprintf( "UTF-8'%s'%s", $lang, $encoded ) );
    }
    # Pure safe ASCII — caller should use simple quoting if needed
    return( undef );
}

sub _hv { return( shift->_set_get_object_without_init( '_hv', 'Module::Generic::HeaderValue', @_ ) ); }

sub _hv_as_string
{
    my $self = shift( @_ );
    my $hv   = $self->_hv;
    return( '' ) if( !$hv );
    return( $hv->as_string( @_ ) );
}

sub _new_hv
{
    my $self = shift( @_ );
    $self->_load_class( 'Module::Generic::HeaderValue' ) || return( $self->pass_error );
    return( Module::Generic::HeaderValue->new( @_ ) );
}

sub _parse_header_value
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "No header value was provided to parse." ) )
        if( !defined( $this ) || !length( "$this" ) );
    $self->_load_class( 'Module::Generic::HeaderValue' ) || return( $self->pass_error );
    my $hv = Module::Generic::HeaderValue->new_from_header( $this, @_ ) ||
        return( $self->pass_error( Module::Generic::HeaderValue->error ) );
    return( $hv );
}

sub _set_get_param
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $hv   = $self->_hv;
    return( '' ) if( !scalar( @_ ) && !$hv );
    return( $self->error( "Header value object (Module::Generic::HeaderValue) could not be found!" ) ) if( !$hv );
    if( @_ )
    {
        $hv->param( $name => shift( @_ ) );
    }
    return( $hv->param( $name ) );
}

sub _set_get_params
{
    my $self   = shift( @_ );
    my $hv     = $self->_hv || return( $self->error( "Header value object could not be found!" ) );
    my $params = $hv->params;
    if( @_ )
    {
        while( my( $n, $v ) = splice( @_, 0, 2 ) )
        {
            $params->set( $n => $v );
        }
    }
    else
    {
        return( $params );
    }
}

# Same as _set_get_param but wraps value in double quotes on store,
# strips them on retrieve
sub _set_get_qparam
{
    my $self = shift( @_ );
    my $name = shift( @_ ) || return( $self->error( "No parameter name was provided." ) );
    my $hv   = $self->_hv || return( $self->error( "Header value object could not be found!" ) );
    my $v;
    if( @_ )
    {
        $v = shift( @_ );
        $v =~ s/^\"//;
        $v =~ s/(?<!\\)\"$//;
        $hv->param( $name => qq{"${v}"} );
    }
    else
    {
        $v = $hv->param( $name );
        return( '' ) if( !defined( $v ) || !length( "$v" ) );
        $v =~ s/^\"//;
        $v =~ s/(?<!\\)\"$//;
    }
    return( $v );
}

sub _set_get_value
{
    my $self = shift( @_ );
    my $hv   = $self->_hv;
    if( @_ )
    {
        $hv->value( shift( @_ ) );
    }
    return( $hv->value_data );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::Generic - Base Class for Mail::Make Header Objects

=head1 SYNOPSIS

    package Mail::Make::Headers::MyHeader;
    use parent qw( Mail::Make::Headers::Generic );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This is the base class for all typed header objects in L<Mail::Make>. It provides shared infrastructure for header value parsing, parameter handling, RFC 2231 filename encoding/decoding, and stringification.

=head1 METHODS

=head2 as_string

Returns the header field value as a string, suitable for inclusion in a mail message.

=head2 field_name

Sets or gets the header field name (e.g. C<Content-Type>).

=head2 param( $name [, $value ] )

Sets or gets a named parameter on the header value. For example the C<charset> parameter of a C<Content-Type> field.

=head2 params( $name => $value, ... )

Sets multiple parameters at once. With no arguments, returns the parameter hash object.

=head2 value( [ $value ] )

Sets or gets the main header value (the part before the first C<;>).

=head1 PRIVATE METHODS

=head2 _filename_encode( $filename [, $language ] )

Encodes C<$filename> using RFC 2231 / RFC 5987 if it contains non-ASCII characters or RFC 2045 special characters (such as commas). Returns the encoded string C<UTF-8'lang'percent-encoded>, or C<undef> if no encoding was necessary.

=head2 _filename_decode( $value )

Decodes an RFC 2231 encoded filename value. In list context returns C<( $decoded, $charset, $language )>. In scalar context returns just the decoded filename. If decoding is not required the original value is returned unchanged.

=head2 _hv

Sets or gets the underlying L<Module::Generic::HeaderValue> object.

=head2 _hv_as_string

Returns the stringified form of the L<Module::Generic::HeaderValue> object, or an empty string if none is set.

=head2 _new_hv( $string )

Instantiates a new L<Module::Generic::HeaderValue> from C<$string>.

=head2 _parse_header_value( $string )

Parses C<$string> as a structured header value using L<Module::Generic::HeaderValue/new_from_header> and returns the resulting object.

=head2 _set_get_param( $name [, $value ] )

Low-level parameter accessor, delegates to the internal L<Module::Generic::HeaderValue> object.

=head2 _set_get_params( $name => $value, ... )

Low-level multi-parameter accessor.

=head2 _set_get_qparam( $name [, $value ] )

Like L</_set_get_param> but stores the value surrounded by double quotes and strips them on retrieval. Used for C<filename=> parameters.

=head2 _set_get_value( [ $value ] )

Low-level main-value accessor.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Headers>, L<Mail::Make::Headers::ContentType>, L<Mail::Make::Headers::ContentDisposition>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
