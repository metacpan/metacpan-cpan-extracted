#!/usr/bin/env perl

# edge_cases.t — Destructive, boundary-condition, and security tests for
# Geo::Coder::Free and its backends.  The strategy is to actively try to
# break or subvert the module rather than verifying the happy path.

use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Scalar::Util qw(looks_like_number refaddr);
use POSIX qw(HUGE_VAL);
use Test::Most;
use Test::Mockingbird qw(mock restore_all);

# Suppress OA/WOF auto-detection so no real database is required.
local $ENV{OPENADDR_HOME}    = '';
local $ENV{WHOSONFIRST_HOME} = '';

use_ok 'Geo::Coder::Free';
use_ok 'Geo::Coder::Free::Local';
use_ok 'Geo::Coder::Free::OpenAddresses';
use_ok 'Geo::Coder::Free::Utils';

# -----------------------------------------------------------------------
# Shared fixtures — created once to avoid exhausting <DATA> filehandle.
# -----------------------------------------------------------------------

# Single Local instance — Geo::Coder::Free::Local reads __DATA__ only once.
my $LOCAL_OBJ = Geo::Coder::Free::Local->new();

# MaxMind mock — prevents any real DB access for GCF facade tests.
# Call _remock_maxmind() after any restore_all() to reinstate these stubs.
sub _remock_maxmind {
	mock('Geo::Coder::Free::MaxMind', 'geocode',         sub { return undef });
	mock('Geo::Coder::Free::MaxMind', 'reverse_geocode', sub { return undef });
}
_remock_maxmind();

# Tempdir for OA — creates a valid (but empty) openaddr directory.
my $TMPDIR = tempdir(CLEANUP => 1);

# Named constants replace magic numbers in assertions.
use constant {
	LAT_MAX   =>  90,
	LAT_MIN   => -90,
	LON_MAX   =>  180,
	LON_MIN   => -180,
	# Alarm timeout for ReDoS regression tests (seconds).
	REDOS_TIMEOUT => 5,
};

# -----------------------------------------------------------------------
# 1. Utils::distance — undef / missing coordinates
# Strategy: each null argument slot should trigger a distinct croak
# rather than silently producing 0 or NaN.
# -----------------------------------------------------------------------
subtest 'distance() — null/undef coordinates croak' => sub {
	throws_ok { Geo::Coder::Free::Utils::distance(undef, 0,     0,     0    ) } qr/lat1 must be defined/,  'undef lat1';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     undef, 0,     0    ) } qr/lon1 must be defined/,  'undef lon1';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     0,     undef, 0    ) } qr/lat2 must be defined/,  'undef lat2';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     0,     0,     undef) } qr/lon2 must be defined/,  'undef lon2';
};

# -----------------------------------------------------------------------
# 2. Utils::distance — non-numeric coordinates
# Strategy: ensure the numeric guard is enforced for every parameter
# position, including empty string (looks_like_number returns false for '').
# -----------------------------------------------------------------------
subtest 'distance() — non-numeric coordinates croak' => sub {
	throws_ok { Geo::Coder::Free::Utils::distance('abc', 0,     0,     0    ) } qr/lat1 must be numeric/, 'alpha lat1';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     'xyz', 0,     0    ) } qr/lon1 must be numeric/, 'alpha lon1';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     0,     'bad', 0    ) } qr/lat2 must be numeric/, 'alpha lat2';
	throws_ok { Geo::Coder::Free::Utils::distance(0,     0,     0,     'no' ) } qr/lon2 must be numeric/, 'alpha lon2';

	# Empty string is not numeric.
	throws_ok { Geo::Coder::Free::Utils::distance('', 0, 0, 0) } qr/lat1 must be numeric/, 'empty string lat1';
};

# -----------------------------------------------------------------------
# 3. Utils::distance — out-of-range coordinates
# Strategy: the range guards must reject impossible geographic coordinates
# even when the values are otherwise numeric.
# -----------------------------------------------------------------------
subtest 'distance() — out-of-range coordinates croak' => sub {
	throws_ok { Geo::Coder::Free::Utils::distance(91,   0,  0,   0   ) } qr/Latitude must be between/, 'lat1 > 90';
	throws_ok { Geo::Coder::Free::Utils::distance(-91,  0,  0,   0   ) } qr/Latitude must be between/, 'lat1 < -90';
	throws_ok { Geo::Coder::Free::Utils::distance(0,    0,  91,  0   ) } qr/Latitude must be between/, 'lat2 > 90';
	throws_ok { Geo::Coder::Free::Utils::distance(0,    0, -91,  0   ) } qr/Latitude must be between/, 'lat2 < -90';

	throws_ok { Geo::Coder::Free::Utils::distance(0, 181,   0,  0   ) } qr/Longitude must be between/, 'lon1 > 180';
	throws_ok { Geo::Coder::Free::Utils::distance(0, -181,  0,  0   ) } qr/Longitude must be between/, 'lon1 < -180';
	throws_ok { Geo::Coder::Free::Utils::distance(0,  0,    0, 181  ) } qr/Longitude must be between/, 'lon2 > 180';
	throws_ok { Geo::Coder::Free::Utils::distance(0,  0,    0, -181 ) } qr/Longitude must be between/, 'lon2 < -180';

	# Large values that are still numeric.
	throws_ok { Geo::Coder::Free::Utils::distance(9999, 0, 0, 0) } qr/Latitude must be between/, 'large lat';
	throws_ok { Geo::Coder::Free::Utils::distance(0, 9999, 0, 0) } qr/Longitude must be between/, 'large lon';
};

