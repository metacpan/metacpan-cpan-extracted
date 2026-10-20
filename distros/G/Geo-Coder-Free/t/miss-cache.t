#!perl -w

# The miss cache, and the three backends that use it.
#
# The unit tests fix the contract of Geo::Coder::Free::MissCache on its own.
# The backend tests are behavioural: they count the work a backend does (a
# database read, a dataset search) and assert that a lookup remembered as a
# miss is not repeated, that a second instance sees the same memory, and that
# clearing it makes the work happen again.  A backend that records a miss but
# never consults the cache fails the "did not do the work again" assertion; a
# backend that consults but never records fails the first "was remembered".

use strict;
use warnings;

use File::Temp qw(tempdir);
use Geo::Hash;
use Test::Most;

use Geo::Coder::Free;
use Geo::Coder::Free::Local;
use Geo::Coder::Free::MaxMind;
use Geo::Coder::Free::MissCache;
use Geo::Coder::Free::OpenAddresses;

my $Cache = 'Geo::Coder::Free::MissCache';

$Cache->clear();
is($Cache->size, 0, 'the cache starts empty');

# ---------------------------------------------------------------------------
# The cache itself
# ---------------------------------------------------------------------------

subtest 'A miss is remembered per scope and can be forgotten' => sub {
	$Cache->clear();

	ok(!$Cache->missed('scope', 'key'), 'an unknown key is not a miss');

	$Cache->remember('scope', 'key');
	ok($Cache->missed('scope', 'key'), 'a remembered key is a miss');
	ok(!$Cache->missed('other', 'key'), 'the same key in another scope is not');
	ok(!$Cache->missed('scope', 'other'), 'another key in the scope is not');

	is($Cache->size, 1, 'one miss is held');
	is($Cache->size('scope'), 1, 'and one in its scope');
	is($Cache->size('other'), 0, 'none in the other');

	ok($Cache->forget('scope', 'key'), 'forget removes the entry');
	ok(!$Cache->missed('scope', 'key'), 'and it is gone');
	ok(!$Cache->forget('scope', 'key'), 'forgetting it twice reports nothing to do');
	is($Cache->size, 0, 'the cache is empty again');
};

subtest 'Clearing a backend clears every data set it opened' => sub {
	$Cache->clear();

	my $oa_one = $Cache->scope_for('OpenAddresses', '/one');
	my $oa_two = $Cache->scope_for('OpenAddresses', '/two');
	isnt($oa_one, $oa_two, 'two OpenAddresses directories are two scopes');

	$Cache->remember($oa_one, 'address');
	$Cache->remember($oa_two, 'address');
	$Cache->remember($Cache->scope_for('Local'), 'address');
	$Cache->remember($Cache->scope_for('MaxMind', '/install'), 'address');
	is($Cache->size, 4, 'four misses are held');

	$Cache->clear('OpenAddresses');
	is($Cache->size, 2, 'clearing OpenAddresses leaves the other backends alone');
	ok(!$Cache->missed($oa_one, 'address'), 'the first data set was cleared');
	ok(!$Cache->missed($oa_two, 'address'), 'the second data set was cleared');
	ok($Cache->missed($Cache->scope_for('Local'), 'address'), 'Local was not');
	ok($Cache->missed($Cache->scope_for('MaxMind', '/install'), 'address'), 'MaxMind was not');

	$Cache->clear();
	is($Cache->size, 0, 'clearing everything empties the cache');
};

subtest 'Entries expire' => sub {
	my $was = $Cache->expires_after();
	$Cache->clear();
	$Cache->expires_after(0);

	$Cache->remember('scope', 'key');
	ok(!$Cache->missed('scope', 'key'), 'a zero lifetime expires as it is recorded');
	is($Cache->size, 0, 'and nothing is left behind');

	$Cache->expires_after($was);
	is($Cache->expires_after(), $was, 'the setting can be put back');

	throws_ok { $Cache->expires_after(-1) } qr/non-negative/,
		'a negative lifetime is refused';
	throws_ok { $Cache->expires_after('soon') } qr/non-negative/,
		'a lifetime that is not a number is refused';
	is($Cache->expires_after(), $was, 'neither change took effect');
};

subtest 'The facade clears the whole cache, or one backend' => sub {
	$Cache->clear();
	$Cache->remember($Cache->scope_for('Local'), 'address');
	$Cache->remember($Cache->scope_for('MaxMind', '/install'), 'address');
	is($Cache->size, 2, 'two backends hold a miss');

	my $geo = Geo::Coder::Free->new();
	is($geo->clear_miss_cache('Local'), 1, 'an instance can clear one backend');
	is($Cache->size, 1, 'and only that backend');

	is(Geo::Coder::Free->clear_miss_cache(), 1, 'the class clears the rest');
	is($Cache->size, 0, 'and the cache is empty');
};

