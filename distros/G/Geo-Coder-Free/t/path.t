#!/usr/bin/env perl

# path.t — Control-Flow Graph (CFG) path-coverage tests.
#
# Each subtest is labelled with the path it covers (e.g. na_1).
# Together they exercise every unique branch in the key functions.
#
# Path identifiers:
#   na_*    — _normalize_args()  (shared by GCF and Local)
#   new_*   — Geo::Coder::Free::new()
#   gc_*    — Geo::Coder::Free::geocode()
#   rgc_*   — Geo::Coder::Free::reverse_geocode()
#   lgc_*   — Geo::Coder::Free::Local::geocode()
#   lrgc_*  — Geo::Coder::Free::Local::reverse_geocode()
#   srch_*  — Local::_search() confidence branches
#   norm_*  — Geo::Coder::Free::_normalize()
#   abbr_*  — Geo::Coder::Free::_abbreviate()
#   ngram_* — Geo::Coder::Free::_find_word_ngrams()
#   geo_*   — Local::_find_geographic_centres()
#   ttls_*  — Local::_to_two_letter_state()

use strict;
use warnings;

use File::Temp qw(tempdir);
use Scalar::Util qw(blessed refaddr);
use Test::Most;
use Test::Mockingbird qw(mock restore_all);

local $ENV{OPENADDR_HOME}    = '';
local $ENV{WHOSONFIRST_HOME} = '';

use_ok 'Geo::Coder::Free';
use_ok 'Geo::Coder::Free::Local';
use_ok 'Geo::Coder::Free::OpenAddresses';
use_ok 'Geo::Coder::Free::Utils';

# ------------------------------------------------------------------
# Re-establish default MaxMind stubs after any restore_all() call.
# Without these, geocode() reaches the real MaxMind which has no DB.
# ------------------------------------------------------------------
sub _remock_maxmind {
	mock('Geo::Coder::Free::MaxMind', 'geocode',         sub { return undef });
	mock('Geo::Coder::Free::MaxMind', 'reverse_geocode', sub { return undef });
}

_remock_maxmind();

# ALL_SAINTS_LOC must include the name prefix so it matches the index key built by
# Geo::Location::Point->as_string() for that row in __DATA__.
use constant {
	ALL_SAINTS_LOC  => 'All Saints Episcopal Church, 203 E Chatsworth Rd, Reisterstown, Baltimore, MD, US',
	ALL_SAINTS_LAT  => 39.467270,
	ALL_SAINTS_LON  => -76.823947,

	NCBI_LAT        => 38.99516556,
	NCBI_LON        => -77.09943963,

	RAMSGATE_LAT    => 51.334522,
	RAMSGATE_LON    => 1.314417,
};

# Local object — __DATA__ is a one-shot filehandle; create exactly one instance.
my $LOCAL_OBJ = Geo::Coder::Free::Local->new();

# A mock GLP to return from MaxMind stubs when a successful hit is required.
my $MOCK_GLP = Geo::Location::Point->new({ lat => 51.3341, long => -1.4159 });

# =======================================================================
# 1. _normalize_args (paths na_1..na_6)
# =======================================================================

subtest '_normalize_args — na_1: hashref arg → flat hash' => sub {
	my $geo = Geo::Coder::Free->new();
	my $r   = $geo->geocode({ location => ALL_SAINTS_LOC });
	ok(!ref($r) || ref($r) eq 'Geo::Location::Point', 'hashref arg accepted');
};

subtest '_normalize_args — na_2: non-hash ref → croak' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode([])     } qr/Usage/, 'arrayref → croak';
	throws_ok { $geo->geocode(sub {}) } qr/Usage/, 'coderef → croak';
	throws_ok { $geo->geocode(\42)    } qr/Usage/, 'scalarref → croak';
};

subtest '_normalize_args — na_3: even-count key-val list returned as-is' => sub {
	my $geo = Geo::Coder::Free->new();
	my $r   = $geo->geocode(location => ALL_SAINTS_LOC);
	ok(!defined($r) || ref($r) eq 'Geo::Location::Point', 'even-count list accepted');
};

subtest '_normalize_args — na_4: single bare string → wrapped as (location => $str)' => sub {
	my $geo = Geo::Coder::Free->new();
	my $r   = $geo->geocode(ALL_SAINTS_LOC);
	ok(!defined($r) || ref($r) eq 'Geo::Location::Point', 'bare string accepted');
};

subtest '_normalize_args — na_5: odd-count > 1 args → croak (M7 fix)' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode('location', 'Foo', 'extra') } qr/Usage/, '3-arg list → croak';
	throws_ok { $geo->geocode('a', 'b', 'c', 'd', 'e')   } qr/Usage/, '5-arg list → croak';
};

