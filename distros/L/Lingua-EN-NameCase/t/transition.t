#!/usr/bin/perl -w

# State transition tests for Lingua::EN::NameCase.
#
# <thinking>
# The POD "STATE DIAGRAM" holds two machines.
#
# Machine A, the configuration (the four switches, $MAX_LENGTH, %MESSAGES):
#   states   DEFAULTS, CUSTOMISED
#   edges    DEFAULTS   --set a switch / key / limit-->   CUSTOMISED
#            CUSTOMISED --set it back, or leave a "local" block--> DEFAULTS
#            CUSTOMISED --set again-->                    CUSTOMISED
#            (setting a value to what it already is leaves DEFAULTS alone)
#   rule     every call is accepted in both states and never changes the
#            configuration
#
# Machine B, one call to nc / NameCase:
#   states   VALIDATING, READING, CASING, DONE, FAILED
#   edges    E1 VALIDATING -> FAILED   bad type or wrong count (usage_nc,
#                                      usage_namecase, single_arg)
#            E2 VALIDATING -> READING  argument is fine
#            E3 READING    -> DONE     undef, '' or '0': returned as is
#            E4 READING    -> CASING   there is text
#            E5 READING    -> FAILED   $MAX_LENGTH set and exceeded (too_long)
#            E6 CASING     -> DONE     the new string is returned
#            side effect  NameCase with an array ref in scalar/void context
#                         replaces each element on the way CASING -> DONE
#   Not in the diagram, so they must not happen: FAILED -> anything (no
#   result, no stage runs, no data changed), DONE -> CASING, READING ->
#   VALIDATING, CASING -> FAILED because of the data, and any call changing
#   the configuration.
#
# Observing the machine: the state of a call is not stored anywhere, so it is
# inferred from events seen by wrapping _fail (which message, if any) and the
# five stages (did casing start).  E5 was missing from the diagram when these
# tests were first written; the POD was brought into line with the code.
#
# Temporal triggers: the diagram has none (nothing expires, nothing is
# cached).  The time tests warp the clock far ahead and prove that no
# transition happens because of time.
# </thinking>

use strict;
use warnings;

use Readonly;
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Mockingbird::TimeTravel qw( freeze_time advance_time );
use Test::Most;
use lib 't/lib';
use ReturnsOk;

BEGIN { my @known = ( \%Sub::Private::config, \$Sub::Private::BYPASS ); }

use Lingua::EN::NameCase qw( NameCase nc );

Readonly my $PKG => 'Lingua::EN::NameCase';

Readonly my %config => (
	frozen_at => '2025-01-01T00:00:00Z',
	years     => 31_536_000 * 50,    # seconds: fifty years
	limit     => 3,
);

Readonly my %DEFAULT => (
	HEBREW      => 1,
	SPANISH     => 0,
	ROMAN       => 1,
	POSTNOMINAL => 1,
	MAX_LENGTH  => undef,
);

Readonly my @STAGES => qw( _base_case _mac_case _particle_case _roman_case _postnominal_case );

# Failure messages and the edge each one belongs to.
Readonly my %FAIL_EDGE => (
	usage_nc       => 'E1',
	usage_namecase => 'E1',
	single_arg     => 'E1',
	too_long       => 'E5',
);

# The states a call passes through, for each outcome.
Readonly my %PATH => (
	E1 => [qw( VALIDATING FAILED )],
	E5 => [qw( VALIDATING READING FAILED )],
	E3 => [qw( VALIDATING READING DONE )],
	E6 => [qw( VALIDATING READING CASING DONE )],
);

# ----- helpers -----------------------------------------------------------

sub get_setting {
	my ($name) = @_;
	no strict 'refs';
	return ${"${PKG}::$name"};
}

sub set_setting {
	my ( $name, $value ) = @_;
	no strict 'refs';
	${"${PKG}::$name"} = $value;
	return;
}

# The configuration machine: which of its two states are we in?
sub config_state {
	for my $name ( keys %DEFAULT ) {
		my ( $now, $want ) = ( get_setting($name), $DEFAULT{$name} );
		return 'CUSTOMISED' if defined $now != defined $want;
		return 'CUSTOMISED' if defined $now && $now ne $want;
	}
	return scalar keys %Lingua::EN::NameCase::MESSAGES ? 'CUSTOMISED' : 'DEFAULTS';
}