# ---------------------------------------------------------------------------
# OpenAddresses: the database is read once per address
# ---------------------------------------------------------------------------

{
	package CountingOpenAddr;

	sub new {
		return bless { calls => 0, geohash => undef }, shift;
	}

	sub calls {
		return $_[0]->{'calls'};
	}

	sub geohash {
		my $self = shift;

		$self->{'calls'}++;
		return $self->{'geohash'};
	}
}

subtest 'OpenAddresses does not read the database twice for the same miss' => sub {
	$Cache->clear();

	my $dir = tempdir(CLEANUP => 1);
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $dir);
	my $db = CountingOpenAddr->new();
	$oa->{'openaddr_db'} = $db;

	my @address = ('No Such Road', 'No Such Town', 'ZZ');

	is($oa->_get(@address), undef, 'the address is not in the database');
	my $first = $db->calls();
	cmp_ok($first, '>', 0, 'the first lookup read the database');
	is($oa->reads(), 1, 'and the backend reports the one read it made');

	is($oa->_get(@address), undef, 'the second lookup misses as well');
	is($db->calls(), $first, 'but did not read the database again');
	is($oa->reads(), 1, 'and reports no read for the cached miss');

	Geo::Coder::Free->clear_miss_cache('OpenAddresses');
	is($oa->_get(@address), undef, 'after clearing the cache it misses again');
	cmp_ok($db->calls(), '>', $first, 'and reads the database again');
	is($oa->reads(), 2, 'which the backend reports as a second read');

	# A miss belongs to the data set that produced it: another OpenAddresses
	# directory holds different data, so its answer must not be hidden by the
	# first directory's absence.
	my $other_dir = tempdir(CLEANUP => 1);
	my $other = Geo::Coder::Free::OpenAddresses->new(openaddr => $other_dir);
	my $other_db = CountingOpenAddr->new();
	$other_db->{'geohash'} = Geo::Hash->new()->encode(51.1, 1.4);
	$other->{'openaddr_db'} = $other_db;
	isa_ok($other->_get(@address), 'Geo::Location::Point',
		'another data set still answers for an address this one missed');
	is($other_db->calls(), 1, 'and read its own database to do so');
	is($other->reads(), 1, 'and reports that read against its own object');
	is($oa->reads(), 2, 'which did not become a read of this data set');

	# A remembered miss must not outlive its truth: once the data has an
	# answer, a hit is returned even though the same address was missed.
	$db->{'geohash'} = Geo::Hash->new()->encode(51.1, 1.4);
	is($oa->_get(@address), undef, 'the miss is still remembered');
	is($oa->reads(), 2, 'and still costs no read');
	Geo::Coder::Free->clear_miss_cache('OpenAddresses');
	my $hit = $oa->_get(@address);
	isa_ok($hit, 'Geo::Location::Point', 'a hit is returned after the cache is cleared');
	is($oa->reads(), 3, 'the hit read the database again, and says so');
};

# ---------------------------------------------------------------------------
# Local: the dataset is searched once per address, for every instance
# ---------------------------------------------------------------------------

subtest 'Local does not search the dataset twice for the same miss' => sub {
	$Cache->clear();

	my $local = Geo::Coder::Free::Local->new();
	# Four parts, so the last-resort "road, city, state, country" search is
	# reached.  With three, only the optional Geo::Address::Parser searches,
	# and without it (bare.yml) the miss is recorded having read nothing.
	my $location = 'No Such Road, No Such Town, Kent, GB';

	is($local->geocode(location => $location), undef, 'the address is not in the dataset');
	my $first = $local->reads();
	cmp_ok($first, '>', 0, 'the first lookup searched the dataset, and the backend reports it');

	is($local->geocode(location => $location), undef, 'the second lookup misses as well');
	is($local->reads(), $first, 'but did not search the dataset again, and reports no read');

	# The cache is the process's, not the instance's: a second Local object
	# knows what the first one has already failed to find, so it has nothing to
	# search for and reports no read of its own.
	my $other = Geo::Coder::Free::Local->new();
	is($other->reads(), 0, 'a fresh instance has read nothing');
	is($other->geocode(location => $location), undef, 'another instance misses too');
	is($other->reads(), 0, 'and shares the miss rather than searching');

	Geo::Coder::Free->clear_miss_cache('Local');
	is($other->geocode(location => $location), undef, 'after clearing it searches again');
	cmp_ok($other->reads(), '>', 0, 'and reports the search it made');

	# A hit is cached as well, and a hit answered from that cache is no read
	# either: the second call is the same object, and reports no new read.
	my $known = 'Ramsgate Station, Station Approach Rd, Ramsgate, Kent, GB';
	my $point = $local->geocode(location => $known);
	isa_ok($point, 'Geo::Location::Point', 'a curated address resolves');
	my $reads = $local->reads();
	is($local->geocode(location => $known), $point, 'the second call is the cached point');
	is($local->reads(), $reads, 'and reports no read for the cached hit');
};

