##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Stream/QuotedPrint.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/30
## Modified 2022/05/30
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Stream::QuotedPrint;
BEGIN
{
    use strict;
    use warnings;
    use HTTP::Promise::Stream;
    use parent -norequire, qw( HTTP::Promise::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $QuotedPrintError $DEBUG );
    use Encode ();
    use Module::Generic::File::IO;
    our @EXPORT_OK = qw( decode_qp encode_qp );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $VERSION = 'v0.1.0';
    our $DEBUG = 0;
};

use strict;
use warnings;

sub decode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer ) = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    $self->_load_class( 'MIME::QuotedPrint', { no_import => 1 } ) || return( $self->pass_error );
    # Wrap the filehandle into an object-oriented one that support the getline() method
    unless( $self->_can( $from_fh => 'getline' ) )
    {
        my $io = Module::Generic::File::IO->new;
        $io->fdopen( ( $self->_can( $from_fh => 'fileno' ) ? $from_fh->fileno : fileno( $from_fh ) ), 'r' ) ||
            return( $self->pass_error( $io->error ) );
        $from_fh = $io;
    }
    
    my $buff;
    while( defined( $buff = $from_fh->getline ) )
    {
        my $decoded = MIME::QuotedPrint::decode_qp( $buff );
        # MIME::QuotedPrint::decode_qp() will decode the data into an utf-8 bytes (not the perl's internal representation)
        # This is fine and we save it as it is in the output
        my $rv = $writer->( $decoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error( $from_fh->error ) ) if( !defined( $buff ) && $self->_can( $from_fh => 'error' ) && $self->error );
    return( $self );
}

sub decode_qp
{
    my $s = __PACKAGE__->new( debug => $DEBUG );
    my $rv = $s->decode( @_ );
    if( !defined( $rv ) )
    {
        $QuotedPrintError = $s->error;
        return;
    }
    else
    {
        undef( $QuotedPrintError );
        return( $rv );
    }
}

sub encode
{
    my $self = shift( @_ );
    my $from = shift( @_ );
    my $to   = shift( @_ );
    my $opts = $self->_get_args_as_hash( @_ );
    my( $from_fh, $reader ) = $self->_get_glob_from_arg( $from );
    my( $to_fh, $writer ) = $self->_get_glob_from_arg( $to, write => 1 );
    return( $self->pass_error ) if( !defined( $from_fh ) || !defined( $to_fh ) );
    $self->_load_class( 'MIME::QuotedPrint', { no_import => 1 } ) || return( $self->pass_error );
    # Wrap the filehandle into an object-oriented one that support the getline() method
    unless( $self->_can( $from_fh => 'getline' ) )
    {
        my $io = Module::Generic::File::IO->new;
        $io->fdopen( ( $self->_can( $from_fh => 'fileno' ) ? $from_fh->fileno : fileno( $from_fh ) ), 'r' ) ||
            return( $self->pass_error( $io->error ) );
        $from_fh = $io;
    }
    my $eol = ( exists( $opts->{eol} ) && defined( $opts->{eol} ) ) ? $opts->{eol} : $/;
    my $has_eol = length( $eol );
    
    my $buff;
    while( defined( $buff = $from_fh->getline ) )
    {
        # Make sure the chunk of data is in formal utf-8 encoding, i.e. not perl's internal representation
        # Should probably use Encode::encode( 'utf-8', $buff ) instead though
        $buff = Encode::encode_utf8( $buff ) if( Encode::is_utf8( $buff ) );
        my $encoded = MIME::QuotedPrint::encode_qp( $buff, ( $has_eol ? ( $eol ) : () ) );
        # MIME::QuotedPrint::decode_qp() will decode the data into an utf-8 bytes (not the perl's internal representation)
        # This is fine and we save it as it is in the output
        my $rv = $writer->( $encoded );
        return( $self->pass_error ) if( !defined( $rv ) );
    }
    return( $self->pass_error( $from_fh->error ) ) if( !defined( $buff ) && $self->_can( $from_fh => 'error' ) && $self->error );
    return( $self );
}

