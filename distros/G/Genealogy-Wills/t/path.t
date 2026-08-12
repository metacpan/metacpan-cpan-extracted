use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir tempfile);
use Readonly;
use Scalar::Util qw(blessed);
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;
use YAML::Any qw(DumpFile);

use_ok('Genealogy::Wills');

# -----------------------------------------------------------------------
# Constants
# -----------------------------------------------------------------------
Readonly my $MAX_YEAR       => (localtime)[5] + 1900;
Readonly my $ABOVE_MAX      => $MAX_YEAR + 1;
Readonly my $MOCK_URL       => 'freepages.rootsweb.com/path-test.html';
Readonly my @MOCK_ROWS      => (
	{ first => 'Alice', last => 'Smith', url => $MOCK_URL },
	{ first => 'Bob',   last => 'Smith', url => $MOCK_URL },
);
Readonly my %MOCK_ROW       => (first => 'Alice', last => 'Smith', url => $MOCK_URL);
Readonly my $MOCK_ROW_COUNT => scalar @MOCK_ROWS;

my $temp_dir = tempdir(CLEANUP => 1);

# -----------------------------------------------------------------------
# Inline mock DB packages — avoids Test::Mockingbird AUTOLOAD decay.
# After several mock/restore_all() cycles on AUTOLOAD-dispatched methods,
# Perl's method cache can return stale results.  Direct package definitions
# are immune to that effect.
# -----------------------------------------------------------------------
{
	package _PT_MockDB_Rows;
	sub new               { bless {}, shift }
	sub selectall_hashref { [ map { +{%$_} } @MOCK_ROWS ] }
	sub fetchrow_hashref  { +{ %MOCK_ROW } }
}

{
	package _PT_MockDB_Empty;
	sub new               { bless {}, shift }
	sub selectall_hashref { [] }
	sub fetchrow_hashref  { undef }
}

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

# White-box: install mock DB with rows; bypasses lazy-init ||=.
sub _inject_rows {
	my ($obj) = @_;
	$obj->{'wills'} = _PT_MockDB_Rows->new();
	return $obj->{'wills'};
}

# White-box: install empty mock DB.
sub _inject_empty {
	my ($obj) = @_;
	$obj->{'wills'} = _PT_MockDB_Empty->new();
	return $obj->{'wills'};
}

# =======================================================================
# new() CONTROL FLOW GRAPH
#
#  Entry: my $class = shift; my $params;
#    |
#    +--[A: scalar(@_)==1 && !ref($_[0])]
#    |    TRUE  --> $params->{'directory'} = $_[0]
#    |    FALSE --> $params = Params::Get::get_params(undef, \@_)
#    |
#    +--[B: !defined($class)]  TRUE  --> $class = __PACKAGE__ --> [D]
#    +--[C: blessed($class)]   TRUE  --> return bless clone        EXIT:CLONE
#    |   (fall-through: string class) ----------------------------> [D]
#    |
#    +--[D: defined(config_file) && !-r]
#    |    TRUE  --> Carp::croak "Can't load configuration..."      EXIT:CROAK-CONFIG
#    |    FALSE --> [E]
#    |
#    +--[E: defined(logger)]
#    |    FALSE --> configure() --> [G]
#    |    TRUE  --> [F]
#    |
#    +--[F: !blessed(l) || !can('info') || !can('error')]
#    |    TRUE  --> Carp::croak "Logger must be..."               EXIT:CROAK-LOGGER
#    |    FALSE --> configure() --> [G]
#    |
#    configure()
#    |
#    +--[G: directory //= MODULE_DATA_DIR]  (fires when dir undef after configure)
#    |
#    +--[H: !(-d dir && -r _)]
#         TRUE  --> Carp::carp + return undef                      EXIT:CARP-UNDEF
#         FALSE --> return bless { cache_duration => ..., %params } EXIT:BLESS
# =======================================================================

