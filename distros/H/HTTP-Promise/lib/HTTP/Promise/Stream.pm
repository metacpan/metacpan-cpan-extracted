##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Stream.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/28
## Modified 2023/09/08
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Stream;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( Module::Generic );
    use vars qw( $FILTER_MAP $CLASSES $ENCODING_SUFFIX $SUFFIX_ENCODING );
    # use Nice::Try;
    use Scalar::Util;
    use constant HAS_BROWSER_SUPPORT => 1;
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;
no warnings 'uninitialized';

{
    no warnings 'once';
    $CLASSES = 
    {
    base64  => [qw( HTTP::Promise::Stream::Base64 HTTP::Promise::Stream::Base64 )],
    brotli  => [qw( HTTP::Promise::Stream::Brotli HTTP::Promise::Stream::Brotli ), HAS_BROWSER_SUPPORT],
    bzip2   => [qw( IO::Compress::Bzip2 IO::Uncompress::Bunzip2 ), HAS_BROWSER_SUPPORT],
    deflate => [qw( IO::Compress::Deflate IO::Uncompress::Inflate ), HAS_BROWSER_SUPPORT],
    gzip    => [qw( IO::Compress::Gzip IO::Uncompress::Gunzip ), HAS_BROWSER_SUPPORT],
    lzf     => [qw( IO::Compress::Lzf IO::Uncompress::UnLzf )],
    lzip    => [qw( IO::Compress::Lzip IO::Uncompress::UnLzip )],
    lzma    => [qw( IO::Compress::Lzma IO::Uncompress::UnLzma )],
    lzop    => [qw( IO::Compress::Lzop IO::Uncompress::UnLzop )],
    lzw     => [qw( HTTP::Promise::Stream::LZW HTTP::Promise::Stream::LZW )],
    qp      => [qw( HTTP::Promise::Stream::QuotedPrint HTTP::Promise::Stream::QuotedPrint )],
    rawdeflate => [qw( IO::Compress::RawDeflate IO::Uncompress::RawInflate ), HAS_BROWSER_SUPPORT],
    uu      => [qw( HTTP::Promise::Stream::UU HTTP::Promise::Stream::UU )],
    xz      => [qw( IO::Compress::Xz IO::Uncompress::UnXz  )],
    zip     => [qw( IO::Compress::Zip IO::Uncompress::Unzip )],
    zstd    => [qw( IO::Compress::Zstd IO::Uncompress::UnZstd )],
    };
    $CLASSES->{inflate} = $CLASSES->{deflate};
    $CLASSES->{rawinflate} = $CLASSES->{inflate};
    $CLASSES->{compress} = $CLASSES->{lzw};
    $CLASSES->{'quoted-printable'} = $CLASSES->{qp};
    # Permit non-standard call with prefix x-
    for( qw( bzip2 gzip zip ) )
    {
        $CLASSES->{'x-' . $_} = $CLASSES->{ $_ };
    }
    
    $FILTER_MAP =
    {
        encode =>
        {
            base64 => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::Base64;
                    HTTP::Promise::Stream::Base64::encode_b64( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::Base64::Base64Error );
                return( $rv );
            },
            brotli => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::Brotli;
                    HTTP::Promise::Stream::Brotli::encode_bro( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::Brotli::BrotliError );
                return( $rv );
            },
            bzip2 => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Bzip2;
                    IO::Compress::Bzip2::bzip2( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Bzip2::Bzip2Error );
                return( $rv );
            },
            deflate => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Deflate;
                    IO::Compress::Deflate::deflate( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Deflate::DeflateError );
                return( $rv );
            },
            gzip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Gzip;
                    IO::Compress::Gzip::gzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Gzip::GzipError );
                return( $rv );
            },
            lzf => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Lzf;
                    IO::Compress::Lzf::lzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Lzf::LzfError );
                return( $rv );
            },
            lzip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Lzip;
                    IO::Compress::Lzip::lzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Lzip::LzipError );
                return( $rv );
            },
            lzma => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Lzma;
                    IO::Compress::Lzma::lzma( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Lzma::LzmaError );
                return( $rv );
            },
            lzop => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Lzop;
                    IO::Compress::Lzip::lzop( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Lzop::LzopError );
                return( $rv );
            },
            lzw => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Streem::LZW;
                    HTTP::Promise::Streem::LZW::encode_lzw( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Streem::LZW::LZWError );
                return( $rv );
            },
            qp => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::QuotedPrint;
                    HTTP::Promise::Stream::QuotedPrint::encode_qp( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError );
                return( $rv );
            },
            rawdeflate => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::RawDeflate;
                    IO::Compress::RawDeflate::rawdeflate( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::RawDeflate::RawDeflateError );
                return( $rv );
            },
            uu => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::UU;
                    HTTP::Promise::Stream::UU::encode_uu( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::UU::UUError );
                return( $rv );
            },
            xz => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Xz;
                    IO::Compress::Xz::xz( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Xz::XzError );
                return( $rv );
            },
            zip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Zip;
                    IO::Compress::Zip::zip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Zip::ZipError );
                return( $rv );
            },
            zstd => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Compress::Zstd;
                    IO::Compress::Zstd::zstd( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Compress::Zstd::ZstdError );
                return( $rv );
            },
        },
        decode =>
        {
            base64 => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::Base64;
                    HTTP::Promise::Stream::Base64::decode_b64( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::Base64::Base64Error );
                return( $rv );
            },
            brotli => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::Brotli;
                    HTTP::Promise::Stream::Brotli::decode_bro( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::Brotli::BrotliError );
                return( $rv );
            },
            bzip2 => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::Bunzip2;
                    IO::Uncompress::Bunzip2::bunzip2( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::Bunzip2::Bunzip2Error );
                return( $rv );
            },
            gzip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::Gunzip;
                    IO::Uncompress::Gunzip::gunzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::Gunzip::GunzipError );
                return( $rv );
            },
            inflate => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::Inflate;
                    IO::Uncompress::Inflate::inflate( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::Inflate::InflateError );
                return( $rv );
            },
            lzf => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnLzf;
                    IO::Uncompress::UnLzf::unlzf( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnLzf::UnLzfError );
                return( $rv );
            },
            lzip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnLzip;
                    IO::Uncompress::UnLzip::unlzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnLzip::UnLzipError );
                return( $rv );
            },
            lzma => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnLzma;
                    IO::Uncompress::UnLzma::unlzma( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnLzma::UnLzmaError );
                return( $rv );
            },
            lzop => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnLzop;
                    IO::Uncompress::UnLzop::unlzop( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnLzop::UnLzopError );
                return( $rv );
            },
            lzw => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Streem::LZW;
                    HTTP::Promise::Streem::LZW::decode_lzw( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Streem::LZW::LZWError );
                return( $rv );
            },
            qp => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::QuotedPrint;
                    HTTP::Promise::Stream::QuotedPrint::decode_qp( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::QuotedPrint::QuotedPrintError );
                return( $rv );
            },
            rawinflate => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::RawInflate;
                    IO::Uncompress::RawInflate::rawinflate( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::RawInflate::RawInflateError );
                return( $rv );
            },
            uu => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require HTTP::Promise::Stream::UU;
                    HTTP::Promise::Stream::UU::decode_uu( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $HTTP::Promise::Stream::UU::UUError );
                return( $rv );
            },
            xz => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnXz;
                    IO::Uncompress::UnXz::unxz( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnXz::UnXzError );
                return( $rv );
            },
            zip => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::Unzip;
                    IO::Uncompress::Unzip::unzip( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::Unzip::UnzipError );
                return( $rv );
            },
            zstd => sub
            {
                # try-catch
                local $@;
                my $rv = eval
                {
                    require IO::Uncompress::UnZstd;
                    IO::Uncompress::UnZstd::unzstd( $_[0] => $_[1], @_[2..$#_] );
                };
                if( $@ )
                {
                    return( undef, $@ );
                }
                $rv or return( undef, $IO::Uncompress::UnZstd::UnZstdError );
                return( $rv );
            },
        }
    };
    # rfc1945, section 3.5
    # Ref: <https://tools.ietf.org/html/rfc1945#section-3.5>
    $FILTER_MAP->{encode}->{ 'x-gzip' } = $FILTER_MAP->{encode}->{gzip};
    $FILTER_MAP->{decode}->{ 'x-gzip' } = $FILTER_MAP->{decode}->{gzip};
    $FILTER_MAP->{encode}->{ 'x-bzip2' } = $FILTER_MAP->{encode}->{bzip2};
    $FILTER_MAP->{decode}->{ 'x-bzip2' } = $FILTER_MAP->{decode}->{bzip2};
    # deflate <-> inflate, make the choice of word irrelevant
    $FILTER_MAP->{decode}->{deflate} = $FILTER_MAP->{decode}->{inflate};
    $FILTER_MAP->{encode}->{inflate} = $FILTER_MAP->{encode}->{deflate};
    $FILTER_MAP->{decode}->{rawdeflate} = $FILTER_MAP->{decode}->{rawinflate};
    $FILTER_MAP->{encode}->{rawinflate} = $FILTER_MAP->{encode}->{rawdeflate};
    $FILTER_MAP->{encode}->{ 'x-zip' } = $FILTER_MAP->{encode}->{zip};
    $FILTER_MAP->{decode}->{ 'x-zip' } = $FILTER_MAP->{decode}->{zip};
    # x-compress was used for LZW compression (the algorithm used in GIF), 
    # but is not actually used. There is a module Compress::LZW, but what is the point? 
    $FILTER_MAP->{encode}->{ 'quoted-printable' } = $FILTER_MAP->{encode}->{qp};
    $FILTER_MAP->{decode}->{ 'quoted-printable' } = $FILTER_MAP->{decode}->{qp};

    $ENCODING_SUFFIX = 
    {
        base64  => 'b64',
        brotli  => 'br',
        bzip2   => 'bz2',
        # See rfc1950
        # <https://fileinfo.com/extension/zz#pigz_zlib_compressed_file>
        deflate => 'zz',
        gzip    => 'gz',
        lzf     => 'lzf',
        # <https://fileinfo.com/extension/lz>
        lzip    => 'lz',
        # <https://fileinfo.com/extension/lzma>
        lzma    => 'lzma',
        lzop    => 'lzop',
        lzw     => 'lzw',
        qp      => 'qp',
        rawdeflate => 'rzz',
        uu      => 'uu',
        xz      => 'xz',
        zip     => 'zip',
        zstd    => 'zstd',
    };
}

