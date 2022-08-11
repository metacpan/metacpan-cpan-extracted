##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Stream/UU.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/29
## Modified 2022/04/29
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Stream::UU;
BEGIN
{
    use strict;
    use warnings;
    use HTTP::Promise::Stream;
    use parent -norequire, qw( HTTP::Promise::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $UUError );
    use constant {
        DECODE_BUFFER_SIZE  => 1024,
        ENCODE_BUFFER_SIZE  => 45,
    };
    our @EXPORT_OK = qw( decode_uu encode_uu );
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
    $buff = '';
    
    my $getline = sub
    {
        if( length( $buff ) > 0 && $buff =~ s/^((?:[^\015\012]+)\015?\012)// )
        {
            return( $1 );
        }
        else
        {
            while( $n = $reader->( $buff, DECODE_BUFFER_SIZE, length( $buff ) ) )
            {
                if( $buff =~ s/^((?:[^\015\012]+)\015?\012)// )
                {
                    return( $1 );
                }
                else
                {
                    next;
                }
            }
            return;
        }
    };
    
    my( $mode, $fname );
    my $done;
    local $_;
    # Credit: brian d foy <https://metacpan.org/dist/PerlPowerTools/view/bin/uudecode>
    READ: while( defined( $_ = $getline->() ) )
    {
        next unless( ( $mode, $fname ) = /^begin[[:blank:]\h]+(\d+)[[:blank:]\h]+(\S+)/ );
        $self->filename( $fname );
        $self->mode( $mode );
        $opts->{filename} = $fname;
        $opts->{mode} = $mode;
        $done = 0;
        LINE: while( defined( $_ = $getline->() ) )
        {
            if( /^end$/ )
            {
                $done = 1;
                last READ;
            }
            next LINE if( /[a-z]/ );
            next LINE unless int( ( ( ( ord( $_ ) - 32 ) & 077 ) + 2 ) / 3 ) == int( length( $_ ) / 4 );
            my $rv = $writer->( unpack( 'u', $_ ) );
                return( $self->pass_error ) if( !defined( $rv ) );
        }
    }
    return( $self->error( "No UU encoded data found." ) ) if( !defined( $done ) );
    return( $self->error( "Missing end. input data stream may be truncated." ) ) if( !$done );
    return( $self );
}

sub decode_uu
{
    my $s = __PACKAGE__->new;
    my $rv = $s->decode( @_ );
    if( !defined( $rv ) )
    {
        $UUError = $s->error;
        return;
    }
    else
    {
        undef( $UUError );
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
    my $fname = ( exists( $opts->{filename} ) && length( $opts->{filename} ) ) ? $opts->{filename} : 'unknown.bin';
    my $mode  = ( exists( $opts->{mode} ) && length( $opts->{mode} ) ) ? $opts->{mode} : 0644;
    my( $n, $buff );
    
    my $rv = $writer->( sprintf( "begin %03o $fname\n", $mode ) );
    return( $self->pass_error ) if( !defined( $rv ) );
    while( $n = $reader->( $buff, ENCODE_BUFFER_SIZE ) )
    {
        $writer->( pack( 'u', $buff ) );
    }
    defined( $writer->( "`\n" ) ) or return( $self->pass_error );
    defined( $writer->( "end\n" ) ) or return( $self->pass_error );
    return( $self );
}

sub encode_uu
{
    my $s = __PACKAGE__->new;
    my $rv = $s->encode( @_ );
    if( !defined( $rv ) )
    {
        $UUError = $s->error;
        return;
    }
    else
    {
        undef( $UUError );
        return( $rv );
    }
}

sub filename { return( shift->_set_get_scalar( 'filename', @_ ) ); }

sub is_decoder_installed { return(1); }

sub is_emcoder_installed { return(1); }

sub mode { return( shift->_set_get_number( 'mode', @_ ) ); }

# NOTE: sub FREEZE is inherited

# NOTE: sub STORABLE_freeze is inherited

# NOTE: sub STORABLE_thaw is inherited

# NOTE: sub THAW is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Stream::UU - Stream Encoder for UU Encoding

=head1 SYNOPSIS

    use HTTP::Promise::Stream::UU;
    my $s = HTTP::Promise::Stream::UU->new || 
        die( HTTP::Promise::Stream::UU->error, "\n" );
    $s->encode( $input => $output, eol => "\n" ) ||
        die( $s->error );
    $s->decode( $input => $output ) || die( $s->error );
    HTTP::Promise::Stream::UU::encode_uu( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::UU::UUError );
    HTTP::Promise::Stream::UU::decode_uu( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::UU::UUError );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements an encoding and decoding mechanism for UU encoding using either of the following on input and output:

=over 4

=item C<filepath>

If the parameter is neither a scalar reference nor a file handle, it will be assumed to be a file path.

=item C<file handle>

This can be a native file handle, or an object oriented one as long as it implements the C<print> or C<write>, and C<read> methods. The C<read> method is expected to return the number of bytes read or C<undef> upon error. The C<print> and C<write> methods are expected to simply return true upon success and C<undef> upon error.

Alternatively, those methods can die and those exceptions wil be caught.

=item C<scalar reference>

This can be a simple scalar reference, or an object scalar reference.

=back

=head1 CONSTRUCTOR

=head2 new

Creates a new L<HTTP::Promise::Stream::UU> object and returns it.

=head1 METHODS

=head2 decode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the UU encoded data and write the result into the output.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head2 encode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into UU encoded data and write the result into the output.

Possible options are:

=over 4

=item I<filename>

The file name (not the file path) to be used for UU encoding.

=item I<mode>

The file octal permisions, like C<0644>. It defaults to C<0644> if nothing is provided.

=back

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head1 CLASS FUNCTIONS

The following class functions are available and can also be exported, such as:

    use HTTP::Promise::Stream::Brotli qw( decode_uu encode_uu );

=head2 decode_uu

This takes the same 2 arguments used in L</decode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the UU encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$UUError> and return C<undef>

    my $decoded = HTTP::Promise::Stream::UU::decode_uu( $encoded );
    die( "Something went wrong: $HTTP::Promise::Stream::UU::UUError\n" if( !defined( $decoded ) );
    print( "Decoded data is: $decoded\n" );

=head2 encode_uu

This takes the same 2 arguments used in L</encode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into UU encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$UUError> and return C<undef>

    my $encoded = HTTP::Promise::Stream::UU::encode_uu( $data );
    die( "Something went wrong: $HTTP::Promise::Stream::UU::UUError\n" if( !defined( $encoded ) );
    print( "Encoded data is: $encoded\n" );

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Wikipedia page|https://en.wikipedia.org/wiki/Uuencoding>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
