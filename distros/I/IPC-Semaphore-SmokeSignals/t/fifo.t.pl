#!/usr/bin/perl -w
use strict;

use Time::HiRes             qw< sleep >;
use File::Basename          qw< dirname >;

BEGIN {
    require lib;
    my $t = dirname( __FILE__ );
    if( -d "$t/../blib" ) {
        lib->import( "$t/../blib/arch", "$t/../blib/lib" );
    } elsif( -d "$t/../lib" ) {
        lib->import( "$t/../lib" );
    }
}

use IPC::Semaphore::SmokeSignals qw< MeetUp >;

my $mod = 'IPC::Semaphore::SmokeSignals';
my $fifo = "/tmp/fifo." . getppid();
warn "# fifo=$fifo\n";
END { unlink $fifo if $fifo; }

# Make this test die if it ever hangs:
alarm( 10 );

my $pipe;
{
    local $SIG{__WARN__} = sub { };
    $pipe = MeetUp( ['a'..'b'], $fifo, 0666 );
}
warn "# Pulling\n";
{
    my $dragon = $pipe->Puff();
    my $tokin = $dragon->Sniff();
    warn "# Got: $tokin\n";
    warn "# Sleeping $ARGV[0]\n";
    sleep( $ARGV[0] );
    warn "# Releasing\n";
}
warn "# Exiting\n";