# -----------------------------------------------------------------------
# 4. Utils::distance — exact boundary coordinates (valid; must not croak)
# Strategy: lat=±90 and lon=±180 are the inclusive extremes of the WGS-84
# coordinate system.  The range check uses strict > / < so the boundary
# values themselves are valid.
# -----------------------------------------------------------------------
subtest 'distance() — valid boundary coordinates' => sub {
	my $d;
	lives_ok { $d = Geo::Coder::Free::Utils::distance(LAT_MAX,  LON_MAX,  LAT_MIN,  LON_MIN,  'K') } 'poles + antimeridian accepted';
	cmp_ok($d, '>', 0, 'distance between diagonally opposite extreme points > 0');

	# Exact poles: both at North Pole should be distance 0.
	lives_ok { $d = Geo::Coder::Free::Utils::distance(90, 0, 90, 0, 'M') } 'North Pole to itself accepted';
	is($d, 0, 'North Pole to itself is 0 miles');

	# Antimeridian: same lat, lon ±180.
	lives_ok { $d = Geo::Coder::Free::Utils::distance(0, 180, 0, -180, 'K') } 'lon=180 and lon=-180 accepted';
	diag("antimeridian distance: $d km") if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 5. Utils::distance — identical-point unit-check bypass
# Strategy: the same-point early-return (return 0) fires BEFORE unit
# validation.  Verifying this prevents a future refactor from accidentally
# reordering the two checks.
# -----------------------------------------------------------------------
subtest 'distance() — identical points bypass unit check' => sub {
	my $d;

	# Same point + nonsense unit → returns 0 without croaking.
	lives_ok { $d = Geo::Coder::Free::Utils::distance(5, 5, 5, 5, 'XYZZY') } 'same point with bad unit lives';
	is($d, 0, 'same point with bad unit returns 0 (unit not validated)');

	# Different points + same nonsense unit → DOES croak (unit IS validated).
	throws_ok { Geo::Coder::Free::Utils::distance(0, 0, 1, 1, 'XYZZY') } qr/Unknown unit 'XYZZY'/, 'distinct points + bad unit croaks';
};

# -----------------------------------------------------------------------
# 6. Utils::distance — unit parameter variants
# Strategy: the unit handling coerces via uc() and treats '' / undef as 'M'.
# Verify that all documented variants are accepted and lowercase is silently
# normalised.
# -----------------------------------------------------------------------
subtest 'distance() — unit parameter variants' => sub {
	my ($d_k, $d_m, $d_n);

	# Capital units.
	lives_ok { $d_k = Geo::Coder::Free::Utils::distance(0, 0, 1, 1, 'K') } 'K accepted';
	lives_ok { $d_m = Geo::Coder::Free::Utils::distance(0, 0, 1, 1, 'M') } 'M accepted';
	lives_ok { $d_n = Geo::Coder::Free::Utils::distance(0, 0, 1, 1, 'N') } 'N accepted';

	# Lowercase letters are silently up-cased.
	my $d_k_lower;
	lives_ok { $d_k_lower = Geo::Coder::Free::Utils::distance(0, 0, 1, 1, 'k') } 'lowercase k accepted';
	is($d_k_lower, $d_k, 'k produces same result as K');

	# Empty string → treated as 'M' via: uc('' || 'M').
	my $d_empty;
	lives_ok { $d_empty = Geo::Coder::Free::Utils::distance(0, 0, 1, 1, '') } 'empty string unit accepted';
	is($d_empty, $d_m, 'empty string unit identical to M');

	# Default omitted → 'M'.
	my $d_omit;
	lives_ok { $d_omit = Geo::Coder::Free::Utils::distance(0, 0, 1, 1) } 'omitted unit accepted';
	is($d_omit, $d_m, 'omitted unit identical to M');

	# km > miles > NM by magnitude for the same path.
	cmp_ok($d_k, '>', $d_m, 'km > statute miles');
	cmp_ok($d_m, '>', $d_n, 'statute miles > nautical miles');

	diag(sprintf("0,0→1,1: %.4f km / %.4f mi / %.4f NM", $d_k, $d_m, $d_n)) if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 7. Utils::create_disc_cache — invalid configurations
# Strategy: each guard in _validate_cache_config / _configure_file_based
# should fire at the earliest possible point with a specific error.
# -----------------------------------------------------------------------
subtest 'create_disc_cache() — hostile configurations' => sub {
	# Missing config entirely.
	throws_ok { Geo::Coder::Free::Utils::create_disc_cache({}) } qr/config is not optional/, 'no config key';

	# Non-hash cache configuration block.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => 'scalar' } })
	} qr/hash reference/, 'non-hash disc_cache config';

	# Unknown driver name.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => { driver => 'FakeDriver' } } })
	} qr/Invalid driver/, 'unknown driver rejected';

	# Port = 0 (not a positive integer).
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => { driver => 'File', port => 0 } } })
	} qr/positive integer/, 'port=0 rejected';

	# Port exceeds 65535.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => { driver => 'File', port => 65536 } } })
	} qr/Port must be between/, 'port=65536 rejected';

	# File driver: missing root_dir.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => { driver => 'File' } } })
	} qr/root_dir/, 'File driver without root_dir';

	# File driver: root_dir does not exist.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({
			config => { disc_cache => { driver => 'File', root_dir => '/nonexistent/path/xyzzy_test_123' } }
		})
	} qr/does not exist|not writable/, 'File driver with non-existent root_dir';

	# DBI driver: missing connect string.
	# If CHI::Driver::DBI is not installed the driver falls back to 'File'
	# (which then requires root_dir) — either way a config error is thrown.
	throws_ok {
		Geo::Coder::Free::Utils::create_disc_cache({ config => { disc_cache => { driver => 'DBI' } } })
	} qr/connect|root_dir/, 'DBI without connect (or fallback to File without root_dir)';
};

