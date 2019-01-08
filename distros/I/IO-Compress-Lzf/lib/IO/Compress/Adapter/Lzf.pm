package IO::Compress::Adapter::Lzf ;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.084 qw(:Status);
use Compress::LZF ;

our ($VERSION);
$VERSION = '2.084';

use constant SIGNATURE => 'ZV';

sub mkCompObject
{
    my $blocksize = shift ;

    return bless {
                  'Buffer'     => '',
                  'BlockSize'  => $blocksize,
                  #'CRC'        => ! $minimal,
                  'Error'      => '',
                  'ErrorNo'    => 0,
                  'CompBytes'  => 0,
                  'UnCompBytes'=> 0,
                 } ;     
}

sub compr
{
    my $self = shift ;

    $self->{Buffer} .= ${ $_[0] } ;
    return $self->writeBlock(\$_[1], 0)
        if length $self->{Buffer} >= $self->{BlockSize} ;
    

    return STATUS_OK;
}

sub flush
{
    my $self = shift ;

    return STATUS_OK
        unless length $self->{Buffer};

    return $self->writeBlock(\$_[0], 1);
}

sub close
{
    my $self = shift ;

    return STATUS_OK
        unless length $self->{Buffer};

    return $self->writeBlock(\$_[0], 1);
}

sub writeBlock
{
    my $self = shift;
    my $flush = $_[1] ;
    my $blockSize = $self->{BlockSize} ;

    while (length $self->{Buffer} >= $blockSize) {
        my $buff = substr($self->{Buffer}, 0, $blockSize);
        substr($self->{Buffer}, 0, $blockSize) = '';
        $self->writeOneBlock(\$buff, $_[0]);
    }

    if ($flush && length $self->{Buffer} ) {
        $self->writeOneBlock(\$self->{Buffer}, $_[0]);
        $self->{Buffer} = '';
    }

    return STATUS_OK;
}

sub writeOneBlock
{
    my $self   = shift;
    my $buff = shift;

    my $cmp ;
    
    eval { $cmp = Compress::LZF::compress($$buff) };

    return STATUS_ERROR
        if $@ || ! defined $cmp;

    ${ $_[0] } .= SIGNATURE ;

    #$self->{UnCompBytes} += length $self->{Buffer} ;
    $self->{UnCompBytes} += length $$buff ;

    # Remove the Compress::LZF header
    substr($cmp, 0, c_lzf_header_length($cmp)) = '';

    #if (length($cmp) >= length($self->{Buffer}))
    if (length($cmp) >= length $$buff)
    {
        ${ $_[0] } .= pack("Cn", 0, length($$buff));
        ${ $_[0] } .= $$buff;
        $self->{CompBytes} += length $$buff;
    }
    else {

        ${ $_[0] } .= pack("Cnn", 1, length($cmp), length($$buff));
        ${ $_[0] } .= $cmp;
        $self->{CompBytes} += length $cmp;
    }
    #$self->{Buffer} = '';

    return STATUS_OK;
}

sub c_lzf_header_length
{
    my $firstByte = unpack ("C", substr($_[0], 0, 1));

    return 1 if     $firstByte == 0 ;
    return 1 unless $firstByte & 0x80 ;
    return 2 unless $firstByte & 0x20 ;
    return 3 unless $firstByte & 0x10 ;
    return 4 unless $firstByte & 0x08 ;
    return 5 unless $firstByte & 0x04 ;
    return 6 unless $firstByte & 0x02 ;

    return undef;
}

sub reset
{
    return STATUS_OK;    
}

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

1;

__END__

