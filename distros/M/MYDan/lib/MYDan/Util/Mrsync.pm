package MYDan::Util::Mrsync;

=head1 NAME

MYDan::Util::Mrsync - Replicate data via phased rsync

=head1 SYNOPSIS

 use MYDan::Util::Mrsync;

 my $mrsync = MYDan::Util::Mrsync->new
 ( 
     src => \@src_hosts,
     dst => \@dst_hosts,
     sp => $src_path,
     dp => $dst_path, ## defaults to sp
 );

 $mrsync->run
 (
     timeout => 300, ## default 0, no timeout
     retry => 2,     ## default 0, no retry
     log => $log_handle,    ## default \*STDERR
     max => $max_in_flight, ## default 2
     opt => $rsync_options, ## default -aqz
 );

=cut
use strict;
use warnings;

use Carp;
use File::Basename;

use base qw( MYDan::Util::Phasic );

our %RUN = ( retry => 2, opt => '-aq' );

sub new
{
    my ( $class, %param ) = splice @_;
    my ( $sp, $dp ) = delete @param{ qw( sp dp ) };
    my %src = map { $_ => 1 } @{ $param{src} };

    $sp = $dp unless $sp;
    $dp = $sp unless $dp;

    croak "path not defined" unless $sp;

    $param{dst} = [ grep { ! $src{$_} } @{ $param{dst} } ] if $sp eq $dp;

    if ( $sp =~ /\/$/ ) { $dp .= '/' if $dp !~ /\/$/ }
    elsif ( $dp =~ /\/$/ ) { $dp .= File::Basename::basename( $sp ) }

    my $w8 = sub 
    {
        my @addr = gethostbyname shift;
        return @addr ? unpack N => $addr[-1] : 0;
    };

    my $rsync = sub
    {
        my ( $src, $dst, %param ) = splice @_;
        my $sp = $src{$src} ? $sp : $dp;
        my $ssh = 'ssh -x -c blowfish -o StrictHostKeyChecking=no';
        my @cmd = ( $ssh, $dst );

        push @cmd, "nice -n $param{nice}" if $param{nice};
        push @cmd, << "RSYNC";
'rsync -e "$ssh" $param{opt} $src:$sp $dp'
RSYNC
        my $rsync = join ' ', @cmd; chop $rsync;
        return system( $rsync ) ? die "ERR: $rsync" : 'OK';
    };

    bless $class->SUPER::new( %param, weight => $w8, code => $rsync ),
        ref $class || $class;
}

sub run
{
    my ( $self, %run ) = splice @_;
    $MYDan::Util::Phasic::MAX = delete $run{max} if $run{max};
    $self->SUPER::run( %RUN, %run );
    return $self;
}

1;