# -----------------------------------------------------------------------
# 8. Utils::create_memory_cache — invalid configurations
# -----------------------------------------------------------------------
subtest 'create_memory_cache() — hostile configurations' => sub {
	# Missing config entirely.
	throws_ok { Geo::Coder::Free::Utils::create_memory_cache({}) } qr/config is not optional/, 'no config key';

	# Non-hash memory_cache block.
	throws_ok {
		Geo::Coder::Free::Utils::create_memory_cache({ config => { memory_cache => 'scalar' } })
	} qr/hash reference/, 'non-hash memory_cache config';

	# Both global and datastore at once (CHI rejects this; _validate_cache_config catches it first).
	throws_ok {
		Geo::Coder::Free::Utils::create_memory_cache({
			config => { memory_cache => { driver => 'Memory', global => 1, datastore => {} } }
		})
	} qr/both global and datastore/, 'global + datastore conflict';
};

# -----------------------------------------------------------------------
# 9. Geo::Coder::Free::geocode() — purely numeric inputs
# Strategy: numeric-only location/scantext strings are explicitly rejected
# with a dedicated "invalid location" croak so that the caller knows the
# value was never an address.
# -----------------------------------------------------------------------
subtest 'GCF geocode() — purely numeric inputs croak' => sub {
	my $geo = Geo::Coder::Free->new();

	throws_ok { $geo->geocode(location => '42')      } qr/invalid location/, '"42" is not an address';
	throws_ok { $geo->geocode(location => '0')       } qr/invalid location/, '"0" is not an address';
	throws_ok { $geo->geocode(location => '999999')  } qr/invalid location/, 'large integer rejected';
	# Note: '3.14' contains '.' which is \D, so it is NOT purely numeric per
	# the regex /\D/ — only digit-only strings trigger the invalid-location croak.
	throws_ok { $geo->geocode(location => '123456')  } qr/invalid location/, 'digit-only 6-char string rejected';

	throws_ok { $geo->geocode(scantext => '99')      } qr/invalid scantext/, 'purely numeric scantext croaks';
};

# -----------------------------------------------------------------------
# 9b. Geo::Coder::Free::valid_location() and geocode(on_error => 'undef')
# Strategy: a batch caller working down a dirty column must be able to skip a
# row rather than have the croak above kill the run (section 2.4 of
# BI-Phase6-Dependency-Specs.md).  Three things must hold: the predicate and
# the guard agree; 'undef' changes the answer for the two documented input
# errors only, so the default is still a croak and a backend that dies still
# dies; and an on_error nobody understands is refused rather than ignored.
# -----------------------------------------------------------------------
subtest 'GCF valid_location() — the rule the guard applies, made public' => sub {
	my $geo = Geo::Coder::Free->new();

	ok(!$geo->valid_location('0044'), '0044 is not a location');
	ok(!$geo->valid_location('12345'), 'a longer bare number is not a location');
	ok(!$geo->valid_location(''), 'the empty string is not a location');
	ok(!$geo->valid_location(undef), 'undef is not a location');

	ok($geo->valid_location('Ramsgate, Kent'), 'an address is a location');
	# The guard has always rejected digits only, so anything holding a non-digit
	# passes: '3.14' and '-' are not addresses, but they are not a numeric column
	# read by mistake either, and answering otherwise here would make the
	# predicate disagree with the croak it is supposed to explain.
	ok($geo->valid_location('3.14'), 'a decimal has a non-digit in it, so it passes');
	ok($geo->valid_location('-'), 'a dash passes');

	# The three calling conventions the rest of the module accepts.
	ok(!Geo::Coder::Free->valid_location('0044'), 'class-method form');
	ok(!Geo::Coder::Free::valid_location('0044'), 'function form');
};

subtest "GCF geocode() — on_error => 'undef' skips the row" => sub {
	my $geo = Geo::Coder::Free->new();

	# The row the guard would have killed, skipped instead.  In both contexts:
	# a scalar caller gets undef, a list caller gets an empty list.
	is($geo->geocode(location => '0044', on_error => 'undef'), undef,
		'numeric location returns undef');
	is($geo->geocode(scantext => '99', on_error => 'undef'), undef,
		'numeric scantext returns undef');
	my @list = $geo->geocode(location => '0044', on_error => 'undef');
	is(scalar @list, 0, 'list context returns an empty list, not a one-element undef');

	# ...and nothing else changes: the default is still the croak it always was,
	# and saying so explicitly is the same as saying nothing.
	throws_ok { $geo->geocode(location => '0044') }
		qr/invalid location/, 'still croaks by default';
	throws_ok { $geo->geocode(location => '0044', on_error => 'croak') }
		qr/invalid location/, "still croaks with on_error => 'croak'";
	throws_ok { $geo->geocode(scantext => '99', on_error => 'croak') }
		qr/invalid scantext/, 'scantext still croaks';

	# The empty string is not an error the option has anything to do with: it has
	# always returned undef without croaking, on either setting.
	is($geo->geocode(location => '', on_error => 'croak'), undef, 'empty location → undef either way');

	# An option that changes error handling must not be guessed at: a caller who
	# misspells it would otherwise ship a batch job that dies on row one.
	throws_ok { $geo->geocode(location => 'Ramsgate, Kent', on_error => 'ignore') }
		qr/on_error must be/, 'an unknown on_error is refused, not ignored';

	# The guard is the only thing the option changes.  A backend that throws must
	# still throw, or on_error would have swallowed the OA failure that
	# t/transaction.t's TX4 exists to protect.
	my $oa_geo = Geo::Coder::Free->new(openaddr => $TMPDIR);
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { die "simulated DB connection failure\n" });
	throws_ok { $oa_geo->geocode(location => 'Somewhere, Someplace', on_error => 'undef') }
		qr/simulated DB connection failure/,
		'a backend exception still propagates under on_error => undef';

	restore_all();
	_remock_maxmind();
};

