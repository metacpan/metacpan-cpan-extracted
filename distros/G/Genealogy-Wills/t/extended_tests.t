use strict;
use warnings;

use File::Temp qw(tempdir);
use Readonly;
use Test::Needs 'Test::Mockingbird';
use Test::Mockingbird;
use Test::Most;
use Test::Returns;

use_ok('Genealogy::Wills');

# -----------------------------------------------------------------------
# Constants -- no magic literals in test bodies.
# -----------------------------------------------------------------------
Readonly my $MOCK_URL       => 'freepages.rootsweb.com/example.html';
Readonly my @MOCK_ROWS      => (
	{ first => 'John',  last => 'Smith', url => $MOCK_URL },
	{ first => 'Jane',  last => 'Smith', url => $MOCK_URL },
	{ first => 'James', last => 'Smith', url => $MOCK_URL },
);
Readonly my %MOCK_ROW       => (first => 'John', last => 'Smith', url => $MOCK_URL);
Readonly my $MOCK_ROW_COUNT => scalar @MOCK_ROWS;

my $temp_dir = tempdir(CLEANUP => 1);

# -----------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------

# Pre-set the wills slot on $obj to a mock DB object (3 rows).
# Bypasses the lazy-init ||= so no real SQLite file is needed.
# Call restore_all() at the end of every subtest that uses this.
sub _inject {
	my ($obj) = @_;
	my $mock_db = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		return [ map { +{%$_} } @MOCK_ROWS ];
	};
	mock 'Genealogy::Wills::wills::fetchrow_hashref' => sub {
		return { %MOCK_ROW };
	};
	$obj->{'wills'} = $mock_db;
	return $mock_db;
}

# Same as _inject but both DB methods return no-result values.
sub _inject_empty {
	my ($obj) = @_;
	my $mock_db = bless {}, 'Genealogy::Wills::wills';
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };
	mock 'Genealogy::Wills::wills::fetchrow_hashref'  => sub { undef };
	$obj->{'wills'} = $mock_db;
	return $mock_db;
}

# =======================================================================
# SECTION 1: Scalar context for undef last
#
# unit.t tests the undef-last carp path in LIST context only.
# Here we cover SCALAR context: the bare `return;` after Carp::carp must
# produce undef (not an empty list) when the caller stores into a scalar.
# =======================================================================

subtest 'search() scalar context + undef last: carps and returns undef' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	# No DB mock needed -- carp fires before the DB layer is reached.

	my $result = 'not_undef';    # sentinel to prove the variable is overwritten
	warning_like(
		sub { $result = $obj->search(last => undef) },
		qr/Value for 'last' is mandatory/,
		'carp fires in scalar context exactly as in list context'
	);
	ok(!defined $result,
		'scalar context: bare return; after carp yields undef, not an empty list');
};

# =======================================================================
# SECTION 2: new() with logger => undef
#
# new() has: if (defined $params->{'logger'}) { ... }
# When logger is explicitly undef the branch is skipped entirely.
# No existing test exercises this LCSAJ path.
# =======================================================================

subtest 'new() logger => undef: validation block skipped, object still created' => sub {
	my $obj;
	lives_ok(
		sub { $obj = Genealogy::Wills->new(directory => $temp_dir, logger => undef) },
		'logger => undef does not trigger the croak branch'
	);
	ok(defined $obj,                  'object is defined when logger is explicitly undef');
	isa_ok($obj, 'Genealogy::Wills', 'returned value is a Genealogy::Wills object');

	diag "obj directory: $obj->{'directory'}" if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 3: Args forwarded to Genealogy::Wills::wills->new()
#
# search() calls:
#   Genealogy::Wills::wills->new(no_entry => 1, no_fixate => 1, %{$self})
# No existing test captures what is actually passed to wills->new().
# =======================================================================

subtest 'search() forwards no_entry, no_fixate, and directory to wills->new()' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);

	my @captured_args;
	mock 'Genealogy::Wills::wills::new' => sub {
		my $class = shift;
		@captured_args = @_;
		return bless {}, 'Genealogy::Wills::wills';
	};
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub { [] };

	my @r = $obj->search(last => 'Smith');

	my %args = @captured_args;
	is($args{'no_entry'},  1,         'no_entry => 1 forwarded to wills->new()');
	is($args{'no_fixate'}, 1,         'no_fixate => 1 forwarded to wills->new()');
	is($args{'directory'}, $temp_dir, 'directory forwarded to wills->new()');

	diag 'wills::new args: ' . join(', ', @captured_args) if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 4: Void context search()
#
# wantarray returns undef (false) in void context, same as scalar context.
# The scalar branch (fetchrow_hashref) must be taken without dying.
# =======================================================================

subtest 'search() in void context: scalar branch taken, no error' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject($obj);

	# Return value silently discarded = void context.
	lives_ok(
		sub { $obj->search(last => 'Smith') },
		'search() in void context does not die'
	);

	restore_all();
};

