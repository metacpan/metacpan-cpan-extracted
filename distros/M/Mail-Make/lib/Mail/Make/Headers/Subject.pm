##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Headers/Subject.pm
## Version v0.1.1
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/03
## Modified 2026/03/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Headers::Subject;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use parent qw( Module::Generic );
    use vars qw( $VERSION $EXCEPTION_CLASS );
    use utf8;
    use Encode ();
    use Mail::Make::Exception;
    use MIME::Base64 ();
    use overload(
        '""'   => 'as_string',
        'bool' => sub { 1 },
    );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION = 'v0.1.1';
    # RFC 2047 §2: an encoded-word must not exceed 75 characters total.
    # =?UTF-8?B? ... ?=  - the wrapper is 12 chars, leaving 63 for base64 text.
    # 63 base64 chars encode floor(63 * 3/4) = 47 raw bytes.
    # We use 45 bytes per chunk (multiple of 3) to keep base64 clean.
    use constant
    {
        CHARSET          => 'UTF-8',
        EW_MAX_BYTES     => 45,
        FOLD_SEP         => "\015\012 ",
    };
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_raw}             = undef;   # original Perl string, not yet encoded
    $self->{_encoded}         = undef;   # RFC 2047 form, cached after first encode
    $self->{_exception_class} = $EXCEPTION_CLASS;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# as_string() - returns the RFC 2047 encoded form suitable for the wire.
# Pure ASCII values are returned unchanged.
sub as_string
{
    my $self = shift( @_ );
    return( '' ) if( !defined( $self->{_raw} ) );
    return( $self->{_encoded} ) if( defined( $self->{_encoded} ) );
    $self->{_encoded} = _encode_subject( $self->{_raw} );
    return( $self->{_encoded} );
}

# decode( $encoded_string ) - class or instance method.
# Decodes an RFC 2047 encoded Subject value back to a Perl string.
sub decode
{
    my $self = shift( @_ );
    my $str  = shift( @_ ) // return( $self->error( "No value to decode." ) );
    return( _decode_subject( $str ) );
}

# field_name() - always returns 'Subject'
sub field_name { return( 'Subject' ); }

# raw() - returns the decoded Perl string (the original value before encoding)
sub raw { return( shift->{_raw} ); }

# value( [$text] ) - sets or gets the subject text.
# On assignment: stores the raw Perl string; clears the encoded cache.
# On retrieval: returns the decoded Perl string (i.e. human-readable).
sub value
{
    my $self = shift( @_ );
    if( @_ )
    {
        my $text = shift( @_ );
        unless( defined( $text ) )
        {
            return( $self->error( "Subject value must be a defined scalar." ) );
        }
        $self->{_raw}     = $text;
        $self->{_encoded} = undef;    # invalidate cache
        return( $self );
    }
    return( $self->{_raw} );
}

# _decode_ew( $charset, $encoding, $text ) → decoded Perl string fragment
sub _decode_ew
{
    my( $charset, $enc, $text ) = @_;
    my $bytes;
    if( uc( $enc ) eq 'B' )
    {
        $bytes = MIME::Base64::decode_base64( $text );
    }
    else
    {
        # Q encoding: _ → space, =XX → byte
        $text =~ s/_/ /g;
        $text =~ s/=([0-9A-Fa-f]{2})/chr( hex( $1 ) )/ge;
        $bytes = $text;
    }
    local $@;
    my $decoded = eval{ Encode::decode( $charset, $bytes ) };
    return( $@ ? $bytes : $decoded );
}

# _decode_subject( $wire_string ) → $perl_string
# Decodes all RFC 2047 encoded-words in $wire_string.
# Handles both ?B? (Base64) and ?Q? (Quoted-Printable) forms.
sub _decode_subject
{
    my $str = shift( @_ );
    return( $str ) unless( defined( $str ) && $str =~ /=\?/ );

    # Collapse folding whitespace between consecutive encoded-words:
    # RFC 2047 §6.2: whitespace between two encoded-words is ignored.
    $str =~ s/\?=[ \t]*(?:\015\012)?[ \t]*=\?/?==?/g;

    $str =~ s/=\?([A-Za-z0-9_-]+)\?([BbQq])\?([^?]*)\?=/_decode_ew( $1, $2, $3 )/ge;
    return( $str );
}