subtest '_normalize_args — na_6: empty arg list → croak from downstream usage guard' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode() } qr/Usage/, 'no args → croak';
};

# =======================================================================
# 2. Geo::Coder::Free::new() (paths new_1..new_7)
# =======================================================================

subtest 'new() — new_1: function call with non-empty params → carp and return undef' => sub {
	# Geo::Coder::Free::new(undef, foo => 'bar'):
	# shift gives $class = undef; get_params sees ('foo','bar') → {foo=>'bar'};
	# !defined($class) && keys %params → carp + return.
	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };
	my $r = Geo::Coder::Free::new(undef, foo => 'bar');
	is($r, undef, 'function call with params returns undef');
	ok($warned, 'carp warning was issued');
};

subtest 'new() — new_2: function call with no args → valid object' => sub {
	# shift gives undef; get_params returns {}; $class set to __PACKAGE__.
	local $SIG{__WARN__} = sub {};    # suppress any incidental warnings
	my $obj = Geo::Coder::Free::new();
	isa_ok($obj, 'Geo::Coder::Free', 'function-call new() returns GCF object');
};

subtest 'new() — new_3: blessed instance->new() → shallow clone' => sub {
	my $orig  = Geo::Coder::Free->new();
	my $clone = $orig->new();
	isa_ok($clone, 'Geo::Coder::Free', 'clone isa GCF');
	isnt(refaddr($orig), refaddr($clone), 'clone is a distinct reference');
	is(refaddr($orig->{'alternatives'}), refaddr($clone->{'alternatives'}),
		'alternatives singleton shared between original and clone');
};

subtest 'new() — new_4: alternatives already loaded → second new() skips reload' => sub {
	my $g1        = Geo::Coder::Free->new();
	my $alt_addr1 = refaddr($Geo::Coder::Free::alternatives);
	my $g2        = Geo::Coder::Free->new();
	my $alt_addr2 = refaddr($Geo::Coder::Free::alternatives);
	is($alt_addr1, $alt_addr2, 'alternatives not re-parsed on second new()');
	ok(scalar keys %{$Geo::Coder::Free::alternatives}, 'alternatives table non-empty');
};

subtest 'new() — new_5: OPENADDR_HOME env var supplies openaddr path' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new', sub {
		bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses'
	});
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	ok(defined($geo->{'openaddr'}), 'openaddr backend created from OPENADDR_HOME env');
	restore_all();
	_remock_maxmind();
};

subtest 'new() — new_6: explicit openaddr param creates OA backend' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new', sub {
		bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses'
	});
	my $geo = Geo::Coder::Free->new(openaddr => $tmpdir);
	ok(defined($geo->{'openaddr'}), 'openaddr backend created from explicit param');
	restore_all();
	_remock_maxmind();
};

subtest 'new() — new_7: cache param stored on object' => sub {
	my $fake = bless {}, 'FakeCache';
	my $geo  = Geo::Coder::Free->new(cache => $fake);
	is($geo->{'cache'}, $fake, 'cache param stored on GCF object');
};

# =======================================================================
# 3. Geo::Coder::Free::geocode() — dispatch and guard paths
# =======================================================================

subtest 'geocode() — gc_A1: non-ref self + more args → delegates to new()->geocode' => sub {
	# self='location' (first arg shifted), @_=(ALL_SAINTS_LOC) — scalar @_ > 0 → A1.
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $r;
	lives_ok { $r = Geo::Coder::Free::geocode(location => ALL_SAINTS_LOC) }
		'function call with extra args lives';
	ok(!ref($r) || ref($r) eq 'Geo::Location::Point', 'A1 delegate returns undef or GLP');
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_A2: undef self, no extra args → croak usage' => sub {
	throws_ok { Geo::Coder::Free::geocode(undef) } qr/Usage/, 'undef self → croak';
};

subtest 'geocode() — gc_A3: __PACKAGE__ self, no extra args → croak usage' => sub {
	throws_ok {
		Geo::Coder::Free::geocode('Geo::Coder::Free')
	} qr/Usage/, '__PACKAGE__ self → croak';
};

subtest 'geocode() — gc_A4: bare string self, no extra args → delegate as bare location' => sub {
	# non-ref, defined, ne __PACKAGE__, no @_ → A4: new()->geocode($self)
	lives_ok { Geo::Coder::Free::geocode('Some Place, Somewhere, US') }
		'bare string self delegates without dying';
};

subtest 'geocode() — gc_B: hashref self → delegates to new()->geocode($self)' => sub {
	# The entire first arg is the hashref $self; any trailing args are discarded.
	# new()->geocode({location => ...}) returns undef (unknown address) but does not croak.
	lives_ok {
		Geo::Coder::Free::geocode({location => 'Nowhere, XY, XX'})
	} 'hashref self delegates cleanly';
};

