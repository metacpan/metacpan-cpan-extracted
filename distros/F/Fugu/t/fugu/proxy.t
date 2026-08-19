#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for the three packages in Fugu::Proxy. The generic
# cache, the metadata table and the supervisor are here; the OpenBSD
# mirror policy is in t/fuguvm/proxy.t.

use v5.36;
use Test::More;
use FindBin    qw($RealBin);
use lib "$RealBin/../../lib";
use File::Temp qw(tempdir);

# The cache maps a URL to a path with URI
BEGIN {
	eval { require URI };
	if ($@) {
		plan skip_all => 'URI not available';
	}
}

use Fugu::File;
use Fugu::Log;
use Fugu::Pidfile;
use Fugu::StateFile;

use_ok('Fugu::Proxy');

Fugu::Log->set_default( Fugu::Log->new( mode => 'quiet' ) );

# cache(%args): a cache over a fresh directory
sub cache (%args)
{
	return Fugu::Proxy::Cache->new(
		dir       => tempdir( CLEANUP => 1 ),
		cacheable => sub ($url) { $url =~ /\.tgz$/ },
		%args,
	);
}

subtest 'a URL becomes a path under the cache root' => sub {
	my $cache = cache();
	my $root  = $cache->root;

	is(
		$cache->cache_path(
			'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz'),
		"$root/cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz",
		'the path mirrors the URL'
	);

	is( $cache->dir . '/proxy', $root, 'the tree lives under the root' );
	ok( -d $root, 'and the constructor made it' );
};

# A path that escapes the cache root is the one thing this mapping
# must never produce. A URL comes from a client.
subtest 'a URL that would escape the cache is refused' => sub {
	my $cache = cache();

	is( $cache->cache_path('http://cdn.openbsd.org/../../../etc/passwd'),
		undef, 'a traversal in the path' );
	is( $cache->cache_path('http://example.com/foo/../bar'),
		undef, 'a traversal in the middle' );
	is( $cache->cache_path('http://example.com/..'),
		undef, 'a bare parent directory' );
	is( $cache->cache_path('http://example.com/foo/..'),
		undef, 'a trailing parent directory' );
	is( $cache->cache_path('http://example.com/'),
		undef, 'an empty path' );
	is( $cache->cache_path('not a url at all'), undef, 'no host' );
};

subtest 'cacheability is the caller decision' => sub {
	my $cache = cache();

	ok( $cache->is_cacheable('http://host/file.tgz'), 'the callback says yes' );
	ok( !$cache->is_cacheable('http://host/page.html'),
		'and no for the rest' );

	# Only a successful response is a candidate. A cached 404 is a
	# mirror that stays broken after the upstream is fixed.
	ok( !$cache->is_cacheable( 'http://host/file.tgz', 404 ),
		'a 404 is never cacheable' );
	ok( !$cache->is_cacheable( 'http://host/file.tgz', 302 ),
		'nor a redirect' );

	# The default refuses everything: a cache that guesses fills a
	# home directory with pages nobody reads again
	my $strict = Fugu::Proxy::Cache->new( dir => tempdir( CLEANUP => 1 ) );
	ok( !$strict->is_cacheable('http://host/file.tgz'),
		'the default callback says no' );
};

subtest 'store, lookup and list' => sub {
	my $cache = cache();
	my $url   = 'http://cdn.openbsd.org/pub/OpenBSD/7.8/arm64/base78.tgz';

	is( $cache->lookup($url), undef, 'nothing is cached yet' );

	my $path = $cache->store( $url, 'content' );
	ok( defined $path, 'store returns the path' );
	is( $cache->lookup($url), $path, 'and lookup finds it' );
	is( Fugu::File->read($path), 'content', 'with its content' );

	is( $cache->size, length('content'), 'size counts the bytes' );

	my $list = $cache->list;
	is( scalar @$list, 1,       'the listing has one entry' );
	is( $list->[0]{url}, $url,  'and rebuilds the URL' );
	is( $list->[0]{path}, $path, 'with the path' );

	ok( $cache->clear, 'clear removes it' );
	is( $cache->lookup($url), undef, 'and the lookup is empty' );
	is( $cache->size, 0, 'and the size is zero' );
	ok( -d $cache->root, 'but the root stays' );
};

subtest 'store_from_file' => sub {
	my $cache  = cache();
	my $source = tempdir( CLEANUP => 1 ) . '/source.tgz';
	Fugu::File->write( $source, 'from a file' );

	my $url  = 'http://host/pub/OpenBSD/x.tgz';
	my $path = $cache->store_from_file( $url, $source );
	ok( defined $path, 'store_from_file returns the path' );
	is( Fugu::File->read($path), 'from a file', 'with the content' );

	is( $cache->store_from_file( $url, "$source.absent" ),
		undef, 'a missing source is a failure' );
};