# -----------------------------------------------------------------------
# PN-1  A=FALSE(empty @_)  B=TRUE(undef class)->__PACKAGE__  D=F  E=F
#        G://= fires  H: depends on data-dir presence
# ::new() function form with no args -- $class defaults to __PACKAGE__.
# -----------------------------------------------------------------------
subtest 'PN-1: ::new() function form, no args => class defaults to __PACKAGE__' => sub {
	my $result;
	lives_ok(
		sub {
			local $SIG{__WARN__} = sub { };    # suppress carp if data dir absent
			$result = Genealogy::Wills::new();
		},
		'PN-1: ::new() with no args does not die'
	);
	# Either a valid object (data dir present) or undef (data dir absent) is correct.
	if(defined $result) {
		isa_ok($result, 'Genealogy::Wills', 'PN-1: object when data dir present');
	} else {
		ok(!defined $result, 'PN-1: undef when data dir absent');
	}
	diag defined $result ? 'PN-1: data dir present' : 'PN-1: data dir absent'
		if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# PN-2  A=TRUE(single string)  C=TRUE(blessed class)->clone
# instance->new(string): single-string arg sets directory in clone.
# -----------------------------------------------------------------------
subtest 'PN-2: blessed->new(string) => A=TRUE branch, clone with directory override' => sub {
	my $orig  = Genealogy::Wills->new(directory => $temp_dir);
	my $clone = $orig->new($temp_dir);

	isa_ok($clone, 'Genealogy::Wills', 'PN-2: clone is correct class');
	isnt($clone, $orig,               'PN-2: clone is a new reference');
	is($clone->{'directory'}, $temp_dir, 'PN-2: directory from single-string arg');
};

# -----------------------------------------------------------------------
# PN-3  A=FALSE(empty @_)  C=TRUE(blessed)->clone  params=undef -> // {} fires
# instance->new() with no args: // {} guard is exercised; all attrs inherited.
# -----------------------------------------------------------------------
subtest 'PN-3: blessed->new() no args => params // {} guard exercised, attrs inherited' => sub {
	my $orig  = Genealogy::Wills->new(directory => $temp_dir, cache_duration => '3 hours');
	my $clone = $orig->new();    # Params::Get may return undef; // {} handles it

	isa_ok($clone, 'Genealogy::Wills',   'PN-3: clone correct class');
	isnt($clone, $orig,                   'PN-3: distinct reference');
	is($clone->{'directory'},      $temp_dir,  'PN-3: directory inherited');
	is($clone->{'cache_duration'}, '3 hours',  'PN-3: cache_duration inherited');
};

# -----------------------------------------------------------------------
# PN-4  A=FALSE(flat list)  C=TRUE(blessed)->clone with override
# instance->new(key=>val): override merged on top of original.
# -----------------------------------------------------------------------
subtest 'PN-4: blessed->new(key=>val) => override merged, non-overridden attrs kept' => sub {
	my $orig  = Genealogy::Wills->new(directory => $temp_dir);
	my $clone = $orig->new(cache_duration => '7 days');

	is($clone->{'cache_duration'}, '7 days',  'PN-4: override applied');
	is($clone->{'directory'},      $temp_dir,  'PN-4: non-overridden attr inherited');
};

# -----------------------------------------------------------------------
# PN-5  A=TRUE(single string)  B/C=FALSE(string class)  D=F  E=F  G=no-op  H=pass
# class->new(string): A branch taken; directory set from single-string arg.
# -----------------------------------------------------------------------
subtest 'PN-5: class->new(string) => A=TRUE, directory from string, success' => sub {
	my $obj = Genealogy::Wills->new($temp_dir);

	ok(defined $obj,                   'PN-5: object defined');
	is($obj->{'directory'}, $temp_dir, 'PN-5: directory set from single-string arg');
};

# -----------------------------------------------------------------------
# PN-6  A=FALSE(hashref)  B/C=FALSE  D=F  E=F  G=no-op  H=pass
# class->new({ dir => ... }): hashref arg form; get_params normalizes.
# -----------------------------------------------------------------------
subtest 'PN-6: class->new({ directory => ... }) hashref => A=FALSE, get_params branch' => sub {
	my $obj = Genealogy::Wills->new({ directory => $temp_dir });

	ok(defined $obj,                   'PN-6: object defined');
	is($obj->{'directory'}, $temp_dir, 'PN-6: directory from hashref arg');
};

# -----------------------------------------------------------------------
# PN-7  A=FALSE(flat list)  B/C=FALSE  D=F  E=F  G=no-op  H=pass
# class->new(key=>val): flat list; get_params normalizes.
# -----------------------------------------------------------------------
subtest 'PN-7: class->new(key=>val) flat list => A=FALSE, get_params branch' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir, cache_duration => '2 days');

	ok(defined $obj,                        'PN-7: object defined');
	is($obj->{'cache_duration'}, '2 days',  'PN-7: extra key stored');
};