# ---------------------------------------------------------------------------
# MaxMind: no second query for a town that is not there
# ---------------------------------------------------------------------------

{
	package CountingCities;

	sub new {
		my ($class, $real) = @_;

		return bless { real => $real, calls => 0 }, $class;
	}

	sub calls {
		return $_[0]->{'calls'};
	}

	sub fetchrow_hashref {
		my $self = shift;

		$self->{'calls'}++;
		return $self->{'real'}->fetchrow_hashref(@_);
	}
}

subtest 'MaxMind does not query the cities database twice for the same miss' => sub {
	plan skip_all => 'the MaxMind cities database is not installed'
		unless -f 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql';

	$Cache->clear();

	my $mm = Geo::Coder::Free::MaxMind->new();
	my $location = 'Nowhere At All, Nowhere, GB';

	is($mm->geocode($location), undef, 'the town is not in the database');
	cmp_ok($mm->reads(), '>', 0, 'a lookup that read the databases reports those reads');

	# The first lookup has opened the cities table; count the queries from
	# here on.  Nothing else about the object changes.
	my $counting = CountingCities->new($mm->{'cities'});
	$mm->{'cities'} = $counting;

	$Cache->clear('MaxMind');
	is($mm->geocode($location), undef, 'the lookup misses again');
	my $first = $counting->calls();
	cmp_ok($first, '>', 0, 'the lookup queried the cities table');
	my $reads = $mm->reads();

	is($mm->geocode($location), undef, 'the next lookup misses as well');
	is($counting->calls(), $first, 'but did not query the cities table again');
	is($mm->reads(), $reads, 'and reports no read for the cached miss');

	Geo::Coder::Free->clear_miss_cache('MaxMind');
	is($mm->geocode($location), undef, 'after clearing the cache it misses again');
	cmp_ok($counting->calls(), '>', $first, 'and queries the table again');
	cmp_ok($mm->reads(), '>', $reads, 'which the backend reports as further reads');
};

# ---------------------------------------------------------------------------
# geocode_many(): a value is a lookup only if a backend read for it
#
# The three reads() counters above are what the count is built from.  Here a
# backend whose reads are known exactly is put behind a real facade, so that
# geocode_many() and the facade's own read accounting are the code under test
# and only the backend and the single lookup they delegate to are doubles.
# ---------------------------------------------------------------------------

{
	package ReportingBackend;

	# answers: location => { point => ..., cached => 1 } - 'cached' means the
	# value is answered without reading, and is what the counter must not move
	# for.
	sub new {
		my ($class, %answers) = @_;

		return bless { reads => 0, answers => { %answers } }, $class;
	}

	sub reads {
		return $_[0]->{'reads'};
	}

	sub geocode {
		my ($self, $params) = @_;
		$params = { %{$params} } if ref($params) eq 'HASH';
		my $answer = $self->{'answers'}{ $params->{'location'} } // {};

		$self->{'reads'}++ unless $answer->{'cached'};
		return $answer->{'point'};
	}
}

