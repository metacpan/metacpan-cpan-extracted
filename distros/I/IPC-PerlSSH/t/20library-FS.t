#!/usr/bin/perl -w

use strict;

use Test::More tests => 17;
use File::Temp qw( tempdir );

use IPC::PerlSSH;

my $ips = IPC::PerlSSH->new( Command => "$^X" );

$ips->use_library( "FS" );

ok( 1, 'library loaded' );

# We need a temporary directory to run our tests in. Usually we'd do this
# by remote calls, but since the remote perl is just "perl", it's local, so
# we can do it directly

my $dir = tempdir( CLEANUP => 1 );

my @dirstat = $ips->call( "stat", $dir );
is_deeply( \@dirstat, [ stat $dir ], 'remote stat' );

$ips->call( "mkdir", "$dir/dir" );
ok( -d "$dir/dir", 'remote mkdir' );

ok( $ips->call( "stat_isdir", "$dir/dir" ), 'remote stat_isdir' );

$ips->call( "chmod", 0600, "$dir/dir" );
is( (stat("$dir/dir"))[2] & 0777, 0600, 'remote chmod' );

my $mode = $ips->call( "stat_mode", "$dir/dir" );
is( $mode & 0777, 0600, 'remote stat_mode' );

$ips->call( "symlink", "$dir/dir", "$dir/link" );
ok( -l "$dir/link", 'remote symlink' );

ok( $ips->call( "stat_islink", "$dir/link" ), 'remote stat_islink' );

my @linkstat = $ips->call( "lstat", "$dir/link" );
is_deeply( \@linkstat, [ lstat "$dir/link" ], 'remote lstat' );

my $l = $ips->call( "readlink", "$dir/link" );
is( $l, "$dir/dir", 'remote readlink' );

my @ents = $ips->call( "readdir", $dir, 0 );
is_deeply( [ sort @ents ], [qw( dir link )], 'remote readdir' );

{
   open( my $fileh, ">", "$dir/file" ) or die "Cannot write $dir/file - $!";
   print $fileh "Initial contents here\n";
}

my $content = $ips->call( "readfile", "$dir/file" );
is( $content, "Initial contents here\n", 'remote readfile' );

$ips->call( "writefile", "$dir/file", "New contents\n" );

{
   open( my $fileh, "<", "$dir/file" ) or die "Cannot read $dir/file - $!";
   local $/; $content = <$fileh>;
}
is( $content, "New contents\n", 'remote writefile' );

$ips->call( "unlink", "$dir/link" );
ok( !-l "$dir/link", 'remote unlink' );

$ips->call( "rmdir", "$dir/dir" );
ok( !-d "$dir/dir", 'remote rmdir' );

$ips->call( "mkpath", "$dir/a/b/c" );
ok( -d "$dir/a/b/c", 'remote mkpath' );

$ips->call( "rmtree", "$dir/a" );
ok( !-d "$dir/a", 'remote rmtree' );