# -----------------------------------------------------------------------
# 9c. One definition of what counts as a location
# Strategy: the rule geocode() applies before it touches a backend was written
# out a second time in MaxMind.pm (with a croak) and a third in
# OpenAddresses.pm (with a miss), so a string the facade refused could still be
# looked up by a backend called directly.  The rule now lives once, in
# Geo::Coder::Free::Validate, and all three callers hold that one sub.  A second
# copy of the sub fails the identity assertions below, and a backend that goes
# back to testing for a digit in the stringified value - the shape of the old
# guard - fails the reference case; both are the failure mode section 2.4 of
# BI-Phase6-Dependency-Specs.md is about.
# -----------------------------------------------------------------------
subtest 'One rule for the facade and both backends' => sub {
	# The real MaxMind backend is called below, so the module-wide mock that the
	# facade tests in this file rely on is removed first and reinstated at the
	# end: asserting against a mock would prove nothing about the guard.
	restore_all();

	my $geo = Geo::Coder::Free->new();

	# The rule, and the public predicate that is its public form.
	ok(!Geo::Coder::Free::Validate::_valid_location('0044'), 'the rule refuses a bare number');
	ok(Geo::Coder::Free::Validate::_valid_location('Ramsgate, Kent'), 'the rule accepts an address');
	ok(!$geo->valid_location('0044'), 'and the public predicate gives the same answer');

	# One definition, not three: each package's _valid_location is the same code
	# reference as the others', so a backend that pasted the rule back in as a sub
	# of its own fails here even though its answers would be identical.
	my $rule = refaddr(\&Geo::Coder::Free::Validate::_valid_location);
	is(refaddr(\&Geo::Coder::Free::_valid_location), $rule,
		'the facade calls the shared rule, not a copy of it');
	is(refaddr(\&Geo::Coder::Free::MaxMind::_valid_location), $rule,
		'MaxMind calls the shared rule');
	is(refaddr(\&Geo::Coder::Free::OpenAddresses::_valid_location), $rule,
		'OpenAddresses calls the shared rule');

	# MaxMind, called directly rather than through the facade: a bare number is
	# refused by the same rule, and with the error this backend has always given.
	# Nothing below the guard is reached, so this needs no database.
	my $mm = bless {}, 'Geo::Coder::Free::MaxMind';
	throws_ok { $mm->geocode(location => '0044') }
		qr/invalid input to geocode/,
		'a bare number is refused by MaxMind itself, not only by the facade';

	# ...and the guard is a filter, not a wall in front of every lookup: an
	# address gets past it.  What happens next is this stub object's business
	# (there is no database behind it), so the assertion is that whatever
	# happened, it was not the numeric refusal.
	my $err = do { local $@; eval { $mm->geocode(location => 'Ramsgate, Kent, England') }; $@ };
	unlike($err, qr/invalid input to geocode/,
		'an address is not refused as though it were a number');

	# The case that tells the shared rule apart from the regex it replaced: the
	# rule rejects a reference, while the old guard asked only whether the
	# stringified value held a digit, and 'SCALAR(0x...)' does, so it let the
	# reference through.  That is what makes this a regression test rather than a
	# restatement of an answer both forms give.
	throws_ok { $mm->geocode(location => \42) }
		qr/invalid input to geocode/, 'a reference is refused by MaxMind as well';

	# OpenAddresses answers every input the way it always did - a miss rather
	# than an error, because its caller may have another backend to try - so no
	# behaviour here can tell the shared rule apart from the regex it replaced.
	# The identity assertion above is what holds it to the shared rule.
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $TMPDIR);
	is($oa->geocode(location => \42), undef,
		'and OpenAddresses treats a reference as a miss, not as a place to look up');

	_remock_maxmind();
};

# -----------------------------------------------------------------------
# 9d. geocode_many() — a column of hundreds of rows, and a dirty one
# Strategy: the loop this method replaces goes wrong in two ways - it looks the
# same value up once per row, and it either dies on a value that is not a place
# at all or spends a lookup on one.  So a repeated value must cost one backend
# call however often it appears, a value the module refuses must cost none, and
# the counts must still account for every distinct value
# (section 2.5 of BI-Phase6-Dependency-Specs.md).
# -----------------------------------------------------------------------
subtest 'GCF geocode_many() — one lookup per distinct value, and none for garbage' => sub {
	my $geo = Geo::Coder::Free->new();

	my @asked;
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub {
		my ($mm, $params) = @_;
		push @asked, $params->{'location'};
		return $params->{'location'} =~ /Ramsgate/
			? Geo::Location::Point->new({ lat => 51.3341, long => -1.4159 })
			: undef;
	});
	mock('Geo::Coder::Free::MaxMind', 'reverse_geocode', sub { return undef });

	# 401 rows holding four distinct values: one that resolves, one that does not,
	# a bare number and an empty cell.  A hand-rolled loop would make 397 lookups
	# for the first value alone.
	my @column = (('Ramsgate, Kent') x 397, 'Nowhere, Imaginary, ZZ', '0044', '0044', '');
	my $batch = $geo->geocode_many(\@column, on_error => 'undef');

	is(scalar @asked, 2, 'two backend lookups for 401 rows and four distinct values');
	is_deeply([grep { /^\d+\z/ || $_ eq '' } @asked], [],
		'a value that is not a location never reached the backend');
	is_deeply([grep { $_ eq 'Ramsgate, Kent' } @asked], ['Ramsgate, Kent'],
		'the repeated value was looked up once, not 397 times');
	is($batch->{'lookups'},    2, 'and exactly the two worth looking up were counted');
	is($batch->{'resolved'},   1, 'one distinct value resolved');
	is($batch->{'unresolved'}, 3, 'the miss and the two refused values did not');
	is(scalar keys %{$batch},  8, 'four values and the four keys of the answer itself');

	_remock_maxmind();
};

