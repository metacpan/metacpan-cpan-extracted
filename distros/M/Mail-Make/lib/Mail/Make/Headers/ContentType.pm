##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/ContentType.pm
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
package Mail::Make::Headers::ContentType;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Mail::Make::Headers::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS $VALID_CHARSETS );
    use Mail::Make::Exception;
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    # Common charsets accepted as valid; not exhaustive but covers typical usage
    our $VALID_CHARSETS  = qr/^(?:
        us-ascii | ascii |
        utf-8    | utf8  |
        iso-8859-[\d]+   |
        windows-\d+      |
        shift[_-]jis     |
        euc-jp           |
        iso-2022-jp
    )$/xi;
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_exception_class} = $EXCEPTION_CLASS;
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $str = shift( @_ );
        if( !defined( $str ) || !length( "$str" ) )
        {
            return( $self->error( "No value was provided for Content-Type field." ) );
        }
        my $params = $self->_get_args_as_hash( @_ );
        my $hv     = $self->_parse_header_value( $str ) || return( $self->pass_error );
        $hv->param( $_ => $params->{ $_ } ) for( keys( %$params ) );
        $self->_hv( $hv );
    }
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Type' );
    return( $self );
}

sub as_string { return( shift->_hv_as_string( @_ ) ); }

sub boundary
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $b = shift( @_ );
        if( defined( $b ) && length( $b ) )
        {
            # RFC 2046 boundary: 1-70 chars from a limited set, no trailing space
            return( $self->error(
                "Invalid boundary '$b': only 0-9 a-z A-Z and '()+_,-./:=? ' are allowed, max 70 chars, no trailing space"
            ) ) if( length( $b ) > 70 || $b =~ m{[^0-9a-zA-Z'()+_,\-./:=? ]} || $b =~ / $/ );
        }
        return( $self->_set_get_param( boundary => $b ) );
    }
    return( $self->_set_get_param( 'boundary' ) );
}

sub charset
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $cs = shift( @_ );
        if( defined( $cs ) && length( $cs ) )
        {
            unless( $cs =~ $VALID_CHARSETS )
            {
                return( $self->error( "Unknown or unsupported charset '$cs'." ) );
            }
            # Normalise to lowercase
            $cs = lc( $cs );
            # Normalise utf8 -> utf-8
            $cs = 'utf-8' if( $cs eq 'utf8' );
        }
        return( $self->_set_get_param( charset => $cs ) );
    }
    return( $self->_set_get_param( 'charset' ) );
}

# Returns a fresh RFC 2046 compliant boundary using Data::UUID
sub make_boundary
{
    my $self = shift( @_ );
    $self->_load_class( 'Data::UUID' ) || return( $self->pass_error );
    return( Data::UUID->new->create_str );
}

sub name { return( shift->_set_get_param( name => @_ ) ); }

sub type
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $mime = shift( @_ ) || return( $self->error( "No MIME type was provided." ) );
        # Basic structural validation: type/subtype
        unless( $mime =~ m{^[A-Za-z0-9][A-Za-z0-9!\#\$&\-^_]*
                            /[A-Za-z0-9][A-Za-z0-9!\#\$&\-^_.+]*$}x )
        {
            return( $self->error( "Invalid MIME type '$mime': expected 'type/subtype' format." ) );
        }
        my $hv = $self->_new_hv( $mime ) || return( $self->pass_error );
        $self->_hv( $hv );
        return( $mime );
    }
    else
    {
        my $hv = $self->_hv || return( '' );
        return( $hv->value_data );
    }
}

# Alias
sub value { return( shift->type( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::ContentType - Content-Type Header Field Object

=head1 SYNOPSIS

    use Mail::Make::Headers::ContentType;

    my $ct = Mail::Make::Headers::ContentType->new( 'text/plain' ) ||
        die( Mail::Make::Headers::ContentType->error );
    $ct->charset( 'utf-8' );
    print "$ct";
    # text/plain; charset=utf-8

    my $ct = Mail::Make::Headers::ContentType->new( 'multipart/mixed' ) ||
        die( Mail::Make::Headers::ContentType->error );
    $ct->boundary( $ct->make_boundary );
    print "$ct";
    # multipart/mixed; boundary=550E8400-E29B-41D4-A716-446655440000

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

Typed object for the C<Content-Type> mail header field. Provides strict validation of the MIME type, charset, and boundary parameter, refusing silently corrupt values that would produce a broken message.

=head1 METHODS

=head2 new( $mime_type [, %params ] )

Instantiates a new object. C<$mime_type> must be in C<type/subtype> format.
Optional C<%params> are set as additional parameters on the header value.

=head2 as_string

Returns the complete header field value as a string, including all parameters.

=head2 boundary( [ $boundary ] )

Sets or gets the C<boundary> parameter. On setting, validates that the value conforms to RFC 2046: up to 70 characters from the set C<[0-9A-Za-z'()+_,-./:=? ]>, with no trailing space.

Returns an error if the boundary is invalid.

=head2 charset( [ $charset ] )

Sets or gets the C<charset> parameter. On setting, validates the value against a list of known charsets and normalises C<utf8> to C<utf-8>.

=head2 make_boundary

Returns a freshly generated, RFC 2046 compliant boundary string based on a UUID.

=head2 name( [ $name ] )

Sets or gets the C<name> parameter (used for inline parts).

=head2 type( [ $mime_type ] )

Sets or gets the MIME type (e.g. C<text/html>). Validates the C<type/subtype> format on assignment.

=head2 value( [ $mime_type ] )

Alias for L</type>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Headers>, L<Mail::Make::Headers::Generic>, L<Mail::Make::Headers::ContentDisposition>

RFC 2045, RFC 2046

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
