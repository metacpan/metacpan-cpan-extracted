#!/usr/bin/perl -w

use strict;

use Test::More tests => 16;
use File::Temp qw( tempdir );

use POSIX qw( WEXITSTATUS );

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

$ips->use_library( "IO" );

ok( 1, 'library loaded' );

# We need a temporary directory to run our tests in. Usually we'd do this
# by remote calls, but since the remote perl is just "perl", it's local, so
# we can do it directly

my $dir = tempdir( CLEANUP => 1 );

my $fd = $ips->call( "open", ">", "$dir/testfile" );
ok( $fd > 2, 'remote open gets filehandle' );

ok( -f "$dir/testfile", 'file exists' );

$ips->call( "write", $fd, "Here is a line\n" );

open( my $shadowfh, "<", "$dir/testfile" ) or die "Cannot reopen file - $!";
is( <$shadowfh>, "Here is a line\n", 'Correctly read back line' );

my $pos = $ips->call( "tell", $fd );
is( $pos, 15, 'tell() is at char 15' );

$ips->call( "close", $fd );

$fd = $ips->call( "open", "<", "$dir/testfile" );
ok( $fd > 2, 'remote open for reading gets filehandle' );

$pos = $ips->call( "seek", $fd, 8, 0 );
is( $pos, 8, 'position after seek is 8' );

my $data = $ips->call( "getline", $fd );
is( $data, "a line\n", 'getline returns data' );

$ips->call( "close", $fd );

$fd = $ips->call( "open", "+<", "$dir/testfile" );
ok( $fd > 2, 'remote open for reading/writing gets filehandle' );

$ips->call( "truncate", $fd, 7 );

$data = $ips->call( "read", $fd, 8192 );
is( $data, "Here is", 'read returns data after truncate' );

my @stat = $ips->call( "fstat", $fd );
is( scalar @stat, 13, 'fstat returns 13-element list' );
is_deeply( \@stat, [ stat "$dir/testfile" ], 'fstat == local stat' );

SKIP: {
   skip( "Perl too old to support fchmod()", 1 ) if $] < 5.008008;

   $ips->call( "fchmod", $fd, 0755 );

   is( (stat "$dir/testfile")[2] & 0777, 0755, 'fchmod works' );
}

# Can't test fchown without being root, but since it's simple and so similar
# to fchmod we'll presume it works...

$ips->call( "close", $fd );

# Test of pipe-open

$fd = $ips->call( "open", "-|", "$^X", "-e", 'print "Hello over the pipe\n"; exit 10' );
ok( $fd > 2, 'remote pipeopen gets filehandle' );

$data = $ips->call( "getline", $fd );
is( $data, "Hello over the pipe\n", 'pipeopen works' );

my $exitcode = $ips->call( "pclose", $fd );
is( WEXITSTATUS($exitcode), 10, 'pclose returns exit status' )