subtest 'geocode() — gc_C_empty_loc: zero-length location → undef (not croak)' => sub {
	my $geo = Geo::Coder::Free->new();
	is($geo->geocode(location => ''), undef, 'empty string → undef');
};

subtest 'geocode() — gc_C_numeric_loc: non-empty numeric → croak invalid_location' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode(location => '42') } qr/invalid location/, '42 → croak';
	throws_ok { $geo->geocode(location => '0')  } qr/invalid location/, '0 → croak';
};

subtest 'geocode() — gc_C_numeric_loc_undef: numeric + on_error => undef → undef, no croak' => sub {
	# The same guard as gc_C_numeric_loc, with the batch caller's setting: the
	# croak becomes the undef that lets the row be skipped (section 2.4 of
	# BI-Phase6-Dependency-Specs.md).
	my $geo = Geo::Coder::Free->new();
	is($geo->geocode(location => '42', on_error => 'undef'), undef, '42 → undef');
	lives_ok { $geo->geocode(location => '0', on_error => 'undef') } '0 → no croak';
};

subtest 'geocode() — gc_C_empty_scan: zero-length scantext → undef (not croak)' => sub {
	my $geo = Geo::Coder::Free->new();
	is($geo->geocode(scantext => ''), undef, 'empty scantext → undef');
};

subtest 'geocode() — gc_C_numeric_scan: non-empty numeric scantext → croak' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode(scantext => '99') } qr/invalid scantext/, '99 → croak';
};

subtest 'geocode() — gc_D1a: scantext in misses cache → immediate undef return' => sub {
	# Pre-populate the miss cache; the guard fires before any OA/Local/MaxMind call.
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless {}, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	$geo->{'scantext_misses'}{'previously seen text'} = 1;
	my $r = $geo->geocode(scantext => 'previously seen text');
	is($r, undef, 'misses-cache hit → immediate undef without any backend call');
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_D1b: no ignore_words → uses \\%_COMMON_WORDS reference directly' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	my $r;
	lives_ok { $r = $geo->geocode(scantext => 'She went to the park') }
		'no ignore_words path: uses \\%_COMMON_WORDS directly, no exception';
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_D1c: custom ignore_words → merged copy of _COMMON_WORDS' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	my $r;
	lives_ok {
		$r = $geo->geocode(scantext => 'Visited Ramsgate Kent', ignore_words => ['visited'])
	} 'custom ignore_words: merged hash path, no exception';
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_E_maxmind_only: no openaddr → MaxMind is sole backend' => sub {
	mock('Geo::Coder::Free::MaxMind', 'geocode', sub { return $MOCK_GLP });
	my $geo = Geo::Coder::Free->new();
	my $r   = $geo->geocode(location => 'Ramsgate, Kent, UK');
	isa_ok($r, 'Geo::Location::Point', 'MaxMind-only path returns GLP');
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_E_croak: no openaddr, no location, no scantext → croak' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->geocode() } qr/Usage/, 'no location/scantext → croak';
};

subtest 'geocode() — gc_E_scan_no_oa: scantext + no openaddr → silent undef' => sub {
	# Without OA, the scantext block is never entered.  Code reaches the
	# MaxMind guard (location is falsy), then the usage croak guard
	# (scantext is truthy → the croak does NOT fire) → returns undef.
	my $geo = Geo::Coder::Free->new();
	my $r;
	lives_ok { $r = $geo->geocode(scantext => 'Ramsgate, Kent, UK') }
		'scantext without openaddr lives (silent return)';
	is($r, undef, 'returns undef rather than croaking');
};

subtest 'geocode() — gc_D2_oa_hit: openaddr hit → returned without Local/MaxMind' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return $MOCK_GLP });
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	my $r = $geo->geocode(location => 'Newport Pagnell, Buckinghamshire, England');
	isa_ok($r, 'Geo::Location::Point', 'OA hit → GLP returned');
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_D2_oa_miss_local_hit: OA miss → Local hit' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return undef });
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	my $r = $geo->geocode(location => ALL_SAINTS_LOC);
	isa_ok($r, 'Geo::Location::Point', 'OA miss → Local hit → GLP returned');
	if ($r) {
		cmp_ok(abs($r->lat()  - ALL_SAINTS_LAT), '<', 0.001, 'latitude correct');
		cmp_ok(abs($r->long() - ALL_SAINTS_LON), '<', 0.001, 'longitude correct');
	}
	restore_all();
	_remock_maxmind();
};

