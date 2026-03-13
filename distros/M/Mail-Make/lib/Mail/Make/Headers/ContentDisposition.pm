##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/ContentDisposition.pm
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
package Mail::Make::Headers::ContentDisposition;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Mail::Make::Headers::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $VALID_DISPOSITIONS );
    use Mail::Make::Exception;
    our $EXCEPTION_CLASS      = 'Mail::Make::Exception';
    our $VALID_DISPOSITIONS   = qr/^(?:inline|attachment|form-data)$/i;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{filename_charset} = undef;
    $self->{filename_lang}    = undef;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    my $disposition = shift( @_ );
    return( $self->error( "No value was provided for Content-Disposition field." ) )
        if( !defined( $disposition ) || !length( "$disposition" ) );
    my $params = $self->_get_args_as_hash( @_ );
    my $debug = delete( $params->{debug} );
    $self->debug( $debug );
    $self->disposition( $disposition, ( scalar( %$params ) ? %$params : () ) ) || return( $self->pass_error );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Disposition' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( [qw( filename )] ) ); }

sub disposition
{
    my $self  = shift( @_ );
    if( @_ )
    {
        my $dispo = shift( @_ ) || return( $self->error( "No content disposition was provided." ) );
        unless( $dispo =~ $VALID_DISPOSITIONS )
        {
            return( $self->error( "Invalid disposition '$dispo': must be one of inline, attachment, form-data." ) );
        }
        my $params = $self->_get_args_as_hash( @_ );
        $dispo = lc( $dispo );
        my $hv = $self->_hv;
        if( $hv )
        {
            $hv->value( $dispo );
        }
        else
        {
            $hv = $self->_parse_header_value( $dispo ) || return( $self->pass_error );
            $self->_hv( $hv );
        }
        $hv->params( $params ) if( scalar( keys( %$params ) ) );
        return( $dispo );
    }
    else
    {
        my $hv = $self->_hv || return( '' );
        return( $hv->value_data );
    }
}

# Sets or gets the filename parameter.
# On assignment, applies RFC 2231 encoding automatically when the filename
# contains non-ASCII or RFC 2045 special characters (including commas).
# This is the fix for the MIME::Entity silent failure bug.
sub filename
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $fname, $lang ) = @_;
        if( !defined( $fname ) )
        {
            # Remove both the plain and extended forms
            my $hv = $self->_hv;
            if( $hv )
            {
                $hv->params->delete( 'filename' );
                $hv->params->delete( 'filename*' );
            }
            return( $self );
        }
        $lang //= $self->filename_lang;
        my $encoded = $self->_filename_encode( $fname, $lang );
        if( defined( $encoded ) )
        {
            # Non-trivial filename: use RFC 2231 extended notation (filename*)
            $self->_set_get_param( 'filename*' => $encoded ) || return( $self->pass_error );
        }
        else
        {
            # Pure safe ASCII: use plain quoted filename
            $self->_set_get_qparam( filename => $fname );
        }
        return( $fname );
    }
    else
    {
        # Prefer filename* (RFC 2231) over plain filename
        my $v = $self->_set_get_param( 'filename*' );
        if( defined( $v ) && length( "$v" ) )
        {
            my( $decoded, $charset, $lang ) = $self->_filename_decode( $v );
            $self->filename_charset( $charset ) if( defined( $charset ) );
            $self->filename_lang( $lang )       if( defined( $lang ) );
            return( $decoded );
        }
        $v = $self->_set_get_qparam( 'filename' );
        return( $v );
    }
}

sub filename_charset
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( defined( $v ) && length( $v ) )
        {
            if( lc( $v ) ne 'utf-8' && lc( $v ) ne 'utf8' )
            {
                return( $self->error( "Only 'utf-8' is supported as filename charset." ) );
            }
            $v = 'UTF-8';
        }
        return( $self->_set_get_scalar_as_object( 'filename_charset', $v ) );
    }
    return( $self->_set_get_scalar_as_object( 'filename_charset' ) );
}

sub filename_lang { return( shift->_set_get_scalar_as_object( 'filename_lang', @_ ) ); }

sub name { return( shift->_set_get_param( name => @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::ContentDisposition - Content-Disposition Header Field Object

=head1 SYNOPSIS

    use Mail::Make::Headers::ContentDisposition;

    my $cd = Mail::Make::Headers::ContentDisposition->new( 'inline' ) ||
        die( Mail::Make::Headers::ContentDisposition->error );
    $cd->filename( 'Yamato,Inc-Logo.png' );
    print "$cd";
    # inline; filename*=UTF-8''Yamato%2CInc-Logo.png

    # Pure ASCII filename - plain quoting used instead
    $cd->filename( 'logo.png' );
    print "$cd";
    # inline; filename="logo.png"

    # With language hint for RFC 2231
    $cd->filename( 'ファイル.txt', 'ja-JP' );
    print "$cd";
    # inline; filename*=UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Typed object for the C<Content-Disposition> mail header field.

The key improvement over L<MIME::Entity> / L<Mail::Field> is the L</filename> method: when the filename contains special RFC 2045 characters (including commas) or non-ASCII characters, it automatically encodes the value using RFC 2231 extended notation (C<filename*>), instead of silently producing a malformed header that corrupts the entire message.

=head1 METHODS

=head2 new( $disposition [, %params ] )

Instantiates a new object. C<$disposition> must be one of C<inline>, C<attachment>, or C<form-data>.

=head2 as_string

Returns the complete header field value as a string, including all parameters.

=head2 disposition( [ $disposition ] )

Sets or gets the disposition type. Validates that the value is one of C<inline>, C<attachment>, or C<form-data>. Returns an error otherwise.

=head2 filename( [ $filename [, $language ] ] )

Sets or gets the filename parameter. This method is RFC 2231 aware:

=over 4

=item *

If C<$filename> contains non-ASCII characters or RFC 2045 special characters (such as C<,>, C<(>, C<)>, C<@>, etc.), it encodes the value as C<filename*=UTF-8'language'percent-encoded> and sets C<filename*> instead of C<filename>.

=item *

Otherwise, the filename is stored as a plain quoted C<filename=> parameter.

=item *

On retrieval, C<filename*> takes precedence over C<filename>. The value is decoded and returned as a plain Perl string.

=back

Setting to C<undef> removes both C<filename> and C<filename*>.

=head2 filename_charset

Returns the charset used during the last RFC 2231 decode operation. Set automatically by L</filename>. Read-only in normal usage; only C<utf-8> is accepted if set explicitly.

=head2 filename_lang

Sets or gets the default language tag (RFC 1766 / ISO 639) used when encoding filenames with RFC 2231. For example C<ja-JP>.

=head2 name( [ $name ] )

Sets or gets the C<name=> parameter, used for C<form-data> dispositions.

=head2 param( $name [, $value ] )

Low-level access to an arbitrary parameter.

=head2 params( $name => $value, ... )

Sets multiple parameters at once. With no arguments, returns the parameter hash object.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Headers>, L<Mail::Make::Headers::Generic>, L<Mail::Make::Headers::ContentType>

RFC 2183, RFC 2231, RFC 5987

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