# Put the configuration into DEFAULTS, and back again after the block.
sub in_defaults {
	my ($code) = @_;
	my %saved   = map { $_ => get_setting($_) } keys %DEFAULT;
	my %msg     = %Lingua::EN::NameCase::MESSAGES;
	set_setting( $_, $DEFAULT{$_} ) for keys %DEFAULT;
	%Lingua::EN::NameCase::MESSAGES = ();
	my $ok    = eval { $code->(); 1 };
	my $error = $@;
	set_setting( $_, $saved{$_} ) for keys %saved;
	%Lingua::EN::NameCase::MESSAGES = %msg;
	die $error unless $ok;
	return;
}

# Run a call with the failure routine and the five stages watched.
# Returns { edge, path, result, error, fail_key, stages }.
sub observe {
	my ($code) = @_;
	my ( @stages, @fail_keys );
	my %real;
	{
		no strict 'refs';
		$real{$_} = \&{"${PKG}::$_"} for ( @STAGES, '_fail' );
	}
	for my $stage (@STAGES) {
		my $original = $real{$stage};
		mock "${PKG}::$stage" => sub { push @stages, $stage; return $original->(@_) };
	}
	mock "${PKG}::_fail" => sub { push @fail_keys, $_[0]; return $real{_fail}->(@_) };

	my @result;
	my $ok    = eval { @result = $code->(); 1 };
	my $error = $@;
	unmock "${PKG}::$_" for ( @STAGES, '_fail' );

	my $edge;
	if (@fail_keys) {
		$edge = $FAIL_EDGE{ $fail_keys[0] };
	}
	elsif (@stages) {
		$edge = 'E6';
	}
	else {
		$edge = 'E3';
	}
	return {
		ok       => $ok,
		edge     => $edge,
		path     => $PATH{$edge},
		result   => $result[0],
		count    => scalar @result,
		error    => $error,
		fail_key => $fail_keys[0],
		stages   => \@stages,
	};
}

# ----- machine B: the call -----------------------------------------------

subtest 'State: VALIDATING -> Trigger: bad argument -> State: FAILED' => sub {
	in_defaults( sub {
		my %bad = (
			'nc: hash ref'           => [ sub { nc( {} ) },                    'usage_nc' ],
			'nc: array ref'          => [ sub { nc( [] ) },                    'usage_nc' ],
			'nc: two arguments'      => [ sub { nc( 'a', 'b' ) },              'usage_nc' ],
			'NameCase: code ref'     => [ sub { scalar NameCase( sub { 1 } ) }, 'usage_namecase' ],
			'NameCase: glob ref'     => [ sub { scalar NameCase( \*STDOUT ) },  'usage_namecase' ],
			'NameCase: no argument'  => [ sub { scalar NameCase() },           'single_arg' ],
			'NameCase: two scalars'  => [ sub { scalar NameCase( 'a', 'b' ) }, 'single_arg' ],
		);
		for my $label ( sort keys %bad ) {
			my ( $code, $key ) = @{ $bad{$label} };
			my $seen = observe($code);
			ok( !$seen->{ok}, "$label: the call dies" );
			is( $seen->{fail_key}, $key, "$label: the documented message $key" );
			is( $seen->{edge}, 'E1', "$label: edge E1" );
			is_deeply( $seen->{path}, [qw( VALIDATING FAILED )], "$label: VALIDATING -> FAILED" );
			is_deeply( $seen->{stages}, [], "$label: casing never started" );
			is( $seen->{count}, 0, "$label: no result" );
		}
	} );
	done_testing();
};

subtest 'State: VALIDATING -> Trigger: good argument -> State: READING' => sub {
	in_defaults( sub {
		# READING is entered by every good argument: each of these goes on to
		# DONE or CASING, never to FAILED.
		for my $arg ( 'john', \'john', undef, q{}, '0' ) {
			my $seen = observe( sub { nc($arg) } );
			ok( $seen->{ok}, 'accepted: ' . ( defined $arg ? ( ref $arg || "'$arg'" ) : 'undef' ) );
			is( $seen->{fail_key}, undef, 'no failure' );
		}
		my $array = observe( sub { scalar NameCase( ['john'] ) } );
		ok( $array->{ok}, 'an array ref is accepted by NameCase' );
		my $list = observe( sub { NameCase( 'a', 'b' ) } );
		ok( $list->{ok}, 'a list is accepted by NameCase in list context' );
	} );
	done_testing();
};

