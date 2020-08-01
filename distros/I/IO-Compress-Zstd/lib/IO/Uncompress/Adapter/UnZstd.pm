package IO::Uncompress::Adapter::UnZstd;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.096 qw(:Status);
use Compress::Stream::Zstd ;
use Compress::Stream::Zstd::Decompressor qw(ZSTD_DSTREAM_IN_SIZE);
our ($VERSION, @ISA);
$VERSION = '2.096';


sub mkUncompObject
{

    my $decompressor = Compress::Stream::Zstd::Decompressor->new;

    return bless {
                  'Inf'          => $decompressor,

                  'CompBytes'    => 0,
                  'UnCompBytes'  => 0,
                  'Error'        => '',
                  'ErrorNo'      => 0,
                  'ConsumesInput' => 0,
                 } ;
}

sub uncompr
{
    my $self = shift ;
    my $from = shift ;
    my $to   = shift ;
    # my $eof  = shift ;

    my $inf  = $self->{Inf};

    eval { $$to = $inf->decompress($$from); } ;

    if ($@ || $inf->isError())
    {
        $self->{Error} =  $inf->getErrorName();
        $self->{ErrorNo} = $inf->status() ;
        return STATUS_ERROR ;
    }

    $self->{Error} = "" ;
    $self->{ErrorNo} = 0;

    return STATUS_ENDSTREAM if $inf->isEndFrame() ;

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
}

1;

__END__