# =======================================================================
# SECTION 5: Hashref argument form -- happy path
#
# carp.t tests search({ last => undef }) (the carp path) but NOT the
# success path.  search({ last => 'Smith' }) must return decorated rows.
# =======================================================================

subtest 'search({ last => "Smith" }) hashref form: happy path returns decorated rows' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject($obj);

	my @results;
	lives_ok(
		sub { @results = $obj->search({ last => 'Smith' }) },
		'hashref argument form does not die'
	);
	is(scalar @results, $MOCK_ROW_COUNT, 'hashref form returns correct number of rows');
	like($results[0]->{'url'}, qr{^https://}, 'hashref form: url decorated with https://');

	restore_all();
};

# =======================================================================
# SECTION 6: _decorate_will called exactly N times for N-row list
#
# The for loop `_decorate_will($_) for @{$wills}` must call the helper
# exactly once per row.  Verified by counting Data::Reuse::fixate calls
# (each _decorate_will call invokes fixate exactly once).
# =======================================================================

subtest '_decorate_will called once per row: fixate count equals row count' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject($obj);    # 3 rows

	my $fixate_calls = 0;
	my $real_fixate  = \&Data::Reuse::fixate;
	mock 'Data::Reuse::fixate' => sub {
		$fixate_calls++;
		$real_fixate->(@_);
	};

	my @results = $obj->search(last => 'Smith');

	is($fixate_calls, $MOCK_ROW_COUNT,
		"fixate called $MOCK_ROW_COUNT times (once per row) in list context");
	is(scalar @results, $MOCK_ROW_COUNT, 'correct row count returned');

	diag "fixate_calls=$fixate_calls" if $ENV{TEST_VERBOSE};

	restore_all();
};

# =======================================================================
# SECTION 7: Data::Reuse::fixate NOT called for empty list
#
# When selectall_hashref returns [], the for-loop body never executes,
# so fixate must be called zero times.  Exercises the empty-list LCSAJ
# branch through the for loop.
# =======================================================================

subtest 'fixate not called when list result is empty' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject_empty($obj);

	my $fixate_calls = 0;
	# Do NOT call the real fixate here -- strings need not be interned for this test.
	mock 'Data::Reuse::fixate' => sub { $fixate_calls++ };

	my @results = $obj->search(last => 'Nonexistent');

	is($fixate_calls, 0,            'Data::Reuse::fixate never called for empty result set');
	is(scalar @results, 0,          'empty result confirmed');

	restore_all();
};

# =======================================================================
# SECTION 8: Return::Set::set_return invoked in scalar non-null path
#
# The scalar branch calls:
#   Return::Set::set_return(_decorate_will($will), { type => 'hashref', min => 1 })
# No existing test verifies that Return::Set::set_return is actually invoked.
# =======================================================================

subtest 'Return::Set::set_return invoked exactly once in scalar result path' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject($obj);

	my $set_return_calls = 0;
	my $real_set_return  = \&Return::Set::set_return;
	mock 'Return::Set::set_return' => sub {
		$set_return_calls++;
		$real_set_return->(@_);
	};

	my $result = $obj->search(last => 'Smith');

	is($set_return_calls, 1, 'Return::Set::set_return called exactly once in scalar context');
	ok(defined $result,      'scalar result is defined');
	is(ref($result), 'HASH', 'scalar result is a hashref');

	restore_all();
};

# =======================================================================
# SECTION 9: Alternating list/scalar calls on the same object
#
# wantarray is evaluated freshly on every search() invocation.
# List calls take the selectall_hashref path; scalar calls take
# fetchrow_hashref.  Interleaving must not corrupt either path.
# =======================================================================

