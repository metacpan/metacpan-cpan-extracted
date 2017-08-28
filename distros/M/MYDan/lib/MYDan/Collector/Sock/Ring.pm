package MYDan::Collector::Sock::Ring;

use warnings;
use strict;
use Carp;

use threads;
use Thread::Queue;
use Socket;
use IO::Select;

use MYDan::Util::Sysrw;
use YAML::XS;
use Thread::Semaphore;

use threads::shared;

our ( $DATA, $MUTEX, $RING ) 
    = ( Thread::Queue->new, Thread::Semaphore->new(), 128 );
use base 'MYDan::Collector::Sock';

our %EXC = ( TEST => 1, PS => 1 );
sub push
{
    my $data = shift;
    my $time = time;
    #my $time = POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime );
    $data = [ splice @$data, 0, $RING ] if @$data > $RING;

    $MUTEX->down();
    my $del = $DATA->pending + @$data - $RING;
    if( $del > 0 )
    {
        warn "sock ring delete: $del\n";
        $DATA->dequeue( $del );
    }

    $data = YAML::XS::Dump [ [ grep{ ! $EXC{$_->[0][0]} }@$data ],$time];
    $DATA->enqueue( $data );
    $MUTEX->up();
}

sub _server
{
    my ( $this, $socket ) = @_;
    $MUTEX->down();
    my $count = $DATA->pending;
    my @data = grep{ref $_} map{eval{ YAML::XS::Load $_}} $count ? $DATA->dequeue($count) : ();
     
    $MUTEX->up();
    MYDan::Util::Sysrw->write( $socket, YAML::XS::Dump \@data );
}

1;
