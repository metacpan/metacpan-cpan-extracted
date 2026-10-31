#!/usr/bin/env perl

# Domain tests: Equivalence Partitioning and Boundary Value Analysis of every
# parameter of the public API, one subtest per parameter.  The partitions and
# limits asserted here are the ones documented under =head3 API SPECIFICATION
# in each module.
#
# No database is needed.  The backends are stand-ins put into the facade's slots,
# and the real OpenAddresses and MaxMind code reads stand-in tables, so what a
# value turns into on its way to the data can be seen as well as whether it
# survived the trip.  The one subtest that reads real data skips without it.
#
# A TODO block marks a partition the code gets wrong today.  Each states the
# behaviour the documentation promises, so it reports "unexpectedly succeeded"
# as soon as the bug is fixed.  The roadmap in Free.pm lists the same bugs.

use strict;
use warnings;

use Encode ();
use File::Spec;
use File::Temp qw(tempdir);
use Readonly;
use Scalar::Util qw(blessed);
use Storable ();
use Test::Most;
use Test::Mockingbird qw(mock restore_all);

# Either parser changes which rows a string reaches and neither is in CI, and
# libpostal's model takes minutes to load; see the same line in t/unit.t.
use Test::Without::Module qw(Geo::libpostal Geo::Address::Parser);

use lib 'lib';

use Geo::Coder::Free;
use Geo::Coder::Free::Local;
use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::MissCache;
use Geo::Coder::Free::OpenAddresses;
use Geo::Coder::Free::Utils qw(distance);
use Geo::Location::Point;

# ---------------------------------------------------------------------------
# Stand-ins
# ---------------------------------------------------------------------------

# A backend for the facade's slots.  It records every location and parameter
# list it is handed, so a test can say what the facade passed on, and answers
# with whatever it was built with.
package Domain::Backend;

sub new {
	my ($class, %args) = @_;

	return bless { answer => $args{'answer'}, seen => [], reverse => [], reads => 0 }, $class;
}

sub geocode {
	my ($self, @args) = @_;

	my $params = ref($args[0]) ? $args[0] : (@args == 1) ? { location => $args[0] } : { @args };
	push @{$self->{'seen'}}, $params->{'location'};
	$self->{'last'} = { %{$params} };
	$self->{'reads'}++;

	return $self->{'answer'};
}

sub reverse_geocode {
	my ($self, $params) = @_;

	push @{$self->{'reverse'}}, { %{$params} };

	return 'a place';
}

sub reads { return $_[0]->{'reads'} }

# The openaddresses table: it finds nothing, and keeps the digests it was asked for
package Domain::OpenAddrTable;

sub new { return bless { digests => [] }, shift }

sub geohash {
	my ($self, %args) = @_;

	push @{$self->{'digests'}}, $args{'md5'};

	return;
}

# The cities table: it finds nothing, and keeps the SQL it was asked to run
package Domain::CitiesTable;

sub new { return bless { sql => [] }, shift }

sub execute {
	my ($self, $sql) = @_;

	push @{$self->{'sql'}}, $sql;

	return;
}

# Only has to be something that can be asked for get() and set()
package Domain::Cache;

sub new { return bless {}, shift }
sub get { return $_[0]->{ $_[1] } }
sub set { $_[0]->{ $_[1] } = $_[2]; return }

package main;

# ---------------------------------------------------------------------------
# Global state: the shell's data directories, and the process-wide miss cache
# ---------------------------------------------------------------------------

local $ENV{'OPENADDR_HOME'}    = '';
local $ENV{'WHOSONFIRST_HOME'} = '';

# local rather than a reset at the end of a subtest, so a subtest that dies
# leaves the setting as it found it
local $Geo::Coder::Free::MissCache::EXPIRES_AFTER = $Geo::Coder::Free::MissCache::EXPIRES_AFTER;

# ---------------------------------------------------------------------------
# Named values
# ---------------------------------------------------------------------------

Readonly::Scalar my $GCF   => 'Geo::Coder::Free';
Readonly::Scalar my $LOCAL => 'Geo::Coder::Free::Local';
Readonly::Scalar my $MM    => 'Geo::Coder::Free::MaxMind';
Readonly::Scalar my $OA    => 'Geo::Coder::Free::OpenAddresses';
Readonly::Scalar my $CACHE => 'Geo::Coder::Free::MissCache';

Readonly::Hash my %config => (
	lat_max           => 90,
	lon_max           => 180,
	just_over         => 0.0000001,
	half_earth_km     => 20015.0868,	# pi * 6371
	half_earth_miles  => 12437.5653,	# pi * 3959
	half_earth_nm     => 10807.3,		# pi * 3440.065
	distance_slack    => 1,
	one_degree_km     => 111.1949,
	long_string       => 65_536,		# no limit is documented: one past 16 bits
	digest_verbatim   => 16,			# longest normalised address kept as written
	scantext_shortest => 6,				# OpenAddresses ignores a scantext below this
	big_batch         => 1_000,
	an_hour           => 3_600,
	scantext_misses   => 10_000,		# how many misses an object keeps
);

