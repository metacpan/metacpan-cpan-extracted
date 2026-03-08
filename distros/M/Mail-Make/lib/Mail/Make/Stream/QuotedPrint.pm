##----------------------------------------------------------------------------
## MIME Email Builder - ~/lib/Mail/Make/Stream/QuotedPrint.pm
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
package Mail::Make::Stream::QuotedPrint;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'Mail::Make' );
    use Mail::Make::Stream;
    use parent -norequire, qw( Mail::Make::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $QuotedPrintError $DEBUG );
    use Exporter qw( import );
    use Mail::Make::Exception;
    use Encode ();
    use Module::Generic::File::IO;
    our @EXPORT_OK       = qw( decode_qp encode_qp );
    our $EXCEPTION_CLASS = 'Mail::Make::Exception';
    our $VERSION = 'v0.3.1';
    our $DEBUG           = 0;
};

use strict;
use warnings;

# decode( $from, $to [, %opts] )
# Decodes QP data from $from line-by-line and writes raw bytes to $to.
sub decode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer )   = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    $self->_load_class( 'MIME::QuotedPrint', { no_import => 1 } ) || return( $self->pass_error );

    # Wrap the filehandle into an object that supports getline().
    # Native in-memory handles (fileno = -1) already support readline(); do NOT attempt
    # fdopen() on them: that call requires a real OS file descriptor.
    unless( $self->_can( $from_fh => 'getline' ) )
    {
        my $fd = $self->_can( $from_fh => 'fileno' ) ? $from_fh->fileno : fileno( $from_fh );
        if( defined( $fd ) && $fd >= 0 )
        {
            my $io = Module::Generic::File::IO->new;
            $io->fdopen( $fd, 'r' ) ||
                return( $self->pass_error( $io->error ) );
            $from_fh = $io;
        }
        # else: native in-memory glob — readline() below works as-is
    }

    my $buff;
    while( defined( $buff = $self->_can( $from_fh => 'getline' ) ? $from_fh->getline : readline( $from_fh ) ) )
    {
        my $decoded = MIME::QuotedPrint::decode_qp( $buff );
        my $rv = $writer->( $decoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error( $from_fh->error ) )
        if( !defined( $buff ) && $self->_can( $from_fh => 'error' ) && $self->error );
    return( $self );
}

sub decode_qp
{
    my $s = __PACKAGE__->new( debug => $DEBUG );
    my $rv = $s->decode( @_ );
    if( !defined( $rv ) )
    {
        $QuotedPrintError = $s->error;
        return( $s->pass_error );
    }
    else
    {
        undef( $QuotedPrintError );
        return( $rv );
    }
}

# encode( $from, $to [, %opts] )
# Encodes raw data from $from as Quoted-Printable and writes to $to.
# Options:
#   eol => $str   line ending (default "\015\012")
sub encode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer )   = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    $self->_load_class( 'MIME::QuotedPrint', { no_import => 1 } ) || return( $self->pass_error );

    # Wrap the filehandle into an object that supports getline().
    # Native in-memory handles (fileno = -1) already support readline(); do NOT attempt
    # fdopen() on them: that call requires a real OS file descriptor.
    unless( $self->_can( $from_fh => 'getline' ) )
    {
        my $fd = $self->_can( $from_fh => 'fileno' ) ? $from_fh->fileno : fileno( $from_fh );
        if( defined( $fd ) && $fd >= 0 )
        {
            my $io = Module::Generic::File::IO->new;
            $io->fdopen( $fd, 'r' ) ||
                return( $self->pass_error( $io->error ) );
            $from_fh = $io;
        }
        # else: native in-memory glob — readline() below works as-is
    }
    my $eol     = ( exists( $opts->{eol} ) && defined( $opts->{eol} ) ) ? $opts->{eol} : "\015\012";
    my $has_eol = length( $eol );

    my $buff;
    while( defined( $buff = $self->_can( $from_fh => 'getline' ) ? $from_fh->getline : readline( $from_fh ) ) )
    {
        # Ensure the chunk is raw UTF-8 bytes, not Perl's internal representation
        $buff = Encode::encode_utf8( $buff ) if( Encode::is_utf8( $buff ) );
        my $encoded = MIME::QuotedPrint::encode_qp( $buff, ( $has_eol ? ( $eol ) : () ) );
        my $rv = $writer->( $encoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error( $from_fh->error ) )
        if( !defined( $buff ) && $self->_can( $from_fh => 'error' ) && $self->error );
    return( $self );
}