# _encode_subject( $perl_string ) → $wire_string
# Returns the string as-is if it is pure printable ASCII (RFC 2822 §2.2).
# Otherwise encodes the UTF-8 bytes in one or more RFC 2047 Base64
# encoded-words, folded with CRLF SP between them.
sub _encode_subject
{
    my $text = shift( @_ );

    # Pure printable ASCII + tab/space: no encoding needed.
    # We also reject bare CRs and LFs here; they are illegal in a header.
    return( $text ) unless( $text =~ /[^\x09\x20-\x7E]/ );

    # Ensure the string carries Perl's UTF-8 flag before encoding to bytes.
    # If the flag is off (raw octets from a context without Encode::decode),
    # Encode::encode treats each octet as Latin-1, producing double-encoding:
    # e.g. U+2014 (E2 80 94) becomes C3 A2 C2 80 C2 94 instead of E2 80 94.
    utf8::decode( $text ) unless( utf8::is_utf8( $text ) );

    # Encode the entire string to UTF-8 bytes, then split into safe chunks.
    # Crucially: we split on byte boundaries that do NOT break a multi-byte UTF-8 sequence.
    # Because we encode the whole string first we work purely in bytes and the split is
    # safe.
    my $bytes = Encode::encode( CHARSET, $text );

    my @words;
    my $offset = 0;
    my $total  = length( $bytes );
    while( $offset < $total )
    {
        # Grab up to EW_MAX_BYTES bytes, but do not cut inside a multi-byte sequence.
        # UTF-8 continuation bytes are 0x80..0xBF; a leading byte of a multi-byte sequence
        # is 0xC0..0xFF. We back up until we sit at a leading byte boundary (or the very end).
        my $len   = EW_MAX_BYTES;
        $len      = $total - $offset if( $offset + $len > $total );
        my $chunk = substr( $bytes, $offset, $len );

        # If the byte immediately after our chunk is a UTF-8 continuation byte (0x80–0xBF),
        # the last character of our chunk is split.c
        # Walk backwards to a safe cut point.
        if( $offset + $len < $total )
        {
            my $next = ord( substr( $bytes, $offset + $len, 1 ) );
            if( ( $next & 0xC0 ) == 0x80 )
            {
                # Find last leading byte in chunk
                while( $len > 0 && ( ord( substr( $chunk, $len - 1, 1 ) ) & 0xC0 ) == 0x80 )
                {
                    $len--;
                }
                $chunk = substr( $bytes, $offset, $len );
            }
        }

        my $b64 = MIME::Base64::encode_base64( $chunk, '' );
        push( @words, '=?' . CHARSET . '?B?' . $b64 . '?=' );
        $offset += $len;
    }

    return( join( FOLD_SEP, @words ) );
}

# NOTE: STORABLE support
sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw   { CORE::return( CORE::shift->THAW( @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Headers::Subject - RFC 2047 Aware Subject Header for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Headers::Subject;

    # Pure ASCII: passed through unchanged
    my $s = Mail::Make::Headers::Subject->new;
    $s->value( 'Quarterly Report' );
    print $s->as_string;
    # Quarterly Report

    # Non-ASCII: automatically encoded per RFC 2047
    $s->value( "Yamato, Inc. - Newsletter" );
    print $s->as_string;
    # =?UTF-8?B?QW5nZWxzLCBJbmMuIOKAlCBOZXdzbGV0dGVy?=

    # Long Japanese subject: folded into multiple encoded-words
    $s->value( "株式会社ヤマト・インク　第3四半期ニュースレター　2026年3月号" );
    print $s->as_string;
    # =?UTF-8?B?...?=\r\n =?UTF-8?B?...?=\r\n =?UTF-8?B?...?=

    # Round-trip decode
    my $decoded = $s->decode( $s->as_string );
    # "株式会社ヤマト・インク　第3四半期ニュースレター　2026年3月号"

=head1 VERSION

    v0.1.1

=head1 DESCRIPTION

A typed header object for the C<Subject> field that implements RFC 2047 encoded-word encoding and decoding.

Key properties:

=over 4

=item *

Pure printable ASCII subjects are passed through without modification.

No unnecessary C<=?UTF-8?B?...?=> wrapping.

=item *

Non-ASCII subjects are encoded as one or more C<=?UTF-8?B?...?=> encoded-words using Base64.

=item *

Long values are split into chunks of at most 45 UTF-8 bytes each, keeping every encoded-word within the RFC 2047 maximum of 75 characters.

=item *

Chunks are joined with C<CRLF SP> (header folding), producing a correctly folded multi-line header value.

=item *

Chunk boundaries are chosen so as never to split a multi-byte UTF-8 sequence.

=item *

The L</decode> method handles both C<?B?> (Base64) and C<?Q?> (Quoted-Printable) encoded-words, and collapses inter-word whitespace per RFC 2047 §6.2.

=back

=head1 METHODS

=head2 new

Instantiates a new object. Optionally accepts a subject string via the C<value> key in a hash argument, consistent with L<Module::Generic> C<init> conventions.

=head2 as_string

Returns the encoded form of the subject, suitable for the wire. Pure ASCII values are returned unchanged. Non-ASCII values are encoded in RFC 2047 C<=?UTF-8?B?...?=> form, folded at CRLF SP as required.

This method is also invoked by the C<""> overload.

=head2 decode( $encoded_string )

Class or instance method. Decodes all RFC 2047 encoded-words present in C<$encoded_string> and returns the result as a Perl Unicode string.

=head2 field_name

Returns the string C<Subject>.

=head2 raw

Returns the stored Perl Unicode string, before any RFC 2047 encoding.

=head2 value( [ $text ] )

Sets or gets the subject text as a Perl Unicode string. On assignment, the encoded cache is invalidated so that the next call to L</as_string> re-encodes the new value.

=head1 STANDARDS

=over 4

=item RFC 2047 - MIME Part Three: Message Header Extensions for Non-ASCII Text

=item RFC 2822 §2.2 - Header Fields

=back

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Headers>, L<Mail::Make::Headers::Generic>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