subtest 'State: READING -> Trigger: undef, empty or "0" -> State: DONE' => sub {
	in_defaults( sub {
		for my $value ( undef, q{}, '0', \undef, \q{}, \'0' ) {
			my $label = ref $value ? 'ref to ' . ( defined ${$value} ? "'${$value}'" : 'undef' )
				: defined $value ? "'$value'" : 'undef';
			my $seen = observe( sub { nc($value) } );
			is( $seen->{edge}, 'E3', "$label: edge E3" );
			is_deeply( $seen->{path}, [qw( VALIDATING READING DONE )], "$label: path" );
			is_deeply( $seen->{stages}, [], "$label: no stage ran" );
			my $want = ref $value ? ${$value} : $value;
			is( $seen->{result}, $want, "$label: returned as it was" );
		}
	} );
	# DONE is reached even when the limit would otherwise refuse (E3 precedes E5)
	in_defaults( sub {
		set_setting( MAX_LENGTH => 0 );
		my $seen = observe( sub { nc('0') } );
		is( $seen->{edge}, 'E3', 'limit 0: the false value still goes READING -> DONE' );
	} );
	done_testing();
};

subtest 'State: READING -> Trigger: text -> State: CASING -> State: DONE' => sub {
	in_defaults( sub {
		my $seen = observe( sub { nc('henry viii phd') } );
		is( $seen->{edge}, 'E6', 'edge E6' );
		is_deeply( $seen->{path}, [qw( VALIDATING READING CASING DONE )], 'path' );
		is_deeply( $seen->{stages}, [@STAGES], 'all five stages ran, in the documented order' );
		is( $seen->{result}, 'Henry VIII PhD', 'the new string is returned' );
		returns_ok( $seen->{result}, { type => 'string' }, 'a string' );
	} );
	done_testing();
};

subtest 'State: CASING -> Trigger: ROMAN / POSTNOMINAL off -> stages skipped' => sub {
	my %expect = (
		'1,1' => [@STAGES],
		'1,0' => [ @STAGES[ 0 .. 3 ] ],
		'0,1' => [ @STAGES[ 0 .. 2 ], $STAGES[4] ],
		'0,0' => [ @STAGES[ 0 .. 2 ] ],
	);
	for my $combo ( sort keys %expect ) {
		my ( $roman, $post ) = split /,/, $combo;
		in_defaults( sub {
			set_setting( ROMAN => $roman );
			set_setting( POSTNOMINAL => $post );
			my $seen = observe( sub { nc('henry viii phd') } );
			is_deeply( $seen->{stages}, $expect{$combo}, "ROMAN=$roman POSTNOMINAL=$post: stages" );
			is( $seen->{edge}, 'E6', 'the call still ends in DONE through CASING' );
		} );
	}
	done_testing();
};

subtest 'State: READING -> Trigger: text over $MAX_LENGTH -> State: FAILED' => sub {
	in_defaults( sub {
		set_setting( MAX_LENGTH => $config{limit} );
		my $seen = observe( sub { nc('abcd') } );
		is( $seen->{edge}, 'E5', 'edge E5 (this edge was missing from the diagram)' );
		is_deeply( $seen->{path}, [qw( VALIDATING READING FAILED )], 'path' );
		is( $seen->{fail_key}, 'too_long', 'the documented message' );
		is_deeply( $seen->{stages}, [], 'casing never started' );
		like( $seen->{error}, qr/\AName is too long: 4 characters \(the maximum is 3\)/, 'exact message' );

		# at the limit the same call goes on to DONE
		my $at = observe( sub { nc('abc') } );
		is( $at->{edge}, 'E6', 'at the limit: CASING -> DONE instead' );
	} );
	done_testing();
};

subtest 'State: CASING -> Trigger: array ref in scalar/void context -> side effect' => sub {
	in_defaults( sub {
		my @names = ( 'john smith', 'MARY JONES' );
		my $ret   = NameCase( \@names );
		is_deeply( \@names, [ 'John Smith', 'Mary Jones' ], 'elements replaced on the way to DONE' );
		is( $ret, \@names, 'the array ref is returned' );

		# the only side effect on caller data: nothing else is changed
		my @list_in = ('john smith');
		my @copy    = NameCase( \@list_in );
		is_deeply( \@list_in, ['john smith'], 'list context: no side effect' );
		my $scalar = 'john smith';
		NameCase( \$scalar );
		is( $scalar, 'john smith', 'scalar ref: no side effect' );
		my $plain = 'john smith';
		my $copy  = NameCase($plain);
		is( $plain, 'john smith', 'plain scalar: no side effect' );
	} );
	done_testing();
};

# ----- invalid transitions -----------------------------------------------