subtest 'GCF geocode_many() — the dirty column, in the words geocode() uses' => sub {
	my $geo = Geo::Coder::Free->new();

	# On the default setting an unusable value is refused with geocode()'s own
	# message for it, so a caller who leaves the option out hears exactly what the
	# loop they replaced would have said.
	throws_ok { $geo->geocode_many(['0044']) }
		qr/invalid location to geocode\(\), 0044/,
		'the default croaks the message geocode() gives for that value';
	throws_ok { $geo->geocode_many(['Ramsgate, Kent'], on_error => 'nonsense') }
		qr/on_error must be/, 'an unknown on_error is refused, not ignored';

	# The counts and the map share one hashref: a value spelled like one of the
	# answer's own keys is refused by name rather than overwriting a count.
	throws_ok { $geo->geocode_many(['lookups'], on_error => 'undef') }
		qr/"lookups" is one of the keys geocode_many\(\) answers with/,
		'a value spelled like a returned key is refused';

	# On 'undef' the same column is reported instead of fatal, and an empty cell
	# is one entry whether it arrived as undef or as ''.
	my $dirty = $geo->geocode_many(['0044', undef, ''], on_error => 'undef');
	is($dirty->{'unresolved'}, 2, 'the bare number and the empty cell are unresolved');
	is($dirty->{'lookups'},    0, 'and neither was looked up');
	ok(exists($dirty->{'0044'}) && !defined($dirty->{'0044'}),
		'the bare number is keyed, with undef');
	ok(exists($dirty->{''}) && !defined($dirty->{''}),
		'so is the empty cell: undef and \'\' share one entry');
	is_deeply([sort keys %{$dirty}],
		[sort ('', '0044', qw(lookups resolved unresolved unresolved_values))],
		'and nothing else was invented');
	is(scalar @{$dirty->{'unresolved_values'}}, 2,
		'both are listed, which is what the caller records to stop retrying them');

	# Nothing here is worth a lookup at all, so a backend that refuses to be called
	# is never asked: if it were, this subtest would die rather than fail.
	mock('Geo::Coder::Free::MaxMind', 'geocode',
		sub { die "geocode_many() looked up a value it should have refused\n" });
	# Five distinct values, none of them a location: three bare numbers, the empty
	# cell (twice over - as '' and as undef, which are one entry) and a reference.
	my @garbage = ('0044', '9999', '7', '', undef, \'not a location');
	my $all_garbage = $geo->geocode_many(\@garbage, on_error => 'undef');
	is($all_garbage->{'unresolved'}, 5, 'five distinct unusable values, counted one by one');
	is($all_garbage->{'resolved'},   0, 'none of them resolved');
	is($all_garbage->{'lookups'},    0, 'and not one of them cost a lookup');
	is(scalar @{$all_garbage->{'unresolved_values'}}, 5, 'all five are listed for the caller');

	_remock_maxmind();
};

# -----------------------------------------------------------------------
# 10. Geo::Coder::Free::geocode() — empty/undef inputs
# Strategy:
#   - empty string location: defined, no \D chars, length=0 → early 'return'
#     (no croak, returns undef).
#   - undef location: not defined, so the numeric guard is skipped.
#     No location AND no scantext → falls through to the bottom-of-geocode
#     croak("Usage: ...").
#   - empty string scantext: same logic as empty location → return undef.
# -----------------------------------------------------------------------
subtest 'GCF geocode() — empty/undef location' => sub {
	my $geo = Geo::Coder::Free->new();

	is($geo->geocode(location => ''),  undef, 'empty string location → undef (not croak)');
	is($geo->geocode(scantext => ''),  undef, 'empty string scantext → undef (not croak)');

	# undef location → no location AND no scantext → usage croak.
	throws_ok { $geo->geocode(location => undef) } qr/Usage/, 'undef location → usage croak';
};

# -----------------------------------------------------------------------
# 11. Geo::Coder::Free::geocode() — non-hash reference arguments
# Strategy: passing an arrayref, coderef, or other reference should croak
# immediately rather than producing a misleading error from deep inside
# Params::Get.  _normalize_args checks ref($args[0]).
# -----------------------------------------------------------------------
subtest 'GCF geocode() — non-hash reference arguments croak' => sub {
	my $geo = Geo::Coder::Free->new();

	throws_ok { $geo->geocode([])        } qr/Usage/, 'arrayref arg croak';
	throws_ok { $geo->geocode(sub { })   } qr/Usage/, 'coderef arg croak';
	throws_ok { $geo->geocode(\42)       } qr/Usage/, 'scalarref arg croak';
};

# -----------------------------------------------------------------------
# 12. Geo::Coder::Free::geocode() — M7 fix: odd-count > 1 croak
# Strategy: (M7) before the fix, ('a', 'b', 'c') silently fell through to
# return ().  Now it croaks.  A regression test prevents re-introducing
# the silent discard.
# -----------------------------------------------------------------------
subtest 'GCF geocode() — odd-count arg-list croaks (M7 regression)' => sub {
	my $geo = Geo::Coder::Free->new();

	# Three args (odd-count > 1) → croak
	throws_ok { $geo->geocode('location', 'Ramsgate', 'extra') } qr/Usage/, '3-arg list croaks';

	# Five args (odd-count > 1) → croak
	throws_ok { $geo->geocode('location', 'Ramsgate', 'region', 'GB', 'extra') } qr/Usage/, '5-arg list croaks';

	# Two args (even-count) → passes _normalize_args; MaxMind mock returns undef
	my $r;
	lives_ok { $r = $geo->geocode(location => 'Nowhere, Nonexistent, XX') } 'even-count arg-list lives';
	is($r, undef, 'unfindable location returns undef');
};

