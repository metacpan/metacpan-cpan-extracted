##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ContentDisposition.pm
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
package HTTP::Promise::Headers::ContentDisposition;
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
    $self->{filename_charset} = undef;
    $self->{filename_lang}    = undef;
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $str = shift( @_ );
        return( $self->error( "No value was provided for Content-Disposition field." ) ) if( !defined( $str ) || !length( "$str" ) );
        my $params = $self->_get_args_as_hash( @_ );
        my $hv = $self->_parse_header_value( $str ) ||
            return( $self->pass_error );
        $hv->params( $params ) if( scalar( keys( %$params ) ) );
        $self->_hv( $hv );
    }
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Disposition' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( [qw( name filename )] ) ); }

sub disposition
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $dispo = shift( @_ ) || return( $self->error( "No content disposition was provided." ) );
        my $hv = $self->_hv;
        if( $hv )
        {
            $hv->value( $dispo );
        }
        else
        {
            $hv = $self->_new_hv( $dispo ) || return( $self->pass_error );
            $self->_hv( $hv );
        }
        return( $dispo );
    }
    else
    {
        # No header value object, means there is just nothing set yet
        my $hv = $self->_hv || return( '' );
        return( $hv->value_data );
    }
}

sub filename
{
    my $self = shift( @_ );
    if( @_ )
    {
        my( $fname, $lang ) = @_;
        if( !defined( $fname ) )
        {
            $self->params->delete( 'filename' );
            $self->params->delete( 'filename*' );
        }
        else
        {
            $lang //= $self->filename_lang;
            if( my $enc = $self->_filename_encode( $fname, $lang ) )
            {
                $self->_set_get_param( 'filename*' => $enc ) || return( $self->pass_error );
            }
            else
            {
                $self->_set_get_qparam( filename => $fname );
            }
        }
    }
    else
    {
        my $v = $self->_set_get_qparam( 'filename' );
        if( defined( $v ) && length( $v ) )
        {
            # decode if necessary
            my( $f_charset, $f_lang );
            ( $v, $f_charset, $f_lang ) = $self->_filename_decode( $v );
            $self->filename_charset( $f_charset );
            $self->filename_lang( $f_lang );
        }
        elsif( $v = $self->_set_get_param( 'filename*' ) )
        {
            my( $f_charset, $f_lang );
            ( $v, $f_charset, $f_lang ) = $self->_filename_decode( $v );
            $self->filename_charset( $f_charset );
            $self->filename_lang( $f_lang );
        }
        return( $v );
    }
}

sub filename_charset
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $v = shift( @_ );
        if( !defined( $v ) )
        {
            return( $self->_set_get_scalar_as_object( 'filename_charset', $v ) );
        }
        return( $self->error( "Only supported charset is 'utf-8'." ) ) if( lc( $v ) ne 'utf-8' && lc( $v ) ne 'utf8' );
        # Convenience
        $v = 'utf-8' if( lc( $v ) eq 'utf8' );
        $v = uc( $v );
        return( $self->_set_get_scalar_as_object( 'filename_charset', $v ) );
    }
    return( $self->_set_get_scalar_as_object( 'filename_charset' ) );
}

sub filename_lang { return( shift->_set_get_scalar_as_object( 'filename_lang', @_ ) ); }

sub name { return( shift->_set_get_param( name => @_ ) ); }

sub param { return( shift->_set_get_param( @_ ) ); }

