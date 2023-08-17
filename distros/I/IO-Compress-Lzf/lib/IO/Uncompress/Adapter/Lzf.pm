package IO::Uncompress::Adapter::Lzf;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.206 qw(:Status);
use Compress::LZF ;

our ($VERSION, @ISA);
$VERSION = '2.206';


sub mkUncompObject
{
    return bless {
                  'CompBytes'    => 0,
                  'UnCompBytes'  => 0,
                  'Error'        => '',
                  'ErrorNo'      => 0,
                  'Identity'     => 0,
                  'USize'        => 0,
                  'ConsumesInput' => 0,
                 } ;
}

sub setIdentity
{
    my $self = shift ;
    $self->{Identity} = 1 ;
}

sub setUSize
{
    my $self = shift ;
    my $size = shift ;
    $self->{USize} = $size ;
}

sub mk_c_lzf_header_length
{
    my $usize = shift ;
    my @dst;

    if ($usize <= 0x7f)
    {
        push @dst, $usize;
    }
    elsif ($usize <= 0x7ff)
    {
        push @dst, (( $usize >>  6)         | 0xc0);
        push @dst, (( $usize        & 0x3f) | 0x80);
    }
    elsif ($usize <= 0xffff)
    {
        push @dst, (( $usize >> 12)         | 0xe0);
        push @dst, ((($usize >>  6) & 0x3f) | 0x80);
        push @dst, (( $usize        & 0x3f) | 0x80);
    }
    elsif ($usize <= 0x1fffff)
    {
        push @dst, (( $usize >> 18)         | 0xf0);
        push @dst, ((($usize >> 12) & 0x3f) | 0x80);
        push @dst, ((($usize >>  6) & 0x3f) | 0x80);
        push @dst, (( $usize        & 0x3f) | 0x80);
    }
    elsif ($usize <= 0x3ffffff)
    {
        push @dst, (( $usize >> 24)         | 0xf8);
        push @dst, ((($usize >> 18) & 0x3f) | 0x80);
        push @dst, ((($usize >> 12) & 0x3f) | 0x80);
        push @dst, ((($usize >>  6) & 0x3f) | 0x80);
        push @dst, (( $usize        & 0x3f) | 0x80);
    }
    elsif ($usize <= 0x7fffffff)
    {
        push @dst, (( $usize >> 30)         | 0xfc);
        push @dst, ((($usize >> 24) & 0x3f) | 0x80);
        push @dst, ((($usize >> 18) & 0x3f) | 0x80);
        push @dst, ((($usize >> 12) & 0x3f) | 0x80);
        push @dst, ((($usize >>  6) & 0x3f) | 0x80);
        push @dst, (( $usize        & 0x3f) | 0x80);
    }
    else
    {
        die("compress can only compress up to 0x7fffffffL bytes");
    }


    return pack ("C*", @dst);
}

sub uncompr
{
    my $self = shift ;
    my $from = shift ;
    my $to   = shift ;
    my $eof  = shift ;
    my $outSize  = shift ;

    return STATUS_OK
        unless length $$from;

    $self->{CompBytes} += length $$from;

    if (length $$from == $outSize) {
        $self->{UnCompBytes} += length $$from;
        $$to .= $$from;
        return STATUS_OK;
    }


    #$$to .= Compress::Lzf::my_decompress($from, $outSize);
    $@ = '';
    if ($self->{Identity} )
      { $$to .= $$from }
    else {

        my $hdr = mk_c_lzf_header_length($self->{USize});

        #  Compress::LZF::decompress croaks if the compressed data is
        #  corrupt.
        eval { $$to .= Compress::LZF::decompress($hdr . $$from) } ;
    }

    $self->{Identity} = 0 ;
    $self->{ErrorNo} = 0;

    if ($@ || ! defined $to) {
        $self->{Error} = "error uncompressing";
        $self->{Error} .= " - " . $@
            if $@;
        $self->{ErrorNo} = 1;
        return STATUS_ERROR;
    }

    $self->{UnCompBytes} += length $$to;

    return STATUS_OK ;
}

sub reset
{
    return STATUS_OK ;
}

#sub count
#{
#    my $self = shift ;
#    $self->{UnCompBytes};
#}

sub compressedBytes
{
    my $self = shift ;
    $self->{CompBytes};
}

sub uncompressedBytes
{
    my $self = shift ;
    $self->{UnCompBytes};
}

sub crc32
{
    my $self = shift ;
    #$self->{Inf}->crc32();
}

sub adler32
{
    my $self = shift ;
    #$self->{Inf}->adler32();
}

sub sync
{
    my $self = shift ;
    #( $self->{Inf}->inflateSync(@_) == BZ_OK)
    #        ? STATUS_OK
    #        : STATUS_ERROR ;
}

1;

__END__
