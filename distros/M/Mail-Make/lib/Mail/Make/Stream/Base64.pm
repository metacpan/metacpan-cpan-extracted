##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Stream/Base64.pm
## Version v0.3.0
## Copyright(c) 2026 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2026/03/02
## Modified 2026/03/05
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Mail::Make::Stream::Base64;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use Mail::Make::Stream;
    use parent -norequire, qw( Mail::Make::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $Base64Error );
    use Exporter qw( import );
    use Mail::Make::Exception;
    use MIME::Base64 ();
    use constant
    {
        # Input chunk must be a multiple of 3 so base64 output lines align cleanly
        ENCODE_BUFFER_SIZE => 300,
        DECODE_BUFFER_SIZE => ( 32 * 1024 ),
    };
    our @EXPORT_OK       = qw( decode_b64 encode_b64 );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION         = 'v0.3.0';
};

use strict;
use warnings;

# decode( $from, $to [, %opts] )
# Decodes base64 data from $from and writes raw bytes to $to.
# Each of $from / $to may be: a filehandle, a scalar reference, or a file path.
sub decode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer )   = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    my( $n, $buff );

    while( $n = $reader->( $buff, DECODE_BUFFER_SIZE ) )
    {
        my $decoded = MIME::Base64::decode_base64( $buff );
        my $rv = $writer->( $decoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error ) if( !defined( $n ) );
    return( $self );
}

sub decode_b64
{
    my $s = __PACKAGE__->new;
    my $rv = $s->decode( @_ );
    if( !defined( $rv ) )
    {
        $Base64Error = $s->error;
        return( $s->pass_error );
    }
    else
    {
        undef( $Base64Error );
        return( $rv );
    }
}

# encode( $from, $to [, %opts] )
# Encodes raw data from $from as RFC 2045 base64 and writes to $to.
# Options:
#   eol => $str   line ending after each 76-char line (default CRLF "\015\012")
sub encode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer )   = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    my $eol     = exists( $opts->{eol} ) ? $opts->{eol} : "\015\012";
    my $has_eol = defined( $eol ) && length( $eol );
    my( $n, $buff );

    while( $n = $reader->( $buff, ENCODE_BUFFER_SIZE ) )
    {
        # MIME::Base64::encode_base64 appends its own newline - strip it, then
        # insert our configured eol every 76 characters.
        my $encoded = MIME::Base64::encode_base64( $buff, '' );
        if( $has_eol )
        {
            $encoded =~ s/(.{76})/$1$eol/g;
            # Ensure a trailing eol if the final chunk did not land on a 76-char boundary
            $encoded .= $eol unless( $encoded =~ /\015\012$/ );
        }
        my $rv = $writer->( $encoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error ) if( !defined( $n ) );
    return( $self );
}

sub encode_b64
{
    my $s = __PACKAGE__->new;
    my $rv = $s->encode( @_ );
    if( !defined( $rv ) )
    {
        $Base64Error = $s->error;
        return( $s->pass_error );
    }
    else
    {
        undef( $Base64Error );
        return( $rv );
    }
}

sub is_decoder_installed
{
    local $@;
    eval
    {
        local $SIG{__DIE__} = sub{};
        require MIME::Base64;
    };
    return( $@ ? 0 : 1 );
}

sub is_encoder_installed
{
    local $@;
    eval
    {
        local $SIG{__DIE__} = sub{};
        require MIME::Base64;
    };
    return( $@ ? 0 : 1 );
}

# NOTE: sub FREEZE is inherited

# NOTE: sub STORABLE_freeze is inherited

# NOTE: sub STORABLE_thaw is inherited

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Mail::Make::Stream::Base64 - Streaming Base64 Encoder/Decoder for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Stream::Base64;

    my $s = Mail::Make::Stream::Base64->new ||
        die( Mail::Make::Stream::Base64->error, "\n" );

    # File to file
    $s->encode( '/path/to/logo.png' => '/tmp/logo.b64' ) ||
        die( $s->error );

    # Scalar ref to scalar ref
    my( $raw, $out ) = ( "Hello, world!" );
    $s->encode( \$raw => \$out ) || die( $s->error );

    # Decode
    my $decoded = '';
    $s->decode( \$out => \$decoded ) || die( $s->error );

    # Exportable wrappers
    use Mail::Make::Stream::Base64 qw( encode_b64 decode_b64 );
    encode_b64( \$raw => \$out ) ||
        die( $Mail::Make::Stream::Base64::Base64Error );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

RFC 2045 compliant Base64 encoder and decoder. Both L</encode> and L</decode> operate as stream pipelines: data is read from C<$from> in chunks and written to C<$to> without accumulating the full content in memory, making them safe for large attachments backed by L<Mail::Make::Body::File>.

Each of C<$from> and C<$to> may be:

=over 4

=item * A native filehandle or IO object

=item * A scalar reference (C<\$scalar>)

=item * A plain string (file path)

=back

=head1 METHODS

=head2 decode( $from, $to )

Reads base64-encoded data from C<$from>, decodes it via L<MIME::Base64>, and writes the raw bytes to C<$to>. Returns C<$self> on success, C<undef> on error.

=head2 encode( $from, $to [, %opts] )

Reads raw bytes from C<$from> in 300-byte chunks, encodes them as RFC 2045 base64 folded at 76 characters per line, and writes the result to C<$to>.

Returns C<$self> on success, C<undef> on error.

Options:

=over 4

=item C<eol>

Line ending appended after each 76-character line. Defaults to CRLF (C<"\015\012">). Pass C<undef> or C<""> to suppress line folding.

=back

=head1 CLASS FUNCTIONS

The following functions are exportable on request:

    use Mail::Make::Stream::Base64 qw( encode_b64 decode_b64 );

=head2 encode_b64( $from, $to [, %opts] )

Convenience wrapper for L</encode>. Sets C<$Base64Error> and returns C<undef> on failure.

=head2 decode_b64( $from, $to )

Convenience wrapper for L</decode>. Sets C<$Base64Error> and returns C<undef> on failure.

=head2 is_encoder_installed

=head2 is_decoder_installed

Return true if L<MIME::Base64> is available.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Entity>, L<Mail::Make::Stream::QuotedPrint>, L<Mail::Make::Stream>, L<MIME::Base64>

RFC 2045

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