# The messages the POD documents, as far as they are this distribution's own
Readonly::Scalar my $ERR_USAGE_GEOCODE  => qr/^\QUsage: Geo::Coder::Free::geocode(location => \E\$location\|scantext/;
Readonly::Scalar my $ERR_USAGE_MANY     => qr/^\QUsage: Geo::Coder::Free::geocode_many(\E/;
Readonly::Scalar my $ERR_USAGE_REVERSE  => qr/^\QUsage: Geo::Coder::Free::reverse_geocode(latlng\E/;
Readonly::Scalar my $ERR_INVALID_LOC    => qr/^\QGeo::Coder::Free: invalid location to geocode(), \E/;
Readonly::Scalar my $ERR_INVALID_SCAN   => qr/^\QGeo::Coder::Free: invalid scantext to geocode(), \E/;
Readonly::Scalar my $ERR_ON_ERROR       => qr/^\QGeo::Coder::Free: on_error must be "croak" or "undef", not \E/;
Readonly::Scalar my $ERR_RESERVED       => qr/\Qis one of the keys geocode_many() answers with\E/;
Readonly::Scalar my $ERR_NO_REVERSE     => qr/\QReverse lookup is not yet supported\E/;
Readonly::Scalar my $ERR_LOCAL_LOC      => qr/^\QUsage: geocode(location => \E/;
Readonly::Scalar my $ERR_LOCAL_SHAPE    => qr/^\QUsage: Geo::Coder::Free::Local::geocode(location => \E/;
Readonly::Scalar my $ERR_LOCAL_REVERSE  => qr/^\QUsage: Geo::Coder::Free::Local::reverse_geocode(latlng\E/;
Readonly::Scalar my $ERR_MM_LOC         => qr/^\QUsage: geocode(location => \E/;
Readonly::Scalar my $ERR_MM_INVALID     => qr/^\QUsage: Geo::Coder::Free::MaxMind: invalid input to geocode(), \E/;
Readonly::Scalar my $ERR_MM_SHAPE       => qr/^\QUsage: Geo::Coder::Free::MaxMind::geocode(location => \E/;
Readonly::Scalar my $ERR_MM_REVERSE     => qr/^\QUsage: Geo::Coder::Free::MaxMind::reverse_geocode(latlng\E/;
Readonly::Scalar my $ERR_MM_COORD       => qr/^\QInvalid coordinate value for reverse_geocode\E/;
Readonly::Scalar my $ERR_MM_DIR         => qr/directory \S+ doesn't exist/;
Readonly::Scalar my $ERR_OA_USAGE       => qr/^\QGeo::Coder::Free::OpenAddresses: Usage: new(openaddr => \E/;
Readonly::Scalar my $ERR_OA_DIR         => qr/^\QGeo::Coder::Free::OpenAddresses: Can't find the directory \E/;
Readonly::Scalar my $ERR_EXPIRES        => qr/^\Qexpires_after() expects a non-negative whole number of seconds\E/;
Readonly::Scalar my $ERR_LATITUDE       => qr/^\QLatitude must be between -90 and 90 degrees\E/;
Readonly::Scalar my $ERR_LONGITUDE      => qr/^\QLongitude must be between -180 and 180 degrees\E/;
Readonly::Scalar my $ERR_UNIT           => qr/^\QUnknown unit '\E/;
Readonly::Scalar my $ERR_FAILED         => qr/\Qgeocoding failed\E/;

# In the data: a whole row, which is an index hit, and a coordinate of it
Readonly::Scalar my $LOCAL_ROW     => 'All Saints Episcopal Church, 203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US';
Readonly::Scalar my $LOCAL_LAT     => '39.467270';
Readonly::Scalar my $LOCAL_NAME    => qr/CHATSWORTH/;
Readonly::Scalar my $MM_KNOWN_ADDR => 'Newport Pagnell, Buckinghamshire, England';

# The character domains, as escapes: this file is strictly ASCII
Readonly::Hash my %MULTIBYTE => (
	'German umlaut'         => "M\x{fc}nchen, Bayern, Deutschland",
	'German sharp s'        => "Stra\x{df}e 1, Gie\x{df}en, Hessen, Germany",
	'Cyrillic'              => "\x{41c}\x{43e}\x{441}\x{43a}\x{432}\x{430}, \x{420}\x{43e}\x{441}\x{441}\x{438}\x{44f}",
	'CJK street, short'     => "\x{4e2d}\x{6587} St, IL, USA",
	'emoji'                 => "\x{1F600} Road, Town, Kent, GB",
	'emoji ZWJ sequence'    => "\x{1F468}\x{200D}\x{1F469}\x{200D}\x{1F467}, Kent, England",
	'Zalgo text'            => "Z\x{0351}\x{036B}a\x{0300}l\x{0301}g\x{0302}o, Kent, GB",
	'right-to-left text'    => "\x{627}\x{644}\x{642}\x{627}\x{647}\x{631}\x{629}, \x{645}\x{635}\x{631}",
	'right-to-left override' => "\x{202E}tneK ,etagsmaR",
	'undecoded UTF-8 bytes' => "M\xc3\xbcnchen, Bayern, Germany",
);

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# A facade whose backends are stand-ins.  Passing openaddr gives the path with
# OpenAddresses configured; leaving it out gives the MaxMind-only path.
sub _facade {
	my (%slots) = @_;

	my $geo = $GCF->new();
	$geo->{'maxmind'} = $slots{'maxmind'} // Domain::Backend->new();
	foreach my $slot(qw(openaddr local)) {
		$geo->{$slot} = $slots{$slot} if $slots{$slot};
	}
	$CACHE->clear();

	return $geo;
}

# A real OpenAddresses backend that reads a stand-in table
sub _openaddr {
	my $backend = $OA->new(openaddr => tempdir(CLEANUP => 1), libpostal => 0);
	$backend->{'openaddr_db'} = Domain::OpenAddrTable->new();
	$CACHE->clear();

	return $backend;
}

# A real MaxMind backend that reads a stand-in cities table
sub _maxmind {
	my $backend = $MM->new();
	$backend->{'cities'} = Domain::CitiesTable->new();
	$CACHE->clear();

	return $backend;
}

sub _point {
	return Geo::Location::Point->new({ lat => 51.5, long => -1.5, location => 'stand-in' });
}

# Runs the code and returns the warnings it gave
sub _warnings_from {
	my ($code) = @_;

	my @warnings;
	local $SIG{'__WARN__'} = sub { push @warnings, @_ };
	$code->();

	return @warnings;
}

# How a value reads in a test name, without any wide character reaching the TAP
sub _show {
	my ($value) = @_;

	return 'undef' if !defined($value);
	return ref($value) if ref($value);
	(my $shown = $value) =~ s/([^\x20-\x7e])/sprintf('\\x{%x}', ord($1))/ge;

	return "'$shown'";
}

# Local's __DATA__ can only be read once: see CLAUDE.md
my $LOCAL_OBJ = $LOCAL->new();

# ---------------------------------------------------------------------------
# Geo::Coder::Free->new
# ---------------------------------------------------------------------------

subtest 'new(openaddr): a readable directory, or nothing' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'a-file');
	open(my $fh, '>', $file) or die "$file: $!";
	close($fh);

	ok($GCF->new(openaddr => $dir)->{'openaddr'}, 'valid: an existing directory configures the backend');

	foreach my $off('', '0') {
		ok(!$GCF->new(openaddr => $off)->{'openaddr'}, 'off: ' . _show($off) . ' configures no backend');
	}

	throws_ok { $GCF->new(openaddr => File::Spec->catfile($dir, 'absent')) } $ERR_OA_DIR, 'invalid: a directory that does not exist';
	throws_ok { $GCF->new(openaddr => $file) } $ERR_OA_DIR, 'invalid: a file is not a directory';

	{
		local $ENV{'OPENADDR_HOME'} = $dir;
		ok($GCF->new()->{'openaddr'}, 'absent: falls back to OPENADDR_HOME');
		ok(!$GCF->new(openaddr => '')->{'openaddr'}, 'an explicit false value beats OPENADDR_HOME');
	}
};

subtest 'new(directory): an existing directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'a-file');
	open(my $fh, '>', $file) or die "$file: $!";
	close($fh);

	ok($GCF->new(directory => $dir)->{'maxmind'}, 'valid: an existing directory');
	throws_ok { $GCF->new(directory => File::Spec->catfile($dir, 'absent')) } $ERR_MM_DIR, 'invalid: a directory that does not exist';
	throws_ok { $GCF->new(directory => $file) } $ERR_MM_DIR, 'invalid: a file is not a directory';
	throws_ok { $MM->new(directory => $file) } $ERR_MM_DIR, 'the same from the backend directly';

	ok($GCF->new()->{'maxmind'}, 'absent: the directory beside the module');
};

subtest 'new(libpostal): a boolean, defaulting to true' => sub {
	my $dir = tempdir(CLEANUP => 1);

	my @cases = (
		[ 'absent', [], 1 ],
		[ 'undef', [ libpostal => undef ], 1 ],
		[ 'false', [ libpostal => 0 ], 0 ],
		[ 'true', [ libpostal => 1 ], 1 ],
	);
	foreach my $case(@cases) {
		my ($name, $args, $want) = @{$case};
		is($GCF->new(openaddr => $dir, @{$args})->{'openaddr'}{'libpostal'}, $want, "$name is $want");
		is($OA->new(openaddr => $dir, @{$args})->{'libpostal'}, $want, "$name is $want on the backend");
	}
};

subtest 'new(cache): an object that understands get and set' => sub {
	my $cache = Domain::Cache->new();

	is($GCF->new(cache => $cache)->{'cache'}, $cache, 'valid: the object is kept');
	ok(!$GCF->new()->{'cache'}, 'absent: the facade holds none');
	ok(!$GCF->new(cache => undef)->{'cache'}, 'undef is the same as absent');
};

subtest 'new(): the shape of the argument list' => sub {
	isa_ok($GCF->new(), $GCF, 'no arguments');
	isa_ok($GCF->new({}), $GCF, 'an empty hashref');
	isa_ok(Geo::Coder::Free::new(undef), $GCF, 'as a function with no arguments');

	foreach my $args([ 'bare' ], [ 'a', 'b', 'c' ]) {
		throws_ok { $GCF->new(@{$args}) } qr/^Usage: /, scalar(@{$args}) . ' argument(s): an odd list is refused';
	}

	my $rc = 'unchanged';
	warning_like { $rc = Geo::Coder::Free::new(undef, directory => '/') } qr/\Quse ->new() not ::new()\E/,
		'as a function with arguments: a warning';
	is($rc, undef, 'and no object');

	my $original = $GCF->new();
	my $clone = $original->new(extra => 1);
	is($clone->{'maxmind'}, $original->{'maxmind'}, 'on an object: a shallow clone');
	is($clone->{'extra'}, 1, 'with the arguments merged in');
};

subtest 'OpenAddresses->new(openaddr): required' => sub {
	my $dir = tempdir(CLEANUP => 1);

	isa_ok($OA->new(openaddr => $dir), $OA, 'valid: a directory');
	throws_ok { $OA->new() } $ERR_OA_USAGE, 'invalid: absent';
	foreach my $false('', '0') {
		throws_ok { $OA->new(openaddr => $false) } $ERR_OA_USAGE, 'invalid: ' . _show($false);
	}
	throws_ok { $OA->new(openaddr => File::Spec->catfile($dir, 'absent')) } $ERR_OA_DIR, 'invalid: not a directory';
};

# ---------------------------------------------------------------------------
# valid_location
# ---------------------------------------------------------------------------

subtest 'valid_location(location): the partitions of the rule' => sub {
	my $geo = _facade();

	my @invalid = (
		[ undef, 'undef' ],
		[ '', 'the empty string' ],
		[ '0', 'the shortest digit string, which is also false' ],
		[ '1', 'one digit' ],
		[ '0044', 'a digit string with leading zeros' ],
		[ '9' x $config{'long_string'}, 'a very long digit string' ],
		[ "\x{661}", 'one digit of another script' ],
		[ "\x{661}\x{662}", 'digits of another script' ],
		[ [], 'an arrayref' ],
		[ {}, 'a hashref' ],
		[ \'Kent', 'a scalar ref' ],
	);
	foreach my $case(@invalid) {
		is($geo->valid_location($case->[0]), 0, "invalid: $case->[1]");
	}

	my @valid = (
		[ 'A', 'the shortest string with a non-digit' ],
		[ 'Ramsgate, Kent', 'a typical location' ],
		[ '-', 'punctuation alone' ],
		[ ' ', 'a space alone' ],
		[ '3.14', 'a decimal number: there is a non-digit in it' ],
		[ '1 ', 'digits then a space' ],
		[ ' 1', 'a space then digits' ],
		[ "1\n", 'digits then a newline: the newline is a non-digit' ],
		[ "\n", 'a newline alone' ],
		[ "\0", 'a zero byte' ],
		[ '1' . ('a' x $config{'long_string'}), 'a very long string' ],
	);
	foreach my $case(@valid) {
		is($geo->valid_location($case->[0]), 1, "valid: $case->[1]");
	}

	foreach my $name(sort keys %MULTIBYTE) {
		is($geo->valid_location($MULTIBYTE{$name}), 1, "valid: $name");
	}
};

subtest 'valid_location(): the invocant is not the location' => sub {
	my $geo = _facade();

	is($geo->valid_location(), 0, 'on an object with no argument');
	is($GCF->valid_location(), 0, 'on the class with no argument');
	is($GCF->valid_location('Kent'), 1, 'on the class, valid');
	is($GCF->valid_location('0044'), 0, 'on the class, invalid');
	is(Geo::Coder::Free::valid_location(), 0, 'as a function with no argument');
	is(Geo::Coder::Free::valid_location('Kent'), 1, 'as a function, valid');
	is(Geo::Coder::Free::valid_location('0044'), 0, 'as a function, invalid');
	is(Geo::Coder::Free::valid_location($GCF), 0, 'the name of the class alone is an invocant, not a location');
};

# ---------------------------------------------------------------------------
# geocode
# ---------------------------------------------------------------------------

subtest 'geocode(location): the partitions of the value' => sub {
	my $point = _point();

	my @found = (
		[ 'A', 'the shortest valid location' ],
		[ 'Ramsgate, Kent', 'a typical location' ],
		[ '3.14', 'a decimal number' ],
		[ "1\n", 'digits and a newline' ],
		[ 'a' x $config{'long_string'}, 'a very long location' ],
	);
	foreach my $case(@found) {
		my ($location, $name) = @{$case};
		my $maxmind = Domain::Backend->new(answer => $point);
		my $rc = _facade(maxmind => $maxmind)->geocode(location => $location);
		ok(defined($rc), "valid: $name");
		is($maxmind->{'seen'}[0], $location, 'and it reaches the backend unchanged');
	}

	foreach my $digits('0', '1', '0044', '9' x $config{'long_string'}, "\x{661}\x{662}") {
		my $maxmind = Domain::Backend->new(answer => $point);
		throws_ok { _facade(maxmind => $maxmind)->geocode(location => $digits) } $ERR_INVALID_LOC,
			'invalid: digits only, ' . substr(_show($digits), 0, 20);
		is(scalar(@{$maxmind->{'seen'}}), 0, 'and no backend was touched');
	}

	foreach my $ref([], {}) {
		throws_ok { _facade()->geocode(location => $ref) } $ERR_INVALID_LOC, 'invalid: a reference as the value, ' . ref($ref);
	}

	my $maxmind = Domain::Backend->new(answer => $point);
	my $geo = _facade(maxmind => $maxmind);
	is(scalar($geo->geocode(location => '')), undef, 'empty: finds nothing, and is not an error');
	is(scalar(@{$maxmind->{'seen'}}), 0, 'and no backend was touched');
	throws_ok { $geo->geocode(location => undef) } $ERR_USAGE_GEOCODE, 'undef: the same as giving no location';
};

subtest 'geocode(): the shape of the argument list' => sub {
	my $point = _point();

	my $maxmind = Domain::Backend->new(answer => $point);
	my $geo = _facade(maxmind => $maxmind);
	foreach my $args([ 'Kent' ], [ location => 'Kent' ], [ { location => 'Kent' } ]) {
		ok(defined(scalar($geo->geocode(@{$args}))), scalar(@{$args}) . ' argument(s), ' . (ref($args->[0]) || 'plain'));
	}
	is_deeply($maxmind->{'seen'}, [ ('Kent') x 3 ], 'each form hands over the same location');

	my @refused = (
		[ [], 'no arguments' ],
		[ [ undef ], 'a lone undef' ],
		[ [ {} ], 'an empty hashref' ],
		[ [ [] ], 'an arrayref' ],
		[ [ \'Kent' ], 'a scalar ref' ],
		[ [ 'a', 'b', 'c' ], 'an odd list longer than one' ],
		[ [ region => 'GB' ], 'options with no location or scantext' ],
	);
	foreach my $case(@refused) {
		my ($args, $name) = @{$case};
		throws_ok { $geo->geocode(@{$args}) } $ERR_USAGE_GEOCODE, "invalid: $name";
	}

	throws_ok { $GCF->geocode() } $ERR_USAGE_GEOCODE, 'on the class with no arguments';
	throws_ok { Geo::Coder::Free::geocode() } $ERR_USAGE_GEOCODE, 'as a function with no arguments';
	throws_ok { Geo::Coder::Free::geocode('0044') } $ERR_INVALID_LOC, 'as a function, a bare invalid location';
	throws_ok { $GCF->geocode(location => '0044') } $ERR_INVALID_LOC, 'on the class, an invalid location';
};

subtest 'geocode(on_error): croak, undef or nothing' => sub {
	my $geo = _facade();

	foreach my $valid(undef, 'croak') {
		throws_ok { $geo->geocode(location => '0044', on_error => $valid) } $ERR_INVALID_LOC, 'on_error ' . _show($valid) . ' croaks on a bad location';
		throws_ok { $geo->geocode(scantext => '0044', on_error => $valid) } $ERR_INVALID_SCAN, 'and on a bad scantext';
	}

	is(scalar($geo->geocode(location => '0044', on_error => 'undef')), undef, "'undef' answers undef for a bad location");
	is(scalar($geo->geocode(scantext => '0044', on_error => 'undef')), undef, 'and for a bad scantext');
	throws_ok { $geo->geocode(on_error => 'undef') } $ERR_USAGE_GEOCODE, 'a usage error is not an input error: it still croaks';

	foreach my $bad('', 'die', 'CROAK', 'Undef', ' croak', 'croak ', "croak\n", "\x{1F600}", '0') {
		throws_ok { $geo->geocode(location => 'Kent', on_error => $bad) } $ERR_ON_ERROR, 'invalid: on_error ' . _show($bad);
	}
};

subtest 'geocode(scantext): the partitions of the value' => sub {
	my $geo = _facade();

	is(scalar($geo->geocode(scantext => '')), undef, 'empty: finds nothing, and is not an error');
	throws_ok { $geo->geocode(scantext => undef) } $ERR_USAGE_GEOCODE, 'undef: the same as giving no scantext';
	foreach my $digits('0', '1', '0044') {
		throws_ok { $geo->geocode(scantext => $digits) } $ERR_INVALID_SCAN, 'invalid: digits only, ' . _show($digits);
	}

	my $maxmind = Domain::Backend->new(answer => _point());
	my $no_openaddr = _facade(maxmind => $maxmind);
	my @warnings = _warnings_from(sub {
		is(scalar($no_openaddr->geocode(scantext => 'Ramsgate')), undef, 'without OpenAddresses a scantext finds nothing');
		is(scalar($no_openaddr->geocode(scantext => 'Margate')), undef, 'nor does another');
	});
	is(scalar(@{$maxmind->{'seen'}}), 0, 'and no backend was touched');
	is(scalar(@warnings), 1, 'it says so once per object');
	like($warnings[0], qr/\Qscantext only searches OpenAddresses data\E/, 'and says what is missing');

	# With OpenAddresses, the whole string is tried first
	my $openaddr = Domain::Backend->new();
	_facade(openaddr => $openaddr, local => Domain::Backend->new())->geocode(scantext => 'Ramsgate');
	is($openaddr->{'seen'}[0], 'Ramsgate', 'with OpenAddresses the whole string is tried first');
};

subtest 'geocode(location, scantext): the two given together' => sub {
	my $point = _point();

	my $maxmind = Domain::Backend->new(answer => $point);
	my $rc = _facade(maxmind => $maxmind)->geocode(location => 'Kent', scantext => 'Ramsgate');
	ok(defined($rc), 'without OpenAddresses the location is looked up');
	is_deeply($maxmind->{'seen'}, [ 'Kent' ], 'and the scantext is not');

	my $openaddr = Domain::Backend->new(answer => $point);
	_facade(openaddr => $openaddr, local => Domain::Backend->new())->geocode(location => 'Kent', scantext => 'Ramsgate');
	is($openaddr->{'seen'}[0], 'Ramsgate', 'with OpenAddresses the scantext is');

	my $geo = _facade();
	throws_ok { $geo->geocode(location => '0044', scantext => 'Ramsgate') } $ERR_INVALID_LOC, 'a bad location beside a good scantext';
	throws_ok { $geo->geocode(location => 'Kent', scantext => '0044') } $ERR_INVALID_SCAN, 'a good location beside a bad scantext';
	is(scalar($geo->geocode(location => '0044', scantext => '0044', on_error => 'undef')), undef, 'both bad, skipped on request');
	throws_ok { $geo->geocode(location => '0044', on_error => 'die') } $ERR_ON_ERROR, 'a bad on_error is reported before a bad location';
};

subtest 'geocode(region): any string, appended to each scantext candidate' => sub {
	my $words = 'Ramsgate Margate Deal';
	my $triplet = 'Ramsgate, Margate, Deal';

	my @cases = (
		[ undef, $triplet, 'absent: no country' ],
		[ '', $triplet, 'empty: no country' ],
		[ '0', $triplet, 'false: no country' ],
		[ 'GB', "$triplet, GB", 'a code the parser understands' ],
		[ 'US', "$triplet, US", 'another' ],
		[ 'gb', "$triplet, GB", 'two letters are upper-cased, as the parsers expect' ],
		[ 'zz', "$triplet, ZZ", 'known or not' ],
		[ 'Kent', "$triplet, Kent", 'anything else is appended as written' ],
		[ 'CA', "$triplet, Canada", 'CA is appended by name: alone it reads as California' ],
		[ 'ca', "$triplet, Canada", 'in any case' ],
		[ 'AU', "$triplet, Australia", 'AU is appended by name' ],
		[ 'IE', "$triplet, Ireland", 'IE is appended by name' ],
		[ 'ZZ', "$triplet, ZZ", 'an unknown code is not refused' ],
		[ "\x{fc}", "$triplet, \x{fc}", 'nor is a non-ASCII one' ],
	);
	foreach my $case(@cases) {
		my ($region, $want, $name) = @{$case};
		my $openaddr = Domain::Backend->new();
		_facade(openaddr => $openaddr, local => Domain::Backend->new())->geocode(
			scantext => $words,
			defined($region) ? (region => $region) : (),
		);
		ok((grep { defined($_) && ($_ eq $want) } @{$openaddr->{'seen'}}), 'region ' . _show($region) . ": $name");
	}

	my $maxmind = Domain::Backend->new(answer => _point());
	_facade(maxmind => $maxmind)->geocode(location => 'Kent', region => 'GB');
	is($maxmind->{'last'}{'region'}, 'GB', 'a location lookup hands the region to the backend');
};

subtest 'geocode(ignore_words): an arrayref of words' => sub {
	my $text = 'Ramsgate Margate Deal';

	my $words_tried = sub {
		my (@options) = @_;

		my $openaddr = Domain::Backend->new();
		_facade(openaddr => $openaddr, local => Domain::Backend->new())->geocode(scantext => $text, @options);

		return grep { defined($_) && ($_ ne $text) } @{$openaddr->{'seen'}};
	};

	my @everything = $words_tried->();
	ok(scalar(grep { /Margate/ } @everything), 'absent: every word is tried');
	ok(scalar(grep { /Margate/ } $words_tried->(ignore_words => [])), 'empty: every word is tried');
	ok(!scalar(grep { /Margate/ } $words_tried->(ignore_words => [ 'Margate' ])), 'one word is left out');
	ok(!scalar(grep { /Margate/ } $words_tried->(ignore_words => [ 'mARGATE' ])), 'in any case');
	ok(scalar(grep { /Margate/ } $words_tried->(ignore_words => [ "\x{1F600}" ])), 'a word that is not in the text changes nothing');
	is(scalar($words_tried->(ignore_words => [ qw(Ramsgate Margate Deal) ])), 0, 'every word left out: nothing to try');

	foreach my $false('', 0) {
		ok(scalar(grep { /Margate/ } $words_tried->(ignore_words => $false)), 'false: ' . _show($false) . ' is the same as absent');
	}
	foreach my $bad('Margate', {}) {
		throws_ok { $words_tried->(ignore_words => $bad) } qr/\bARRAY\b/, 'invalid: ' . _show($bad) . ' with OpenAddresses configured';
		_warnings_from(sub {
			lives_ok { _facade()->geocode(scantext => $text, ignore_words => $bad) } 'without OpenAddresses it is not looked at';
		});
	}
};

subtest 'geocode(): region and ignore_words at their edges together' => sub {
	my $openaddr = Domain::Backend->new();
	my $geo = _facade(openaddr => $openaddr, local => Domain::Backend->new());

	# An unknown region, with every word ignored: nothing to try but the
	# whole string, which is a miss, and that miss is remembered
	my $text = 'Ramsgate Margate';
	is(scalar($geo->geocode(scantext => $text, region => 'ZZ', ignore_words => [ qw(Ramsgate Margate) ])), undef, 'finds nothing');
	is_deeply($openaddr->{'seen'}, [ $text ], 'only the whole string was tried');
	$geo->geocode(scantext => $text, region => 'zz', ignore_words => [ qw(margate RAMSGATE) ]);
	is(scalar(@{$openaddr->{'seen'}}), 1, 'the miss is remembered, whatever the case or the order of the options');
};

subtest 'geocode(scantext): a miss holds for that search, and for a while' => sub {
	my $text = 'Ramsgate Margate';

	# How many lookups the same text costs, given the options of each call
	my $lookups = sub {
		my ($geo, $openaddr, @options) = @_;

		my $before = scalar(@{$openaddr->{'seen'}});
		$geo->geocode(scantext => $text, @options);

		return scalar(@{$openaddr->{'seen'}}) - $before;
	};
	my $fresh = sub {
		my $openaddr = Domain::Backend->new();
		return (_facade(openaddr => $openaddr, local => Domain::Backend->new()), $openaddr);
	};

	my ($geo, $openaddr) = $fresh->();
	cmp_ok($lookups->($geo, $openaddr), '>', 0, 'the first search looks');
	is($lookups->($geo, $openaddr), 0, 'the same search does not');
	cmp_ok($lookups->($geo, $openaddr, region => 'CA'), '>', 0, 'another region is another search: this text may be in Canada');
	is($lookups->($geo, $openaddr, region => 'ca'), 0, 'and is remembered in its turn, in either case');
	cmp_ok($lookups->($geo, $openaddr, ignore_words => [ 'Margate' ]), '>', 0, 'other ignore_words are another search');

	$geo->clear_miss_cache('Local');
	is($lookups->($geo, $openaddr), 0, 'clearing another backend leaves it remembered');
	$geo->clear_miss_cache('OpenAddresses');
	cmp_ok($lookups->($geo, $openaddr), '>', 0, 'clearing OpenAddresses forgets it');
	$GCF->clear_miss_cache();
	cmp_ok($lookups->($geo, $openaddr), '>', 0, 'and so does clearing everything');

	($geo, $openaddr) = $fresh->();
	$CACHE->expires_after(0);
	$lookups->($geo, $openaddr);
	$CACHE->expires_after($config{'an_hour'});
	cmp_ok($lookups->($geo, $openaddr), '>', 0, 'expires_after(0) turns this memory off as well');

	($geo, $openaddr) = $fresh->();
	$lookups->($geo, $openaddr);
	$geo->{'scantext_misses'}{$text} = time() - 1;
	cmp_ok($lookups->($geo, $openaddr), '>', 0, 'an expired miss is looked for again');

	($geo, $openaddr) = $fresh->();
	$geo->{'scantext_misses'}{$_} = time() + $config{'an_hour'} foreach 1 .. $config{'scantext_misses'};
	$lookups->($geo, $openaddr);
	cmp_ok(scalar(keys %{$geo->{'scantext_misses'}}), '<', $config{'scantext_misses'}, 'and the memory has a limit');
};

# ---------------------------------------------------------------------------
# The character domains, through each backend
# ---------------------------------------------------------------------------

subtest 'non-ASCII text through the facade: not altered on the way' => sub {
	foreach my $name(sort keys %MULTIBYTE) {
		my $text = $MULTIBYTE{$name};

		my $maxmind = Domain::Backend->new();
		my @warnings = _warnings_from(sub {
			lives_ok { _facade(maxmind => $maxmind)->geocode(location => $text) } "$name: does not die";
		});
		is($maxmind->{'seen'}[0], $text, "$name: reaches MaxMind unchanged");
		is(length($maxmind->{'seen'}[0]), length($text), "$name: with its length intact");
		is_deeply(\@warnings, [], "$name: no warnings");

		my $openaddr = Domain::Backend->new();
		my $local = Domain::Backend->new();
		@warnings = _warnings_from(sub {
			lives_ok { _facade(openaddr => $openaddr, local => $local)->geocode(location => $text) } "$name: does not die with OpenAddresses";
		});
		is($openaddr->{'seen'}[0], $text, "$name: reaches OpenAddresses unchanged");
		is($local->{'seen'}[0], $text, "$name: reaches Local unchanged");
		is_deeply(\@warnings, [], "$name: no warnings with OpenAddresses");

		$openaddr = Domain::Backend->new();
		@warnings = _warnings_from(sub {
			lives_ok {
				_facade(openaddr => $openaddr, local => Domain::Backend->new())->geocode(scantext => $text, region => 'GB')
			} "$name: does not die as a scantext";
		});
		is($openaddr->{'seen'}[0], $text, "$name: the whole scantext is tried unchanged");
		is_deeply(\@warnings, [], "$name: no warnings as a scantext");
	}
};

subtest 'non-ASCII text through Local: found nowhere, and remembered' => sub {
	foreach my $name(sort keys %MULTIBYTE) {
		my $text = $MULTIBYTE{$name};

		$CACHE->clear();
		my @warnings = _warnings_from(sub {
			lives_ok { is(scalar($LOCAL_OBJ->geocode(location => $text)), undef, "$name: finds nothing") } "$name: does not die";
		});
		is_deeply(\@warnings, [], "$name: no warnings");
		is($CACHE->size('Local'), 1, "$name: one miss remembered");

		my $reads = $LOCAL_OBJ->reads();
		is(scalar($LOCAL_OBJ->geocode(location => $text)), undef, "$name: the same answer again");
		is($LOCAL_OBJ->reads(), $reads, "$name: without a search");
	}
};

subtest 'non-ASCII text through OpenAddresses: the digest does not corrupt it' => sub {
	foreach my $name(sort keys %MULTIBYTE) {
		my $text = $MULTIBYTE{$name};

		foreach my $param(qw(location scantext)) {
			my $backend = _openaddr();
			my @warnings = _warnings_from(sub {
				lives_ok { $backend->geocode($param => $text) } "$name: $param does not die";
			});
			is_deeply(\@warnings, [], "$name: $param gives no warnings");
		}
	}

	# Short enough to be stored as written: the characters are all there
	my $backend = _openaddr();
	my $cjk = "\x{4e2d}" x 4;
	$backend->geocode(location => "$cjk US");
	is($backend->{'openaddr_db'}{'digests'}[0], Encode::encode_utf8("${cjk}US"), 'a short non-ASCII address is looked up as its UTF-8');
};

subtest 'non-ASCII text through MaxMind: real data' => sub {
	# Stops before new(): the arguments of the first real query die without the file
	plan(skip_all => 'No cities database found') unless -f 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql';

	my $backend = $MM->new();
	foreach my $name(sort keys %MULTIBYTE) {
		$CACHE->clear();
		lives_ok { $backend->geocode(location => $MULTIBYTE{$name}) } "$name: does not die";
	}
};

subtest 'geocode_many(values): non-ASCII values key the result as given' => sub {
	my $geo = _facade();
	my @values = map { $MULTIBYTE{$_} } sort keys %MULTIBYTE;

	my $batch = $geo->geocode_many(\@values);

	foreach my $name(sort keys %MULTIBYTE) {
		ok(exists($batch->{$MULTIBYTE{$name}}), "$name: has its own key");
	}
	is($batch->{'unresolved'}, scalar(@values), 'each is a value of its own');
	is_deeply($batch->{'unresolved_values'}, \@values, 'and comes back as it went in');
};

# ---------------------------------------------------------------------------
# geocode_many
# ---------------------------------------------------------------------------

subtest 'geocode_many(values): the size and content of the list' => sub {
	my $point = _point();

	my $maxmind = Domain::Backend->new(answer => $point);
	my $geo = _facade(maxmind => $maxmind);

	my $batch = $geo->geocode_many([]);
	is_deeply(
		[ @{$batch}{qw(lookups resolved unresolved)} ],
		[ 0, 0, 0 ],
		'none: every count is zero',
	);
	is_deeply($batch->{'unresolved_values'}, [], 'and there is nothing unresolved');

	$batch = $geo->geocode_many([ 'Kent' ]);
	is($batch->{'resolved'}, 1, 'one value: one resolved');

	# Every row the same: at the far end of a batch, the lookups stay at one
	$maxmind = Domain::Backend->new(answer => $point);
	$geo = _facade(maxmind => $maxmind);
	$batch = $geo->geocode_many([ ('Kent') x $config{'big_batch'} ]);
	is($batch->{'resolved'}, 1, 'many rows, one value: one resolved');
	is(scalar(@{$maxmind->{'seen'}}), 1, 'and one lookup');

	# Every row different
	$maxmind = Domain::Backend->new(answer => $point);
	$geo = _facade(maxmind => $maxmind);
	$batch = $geo->geocode_many([ map { "Place $_" } 1 .. $config{'big_batch'} ]);
	is($batch->{'resolved'}, $config{'big_batch'}, 'many rows, all different: all resolved');
	is(scalar(@{$maxmind->{'seen'}}), $config{'big_batch'}, 'and a lookup each');

	foreach my $empty(undef, '') {
		$batch = $geo->geocode_many([ $empty ]);
		is($batch->{'unresolved'}, 1, _show($empty) . ' is unresolved, on the default setting too');
		ok(exists($batch->{''}), 'keyed under the empty string');
		is_deeply($batch->{'unresolved_values'}, [ $empty ], 'and reported as it was given');
	}
	$batch = $geo->geocode_many([ undef, '' ]);
	is($batch->{'unresolved'}, 1, 'undef and the empty string are one value');

	throws_ok { $geo->geocode_many([ '0044' ]) } $ERR_INVALID_LOC, 'digits only croak by default';
	throws_ok { $geo->geocode_many([ [] ]) } $ERR_INVALID_LOC, 'so does a reference';

	$batch = $geo->geocode_many([ '0044', [], 'Kent' ], on_error => 'undef');
	is($batch->{'unresolved'}, 2, 'on_error undef: the refused values are unresolved');
	is($batch->{'resolved'}, 1, 'and the rest carry on');
	is($batch->{'resolved'} + $batch->{'unresolved'}, 3, 'resolved and unresolved add up to the distinct values');
};

subtest 'geocode_many(values): the five reserved keys' => sub {
	my $maxmind = Domain::Backend->new();
	my $geo = _facade(maxmind => $maxmind);

	foreach my $key(qw(lookups reads resolved unresolved unresolved_values)) {
		throws_ok { $geo->geocode_many([ $key ]) } $ERR_RESERVED, "invalid: $key";
		throws_ok { $geo->geocode_many([ 'Kent', $key ], on_error => 'undef') } $ERR_RESERVED, 'on any setting, wherever it is in the list';
	}
	is(scalar(@{$maxmind->{'seen'}}), 0, 'refused before anything is looked up');

	foreach my $near('Lookups', 'READS', ' resolved', 'unresolved ', 'unresolve') {
		lives_ok { $geo->geocode_many([ $near ]) } 'valid: ' . _show($near) . ' is not reserved';
	}
};

subtest 'geocode_many(): the shape of the argument list' => sub {
	my $geo = _facade();

	foreach my $bad(undef, 'Kent', {}, \'Kent', 0) {
		throws_ok { $geo->geocode_many($bad) } $ERR_USAGE_MANY, 'invalid: values is ' . _show($bad);
	}
	throws_ok { $geo->geocode_many() } $ERR_USAGE_MANY, 'invalid: no values';
	throws_ok { $GCF->geocode_many() } $ERR_USAGE_MANY, 'invalid: on the class, no values';
	throws_ok { $GCF->geocode_many('Kent') } $ERR_USAGE_MANY, 'invalid: on the class, not an arrayref';
	throws_ok { Geo::Coder::Free::geocode_many('Kent') } $ERR_USAGE_MANY, 'invalid: as a function, not an arrayref';

	foreach my $options([ 'lone' ], [ qw(a b c) ], [ [] ], [ on_error => [] ]) {
		throws_ok { $geo->geocode_many([], @{$options}) } $ERR_USAGE_MANY, 'invalid: options ' . join(',', map { _show($_) } @{$options});
	}

	is($geo->geocode_many([], {})->{'resolved'}, 0, 'valid: an empty hashref of options');
	is($geo->geocode_many([], { on_error => 'undef' })->{'resolved'}, 0, 'valid: a hashref of options');
	is($GCF->geocode_many([])->{'resolved'}, 0, 'valid: on the class');
	is(Geo::Coder::Free::geocode_many([])->{'resolved'}, 0, 'valid: as a function');
};

subtest 'geocode_many(on_error): the same domain as geocode' => sub {
	my $geo = _facade();

	foreach my $bad('', 'die', 'CROAK', 'Undef') {
		throws_ok { $geo->geocode_many([], on_error => $bad) } $ERR_ON_ERROR, 'invalid: ' . _show($bad) . ', even with no values';
	}
	foreach my $good(undef, 'croak', 'undef') {
		lives_ok { $geo->geocode_many([ 'Kent' ], on_error => $good) } 'valid: ' . _show($good);
	}
	throws_ok { $geo->geocode_many([ 'lookups' ], on_error => 'die') } $ERR_ON_ERROR, 'a bad on_error is reported before a reserved value';
};

subtest 'geocode_many(region): handed to every lookup' => sub {
	foreach my $region('GB', '', "\x{fc}") {
		my $maxmind = Domain::Backend->new();
		_facade(maxmind => $maxmind)->geocode_many([ 'Kent' ], region => $region);
		is($maxmind->{'last'}{'region'}, $region, 'region ' . _show($region));
	}

	my $maxmind = Domain::Backend->new();
	_facade(maxmind => $maxmind)->geocode_many([ 'Kent' ]);
	ok(!exists($maxmind->{'last'}{'region'}), 'absent stays absent');
};

# ---------------------------------------------------------------------------
# reverse_geocode
# ---------------------------------------------------------------------------

subtest 'reverse_geocode(latlng) on the facade: truth is all it asks' => sub {
	my $maxmind = Domain::Backend->new();
	my $geo = _facade(maxmind => $maxmind);

	foreach my $latlng('0,0', '90,180', '-90,-180', '91,181', 'not a coordinate') {
		is($geo->reverse_geocode(latlng => $latlng), 'a place', 'handed to the backend: ' . _show($latlng));
		is($maxmind->{'reverse'}[-1]{'latlng'}, $latlng, 'unchanged');
		is($geo->reverse_geocode($latlng), 'a place', 'and as a bare string');
	}
	is($geo->reverse_geocode({ latlng => '0,0' }), 'a place', 'and in a hashref');

	foreach my $false(undef, '', '0') {
		throws_ok { $geo->reverse_geocode(latlng => $false) } $ERR_NO_REVERSE, 'false: ' . _show($false);
	}
	throws_ok { $geo->reverse_geocode() } $ERR_NO_REVERSE, 'no arguments';
	throws_ok { $geo->reverse_geocode(lat => 1, lon => 2) } $ERR_NO_REVERSE, 'separate coordinates are not supported here';

	throws_ok { $geo->reverse_geocode([]) } $ERR_USAGE_REVERSE, 'an arrayref';
	throws_ok { $geo->reverse_geocode(qw(a b c)) } $ERR_USAGE_REVERSE, 'an odd list';
	throws_ok { $GCF->reverse_geocode() } $ERR_USAGE_REVERSE, 'on the class with no arguments';
	throws_ok { Geo::Coder::Free::reverse_geocode() } $ERR_USAGE_REVERSE, 'as a function with no arguments';

	my $dir = tempdir(CLEANUP => 1);
	throws_ok { $GCF->new(openaddr => $dir)->reverse_geocode(latlng => '0,0') } $ERR_NO_REVERSE, 'with OpenAddresses configured it always croaks';
};

subtest 'OpenAddresses->reverse_geocode: refuses everything' => sub {
	my $backend = _openaddr();

	foreach my $args([], [ '0,0' ], [ latlng => '0,0' ], [ {} ], [ \'junk' ]) {
		throws_ok { $backend->reverse_geocode(@{$args}) } qr/^\QGeo::Coder::Free::OpenAddresses: Reverse lookup is not yet supported\E/,
			scalar(@{$args}) . ' argument(s)';
	}
};

subtest 'MaxMind->reverse_geocode(latlng): the format of a coordinate' => sub {
	my $backend = _maxmind();

	my @queried = (
		[ '0,0', 'zero, which a truth test on either part would lose' ],
		[ '51.5,-1.5', 'a typical pair' ],
		[ '90,180', 'the top of both ranges' ],
		[ '-90,-180', 'the bottom of both ranges' ],
		[ '90,-180', 'latitude at its maximum and longitude at its minimum' ],
		[ '90.000001,0', 'just over the latitude range: not range checked' ],
		[ '0,180.000001', 'just over the longitude range: not range checked' ],
		[ '91,181', 'well over both' ],
		[ '1.,2.', 'a trailing point' ],
		[ '1,2,3', 'a third part is dropped' ],
	);
	foreach my $case(@queried) {
		my ($latlng, $name) = @{$case};
		my $cities = $backend->{'cities'} = Domain::CitiesTable->new();
		lives_ok { $backend->reverse_geocode(latlng => $latlng) } "valid: $name";
		is(scalar(@{$cities->{'sql'}}), 1, 'and the table is read');
	}

	my @refused = (
		[ '51.5,', 'no longitude', $ERR_MM_COORD ],
		[ ',1', 'no latitude', $ERR_MM_COORD ],
		[ 'abc,def', 'not numbers', $ERR_MM_COORD ],
		[ '+1,2', 'a leading plus', $ERR_MM_COORD ],
		[ '.5,1', 'no digit before the point', $ERR_MM_COORD ],
		[ '1e2,0', 'an exponent', $ERR_MM_COORD ],
		[ ' 1,2', 'a leading space', $ERR_MM_COORD ],
		[ '1, 2', 'a space after the comma', $ERR_MM_COORD ],
		[ '--1,2', 'two signs', $ERR_MM_COORD ],
		[ '1.2.3,0', 'two points', $ERR_MM_COORD ],
		[ q{1;DROP TABLE cities,2}, 'SQL', $ERR_MM_COORD ],
		[ "M\x{fc}nchen,\x{1F600}", 'non-ASCII text', $ERR_MM_COORD ],
		[ '51', 'one part', $ERR_MM_REVERSE ],
	);
	foreach my $case(@refused) {
		my ($latlng, $name, $error) = @{$case};
		my $cities = $backend->{'cities'} = Domain::CitiesTable->new();
		throws_ok { $backend->reverse_geocode(latlng => $latlng) } $error, "invalid: $name";
		is(scalar(@{$cities->{'sql'}}), 0, 'and the table is not read');
	}

	my @more = (
		[ "\x{661},\x{662}", 'digits of another script' ],
		[ "1\n,2\n", 'a trailing newline' ],
	);
	foreach my $case(@more) {
		my ($latlng, $name) = @{$case};
		my $cities = $backend->{'cities'} = Domain::CitiesTable->new();
		throws_ok { $backend->reverse_geocode(latlng => $latlng) } $ERR_MM_COORD, "invalid: $name";
		is(scalar(@{$cities->{'sql'}}), 0, 'and the table is not read');
	}
};

subtest 'MaxMind->reverse_geocode(lat, lon, long): the other spelling' => sub {
	my $backend = _maxmind();

	foreach my $args([ lat => 0, lon => 0 ], [ lat => 0, long => 0 ], [ { lat => 90, lon => -180 } ]) {
		lives_ok { $backend->reverse_geocode(@{$args}) } 'valid: ' . join(',', map { _show($_) } @{$args});
	}

	# latlng is only preferred when it is true
	foreach my $false('', '0') {
		my $cities = $backend->{'cities'} = Domain::CitiesTable->new();
		$backend->reverse_geocode(latlng => $false, lat => 1, lon => 2);
		like($cities->{'sql'}[0], qr/Latitude - 1\b/, 'latlng ' . _show($false) . ' gives way to lat and lon');
	}

	foreach my $args([ lat => 1 ], [ lon => 1 ], [ long => 1 ], []) {
		throws_ok { $backend->reverse_geocode(@{$args}) } $ERR_MM_REVERSE, 'invalid: ' . (@{$args} ? "only $args->[0]" : 'nothing');
	}
	foreach my $args([ lat => 'x', lon => 1 ], [ lat => 1, lon => 'y' ], [ lat => 1, long => '' ]) {
		throws_ok { $backend->reverse_geocode(@{$args}) } $ERR_MM_COORD, 'invalid: not a number, ' . join(',', map { _show($_) } @{$args});
	}
	throws_ok { $backend->reverse_geocode([]) } $ERR_MM_REVERSE, 'invalid: an arrayref';
};

subtest 'Local->reverse_geocode(latlng): four significant figures' => sub {
	my $hit = '39.46727,-76.823947';

	like(scalar($LOCAL_OBJ->reverse_geocode(latlng => $hit)), $LOCAL_NAME, 'the row itself');
	like(scalar($LOCAL_OBJ->reverse_geocode($hit)), $LOCAL_NAME, 'and as a bare string');
	like(scalar($LOCAL_OBJ->reverse_geocode({ latlng => $hit })), $LOCAL_NAME, 'and in a hashref');
	like(scalar($LOCAL_OBJ->reverse_geocode(lat => '39.46727', lon => '-76.823947')), $LOCAL_NAME, 'and as lat and lon');
	like(scalar($LOCAL_OBJ->reverse_geocode(lat => '39.46727', long => '-76.823947')), $LOCAL_NAME, 'and as lat and long');

	# Both round to 39.47 and -76.82, and the values either side of the edges do not
	like(scalar($LOCAL_OBJ->reverse_geocode('39.47,-76.82')), $LOCAL_NAME, 'in the same rounding, low digits gone');
	like(scalar($LOCAL_OBJ->reverse_geocode('39.4749,-76.8249')), $LOCAL_NAME, 'just inside the rounding');
	ok(!$LOCAL_OBJ->reverse_geocode('39.4751,-76.82'), 'latitude just outside it');
	ok(!$LOCAL_OBJ->reverse_geocode('39.464,-76.82'), 'latitude below it');
	ok(!$LOCAL_OBJ->reverse_geocode('39.47,-76.81'), 'longitude outside it');

	foreach my $elsewhere('0,0', '90,180', '-90,-180', '91,181', '1,2,3') {
		ok(!$LOCAL_OBJ->reverse_geocode($elsewhere), 'nothing there, not an error: ' . _show($elsewhere));
	}

	# The same test as MaxMind applies
	foreach my $junk('abc,def', '51.5,', ',1', "\x{1F600},\x{1F600}", "\x{661},\x{662}", "1\n,2\n", '1e2,3') {
		throws_ok { $LOCAL_OBJ->reverse_geocode($junk) } $ERR_MM_COORD, 'invalid: ' . _show($junk);
	}
	throws_ok { $LOCAL_OBJ->reverse_geocode(lat => 'abc', lon => 1) } $ERR_MM_COORD, 'invalid: as lat and lon as well';

	foreach my $args([], [ latlng => '' ], [ latlng => '0' ], [ 'abc' ], [ lat => 1 ], [ lon => 1 ], [ long => 1 ], [ [] ], [ qw(a b c) ]) {
		throws_ok { $LOCAL_OBJ->reverse_geocode(@{$args}) } $ERR_LOCAL_REVERSE, 'invalid: ' . (join(',', map { _show($_) } @{$args}) || 'nothing');
	}
};

# ---------------------------------------------------------------------------
# The backends' geocode
# ---------------------------------------------------------------------------

subtest 'Local->geocode(location): a country it cannot search on is a miss' => sub {
	my $address = '12 Rue Lepic, Paris, Paris, Elbonia';
	my $found;
	lives_ok { $found = $LOCAL_OBJ->geocode(location => $address) } 'does not die';
	is($found, undef, 'and finds nothing');
};

subtest 'Local->geocode(location): a whole row or at least two commas' => sub {
	my $hit = $LOCAL_OBJ->geocode(location => $LOCAL_ROW);
	is($hit->lat(), $LOCAL_LAT, 'valid: a whole row');
	is($LOCAL_OBJ->geocode($LOCAL_ROW)->lat(), $LOCAL_LAT, 'as a bare string');
	is($LOCAL_OBJ->geocode({ location => $LOCAL_ROW })->lat(), $LOCAL_LAT, 'in a hashref');
	is($LOCAL_OBJ->geocode(lc($LOCAL_ROW))->lat(), $LOCAL_LAT, 'in lower case');
	is($LOCAL_OBJ->geocode(uc($LOCAL_ROW))->lat(), $LOCAL_LAT, 'in upper case');
	(my $usa = $LOCAL_ROW) =~ s/US$/USA/;
	is($LOCAL_OBJ->geocode($usa)->lat(), $LOCAL_LAT, 'USA is the same as US');

	foreach my $args([], [ undef ], [ '' ], [ '0' ], [ location => undef ], [ location => '' ], [ location => '0' ], [ {} ]) {
		throws_ok { $LOCAL_OBJ->geocode(@{$args}) } $ERR_LOCAL_LOC, 'invalid: ' . (join(',', map { _show($_) } @{$args}) || 'nothing');
	}
	foreach my $args([ [] ], [ qw(a b c) ]) {
		throws_ok { $LOCAL_OBJ->geocode(@{$args}) } $ERR_LOCAL_SHAPE, 'invalid: ' . join(',', map { _show($_) } @{$args});
	}

	# Whether the search goes on is whether the address parser gets the string
	my $parses = 0;
	mock('Lingua::EN::AddressParse', 'parse', sub { $parses++; return 1 });
	my @commas = (
		[ 'Road',            0, 'no comma' ],
		[ 'Road, GB',        0, 'one comma' ],
		[ 'Road,,GB',        0, 'two commas with nothing between them' ],
		[ 'Road, ,GB',       1, 'two commas with one character between them' ],
		[ 'Road, Town, GB',  1, 'two commas' ],
	);
	foreach my $case(@commas) {
		my ($location, $want, $name) = @{$case};
		$CACHE->clear();
		$parses = 0;
		is(scalar($LOCAL_OBJ->geocode(location => $location)), undef, "$name: nothing found");
		is($parses, $want, "$name: " . ($want ? 'searched' : 'not searched'));
		is($CACHE->size('Local'), 1, "$name: the miss is remembered");
	}
	restore_all();

	# With no parser for the country the last-resort search needs four parts
	$CACHE->clear();
	my $reads = $LOCAL_OBJ->reads();
	$LOCAL_OBJ->geocode(location => 'a,b,c');
	is($LOCAL_OBJ->reads(), $reads, 'three parts in an unknown country: no read');
	$LOCAL_OBJ->geocode(location => 'a,b,c,d');
	is($LOCAL_OBJ->reads(), $reads + 1, 'four parts: a read');
};

subtest 'MaxMind->geocode(location): the partitions of the value' => sub {
	my $backend = _maxmind();

	is($backend->geocode(location => $MM_KNOWN_ADDR)->{'accuracy'}, 'locality', 'valid: a hand-curated location');
	is($backend->reads(), 0, 'without a read');

	foreach my $none('Ramsgate', "M\x{fc}nchen", "\x{1F600}") {
		is(scalar($backend->geocode(location => $none)), undef, 'no comma and no region: nothing, ' . _show($none));
		is($backend->reads(), 0, 'without a read');
	}

	foreach my $args([ undef ], [ '' ], [ '0' ], [ location => undef ], [ location => '' ], [ location => '0' ], [ {} ]) {
		throws_ok { $backend->geocode(@{$args}) } $ERR_MM_LOC, 'invalid: ' . (join(',', map { _show($_) } @{$args}) || 'nothing');
	}
	foreach my $digits('1', '0044') {
		throws_ok { $backend->geocode(location => $digits) } $ERR_MM_INVALID, 'invalid: digits only, ' . _show($digits);
	}
	throws_ok { $backend->geocode([]) } $ERR_MM_SHAPE, 'invalid: an arrayref';
};

subtest 'OpenAddresses->geocode(location): the digest boundary' => sub {
	my $verbatim = $config{'digest_verbatim'};
	my $suffix = 'US';	# Joined on to what comes before it, so it counts

	my $digest_of = sub {
		my ($location) = @_;

		my $backend = _openaddr();
		$backend->geocode(location => $location);
		return $backend->{'openaddr_db'}{'digests'}[0];
	};

	my $at_limit = 'A' x ($verbatim - length($suffix));
	is($digest_of->("$at_limit $suffix"), "$at_limit$suffix", "$verbatim characters: looked up as written");

	my $past_limit = 'A' x ($verbatim - length($suffix) + 1);
	my $digest = $digest_of->("$past_limit $suffix");
	is(length($digest), $verbatim, 'one more: a digest of the same length');
	isnt($digest, "$past_limit$suffix", 'which is not the address');

	# The limit is in bytes of UTF-8: the key has to be the one createdatabase.PL made
	my $two_bytes = (($verbatim - length($suffix)) / 2);
	is($digest_of->(("\x{fc}" x $two_bytes) . " $suffix"), Encode::encode_utf8(("\x{dc}" x $two_bytes) . $suffix), "$verbatim bytes in Latin-1: looked up as its UTF-8, in upper case");
	my $digest_too = $digest_of->(("\x{fc}" x ($two_bytes + 1)) . " $suffix");
	is(length($digest_too), $verbatim, 'one more character: a digest');
	isnt($digest_too, Encode::encode_utf8(("\x{dc}" x ($two_bytes + 1)) . $suffix), 'which is not the address');

	my $three_bytes = "\x{4e2d}" x int(($verbatim - length($suffix)) / 3);
	is($digest_of->("$three_bytes $suffix"), Encode::encode_utf8("$three_bytes$suffix"), 'within the limit, beyond Latin-1: looked up as its UTF-8');
	is(length($digest_of->("$three_bytes\x{4e2d} $suffix")), $verbatim, 'over it: a digest');

	lives_ok { $digest_of->(("\x{4e2d}" x $verbatim) . " $suffix") } 'a long address beyond Latin-1 does not die';
	lives_ok { $digest_of->("12 \x{4e2d}\x{6587} St, Springfield, IL, USA") } 'nor does a whole address with a non-Latin-1 word';

	my $bytes = "M\x{fc}nchen";
	my $chars = $bytes;
	utf8::upgrade($chars);
	is($digest_of->("$chars $suffix"), $digest_of->("$bytes $suffix"), 'one string has one digest, however it is stored');
	isnt($digest_of->("$bytes $suffix"), 'M' . "\x{fc}" . "NCHEN$suffix", 'and the upper case is by character');

	# Values the builder wrote to the shipped database: see create_md5() in createdatabase.PL
	my $backend = _openaddr();
	$backend->_get("L\x{e9}vis, QC, CA");
	is($backend->{'openaddr_db'}{'digests'}[0], "L\xc3\x89VISQCCA", 'an accented address gets the key it was stored under');
	$backend = _openaddr();
	$backend->_get('Washington, DC, US');
	is($backend->{'openaddr_db'}{'digests'}[0], 'WASHINGTONDCUS', 'as does a plain one');
	$backend = _openaddr();
	$backend->_get("\x{17e}a, US");
	is($backend->{'openaddr_db'}{'digests'}[0], "z\xbdAUS", 'and a z with caron goes through the same translation');
};

subtest 'OpenAddresses->new(cache): only get() and set() are asked of it' => sub {
	my $backend = _openaddr();
	my $cache = $backend->{'cache'} = Domain::Cache->new();
	my $row = { latitude => 51.5, longitude => -1.5 };

	$cache->set('LONDONGB', Storable::freeze($row));
	is_deeply($backend->_get('London, GB'), $row, 'a cached row is answered through get(), and thawed');
	is(scalar(@{$backend->{'openaddr_db'}{'digests'}}), 0, 'without reading the table');
	is($backend->_get('Nowhere, GB'), undef, 'nothing cached: nothing found');
	is_deeply($backend->{'openaddr_db'}{'digests'}, [ 'NOWHEREGB' ], 'after reading the table');
};

subtest 'OpenAddresses->geocode(scantext): shorter than six characters is ignored' => sub {
	my $shortest = $config{'scantext_shortest'};

	my $upgraded_umlaut = "\x{fc}";
	utf8::upgrade($upgraded_umlaut);

	# Words are made of word characters, so an emoji is punctuation here: it is
	# dropped, and a text of nothing else leaves nothing to look up
	foreach my $case([ 'a', 1 ], [ $upgraded_umlaut, 1 ], [ "\x{4e2d}", 1 ], [ "\x{1F600}", 0 ]) {
		my ($alphabet, $has_words) = @{$case};
		my $name = _show($alphabet);

		# Spaces split the text, so the last word is left to be looked up with a comma
		my $backend = _openaddr();
		my $short = ($alphabet x ($shortest - 4)) . ' UK';
		is(length($short), $shortest - 1, "$name: one under the limit");
		is(scalar($backend->geocode(scantext => $short)), undef, 'finds nothing');
		is($backend->reads(), 0, 'without a read');

		$backend = _openaddr();
		my $long = ($alphabet x ($shortest - 3)) . ' UK';
		is(length($long), $shortest, "$name: at the limit");
		lives_ok { $backend->geocode(scantext => $long) } 'does not die';
		cmp_ok($backend->reads(), ($has_words ? '>' : '=='), 0, $has_words ? 'and reads the table' : 'and has no word to look up');
	}

	my $backend = _openaddr();
	$backend->geocode(scantext => "M\x{fc}nchen UK");
	ok(!scalar(grep { $_ eq 'NCHENGB' } @{$backend->{'openaddr_db'}{'digests'}}), 'an umlaut does not end a word');
};

# ---------------------------------------------------------------------------
# distance
# ---------------------------------------------------------------------------

subtest 'distance(lat1, lon1, lat2, lon2): the range of each coordinate' => sub {
	my ($lat, $lon, $over) = @config{qw(lat_max lon_max just_over)};

	my @positions = (
		[ 'lat1', 0 ],
		[ 'lon1', 1 ],
		[ 'lat2', 2 ],
		[ 'lon2', 3 ],
	);
	foreach my $position(@positions) {
		my ($name, $index) = @{$position};
		my $limit = ($index % 2) ? $lon : $lat;
		my $error = ($index % 2) ? $ERR_LONGITUDE : $ERR_LATITUDE;
		my @base = (1, 1, 2, 2);

		foreach my $edge($limit, -$limit) {
			my @args = @base;
			$args[$index] = $edge;
			lives_ok { distance(@args) } "valid: $name at $edge";
		}
		foreach my $outside($limit + $over, -$limit - $over) {
			my @args = @base;
			$args[$index] = $outside;
			throws_ok { distance(@args) } $error, "invalid: $name just past the edge, $outside";
		}

		foreach my $bad([ undef, qr/^$name must be defined/ ], [ 'abc', qr/^$name must be numeric/ ], [ '', qr/^$name must be numeric/ ], [ "\x{fc}", qr/^$name must be numeric/ ], [ 'Inf', $error ], [ '-Inf', $error ]) {
			my @args = @base;
			$args[$index] = $bad->[0];
			throws_ok { distance(@args) } $bad->[1], "invalid: $name is " . _show($bad->[0]);
		}

		TODO: {
			local $TODO = 'NaN looks like a number and compares false, so it passes the range check and dies in Math::Complex';
			my @args = @base;
			$args[$index] = 'NaN';
			throws_ok { distance(@args) } $error, "invalid: $name is NaN";
		}
	}

	foreach my $numeric([ '1e1', 'an exponent' ], [ ' 1', 'a leading space' ], [ "1\n", 'a trailing newline' ], [ '+1', 'a leading plus' ], [ '.5', 'no digit before the point' ]) {
		lives_ok { distance($numeric->[0], 0, 0, 0) } "valid: $numeric->[1], which looks like a number";
	}

	throws_ok { distance(0, 0, 1) } qr/Too few arguments/, 'invalid: three coordinates';
	throws_ok { distance(0, 0, 1, 1, 'K', 'extra') } qr/Too many arguments/, 'invalid: six arguments';
};

subtest 'distance(): the combinations at the edges of the globe' => sub {
	my ($lat, $lon, $slack) = @config{qw(lat_max lon_max distance_slack)};

	my @cases = (
		[ [ 0, 0, 0, 0 ], 0, 'the same point' ],
		[ [ $lat, $lon, $lat, $lon ], 0, 'the same corner' ],
		[ [ $lat, 0, -$lat, 0 ], $config{'half_earth_km'}, 'pole to pole' ],
		[ [ 0, 0, 0, $lon ], $config{'half_earth_km'}, 'half way round the equator' ],
		[ [ 0, 0, 0, -$lon ], $config{'half_earth_km'}, 'half way round the other way' ],
		[ [ 0, $lon, 0, -$lon ], 0, 'the two sides of the antimeridian are one place' ],
		[ [ $lat, -$lon, $lat, $lon ], 0, 'latitude at its maximum and longitude at both ends: all the pole' ],
		[ [ $lat, -$lon, -$lat, $lon ], $config{'half_earth_km'}, 'latitude at both ends and longitude at both ends' ],
		[ [ 0, 0, 1, 0 ], $config{'one_degree_km'}, 'one degree of latitude' ],
	);
	foreach my $case(@cases) {
		my ($points, $want, $name) = @{$case};
		cmp_ok(abs(distance(@{$points}, 'K') - $want), '<', $slack, "$name is $want km");
	}
};

subtest 'distance(unit): K, N or M, in either case' => sub {
	my $slack = $config{'distance_slack'};
	my @halfway = (0, 0, 0, $config{'lon_max'});

	my @cases = (
		[ 'K', 'half_earth_km' ],
		[ 'k', 'half_earth_km' ],
		[ 'N', 'half_earth_nm' ],
		[ 'n', 'half_earth_nm' ],
		[ 'M', 'half_earth_miles' ],
		[ 'm', 'half_earth_miles' ],
		[ undef, 'half_earth_miles' ],
		[ '', 'half_earth_miles' ],
		[ '0', 'half_earth_miles' ],
	);
	foreach my $case(@cases) {
		my ($unit, $key) = @{$case};
		cmp_ok(abs(distance(@halfway, $unit) - $config{$key}), '<', $slack, 'valid: ' . _show($unit) . " is $key");
	}
	cmp_ok(abs(distance(@halfway) - $config{'half_earth_miles'}), '<', $slack, 'absent: miles');

	foreach my $bad('X', 'KM', 'kilometres', ' K', 'K ', '1', "\x{fc}", "\x{1F600}") {
		throws_ok { distance(@halfway, $bad) } $ERR_UNIT, 'invalid: ' . _show($bad);
	}

	is(distance(0, 0, 0, 0, 'X'), 0, 'the same point is 0 before the unit is looked at');

	TODO: {
		local $TODO = 'the unit check uses $, which lets a trailing newline through, and the unit then falls through to miles';
		foreach my $bad("K\n", "N\n") {
			throws_ok { distance(@halfway, $bad) } $ERR_UNIT, 'invalid: ' . _show($bad);
		}
	}
};

# ---------------------------------------------------------------------------
# MissCache
# ---------------------------------------------------------------------------

subtest 'MissCache->scope_for(backend, dataset...): any number of parts' => sub {
	is($CACHE->scope_for(), '', 'none');
	is($CACHE->scope_for('Local'), 'Local', 'one');
	is($CACHE->scope_for('OpenAddresses', '/data'), "OpenAddresses\0/data", 'two, joined by a zero byte');
	is($CACHE->scope_for('a', 'b', 'c'), "a\0b\0c", 'three');
	is($CACHE->scope_for('a', ''), "a\0", 'an empty data set is not no data set');
	is($CACHE->scope_for("M\x{fc}nchen", "\x{1F600}"), "M\x{fc}nchen\0\x{1F600}", 'non-ASCII parts are kept');
};

subtest 'MissCache: the domain of a key' => sub {
	my @keys = (
		[ '', 'the empty string' ],
		[ '0', 'a false string' ],
		[ 'k' x $config{'long_string'}, 'a very long key' ],
		[ "a\0b", 'a zero byte' ],
		[ "M\x{fc}nchen", 'an umlaut' ],
		[ "\x{1F600}", 'an emoji' ],
		[ "\x{202E}Kent", 'a right-to-left override' ],
	);
	foreach my $case(@keys) {
		my ($key, $name) = @{$case};
		$CACHE->clear();
		is($CACHE->missed('scope', $key), 0, "$name: not remembered yet");
		is($CACHE->remember('scope', $key), 1, "$name: remember is true");
		is($CACHE->missed('scope', $key), 1, "$name: remembered");
		is($CACHE->size('scope'), 1, "$name: one entry");
		is($CACHE->remember('scope', $key), 1, "$name: remember again is true");
		is($CACHE->size('scope'), 1, "$name: still one entry");
		is($CACHE->forget('scope', $key), 1, "$name: forget is true");
		is($CACHE->forget('scope', $key), 0, "$name: forget again is false");
		is($CACHE->size(), 0, "$name: the scope has gone too");
	}

	$CACHE->clear();
	$CACHE->remember('scope', "M\x{fc}nchen");
	is($CACHE->missed('scope', "M\xc3\xbcnchen"), 0, 'characters are not the same key as their UTF-8 bytes');
	my $upgraded = "M\x{fc}nchen";
	utf8::upgrade($upgraded);
	is($CACHE->missed('scope', $upgraded), 1, 'and how perl stores a string makes no difference');

	is($CACHE->missed('no such scope', 'k'), 0, 'missed: an unknown scope is false');
	is($CACHE->forget('no such scope', 'k'), 0, 'forget: an unknown scope is false');
	is($CACHE->missed('scope', 'no such key'), 0, 'missed: an unknown key is false');
	is($CACHE->forget('scope', 'no such key'), 0, 'forget: an unknown key is false');
};

subtest 'MissCache->clear(scope) and size(scope): whole parts of a scope' => sub {
	my $load = sub {
		$CACHE->clear();
		$CACHE->remember('OpenAddresses', 'k');
		$CACHE->remember($CACHE->scope_for('OpenAddresses', '/a'), 'k');
		$CACHE->remember($CACHE->scope_for('OpenAddresses', '/b'), 'k');
		$CACHE->remember('OpenAddressesX', 'k');
		return;
	};

	$load->();
	is($CACHE->size(), 4, 'absent: every scope');
	is($CACHE->size('OpenAddresses'), 3, 'a scope and those below it');
	is($CACHE->size($CACHE->scope_for('OpenAddresses', '/a')), 1, 'one data set');
	is($CACHE->size('OpenAddressesX'), 1, 'one character more is another scope');
	is($CACHE->size('OpenAddresse'), 0, 'one character less matches nothing');
	is($CACHE->size(''), 0, 'the empty scope holds nothing here');
	is($CACHE->size("\x{1F600}"), 0, 'neither does a scope that was never used');

	foreach my $none('OpenAddresse', '', 'Nonsense', "\x{1F600}") {
		$load->();
		is($CACHE->clear($none), 1, 'clear is true for ' . _show($none));
		is($CACHE->size(), 4, 'and it forgets nothing');
	}

	$load->();
	$CACHE->clear($CACHE->scope_for('OpenAddresses', '/a'));
	is($CACHE->size(), 3, 'one data set goes');

	$load->();
	$CACHE->clear('OpenAddresses');
	is($CACHE->size(), 1, 'a scope goes with those below it, and not the longer name');

	$load->();
	is($CACHE->clear(undef), 1, 'undef is true');
	is($CACHE->size(), 0, 'and is the same as absent');

	$CACHE->clear();
	$CACHE->remember('', 'k');
	is($CACHE->size(''), 1, 'the empty string is a scope like any other');
	$CACHE->clear('');
	is($CACHE->size(), 0, 'and can be cleared like any other');
};

subtest 'MissCache->expires_after(seconds): a whole number of seconds' => sub {
	my $original = $CACHE->expires_after();
	is($original, $config{'an_hour'}, 'the default is an hour');

	foreach my $good('0', '1', $config{'an_hour'}, '007', '99999999999999999999') {
		is($CACHE->expires_after($good), $good, 'valid: ' . _show($good));
		is($CACHE->expires_after(), $good, 'and it is the setting');
		$CACHE->expires_after($original);
	}
	is($CACHE->expires_after(undef), $original, 'undef asks for the setting, and leaves it alone');

	foreach my $bad('-1', '1.5', '1.0', '1e3', '0x10', 'abc', '', ' 1', '1 ', "\x{fc}", "\x{1F600}", []) {
		throws_ok { $CACHE->expires_after($bad) } $ERR_EXPIRES, 'invalid: ' . _show($bad);
		is($CACHE->expires_after(), $original, 'and the setting is left as it was');
	}

	foreach my $bad("5\n", "\x{661}") {
		throws_ok { $CACHE->expires_after($bad) } $ERR_EXPIRES, 'invalid: ' . _show($bad);
		is($CACHE->expires_after(), $original, 'and the setting is left as it was');
	}

	# The lower boundary, combined with what it does to an entry
	$CACHE->clear();
	$CACHE->expires_after(0);
	$CACHE->remember('scope', 'k');
	is($CACHE->missed('scope', 'k'), 0, '0: an entry has expired as soon as it is recorded');
	is($CACHE->size(), 0, '0: nothing is left in the cache');
	$CACHE->expires_after($config{'an_hour'});
	$CACHE->remember('scope', 'k');
	is($CACHE->missed('scope', 'k'), 1, 'not 0: the entry lives');

	$CACHE->expires_after($original);
	$CACHE->clear();
};

# ---------------------------------------------------------------------------
# provenance and clear_miss_cache
# ---------------------------------------------------------------------------

subtest 'provenance(point): anything hash-based' => sub {
	my $geo = _facade();

	foreach my $not_a_result(undef, '', 0, 'a string', [], \'x', sub { }, bless([], 'Domain::Array')) {
		my @list = $geo->provenance($not_a_result);
		is(scalar(@list), 0, 'not a result: empty list, ' . _show($not_a_result));
		is_deeply(scalar($geo->provenance($not_a_result)), {}, 'and an empty hashref');
	}
	is_deeply(scalar($GCF->provenance()), {}, 'absent: an empty hashref');

	my @no_keys = $geo->provenance({});
	is_deeply(\@no_keys, [ undef, undef, undef, undef ], 'an empty hash: four undefs, nothing guessed');

	my @cases = (
		[ { database => 'Geo::Coder::Free::Local' }, 'Local', 'the prefix is removed' ],
		[ { database => 'MaxMind' }, 'MaxMind', 'no prefix: unchanged' ],
		[ { database => 'Geo::Coder::Free::' }, '', 'the prefix alone leaves an empty name' ],
		[ { database => 'A::Geo::Coder::Free::B' }, 'A::Geo::Coder::Free::B', 'only a leading prefix is removed' ],
		[ bless({ database => 'Blessed' }, 'Domain::Hash'), 'Blessed', 'any class that is a hash' ],
	);
	foreach my $case(@cases) {
		my ($point, $want, $name) = @{$case};
		is($geo->provenance($point)->{'backend'}, $want, $name);
	}

	# Not checked: a confidence is reported as it is held
	foreach my $confidence(0, 1, 0.5, 2, -1) {
		is($geo->provenance({ confidence => $confidence })->{'confidence'}, $confidence, "confidence $confidence is passed through");
	}
};

subtest 'clear_miss_cache(scope): any string' => sub {
	my $load = sub {
		$CACHE->clear();
		$CACHE->remember('Local', 'k');
		$CACHE->remember('MaxMind', 'k');
		return;
	};

	my @cases = (
		[ [], 0, 'absent: everything' ],
		[ [ undef ], 0, 'undef: everything' ],
		[ [ 'Local' ], 1, 'a backend: that one' ],
		[ [ 'Nonsense' ], 2, 'not a backend: nothing, and not an error' ],
		[ [ '' ], 2, 'empty: nothing' ],
		[ [ "\x{1F600}" ], 2, 'non-ASCII: nothing' ],
	);
	foreach my $case(@cases) {
		my ($args, $left, $name) = @{$case};
		$load->();
		is($GCF->clear_miss_cache(@{$args}), 1, "$name: true");
		is($CACHE->size(), $left, "$name: leaves $left");
	}

	my $geo = _facade();
	$load->();
	is($geo->clear_miss_cache('Local'), 1, 'on an object');
	is($CACHE->size(), 1, 'the scope is still the argument after the invocant');
	$CACHE->clear();
};

# ---------------------------------------------------------------------------
# ua, reads, run
# ---------------------------------------------------------------------------

subtest 'ua() and reads(): take nothing of interest' => sub {
	foreach my $class($GCF, $LOCAL, $MM, $OA) {
		my @rc = $class->can('ua')->(undef, 'any', 'arguments');
		is(scalar(@rc), 0, "$class\::ua answers nothing");
	}

	foreach my $backend(_openaddr(), _maxmind()) {
		is($backend->reads(), 0, ref($backend) . ': 0 for a new object');
	}
	cmp_ok($LOCAL_OBJ->reads(), '>=', 0, 'Local: never negative');
};

subtest 'run(words): joined with spaces into one location' => sub {
	throws_ok { $GCF->run() } $ERR_FAILED, 'none: the empty string, which finds nothing';
	throws_ok { $GCF->run('0044') } $ERR_INVALID_LOC, 'one word of digits';

	my $location;
	mock($MM, 'geocode', sub { $location = $_[1]->{'location'}; return { lat => 1, long => 2 } });

	my $output = '';
	{
		local *STDOUT;
		open(STDOUT, '>', \$output) or die "STDOUT: $!";
		$GCF->run('1', '2');
	}
	is($location, '1 2', 'two words of digits are one valid location');
	like($output, qr/lat/, 'and what was found is printed');

	restore_all();
};

$CACHE->clear();

done_testing();