subtest 'geocode() — gc_D2_list: wantarray path in OA block' => sub {
	my $tmpdir = tempdir(CLEANUP => 1);
	mock('Geo::Coder::Free::OpenAddresses', 'new',    sub { bless { openaddr => $tmpdir }, 'Geo::Coder::Free::OpenAddresses' });
	mock('Geo::Coder::Free::OpenAddresses', 'geocode', sub { return $MOCK_GLP });
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	my $geo;
	{
		local $ENV{OPENADDR_HOME} = $tmpdir;
		$geo = Geo::Coder::Free->new();
	}
	my @r = $geo->geocode(location => 'Ramsgate, Kent, UK');
	ok(scalar @r > 0, 'list context OA hit → non-empty list');
	isa_ok($r[0], 'Geo::Location::Point', 'first element is GLP');
	restore_all();
	_remock_maxmind();
};

# =======================================================================
# 4. Geo::Coder::Free::reverse_geocode() — dispatch and coord-source paths
# =======================================================================

subtest 'reverse_geocode() — rgc_A1: function call + args → delegates' => sub {
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	lives_ok {
		Geo::Coder::Free::reverse_geocode(latlng => '39.467270,-76.823947')
	} 'function call with args delegates cleanly';
	restore_all();
	_remock_maxmind();
};

subtest 'reverse_geocode() — rgc_A2: undef self → croak usage' => sub {
	throws_ok { Geo::Coder::Free::reverse_geocode(undef) } qr/Usage/, 'undef self → croak';
};

subtest 'reverse_geocode() — rgc_A3: __PACKAGE__ self → croak usage' => sub {
	throws_ok {
		Geo::Coder::Free::reverse_geocode('Geo::Coder::Free')
	} qr/Usage/, '__PACKAGE__ self → croak';
};

subtest 'reverse_geocode() — rgc_A4: bare string self → delegates' => sub {
	lives_ok { Geo::Coder::Free::reverse_geocode('39.467270,-76.823947') }
		'bare string self delegates';
};

subtest 'reverse_geocode() — rgc_latlng: latlng param → split into lat/lon' => sub {
	mock('Geo::Coder::Free::MaxMind', 'reverse_geocode', sub { return $MOCK_GLP });
	my $geo = Geo::Coder::Free->new();
	my $r   = $geo->reverse_geocode(latlng => '39.467270,-76.823947');
	isa_ok($r, 'Geo::Location::Point', 'latlng param → GLP from MaxMind');
	restore_all();
	_remock_maxmind();
};

subtest 'reverse_geocode() — rgc_lat_lon: separate lat/lon → croak (GCF requires latlng)' => sub {
	# GCF normalises args with bare_key='latlng'; separate lat/lon produce no 'latlng'
	# key in %params → the latlng guard is false → croak 'not yet supported'.
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->reverse_geocode(lat => 39.467270, lon => -76.823947) }
		qr/not yet supported/, 'lat+lon without latlng → croak';
};

subtest 'reverse_geocode() — rgc_lat_long_alias: lat/long → croak (GCF requires latlng)' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->reverse_geocode(lat => 39.467270, long => -76.823947) }
		qr/not yet supported/, 'lat/long alias without latlng → croak';
};

subtest 'reverse_geocode() — rgc_no_coords: no openaddr, no coords → croak' => sub {
	my $geo = Geo::Coder::Free->new();
	throws_ok { $geo->reverse_geocode() } qr/not yet supported/, 'no coords → croak';
};

# =======================================================================
# 5. Geo::Coder::Free::Local::geocode() — guard and early-return paths
# =======================================================================

subtest 'Local::geocode() — lgc_A1: function call + args → delegates' => sub {
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	lives_ok { Geo::Coder::Free::Local::geocode(location => ALL_SAINTS_LOC) } 'delegates';
	restore_all();
	_remock_maxmind();
};

subtest 'Local::geocode() — lgc_A2: undef self → croak usage' => sub {
	throws_ok { Geo::Coder::Free::Local::geocode(undef) } qr/Usage/, 'undef self → croak';
};

subtest 'Local::geocode() — lgc_A3: __PACKAGE__ self → croak usage' => sub {
	throws_ok {
		Geo::Coder::Free::Local::geocode('Geo::Coder::Free::Local')
	} qr/Usage/, '__PACKAGE__ self → croak';
};

subtest 'Local::geocode() — lgc_A4: bare string self → delegates' => sub {
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	lives_ok { Geo::Coder::Free::Local::geocode(ALL_SAINTS_LOC) } 'bare string self delegates';
	restore_all();
	_remock_maxmind();
};

subtest 'Local::geocode() — lgc_B: hashref self → delegates to new()->geocode($self)' => sub {
	# The hashref is $self; trailing args would be discarded on the delegate call.
	# Pass location inside the hashref so the delegate receives it.
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	lives_ok {
		Geo::Coder::Free::Local::geocode({location => ALL_SAINTS_LOC})
	} 'hashref self delegates cleanly';
	restore_all();
	_remock_maxmind();
};