sub encode_qp
{
    my $s = __PACKAGE__->new;
    my $rv = $s->encode( @_ );
    if( !defined( $rv ) )
    {
        $QuotedPrintError = $s->error;
        return( $s->pass_error );
    }
    else
    {
        undef( $QuotedPrintError );
        return( $rv );
    }
}

sub encode_qp_utf8 { return( shift->encode_qp( Encode::encode_utf8( shift( @_ ) ) ) ); }

sub is_decoder_installed
{
    local $@;
    eval
    {
        local $SIG{__DIE__} = sub{};
        require MIME::QuotedPrint;
    };
    return( $@ ? 0 : 1 );
}

sub is_encoder_installed
{
    local $@;
    eval
    {
        local $SIG{__DIE__} = sub{};
        require MIME::QuotedPrint;
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

Mail::Make::Stream::QuotedPrint - Streaming Quoted-Printable Encoder/Decoder for Mail::Make

=head1 SYNOPSIS

    use Mail::Make::Stream::QuotedPrint;

    my $s = Mail::Make::Stream::QuotedPrint->new ||
        die( Mail::Make::Stream::QuotedPrint->error, "\n" );

    $s->encode( $input => $output, eol => "\015\012" ) ||
        die( $s->error );

    $s->decode( $input => $output ) || die( $s->error );

    use Mail::Make::Stream::QuotedPrint qw( encode_qp decode_qp );
    encode_qp( $input => $output, eol => "\015\012" ) ||
        die( $Mail::Make::Stream::QuotedPrint::QuotedPrintError );

=head1 VERSION

    v0.3.0

=head1 DESCRIPTION

RFC 2045 Quoted-Printable encoder and decoder. Both L</encode> and L</decode> operate as line-oriented stream pipelines: data is read from C<$from> line by line (via C<getline()>) and written to C<$to> without accumulating the full content in memory. Suitable for large text parts backed by L<Mail::Make::Body::File>.

Each of C<$from> and C<$to> may be:

=over 4

=item * A native filehandle or IO object

=item * A scalar reference (C<\$scalar>)

=item * A plain string (file path)

=back

=head1 METHODS

=head2 decode( $from, $to )

Reads QP-encoded data from C<$from> line by line, decodes each line via L<MIME::QuotedPrint>, and writes the raw bytes to C<$to>. Returns C<$self> on success, C<undef> on error.

=head2 encode( $from, $to [, %opts] )

Reads raw data from C<$from> line by line, encodes each line as Quoted-Printable, and writes the result to C<$to>. Any Perl-internal UTF-8 representation is converted to raw UTF-8 bytes via L<Encode/encode_utf8> before encoding. Returns C<$self> on success, C<undef> on error.

Options:

=over 4

=item C<eol>

Line ending appended after each encoded line. Defaults to CRLF (C<"\015\012">).

=back

=head1 CLASS FUNCTIONS

The following functions are exportable on request:

    use Mail::Make::Stream::QuotedPrint qw( encode_qp decode_qp );

=head2 encode_qp( $from, $to [, %opts] )

Convenience wrapper for L</encode>. Sets C<$QuotedPrintError> and returns C<undef> on failure.

=head2 decode_qp( $from, $to )

Convenience wrapper for L</decode>. Sets C<$QuotedPrintError> and returns C<undef> on failure.

=head2 encode_qp_utf8( $str )

Encodes C<$str> as UTF-8 bytes first, then as Quoted-Printable.

=head2 is_encoder_installed

=head2 is_decoder_installed

Return true if L<MIME::QuotedPrint> is available.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mail::Make>, L<Mail::Make::Entity>, L<Mail::Make::Stream::Base64>, L<Mail::Make::Stream>, L<MIME::QuotedPrint>

RFC 2045

=head1 COPYRIGHT & LICENSE

Copyright(c) 2026 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
