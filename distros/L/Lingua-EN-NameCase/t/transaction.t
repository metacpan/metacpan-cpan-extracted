#!/usr/bin/perl -w

# Transaction-flow tests for Lingua::EN::NameCase.
#
# <thinking>
# The module has no database, file or socket.  It does have one real
# multi-step transaction: NameCase( \@names ) in scalar or void context.
#
#   Create    the caller builds @names
#   Validate  every element is checked (type, $MAX_LENGTH)
#   Process   every element goes through five stages
#   Commit    the answers are stored back into the SAME elements
#   Complete  the array reference is returned
#
# The contract is all-or-nothing: if any element fails at any stage, nothing
# is stored.  The rollback point is the single commit step; everything before
# it works on private copies.  Other lifecycle facts:
#
#   * A failed call can be retried; once the cause is fixed it succeeds.
#   * Repeating a completed transaction changes nothing (idempotent), and
#     repeating a failed one fails the same way without damage.
#   * The settings ($HEBREW, $MAX_LENGTH ...) are read at each call, so a
#     setting changed between a "check" call and a "use" call (the module's
#     form of time-of-check to time-of-use) is honoured by the later call,
#     and the all-or-nothing rule still holds.
#   * A caller or another process may change the array while the call is
#     running.  There is no lock to take (no shared file or resource), so the
#     requirement is only that nothing is corrupted: no crash, no warning, no
#     half-cased element.
#   * No file handle is opened and no file is created, whether the call
#     succeeds or fails.  There is therefore nothing to flock; the tests
#     prove that no lock or temporary file appears and no descriptor leaks.
#   * Time is not an input.  Results must be the same at any time.
# </thinking>

use strict;
use warnings;

use File::Temp qw(tempdir);
use POSIX ();
use Readonly;
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw( freeze_time advance_time with_frozen_time );
use Test::Most;
use lib 't/lib';
use ReturnsOk;

BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }

use Lingua::EN::NameCase qw( NameCase nc );

Readonly my $PKG => 'Lingua::EN::NameCase';

Readonly my %config => (
	repeat      => 5,                       # how many times a sequence is replayed
	children    => 4,                       # concurrent processes
	frozen_at   => '2025-01-01T00:00:00Z',
	step_secs   => 3600,                    # clock jump between steps
	limit       => 10,                      # a $MAX_LENGTH
	fd_rounds   => 200,                     # repetitions for the descriptor check
);

Readonly my @STAGES => qw( _base_case _mac_case _particle_case _roman_case _postnominal_case );
Readonly my @ORIGINAL => ( 'john smith', 'MARY MACDONALD', 'henry viii phd', 'ludwig von beethoven' );
Readonly my @CASED    => ( 'John Smith', 'Mary MacDonald', 'Henry VIII PhD', 'Ludwig von Beethoven' );

# ----- helpers -----------------------------------------------------------

# Run a block with the package settings at their defaults and restore them
# afterwards, even if the block dies.
sub with_settings {
	my ( $settings, $code ) = @_;
	my @names = qw( HEBREW SPANISH ROMAN POSTNOMINAL MAX_LENGTH );
	my %saved;
	{
		no strict 'refs';
		%saved = map { $_ => ${"${PKG}::$_"} } @names;
		my %default = ( HEBREW => 1, SPANISH => 0, ROMAN => 1, POSTNOMINAL => 1, MAX_LENGTH => undef );
		${"${PKG}::$_"} = $default{$_} for @names;
		${"${PKG}::$_"} = $settings->{$_} for keys %{$settings};
	}
	my $ok    = eval { $code->(); 1 };
	my $error = $@;
	{
		no strict 'refs';
		${"${PKG}::$_"} = $saved{$_} for @names;
	}
	die $error unless $ok;
	return;
}

# Wrap a pipeline stage so that the Nth call (counting from 1) dies and every
# other call behaves normally.  Returns a closure that removes the wrapper.
sub fail_stage_on_call {
	my ( $stage, $nth ) = @_;
	my $real = do { no strict 'refs'; \&{"${PKG}::$stage"} };
	my $count = 0;
	mock "${PKG}::$stage" => sub {
		die "injected failure in $stage\n" if ++$count == $nth;
		return $real->(@_);
	};
	return sub { unmock "${PKG}::$stage" };
}

# Warnings seen while a block runs.
sub warnings_from {
	my ($code) = @_;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	eval { $code->() };
	return \@warnings;
}

# Open descriptors of this process, or undef where /proc is not available.
sub open_fds {
	return unless -d '/proc/self/fd';
	opendir my $dh, '/proc/self/fd' or return;
	my @fds = grep { !/\A\.\.?\z/ } readdir $dh;
	closedir $dh;
	return scalar @fds - 1;    # minus the handle used for the listing
}