subtest 'content types come from a table with an override' => sub {
	my $cache = cache( types => { qr{/bsd$} => 'application/x-kernel' } );

	is( $cache->content_type('/a/base78.tgz'), 'application/x-gzip', 'tgz' );
	is( $cache->content_type('/a/x.gz'),       'application/gzip',   'gz' );
	is( $cache->content_type('/a/index.txt'),  'text/plain',         'txt' );
	is( $cache->content_type('/a/SHA256'),     'text/plain',   'checksums' );
	is( $cache->content_type('/a/BUILDINFO'),  'text/plain',   'build info' );
	is( $cache->content_type('/a/bsd'), 'application/x-kernel',
		'the override wins for a name with no extension' );
	is( $cache->content_type('/a/unknown'),
		'application/octet-stream', 'and the fallback is bytes' );
};

subtest 'the metadata table validates against the file' => sub {
	my $cache = cache();
	my $url   = 'http://host/pub/OpenBSD/x.tgz';
	my $path  = $cache->store( $url, 'some content' );

	my $meta = Fugu::Proxy::Meta->new;
	is( $meta->lookup($url), undef, 'an unknown URL is absent' );
	is( $meta->count,        0,     'and the table is empty' );

	my $entry = $meta->store( $url, $path, $cache );
	ok( defined $entry, 'store returns the entry' );
	is( $entry->{path}, $path, 'with the path' );
	is( $entry->{size}, length('some content'), 'and the size' );
	is( $entry->{content_type}, 'application/x-gzip',
		'and the type from the cache' );
	like( $entry->{etag}, qr/^"[0-9a-f]+-[0-9a-f]+"$/, 'and an ETag' );

	is_deeply( $meta->lookup($url), $entry, 'lookup returns it' );
	is( $meta->count, 1, 'the table has one entry' );

	# An entry whose file changed under the proxy is not valid
	Fugu::File->write( $path, 'different content of another length' );
	is( $meta->lookup($url), undef, 'a changed file invalidates the entry' );

	# So is one whose file is gone
	$meta->store( $url, $path, $cache );
	unlink $path;
	is( $meta->lookup($url), undef, 'a removed file invalidates it too' );

	is( $meta->store( $url, $path, $cache ),
		undef, 'and store refuses a file that does not stat' );
};

subtest 'warm builds an entry for every cached file' => sub {
	my $cache = cache();
	for my $n ( 1 .. 3 ) {
		$cache->store( "http://host/pub/OpenBSD/$n.tgz", "content $n" );
	}

	my $meta = Fugu::Proxy::Meta->new;
	is( $meta->warm($cache), 3, 'warm reports the count' );
	is( $meta->count,        3, 'and the table holds them' );
	ok( defined $meta->lookup('http://host/pub/OpenBSD/2.tgz'),
		'each URL resolves' );

	my $empty = Fugu::Proxy::Meta->new;
	is( $empty->warm( cache() ), 0, 'an empty cache warms to nothing' );
};

subtest 'the supervisor before anything runs' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $proxy = Fugu::Proxy->new(
		cache   => cache(),
		pidfile => Fugu::Pidfile->new( path => "$dir/proxy.pid" ),
		store   => Fugu::StateFile->new( path => "$dir/state.json" )->load,
	);

	ok( defined $proxy,      'the supervisor exists' );
	ok( !$proxy->is_running, 'nothing runs yet' );
	is( $proxy->port, undef, 'and there is no port' );
	is( $proxy->wait_ready(1), 0, 'waiting for nothing gives up' );

	my $port = $proxy->_find_free_port;
	ok( defined $port, 'a free port exists' );
	ok( $port >= 8080 && $port <= 8180, 'inside the default range' );

	# The range is configurable, because two tools must not fight
	# over the same ports
	my $narrow = Fugu::Proxy->new(
		cache   => cache(),
		pidfile => Fugu::Pidfile->new( path => "$dir/other.pid" ),
		store   => Fugu::StateFile->new( path => "$dir/other.json" )->load,
		ports   => [ 19000, 19010 ],
	);
	my $narrow_port = $narrow->_find_free_port;
	ok( $narrow_port >= 19000 && $narrow_port <= 19010,
		'and it is honored' );
};

subtest 'the supervisor reads its port from the store' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Fugu::StateFile->new( path => "$dir/state.json" )->load;
	$store->set( proxy_port => 8099 );

	my $proxy = Fugu::Proxy->new(
		cache   => cache(),
		pidfile => Fugu::Pidfile->new( path => "$dir/proxy.pid" ),
		store   => $store,
	);

	is( $proxy->port, 8099, 'the port' );

	# A stop with nothing running clears the record and does not
	# complain
	ok( $proxy->stop, 'stop is a success with no child' );
	is( $proxy->port, undef, 'and the port is forgotten' );
};

subtest 'the supervisor needs its three parts' => sub {
	my $dir = tempdir( CLEANUP => 1 );

	ok( !eval { Fugu::Proxy->new; 1 }, 'new needs arguments' );
	ok(
		!eval {
			Fugu::Proxy->new( cache => cache() );
			1;
		},
		'a cache alone is not enough'
	);
	ok( !eval { Fugu::Proxy::Cache->new; 1 }, 'a cache needs a dir' );
};

done_testing();