subtest 'search() alternating list/scalar contexts: no cross-contamination' => sub {
	my $obj = Genealogy::Wills->new(directory => $temp_dir);
	_inject($obj);

	my @list1 = $obj->search(last => 'Smith');
	my $sca1  = $obj->search(last => 'Smith');
	my @list2 = $obj->search(last => 'Smith');
	my $sca2  = $obj->search(last => 'Smith');

	is(scalar @list1, $MOCK_ROW_COUNT, 'first list call: correct row count');
	is(ref($sca1),    'HASH',          'first scalar call: returns hashref');
	is(scalar @list2, $MOCK_ROW_COUNT, 'second list call: correct row count');
	is(ref($sca2),    'HASH',          'second scalar call: returns hashref');

	like($list1[0]->{'url'}, qr{^https://}, 'list1 url decorated');
	like($sca1->{'url'},     qr{^https://}, 'scalar1 url decorated');
	like($list2[0]->{'url'}, qr{^https://}, 'list2 url decorated');
	like($sca2->{'url'},     qr{^https://}, 'scalar2 url decorated');

	restore_all();
};

# =======================================================================
# SECTION 10: Clone inherits pre-initialised wills slot
#
# new() on a blessed object (clone path) executes:
#   bless { %{$class}, %{$params // {}} }, ref($class)
# If the original already has a wills slot, the clone inherits it.
# A subsequent search() on the clone must NOT call wills::new() again
# because the ||= guard sees the inherited truthy value.
# =======================================================================

subtest 'clone inherits wills slot: wills::new() not called for cloned object' => sub {
	my $orig = Genealogy::Wills->new(directory => $temp_dir);
	_inject($orig);    # directly sets orig->{'wills'}; no search() needed

	my $clone = $orig->new();    # clone with no overrides

	ok(exists $clone->{'wills'}, 'clone has a wills key (inherited from original)');
	is($clone->{'wills'}, $orig->{'wills'},
		'clone shares the same wills reference as the original');

	# Install the wills::new mock BEFORE searching on the clone.
	# If the ||= guard fires erroneously, this counter will increment.
	my $new_call_count = 0;
	mock 'Genealogy::Wills::wills::new' => sub {
		$new_call_count++;
		return bless {}, 'Genealogy::Wills::wills';
	};

	my @clone_results = $clone->search(last => 'Smith');

	is($new_call_count, 0,
		'wills::new() not called on clone (||= short-circuits on inherited slot)');
	ok(scalar @clone_results > 0, 'clone search returns results');

	restore_all();
};

# =======================================================================
# SECTION 11: Optional fields forwarded verbatim to the DB layer
#
# PVS validates and allows apostrophes, periods, hyphens (first/middle)
# and commas (town).  Capture what actually arrives at selectall_hashref
# to confirm PVS does not strip or transform these characters.
# =======================================================================

subtest 'search() forwards first name with apostrophe verbatim to DB' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search(last => 'Brien', first => "O'Brien");

	is($captured{'first'}, "O'Brien", "apostrophe in first name forwarded verbatim");
	is($captured{'last'},  'Brien',   'last name forwarded verbatim alongside first');

	restore_all();
};

subtest 'search() forwards middle with period and hyphen verbatim to DB' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search(last => 'Smith', middle => 'St. John-Baptiste');

	is($captured{'middle'}, 'St. John-Baptiste',
		'period and hyphen in middle name forwarded verbatim');

	restore_all();
};

subtest 'search() forwards town with commas verbatim to DB' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search(last => 'Smith', town => 'Canterbury, Kent, England');

	is($captured{'town'}, 'Canterbury, Kent, England',
		'comma-separated town forwarded verbatim');

	restore_all();
};

# =======================================================================
# SECTION 12: Bare-string form maps string to { last => string }
#
# search('Smith') must produce { last => 'Smith' } via Params::Get.
# Verify what actually arrives at the DB layer, not just that it runs.
# =======================================================================

subtest 'search("Smith") bare-string: DB receives { last => "Smith" }' => sub {
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

	is($captured{'last'}, 'Smith',
		"bare-string 'Smith' arrives at DB layer as { last => 'Smith' }");
	ok(!exists $captured{'first'},  'no first key added by bare-string form');
	ok(!exists $captured{'middle'}, 'no middle key added by bare-string form');

	restore_all();
};

# =======================================================================
# SECTION 13: Clone with no args inherits all original attributes
#
# 10-new.t only confirms the clone ISA check.  This test verifies that
# the cloned hash contains the correct attribute values when the caller
# provides no overrides.
# =======================================================================

subtest 'new() clone with no args inherits all attributes from original' => sub {
	my $orig  = Genealogy::Wills->new(directory => $temp_dir, cache_duration => '6 hours');
	my $clone = $orig->new();    # no overrides

	isa_ok($clone, 'Genealogy::Wills', 'clone');
	isnt($clone, $orig, 'clone is a distinct reference');
	is($clone->{'directory'},      $orig->{'directory'},
		'clone inherits directory from original');
	is($clone->{'cache_duration'}, $orig->{'cache_duration'},
		'clone inherits cache_duration from original');

	diag "clone cache_duration=$clone->{'cache_duration'}" if $ENV{TEST_VERBOSE};
};

# =======================================================================
# SECTION 14: year field forwarded to DB
#
# 'year' is an optional integer field.  When supplied, the validated value
# must arrive at selectall_hashref unchanged.
# =======================================================================

subtest 'search() forwards year to DB as the validated integer' => sub {
	my $obj     = Genealogy::Wills->new(directory => $temp_dir);
	my $mock_db = bless {}, 'Genealogy::Wills::wills';

	my %captured;
	mock 'Genealogy::Wills::wills::selectall_hashref' => sub {
		my (undef, $params) = @_;
		%captured = %{$params};
		return [];
	};
	$obj->{'wills'} = $mock_db;

	my @r = $obj->search(last => 'Smith', year => 1750);

	is($captured{'year'}, 1750, 'year => 1750 forwarded verbatim to DB layer');

	restore_all();
};

done_testing();