# ----- phase 1: the whole lifecycle --------------------------------------

subtest 'phase 1: create -> validate -> process -> commit -> complete' => sub {
	with_settings( {}, sub {
		# Create
		my @names = @ORIGINAL;
		my $entity = \@names;
		is_deeply( $entity, [@ORIGINAL], 'created: the caller data is as supplied' );

		# Validate: a list-context call is a dry run that changes nothing
		my @preview;
		lives_ok { @preview = NameCase($entity) } 'validate: the dry run is accepted';
		is_deeply( \@preview, [@CASED], 'validate: the preview is the final answer' );
		is_deeply( $entity, [@ORIGINAL], 'validate: nothing was changed' );

		# Process and commit: in place, element by element
		my @alias = \( @names );    # references to the elements
		my $done = NameCase($entity);

		# Complete
		is( $done, $entity, 'complete: the same reference comes back' );
		is_deeply( $entity, [@CASED], 'complete: every element is committed' );
		returns_ok( $done, { type => 'arrayref' }, 'complete: an array reference' );
		for my $i ( 0 .. $#names ) {
			is( $alias[$i], \$names[$i], "element $i is the same variable" );
			is( ${ $alias[$i] }, $CASED[$i], "element $i seen through its alias" );
		}
		is( scalar @names, scalar @ORIGINAL, 'no element added or removed' );
	} );
	done_testing();
};

# ----- phase 2: mid-flight failure and rollback --------------------------

subtest 'phase 2: a failure at any stage, on any element, rolls back' => sub {
	with_settings( {}, sub {
		my $size = scalar @ORIGINAL;
		for my $stage (@STAGES) {
			# POSTNOMINAL / ROMAN stages exist because both switches are on
			for my $nth ( 1 .. $size ) {
				my @names  = @ORIGINAL;
				my $remove = fail_stage_on_call( $stage, $nth );
				my $died   = !eval { NameCase( \@names ); 1 };
				my $error  = $@;
				$remove->();
				ok( $died, "$stage fails on element $nth: the call dies" );
				like( $error, qr/\Ainjected failure in \Q$stage\E\n/, "$stage/$nth: the original error is passed on" );
				is_deeply( \@names, [@ORIGINAL], "$stage/$nth: rolled back, nothing written" );
			}
		}
	} );
	done_testing();
};

subtest 'phase 2b: list context returns nothing when a step fails' => sub {
	with_settings( {}, sub {
		my @names  = @ORIGINAL;
		my $remove = fail_stage_on_call( '_mac_case', 3 );
		my @got;
		my $died = !eval { @got = NameCase(@names); 1 };
		$remove->();
		ok( $died, 'the call died' );
		is( scalar @got, 0, 'no partial list was handed out' );
		is_deeply( \@names, [@ORIGINAL], 'the inputs are intact' );
	} );
	done_testing();
};

subtest 'phase 2c: failure while reporting a failure' => sub {
	with_settings( { MAX_LENGTH => 3 }, sub {
		my @names = ( 'abc', 'abcd' );
		mock "${PKG}::_i18n" => sub { die "message system down\n" };
		my $died = !eval { NameCase( \@names ); 1 };
		my $error = $@;
		unmock "${PKG}::_i18n";
		ok( $died, 'the transaction still fails' );
		like( $error, qr/message system down/, 'the secondary error is what surfaces' );
		is_deeply( \@names, [ 'abc', 'abcd' ], 'and nothing was written' );
	} );
	done_testing();
};

subtest 'phase 2d: recovery - fix the cause and retry the same data' => sub {
	my @names = ( 'abc', 'abcdef' );
	with_settings( { MAX_LENGTH => 3 }, sub {
		throws_ok { NameCase( \@names ) } qr/\AName is too long: 6 characters \(the maximum is 3\)/,
			'first attempt is rejected';
		is_deeply( \@names, [ 'abc', 'abcdef' ], 'rolled back' );
	} );
	with_settings( { MAX_LENGTH => undef }, sub {
		lives_ok { NameCase( \@names ) } 'retry after the cause is removed';
		is_deeply( \@names, [ 'Abc', 'Abcdef' ], 'retry committed everything' );
	} );
	done_testing();
};

# ----- phase 3: idempotency ----------------------------------------------