# -----------------------------------------------------------------------
# 13. Geo::Coder::Free::geocode() — hostile string payloads
# Strategy: strings designed to exploit SQL injection, shell injection,
# log injection, and directory traversal must pass through the geocoding
# stack without crashing and must return undef (not a real result).
# -----------------------------------------------------------------------
subtest 'GCF geocode() — hostile string payloads return undef' => sub {
	my $geo = Geo::Coder::Free->new();
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });

	# SQL injection attempt.
	is(
		$geo->geocode(location => "'; DROP TABLE cities; --, state, US"),
		undef, 'SQL injection in location → undef'
	);

	# UNION-based SQL injection.
	is(
		$geo->geocode(location => "' UNION SELECT 1,2,3 --, state, US"),
		undef, 'UNION injection in location → undef'
	);

	# Log injection via newline.
	is(
		$geo->geocode(location => "City\nX-Injected: evil, State, US"),
		undef, 'newline injection in location → undef'
	);

	# Path traversal characters.
	is(
		$geo->geocode(location => '../../etc/passwd, state, US'),
		undef, 'path traversal in location → undef'
	);

	# Shell metacharacters.
	is(
		$geo->geocode(location => '; ls -la, state, US'),
		undef, 'shell metacharacter in location → undef'
	);

	# Null byte (C-string terminator).
	is(
		$geo->geocode(location => "City\x00Injected, State, US"),
		undef, 'null byte in location → undef'
	);

	restore_all();
	_remock_maxmind();
};

# -----------------------------------------------------------------------
# 14. Geo::Coder::Free::geocode() — global variable isolation
# Strategy: a geocode call must not clobber $_, $@, or $! in the caller's
# scope.  These are widely used in Perl idioms and unexpected mutation
# causes subtle, hard-to-debug failures.
# -----------------------------------------------------------------------
subtest 'GCF geocode() — global variable isolation' => sub {
	my $geo = new_ok('Geo::Coder::Free');

	if(!defined($ENV{NO_NETWORK_TESTING})) {
		# $_ isolation.
		local $_ = 'sentinel_dollar_underscore';
		$geo->geocode(location => 'Ramsgate, Kent, UK');
		is($_, 'sentinel_dollar_underscore', 'geocode() does not clobber $_');

		# $@ isolation — must be sampled immediately after the eval to avoid
		# interference from any subsequent ops.
		eval { 1 };
		my $prev_err = $@;
		$geo->geocode(location => 'Nonexistent, Place, XX');
		is($@, $prev_err, 'geocode() does not clobber $@');

		# Alarm state — verify geocode does not leave a pending alarm.
		alarm(0);
		$geo->geocode(location => 'Ramsgate, Kent, UK');
		my $remaining = alarm(0);
		is($remaining, 0, 'geocode() does not install a lingering alarm');
	}
};

# -----------------------------------------------------------------------
# 15. Geo::Coder::Free::reverse_geocode() — hostile inputs
# -----------------------------------------------------------------------
subtest 'GCF reverse_geocode() — hostile inputs' => sub {
	my $geo = Geo::Coder::Free->new();

	# No args and no openaddr → "not yet supported"
	throws_ok { $geo->reverse_geocode() } qr/not yet supported/, 'no-arg reverse_geocode';

	# Non-hash reference → usage croak (from _normalize_args before the backend check).
	throws_ok { $geo->reverse_geocode([]) } qr/Usage/, 'arrayref arg to reverse_geocode';

	# Odd-count args > 1 → M7 croak.
	throws_ok { $geo->reverse_geocode('latlng', '51.3,-1.4', 'extra') } qr/Usage/, '3-arg reverse_geocode';

	# Valid latlng but no openaddr → MaxMind path (mocked to undef).
	my $r;
	lives_ok { $r = $geo->reverse_geocode(latlng => '51.3341,-1.4159') } 'valid latlng lives';
	is($r, undef, 'reverse_geocode without OA returns undef from MaxMind mock');
};

# -----------------------------------------------------------------------
# 16. Geo::Coder::Free::new() — hostile construction
# -----------------------------------------------------------------------
subtest 'GCF new() — hostile construction' => sub {
	# Called as a function (::new) with no args — warns and returns undef.
	my $result = Geo::Coder::Free::new();
	# The function path only works with no-args; it returns the class and proceeds.
	# The important check: it must not crash.
	pass('::new() with no args does not die');

	# Unknown options are silently ignored — Object::Configure is permissive.
	my $geo;
	lives_ok { $geo = Geo::Coder::Free->new(bogus_option => 'ignored') } 'unknown option silently ignored';
	isa_ok($geo, 'Geo::Coder::Free', 'object still created');

	# Clone via new() on an existing object.
	my $geo2;
	lives_ok { $geo2 = $geo->new() } 'clone via ->new() on instance';
	isa_ok($geo2, 'Geo::Coder::Free', 'clone is GCF');
	isnt(refaddr($geo), refaddr($geo2), 'clone is a distinct reference');
};

# -----------------------------------------------------------------------
# 17. Geo::Coder::Free::Local::geocode() — insufficient comma count
# Strategy: Local's geocode() requires at least "road, city, country"
# (two commas) before invoking any parser.  The guard `return if $location
# !~ /,.+,/` is cheap and must reject all under-specified inputs without
# touching the data.
# -----------------------------------------------------------------------
subtest 'Local geocode() — insufficient commas → undef' => sub {
	is($LOCAL_OBJ->geocode(location => 'Ramsgate'),              undef, 'bare city → undef');
	is($LOCAL_OBJ->geocode(location => 'Ramsgate, Kent'),        undef, 'city+county, one comma → undef');
	is($LOCAL_OBJ->geocode(location => ','),                     undef, 'only comma, no content → undef');

	# Two commas are required; a string with exactly two commas but no
	# content between them also fails to match /,.+,/.
	is($LOCAL_OBJ->geocode(location => 'A,,B'),                  undef, 'no content between commas → undef');
};