sub encode_qp
{
    my $s = __PACKAGE__->new;
    my $rv = $s->encode( @_ );
    if( !defined( $rv ) )
    {
        $QuotedPrintError = $s->error;
        return;
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
    eval( 'use MIME::QuotedPrint ();' );
    return( $@ ? 0 : 1 );
}

sub is_emcoder_installed
{
    eval( 'use MIME::QuotedPrint ();' );
    return( $@ ? 0 : 1 );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Stream::QuotedPrint - Stream Encoder for QuotedPrint Encoding

=head1 SYNOPSIS

    use HTTP::Promise::Stream::QuotedPrint;
    my $s = HTTP::Promise::Stream::QuotedPrint->new || 
        die( HTTP::Promise::Stream::QuotedPrint->error, "\n" );
    $s->encode( $input => $output, eol => "\n" ) ||
        die( $s->error );
    $s->decode( $input => $output ) || die( $s->error );
    HTTP::Promise::Stream::QuotedPrint::encode_qp( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError );
    HTTP::Promise::Stream::QuotedPrint::decode_qp( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements an encoding and decoding mechanism for quoted-printable encoding using either of the following on input and output:

=over 4

=item C<filepath>

If the parameter is neither a scalar reference nor a file handle, it will be assumed to be a file path.

=item C<file handle>

This can be a native file handle, or an object oriented one as long as it implements the C<print> or C<write>, and C<read> methods. The C<read> method is expected to return the number of bytes read or C<undef> upon error. The C<print> and C<write> methods are expected to simply return true upon success and C<undef> upon error.

Alternatively, those methods can die and those exceptions wil be caught.

=item C<scalar reference>

This can be a simple scalar reference, or an object scalar reference.

=back

Requires the XS module L<MIME::QuotedPrint> for encoding and decoding.

This encodes and decodes the quoted-printable data according to L<rfc2045, section 6.7|https://tools.ietf.org/html/rfc2045#section-6.7>

=head1 CONSTRUCTOR

=head2 new

Creates a new L<HTTP::Promise::Stream::QuotedPrint> object and returns it.

=head1 METHODS

=head2 decode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the quoted-printable encoded data and write the result into the output.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head2 encode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into quoted-printable encoded data and write the result into the output.

If the option I<eol> (standing for "End of line") is provided, it will be used at the end of each line of 76 characters. If I<eol> is not provided, it will default to C<$/>, which usually is C<\n>.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head1 CLASS FUNCTIONS

The following class functions are available and can also be exported, such as:

    use HTTP::Promise::Stream::QuotedPrint qw( decode_qp encode_qp );

=head2 decode_qp

This takes the same 2 arguments used in L</decode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the quoted-printable encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$QuotedPrintError> and return C<undef>

    my $decoded = HTTP::Promise::Stream::QuotedPrint::decode_qp( $encoded );
    die( "Something went wrong: $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError\n" if( !defined( $decoded ) );
    print( "Decoded data is: $decoded\n" );

=head2 encode_qp

This takes the same 2 arguments used in L</encode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into quoted-printable encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$QuotedPrintError> and return C<undef>

    my $encoded = HTTP::Promise::Stream::QuotedPrint::encode_qp( $data );
    die( "Something went wrong: $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError\n" if( !defined( $encoded ) );
    print( "Encoded data is: $encoded\n" );

=head2 encode_qp_utf8

This takes a string, encode it into an UTF-8 string using L<Encode/encode_utf8> and then encode the resulting string into quoted-printable and returns the result.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

This encodes and decodes the quoted-printable data according to L<rfc2045, section 6.7|https://tools.ietf.org/html/rfc2045#section-6.7>

See also the L<Wikipedia page|https://en.wikipedia.org/wiki/Quoted-printable>

L<PerlIO::via::QuotedPrint>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