sub init
{
    my $self = shift( @_ );
    my $src  = shift( @_ );
    return( $self->error( "No stream was provided." ) ) if( !defined( $src ) && !length( $src ) );
    my $type = ref( $src ) ? lc( Scalar::Util::reftype( $src ) ) : '';
    if( ref( $src ) )
    {
        if( $self->_is_a( $src => 'Module::Generic::File' ) )
        {
            $src = "$src";
        }
        elsif( $type ne 'scalar' && $type ne 'glob' && $type ne 'code' )
        {
            return( $self->error( "You can only provide a scalar reference, array reference, code reference or a glob as a reference element for the filter." ) );
        }
    }
    else
    {
        if( $src =~ /\n/ )
        {
            return( $self->error( "You cannot provide a text to set the filter. It can only be a scalar reference, array reference, a glob or a file path." ) );
        }
    }
    $self->{compress_params} = {};
    $self->{encoding}   = undef;
    $self->{decoding}   = undef;
    $self->{_init_strict_use_sub} = 1;
    $self->{_exception_class} = 'HTTP::Promise::Exception';
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->source( $src );
    $self->{read_tmp_file} = undef;
    $self->{src_file_handle} = undef;
    if( defined( $self->{encoding} ) && length( $self->{encoding} ) )
    {
        return( $self->error( "Encoding provided \"$self->{encoding}\" is unsupported." ) ) if( !exists( $FILTER_MAP->{encode}->{ $self->{encoding} } ) );
    }
    elsif( defined( $self->{decoding} ) && length( $self->{decoding} ) )
    {
        return( $self->error( "Decoding provided \"$self->{decoding}\" is unsupported." ) ) if( !exists( $FILTER_MAP->{decode}->{ $self->{decoding} } ) );
    }
    return( $self );
}

sub as_string
{
    my $self = shift( @_ );
    my $src  = $self->source;
    if( ref( $src ) )
    {
        my $type = lc( Scalar::Util::reftype( $src ) );
        if( $type eq 'scalar' )
        {
            return( length( ${$src} ) );
        }
        elsif( $type eq 'glob' )
        {
            if( $self->_is_a( $src => 'Module::Generic::Scalar::IO' ) )
            {
                return( join( '', $src->getlines ) );
            }
            elsif( $self->_is_object( $src ) && $self->_can( $src => 'seek' ) && $self->_can( $src => 'read' ) )
            {
                my $data = '';
                $src->seek(0,0) || return( $self->error( "Unable to seek source stream glob: $!" ) );
                while( $src->read( my $buff, 10240 ) )
                {
                    $data .= $buff;
                }
                return( $data );
            }
            elsif( fileno( $src ) )
            {
                my $data = '';
                CORE::seek( $src, 0, 0 ) || return( $self->error( "Unable to seek source stream glob: $!" ) );
                while( CORE::read( $src, my $buff, 10240 ) )
                {
                    $data .= $buff;
                }
                return( $data );
            }
        }
        elsif( $self->_is_a( $src => 'Module::Generic::File' ) )
        {
            return( $src->content );
        }
        return;
    }
    else
    {
        my $f = $self->new_file( $src ) || return( $self->pass_error );
        return( $f->content );
    }
}

sub compress_params { return( shift->_set_get_hash_as_mix_object( 'compress_params', @_ ) ); }

sub decodable { return( shift->_decodable_encodable( 0, @_ ) ); }

# Decoding $data and writing to stream:
#   $stream->decode( $data );
# Decoding stream and returning decoded data:
#   my $decoded = $stream->decode;
sub decode
{
    my( $self ) = @_;
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{encoding} //= '';
    $opts->{decoding} //= '';
    my $dec  = $opts->{decoding} || $opts->{encoding} || $self->decoding->lower;
    my $src  = $self->source;
    # Scalar reference or glob
    my $this = @_ >= 2 ? $_[1] : $src;
    my $size = $self->_get_size( $this );
    
    # No need to bother going further
    if( !defined( $dec ) || !length( $dec ) || !$size )
    {
        # $stream->decode( $data );
        return( $self ) if( @_ >= 2 );
        # my $decoded = $stream->decode;
        return( '' );
    }
    my $filters = $FILTER_MAP->{decode};
    return( $self->error( "Unknown decoding \"$dec\"." ) ) if( !exists( $filters->{ $dec } ) );
    my $params = $self->_io_compress_params( $opts );
    my $rv;
    # Decode some data provided and into the stream
    if( @_ >= 2 )
    {
        ( $rv, my $err ) = $filters->{ $dec }->( $_[0] => $src, %$params );
        return( $self->error( "Unable to decode $size bytes of data into the stream with $dec: $err" ) ) if( !defined( $rv ) );
        return( $rv );
    }
    # Decode the stream and return the decoded data
    else
    {
        my $buf;
        ( $rv, my $err ) = $filters->{ $dec }->( $src => \$buf, %$params );
        return( $self->error( "Unable to decode $size bytes of data from the stream with $dec: $err" ) ) if( !defined( $rv ) );
        return( $buf ) if( defined( $rv ) );
        return( $rv );
    }
}

sub decoding { return( shift->_set_get_scalar_as_object( 'decoding', @_ ) ); }

sub encodable { return( shift->_decodable_encodable( 1, @_ ) ); }

# Encoding $data and writing to stream:
#   $stream->encode( $data );
# Encoding stream and returning decoded data:
#   my $encoded = $stream->encode;
sub encode
{
    my( $self ) = @_;
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{encoding} //= '';
    my $enc  = $opts->{encoding} || $self->encoding->lower;
    my $src  = $self->source;
    # Scalar reference or glob
    my $this = @_ >= 2 ? $_[1] : $src;
    my $size = $self->_get_size( $this );
    
    # No need to bother going further
    if( !defined( $enc ) || !length( $enc ) || !$size )
    {
        # $stream->encode( $data );
        return( $self ) if( @_ >= 2 );
        # my $encoded = $stream->encode;
        return( '' );
    }
    my $filters = $FILTER_MAP->{encode};
    return( $self->error( "Unknown encoding \"$enc\". Supported encodings are: ", join( ', ', sort( keys( %$filters ) ) ) ) ) if( !exists( $filters->{ $enc } ) );
    my $params = $self->_io_compress_params( $opts );
    my $rv;
    # Encode some data provided and into the stream
    if( @_ >= 2 )
    {
        ( $rv, my $err ) = $filters->{ $enc }->( $_[0] => $src, %$params );
        return( $self->error( "Unable to encode $size bytes of data into the stream with $enc: $err" ) ) if( !defined( $rv ) );
        return( $rv );
    }
    # Encode the stream and return the decoded data
    else
    {
        my $buf;
        my $ref = \$buf;
        ( $rv, my $err ) = $filters->{ $enc }->( $src => \$buf, %$params );
        return( $self->error( "Unable to encode $size bytes of data from the stream with $enc: $err" ) ) if( !defined( $rv ) );
        return( $buf ) if( defined( $rv ) );
        return( $rv );
    }
}