# -----------------------------------------------------------------------
# PN-8  D=TRUE(config_file defined + !-r) -> croak
# -----------------------------------------------------------------------
subtest 'PN-8: config_file defined + not readable => D=TRUE, croak' => sub {
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/no/such/config.yml') },
		qr/Can't load configuration from/,
		'PN-8: croak message matches documented text'
	);
	throws_ok(
		sub { Genealogy::Wills->new(config_file => '/no/such/config.yml') },
		qr{/no/such/config\.yml},
		'PN-8: croak includes the offending path'
	);
};

# -----------------------------------------------------------------------
# PN-9  D=FALSE(config_file defined + readable)  E=F  G=no-op  H=pass
# config_file readable: D check passes, no croak, object created.
# -----------------------------------------------------------------------
subtest 'PN-9: config_file defined + readable => D=FALSE, success' => sub {
	my $config = File::Spec->catfile($temp_dir, 'pn9.yml');
	DumpFile($config, { Genealogy__Wills => { directory => $temp_dir } });

	my $obj = Genealogy::Wills->new(config_file => $config);

	ok(defined $obj,                  'PN-9: object created when config_file readable');
	isa_ok($obj, 'Genealogy::Wills', 'PN-9: correct class');
};

# -----------------------------------------------------------------------
# PN-10  E=TRUE  F=TRUE(!blessed) -> croak "Logger must be..."
# -----------------------------------------------------------------------
subtest 'PN-10: logger not blessed => F=TRUE(!blessed), croak' => sub {
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => 'plain_string') },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'PN-10: unblessed logger croaks with exact message'
	);
};

# -----------------------------------------------------------------------
# PN-11  E=TRUE  F=TRUE(!can info) -> croak
# -----------------------------------------------------------------------
subtest 'PN-11: logger blessed + missing info() => F=TRUE(!can info), croak' => sub {
	{
		package _PT_NoInfoLogger;
		sub new   { bless {}, shift }
		sub error { }
	}
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => _PT_NoInfoLogger->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'PN-11: logger missing info() croaks'
	);
};

# -----------------------------------------------------------------------
# PN-12  E=TRUE  F=TRUE(!can error) -> croak
# -----------------------------------------------------------------------
subtest 'PN-12: logger has info() but missing error() => F=TRUE(!can error), croak' => sub {
	{
		package _PT_NoErrorLogger;
		sub new  { bless {}, shift }
		sub info { }
	}
	throws_ok(
		sub { Genealogy::Wills->new(directory => $temp_dir, logger => _PT_NoErrorLogger->new()) },
		qr/Logger must be an object with info\(\) and error\(\)/,
		'PN-12: logger missing error() croaks even with info() present'
	);
};

# -----------------------------------------------------------------------
# PN-13  E=TRUE  F=FALSE(all checks pass) -> configure -> G=no-op -> H=pass
# -----------------------------------------------------------------------
subtest 'PN-13: valid logger (both methods) => F=FALSE, no croak, success' => sub {
	{
		package _PT_GoodLogger;
		sub new   { bless {}, shift }
		sub info  { }
		sub error { }
	}
	my $obj;
	lives_ok(
		sub { $obj = Genealogy::Wills->new(directory => $temp_dir, logger => _PT_GoodLogger->new()) },
		'PN-13: valid logger does not croak'
	);
	ok(defined $obj, 'PN-13: object created');
};

# -----------------------------------------------------------------------
# PN-14  E=FALSE(logger=undef, defined() is false) -> skip F block -> success
# -----------------------------------------------------------------------
subtest 'PN-14: logger => undef => E=FALSE, validation block skipped' => sub {
	my $obj;
	lives_ok(
		sub { $obj = Genealogy::Wills->new(directory => $temp_dir, logger => undef) },
		'PN-14: logger => undef does not croak'
	);
	ok(defined $obj, 'PN-14: object created when logger explicitly undef');
};

