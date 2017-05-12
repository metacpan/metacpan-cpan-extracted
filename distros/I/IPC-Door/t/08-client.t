#########################
# Test script for IPC::Door
# $Id: 08-client.t 37 2005-06-07 05:50:05Z asari $

use Test::More tests => 5;
use strict;

use IPC::Door qw( :attr );
use IPC::Door::Client;

use File::Basename;
use Fcntl;
use Errno qw( EAGAIN );

my @tests = 0 .. 2;

my ( $base, $path, $suffix ) = fileparse( $0, qr(\.[t|pl]$) );
my $dserver_pid;
my @dserver_script = map { 'door-server' . $_ . '.pl' } @tests;
@dserver_script = map { $path . $_ } @dserver_script;
my @door = map { 'DOOR' . $_ } @tests;
@door = map { $path . $_ } @door;
my @dserver_pid;
my @dclient;

unlink $door[$_] for @tests;

foreach my $test (@tests) {
  FORK_DOOR_SERVER: {
        if ( ${ dserver_pid [$test] } = fork ) {

            # fall through
            ;
        }
        elsif ( defined $dserver_pid[$test] ) {

       #exec "truss $dserver_script[$test] 2>${dserver_script[$test]}_truss.out"
            exec $dserver_script[$test];
        }
        elsif ( $! == EAGAIN ) {
            sleep 5;
            redo FORK_DOOR_SERVER;
        }
        else {
            die "Cannot fork the door server $dserver_script[$test]: $!\n";
        }
    }

}

$dclient[$_] = new IPC::Door::Client( $door[$_] ) for @tests;

# sleep a little while until the door servers have been forked
while ( !-e $door[0] || !-e $door[1] || !-e $door[2] ) {
    select undef, undef, undef, 0.2;
}

# Test door-server0.pl
# Send a number and get its square.
my $num = rand() * ( 2**16 - 1 );
my $ans;
if ( $dclient[0]->is_door ) {
    $ans = $dclient[0]->call( $num, O_RDWR );
}
else {
    die "$door[0] is not a door: $!\n";
}

my $precision = 0.0005;

$ans = 0 unless defined($ans);
cmp_ok( abs( $ans - $num**2 ), '<=', $precision, 'client-server 0' );

my ( $target, $attr ) = ( $dclient[0]->info() )[ 0 .. 1 ];
is( $target, $dserver_pid[0], 'info(pid) - remote' );
is( $attr, 0, 'info(attr) - remote' );

# Test door-server1.pl
# Send a string to be manipulated by the server.
# The server process simply replaces "_" with "-".

undef $ans;
my $str = '2004_01_01';
if ( $dclient[1]->is_door ) {
    $ans = $dclient[1]->call( $str, O_RDWR );
}
else {
    die "$door[1] is not a door: $!\n";
}
$ans = '' unless defined($ans);
is( $ans, '2004-01-01', 'client-server 1' );

# Test door-server2.pl
# Create an array of 1000 elements, pack it with the Storable module.
# Skip if Storable is not available.
SKIP: {
    undef $ans;
    ( eval { require Storable } );

    skip "Storable not installed", 1 if $@;

    my @array  = ( 1 .. 1000 );
    my @rarray = reverse @array;

    $str = Storable::freeze( \@array );

    if ( $dclient[2]->is_door ) {
        $ans = $dclient[2]->call( $str, O_RDWR );
    }
    else {
        die "$door[2] is not a door: $!\n";
    }

    $ans = '' unless defined($ans);
    is_deeply( \@{ Storable::thaw($ans) }, \@rarray, 'client-server 2' );

}    # end of SKIP: block

# Clean up
select undef, undef, undef, 2;
kill "TERM", $dserver_pid[$_] for @tests;