subtest 'Local::geocode() — lgc_comma_guard: fewer than 2 commas → undef' => sub {
	is($LOCAL_OBJ->geocode(location => 'Ramsgate'),       undef, 'no commas → undef');
	is($LOCAL_OBJ->geocode(location => 'Ramsgate, Kent'), undef, 'one comma → undef');
};

subtest 'Local::geocode() — lgc_canada_early: Canada → undef early return' => sub {
	is($LOCAL_OBJ->geocode(location => '123 Main St, Toronto, ON, Canada'), undef,
		'Canada → undef early return');
};

subtest 'Local::geocode() — lgc_australia_early: Australia → undef early return' => sub {
	is($LOCAL_OBJ->geocode(location => '1 George St, Sydney, NSW, Australia'), undef,
		'Australia → undef early return');
};

subtest 'Local::geocode() — lgc_cache_hit: cached value returned without scan' => sub {
	my $fake = Geo::Location::Point->new({ lat => 1.0, long => 2.0 });
	my $key  = 'cache test key, city, us';
	$LOCAL_OBJ->{'cache'}{$key} = $fake;
	my $r = $LOCAL_OBJ->geocode(location => 'Cache Test Key, City, US');
	delete $LOCAL_OBJ->{'cache'}{$key};
	is(refaddr($r), refaddr($fake), 'cache hit returns the exact cached object');
};

subtest 'Local::geocode() — lgc_index_hit: exact string in index → GLP returned' => sub {
	my $r = $LOCAL_OBJ->geocode(location => ALL_SAINTS_LOC);
	isa_ok($r, 'Geo::Location::Point', 'index hit returns GLP');
	if ($r) {
		cmp_ok(abs($r->lat()  - ALL_SAINTS_LAT), '<', 0.001, 'latitude correct');
		cmp_ok(abs($r->long() - ALL_SAINTS_LON), '<', 0.001, 'longitude correct');
	}
};

subtest 'Local::geocode() — lgc_three_part_gb: 3-part UK address (no road) → undef' => sub {
	# "Town, County, England" has 2 commas so passes the comma guard, then enters the
	# GB AddressParse branch.  Without a road component, _search cannot reach 3 matches.
	my $r = $LOCAL_OBJ->geocode(location => 'Ramsgate, Kent, England');
	is($r, undef, '3-part UK address without road/number → undef');
};

# =======================================================================
# 6. Geo::Coder::Free::Local::reverse_geocode() — coordinate-source paths
# =======================================================================

subtest 'Local::reverse_geocode() — lrgc_A1: function call + args → delegates' => sub {
	mock('Geo::Coder::Free::Local', 'new', sub { return $LOCAL_OBJ });
	lives_ok { Geo::Coder::Free::Local::reverse_geocode(latlng => '0,0') } 'delegates';
	restore_all();
	_remock_maxmind();
};

subtest 'Local::reverse_geocode() — lrgc_A2: undef self → croak' => sub {
	throws_ok { Geo::Coder::Free::Local::reverse_geocode(undef) } qr/Usage/,
		'undef self → croak';
};

subtest 'Local::reverse_geocode() — lrgc_A3: __PACKAGE__ self → croak' => sub {
	throws_ok {
		Geo::Coder::Free::Local::reverse_geocode('Geo::Coder::Free::Local')
	} qr/Usage/, '__PACKAGE__ self → croak';
};

subtest 'Local::reverse_geocode() — lrgc_latlng: latlng split into lat/lon' => sub {
	my @r = $LOCAL_OBJ->reverse_geocode(latlng => sprintf('%s,%s', NCBI_LAT, NCBI_LON));
	ok(scalar @r > 0, 'latlng split → NCBI area found');
	like($r[0], qr/NCBI|BETHESDA|MEDLARS/i, 'result mentions NCBI area');
};

subtest 'Local::reverse_geocode() — lrgc_lat_lon: separate lat/lon params' => sub {
	my @r = $LOCAL_OBJ->reverse_geocode(lat => NCBI_LAT, lon => NCBI_LON);
	ok(scalar @r > 0, 'lat+lon params → finds entry');
};

subtest 'Local::reverse_geocode() — lrgc_lat_long_alias: long alias param' => sub {
	my @r = $LOCAL_OBJ->reverse_geocode(lat => NCBI_LAT, long => NCBI_LON);
	ok(scalar @r > 0, 'lat+long alias → finds entry');
};