sub params { return( shift->_set_get_params( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ContentDisposition - Content-Disposition Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ContentDisposition;
    my $cd = HTTP::Promise::Headers::ContentDisposition->new || 
        die( HTTP::Promise::Headers::ContentDisposition->error, "\n" );
    my $dispo = $cd->disposition;
    # For example, attachment
    $cd->disposition( 'inline' );
    $cd->filename( 'some-file.txt' );
    $cd->disposition( 'form-data' );
    $cd->name( 'someField' );
    my $name = $cd->name;
    # Same thing
    my $name = $cd->param( 'name' );
    $cd->params( name => 'someField', filename => 'some-file.txt' );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

    Content-Disposition: inline
    Content-Disposition: attachment
    Content-Disposition: attachment; filename="filename.jpg"
    Content-Disposition: form-data; name="fieldName"
    Content-Disposition: form-data; name="fieldName"; filename="filename.jpg"

=head1 METHODS

=head2 as_string

Returns a string representation of the Content-Disposition object.

=head2 disposition

Sets or gets the type of C<Content-Disposition> this is. For example: C<attachment>, C<form-data>

=head2 name

Is followed by a string containing the name of the HTML field in the form that the content of this subpart refers to. When dealing with multiple files in the same field (for example, the multiple attribute of an <input type="file"> element), there can be several subparts with the same name.

A name with a value of '_charset_' indicates that the part is not an HTML field, but the default charset to use for parts without explicit charset information.

=head2 filename

Without any argument, this returns the string containing the original name of the file transmitted. The C<filename> is always optional and must not be used blindly by the application: path information should be stripped, and conversion to the server file system rules should be done. This parameter provides mostly indicative information. When used in combination with C<Content-Disposition: attachment>, it is used as the default C<filename> for an eventual "Save As" dialog presented to the user.

If the property C<filename*> is set instead, then it will be decoded and used instead, and the value for L</filename_charset> and L</filename_lang> will be set.

When setting the filename value, this takes an optional language iso 639 code (see L<rfc5987|https://tools.ietf.org/html/rfc5987> and L<rfc2231|https://tools.ietf.org/html/rfc2231>).
If the filename contains non ascii characters, it will be automatically encoded according to L<rfc5987|https://tools.ietf.org/html/rfc5987>. and the property C<filename*> set instead. That property, by rfc standard, takes precedence over the C<filename> one.

The language provided, if any, will be used then.

For example:

    $h->disposition( 'form-data' );
    $h->name( 'fileField' );
    $h->filename( q{file.txt} );
    say "$h";
    # form-data; name="fileField"; filename="file.txt"

    $h->disposition( 'form-data' );
    $h->name( 'fileField' );
    $h->filename( q{ファイル.txt} );
    say "$h";
    # form-data; name="fileField"; filename*="UTF-8''%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt"
 
    $h->disposition( 'form-data' );
    $h->name( 'fileField' );
    $h->filename( q{ファイル.txt}, 'ja-JP' );
    say "$h";
    # form-data; name="fileField"; filename*="UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt"

    # Using default value
    $h->filename_lang( 'ja-JP' );
    $h->disposition( 'form-data' );
    $h->name( 'fileField' );
    $h->filename( q{ファイル.txt} );
    say "$h";
    # form-data; name="fileField"; filename*="UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt"

    $headers->header( Content_Disposition => "$h" );

The C<Content-Disposition> header value would then contain a property C<filename*> (with the trailing wildcard).

See also L<HTTP::Promise::Headers/decode_filename> and L<HTTP::Promise::Headers/encode_filename> which are used to decode and encode filenames.

=head2 filename_charset

Sets or gets the encoded filename charset.

This is used when the filename contains non-ascii characters, such as Japanese, Korean, or Cyrillic.
Although theoretically one can set any character set, by design this only accepts C<UTF-8> (case insensitive).

This is set automatically when calling L</filename>. You actually need to call L</filename> first to have a value set.

Returns a L<scalar object|Module::Generic::Scalar> containing the filename charset.

=head2 filename_lang

Sets or gets the encoded filename language. This takes an iso 639 language code (see L<rfc1766|https://tools.ietf.org/html/rfc1766>).

This is set automatically when calling L</filename>. You actually need to call L</filename> first to have a value set.

Returns a L<scalar object|Module::Generic::Scalar> containing the filename language.

=head2 param

Sets or gets an arbitrary C<Content-Disposition> property.

Note that if you use this, you bypass other specialised method who do some additional processing, so be mindful.

=head2 params

Sets or gets multiple arbitrary C<Content-Disposition> properties at once.

If called without any arguments, this returns the L<hash object|Module::Generic::Hash> used to store the C<Content-Disposition> properties.

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See L<rfc6266, section 4|https://tools.ietf.org/html/rfc6266#section-4>, L<rfc7578, section 4.2|https://tools.ietf.org/html/rfc7578#section-4.2> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Disposition>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