sub encoding { return( shift->_set_get_scalar_as_object( 'encoding', @_ ) ); }

sub encoding2suffix
{
    my $self = shift( @_ );
    my $this = shift( @_ );
    return( $self->error( "Bad argument provided. encoding2suffix() takes either an array of encodings or a string or something that stringifies." ) ) if( !defined( $this ) || ( !$self->_is_array( $this ) && ( ref( $this ) && !overload::Method( $this => '""' ) ) ) );
    my $encodings = $self->new_array( $self->_is_array( $this ) ? $this : [split( /[[:blank:]\h]*,[[:blank:]\h]*/, lc( "${this}" ) )] );
    my $ext = $self->new_array;
    foreach( @$encodings )
    {
        return( $self->error( "Unknown encoding provided \"$_\"." ) ) if( !exists( $ENCODING_SUFFIX->{ $_ } ) );
        $ext->push( $ENCODING_SUFFIX->{ $_ } );
    }
    return( $ext );
}

sub load
{
    my $self = shift( @_ );
    my $enc  = shift( @_ ) || return( $self->error( "No encoding was provided." ) );
    $enc = lc( $enc );
    return(0) if( !exists( $CLASSES->{ $enc } ) );
    my $opts = $self->_get_args_as_hash( @_ );
    my $p = {};
    $p->{version} = $opts->{version} if( exists( $opts->{version} ) && length( $opts->{version} ) );
    my( $encoder, $decoder ) = @{$CLASSES->{ $enc }};
    my $ok = 0;
    for( $encoder, $decoder )
    {
        $ok++, next if( $_ eq $decoder && $decoder eq $encoder );
        $self->_load_class( $_, $p ) || next;
        $ok++;
    }
    return(1) if( $ok == 2 );
    return(0);
}