subtest 'Invalid: FAILED -> any state (a failed call produces nothing)' => sub {
	in_defaults( sub {
		set_setting( MAX_LENGTH => $config{limit} );
		my @names = ( 'abc', 'abcd' );
		my $seen  = observe( sub { NameCase( \@names ) } );
		ok( !$seen->{ok}, 'FAILED is reached' );
		is( $seen->{count}, 0, 'FAILED -> DONE does not exist: no result handed back' );
		is_deeply( \@names, [ 'abc', 'abcd' ], 'FAILED -> side effect does not exist: array unchanged' );

		for my $bad ( [ sub { nc( {} ) }, 'usage_nc' ], [ sub { scalar NameCase() }, 'single_arg' ] ) {
			my $failed = observe( $bad->[0] );
			is_deeply( $failed->{stages}, [], "FAILED -> CASING does not exist ($bad->[1])" );
		}
		throws_ok { nc( {} ) } qr/\AUsage: nc /, 'the exception is thrown at once';
		# the module is usable again straight afterwards
		set_setting( MAX_LENGTH => undef );
		is( nc('john'), 'John', 'a failure leaves no residue: the next call works' );
	} );
	done_testing();
};

subtest 'Invalid: DONE -> CASING (a finished false value is never cased)' => sub {
	in_defaults( sub {
		my $seen = observe( sub { nc('0') } );
		is_deeply( $seen->{stages}, [], 'no stage ran after DONE' );
		is( $seen->{result}, '0', 'and the value is as given' );
	} );
	done_testing();
};

subtest 'Invalid: no call changes the configuration (either state)' => sub {
	my @calls = (
		sub { nc('john smith') },
		sub { nc(undef) },
		sub { eval { nc( {} ) } },
		sub { eval { nc( 'a' x 10 ) } },
		sub { NameCase( ['a b'] ) },
		sub { eval { NameCase() } },
	);
	# in DEFAULTS
	in_defaults( sub {
		is( config_state(), 'DEFAULTS', 'start: DEFAULTS' );
		$_->() for @calls;
		is( config_state(), 'DEFAULTS', 'after every kind of call: still DEFAULTS' );
	} );
	# in CUSTOMISED
	in_defaults( sub {
		set_setting( HEBREW => 0 );
		set_setting( MAX_LENGTH => $config{limit} + 20 );
		local $Lingua::EN::NameCase::MESSAGES{single_arg} = 'custom';
		is( config_state(), 'CUSTOMISED', 'start: CUSTOMISED' );
		my %before = map { $_ => get_setting($_) } keys %DEFAULT;
		my $messages = { %Lingua::EN::NameCase::MESSAGES };
		$_->() for @calls;
		is( config_state(), 'CUSTOMISED', 'after every kind of call: still CUSTOMISED' );
		is_deeply( { map { $_ => get_setting($_) } keys %DEFAULT }, \%before, 'no switch changed' );
		is_deeply( \%Lingua::EN::NameCase::MESSAGES, $messages, '%MESSAGES not changed' );
	} );
	done_testing();
};

subtest 'Invalid: a bad call does not corrupt either state' => sub {
	in_defaults( sub {
		eval { nc( {} ) };
		is( config_state(), 'DEFAULTS', 'DEFAULTS survives a failed call' );
		is( nc('o\'neil'), "O'Neil", 'and still gives the default answer' );
	} );
	in_defaults( sub {
		set_setting( SPANISH => 1 );
		eval { nc( [] ) };
		is( config_state(), 'CUSTOMISED', 'CUSTOMISED survives a failed call' );
		is( nc('el cid'), 'El Cid', 'and still gives the customised answer' );
	} );
	done_testing();
};

# ----- machine A: the configuration --------------------------------------

subtest 'State: DEFAULTS -> Trigger: set a switch -> State: CUSTOMISED' => sub {
	my %other = ( HEBREW => 0, SPANISH => 1, ROMAN => 0, POSTNOMINAL => 0, MAX_LENGTH => 50 );
	for my $name ( sort keys %other ) {
		in_defaults( sub {
			is( config_state(), 'DEFAULTS', "$name: start in DEFAULTS" );
			set_setting( $name => $other{$name} );
			is( config_state(), 'CUSTOMISED', "$name: set to $other{$name} -> CUSTOMISED" );
		} );
	}
	in_defaults( sub {
		$Lingua::EN::NameCase::MESSAGES{single_arg} = 'x';
		is( config_state(), 'CUSTOMISED', 'a %MESSAGES key -> CUSTOMISED' );
	} );
	done_testing();
};

subtest 'Action: later calls use the new configuration' => sub {
	in_defaults( sub {
		is( nc('bob ben david'), 'Bob ben David', 'DEFAULTS answer' );
		set_setting( HEBREW => 0 );
		is( nc('bob ben david'), 'Bob Ben David', 'CUSTOMISED answer: used at once' );
		set_setting( HEBREW => 1 );
		is( nc('bob ben david'), 'Bob ben David', 'back to the DEFAULTS answer' );

		$Lingua::EN::NameCase::MESSAGES{single_arg} = 'my own text';
		throws_ok { scalar NameCase() } qr/\Amy own text at /, 'a message override is used at once';
	} );
	done_testing();
};

