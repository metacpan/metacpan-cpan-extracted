#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;

BEGIN { use_ok('Genealogy::Obituary::Lookup') }

# ---------------------------------------------------------------------------
# Mock the DB driver so tests run without a built obituaries.sql
# ---------------------------------------------------------------------------
BEGIN {
	package Genealogy::Obituary::Lookup::obituaries;
	use strict;
	use warnings;

	my $mock_source = 'M';	# Overridable per subtest via _set_mock_source()
	my $mock_page   = 1;

	sub _set_mock($$) { ($mock_source, $mock_page) = @_ }

	sub new {
		return bless {}, shift;
	}

	sub selectall_hashref {
		return [
			{ first => 'John', last => 'Smith', source => $mock_source, page => $mock_page },
			{ first => 'Jane', last => 'Smith', source => 'F',          page => 'v26no080' },
		];
	}

	sub fetchrow_hashref {
		return { first => 'John', last => 'Smith', source => $mock_source, page => $mock_page };
	}
}

# ---------------------------------------------------------------------------
# Constructor tests
# ---------------------------------------------------------------------------
my $directory = tempdir(CLEANUP => 1);
my $obj = Genealogy::Obituary::Lookup->new(directory => $directory);
ok($obj, 'Object created with explicit directory');

subtest 'new() constructor' => sub {
	# Determine whether the module-relative data/ directory exists.
	# It may be absent when running under blib/ before the database is built.
	my $has_data_dir = do {
		(my $base = $INC{'Genealogy/Obituary/Lookup.pm'} // '') =~ s/\.pm$//;
		$base && -d File::Spec->catdir($base, 'data');
	};

	SKIP: {
		skip 'module-relative data/ not present (run `make` first)', 1
			unless $has_data_dir;
		my $default = Genealogy::Obituary::Lookup->new();
		ok($default, 'Constructor works without arguments');
	}

	# Invalid directory is rejected gracefully (carp, not croak)
	my $bad = Genealogy::Obituary::Lookup->new(directory => '/nonexistent/path/$$');
	ok(!$bad, 'Constructor returns undef for nonexistent directory');

	# Valid directory is accepted
	my $valid = Genealogy::Obituary::Lookup->new(directory => '.');
	ok($valid, 'Constructor accepts valid directory argument');

	# Cloning via ->new on an existing object
	my $clone = $valid->new();
	ok($clone, 'Clone construction works on an existing object');
	cmp_deeply($clone, $valid, 'Cloned object matches original');

	SKIP: {
		skip 'module-relative data/ not present (run `make` first)', 1
			unless $has_data_dir;
		my $legacy = Genealogy::Obituary::Lookup::new();
		ok($legacy, '::new() with no args still works (legacy compatibility)');
	}
};

# ---------------------------------------------------------------------------
# search() basic list-context tests
# ---------------------------------------------------------------------------
subtest 'search() — list context' => sub {
	my $o = Genealogy::Obituary::Lookup->new(directory => $directory);

	my @results = $o->search(last => 'Smith');
	is(scalar(@results), 2, 'Returns both mock records');
	is($results[0]{'first'}, 'John', 'First result first name correct');
	like($results[0]{'url'}, qr{^https://}, 'URL is an https link');

	# Single positional argument is treated as last name
	my @pos = $o->search('Smith');
	ok(scalar(@pos) > 0, 'Positional last-name argument is accepted');

	# Extra filters are accepted
	my @filtered = $o->search(last => 'Smith', first => 'John');
	isa_ok(\@filtered, 'ARRAY', 'search() with extra params returns arrayref');
};

# ---------------------------------------------------------------------------
# search() scalar-context test
# ---------------------------------------------------------------------------
subtest 'search() — scalar context' => sub {
	my $o = Genealogy::Obituary::Lookup->new(directory => $directory);
	my $hit = $o->search(last => 'Smith');
	ok(defined($hit), 'Scalar context returns a defined value when match exists');
	isa_ok($hit, 'HASH', 'Scalar result is a hashref');
	like($hit->{'url'}, qr{^https://}, 'Scalar result has a valid URL');
};

# ---------------------------------------------------------------------------
# URL generation — tested indirectly through search() with controlled mocks
# _create_url is private and enforces caller package; direct calls are not
# supported from outside Genealogy::Obituary::Lookup.
# ---------------------------------------------------------------------------
subtest '_create_url() — source M produces wayback URL' => sub {
	Genealogy::Obituary::Lookup::obituaries::_set_mock('M', 96);
	my $o = Genealogy::Obituary::Lookup->new(directory => $directory);
	delete $o->{'obituaries'};	# Force re-init with new mock settings
	my ($hit) = $o->search(last => 'Smith');
	like($hit->{'url'}, qr{wayback\.archive-it\.org}, 'Source M yields Wayback URL');
	like($hit->{'url'}, qr{96$}, 'Page number appears at end of URL');
};

subtest '_create_url() — source F produces freelists URL' => sub {
	Genealogy::Obituary::Lookup::obituaries::_set_mock('F', 'v26no080');
	my $o = Genealogy::Obituary::Lookup->new(directory => $directory);
	delete $o->{'obituaries'};
	my ($hit) = $o->search(last => 'Smith');
	like($hit->{'url'}, qr{freelists\.org}, 'Source F yields freelists URL');
	like($hit->{'url'}, qr{v26no080}, 'Page identifier appears in URL');
};

subtest '_create_url() — source L with embedded URL' => sub {
	# Override the mock's fetchrow_hashref for source L with a direct URL in 'page'
	{
		no warnings 'redefine';
		local *Genealogy::Obituary::Lookup::obituaries::fetchrow_hashref = sub {
			return {
				first     => 'Joyce',
				last      => 'Diver',
				source    => 'L',
				page      => 'https://funeral-notices.co.uk/notice/diver/5174279',
				newspaper => 'https://funeral-notices.co.uk/notice/diver/5174279',
			};
		};
		local *Genealogy::Obituary::Lookup::obituaries::selectall_hashref = sub {
			return [{
				first     => 'Joyce',
				last      => 'Diver',
				source    => 'L',
				page      => 'https://funeral-notices.co.uk/notice/diver/5174279',
				newspaper => 'https://funeral-notices.co.uk/notice/diver/5174279',
			}];
		};

		my $o = Genealogy::Obituary::Lookup->new(directory => $directory);
		delete $o->{'obituaries'};
		my ($hit) = $o->search(last => 'Diver');
		like($hit->{'url'}, qr{funeral-notices\.co\.uk}, 'Source L yields the embedded URL');
	}
};

subtest '_create_url() — private enforcement' => sub {
	# Calling _create_url from outside the package must croak
	throws_ok {
		Genealogy::Obituary::Lookup::_create_url({ source => 'M', page => 1 })
	} qr/private/, 'External call to _create_url() is refused';
};

# ---------------------------------------------------------------------------
# Config-file loading
# ---------------------------------------------------------------------------
subtest 'Config file loading' => sub {
	# abs_path resolves the '..' so Object::Configure's path-traversal guard
	# does not reject the path (canonpath does not resolve '..' on Unix)
	my $config_file = abs_path(
		File::Spec->catfile($Bin, File::Spec->updir(), 'config.yaml')
	);
	my $o = Genealogy::Obituary::Lookup->new(config_file => $config_file);
	cmp_ok($o->{'directory'}, 'eq', '/', 'Config file directory value is loaded');
};

done_testing();