# $stream->read( $buffer, $len, $offset );
# $stream->read( $buffer, $len );
# $stream->read( $buffer );
# $stream->read( *buffer );
# $stream->read( sub{} );
# $stream->read( \$buffer );
# $stream->read( '/some/where/file.txt' );
sub read
{
    my( $self ) = @_;
    my $opts = {};
    $opts = pop( @_ ) if( ref( $_[-1] ) eq 'HASH' );
    $opts->{binmode} = 'raw' if( !exists( $opts->{binmode} ) || !length( $opts->{binmode} ) );
    my $src = $self->source;
    my $enc = $self->encoding->lower || lc( $opts->{encoding} );
    my $dec = $self->decoding->lower || lc( $opts->{decoding} );
    my $io = $self->{src_file_handle};
    my $tempfile = $self->{read_tmp_file};
    unless( $io )
    {
        $tempfile = $self->{read_tmp_file} = $self->new_tempfile ||
            return( $self->error( "Unable to get a new tempfile: ", $self->error ) );
        if( $enc )
        {
            my $params = $self->_io_compress_params( $opts );
            my $filters = $FILTER_MAP->{encode};
            return( $self->error( "Unknown encoding \"$enc\"." ) ) if( !exists( $filters->{ $enc } ) );
            my( $rv, $err ) = $filters->{ $enc }->( $self->_normalise( $src ) => "$tempfile", %$params );
            my $size = $self->_get_size( $src );
            return( $self->error( "Unable to encode $size bytes of data into the stream with $enc: $err" ) ) if( !defined( $rv ) );
            $io = $self->{src_file_handle} = $tempfile->open( '<', { binmode => $opts->{binmode} }) ||
                return( $self->pass_error( $tempfile ) );
        }
        elsif( $dec )
        {
            my $params = $self->_io_compress_params( $opts );
            my $filters = $FILTER_MAP->{decode};
            return( $self->error( "Unknown decoding \"$dec\"." ) ) if( !exists( $filters->{ $dec } ) );
            my( $rv, $err ) = $filters->{ $dec }->( $self->_normalise( $src ) => "$tempfile", %$params );
            my $size = $self->_get_size( $src );
            return( $self->error( "Unable to decode $size bytes of data into the stream with $dec and input '", $self->_normalise( $src ), "' and output '", $tempfile, "': $err" ) ) if( !defined( $rv ) );
            $io = $self->{src_file_handle} = $tempfile->open( '<', { binmode => $opts->{binmode} }) ||
                return( $self->pass_error( $tempfile ) );
        }
        else
        {
            my $type = lc( Scalar::Util::reftype( $src ) );
            if( $type eq 'scalar' )
            {
                my $s = $self->new_scalar( $src );
                $io = $self->{src_file_handle} = $s->open( '<' ) ||
                    return( $self->pass_error( $s->error ) );
            }
            elsif( $type eq 'glob' )
            {
                $io = $self->{src_file_handle} = $src;
            }
            elsif( !ref( $src ) )
            {
                my $f = $self->new_file( $src );
                $io = $self->{src_file_handle} = $f->open( '<', { $opts->{binmode} ? ( binmode => $opts->{binmode} ) : () }) ||
                    return( $self->pass_error( $f->error ) );
            }
            else
            {
                return( $self->error( "I do not know how to handle source '$src'." ) );
            }
        }
    }
    
    my $len;
    if( ref( $_[1] ) eq 'CODE' )
    {
        my $buf;
        # Because there is no buffer provided and we send the data chunk to a callback, the
        # offset option of the read() function is useless
        if( @_ >= 3 )
        {
            $len = $io->read( $buf, $_[2] );
            return( $self->error( "Unable to read ", $_[2], " bytes from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 2 )
        {
            $len = $io->read( $buf, $tempfile->length );
            return( $self->error( "Unable to read bytes from source: $!" ) ) if( !defined( $len ) );
        }
        
        # try-catch
        local $@;
        eval
        {
            $_[1]->( $buf );
        };
        if( $@ )
        {
            return( $self->error( "Callback raised an exception when sending it the ", length( $buf ), " bytes of data read from source: $@" ) );
        }
    }
    elsif( Scalar::Util::reftype( $_[1] ) eq 'SCALAR' )
    {
        if( @_ >= 4 )
        {
            $len = $io->read( ${$_[1]}, $_[2], $_[3] );
            return( $self->error( "Unable to read ", $_[2], " bytes at offset ", $_[3], " from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 3 )
        {
            $len = $io->read( ${$_[1]}, $_[2] );
            return( $self->error( "Unable to read ", $_[2], " bytes from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 2 )
        {
            $len = $io->read( ${$_[1]}, $tempfile->length );
            return( $self->error( "Unable to read bytes from source: $!" ) ) if( !defined( $len ) );
        }
    }
    elsif( Scalar::Util::reftype( $_[1] ) eq 'GLOB' )
    {
        my $buf;
        # Because there is no buffer provided and we send the data chunk to a glob, the
        # offset option of the read() function is useless
        if( @_ >= 3 )
        {
            $len = $io->read( $buf, $_[2] );
            return( $self->error( "Unable to read ", $_[2], " bytes from source: $!" ) ) if( !defined( $len ) );
            my $rv = CORE::print( $_[1], $buf );
            return( $self->error( "Unable to print ", CORE::length( $buf ), " bytes of data to provided file handle '", $_[1], "': $!" ) ) if( !$rv );
        }
        elsif( @_ >= 2 )
        {
            my $chunklen;
            while( $chunklen = $io->read( $buf, 10240 ) )
            {
                $len += $chunklen;
                #my $rv = CORE::print( $_[1], $buf );
                my $rv = $_[1]->print( $buf );
                return( $self->error( "Unable to print ", CORE::length( $buf ), " bytes of data to provided file handle '", $_[1], "': $!" ) ) if( !$rv );
            }
            return( $self->error( "Unable to read bytes from source: $!" ) ) if( !defined( $chunklen ) );
        }
    }
    # A file
    elsif( $self->_is_a( $_[1] => 'Module::Generic::File' ) || 
           ( !ref( $_[1] ) && 
             CORE::length( $_[1] ) &&
             CORE::index( $_[1], "\n" ) == -1
           ) )
    {
        my $f = $self->new_file( $_[1] ) || return( $self->pass_error );
        my $buf;
        # Because there is no buffer provided and we send the data chunk to a file, the
        # offset option of the read() function is useless
        if( @_ >= 3 )
        {
            $len = $io->read( $buf, $_[2] );
            return( $self->error( "Unable to read ", $_[2], " bytes from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 2 )
        {
            $len = $io->read( $buf, $tempfile->length );
            return( $self->error( "Unable to read bytes from source: $!" ) ) if( !defined( $len ) );
        }
        my $mode = $opts->{mode} ? $opts->{mode} : '>';
        my $params = {};
        $params->{binmode} = $opts->{binmode} if( $opts->{binmode} );
        $params->{autoflush} = $opts->{autoflush} if( $opts->{autoflush} );
        $f->open( $mode, $params ) || 
            return( $self->pass_error( $f->error ) );
        $f->print( $buf ) || return( $self->pass_error( $f->error ) );
        $f->close;
    }
    # A regular string
    else
    {
        if( @_ >= 4 )
        {
            $len = $io->read( $_[1], $_[2], $_[3] );
            return( $self->error( "Unable to read ", $_[2], " bytes at offset ", $_[3], " from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 3 )
        {
            $len = $io->read( $_[1], $_[2] );
            return( $self->error( "Unable to read ", $_[2], " bytes from source: $!" ) ) if( !defined( $len ) );
        }
        elsif( @_ >= 2 )
        {
            $len = $io->read( $_[1], $tempfile->length );
            return( $self->error( "Unable to read bytes from source: $!" ) ) if( !defined( $len ) );
        }
    }
    return( $len );
}

sub source { return( shift->_set_get_scalar( 'source', @_ ) ); }

sub suffix2encoding
{
    my $self = shift( @_ );
    my $file = shift( @_ ) || return( $self->pass_error( "No file was provided to guess encoding." ) );
    my @parts = reverse( split( /\./, $file ) );
    unless( defined( $SUFFIX_ENCODING ) && %$SUFFIX_ENCODING )
    {
        my @keys = keys( %$ENCODING_SUFFIX );
        my @vals = @$ENCODING_SUFFIX{ @keys };
        $SUFFIX_ENCODING = {};
        @$SUFFIX_ENCODING{ @vals } = @keys;
    }
    my $encs = $self->new_array;
    foreach( @parts )
    {
        if( exists( $SUFFIX_ENCODING->{ $_ } ) )
        {
            $encs->push( $SUFFIX_ENCODING->{ $_ } );
        }
        else
        {
            last;
        }
    }
    return( $encs->reverse );
}

sub supported
{
    my $self = shift( @_ );
    return( $self->error( "No encoding was provided to check if it exists." ) ) if( !@_ || !defined( $_[0] ) || !length( $_[0] ) );
    my $this = lc( shift( @_ ) );
    return(1) if( exists( $FILTER_MAP->{encode}->{ $this } ) || exists( $FILTER_MAP->{decode}->{ $this } ) );
    return(0);
}

# $stream->write( $data );
# $stream->write( \$data );
# $stream->write( *$data );
# $stream->write( '/some/where/file.txt' );
# $stream->write( sub{} );
sub write
{
    my( $self ) = @_;
    # No data was provided
    return(0) if( !defined( $_[1] ) || !length( $_[1] ) );
    my $src = $self->source;
    my $enc = $self->encoding->lower;
    my $dec = $self->decoding->lower;
    my $type = lc( Scalar::Util::reftype( $_[1] ) );
    my $data;
    my $size;
    my $len;
    if( $type eq 'code' )
    {
        # try-catch
        local $@;
        my $buf = eval
        {
            $_[1]->()
        };
        if( $@ )
        {
            return( $self->error( "Error getting data from callback: $@" ) );
        }
        $data = \$buf;
        $size = length( $$data );
    }
    else
    {
        $size = $self->_get_size( $_[1] );
        # If the data provided is not a reference i.e. a string and it does not have any 
        # CRLF sequence and it is not a file that exists, OR it has multiple CRLF 
        # sequences, then we treat it as a string, and to remove ambiguity, we make it a
        # scalar reference
        if( !ref( $_[1] ) && 
            (
                ( index( $_[1], "\n" ) == -1 &&  !-e( $_[1] ) ) ||
                ( index( $_[1], "\n" ) != -1 )
            ) )
        {
            $data = \$_[1];
        }
        elsif( $type eq 'scalar' )
        {
            $data = $_[1];
        }
        elsif( $self->_is_a( $_[1] => 'Module::Generic::File' ) ||
               $self->_can( $_[1] => 'filename' ) )
        {
            $data = $_[1]->filename;
        }
        # otherwise, it is either a scalar reference, a glob or a file, and if it is none
        # of those, we return an error
        else
        {
            $data = $_[1];
            return( $self->error( "Unsupported data type '", overload::StrVal( $data ), "'. You can only provide a string, a scalar reference, a code reference, a glob or a file path." ) ) if( ref( $data ) && $type ne 'scalar' && $type ne 'glob' && $type ne 'code' );
        }
        
        # If we are dealing with a file, open it and use its file glob instead, 
        # because some encoder like IO::Compress::Zip actually creates and archive of the file with the file path included, rather than just the file content as advertised.
        # See Bug #38
        # <https://github.com/pmqs/IO-Compress/issues/38>
        if( !ref( $data ) )
        {
            my $f = $self->new_file( $data );
            $data = $f->open( '<', { binmode => 'raw' } ) ||
                return( $self->pass_error( $f->error ) );
        }
    }

    my $stype = lc( Scalar::Util::reftype( $src ) );
    if( $stype eq 'code' )
    {
        if( $enc )
        {
            my $params = $self->_io_compress_params;
            # try-catch
            local $@;
            eval
            {
                $src->( $self->encode( $data, $params ) );
            };
            if( $@ )
            {
                return( $self->error( "Error executing calback to write $size bytes of data: $@" ) );
            }
            $len = $size;
        }
        elsif( $dec )
        {
            my $params = $self->_io_compress_params;
            # try-catch
            local $@;
            eval
            {
                $src->( $self->decode( $data, $params ) );
            };
            if( $@ )
            {
                return( $self->error( "Error executing calback to write $size bytes of data: $@" ) );
            }
            $len = $size;
        }
        else
        {
            if( $type eq 'scalar' )
            {
                $len = length( $$data );
                # try-catch
                local $@;
                eval
                {
                    $src->( $$data );
                };
                if( $@ )
                {
                    return( $self->error( "Error executing calback to write $size bytes of data: $@" ) );
                }
            }
            elsif( $type eq 'glob' )
            {
                my( $rv, $buf );
                while( $rv = CORE::read( $data, $buf, 10240 ) )
                {
                    # try-catch
                    local $@;
                    eval
                    {
                        $src->( $buf );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error executing calback to write $size bytes of data: $@" ) );
                    }
                    $len += length( $buf );
                }
                return( $self->error( "Unable to read data from glob provided: $!" ) ) if( !defined( $rv ) );
            }
            else
            {
                my $f = $self->new_file( $data ) || return( $self->pass_error );
                my $fh = $f->open( '<' ) || return( $self->pass_error( $f->error ) );
                my $buf;
                my $rv = $fh->read( $buf );
                return( $self->error( "Unable to read data from file \"$f\" provided: $!" ) ) if( !defined( $rv ) );
                # try-catch
                local $@;
                eval
                {
                    $src->( $buf );
                };
                if( $@ )
                {
                    return( $self->error( "Error executing calback to write $size bytes of data: $@" ) );
                }
                $fh->close;
                $len = length( $buf );
            }
        }
    }
    else
    {
        my $filters;
        if( $dec )
        {
            $filters = $FILTER_MAP->{decode};
        }
        elsif( $enc )
        {
            $filters = $FILTER_MAP->{encode};
        }
        
        my $rv;
        if( $dec )
        {
            my $params = $self->_io_compress_params;
            return( $self->error( "No encoding found for \"$dec\"." ) ) if( !exists( $filters->{ $dec } ) );
            # try-catch
            local $@;
            ( $rv, my $err ) = eval
            {
                $filters->{ $dec }->( $data => $src, %$params );
            };
            if( $@ )
            {
                return( $self->error( "Error ", ( $self->encode ? 'encoding' : 'decoding' ), " $size bytes of data: $@" ) );
            }
            return( $self->error( "Unable to decode data to write to source: $err" ) ) if( !defined( $rv ) );
            $len = $size;
        }
        elsif( $enc )
        {
            my $params = $self->_io_compress_params;
            return( $self->error( "No encoding found for \"$enc\"." ) ) if( !exists( $filters->{ $enc } ) );
            # try-catch
            local $@;
            ( $rv, my $err ) = eval
            {
                $filters->{ $enc }->( $data => $src, %$params );
            };
            if( $@ )
            {
                return( $self->error( "Error ", ( $self->encode ? 'encoding' : 'decoding' ), " $size bytes of data: $@" ) );
            }
            return( $self->error( "Unable to encode data to write to source: $err" ) ) if( !defined( $rv ) );
            $len = $size;
        }
        elsif( $stype eq 'scalar' )
        {
            if( $type eq 'scalar' )
            {
                $$src .= $$data;
                $len = length( $$data );
            }
            elsif( $type eq 'glob' )
            {
                my( $rv, $buf );
                while( $rv = CORE::read( $data, $buf, 10240 ) )
                {
                    $$src .= $buf;
                    $len += length( $buf );
                }
                return( $self->error( "Unable to read data from glob provided: $!" ) ) if( !defined( $rv ) );
            }
            else
            {
                my $f = $self->new_file( $data ) || return( $self->pass_error );
                my $fh = $f->open( '<' ) ||
                    return( $self->pass_error( $f->error ) );
                my $buf;
                my $rv = $fh->read( $buf );
                return( $self->error( "Unable to read data from file \"$f\" provided: $!" ) ) if( !defined( $rv ) );
                $$src .= $buf;
                $len = length( $buf );
            }
        }
        elsif( $stype eq 'glob' )
        {
            if( $type eq 'scalar' )
            {
                print( $src, $$data ) ||
                    return( $self->error( "Unable to write ", length( $$data ), " bytes of data to source glob: $!" ) );
                $len = length( $$data );
            }
            elsif( $type eq 'glob' )
            {
                my $buf;
                while( CORE::read( $data, $buf, 10240 ) )
                {
                    print( $src, $buf ) ||
                        return( $self->error( "Unable to write ", length( $buf ), " bytes of data to source glob: $!" ) );
                    $len += length( $buf );
                }
            }
            else
            {
                my $f = $self->new_file( $data ) || return( $self->pass_error );
                my $fh = $f->open( '<' ) ||
                    return( $self->pass_error( $f->error ) );
                my $buf;
                while( $fh->read( $buf, 10240 ) )
                {
                    print( $src, $buf ) ||
                        return( $self->error( "Unable to write ", length( $buf ), " bytes of data to source glob: $!" ) );
                    $len += length( $buf );
                }
            }
        }
        else
        {
            my $f = $self->new_file( $src ) || return( $self->pass_error );
            my $fh = $f->open( '>', { autoflush => 1 } ) || return( $self->pass_error( $f->error ) );
            if( $type eq 'scalar' )
            {
                $fh->print( $$data ) ||
                    return( $self->error( "Unable to write ", length( $$data ), " bytes of data to file \"$f\": $!" ) );
                $len = length( $$data );
            }
            elsif( $type eq 'glob' )
            {
                my $buf;
                while( CORE::read( $data, $buf, 10240 ) )
                {
                    $fh->print( $buf ) ||
                    return( $self->error( "Unable to write ", length( $buf ), " bytes of data to file \"$f\": $!" ) );
                    $len += length( $buf );
                }
            }
            else
            {
                my $f2 = $self->new_file( $data ) || return( $self->pass_error );
                my $fh2 = $f2->open( '<' ) ||
                    return( $self->pass_error( $f2->error ) );
                my $buf;
                while( $fh2->read( $buf, 10240 ) )
                {
                    $fh->print( $buf ) ||
                        return( $self->error( "Unable to write ", length( $buf ), " bytes of data to source file \"$f\": $!" ) );
                    $len += length( $buf );
                }
                $fh2->close;
            }
            $fh->close;
        }
    }
    return( $len );
}

sub _decodable_encodable
{
    my $self = shift( @_ );
    # 1 for encodable, 0 for decodable
    my $enc_or_dec = shift( @_ );
    my $what = shift( @_ ) || 'all';
    my $list = $self->new_array;
    my $offset = $enc_or_dec ? 0 : 1;
    if( $self->_is_array( $what ) )
    {
        $list = $what;
    }
    elsif( $what eq 'all' || $what eq 'auto' )
    {
        $list = [sort( keys( %$CLASSES ) )];
    }
    elsif( $what eq 'browser' )
    {
        foreach( keys( %$CLASSES ) )
        {
            $list->push( $_ ) if( $CLASSES->{ $_ }->[2] );
        }
    }
    else
    {
        return( $self->error( "Unsupported keyword '$what' used." ) );
    }
    
    my $res = $self->new_array;
    foreach my $enc ( @$list )
    {
        # inflate is just an alias for deflate
        next if( $enc eq 'inflate' || $enc eq 'rawinflate' || substr( $enc, 0, 2 ) eq 'x-' );
        if( !exists( $CLASSES->{ $enc } ) )
        {
            warn( "Unsupported content encoding \"$enc\"." ) if( $self->_is_warnings_enabled( 'HTTP::Promise' ) );
            next;
        }
        my $encoder_class = $CLASSES->{ $enc }->[$offset];
        my $is_installed_method = ( $enc_or_dec ? 'is_encoder_installed' : 'is_decoder_installed' );
        if( my $coderef = $encoder_class->can( $is_installed_method ) )
        {
            $res->push( $enc ) if( $coderef->() );
        }
        elsif( $self->_is_class_loadable( $encoder_class ) )
        {
            $res->push( $enc );
        }
    }
    return( $res );
}

sub _get_size
{
    my $self = shift( @_ );
    if( ref( $_[0] ) )
    {
        my $type = lc( Scalar::Util::reftype( $_[0] ) );
        if( $type eq 'scalar' )
        {
            return( length( ${$_[0]} ) );
        }
        elsif( $type eq 'glob' )
        {
            if( $self->_is_a( $_[0] => 'Module::Generic::Scalar::IO' ) )
            {
                return( $_[0]->size );
            }
            elsif( $self->_is_object( $_[0] ) && $self->_can( $_[0] => 'size' ) )
            {
                return( $_[0]->size );
            }
            elsif( fileno( $_[0] ) )
            {
                return( -s( $_[0] ) );
            }
        }
        elsif( $self->_is_a( $_[0] => 'Module::Generic::File' ) )
        {
            return( $_[0]->size );
        }
        return;
    }
    # If the data provided is not a reference i.e. a string and it does not have any 
    # CRLF sequence and it is not a file that exists, OR it has multiple CRLF 
    # sequences, then we treat it as a string, and to remove ambiguity, we make it a
    # scalar reference
    elsif( !ref( $_[0] ) && 
           (
               ( index( $_[0], "\n" ) == -1 &&  !-e( $_[0] ) ) ||
               ( index( $_[0], "\n" ) != -1 )
           ) )
    {
        return( length( $_[0] ) );
    }
    else
    {
        return( -s( $_[0] ) );
    }
}

sub _io_compress_params
{
    my $self = shift( @_ );
    my $opts = {};
    my $ref = $self->compress_params;
    if( @_ )
    {
        $opts = shift( @_ );
        my @keys = grep( /^[A-Z]\w+$/, keys( %$opts ) );
        @$ref{ @keys } = @$opts{ @keys } if( scalar( @keys ) );
    }
    return( $ref );
}

# Because the IO::Compress and IO::Uncompress family does not recognise a scalar object 
# as a valid scalar reference, we have to normalise it, before we can pass it to the filters
# Remove this once IO::Compress has accepted my pull request to change
# IO::Compress::Base::Common->whatIs made on 2022-04-11
# <https://github.com/pmqs/IO-Compress/pull/40>
sub _normalise
{
    my $self = shift( @_ );
    if( ref( $_[0] ) )
    {
        my $type = lc( Scalar::Util::reftype( $_[0] ) );
        if( $type eq 'scalar' )
        {
            # if it is a regular scalar reference, we return it
            # return( $self->_is_object( $_[0] ) ? \${$_[0]} : $_[0] );
            if( $self->_is_object( $_[0] ) )
            {
                my $tmp = ${$_[0]};
                return( \$tmp );
            }
            else
            {
                return( $_[0] );
            }
        }
        elsif( $type eq 'glob' )
        {
            return( $_[0] );
        }
        elsif( $self->_is_a( $_[0] => 'Module::Generic::File' ) || $self->_can( $_[0] => 'filename' ) )
        {
            return( $_[0]->filename );
        }
        else
        {
            return( $_[0] );
        }
    }
    else
    {
        return( $_[0] );
    }
}

# NOTE: sub FREEZE is inherited

sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

# NOTE: sub THAW is inherited

# NOTE: HTTP::Promise::Stream::Generic class
{
    package
        HTTP::Promise::Stream::Generic;
    BEGIN
    {
        use strict;
        use warnings;
        use parent qw( Module::Generic );
        use vars qw( $VERSION $EXCEPTION_CLASS );
        use Module::Generic::File::IO;
        use Module::Generic::Scalar::IO;
        # use Nice::Try;
        our $EXCEPTION_CLASS = 'HTTP::Promise::Exception';
        our $VERSION = $HTTP::Promise::Stream::VERSION;
    };

    use strict;
    use warnings;

    sub init
    {
        my $self = shift( @_ );
        my $class = ( ref( $self ) || $self );
        $self->{_init_strict_use_sub} = 1;
        no strict 'refs';
        $self->{_exception_class} = defined( ${"${class}\::EXCEPTION_CLASS"} ) ? ${"${class}\::EXCEPTION_CLASS"} : $EXCEPTION_CLASS;
        $self->SUPER::init( @_ ) || return( $self->pass_error );
        return( $self );
    }

    sub _get_glob_from_arg
    {
        my $self = shift( @_ );
        my $this = shift( @_ );
        return( $self->error( "No argument was provided." ) ) if( !defined( $this ) || ( !ref( $this ) && !length( $this ) ) );
        my $opts = $self->_get_args_as_hash( @_ );
        $opts->{write} = 0 if( !exists( $opts->{write} ) );
        my $mode = $opts->{write} ? '+>' : '<';
        my $fh;
        my $is_native_glob = 0;
        if( $self->_is_glob( $this ) )
        {
            $fh = $this;
            # even if this is a scalar reference opened in memory, perl will return -1, which is true
            $is_native_glob++ if( fileno( $this ) );
        }
        elsif( $self->_is_scalar( $this ) )
        {
            $fh = Module::Generic::Scalar::IO->new( $this, $mode ) ||
                return( $self->pass_error( Module::Generic::Scalar::IO->error ) );
            $is_native_glob++;
        }
        else
        {
            my $f = $self->new_file( "$this" ) || return( $self->pass_error );
            return( $self->error( "File '$this' does not exist." ) ) if( !$f->exists && !$opts->{write} );
            $fh = $f->open( $mode, { binmode => 'raw', ( $opts->{write} ? ( autoflush => 1 ) : () ) } ) ||
                return( $self->pass_error( $f->error ) );
            $is_native_glob++;
        }
        my $flags;
        if( $self->_can( $fh => 'fcntl' ) )
        {
            $flags = $fh->fcntl( F_GETFL, 0 );
        }
        else
        {
            $flags = fcntl( $fh, F_GETFL, 0 );
        }
    
        if( defined( $flags ) )
        {
            if( $opts->{write} )
            {
                unless( $flags & ( O_RDWR | O_WRONLY | O_APPEND ) )
                {
                    return( $self->error( "Filehandle provided does not have write permission enabled." ) );
                }
            }
            # read mode then
            else
            {
                unless( ( ( $flags & O_RDONLY ) == O_RDONLY ) || ( $flags & O_RDWR ) )
                {
                    return( $self->error( "Filehandle provided does not have read permission enabled. File handle flags value is '$flags'" ) );
                }
            }
        }
    
        # We check if the file handle is an object, in which case we use its method, because
        # it may not be a true glob and calling perl's core read() or print() on it would not
        # work unless that glob object has implemented a tie. See perltie manual page.
        my $op;
        my $meth;
        if( $opts->{write} )
        {
            if( $is_native_glob )
            {
                $op = sub
                {
                    my $rv = print( $fh @_ );
                    return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $!" ) ) if( !defined( $rv ) );
                    return( $rv );
                };
            }
            elsif( ( $meth = ( $self->_can( $fh => 'print' ) || $self->_can( $fh => 'write' ) ) ) )
            {
                $op = sub
                {
                    # try-catch
                    local $@;
                    my $rv = eval
                    {
                        $fh->$meth( @_ );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $@" ) );
                    }
                    if( !defined( $rv ) )
                    {
                        my $err;
                        if( defined( $! ) )
                        {
                            $err = $!;
                        }
                        elsif( $self->_can( $fh => 'error' ) )
                        {
                            $err = $fh->error;
                        }
                        elsif( $self->_can( $fh => 'errstr' ) )
                        {
                            $err = $fh->errstr;
                        }
                        return( $self->error( "Error writing ", CORE::length( $_[0] ), " bytes of data to output: $err" ) );
                    }
                    return( $rv );
                };
            }
            else
            {
               return( $self->error( "The file handle provided is not a native opened one and does not support the print() or write() methods." ) );
            }
        }
        else
        {
            if( $is_native_glob )
            {
                $op = sub
                {
                    my $n = read( $fh, $_[0], $_[1] );
                    return( $self->error( "Error reading ", $_[1], " bytes of data from input: $!" ) ) if( !defined( $n ) );
                    return( $n );
                };
            }
            elsif( $self->_can( $fh => 'read' ) )
            {
                $op = sub
                {
                    # try-catch
                    local $@;
                    my $n = eval
                    {
                        $fh->read( @_ );
                    };
                    if( $@ )
                    {
                        return( $self->error( "Error reading ", $_[1], " bytes of data from input: $@" ) );
                    }
                    if( !defined( $n ) )
                    {
                        my $err;
                        if( defined( $! ) )
                        {
                            $err = $!;
                        }
                        elsif( $self->_can( $fh => 'error' ) )
                        {
                            $err = $fh->error;
                        }
                        elsif( $self->_can( $fh => 'errstr' ) )
                        {
                            $err = $fh->errstr;
                        }
                        return( $self->error( "Error reading ", $_[1], " bytes of data from intput: $err" ) );
                    }
                    return( $n );
                };
            }
            else
            {
               return( $self->error( "The file handle provided is not a native opened one and does not support the read() method." ) );
            }
        }
        return( $fh, $op );
    }

    # NOTE: sub FREEZE is inherited

    sub STORABLE_freeze { CORE::return( CORE::shift->FREEZE( @_ ) ); }

    sub STORABLE_thaw { CORE::return( CORE::shift->THAW( @_ ) ); }

    # NOTE: sub THAW is inherited
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Stream - Data Stream Encoding and Decoding

=head1 SYNOPSIS

    use HTTP::Promise::Stream;
    my $this = HTTP::Promise::Stream->new || 
        die( HTTP::Promise::Stream->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

L<HTTP::Promise::Stream> serves to set a stream of data tha that optionally may need to be encoding or decoding, and read or write data from or to it that may also need to be compressed or decompressed.

Once those versatile parameters are set, one can use the class method to access or write the data and the necessary encoding or decoding is done automatically.

=head1 CONSTRUCTOR

=head2 new

Provided with a stream source, and some optional parameters and this will return a new L<HTTP::Promise::Stream> object.

Currently supported stream sources are: scalar reference, glob and file path.

If an error occurred, this sets an L<error|Module::Generic/error> and returns C<undef>

Supported parameters are:

=over 4

=item * C<decoding>

A string representing the encoding to use for decoding data. Currently supported encodings are: gzip, bzip2, deflate/inflate and zip

=item * C<encoding>

A string representing the encoding to use for encoding data. Currently supported encodings are: gzip, bzip2, deflate/inflate and zip

=back

=head1 METHODS

=head2 as_string

Returns the source stream as a string, or C<undef> and an L<error|Module::Generic/error> occurred.

=head2 compress_params

Sets or gets an hash of parameters-value pairs to be used for the compression algorithm used.

=head2 decodable

Provided with a C<target> and this returns an L<array object|Module::Generic::Array> of decoders that are installed.

The C<target> can be a string or an array reference of decoder names. If the target string C<all> is specified, then, this will check all supported encodings. See L</supported>. If the target string C<browser> is specified, then ths will check only the supported encodings that are also supported by web browsers. If no target is specified, it defaults to C<all>.

If the target is an array reference, it will return the list of supported decoders in the order provided.

    my $all = $stream->decodable;
    # Same as above
    my $all = $stream->decodable( 'all' );
    my $all = $stream->decodable( 'browser' );
    my $all = $stream->decodable( [qw( gzip br deflate )] );
    # $all could contain gzip and br for example

Note that for most encoding, encoding and decoding is done by different classes.

=head2 decode

    $stream->decode( $data );
    $stream->decode( $data, { encoding => bzip2 } );
    $stream->decode( $data, { decoding => bzip2 } );
    my $decoded = $stream->decode;
    my $decoded = $stream->decode( { encoding => bzip2 } );
    my $decoded = $stream->decode( { decoding => bzip2 } );

This behaves in two different ways depending on the parameters provided:

=over 4

=item 1. with C<data> provided

This will decode the C<data> provided using the encoding specified and write the decoded data to the source stream.

=item 2. without C<data> provided

This will decode the source stream directly and return the data thus decoded.

=back

This method will take the required encoding in the following order: from the C<decoding> parameter, from the C<encoding> parameter, or from L</decoding> as set during object instantiation.

If the encoding specified is not supported this will return an error.

It returns true upon success, or sets an L<error|Module::Generic/error> and returns C<undef>

=head2 decoding

This is a string. Sets or gets the encoding used for decoding. Supported encodings are: gzip, bzip2, inflate/deflate and zip

=head2 encodable

Provided with a C<target> and this returns an L<array object|Module::Generic::Array> of encoders that are installed.

The C<target> can be a string or an array reference of decoder names. If the target string C<all> is specified, then, this will check all supported encodings. See L</supported>. If the target string C<browser> is specified, then ths will check only the supported encodings that are also supported by web browsers. If no target is specified, it defaults to C<all>.

If the target is an array reference, it will return the list of supported encoders in the order provided.

    my $all = $stream->encodable;
    # Same as above
    my $all = $stream->encodable( 'all' );
    my $all = $stream->encodable( 'browser' );
    my $all = $stream->encodable( [qw( gzip br deflate )] );
    # $all could contain gzip and br for example

Note that for most encoding, encoding and decoding is done by different classes.

=head2 encode

    $stream->encode( $data );
    $stream->encode( $data, { encoding => bzip2 } );
    $stream->encode( $data, { decoding => bzip2 } );
    my $encoded = $stream->encode;
    my $encoded = $stream->encode( { encoding => bzip2 } );
    my $encoded = $stream->encode( { decoding => bzip2 } );

This is the alter ego of L</decode>

This behaves in two different ways depending on the parameters provided:

=over 4

=item 1. with C<data> provided

This will encode the C<data> provided using the encoding specified and write the encoded data to the source stream.

=item 2. without C<data> provided

This will encode the source stream directly and return the data thus encoded.

=back

This method will take the required encoding in the following order: from the C<encoding> parameter, or from L</encoding> as set during object instantiation.

If the encoding specified is not supported this will return an error.

It returns true upon success, or sets an L<error|Module::Generic/error> and returns C<undef>

=head2 encoding

This is a string. Sets or gets the encoding used for encoding. Supported encodings are: gzip, bzip2, inflate/deflate and zip

=head2 encoding2suffix

Provided with a string of comma-separated encodings, or an array reference of encodings and this will return an L<array object|Module::Generic::Array> of associated file extensions.

For example:

    my $a = HTTP::Promise::Stream->encoding2suffix( [qw( base64 gzip )] );
    # $a contains: b64 and gz

    my $a = HTTP::Promise::Stream->encoding2suffix( 'gzip' );
    # $a contains: gz

=head2 load

This attempts the load the specified encoding related class and returns true upon success or false otherwise.

It sets an L<error|Module::Generic/error> and returns C<undef> upon error.

For example:

    if( HTTP::Promise::Stream->load( 'bzip2' ) )
    {
        my $s = HTTP::Promise::Stream->new( \$data, encoding => 'bzip2' );
        my $output = Module::Generic::Scalar->new;
        my $len = $s->read( $output, { Transparent => 0 } );
        die( $s->error ) if( !defined( $len ) );
        say "Ok, $len bytes were encoded.";
    }
    else
    {
        say "Encoder/decoder bzip2 related modules are not installed on this system.";
    }

See also L</supported>, which will tell you if L<HTTP::Promise::Stream> even supports the specified encoding.

=head2 read

    $stream->read( $buffer );
    $stream->read( $buffer, $len );
    $stream->read( $buffer, $len, $offset );
    $stream->read( *buffer );
    $stream->read( *buffer, $len );
    $stream->read( sub{} );
    $stream->read( sub{}, $len );
    $stream->read( \$buffer );
    $stream->read( \$buffer, $len );
    $stream->read( \$buffer, $len, $offset );
    $stream->read( '/some/where/file.txt' );
    $stream->read( '/some/where/file.txt', $len );

Provided with some parameters, as detailed below, and this will either encode or decode the stream if any encoding was provided at all and into the read buffer specified.

Possible read buffers are:

=over 4

=item * scalar

=item * scalar reference

=item * file handle (glob)

=item * subroutine reference or anonymous subroutine

=item * file path

=back

It takes as optional parameters the C<length> of data, possibly encoded or decoded if any encoding was provided, and an optional C<offset>. However, note that the C<offset> argument is not used and ignored if the data buffer is not a string or a scalar reference.

Also you can specify an hash reference of options as the last parameter. Recognised options are:

=over 4

=item * autoflush

Boolean value. If true, this will set the auto flush.

=item * binmode

The encoding to be used when opening the file specified, if one is specified. See L</binmode>

=item * mode

The mode in which to open the file specified, if one is specified.

Possible modes can be >, +>, >>, +<, w, w+, r+, a, a+, < and r or an integer representing a bitwise value such as O_APPEND, O_ASYNC, O_CREAT, O_DEFER, O_EXCL, O_NDELAY, O_NONBLOCK, O_SYNC, O_TRUNC, O_RDONLY, O_WRONLY, O_RDWR. For example: C<O_WRONLY|O_APPEND> For that see L<Fcntl>

=item * other parameters starting with an uppercase letter

Those parameters will be passed directly to the encoder/decoder.

    my $s = HTTP::Promise::Stream->new( \$data, decoding => 'inflate' );
    # Transparent and its value are passed directly to IO::Uncompress::Inflate
    $s->read( \$output, { Transparent => 0 } );

=back

A typical recommended parameter used for the C<IO::Compress> and C<IO::Uncompress> families is C<Transparent> set to C<0>, otherwise, the default is C<1> and it would be lenient and any encoding/decoding issues with the data would be ignored.

For example, when using C<inflate> to uncompress data compressed with C<deflate>, some encoder do not format the data correctly, or declare it as C<deflate> when they really meant C<rawdeflate>, i.e. without the zlib headers and trailers. By default with C<Transparent> set to C<1>, L<IO::Uncompress::Inflate> will simply pass through the data. However, you are better of catching the error and resort to using C<rawinflate> instead.

For example:

    use v5.17;
    use HTTP::Promise::Stream;
    my $data = '80jNyclXCM8vyklRBAA=';
    my $buff = '';
    my $s = HTTP::Promise::Stream->new( \$data, decoding => 'base64' ) ||
        die( HTTP::Promise::Stream->error );
    my $len = $s->read( \$buff );
    die( $s->error ) if( !defined( $len ) );
    
    say "Now inflating data.";
    $data = $buff;
    $buff = '';
    my $s = HTTP::Promise::Stream->new( \$data, decoding => 'deflate' ) ||
        die( HTTP::Promise::Stream->error );
    $len = $s->read( \$buff, { Transparent => 0 } );
    if( !defined( $len ) )
    {
        # Trying with rawinflate instead
        if( $s->error->message =~ /Header Error: CRC mismatch/ )
        {
            say "Found deflate encoding error (", $s->error->message, "), trying with rawinflate instead.";
            my $s = HTTP::Promise::Stream->new( \$data, decoding => 'rawdeflate' ) ||
                die( HTTP::Promise::Stream->error );
            $len = $s->read( \$buff, { Transparent => 0 } );
            die( $s->error ) if( !defined( $len ) );
        }
        else
        {
            die( $s->error );
        }
    }
    say $buff; # Hello world

=head2 source

Set or get the source stream.

=head2 suffix2encoding

Provided with a filename, and this will return an L<array object|Module::Generic::Array> containing the encoding naes associated with the extensions found.

For example:

    my $a = HTTP::Promise::Stream->suffix2encoding( 'file.html.gz' );
    # $a contains: gzip

    my $a = HTTP::Promise::Stream->suffix2encoding( 'file.html' );
    # $a contains nothing

=head2 supported

Provided with an encoding name and this returns true if it is supported, or false otherwise.

Currently supported encodings are:

=over 4

=item Base64

Supported natively. See L<HTTP::Promise::Stream::Base64>

=item Brotli

Requires L<IO::Compress::Brotli> for encoding and L<IO::Uncompress::Brotli> for decoding.

See also L<caniuse|https://caniuse.com/brotli>

=item Bzip2

Requires L<IO::Compress::Bzip2> for encoding and L<IO::Uncompress::Bunzip2> for decoding.

=item Deflate and Inflate

Requires L<IO::Compress::Deflate> for encoding and L<IO::Uncompress::Inflate> for decoding.

This is the same as C<rawdeflate> and C<rawinflate>, except it has zlib headers and trailers.

See also its L<rfc1950|https://tools.ietf.org/html/rfc1950>, L<the Wikipedia page|https://en.wikipedia.org/wiki/Deflate> and L<Mozilla documentation about Content-Encoding|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding#directives>

Note that some web server announce data encoded with C<deflate> whereas they really mean C<rawdeflate>, so you might want to use the C<Transparent> parameter set to C<0> when using L</read>

=item Gzip

Requires L<IO::Compress::Gzip> for encoding and L<IO::Uncompress::Gunzip> for decoding.

See also L<caniuse|https://caniuse.com/sr_content-encoding-gzip>

=item Lzf

This is Lempel-Ziv-Free compression.

Requires L<IO::Compress::Lzf> for encoding and L<IO::Uncompress::UnLzf> for decoding.

See L<Stackoverflow discussion|https://stackoverflow.com/questions/5089112/whatre-lzo-and-lzf-and-the-differences>

=item Lzip

Requires L<IO::Compress::Lzip> for encoding and L<IO::Uncompress::UnLzip> for decoding.

=item Lzma

Requires L<IO::Compress::Lzma> for encoding and L<IO::Uncompress::UnLzma> for decoding.

See L<Wikipedia page|https://fr.wikipedia.org/wiki/LZMA>

=item Lzop

Requires L<IO::Compress::Lzop> for encoding and L<IO::Uncompress::UnLzop> for decoding.

"lzop is a file compressor which is very similar to L<gzip|http://www.gzip.org/>. lzop uses the L<LZO data compression library|http://www.oberhumer.com/opensource/lzo/> for compression services, and its main advantages over gzip are much higher compression and decompression speed (at the cost of some compression ratio)."

See the L<compressor home page|https://www.lzop.org/> and L<Wikipedia page|https://en.wikipedia.org/wiki/Lzop>

=item Lzw

This is Lempel-Ziv-Welch compression.

Requires L<Compress::LZW> for encoding and for decoding.

A.k.a C<compress>, this was used commonly until some corporation purchased the patent and started asking everyone for royalties. The patent expired in 2003. Gzip took over since then.

=item QuptedPrint

Requires the XS module L<MIME::QuotedPrint> for encoding and decoding.

This encodes and decodes the quoted-printable data according to L<rfc2045, section 6.7|https://tools.ietf.org/html/rfc2045#section-6.7>

See also the L<Wikipedia page|https://en.wikipedia.org/wiki/Quoted-printable>

=item Raw deflate

Requires L<IO::Compress::RawDeflate> for encoding and L<IO::Uncompress::RawInflate> for decoding.

This is the same as C<deflate> and C<inflate>, but without the zlib headers and trailers.

See also its L<rfc1951|https://tools.ietf.org/html/rfc1951> and L<Mozilla documentation about Content-Encoding|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding#directives>

=item UU encoding and decoding

Supported natively. See L<HTTP::Promise::Stream::UU>

=item Xz

Requires L<IO::Compress::Xz> for encoding and L<IO::Uncompress::UnXz> for decoding.

Reportedly, "xz achieves higher compression rates than alternatives like gzip and bzip2. Decompression speed is higher than bzip2, but lower than gzip. Compression can be much slower than gzip, and is slower than bzip2 for high levels of compression, and is most useful when a compressed file will be used many times."

See L<compressor home page|https://tukaani.org/xz/> and L<Wikipedia page|https://en.wikipedia.org/wiki/XZ_Utils>

=item Zip

Requires L<IO::Compress::Zip> for encoding and L<IO::Uncompress::Unzip> for decoding.

=item Zstd

Requires L<IO::Compress::Zstd> for encoding and L<IO::Uncompress::UnZstd> for decoding.

See L<rfc8878|https://tools.ietf.org/html/rfc8878> and L<Wikipedia page|https://en.wikipedia.org/wiki/Zstd>

=back

See also L</load>, which will tell you if the specified encoding related modules are installed on the system or not.

=head2 write

    $stream->write( $data );
    $stream->write( \$data );
    $stream->write( *$data );
    $stream->write( '/some/where/file.txt' );
    $stream->write( sub{} );

Provided with some data, and this will read the data provided, and write it, possibly encoded or decoded, depending on whether a decoding or encoding was provided, to the stream source.

It returns the amount of bytes written to the source stream, but before any possible encoding or decoding.

The data that can be provided are:

=over 4

=item * string

Note that the difference between a file and a string is slim. To distinguish the two, this method will treat as a string any value that is not a reference and that either contains a CRLF sequence, or that does not contain a CRLF sequence and is not an existing file.

=item * scalar reference

=item * file handle (glob)

=item * file path

Note that the difference between a file and a string is slim. So to distinguish the two, this method will treat as a file a value that has no CRLR sequence

=item * code reference (anonymous subroutine or subroutine reference)

It will be called once and expect data in return. If the code executed dies, the exception will be trapped using try-catch block from L<Nice::Try>

=back

The behaviour is different depending on the source type and the data type being provided. Below is an in-depth explanation:

=over 4

=item 1. Source stream is a code reference

=over 8

=item 1.1 Data is to be encoded

Data is encoded with L</encode>, then the source code reference is executed, passing it the encoded data

=item 1.2 Data is to be decoded

Data is decoded with L</decode>, then the source code reference is executed, passing it the decoded data

=item 1.3 Data is scalar reference

The source code reference is executed, passing it the content of the scalar reference

=item 1.4 Data is a glob

The file handle is read by chunks of 10Kb (10240 bytes) and each time the source code reference is called passing it the data chunk read.

=item 1.5 Data is a file path

The file is opened in read mode, and all its content is provided in one pass to the source code reference.

=back

=item 2. Data is the be encoded

The appropriate encoder is called to encode the data and write to the source stream.

=item 3. Data is to be decoded

The appropriate decoder is called to decode the data and write to the source stream.

=item 4. Source stream is a scalar reference

=over 8

=item 4.1 Data is a scalar reference

The provided data is simply appended to the source stream.

=item 4.2 Data is a glob

The file handle is read by chunks of 10Kb (10240 bytes) and appended to the source stream.

=item 4.3 Data is a file path

The file is opened in read mode and its content appended to the source stream.

=back

=item 5. Source stream is a glob

=over 8

=item 5.1 Data is a scalar reference

The file handle of the source stream is called with L</print> and the data is printed to it.

=item 5.2 Data is a glob

The data file handle is read by chunks of 10Kb (10240 bytes) and each one printed to the source stream file handle.

=item 5.3 Data is a file path

The given file path is read in read mode and each chunk of 10Kb (10240 bytes) read is printed to the source stream file handle.

=back

=item 6. Source stream is a file path

The source file is opened in write clobbering mode.

=over 8

=item 6.1 Data is a scalar reference

The data is printed to the source stream

=item 6.2 Data is a glob

Data from the glob is read by chunks of 10Kb (10240 bytes) and each one printed to the source stream

=item 6.3 Data is a file path.

The file is opened in read mode and its content is read by chunks o 10Kb (10240 bytes) and each chunk printed to the source stream.

=back

=back

=for Pod::Coverage _get_size

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Compression>, L<Content-Encoding documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Encoding>

L<Wikipedia page|https://en.wikipedia.org/wiki/HTTP_compression>

L<PerlIO::via::gzip>, L<PerlIO::via::Bzip2>, L<PerlIO::via::Base64>, L<PerlIO::via::QuotedPrint>, L<PerlIO::via::xz>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
