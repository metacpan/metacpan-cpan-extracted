package IO::Compress::Adapter::LZO ;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.103 qw(:Status);
use Compress::LZO qw(crc32 adler32);

our ($VERSION);
$VERSION = '2.103';

sub mkCompObject
{
    my $blocksize = shift ;
    my $optimize = shift ;
    my $minimal = shift ;


    return bless {
                  'Buffer'     => '',
                  'BlockSize'  => $blocksize,
                  'Optimize'   => $optimize,
                  'CRC'        => ! $minimal,
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

    #my $cmp = Compress::LZO::my_compress($self->{Buffer});
    my $cmp = Compress::LZO::compress($$buff);

    return STATUS_ERROR
        unless defined $cmp;


    if ($self->{Optimize}) {
        my $oldLen = length $cmp;
        $cmp = Compress::LZO::optimize($cmp);

        return STATUS_ERROR
            if ! defined $cmp || length($cmp) != $oldLen ;
    }

    $cmp = substr($cmp, 5);

    #$self->{UnCompBytes} += length $self->{Buffer} ;
    $self->{UnCompBytes} += length $$buff ;

    #if (length($cmp) >= length($self->{Buffer}))
    if (length($cmp) >= length $$buff)
    {
        ${ $_[0] } .= pack("NN", length($$buff), length($$buff) );
        if ($self->{CRC}) {
            ${ $_[0] } .= pack("N", adler32($$buff));
        }
        ${ $_[0] } .= $$buff;
        $self->{CompBytes} += length $$buff;
    }
    else {

        ${ $_[0] } .= pack("NN", length($$buff), length($cmp));
        if ($self->{CRC}) {
            ${ $_[0] } .= pack("NN", adler32($$buff), adler32($cmp));
        }
        ${ $_[0] } .= $cmp;
        $self->{CompBytes} += length $cmp;
    }
    #$self->{Buffer} = '';

    return STATUS_OK;
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



#sub total_out
#{
#    my $self = shift ;
#    0;
#}

#sub total_in
#{
#    my $self = shift ;
#    $self->{Def}->total_in();
#}
#
#sub crc32
#{
#    my $self = shift ;
#    $self->{Def}->crc32();
#}
#
#sub adler32
#{
#    my $self = shift ;
#    $self->{Def}->adler32();
#}


1;

__END__
