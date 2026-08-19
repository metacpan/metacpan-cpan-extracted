#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.36;
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);

use_ok('Fugu::Privdrop');

# Test 1: Module loads
pass('Fugu::Privdrop loaded');

# Test 2: drop_privileges requires user parameter
{
	eval { Fugu::Privdrop->drop_privileges(); };
	like( $@, qr/user parameter required/, 'drop_privileges requires user parameter' );
}

# Test 3: drop_privileges with invalid user
SKIP: {
	skip 'Must be root to test invalid user error', 1 unless $> == 0;
	
	eval { Fugu::Privdrop->drop_privileges( user => 'nonexistent_user_12345' ); };
	like( $@, qr/Cannot get UID for user/, 'drop_privileges fails with invalid user' );
}

# Test 4: drop_privileges with invalid group
SKIP: {
	skip 'Must be root to test privilege dropping', 1 unless $> == 0;
	
	eval { Fugu::Privdrop->drop_privileges( user => 'nobody', group => 'nonexistent_group_12345' ); };
	like( $@, qr/Cannot get GID for group/, 'drop_privileges fails with invalid group' );
}

# Test 5: drop_privileges when already non-root (a no-op)
SKIP: {
	skip 'Running as root, cannot test non-root behavior', 1 if $> == 0;
	
	my $orig_uid = $>;
	my $ok = eval { Fugu::Privdrop->drop_privileges( user => 'nobody' ); 1; };
	ok( $ok, 'drop_privileges succeeds when already non-root' );
	is( $>, $orig_uid, 'UID unchanged when already non-root' );
}

# Test 6: Actual privilege drop (requires root)
SKIP: {
	skip 'Must be root to test actual privilege dropping', 5 unless $> == 0;
	
	# This test drops privileges for real. That has an effect on
	# the rest of the test suite. Thus normal test runs skip it.
	# Test it manually or in isolation.
	skip 'Actual privilege drop test skipped (would affect other tests)', 5;
	
	# A manual test does these steps:
	# - Fork a child process
	# - In the child, call drop_privileges
	# - Make sure that the UID and the GID have changed
	# - Make sure that the child cannot get root again
	# - Exit the child
}

# Test 7: prepare_statedir needs both names
{
	ok( !eval { Fugu::Privdrop->prepare_statedir; 1 },
		'prepare_statedir needs a path' );
	like( $@, qr/path parameter required/, 'and says which' );

	ok(
		!eval {
			Fugu::Privdrop->prepare_statedir( path => '/tmp' );
			1;
		},
		'prepare_statedir needs a user'
	);
	like( $@, qr/user parameter required/, 'and says which' );
}

# Test 8: prepare_statedir creates the directory with the mode. The
# chown is a no-op for a non-root caller that names itself, so the
# create and the mode are what a unit test can prove anywhere.
{
	my $dir  = tempdir( CLEANUP => 1 );
	my $user = getpwuid($>);

	SKIP: {
		skip 'cannot resolve the current user by name', 4
		    unless defined $user;

		my $state = "$dir/run/myapp";
		ok(
			Fugu::Privdrop->prepare_statedir(
				path => $state,
				user => $user,
				mode => 0700,
			),
			'prepare_statedir reports success'
		);
		ok( -d $state, 'the directory exists' );
		is( ( stat $state )[2] & 07777, 0700, 'with the given mode' );

		# The call runs again on every daemon start, so it must
		# be idempotent
		ok(
			Fugu::Privdrop->prepare_statedir(
				path => $state,
				user => $user,
				mode => 0700,
			),
			'a second call is a success'
		);
	}
}

# Test 9: an unknown user is a hard error, and an unusable path is not
{
	my $dir = tempdir( CLEANUP => 1 );

	ok(
		!eval {
			Fugu::Privdrop->prepare_statedir(
				path => "$dir/x",
				user => 'nonexistent_user_12345',
			);
			1;
		},
		'an unknown user dies'
	);

	my $user = getpwuid($>);
	SKIP: {
		skip 'cannot resolve the current user by name', 2
		    unless defined $user;
		skip 'root creates directories anywhere', 2 if $> == 0;

		# A file where a directory must be
		my $blocked = "$dir/blocked";
		open my $fh, '>', $blocked or die "open $blocked: $!";
		close $fh;

		my @warnings;
		is(
			Fugu::Privdrop->prepare_statedir(
				path    => "$blocked/inside",
				user    => $user,
				on_warn => sub ($msg) { push @warnings, $msg },
			),
			undef,
			'an unusable path returns undef'
		);
		ok( @warnings, 'and reports through on_warn' );
	}
}

done_testing();