subtest 'Local::reverse_geocode() — lrgc_no_coords: undef latlng → croak' => sub {
	throws_ok { $LOCAL_OBJ->reverse_geocode(latlng => undef) } qr/Usage/,
		'undef latlng → croak';
};

subtest 'Local::reverse_geocode() — lrgc_no_match: unknown coords → empty list' => sub {
	my @r = $LOCAL_OBJ->reverse_geocode(latlng => '0.0000001,0.0000001');
	is(scalar @r, 0, 'unknown coords → empty list');
};

subtest 'Local::reverse_geocode() — lrgc_scalar: scalar context returns first match' => sub {
	my $r = $LOCAL_OBJ->reverse_geocode(latlng => sprintf('%s,%s', NCBI_LAT, NCBI_LON));
	ok(defined $r && !ref($r), 'scalar context returns a plain string');
};

subtest 'Local::reverse_geocode() — lrgc_list: list context collects all candidates' => sub {
	my @r = $LOCAL_OBJ->reverse_geocode(
		latlng => sprintf('%s,%s', RAMSGATE_LAT, RAMSGATE_LON)
	);
	ok(scalar @r >= 1, 'list context returns at least one result');
};

# =======================================================================
# 7. Local::_search() — confidence-level branches
# =======================================================================

subtest '_search() — srch_exact: all 5 columns match → CONF_EXACT (1.0)' => sub {
	# All Saints row: number=203, road=E CHATSWORTH RD, city=REISTERSTOWN, state=MD, country=US.
	my %data = (
		number  => '203',
		road    => 'E CHATSWORTH RD',
		city    => 'REISTERSTOWN',
		state   => 'MD',
		country => 'US',
	);
	my $r = $LOCAL_OBJ->_search(\%data, qw(number road city state country));
	isa_ok($r, 'Geo::Location::Point', '_search returns GLP on exact 5/5 match');
	is($r->{'confidence'}, 1.0, 'CONF_EXACT = 1.0') if $r;
};

subtest '_search() — srch_high: 5 of 6 columns match → CONF_HIGH (0.7)' => sub {
	# state_district absent from %data (not exists) → skipped, not counted.
	# All other 5 columns match the All Saints row → matched=5, cols=6 → CONF_HIGH.
	my %data = (
		number  => '203',
		road    => 'E CHATSWORTH RD',
		city    => 'REISTERSTOWN',
		state   => 'MD',
		country => 'US',
	);
	my $r = $LOCAL_OBJ->_search(\%data, qw(number road city state_district state country));
	isa_ok($r, 'Geo::Location::Point', '_search returns GLP on 5/6 match');
	is($r->{'confidence'}, 0.7, 'CONF_HIGH = 0.7') if $r;
};

subtest '_search() — srch_medium: 3 of 4 columns match → CONF_MEDIUM (0.5)' => sub {
	# number absent from %data (not exists) → skipped → matched=3 (city/state/country), cols=4.
	my %data = (
		city    => 'BETHESDA',
		state   => 'MD',
		country => 'US',
	);
	my $r = $LOCAL_OBJ->_search(\%data, qw(number city state country));
	isa_ok($r, 'Geo::Location::Point', '_search returns GLP on 3/4 match');
	is($r->{'confidence'}, 0.5, 'CONF_MEDIUM = 0.5') if $r;
};

subtest '_search() — srch_no_match: nothing in dataset matches → undef' => sub {
	my %data = ( city => 'ATLANTIS', state => 'ZZ', country => 'XX' );
	is($LOCAL_OBJ->_search(\%data, qw(city state country)), undef, 'no match → undef');
};

subtest '_search() — srch_undef_col: undef value in %data → delete branch, not counted' => sub {
	# number exists in %data but is undef → `elsif (exists ...)` branch fires, deletes it.
	my %data = (
		city    => 'REISTERSTOWN',
		state   => 'MD',
		country => 'US',
		number  => undef,
	);
	my $r = $LOCAL_OBJ->_search(\%data, qw(number city state country));
	ok(!defined($r) || ref($r) eq 'Geo::Location::Point',
		'undef column: delete branch fires, search still proceeds');
};

# =======================================================================
# 8. Geo::Coder::Free::_normalize() — word-count paths
# =======================================================================

subtest '_normalize() — norm_3plus_minus2_abbrev: words[-2] abbreviates' => sub {
	my $r = Geo::Coder::Free::_normalize('Penn Avenue NW');
	like($r, qr/AV/i, '"Avenue" at [-2] abbreviated');
};

subtest '_normalize() — norm_3plus_cross_guard: "CROSS" at [-2] skips it, tries [-1]' => sub {
	my $r = Geo::Coder::Free::_normalize('King Cross Street');
	like($r, qr/\bST\b/i, '"CROSS" guard prevents [-2] abbreviation; "Street" at [-1] abbreviated');
};