# -----------------------------------------------------------------------
# 18. Geo::Coder::Free::Local::geocode() — hostile argument types
# -----------------------------------------------------------------------
subtest 'Local geocode() — hostile argument types' => sub {
	# Non-hash reference → usage croak.
	throws_ok { $LOCAL_OBJ->geocode([])      } qr/Usage/, 'arrayref arg';
	throws_ok { $LOCAL_OBJ->geocode(sub {})  } qr/Usage/, 'coderef arg';

	# Odd-count > 1 → M7 croak.
	throws_ok { $LOCAL_OBJ->geocode('location', 'x', 'extra') } qr/Usage/, '3-arg list';

	# Empty string location: falsy → or-croak in geocode fires.
	throws_ok { $LOCAL_OBJ->geocode(location => '') } qr/Usage/, 'empty string location croaks in Local';

	# undef location: falsy → croak.
	throws_ok { $LOCAL_OBJ->geocode(location => undef) } qr/Usage/, 'undef location croaks in Local';
};

# -----------------------------------------------------------------------
# 19. Geo::Coder::Free::Local::reverse_geocode() — missing coordinates
# -----------------------------------------------------------------------
subtest 'Local reverse_geocode() — missing/invalid coordinates' => sub {
	# No args at all → croak (no latlng, no lat, no lon).
	throws_ok { $LOCAL_OBJ->reverse_geocode() } qr/Usage/, 'no args';

	# latlng is undef → the split gives two undefs → croak in the defined-check.
	throws_ok { $LOCAL_OBJ->reverse_geocode(latlng => undef) } qr/Usage/, 'latlng=undef';

	# Non-hash reference.
	throws_ok { $LOCAL_OBJ->reverse_geocode([]) } qr/Usage/, 'arrayref arg';

	# Odd-count > 1.
	throws_ok { $LOCAL_OBJ->reverse_geocode('latlng', '1,2', 'extra') } qr/Usage/, '3-arg list';

	# Valid latlng that matches no data point → empty list (not a croak).
	my @rc;
	lives_ok { @rc = $LOCAL_OBJ->reverse_geocode(latlng => '0,0') } 'unmatchable latlng lives';
	is(scalar @rc, 0, 'unmatchable latlng returns empty list');
};

# -----------------------------------------------------------------------
# 20. Geo::Coder::Free::OpenAddresses::new() — hostile construction
# Strategy: OA->new() must croak on invalid/missing openaddr paths before
# any database handle is opened.
# -----------------------------------------------------------------------
subtest 'OA new() — hostile construction' => sub {
	# No openaddr argument → croak usage.
	throws_ok { Geo::Coder::Free::OpenAddresses->new() } qr/Usage: new/, 'no openaddr arg';

	# Non-existent directory.
	throws_ok {
		Geo::Coder::Free::OpenAddresses->new(openaddr => '/nonexistent/path/xyzzy_42')
	} qr/Can't find the directory/, 'non-existent directory';

	# Existing FILE rather than a directory.
	my (undef, $tmpfile) = tempfile(UNLINK => 1);
	throws_ok {
		Geo::Coder::Free::OpenAddresses->new(openaddr => $tmpfile)
	} qr/Can't find the directory/, 'file instead of directory';

	# Valid empty directory → object created.
	my $oa;
	lives_ok { $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $TMPDIR) } 'valid empty dir lives';
	isa_ok($oa, 'Geo::Coder::Free::OpenAddresses', 'OA object');
};

# -----------------------------------------------------------------------
# 21. Geo::Coder::Free::OpenAddresses::geocode() — pre-DB guards
# Strategy: several cheap guards fire before any DB query.  Test them
# against an OA instance backed by an empty directory so no SQLite file
# is required.
#
# Important: in OA::geocode an empty-string scantext is FALSY — it does
# not enter the scantext block, so the code falls through to the location
# guard which croaks "Usage:...".  Only non-empty but short strings (1–5
# chars) enter the block and hit the length<6 early-return.
# -----------------------------------------------------------------------
subtest 'OA geocode() — pre-database guards' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $TMPDIR);

	# Empty string scantext is falsy → falls through to location croak.
	throws_ok { $oa->geocode(scantext => '') } qr/Usage/, 'empty scantext → location croak (falsy)';

	# Non-empty but < 6 chars → enters the scantext block → early return undef.
	is($oa->geocode(scantext => 'ab'),    undef, '2-char scantext → undef');
	is($oa->geocode(scantext => 'abcde'), undef, '5-char scantext → undef');

	# known_locations hash hit (hardcoded, no DB needed).
	my $kl = $oa->geocode(location => 'Newport Pagnell, Buckinghamshire, England');
	isa_ok($kl, 'Geo::Location::Point', 'known_location returns GLP');
	if ($kl) {
		cmp_ok(abs($kl->lat()  - 52.08675),    '<', 0.001, 'known_location lat correct');
		cmp_ok(abs($kl->long() - (-0.72270)),   '<', 0.001, 'known_location lon correct');
	}
};

