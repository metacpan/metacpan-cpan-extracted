##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Stream/Base64.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/04/28
## Modified 2022/04/28
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Stream::Base64;
BEGIN
{
    use strict;
    use warnings;
    use HTTP::Promise::Stream;
    use parent -norequire, qw( HTTP::Promise::Stream::Generic );
    use vars qw( @EXPORT_OK $VERSION $EXCEPTION_CLASS $Base64Error );
    use Crypt::Misc ();
    use constant {
        ENCODE_BUFFER_SIZE  => 300,
        DECODE_BUFFER_SIZE  => ( 32 * 1024 ),
    };
    our @EXPORT_OK = qw( decode_b64 encode_b64 );
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
    
    while( $n = $reader->( $buff, DECODE_BUFFER_SIZE ) )
    {
        my $decoded = Crypt::Misc::decode_b64( $buff );
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
        return;
    }
    else
    {
        undef( $Base64Error );
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
    my $eol = exists( $opts->{eol} ) ? $opts->{eol} : $/;
    my $has_eol = length( $eol );
    my( $n, $buff );
    
    while( $n = $reader->( $buff, ENCODE_BUFFER_SIZE ) )
    {
        my $encoded = Crypt::Misc::encode_b64( $buff );
        if( $has_eol )
        {
            $encoded =~ s/(.{76})/$1$eol/g;
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
        return;
    }
    else
    {
        undef( $Base64Error );
        return( $rv );
    }
}

sub is_decoder_installed
{
    eval( 'use Crypt::Misc ();' );
    return( $@ ? 0 : 1 );
}

sub is_encoder_installed
{
    eval( 'use Crypt::Misc ();' );
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

HTTP::Promise::Stream::Base64 - Stream Encoder for Base64 Encoding

=head1 SYNOPSIS

    use HTTP::Promise::Stream::Base64;
    my $s = HTTP::Promise::Stream::Base64->new || 
        die( HTTP::Promise::Stream::Base64->error, "\n" );
    $s->encode( $input => $output, eol => "\n" ) ||
        die( $s->error );
    $s->decode( $input => $output ) || die( $s->error );
    HTTP::Promise::Stream::Base64::encode_b64( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::Base64::Base64Error );
    HTTP::Promise::Stream::Base64::decode_b64( $input => $output, eol => "\n" ) ||
        die( $HTTP::Promise::Stream::Base64::Base64Error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This implements an encoding and decoding mechanism for base64 encoding using either of the following on input and output:

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

Creates a new L<HTTP::Promise::Stream::Base64> object and returns it.

=head1 METHODS

=head2 decode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the base64 encoded data and write the result into the output.

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head2 encode

This takes 2 arguments: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into base64 encoded data and write the result into the output.

If the option I<eol> (standing for "End of line") is provided, it will be used to break down the base64 encoded into lines of 76 characters ending with the I<eol>. If I<eol> is not provided, it will default to C<$/>, which usually is C<\n>. If you want base64 data that are not borken down into 76 characters line, then pass an empty I<eol> parameter, such as:

    my $s = HTTP::Promise::Stream::Base64->new;
    $s->encode( $from => $to, eol => undef ); # or eol => ''

It returns true upon success and sets an L<error|Module::Generic/error> and return C<undef> upon error.

=head1 CLASS FUNCTIONS

The following class functions are available and can also be exported, such as:

    use HTTP::Promise::Stream::Base64 qw( decode_b64 encode_b64 );

=head2 decode_b64

This takes the same 2 arguments used in L</decode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will decode the base64 encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$Base64Error> and return C<undef>

    my $decoded = HTTP::Promise::Stream::Base64::decode_b64( $encoded );
    die( "Something went wrong: $HTTP::Promise::Stream::Base64::Base64Error\n" if( !defined( $decoded ) );
    print( "Decoded data is: $decoded\n" );

=head2 encode_b64

This takes the same 2 arguments used in L</encode>: an input and an output. Each one can be either a file path, a file handle, or a scalar reference.

It will encode the data into base64 encoded data and write the result into the output.

It returns true upon success, and upon error, it will set the error in the global variable C<$Base64Error> and return C<undef>

    my $encoded = HTTP::Promise::Stream::Base64::encode_b64( $data );
    die( "Something went wrong: $HTTP::Promise::Stream::Base64::Base64Error\n" if( !defined( $encoded ) );
    print( "Encoded data is: $encoded\n" );

=head2 is_decoder_installed

Returns true if the module L<Crypt::Misc> is installed, false otherwise.

=head2 is_encoder_installed

Returns true if the module L<Crypt::Misc> is installed, false otherwise.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<W3C|http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4.2>

L<caniuse|https://caniuse.com/atob-btoa>

L<PerlIO::via::Base64>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