subtest '_normalize() — norm_3plus_no_abbrev: neither word abbreviates → uppercase unchanged' => sub {
	my $r = Geo::Coder::Free::_normalize('Alpha Beta Gamma');
	is($r, 'ALPHA BETA GAMMA', 'no abbreviation found → uppercased unchanged');
};

subtest '_normalize() — norm_2words_abbrev: 2 words, last abbreviates' => sub {
	my $r = Geo::Coder::Free::_normalize('Penn Street');
	like($r, qr/^PENN\s+ST\b/i, '"Street" at [-1] abbreviated');
};

subtest '_normalize() — norm_2words_no_abbrev: 2 words, last does not abbreviate' => sub {
	my $r = Geo::Coder::Free::_normalize('Alpha Beta');
	is($r, 'ALPHA BETA', '2-word no abbreviation → uppercase only');
};

subtest '_normalize() — norm_1word: single word → no abbreviation block entered' => sub {
	my $r = Geo::Coder::Free::_normalize('Avenue');
	is($r, 'AVENUE', 'single word → uppercase only, no abbreviation');
};

subtest '_normalize() — norm_leading_zero: stripped from result' => sub {
	my $r = Geo::Coder::Free::_normalize('04th Street');
	like($r, qr/^4TH/i, 'leading "0" stripped from result');
};

# =======================================================================
# 9. Geo::Coder::Free::_abbreviate() — found / not-found paths
# =======================================================================

subtest '_abbreviate() — abbr_found: known word → abbreviated string returned' => sub {
	my $r = Geo::Coder::Free::_abbreviate('Avenue');
	isnt($r, 'AVENUE', 'abbreviation differs from raw uppercase form');
	ok(length($r) > 0, 'non-empty string returned');
};

subtest '_abbreviate() — abbr_not_found: unknown word → original returned unchanged' => sub {
	my $r = Geo::Coder::Free::_abbreviate('XYZZY_NOABBREV');
	is($r, 'XYZZY_NOABBREV', 'unknown word → original (uppercase) returned');
};

# =======================================================================
# 10. Geo::Coder::Free::_find_word_ngrams() — paths
# =======================================================================

subtest '_find_word_ngrams() — ngram_enough: produces expected bigrams' => sub {
	my @ng = Geo::Coder::Free::_find_word_ngrams('Ramsgate Kent England', 2, {});
	ok(scalar @ng > 0, 'enough words → bigrams produced');
	like($ng[0], qr/Ramsgate.*Kent/i, 'first bigram is first two words');
};

subtest '_find_word_ngrams() — ngram_too_few: fewer words than n → empty list' => sub {
	my @ng = Geo::Coder::Free::_find_word_ngrams('Ramsgate', 3, {});
	is(scalar @ng, 0, 'one word with n=3 → no ngrams');
};

subtest '_find_word_ngrams() — ngram_stopwords: stopwords filtered before window' => sub {
	my $stop = { 'the' => 1, 'in' => 1 };
	my @ng   = Geo::Coder::Free::_find_word_ngrams('She lived in the city', 2, $stop);
	for my $ng (@ng) {
		unlike($ng, qr/\bthe\b|\bin\b/i, "stopword absent from ngram: $ng");
	}
};

subtest '_find_word_ngrams() — ngram_digits: pure-digit tokens removed before window' => sub {
	my @ng = Geo::Coder::Free::_find_word_ngrams('12345 Main Street', 2, {});
	for my $ng (@ng) {
		unlike($ng, qr/^\d+,/, 'digit token not leading ngram: ' . $ng);
	}
};

subtest '_find_word_ngrams() — ngram_commas: commas normalised to spaces' => sub {
	my @ng1 = Geo::Coder::Free::_find_word_ngrams('Ramsgate, Kent', 2, {});
	my @ng2 = Geo::Coder::Free::_find_word_ngrams('Ramsgate Kent',  2, {});
	is_deeply(\@ng1, \@ng2, 'comma in input produces same ngrams as space');
};

# =======================================================================
# 11. Local::_find_geographic_centres() — execution paths
# =======================================================================

subtest '_find_geographic_centres() — geo_empty: no rows → undef' => sub {
	is(Geo::Coder::Free::Local::_find_geographic_centres([]), undef,
		'empty arrayref → undef');
};

subtest '_find_geographic_centres() — geo_bad_coords: invalid lat/lon rows → skipped → undef' => sub {
	my $rows = [
		{ city => 'X', state => 'Y', country => 'Z' },
		{ city => 'X', state => 'Y', country => 'Z', latitude => 'abc', longitude => 'def' },
	];
	is(Geo::Coder::Free::Local::_find_geographic_centres($rows), undef,
		'rows with bad coords → undef');
};

