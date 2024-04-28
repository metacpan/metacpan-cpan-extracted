package IO::Uncompress::Adapter::LZO;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.212 qw(:Status);
use Compress::LZO ;

our ($VERSION, @ISA);
$VERSION = '2.212';


sub mkUncompObject
{
    return bless {
                  'CompBytes'    => 0,
                  'UnCompBytes'  => 0,
                  'Error'        => '',
                  'ConsumesInput' => 0,
                 } ;
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


    #$$to .= Compress::LZO::my_decompress($from, $outSize);

    $$to .= Compress::LZO::decompress("\xf0" . pack("N", $outSize) . $$from);

    $self->{ErrorNo} = 0;

    if (! defined $to) {
        $self->{Error} = "error uncompressing";
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
