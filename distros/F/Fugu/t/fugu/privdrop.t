#!/usr/bin/env perl
# ex:ts=8 sw=4:
use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use English    qw(-no_match_vars);
use File::Temp qw(tempdir);
use POSIX      ();

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

# run_in_child($code):
#	Run $code in a forked child, and return what it printed. The
#	child does the whole privilege drop, so the drop cannot reach
#	the ids of the test process. The child reports over a pipe,
#	and it exits with POSIX::_exit so no test hook runs twice.
sub run_in_child ($code)
{
	pipe my $reader, my $writer or die "pipe: $!";
	my $pid = fork // die "fork: $!";
	if ( $pid == 0 ) {
		close $reader;
		my $report = eval { $code->() } // "DIED: $@";
		print {$writer} $report;
		close $writer;
		POSIX::_exit(0);
	}
	close $writer;
	my $report = do { local $/ = undef; <$reader> };
	close $reader;
	waitpid $pid, 0;

	return $report // '';
}

# Test 5: drop_privileges for a process that was never root
SKIP: {
	skip 'Running as root, cannot test non-root behavior', 4 if $> == 0;

	my $orig_uid = $>;
	my $orig_gid = ( split ' ', $EFFECTIVE_GROUP_ID )[0];
	my $ret =
	    eval { Fugu::Privdrop->drop_privileges( user => 'nobody' ) };
	ok( defined $ret, 'the return value is defined' );
	is( $ret, 0, 'drop_privileges returns 0 for a non-root process' );
	is( $>,  $orig_uid, 'the UID did not change' );
	is( ( split ' ', $EFFECTIVE_GROUP_ID )[0],
		$orig_gid, 'the GID did not change' );
}

# Test 6: the real privilege drop, in a forked child
SKIP: {
	skip 'Must be root to test the real privilege drop', 1
	    unless $> == 0;

	my ( $uid, $gid ) = ( getpwnam('nobody') )[ 2, 3 ];
	skip 'no nobody user on this host', 1 unless defined $uid;

	my $report = run_in_child(
		sub {
			my $ret =
			    Fugu::Privdrop->drop_privileges(
				user => 'nobody' );

			return "ret=$ret" unless $ret == 1;
			return 'wrong ruid' unless $< == $uid;
			return 'wrong euid' unless $> == $uid;
			my ($rgid) = split ' ', $REAL_GROUP_ID;
			my ( $egid, @members ) = split ' ',
			    $EFFECTIVE_GROUP_ID;
			return 'wrong rgid' unless $rgid == $gid;
			return 'wrong egid' unless $egid == $gid;
			for my $member (@members) {
				return "kept group $member"
				    unless $member == $gid;
			}

			# The drop must be permanent
			POSIX::setuid(0);
			return 'root came back' if $< == 0 || $> == 0;

			return 'ok';
		}
	);
	is( $report, 'ok', 'the child dropped to nobody and stayed there' );
}

# Test 6b: a drop with a named group lands on that group
SKIP: {
	skip 'Must be root to test the real privilege drop', 1
	    unless $> == 0;

	my ($uid)   = ( getpwnam('nobody') )[2];
	my $daemon  = getgrnam('daemon');
	my $primary = ( getpwnam('nobody') )[3];
	skip 'no nobody user on this host', 1 unless defined $uid;
	skip 'no daemon group on this host', 1
	    unless defined $daemon && $daemon != ( $primary // -1 );

	my $report = run_in_child(
		sub {
			my $ret = Fugu::Privdrop->drop_privileges(
				user  => 'nobody',
				group => 'daemon',
			);

			return "ret=$ret" unless $ret == 1;
			my ($rgid) = split ' ', $REAL_GROUP_ID;
			return "rgid=$rgid" unless $rgid == $daemon;

			return 'ok';
		}
	);
	is( $report, 'ok', 'the named group wins over the primary group' );
}

# Test 6c: keep_groups keeps the list, and the drop still verifies
SKIP: {
	skip 'Must be root to test the real privilege drop', 1
	    unless $> == 0;

	my ($uid) = ( getpwnam('nobody') )[2];
	skip 'no nobody user on this host', 1 unless defined $uid;

	my $report = run_in_child(
		sub {
			my $ret = Fugu::Privdrop->drop_privileges(
				user        => 'nobody',
				keep_groups => 1,
			);

			return "ret=$ret" unless $ret == 1;
			return 'wrong euid' unless $> == $uid;

			return 'ok';
		}
	);
	is( $report, 'ok', 'keep_groups passes the two group id checks' );
}

# Test 6d: uid 0 as the target is a refusal. The guard returns 0 for
# a normal user before the resolve, so only root reaches the check.
SKIP: {
	skip 'Must be root to test the uid 0 refusal', 2 unless $> == 0;

	ok( !eval { Fugu::Privdrop->drop_privileges( user => 'root' ); 1 },
		'a drop to root dies' );
	like(
		$@,
		qr/Refusing to drop privileges to uid 0/,
		'and the message names the refusal'
	);
}

# Test 6e: a mixed root state is a hard error. Only root can build
# that state, so the test forks, and the child calls seteuid(2)
# before it calls the method. A normal user skips.
SKIP: {
	skip 'Must be root to build a mixed root state', 1 unless $> == 0;

	my ($uid) = ( getpwnam('nobody') )[2];
	skip 'no nobody user on this host', 1 unless defined $uid;

	my $report = run_in_child(
		sub {
			# Set the effective UID alone; the real UID
			# stays 0
			$> = $uid;
			my $ok = eval {
				Fugu::Privdrop->drop_privileges(
					user => 'nobody' );
				1;
			};
			return 'no death' if $ok;
			return $@;
		}
	);
	like(
		$report,
		qr/mixed root state/,
		'a mixed root state is a death, not a guess'
	);
}

# Test 6f: the verification helper, without a drop. The helper reads
# the live ids, so a test can prove the checks with no root. The
# keep_groups flag is 1: the group list of a normal user holds more
# than one group, and the list check is not under test here.
{
	my ($rgid) = split ' ', $REAL_GROUP_ID;
	my ($egid) = split ' ', $EFFECTIVE_GROUP_ID;

	SKIP: {
		skip 'the real and the effective gid differ', 1
		    unless $rgid == $egid;
		is( Fugu::Privdrop->_verify_ids( $<, $rgid, 1 ),
			1, '_verify_ids returns 1 for the live ids' );
	}

	my $wrong = $rgid + 1;
	ok( !eval { Fugu::Privdrop->_verify_ids( $<, $wrong, 1 ); 1 },
		'a wrong group id is a death' );
	like(
		$@,
		qr/real gid is $rgid, wanted $wrong/,
		'and the message names the found and the wanted value'
	);

	SKIP: {
		skip 'the real and the effective gid differ', 2
		    unless $rgid == $egid;
		my $uid = $< + 1;
		ok(
			!eval {
				Fugu::Privdrop->_verify_ids( $uid, $rgid, 1 );
				1;
			},
			'a wrong user id is a death'
		);
		like(
			$@,
			qr/real uid is $<, wanted $uid/,
			'and the message names the found and the wanted value'
		);
	}
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