subtest 'phase 3: replaying a completed transaction changes nothing' => sub {
	with_settings( {}, sub {
		my @names = @ORIGINAL;
		NameCase( \@names );
		my @after_first = @names;
		for my $round ( 1 .. $config{repeat} ) {
			my $ret = NameCase( \@names );
			is_deeply( \@names, \@after_first, "round $round: same data" );
			is( $ret, \@names, "round $round: same reference" );
		}
		for my $name (@ORIGINAL) {
			my $once = nc($name);
			is( nc($once), $once, "nc is idempotent: $name" );
		}
		# non-ASCII and awkward text is a fixed point too
		for my $name ( "stra\x{df}e", "\x{df}", "\x{130}stanbul", "\x{390}", "fred\x{2019}s", "al bar" ) {
			my $once = nc($name);
			is( nc($once), $once, 'fixed point: ' . join q{}, map { sprintf '%x ', ord } split //, $name );
		}
	} );
	done_testing();
};

subtest 'phase 3b: replaying a failed transaction fails the same way' => sub {
	with_settings( { MAX_LENGTH => 3 }, sub {
		my @names = ( 'abc', 'abcd' );
		my @messages;
		for ( 1 .. $config{repeat} ) {
			eval { NameCase( \@names ) };
			push @messages, $@;
		}
		is( scalar( grep { $_ ne $messages[0] } @messages ), 0, 'the same message every time' )
			or diag( explain \@messages );
		is_deeply( \@names, [ 'abc', 'abcd' ], 'no data corrupted by the repeats' );
	} );
	done_testing();
};

# ----- phase 4: concurrency and time-of-check/time-of-use ----------------

subtest 'phase 4a: a limit that changes between check and use' => sub {
	my @names = ( 'a' x $config{limit}, 'b' x ( $config{limit} + 5 ) );

	# check: with no limit, the dry run passes
	with_settings( { MAX_LENGTH => undef }, sub {
		lives_ok { my @preview = NameCase( \@names ) } 'check passes with no limit';
	} );

	# use: the limit is tightened by "another process" before the commit
	with_settings( { MAX_LENGTH => $config{limit} }, sub {
		my $before = [@names];
		throws_ok { NameCase( \@names ) } qr/\AName is too long: /, 'use is refused under the new limit';
		is_deeply( \@names, $before, 'atomic: not even the valid first element was written' );
	} );

	# and the other direction: a limit lifted mid-flight is honoured
	with_settings( { MAX_LENGTH => $config{limit} }, sub {
		my @one = ( 'c' x ( $config{limit} + 1 ) );
		throws_ok { NameCase( \@one ) } qr/too long/, 'refused while the limit stands';
		$Lingua::EN::NameCase::MAX_LENGTH = undef;
		lives_ok { NameCase( \@one ) } 'accepted once the limit is lifted';
	} );
	done_testing();
};

subtest 'phase 4b: the caller changes the array while it is being processed' => sub {
	with_settings( {}, sub {
		my @names = @ORIGINAL;

		# While element 1 is processed, "another process" rewrites element 3
		# and appends a new one.
		my $real  = do { no strict 'refs'; \&{"${PKG}::_base_case"} };
		my $calls = 0;
		mock "${PKG}::_base_case" => sub {
			if ( ++$calls == 1 ) {
				$names[3] = 'changed behind your back';
				push @names, 'appended';
			}
			return $real->(@_);
		};
		my @warnings;
		my $ok = do {
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			eval { NameCase( \@names ); 1 };
		};
		unmock "${PKG}::_base_case";

		ok( $ok, 'no crash' ) or diag($@);
		is( scalar @warnings, 0, 'no warning' ) or diag( join q{}, @warnings );

		# Every element must be a whole answer: the cased form of whatever
		# was read, or exactly what the writer left.
		my %allowed = map { $_ => 1 } (
			@CASED, 'changed behind your back', 'appended',
			'Changed Behind Your Back', 'Appended',
		);
		my @bad = grep { !$allowed{$_} } @names;
		is( scalar @bad, 0, 'no element is half-processed' ) or diag( explain \@bad );
		is( $names[0], $CASED[0], 'the elements read before the change are committed' );
	} );
	done_testing();
};

subtest 'phase 4c: a switch flipped between two names of one batch' => sub {
	my @names = ('bob ben david') x 3;
	with_settings( { HEBREW => 1 }, sub {
		my $real  = do { no strict 'refs'; \&{"${PKG}::_particle_case"} };
		my $calls = 0;
		mock "${PKG}::_particle_case" => sub {
			$Lingua::EN::NameCase::HEBREW = 0 if ++$calls == 2;    # flips mid-batch
			return $real->(@_);
		};
		my @got = NameCase(@names);
		unmock "${PKG}::_particle_case";
		is( $got[0], 'Bob ben David', 'before the flip: Hebrew rule on' );
		is( $got[1], 'Bob Ben David', 'after the flip: rule off (read per call)' );
		is( $got[2], 'Bob Ben David', 'and it stays off' );
		is( scalar( grep { $_ ne 'Bob ben David' && $_ ne 'Bob Ben David' } @got ), 0,
			'every name is a whole answer of one rule or the other' );
	} );
	done_testing();
};

subtest 'phase 4d: concurrent processes do not interfere' => sub {
	plan skip_all => 'fork is not reliable here' if $^O eq 'MSWin32';
	my @pids;
	for my $child ( 1 .. $config{children} ) {
		my $pid = fork;
		die "fork failed: $!" unless defined $pid;
		if ( !$pid ) {
			# each child uses its own settings and its own data
			my $hebrew = $child % 2;
			local $Lingua::EN::NameCase::HEBREW = $hebrew;
			my $want = $hebrew ? 'Bob ben David' : 'Bob Ben David';
			my $ok = 1;
			for ( 1 .. $config{fd_rounds} ) {
				my @names = ('bob ben david');
				NameCase( \@names );
				$ok = 0 if $names[0] ne $want;
			}
			POSIX::_exit( $ok ? 0 : 1 );
		}
		push @pids, $pid;
	}
	for my $pid (@pids) {
		waitpid $pid, 0;
		is( $? >> 8, 0, "child $pid saw only its own settings and data" );
	}
	is( $Lingua::EN::NameCase::HEBREW, 1, 'the parent settings are untouched' );
	done_testing();
};

# ----- phase 5: resources ------------------------------------------------

subtest 'phase 5: no handle leaks, no file or lock appears' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	my $cwd_before = do { opendir my $dh, $dir or die; my @f = grep { !/\A\.\.?\z/ } readdir $dh; closedir $dh; \@f };

	SKIP: {
		my $before = open_fds();
		skip 'no /proc/self/fd on this system', 1 unless defined $before;

		with_settings( { MAX_LENGTH => 3 }, sub {
			for ( 1 .. $config{fd_rounds} ) {
				my @names = ( 'abc', 'abcd' );
				eval { NameCase( \@names ) };                     # failing transaction
				my @fine = ('abc');
				NameCase( \@fine );                               # successful transaction
			}
		} );
		is( open_fds(), $before, 'the number of open descriptors is unchanged' );
	}

	# Run the sequence with the working directory inside a clean directory.
	{
		require Cwd;
		my $start = Cwd::getcwd();
		chdir $dir or die "chdir: $!";
		with_settings( {}, sub { my @n = @ORIGINAL; NameCase( \@n ); eval { nc( {} ) } } );
		chdir $start or die "chdir back: $!";
	}
	my $cwd_after = do { opendir my $dh, $dir or die; my @f = grep { !/\A\.\.?\z/ } readdir $dh; closedir $dh; \@f };
	is_deeply( $cwd_after, $cwd_before, 'no lock, temporary or other file was created' );
	done_testing();
};

