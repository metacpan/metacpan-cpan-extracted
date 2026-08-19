#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);

use_ok('Fugu::Pidfile');

my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

# next_path(): a fresh, absent path for each case
sub next_path()
{
	$n++;
	return "$dir/pidfile-$n.pid";
}

# Test 1: Create an object
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );
	isa_ok( $pidfile, 'Fugu::Pidfile' );
	ok( !defined $pidfile->error, 'no error on a fresh object' );
}

# Test 2: A missing path is a programming error
{
	ok( !eval { Fugu::Pidfile->new; 1 }, 'new dies without a path' );
	ok( !eval { Fugu::Pidfile->new( path => '' ); 1 },
		'new dies on an empty path' );
}

# Test 3: Write and read a PID
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );

	ok( $pidfile->write_pid(12345), 'wrote a PID' );
	is( $pidfile->read_pid, 12345, 'read back the PID' );
}

# Test 4: The default PID is the caller's
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );

	ok( $pidfile->write_pid, 'wrote the current PID' );
	is( $pidfile->read_pid,   $$, 'read back the current PID' );
	is( $pidfile->is_running, $$, 'the current process is running' );
}

# Test 5: A PID that does not exist is stale
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );

	$pidfile->write_pid(999999);
	ok( $pidfile->is_stale, 'a dead PID is stale' );
	ok( !$pidfile->is_running, 'a dead PID is not running' );
}

# Test 6: Remove
{
	my $path    = next_path();
	my $pidfile = Fugu::Pidfile->new( path => $path );

	$pidfile->write_pid;
	ok( -f $path, 'the file exists' );

	ok( $pidfile->remove, 'removed the file' );
	ok( !-e $path, 'the file is gone' );
	ok( $pidfile->remove, 'a second remove is a success' );
}

# Test 7: An absent or malformed file yields no PID
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );
	is( $pidfile->read_pid, undef, 'no PID from an absent file' );
	is( $pidfile->is_stale, 0,     'an absent file is not stale' );

	my $path = next_path();
	open my $fh, '>', $path or die "open $path: $!";
	print {$fh} "not a number\n";
	close $fh;

	my $bad = Fugu::Pidfile->new( path => $path );
	is( $bad->read_pid, undef, 'malformed content yields no PID' );
}

# Test 8: An unopenable path reports through error, and does not die
{
	my $pidfile =
	    Fugu::Pidfile->new( path => "$dir/absent-dir/openhapd.pid" );

	is( $pidfile->write_pid, undef, 'write_pid fails on a bad path' );
	like( $pidfile->error, qr/open/, 'the reason names the open' );
}

# Test 9: The lock comes before the truncate. A writer that cannot take
# the lock must leave the previous content intact.
{
	my $path = next_path();
	my $held = Fugu::Pidfile->new( path => $path );
	ok( $held->acquire(4242), 'acquired the lock' );
	is( $held->read_pid, 4242, 'the holder wrote its PID' );

	# A second process, because flock does not conflict with the
	# process that already holds the lock
	my $pid = fork;
	die "fork: $!" unless defined $pid;
	if ( $pid == 0 ) {
		my $second = Fugu::Pidfile->new( path => $path );
		exit( $second->acquire(7) ? 0 : 3 );
	}
	waitpid $pid, 0;
	is( $? >> 8, 3, 'a second acquire fails while the first holds it' );

	is( $held->read_pid, 4242, 'the content survives the refused acquire' );

	# Destroying the holder drops the lock and frees the file
	undef $held;
	my $again = Fugu::Pidfile->new( path => $path );
	ok( $again->acquire(99), 'acquire succeeds after the holder is gone' );
	is( $again->read_pid, 99, 'the new holder replaced the PID' );
}

# Test 10: A second acquire on the same object is refused
{
	my $pidfile = Fugu::Pidfile->new( path => next_path() );
	ok( $pidfile->acquire, 'first acquire' );
	is( $pidfile->acquire, undef, 'second acquire on the same object' );
	like( $pidfile->error, qr/already acquired/, 'and it says why' );
}

# Test 11: path accessor
{
	my $path = next_path();
	is( Fugu::Pidfile->new( path => $path )->path,
		$path, 'path returns the file' );
}

done_testing();
