##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Stream/LZW.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/04
## Modified 2022/05/04
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Stream::LZW;
BEGIN
{
    use strict;
    use warnings;
    use HTTP::Promise::Stream;
    use parent -norequire, qw( HTTP::Promise::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $LZWError );
    use Nice::Try;
    use constant {
        ENCODE_BUFFER_SIZE  => ( 32 * 1024 ),
        DECODE_BUFFER_SIZE  => ( 32 * 1024 ),
    };
    our @EXPORT_OK = qw( decode_lzw encode_lzw );
    our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
    our $VERSION = 'v0.1.0';
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
    my( $n, $buff );
    $self->_load_class( 'Compress::LZW::Decompressor', { no_import => 1 } ) || return( $self->pass_error );
    my $c = Compress::LZW::Decompressor->new;
    
    try
    {
        while( $n = $reader->( $buff, DECODE_BUFFER_SIZE ) )
        {
            my $decoded = $c->decompress( $buff );
            my $rv = $writer->( $decoded );
            return( $self->pass_error ) if( !defined( $rv ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error decompressing with LZW: $e" ) );
    }
    return( $self->pass_error ) if( !defined( $n ) );
    return( $self );
}

sub decode_lzw
{
    my $s = __PACKAGE__->new;
    my $rv = $s->decode( @_ );
    if( !defined( $rv ) )
    {
        $LZWError = $s->error;
        return;
    }
    else
    {
        undef( $LZWError );
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
    my( $n, $buff );
    $self->_load_class( 'Compress::LZW::Compressor', { no_import => 1 } ) || return( $self->pass_error );
    my $c = Compress::LZW::Compressor->new;
    
    try
    {
        while( $n = $reader->( $buff, ENCODE_BUFFER_SIZE ) )
        {
            my $encoded = $c->compress( $buff );
            my $rv = $writer->( $encoded );
            return( $self->pass_error ) if( !defined( $rv ) );
        }
    }
    catch( $e )
    {
        return( $self->error( "Error compressing with LZW: $e" ) );
    }
    return( $self->pass_error ) if( !defined( $n ) );
    return( $self );
}

sub encode_lzw
{
    my $s = __PACKAGE__->new;
    my $rv = $s->encode( @_ );
    if( !defined( $rv ) )
    {
        $LZWError = $s->error;
        return;
    }
    else
    {
        undef( $LZWError );
        return( $rv );
    }
}

sub is_decoder_installed
{
    eval( 'use Compress::LZW::Decompressor ();' );
    return( $@ ? 0 : 1 );
}

sub is_emcoder_installed
{
    eval( 'use Compress::LZW::Compressor ();' );
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

HTTP::Promise::Stream::LZW - Stream Encoder for LZW Compression

=head1 SYNOPSIS

    use HTTP::Promise::Stream::LZW;
    my $s = HTTP::Promise::Stream::LZW->new || 
        die( HTTP::Promise::Stream::LZW->error, "\n" );
    $s->encode( $input => $output ) ||
        die( $s->error );
    $s->decode( $input => $output ) || die( $s->error );
    HTTP::Promise::Stream::LZW::encode_lzw( $input => $output ) ||
        die( $HTTP::Promise::Stream::LZW::LZWError );
    HTTP::Promise::Stream::LZW::decode_lzw( $input => $output ) ||
        die( $HTTP::Promise::Stream::LZW::LZWError );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements an encoding and decoding mechanism for LZW compression using either of the following on input and output:

=over 4

=item C<filepath>

If the parameter is neither a scalar reference nor a file handle, it will be assumed to be a file path.

=item C<file handle>

This can be a native file handle, or an object oriented one as long as it implements the C<print> or C<write>, and C<read> methods. The C<read> method is expected to return the number of bytes read or C<undef> upon error. The C<print> and C<write> methods are expected to simply return true upon success and C<undef> upon error.

Alternatively, those methods can die and those exceptions wil be caught.

=item C<scalar reference>

This can be a simple scalar reference, or an object scalar reference.

=back

This module requires L<Compress::LZW> to be installed or it will return an error.

=head1 CONSTRUCTOR

=head2 new

Creates a new L<HTTP::Promise::Stream::LZW> object and returns it.

=head1 METHODS

=head2 decode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the LZW encoded data and write the result into the output.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head2 encode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into LZW encoded data and write the result into the output.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head1 CLASS FUNCTIONS

The following class functions are available and can also be exported, such as:

    use HTTP::Promise::Stream::Brotli qw( decode_lzw encode_lzw );

=head2 decode_lzw

This takes the same 2 arguments used in L</decode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the LZW encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$UUError> and return C<undef>

    my $decoded = HTTP::Promise::Stream::LZW::decode_lzw( $encoded );
    die( "Something went wrong: $HTTP::Promise::Stream::LZW::LZWError\n" if( !defined( $decoded ) );
    print( "Decoded data is: $decoded\n" );

=head2 encode_lzw

This takes the same 2 arguments used in L</encode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into LZW encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$LZWError> and return C<undef>

    my $encoded = HTTP::Promise::Stream::LZW::encode_lzw( $data );
    die( "Something went wrong: $HTTP::Promise::Stream::LZW::LZWError\n" if( !defined( $encoded ) );
    print( "Encoded data is: $encoded\n" );

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Compress::LZW>

L<Discussion on Stackoverflow|http://web.archive.org/web/20170310213520/https://stackoverflow.com/questions/3855204/looking-for-library-which-implements-lzw-compression-decompression>, L<Wikipedia page|https://fr.wikipedia.org/wiki/Lempel-Ziv-Welch>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