subtest 'State: CUSTOMISED -> Trigger: set back -> State: DEFAULTS' => sub {
	for my $name ( sort grep { $_ ne 'MAX_LENGTH' } keys %DEFAULT ) {
		in_defaults( sub {
			set_setting( $name => $DEFAULT{$name} ? 0 : 1 );
			is( config_state(), 'CUSTOMISED', "$name changed" );
			set_setting( $name => $DEFAULT{$name} );
			is( config_state(), 'DEFAULTS', "$name set back -> DEFAULTS" );
		} );
	}
	in_defaults( sub {
		set_setting( MAX_LENGTH => 5 );
		set_setting( MAX_LENGTH => undef );
		is( config_state(), 'DEFAULTS', 'MAX_LENGTH set back to undef -> DEFAULTS' );
		$Lingua::EN::NameCase::MESSAGES{single_arg} = 'x';
		delete $Lingua::EN::NameCase::MESSAGES{single_arg};
		is( config_state(), 'DEFAULTS', 'the %MESSAGES key removed -> DEFAULTS' );
	} );
	done_testing();
};

subtest 'State: CUSTOMISED -> Trigger: leave a "local" block -> State: DEFAULTS' => sub {
	in_defaults( sub {
		{
			local $Lingua::EN::NameCase::ROMAN = 0;
			local $Lingua::EN::NameCase::MESSAGES{single_arg} = 'x';
			local $Lingua::EN::NameCase::MAX_LENGTH = 9;
			is( config_state(), 'CUSTOMISED', 'inside the block' );
		}
		is( config_state(), 'DEFAULTS', 'after the block' );

		# also when the block is left by an exception
		eval {
			local $Lingua::EN::NameCase::SPANISH = 1;
			die "leave\n";
		};
		is( config_state(), 'DEFAULTS', 'after a block left by die' );
	} );
	done_testing();
};

subtest 'State: CUSTOMISED -> Trigger: set again -> State: CUSTOMISED' => sub {
	in_defaults( sub {
		set_setting( HEBREW => 0 );
		set_setting( ROMAN  => 0 );
		is( config_state(), 'CUSTOMISED', 'two changes' );
		set_setting( HEBREW => 1 );
		is( config_state(), 'CUSTOMISED', 'one set back, one still different: stays CUSTOMISED' );
		set_setting( ROMAN => 1 );
		is( config_state(), 'DEFAULTS', 'all back: DEFAULTS' );
	} );
	done_testing();
};

subtest 'Invalid: setting a default value is not a transition' => sub {
	in_defaults( sub {
		set_setting( $_ => $DEFAULT{$_} ) for keys %DEFAULT;
		is( config_state(), 'DEFAULTS', 'DEFAULTS -> DEFAULTS' );
		set_setting( HEBREW => 'yes' );    # another true value: same behaviour
		is( nc('bob ben david'), 'Bob ben David', 'another true value behaves like 1' );
	} );
	done_testing();
};

# ----- temporal triggers -------------------------------------------------

subtest 'Temporal: no state expires (the diagram has no time edge)' => sub {
	in_defaults( sub {
		freeze_time( $config{frozen_at} );

		set_setting( HEBREW => 0 );
		my $before = nc('bob ben david');
		advance_time( $config{years} => 'seconds' );
		is( config_state(), 'CUSTOMISED', 'CUSTOMISED does not expire back to DEFAULTS' );
		is( nc('bob ben david'), $before, 'and gives the same answer fifty years later' );

		set_setting( HEBREW => 1 );
		is( config_state(), 'DEFAULTS', 'DEFAULTS reached after the time jump' );
		advance_time( $config{years} => 'seconds' );
		is( config_state(), 'DEFAULTS', 'DEFAULTS does not time out into CUSTOMISED' );

		# a failed call does not "heal" or "decay" either
		my $first  = observe( sub { nc( {} ) } );
		advance_time( $config{years} => 'seconds' );
		my $second = observe( sub { nc( {} ) } );
		( my $first_text  = $first->{error} )  =~ s/ at .*//s;
		( my $second_text = $second->{error} ) =~ s/ at .*//s;
		is( $second_text, $first_text, 'FAILED behaves the same later' );
		is( $second->{edge}, $first->{edge}, 'same edge later' );
	} );
	Test::Mockingbird::TimeTravel::restore_all();
	done_testing();
};

done_testing();