# -----------------------------------------------------------------------
# PN-15  No directory arg -> configure returns no dir -> G: //= fires
# The //= branch is taken; outcome depends on MODULE_DATA_DIR presence.
# -----------------------------------------------------------------------
subtest 'PN-15: no directory => G(//= MODULE_DATA_DIR) branch fires, no croak' => sub {
	lives_ok(
		sub {
			local $SIG{__WARN__} = sub { };
			Genealogy::Wills->new();    # no dir -> //= fires
		},
		'PN-15: //= branch does not cause a croak'
	);
};

# -----------------------------------------------------------------------
# PN-16  directory defined -> G no-op -> H=FALSE(-d+r ok) -> bless
# Default cache_duration constant is applied in the bless.
# -----------------------------------------------------------------------
subtest 'PN-16: valid directory => G no-op, H=FALSE, bless with default cache_duration' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	ok(defined $obj,                       'PN-16: object defined');
	isa_ok($obj, 'Genealogy::Wills',       'PN-16: blessed correctly');
	is($obj->{'cache_duration'}, '1 day',  'PN-16: default cache_duration applied');
	is($obj->{'directory'}, $temp_dir,     'PN-16: directory stored');
};

# -----------------------------------------------------------------------
# PN-17  H=TRUE(-d fails) -> Carp::carp + return undef
# -----------------------------------------------------------------------
subtest 'PN-17: non-existent directory => H=TRUE(-d fails), carp + undef' => sub {
	my $obj;
	warning_like(
		sub { $obj = Genealogy::Wills->new(directory => '/no/such/path/xyz') },
		qr/is not a directory/,
		'PN-17: carp message contains "is not a directory"'
	);
	ok(!defined $obj, 'PN-17: undef returned (not a croak)');
};

# -----------------------------------------------------------------------
# PN-18  H=TRUE(-d ok, -r fails) -> Carp::carp + return undef
# Requires creating a directory we own but make mode 0000.
# -----------------------------------------------------------------------
subtest 'PN-18: directory exists but not readable => H=TRUE(-r fails), carp + undef' => sub {
	SKIP: {
		skip 'Running as root: chmod 0 has no effect', 2 if $> == 0;
		skip 'Windows does not honour Unix permissions', 2 if $^O eq 'MSWin32';

		my $unreadable = tempdir(CLEANUP => 1);
		chmod 0, $unreadable or skip "chmod failed: $!", 2;

		my $obj;
		warning_like(
			sub { $obj = Genealogy::Wills->new(directory => $unreadable) },
			qr/is not a directory/,
			'PN-18: carp fires for unreadable directory'
		);
		ok(!defined $obj, 'PN-18: undef returned');

		chmod 0755, $unreadable;    # restore so File::Temp CLEANUP works
	}
};

# =======================================================================
# search() CONTROL FLOW GRAPH
#
#  Entry: my $self = shift
#    |
#    +--[A: !blessed($self)]------------- TRUE  -> croak "search() must be..."  EXIT:CROAK-A
#    |                                    FALSE -> [B]
#    +--[B: !@_]------------------------ TRUE  -> croak "Usage: search(..."     EXIT:CROAK-B
#    |                                    FALSE -> [C]
#    +--[C: validate_strict(get_params)] THROWS -> die (PVS)                   EXIT:DIE-C
#    |                                    OK    -> $params -> [D]
#    +--[D: !length(last // '')]-------- TRUE  -> carp + return                 EXIT:CARP-D
#    |                                    FALSE -> [E]
#    +--[E: $self->{'wills'} ||= new()]  new() returns undef -> [F=TRUE]
#    |                                    new() returns obj  -> [F=FALSE]
#    |                                    already set (||= no-op) -> [F=FALSE]
#    +--[F: !defined(wills)]------------ TRUE  -> croak "Can't open..."         EXIT:CROAK-F
#    |                                    FALSE -> [G]
#    +--[G: wantarray]------------------ TRUE  -> [H list branch]
#    |                                    FALSE -> [I scalar branch]
#    +--[H: selectall_hashref // []]
#    |  [H-LOOP: for @{$wills}]--------- 0 iters (empty)
#    |                                    N iters -> _decorate_will each
#    |  return @{$wills}                                                         EXIT:LIST
#    +--[I: defined(fetchrow_hashref)]-- TRUE  -> Return::Set -> return hashref  EXIT:SCALAR-FOUND
#                                         FALSE -> return                         EXIT:SCALAR-UNDEF
# =======================================================================