# ----- phase 6: time -----------------------------------------------------

subtest 'phase 6: the answer does not depend on the clock' => sub {
	with_settings( {}, sub {
		freeze_time( $config{frozen_at} );
		my @first = NameCase(@ORIGINAL);
		advance_time( $config{step_secs} => 'seconds' );
		my @second = NameCase(@ORIGINAL);
		with_frozen_time '1999-12-31T23:59:59Z' => sub {
			is_deeply( [ NameCase(@ORIGINAL) ], \@first, 'same answer just before a year change' );
		};
		with_frozen_time '2038-01-19T03:14:08Z' => sub {
			is_deeply( [ NameCase(@ORIGINAL) ], \@first, 'same answer at the 32-bit limit' );
		};
		Test::Mockingbird::TimeTravel::restore_all();
		is_deeply( \@second, \@first, 'same answer an hour later' );
		is_deeply( \@first, [@CASED], 'and it is the right answer' );
	} );
	done_testing();
};

# ----- phase 7: state after everything -----------------------------------

subtest 'phase 7: no state is left behind by the failures above' => sub {
	is( $Lingua::EN::NameCase::HEBREW,      1,     'HEBREW at its default' );
	is( $Lingua::EN::NameCase::SPANISH,     0,     'SPANISH at its default' );
	is( $Lingua::EN::NameCase::ROMAN,       1,     'ROMAN at its default' );
	is( $Lingua::EN::NameCase::POSTNOMINAL, 1,     'POSTNOMINAL at its default' );
	is( $Lingua::EN::NameCase::MAX_LENGTH,  undef, 'MAX_LENGTH at its default' );
	is_deeply( \%Lingua::EN::NameCase::MESSAGES, {}, 'no message override left' );
	is( nc('john smith'), 'John Smith', 'the module still works' );
	done_testing();
};

done_testing();