subtest '_find_geographic_centres() — geo_small: cluster < 3 → skipped → undef' => sub {
	my $rows = [
		{ city => 'X', state => 'Y', country => 'Z', latitude => '10.0', longitude => '20.0' },
		{ city => 'X', state => 'Y', country => 'Z', latitude => '10.1', longitude => '20.1' },
	];
	is(Geo::Coder::Free::Local::_find_geographic_centres($rows), undef,
		'cluster of 2 → skipped → undef');
};

subtest '_find_geographic_centres() — geo_large: cluster >= 3 → centre computed' => sub {
	my $rows = [
		{ city => 'X', state => 'Y', country => 'Z', latitude => '10.0', longitude => '20.0' },
		{ city => 'X', state => 'Y', country => 'Z', latitude => '10.2', longitude => '20.2' },
		{ city => 'X', state => 'Y', country => 'Z', latitude => '10.4', longitude => '20.4' },
	];
	my $r = Geo::Coder::Free::Local::_find_geographic_centres($rows);
	ok(defined $r && ref($r) eq 'ARRAY', 'cluster of 3 → arrayref returned');
	is(scalar @{$r}, 1, 'exactly one centre produced');
	if ($r && @{$r}) {
		cmp_ok(abs($r->[0]{'latitude'}  - 10.2), '<', 0.001, 'centre latitude = mean');
		cmp_ok(abs($r->[0]{'longitude'} - 20.2), '<', 0.001, 'centre longitude = mean');
	}
};

subtest '_find_geographic_centres() — geo_mixed: qualifying and non-qualifying clusters' => sub {
	my $rows = [
		map({ city => 'A', state => 'X', country => 'Z', latitude => "$_.0", longitude => '0.0' }, 1 .. 3),
		map({ city => 'B', state => 'X', country => 'Z', latitude => "$_.0", longitude => '0.0' }, 4, 5),
	];
	my $r = Geo::Coder::Free::Local::_find_geographic_centres($rows);
	ok(defined $r, 'mixed clusters → arrayref returned');
	is(scalar @{$r}, 1, 'only group A (size 3) produces a centre');
	is($r->[0]{'city'}, 'A', 'centre is for group A') if $r && @{$r};
};

subtest '_find_geographic_centres() — geo_real_data: Local new() adds centre rows' => sub {
	# Local::new() calls _find_geographic_centres on __DATA__ rows.
	# There are 9+ Ramsgate entries, so at least one centre is appended.
	my $data_count = scalar @{ $LOCAL_OBJ->{'data'} };
	cmp_ok($data_count, '>', 60, 'data array includes original rows + geographic centres');
};

# =======================================================================
# 12. Local::_to_two_letter_state() — all paths
# =======================================================================

subtest '_to_two_letter_state() — ttls_undef_state: undef → empty string' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('US', undef), '',
		'undef state → ""');
};

subtest '_to_two_letter_state() — ttls_short: length <= 2 → returned unchanged' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('US', 'MD'), 'MD', '2-char → unchanged');
	is(Geo::Coder::Free::Local::_to_two_letter_state('US', 'X'),  'X',  '1-char → unchanged');
};

subtest '_to_two_letter_state() — ttls_us_known: US state name → 2-letter code' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('US',            'Maryland'), 'MD',
		'US: Maryland → MD');
	is(Geo::Coder::Free::Local::_to_two_letter_state('United States', 'Maryland'), 'MD',
		'"United States": Maryland → MD');
};

subtest '_to_two_letter_state() — ttls_us_unknown: unrecognised US state → unchanged' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('US', 'Nonexistent State'),
		'Nonexistent State', 'unrecognised US state → original returned');
};

subtest '_to_two_letter_state() — ttls_canada_known: province → 2-letter code' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('Canada', 'Ontario'), 'ON',
		'Canada: Ontario → ON');
};

subtest '_to_two_letter_state() — ttls_canada_unknown: unrecognised province → unchanged' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('Canada', 'Nonexistentia'),
		'Nonexistentia', 'unrecognised province → original returned');
};

subtest '_to_two_letter_state() — ttls_other: not US/Canada → returned unchanged' => sub {
	is(Geo::Coder::Free::Local::_to_two_letter_state('GB', 'England'), 'England',
		'GB: no Locale module → unchanged');
};

subtest '_to_two_letter_state() — ttls_singleton: Locale objects shared across calls' => sub {
	my $r1 = Geo::Coder::Free::Local::_to_two_letter_state('US', 'California');
	my $r2 = Geo::Coder::Free::Local::_to_two_letter_state('US', 'California');
	is($r1, $r2, 'singleton: consistent result on repeated call');
};

done_testing();