# -----------------------------------------------------------------------
# PS-1  A=TRUE(!blessed) -> croak
# -----------------------------------------------------------------------
subtest 'PS-1: A=TRUE(!blessed) => croak "search() must be called on an object"' => sub {
	throws_ok(
		sub { Genealogy::Wills->search(last => 'Smith') },
		qr/search\(\) must be called on an object/,
		'PS-1: exact croak message'
	);
};

# -----------------------------------------------------------------------
# PS-2  A=FALSE  B=TRUE(!@_) -> croak "Usage: search(..."
# -----------------------------------------------------------------------
subtest 'PS-2: A=FALSE, B=TRUE(no args) => croak "Usage: search(...)"' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	throws_ok(
		sub { $obj->search() },
		qr/Usage:\s+search/,
		'PS-2: Usage croak message'
	);
};

# -----------------------------------------------------------------------
# PS-3  A=F  B=F  C=THROWS(invalid 'last') -> die propagates
# -----------------------------------------------------------------------
subtest 'PS-3: C=THROWS on invalid last => die propagates from PVS' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	dies_ok(sub { $obj->search(last => "O'Brien") },
		"PS-3a: apostrophe in last -> PVS die");
	dies_ok(sub { $obj->search(last => 'Smith;DROP') },
		'PS-3b: semicolon in last -> PVS die');
	dies_ok(sub { $obj->search(last => 'X' x 101) },
		'PS-3c: 101-char last (above max) -> PVS die');
};

# -----------------------------------------------------------------------
# PS-3d  C=THROWS on invalid optional field (first/town with injection char)
# -----------------------------------------------------------------------
subtest 'PS-3d: C=THROWS on invalid optional field => die' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	dies_ok(sub { $obj->search(last => 'Smith', first => '<script>') },
		'PS-3d: XSS in first -> PVS die');
	dies_ok(sub { $obj->search(last => 'Smith', town => "Town\x00") },
		'PS-3d: null byte in town -> PVS die');
};

# -----------------------------------------------------------------------
# PS-3e  C=THROWS on year out of range
# -----------------------------------------------------------------------
subtest 'PS-3e: C=THROWS on year out of range => die' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	dies_ok(sub { $obj->search(last => 'Smith', year => 0) },
		'PS-3e: year=0 (below min=1) -> PVS die');
	dies_ok(sub { $obj->search(last => 'Smith', year => $ABOVE_MAX) },
		'PS-3e: year above MAX -> PVS die');
};

# -----------------------------------------------------------------------
# PS-4  D=TRUE(last=undef)  list context -> carp + return (empty list)
# -----------------------------------------------------------------------
subtest 'PS-4: D=TRUE(undef last) list context => carp + empty list' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	my @results;
	warning_like(
		sub { @results = $obj->search(last => undef) },
		qr/Value for 'last' is mandatory/,
		'PS-4: carp text matches documented message'
	);
	is(scalar @results, 0, 'PS-4: bare return in list context => empty list');
};

# -----------------------------------------------------------------------
# PS-4b  D=TRUE(last=undef)  scalar context -> carp + undef
# Bare `return;` yields undef (not empty list) in scalar context.
# -----------------------------------------------------------------------
subtest 'PS-4b: D=TRUE(undef last) scalar context => carp + undef' => sub {
	my $obj    = Genealogy::Wills->new(directory => $temp_dir);
	my $result = 'sentinel';
	warning_like(
		sub { $result = $obj->search(last => undef) },
		qr/Value for 'last' is mandatory/,
		'PS-4b: carp fires in scalar context too'
	);
	ok(!defined $result, 'PS-4b: bare return in scalar context => undef, not empty list');
};

