package IO::Compress::Adapter::Zstd ;

use strict;
use warnings;
use bytes;

use IO::Compress::Base::Common  2.100 qw(:Status);
use Compress::Stream::Zstd qw(ZSTD_MAX_CLEVEL);
use Compress::Stream::Zstd::Compressor qw(ZSTD_CSTREAM_IN_SIZE);

our ($VERSION);
$VERSION = '2.100';

sub mkCompObject
{
    my $level = shift ;

    # TODO - parameterise level
    my $compressor = Compress::Stream::Zstd::Compressor->new($level);

    return bless {
                  'Def'        => $compressor,
                  'Buffer'     => '',
                  'Error'      => '',
                  'ErrorNo'    => 0,
                  'CompBytes'  => 0,
                  'UnCompBytes'=> 0,
                 } ;
}

sub compr
{
    my $self = shift ;
    my $buffer = shift ;

    my $def   = $self->{Def};

    eval { $_[0] .= $def->compress($$buffer) ; };

    if ($@ || $def->isError())
    {
        $self->{Error} =  $def->getErrorName();
        $self->{ErrorNo} = $def->status() ;
        return STATUS_ERROR ;
    }

    $self->{Error}   = '';
    $self->{ErrorNo} = 0;

    return STATUS_OK;
}

sub flush
{
    my $self = shift ;

    my $def   = $self->{Def};

    eval { $_[0] .= $def->flush() } ;

    if ($@)
    {
        $self->{ErrorNo} = $def->status() ;
        return STATUS_ERROR ;
    }

    $self->{ErrorNo} = 0;

    return STATUS_OK;
}

sub close
{
    my $self = shift ;

    my $def   = $self->{Def};

    eval { $_[0] .= $def->end() } ;

    if ($@)
    {
        $self->{ErrorNo} = $def->status() ;
        return STATUS_ERROR ;
    }
    $self->{ErrorNo} = 0;

    return STATUS_OK;
}



sub reset
{
    my $self = shift ;

    my $def   = $self->{Def};

    eval { $_[0] = $def->init() } ;

    if ($@)
    {
        $self->{ErrorNo} = $def->status() ;
        return STATUS_ERROR ;
    }

    $self->{ErrorNo} = 0;

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