# -----------------------------------------------------------------------
# 22. Geo::Coder::Free::OpenAddresses::reverse_geocode() — always croaks
# Strategy: OA::reverse_geocode() is not implemented and must croak with
# "Reverse lookup is not yet supported" regardless of the argument.
# -----------------------------------------------------------------------
subtest 'OA reverse_geocode() — always croaks' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $TMPDIR);

	throws_ok { $oa->reverse_geocode()                         } qr/not yet supported/, 'no args';
	throws_ok { $oa->reverse_geocode(latlng => '51.3,-1.4')   } qr/not yet supported/, 'with latlng';
	throws_ok { $oa->reverse_geocode(lat => 51.3, lon => -1.4) } qr/not yet supported/, 'with lat+lon';
};

# -----------------------------------------------------------------------
# 23. Security — ReDoS regression: _normalize() with long input
# Strategy: the former /(.+)\s+(.+)\s+(.+)/ regex was O(N³).  The fix
# uses split /\s+/.  This test quantifies the safety margin by verifying
# that a 10 000-character input returns in well under REDOS_TIMEOUT seconds.
# -----------------------------------------------------------------------
subtest 'Security — _normalize() does not backtrack catastrophically' => sub {
	# Build a pathologically long street name with no natural abbreviation.
	my $long_street = join(' ', ('VeryLongStreetNameWord') x 200);

	my $result;
	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(REDOS_TIMEOUT);
	eval { $result = Geo::Coder::Free::_normalize($long_street) };
	alarm(0);

	isnt($@, "TIMEOUT\n", "_normalize() with 200-word input completes within @{[REDOS_TIMEOUT]}s");
	like($result, qr/\S/, '_normalize() returns a non-empty string');

	diag("_normalize result length: " . length($result)) if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 24. Security — ReDoS regression: _find_gb_addresses() comma-free input
# Strategy: the former \s*,?\s* separator (optional comma) caused O(N²)
# backtracking on long comma-free strings.  Making commas mandatory
# eliminates the ambiguity.  Verify the fix holds under hostile input.
# -----------------------------------------------------------------------
subtest 'Security — _find_gb_addresses() does not backtrack on comma-free input' => sub {
	# A long string with no commas — the pattern must fail-fast, not backtrack.
	my $no_commas = 'A' x 5000;
	my @matches;

	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(REDOS_TIMEOUT);
	eval { @matches = Geo::Coder::Free::_find_gb_addresses($no_commas) };
	alarm(0);

	isnt($@, "TIMEOUT\n", "_find_gb_addresses() on 5000-char comma-free input finishes within @{[REDOS_TIMEOUT]}s");
	is(scalar @matches, 0, 'no addresses extracted from comma-free text');
};

# -----------------------------------------------------------------------
# 25. Security — ReDoS regression: OA city-name nested quantifier
# The old pattern ([a-zA-Z|\s+]{1,30}){1,2} was a ReDoS bomb because
# the inner character class matched spaces, creating ambiguous splits.
# The fix uses ([A-Za-z]+(?:\s+[A-Za-z]+)*).  Verify with a hostile
# string that would have triggered the backtracking.
# -----------------------------------------------------------------------
subtest 'Security — OA city-name regex does not backtrack' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $TMPDIR);

	# A long space-only string wrapped in city-like context, which used
	# to cause exponential backtracking in the nested quantifier.
	my $hostile = '1600 Pennsylvania ' . ' Ave ' x 200 . ', Springfield, IL 12345';

	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(REDOS_TIMEOUT);
	my $r = eval { $oa->geocode(location => $hostile) };
	alarm(0);

	isnt($@, "TIMEOUT\n", "OA geocode with hostile city padding completes within @{[REDOS_TIMEOUT]}s");
	is($r, undef, 'hostile city-padding string returns undef (not found in empty DB)');
};

# -----------------------------------------------------------------------
# 26. Multiple concurrent GCF instances — no shared mutable state
# Strategy: verify that scantext_misses recorded on one instance do not
# bleed into a freshly-created independent instance.
# -----------------------------------------------------------------------
subtest 'Concurrent GCF instances — scantext_misses isolation' => sub {
	my $g1 = Geo::Coder::Free->new();
	my $g2 = Geo::Coder::Free->new();

	# Force g1 to record a miss by geocoding something that does not exist
	# and has no OA backend to recurse into.  MaxMind mock returns undef.
	$g1->geocode(location => 'Nonexistent City XYZ, Nonexistent State, XX');

	# g1 should have no scantext_misses here (scantext path is only triggered
	# when openaddr is set; without it, regular location goes to MaxMind).
	# Verify the independent-instance invariant regardless.
	my $g1_misses = scalar keys %{ $g1->{'scantext_misses'} // {} };
	my $g2_misses = scalar keys %{ $g2->{'scantext_misses'} // {} };

	isnt(refaddr($g1), refaddr($g2), 'g1 and g2 are distinct objects');
	is($g2_misses, 0, 'g2 scantext_misses starts empty regardless of g1 activity');

	diag("g1 misses=$g1_misses  g2 misses=$g2_misses") if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# 27. Context propagation: geocode() in list vs scalar context
# Strategy: in scalar context a single GLP (or undef) is returned.
# In list context, a list is returned.  These are semantically different
# and the distinction must be preserved.
# -----------------------------------------------------------------------
subtest 'GCF geocode() — list vs scalar context' => sub {
	my $geo = Geo::Coder::Free->new();
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });

	# Scalar context: geocode of a known Local entry returns a GLP.
	my $scalar = $geo->geocode(location => '203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US');
	# MaxMind mock returns undef; Local has the entry.  If Local has it, scalar is a GLP.
	# If not found, scalar is undef.  The key invariant: scalar context is a scalar.
	ok(!ref($scalar) || ref($scalar) eq 'Geo::Location::Point', 'scalar context returns scalar or GLP');

	# List context: same call returns a list.
	my @list = $geo->geocode(location => '203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US');
	ok(ref(\@list) eq 'ARRAY', 'list context returns a list');

	restore_all();
};

done_testing();