# -----------------------------------------------------------------------
# PS-5  E: wills->new() returns undef  F=TRUE -> croak "Can't open..."
# -----------------------------------------------------------------------
subtest "PS-5: E: wills->new()=undef, F=TRUE => croak \"Can't open the wills database\"" => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	mock 'Genealogy::Wills::wills::new' => sub { return undef };

	throws_ok(
		sub { $obj->search(last => 'Smith') },
		qr/Can't open the wills database/,
		"PS-5: croak text matches documented message"
	);

	restore_all();
};

# -----------------------------------------------------------------------
# PS-6  E: wills->new() succeeds (first call)  G=TRUE(list)  H-LOOP: 0 iters
# selectall returns [] -> for loop body never executes -> return ()
# fixate call count = 0 proves the loop body was skipped.
# -----------------------------------------------------------------------
subtest 'PS-6: first call, list context, empty result => H-LOOP 0 iters, fixate=0' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	mock 'Genealogy::Wills::wills::new' => sub { bless {}, 'Genealogy::Wills::wills' };
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };

	my $fixate_calls = 0;
	my $real_fixate  = \&Data::Reuse::fixate;
	mock 'Data::Reuse::fixate' => sub { $fixate_calls++; $real_fixate->(@_) };

	my @results = $obj->search(last => 'Nonexistent');

	is(scalar @results, 0, 'PS-6: empty list returned');
	is($fixate_calls,   0, 'PS-6: fixate=0 proves loop body never ran (0 iterations)');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-7  E: wills->new() succeeds (first call)  G=TRUE(list)  H-LOOP: N iters