subtest 'geocode_many counts the values that made a backend read' => sub {
	my $point = Geo::Location::Point->new({ lat => 1, long => 2 });
	my $backend = ReportingBackend->new(
		'Read, Read, GB'       => { point => $point },
		'Cached, Cached, GB'   => { point => $point, cached => 1 },
		'Missing, Missing, GB' => {},
	);

	# A real facade, asked for no OpenAddresses data, with the reporting backend
	# in place of the MaxMind one it would have built: the guards, the accounting
	# and the delegation to the backend are the shipped code.
	local $ENV{'OPENADDR_HOME'};
	delete $ENV{'OPENADDR_HOME'};
	my $geo = Geo::Coder::Free->new();
	delete $geo->{'openaddr'};
	delete $geo->{'local'};
	$geo->{'maxmind'} = $backend;

	my $batch = $geo->geocode_many(
		['Read, Read, GB', 'Cached, Cached, GB', 'Missing, Missing, GB', 'Read, Read, GB'],
		on_error => 'undef');

	is($batch->{'lookups'}, 2,
		'the read and the miss are counted; the cached answer and the repeat are not');
	is($batch->{'resolved'}, 2, 'the read and the cached answer resolved');
	is($batch->{'unresolved'}, 1, 'the miss did not');
	is($backend->reads(), 2, 'and the backend was asked once for each counted value');

	# The same accounting per backend, in the vocabulary provenance() uses: the
	# stand-in sits in the facade's MaxMind slot, so that is the name it is
	# reported under, and the answer it gave without reading leaves the count
	# where it was.  A caller reading this can tell a backend that read from one
	# that answered from a cache, which the batch's single lookup count cannot.
	is_deeply($batch->{'reads'}, { MaxMind => 2 },
		'the reads are reported per backend, and a cached answer is no read');

	# A value the module refuses before any backend is not a lookup even if a
	# backend would have reported a read for it: the backend is never asked.
	my $before = $backend->reads();
	my $refused = $geo->geocode_many(['0044'], on_error => 'undef');
	is($refused->{'lookups'}, 0, 'a refused value is not a lookup');
	is($backend->reads(), $before, 'and never reached the backend');
};

subtest 'geocode_many reports a read against each backend that made one' => sub {
	my $point = Geo::Location::Point->new({ lat => 1, long => 2 });

	# All three backends are stand-ins with known read counts, in a real facade,
	# so that the delegation order, the accounting and the naming are the code
	# under test.  'Read, Read, GB' is in none of their data: OpenAddresses and
	# Local each read and miss, and MaxMind reads and finds it.  'Cached, Cached,
	# GB' is OpenAddresses' to miss and Local's to answer without reading, so the
	# backend that answered and the backends that read are told apart by the
	# answer itself rather than by this test.
	my $openaddr = ReportingBackend->new('Read, Read, GB' => {}, 'Cached, Cached, GB' => {});
	my $local    = ReportingBackend->new('Cached, Cached, GB' => { point => $point, cached => 1 });
	my $maxmind  = ReportingBackend->new('Read, Read, GB' => { point => $point });

	local $ENV{'OPENADDR_HOME'};
	delete $ENV{'OPENADDR_HOME'};
	my $geo = Geo::Coder::Free->new();
	$geo->{'openaddr'} = $openaddr;
	$geo->{'local'}    = $local;
	$geo->{'maxmind'}  = $maxmind;

	my $batch = $geo->geocode_many(['Read, Read, GB', 'Cached, Cached, GB'], on_error => 'undef');

	# Two values, two of them worth a lookup even though four reads were made:
	# the count a caller caps its work by is the values, and the reads say which
	# backend did the work for them.
	is($batch->{'lookups'}, 2, 'both values cost a lookup');
	is_deeply($batch->{'reads'},
		{ 'OpenAddresses' => 2, 'Local' => 1, 'MaxMind' => 1 },
		'and each backend is credited with the reads it made, by its own name');

	# The names are the vocabulary provenance() uses, so a caller can put the
	# backend that read a value beside the backend a result came from.
	is_deeply([sort keys %{$batch->{'reads'}}], ['Local', 'MaxMind', 'OpenAddresses'],
		'the three backends are named as provenance() names them');
	is($local->reads(), 1, 'Local read for the value it did not have');
	is($maxmind->reads(), 1, 'MaxMind read for the one it found');
	is($openaddr->reads(), 2, 'and OpenAddresses read for both, having neither');
};

subtest 'geocode_many excludes a value answered from the miss cache' => sub {
	plan skip_all => 'the MaxMind cities database is not installed'
		unless -f 'lib/Geo/Coder/Free/MaxMind/databases/cities.sql';

	$Cache->clear();

	# No openaddr: the facade asks MaxMind and nothing else, and this value is
	# not in its data.
	my $geo = Geo::Coder::Free->new();
	my @places = ('Nowhere At All, Nowhere, GB');

	is($geo->geocode_many(\@places, on_error => 'undef')->{'lookups'}, 1,
		'the first batch reads the databases for the value');

	my $cached = $geo->geocode_many(\@places, on_error => 'undef');
	is($cached->{'lookups'}, 0,
		'the second batch is answered from the miss cache and counts no read');
	is($cached->{'reads'}{'MaxMind'}, 0,
		'and the backend that read for the first batch is reported with none');

	Geo::Coder::Free->clear_miss_cache('MaxMind');
	is($geo->geocode_many(\@places, on_error => 'undef')->{'lookups'}, 1,
		'and clearing the cache makes the read happen again');
};

done_testing();
