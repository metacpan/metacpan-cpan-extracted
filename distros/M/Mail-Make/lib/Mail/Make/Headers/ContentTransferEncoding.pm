##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/ContentTransferEncoding.pm
## Version v0.2.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/03
## All rights reserved.
##
## This program is free software; you can redistribute it and/or modify it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Headers::ContentTransferEncoding;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS %VALID_ENCODINGS );
    use Mail::Make::Exception;
    use overload
    (
        '""'  => 'as_string',
        bool  => sub{1},
    );
    # RFC 2045 section 6.1 - defined encodings
    %VALID_ENCODINGS =
    (
        '7bit'              => 1,
        '8bit'              => 1,
        'binary'            => 1,
        'base64'            => 1,
        'quoted-printable'  => 1,
    );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_encoding}        = undef;
    $self->{_exception_class} = $EXCEPTION_CLASS;
    # Module::Generic passes positional args through init() as-is when
    # _init_strict_use_sub is not set - accept the encoding as first positional arg.
    my $encoding = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    if( defined( $encoding ) && length( $encoding ) )
    {
        $self->encoding( $encoding ) || return( $self->pass_error );
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    return( $self->{_encoding} // '' );
}

# encoding( [$value] )
# Gets or sets the encoding token. Validates against VALID_ENCODINGS.
sub encoding
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $enc = lc( shift( @_ ) // '' );
        unless( exists( $VALID_ENCODINGS{ $enc } ) )
        {
            return( $self->error( "Invalid Content-Transfer-Encoding '$enc'; must be one of: " .
                join( ', ', sort( keys( %VALID_ENCODINGS ) ) ) ) );
        }
        $self->{_encoding} = $enc;
        return( $self );
    }
    return( $self->{_encoding} );
}

# is_binary()
# Returns true if the encoding is 'binary' (never valid for mail text parts).
sub is_binary { return( ( shift->{_encoding} // '' ) eq 'binary' ? 1 : 0 ); }

# is_encoded()
# Returns true if the encoding is base64 or quoted-printable.
sub is_encoded
{
    my $enc = shift->{_encoding} // '';
    return( ( $enc eq 'base64' || $enc eq 'quoted-printable' ) ? 1 : 0 );
}

# value() - alias for as_string
sub value { return( shift->as_string ); }

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::ContentTransferEncoding - Typed Content-Transfer-Encoding Header for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Headers::ContentTransferEncoding;

    my $cte = Mail::Make::Headers::ContentTransferEncoding->new( 'quoted-printable' ) ||
        die( Mail::Make::Headers::ContentTransferEncoding->error );
    print $cte->as_string;
    # quoted-printable

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

A typed, validating object for the C<Content-Transfer-Encoding> header field.

Accepts only the RFC 2045-defined encoding tokens: C<7bit>, C<8bit>, C<binary>, C<base64>, and C<quoted-printable>.

=head1 CONSTRUCTOR

=head2 new( $encoding )

Creates a new object with the given encoding token. Returns an error if the token is not one of the RFC 2045-defined values.

=head1 METHODS

=head2 as_string

Returns the encoding token string.

=head2 encoding( [$value] )

Gets or sets the encoding token. Validates against allowed values.

=head2 is_binary

Returns true if the encoding is C<binary>.

=head2 is_encoded

Returns true if the encoding is C<base64> or C<quoted-printable>.

=head2 value

Alias for C<as_string>.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

RFC 2045 section 6

L<Mail::Make::Headers::ContentType>, L<Mail::Make::Headers>, L<Mail::Make>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