# selectall returns N rows -> _decorate_will called N times (via fixate count).
# -----------------------------------------------------------------------
subtest 'PS-7: first call, list context, N rows => H-LOOP N iters, all rows decorated' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	mock 'Genealogy::Wills::wills::new' => sub { bless {}, 'Genealogy::Wills::wills' };
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		return [ map { +{%$_} } @MOCK_ROWS ];
	};

	my $fixate_calls = 0;
	my $real_fixate  = \&Data::Reuse::fixate;
	mock 'Data::Reuse::fixate' => sub { $fixate_calls++; $real_fixate->(@_) };

	my @results = $obj->search(last => 'Smith');

	is(scalar @results, $MOCK_ROW_COUNT, 'PS-7: all rows returned');
	is($fixate_calls,   $MOCK_ROW_COUNT, 'PS-7: fixate=N proves loop ran N times');
	like($results[0]->{'url'}, qr{^https://}, 'PS-7: first row url decorated');
	like($results[1]->{'url'}, qr{^https://}, 'PS-7: second row url decorated');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-8  E: ||= no-op (wills pre-set)  G=FALSE(scalar)  I=FALSE(fetchrow=undef) -> return
# -----------------------------------------------------------------------
subtest 'PS-8: wills pre-set (||= no-op), scalar context, fetchrow=undef => return undef' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_empty($obj);    # _PT_MockDB_Empty::fetchrow_hashref always returns undef

	my $new_calls = 0;
	mock 'Genealogy::Wills::wills::new' => sub { $new_calls++ };

	my $result = $obj->search(last => 'Nonexistent');

	is($new_calls, 0,    'PS-8: ||= short-circuited, wills::new not called');
	ok(!defined $result, 'PS-8: I=FALSE -> bare return -> undef');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-9  E: ||= no-op (wills pre-set)  G=FALSE(scalar)  I=TRUE(fetchrow defined)
#        -> Return::Set::set_return -> return hashref
# -----------------------------------------------------------------------
subtest 'PS-9: wills pre-set, scalar context, fetchrow defined => Return::Set, hashref' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	# Use the inline package so fetchrow_hashref is a real named method, not a
	# Test::Mockingbird stash entry that degrades after multiple restore_all() cycles.
	_inject_rows($obj);

	my $set_return_calls = 0;
	my $real_set_return  = \&Return::Set::set_return;
	mock 'Return::Set::set_return' => sub {
		$set_return_calls++;
		$real_set_return->(@_);
	};

	my $result = $obj->search(last => 'Smith');

	is($set_return_calls, 1,             'PS-9: Return::Set::set_return called once');
	ok(defined $result,                   'PS-9: result is defined');
	is(ref($result), 'HASH',              'PS-9: I=TRUE -> hashref returned');
	like($result->{'url'}, qr{^https://}, 'PS-9: url decorated');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-10  E: ||= no-op on SECOND call (wills slot already populated)
# Verifies the ||= short-circuit on a second search() invocation.
# -----------------------------------------------------------------------
subtest 'PS-10: second call => E(||= no-op), wills::new never called for pre-set slot' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_rows($obj);    # wills slot pre-set

	my $new_calls = 0;
	mock 'Genealogy::Wills::wills::new' => sub {
		$new_calls++;
		return bless {}, 'Genealogy::Wills::wills';
	};

	my @r1 = $obj->search(last => 'Smith');
	my @r2 = $obj->search(last => 'Smith');

	is($new_calls, 0,              'PS-10: wills::new never called (slot was pre-set)');
	is(scalar @r1, $MOCK_ROW_COUNT, 'PS-10: first call returns rows');
	is(scalar @r2, $MOCK_ROW_COUNT, 'PS-10: second call returns rows');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-11  bare-string arg form -> Params::Get maps 'Smith' to { last => 'Smith' }
# Verified by capturing what reaches selectall_hashref.
# -----------------------------------------------------------------------
subtest 'PS-11: bare-string arg => get_params maps to {last=>str}, forwarded to DB' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search('Smith');

	is($captured{'last'}, 'Smith', "PS-11: bare 'Smith' -> { last => 'Smith' } at DB");
	ok(!exists $captured{'first'},  'PS-11: no spurious first key added');

	restore_all();
};

# -----------------------------------------------------------------------
# PS-12  hashref arg form -> get_params normalizes -> same path as flat list
# -----------------------------------------------------------------------
subtest 'PS-12: hashref arg form { last=>... } => get_params normalizes, same path' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search({ last => 'Jones' });

	is($captured{'last'}, 'Jones', "PS-12: hashref { last => 'Jones' } forwarded to DB");

	restore_all();
};

# =======================================================================
# _decorate_will() CONTROL FLOW GRAPH
#
# No conditional branches. Single sequential path:
#   Entry: my $will = shift
#   -> $will->{'url'} = 'https://' . $will->{'url'}   (url mutated in place)
#   -> Data::Reuse::fixate(%{$will})                   (strings interned)
#   -> return $will                                     (same ref returned)
# =======================================================================

# -----------------------------------------------------------------------
# PD-1  Sequential path: url prepend, fixate, return same ref.
# -----------------------------------------------------------------------
subtest 'PD-1: _decorate_will sole path => url prepended, fixate called, same ref' => sub {
	my $will = { first => 'Alice', last => 'Smith', url => 'example.com/test' };

	my $fixate_called = 0;
	my $real_fixate   = \&Data::Reuse::fixate;
	mock 'Data::Reuse::fixate' => sub { $fixate_called++; $real_fixate->(@_) };

	my $returned = Genealogy::Wills::_decorate_will($will);

	is($will->{'url'},  'https://example.com/test', 'PD-1: url prepended in place');
	is($returned,       $will,                       'PD-1: same hashref returned');
	is($fixate_called,  1,                           'PD-1: fixate called exactly once');

	restore_all();
};

# =======================================================================
# DEAD CODE SUMMARY
# No dead code detected in Genealogy::Wills.pm.
# All branches in new() and search() are reachable:
#   - !defined($class) branch: reached via Genealogy::Wills::new() with no args
#   - blessed($class)  branch: reached via $obj->new(...)
#   - string class           : reached via Genealogy::Wills->new(...)
#   - config_file croak      : reached when file missing/unreadable
#   - logger croak           : reached when logger lacks required methods
#   - carp+undef             : reached when directory invalid
#   - D=TRUE(undef last)     : reached when last => undef
#   - F=TRUE(wills=undef)    : reached when wills::new() returns undef
#   - list branch            : reached when wantarray is true
#   - scalar found           : reached when fetchrow_hashref returns a row
#   - scalar undef           : reached when fetchrow_hashref returns undef
#
# LOOP ANALYSIS
# `_decorate_will($_) for @{$wills}` in search():
#   - Executes 0 times  (empty result set)     : covered by PS-6
#   - Executes N times  (N rows returned)      : covered by PS-7
#   - Can execute 2+ times: no loop-reduction annotation required.
# =======================================================================

done_testing();
