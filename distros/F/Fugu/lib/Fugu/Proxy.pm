# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::Proxy;
our $VERSION = '0.1.2';

use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use Fugu::Timeout;
use IO::Socket::INET;
use Socket      qw(IPPROTO_TCP TCP_NODELAY SOL_SOCKET SO_SNDBUF);
use Time::HiRes qw(time);

# Fugu::Proxy - a caching HTTP proxy.
#
# The file holds three packages. Fugu::Proxy is the supervisor and
# the serve loop. Fugu::Proxy::Cache is the URL-to-file store.
# Fugu::Proxy::Meta is the stat-validated metadata that makes a
# cache hit one write instead of a read and a re-encode.
#
# Nothing here knows what content is worth caching. That is a callback
# on the cache, because the answer is a property of the mirror and not
# of HTTP.
#
# HTTP::Daemon and LWP::UserAgent load in the child, at serve time.
# Thus the module keeps the Fugu core-Perl load contract, and an
# installation without them still loads it.

use constant {
	PORT_RANGE_START => 8080,
	PORT_RANGE_END   => 8180,
	READY_TIMEOUT    => 30,
	STREAM_CHUNK     => 262144,     # 256KB
	SEND_BUFFER      => 1048576,    # 1MB
};

# Fugu::Proxy->new(%args):
#	cache   => $cache	a Fugu::Proxy::Cache (required)
#	pidfile => $pidfile	a Fugu::Pidfile for the child (required)
#	store   => $store	a Fugu::StateFile that holds the port (required)
#	logfile => $path	where the child's output goes
#	log     => $logger	default: Fugu::Log->default
#	ports   => [$first, $last]	the range to look in
sub new ( $class, %args )
{
	for my $required (qw(cache pidfile store)) {
		die "$required parameter required"
		    unless defined $args{$required};
	}

	my $ports = $args{ports} // [ PORT_RANGE_START, PORT_RANGE_END ];

	return bless {
		cache   => $args{cache},
		pidfile => $args{pidfile},
		store   => $args{store},
		logfile => $args{logfile} // '/dev/null',
		log     => $args{log}     // Fugu::Log->default,
		ports   => $ports,
		meta    => Fugu::Proxy::Meta->new,
		error   => undef,
	}, $class;
}

# $self->cache:
#	Return the cache object.
sub cache ($self)
{
	return $self->{cache};
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->port:
#	Return the port the running proxy listens on, or undef.
sub port ($self)
{
	return $self->{store}->get('proxy_port');
}

# $self->is_running:
#	Report if the proxy child is alive. The check reaps, so a
#	child that became a zombie reads as stopped.
sub is_running ($self)
{
	return $self->{pidfile}->is_running ? 1 : 0;
}

# $self->start:
#	Start the proxy child and wait until it takes connections. The
#	method returns the port, or undef with the reason in ->error.
#	A proxy that already runs returns its port and starts nothing.
sub start ($self)
{
	$self->{error} = undef;

	return $self->port if $self->is_running;

	my $port = $self->_find_free_port;
	unless ( defined $port ) {
		$self->{error} = sprintf 'no free port in %d-%d',
		    @{ $self->{ports} };
		return;
	}

	my $child  = ref $self;
	my $result = Fugu::Process->spawn_perl(
		code      => "use $child; $child->run_child(\@ARGV)",
		args      => [ $port, $self->{cache}->dir ],
		daemonize => 1,
		stdout    => $self->{logfile},
		stderr    => $self->{logfile},
	);
	unless ( $result->{success} ) {
		$self->{error} = "cannot start the proxy: $result->{error}";
		return;
	}

	$self->{pidfile}->write_pid( $result->{pid} );
	$self->{store}->set( proxy_port => $port );

	unless ( $self->wait_ready ) {
		$self->{error} = 'the proxy did not take connections';
		$self->stop;
		return;
	}

	return $port;
}

# $self->stop:
#	Stop the proxy child and forget its port. The method returns 1.
sub stop ($self)
{
	my $pid = $self->{pidfile}->read_pid;
	Fugu::Process->terminate( $pid, grace_period => 5 )
	    if defined $pid;

	$self->{pidfile}->remove;
	$self->{store}->delete('proxy_port');

	return 1;
}

# $self->wait_ready($timeout):
#	Wait until the proxy takes a connection.
sub wait_ready ( $self, $timeout = READY_TIMEOUT )
{
	my $port = $self->port;
	return 0 if !defined $port;

	my $ready = Fugu::Timeout::wait_until(
		$timeout, 0.5,
		sub {
			my $sock = IO::Socket::INET->new(
				PeerAddr => '127.0.0.1',
				PeerPort => $port,
				Proto    => 'tcp',
				Timeout  => 1,
			) or return 0;
			close $sock;
			return 1;
		} );

	return $ready ? 1 : 0;
}

# $self->serve($port):
#	Run the server loop. The spawned child calls this, and it
#	returns when a SIGTERM arrives.
sub serve ( $self, $port )
{
	eval { require HTTP::Daemon; require LWP::UserAgent; 1 }
	    or die "Fugu::Proxy needs HTTP::Daemon and LWP::UserAgent: $@";
	require HTTP::Request;
	require HTTP::Response;
	require IO::Select;

	# A client can disconnect in the middle of a transfer
	local $SIG{PIPE} = 'IGNORE';

	my $daemon = HTTP::Daemon->new(
		LocalAddr => '0.0.0.0',
		LocalPort => $port,
		ReuseAddr => 1,
		Listen    => 20,
	) or die "Cannot listen on port $port: $!";

	$self->{log}->info( 'Proxy listening on 0.0.0.0:%d', $port );

	# The self-pipe makes the signal safe: the handler writes one
	# byte, and the select loop notices it between requests instead
	# of inside one.
	pipe my $sig_read, my $sig_write or die "pipe: $!";
	$sig_read->blocking(0);
	$sig_write->blocking(0);

	my $running = 1;
	local $SIG{TERM} = sub {
		$running = 0;
		syswrite $sig_write, 'x', 1;
	};

	my $select = IO::Select->new( $daemon, $sig_read );

	while ($running) {
		my @ready = $select->can_read;
		last if !$running;

		for my $fh (@ready) {
			if ( $fh == $sig_read ) {
				sysread $sig_read, my $drain, 100;
				next;
			}

			my $client = $daemon->accept or next;
			$self->_handle_client($client);
			$client->close;
		}
	}

	$self->{log}->info('Proxy shutting down');
	close $sig_read;
	close $sig_write;
	$daemon->close;

	return 1;
}

# $self->warm:
#	Fill the metadata cache from what is already on disk. A cold
#	proxy would otherwise stat every file on its first hit.
sub warm ($self)
{
	my $start = time;
	my $count = $self->{meta}->warm( $self->{cache} );
	$self->{log}->info( 'Metadata cache warmed: %d entries in %.3f seconds',
		$count, time - $start );

	return $count;
}

# $self->_find_free_port:
#	Return the first port in the range that nothing holds.
sub _find_free_port ($self)
{
	my ( $first, $last ) = @{ $self->{ports} };

	for my $port ( $first .. $last ) {
		my $sock = IO::Socket::INET->new(
			LocalPort => $port,
			Proto     => 'tcp',
			ReuseAddr => 1,
			Listen    => 1,
		) or next;
		close $sock;
		return $port;
	}

	return;
}

sub _handle_client ( $self, $client )
{
	while ( my $request = $client->get_request ) {
		my $method = $request->method;
		my $url    = $request->uri->as_string;

		$self->{log}->debug( '%s %s from %s', $method, $url,
			$client->peerhost );

		my $meta;
		if ( $method eq 'GET' || $method eq 'HEAD' ) {
			$meta = $self->{meta}->lookup($url);

			# A disk hit the metadata cache does not know yet:
			# build its entry and stream it like every hit
			unless ( defined $meta ) {
				my $cached = $self->{cache}->lookup($url);
				$meta =
				    $self->{meta}
				    ->store( $url, $cached, $self->{cache} )
				    if defined $cached;
			}
		}

		if ( defined $meta ) {
			$self->{log}->info( 'CACHE HIT: %s [%d bytes]',
				$url, $meta->{size} );
			$self->_serve_streaming( $client, $meta, $request );
			next;
		}

		my $start    = time;
		my $response = $self->_process_request($request);
		$client->send_response($response);
		$self->{log}->info(
			'Served %d bytes in %.3f seconds',
			length( $response->content // '' ),
			time - $start
		);
	}

	return;
}

sub _process_request ( $self, $request )
{
	my $method = $request->method;
	my $url    = $request->uri->as_string;

	return $self->_forward($request)
	    if $method ne 'GET' && $method ne 'HEAD';

	$self->{log}->info( 'CACHE MISS: fetching %s', $url );
	my $start    = time;
	my $response = $self->_forward($request);
	$self->{log}->info(
		'Fetched %d bytes in %.3f seconds - status %d',
		length( $response->content // '' ),
		time - $start,
		$response->code
	);

	if ( !$response->is_success ) {
		$self->{log}
		    ->warning( 'Not caching failed response: %s (status %d)',
			$url, $response->code );
		return $response;
	}
	if ( !$self->{cache}->is_cacheable( $url, $response->code ) ) {
		$self->{log}->debug( 'URL not cacheable: %s', $url );
		return $response;
	}

	my $path = $self->{cache}->store( $url, $response->content );
	if ( defined $path ) {
		$self->{meta}->store( $url, $path, $self->{cache} );
		$self->{log}->info( 'Cached to: %s', $path );
	}
	else {
		$self->{log}->warning( 'Failed to cache: %s', $url );
	}

	return $response;
}

sub _forward ( $self, $request )
{
	my $agent = LWP::UserAgent->new(
		timeout => 300,
		agent   => 'Fugu-Proxy/1.0',
	);

	my $forwarded = HTTP::Request->new(
		$request->method,
		$request->uri->as_string,
		$request->headers->clone,
	);
	$forwarded->content( $request->content ) if $request->content;

	return $agent->request($forwarded);
}

# $self->_serve_streaming($socket, $meta, $request):
#	Write the response straight to the socket, in large chunks. A
#	file set is hundreds of megabytes, so the whole-file path would
#	hold all of it in memory for every client.
sub _serve_streaming ( $self, $socket, $meta, $request )
{
	# Nagle's algorithm delays a large transfer for no benefit
	# here, and a bigger send buffer cuts the syscall count.
	setsockopt( $socket, IPPROTO_TCP, TCP_NODELAY, 1 );
	setsockopt( $socket, SOL_SOCKET,  SO_SNDBUF, pack( 'I', SEND_BUFFER ) );

	my $if_none_match = $request->header('If-None-Match');
	if ( defined $if_none_match && $if_none_match eq $meta->{etag} ) {
		$self->{log}->info('Sending 304 Not Modified');
		$self->_send_headers( $socket, 304, 'Not Modified',
			{ ETag => $meta->{etag} } );
		return 1;
	}

	$self->_send_headers(
		$socket, 200, 'OK',
		{
			'Content-Type'   => $meta->{content_type},
			'Content-Length' => $meta->{size},
			'X-Cache'        => 'HIT',
			'ETag'           => $meta->{etag},
		} );

	return 1 if $request->method ne 'GET';

	my $start = time;
	my $sent = $self->_stream_file( $socket, $meta->{path}, $meta->{size} );
	if ( defined $sent ) {
		$self->{log}->debug( 'Streamed %d bytes in %.3f seconds',
			$sent, time - $start );
	}
	else {
		$self->{log}->error( 'Stream failed for: %s', $meta->{path} );
	}

	return 1;
}

sub _send_headers ( $self, $socket, $code, $message, $headers )
{
	my $head = "HTTP/1.1 $code $message\r\n";
	$head .= "$_: $headers->{$_}\r\n" for sort keys %$headers;
	$head .= "\r\n";

	return Fugu::File->_write_all( $socket, $head, 'client socket' );
}

sub _stream_file ( $self, $socket, $path, $size )
{
	open my $fh, '<', $path or do {
		$self->{log}->error( 'Cannot open %s: %s', $path, $! );
		return;
	};
	binmode $fh;

	my $sent      = 0;
	my $remaining = $size;
	while ( $remaining > 0 ) {
		my $want =
		    $remaining < STREAM_CHUNK ? $remaining : STREAM_CHUNK;
		my $buffer;
		my $n = sysread( $fh, $buffer, $want );
		if ( !$n ) {
			$self->{log}->error( 'Read error after %d bytes: %s',
				$sent, $! );
			last;
		}

		unless ( Fugu::File->_write_all( $socket, $buffer, $path ) ) {
			$self->{log}->error( 'Write error after %d bytes: %s',
				$sent, $! );
			close $fh;
			return;
		}

		$sent      += $n;
		$remaining -= $n;
	}
	close $fh;

	return $sent;
}

package Fugu::Proxy::Cache;
our $VERSION = '0.1.2';

use File::Basename qw(dirname);
use Fugu::File;
use Fugu::Log;

# Fugu::Proxy::Cache - the URL-to-file store under the proxy.
#
# A cached URL becomes <dir>/proxy/<host>/<path>. The layout is the
# URL, so a person can find a file and a mirror tree survives a
# restart of the proxy.
#
# Which URL is worth caching is a callback, because the answer belongs
# to the mirror and not to HTTP.

# The content types that a mirror serves. A caller adds to the table
# through the types argument.
my %CONTENT_TYPE = (
	qr{\.tgz$}          => 'application/x-gzip',
	qr{\.gz$}           => 'application/gzip',
	qr{\.img$}          => 'application/octet-stream',
	qr{\.txt$}          => 'text/plain',
	qr{SHA256(\.sig)?$} => 'text/plain',
	qr{BUILDINFO$}      => 'text/plain',
);

# Fugu::Proxy::Cache->new(%args):
#	dir       => $path		the cache root (required)
#	cacheable => sub ($url)		which URL is worth keeping
#	types     => \%table		extra content types, pattern to type
#
#	The default cacheable callback says no. A cache that guesses
#	fills a home directory with pages nobody will read again.
sub new ( $class, %args )
{
	my $dir = $args{dir};
	die 'dir parameter required' unless defined $dir && length $dir;

	my $self = bless {
		dir       => $dir,
		cacheable => $args{cacheable} // sub ($) { 0 },
		types     => { %CONTENT_TYPE, %{ $args{types} // {} } },
	}, $class;

	Fugu::File->ensure_dir( $self->root );

	return $self;
}

# $self->dir:
#	Return the cache root, the directory the caller named.
sub dir ($self)
{
	return $self->{dir};
}

# $self->root:
#	Return the directory that holds the mirrored tree.
sub root ($self)
{
	return "$self->{dir}/proxy";
}

# $self->cache_path($url):
#	Map a URL to its file. The method returns undef for a URL that
#	would escape the cache root: no host, an empty path, or a path
#	that walks up.
sub cache_path ( $self, $url )
{
	require URI;

	my $uri = URI->new($url);
	return if !$uri->can('host');

	my $host = $uri->host // return;
	return if $host eq '' || $host =~ m{[/\\]};

	my $path = $uri->path // return;
	$path =~ s{^/}{};
	return if $path eq '' || $path =~ /\.\./;

	return $self->root . "/$host/$path";
}

# $self->is_cacheable($url, $status):
#	Ask the callback. Only a successful response is a candidate: a
#	cached 404 is a mirror that stays broken after the upstream is
#	fixed.
sub is_cacheable ( $self, $url, $status = 200 )
{
	return 0 if $status != 200;

	return $self->{cacheable}->($url) ? 1 : 0;
}

# $self->content_type($path):
#	Return the content type for a file, from the table.
sub content_type ( $self, $path )
{
	for my $pattern ( sort { "$a" cmp "$b" } keys %{ $self->{types} } ) {
		return $self->{types}{$pattern} if $path =~ /$pattern/;
	}

	return 'application/octet-stream';
}

# $self->lookup($url):
#	Return the cached file for a URL, or undef.
sub lookup ( $self, $url )
{
	my $path = $self->cache_path($url) // return;

	return -f $path ? $path : undef;
}

# $self->store($url, $content):
#	Write the content to the cache. The write is atomic, so a
#	client that reads while another writes never gets a partial
#	file. The method returns the path, or undef.
sub store ( $self, $url, $content )
{
	my $path = $self->cache_path($url) // return;

	Fugu::File->ensure_dir( dirname($path) )    or return;
	Fugu::File->write_atomic( $path, $content ) or return;

	return $path;
}

# $self->store_from_file($url, $source):
#	Put a file that is already on disk into the cache.
sub store_from_file ( $self, $url, $source )
{
	my $path = $self->cache_path($url) // return;

	Fugu::File->ensure_dir( dirname($path) ) or return;

	require File::Copy;
	File::Copy::copy( $source, $path ) or do {
		Fugu::Log->default->warning( 'Cannot copy %s to %s: %s',
			$source, $path, $! );
		return;
	};

	return $path;
}

# $self->size:
#	Return the total bytes of the cached files.
sub size ($self)
{
	return $self->dir_size( $self->root );
}

# $self->list:
#	Return every cached file as { url, path, size }.
sub list ($self)
{
	my $root = $self->root;
	my @files;

	$self->walk(
		$root,
		sub ($path) {
			my $url = $self->path_to_url($path) // return;
			push @files,
			    { url => $url, path => $path, size => -s $path };
		} );

	return \@files;
}

# $self->clear:
#	Remove every cached file.
sub clear ($self)
{
	my $root = $self->root;
	return 1 if !-d $root;

	require File::Path;
	File::Path::remove_tree($root);
	Fugu::File->ensure_dir($root);

	return 1;
}

# $self->path_to_url($path):
#	Rebuild the URL that a cached file came from.
sub path_to_url ( $self, $path )
{
	my $root = $self->root;
	return unless $path =~ s{^\Q$root\E/}{};

	my ( $host, @rest ) = split m{/}, $path;
	return unless defined $host && @rest;

	return "http://$host/" . join( '/', @rest );
}

# $self->dir_size($dir):
#	Return the total bytes of the regular files under a directory.
sub dir_size ( $self, $dir )
{
	my $total = 0;
	$self->walk( $dir, sub ($path) { $total += ( -s $path ) // 0 } );

	return $total;
}

# $self->walk($dir, $callback):
#	Call the callback for every regular file under a directory.
#	One walker serves the size, the listing and the metadata warm.
sub walk ( $self, $dir, $callback )
{
	return unless -d $dir;

	opendir my $dh, $dir or return;
	my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
	closedir $dh;

	for my $entry ( sort @entries ) {
		my $path = "$dir/$entry";
		if ( -d $path ) {
			$self->walk( $path, $callback );
			next;
		}
		$callback->($path) if -f $path;
	}

	return;
}

package Fugu::Proxy::Meta;
our $VERSION = '0.1.2';

# Fugu::Proxy::Meta - the metadata of the cached files, in memory.
#
# A hit needs the size, the content type and an ETag. Without this
# table the proxy stats the file and guesses the type again for every
# request. The entry carries the size and the mtime it was built from,
# so a file that changed under the proxy invalidates its own entry.

sub new ($class)
{
	return bless { entries => {} }, $class;
}

# $self->lookup($url):
#	Return the metadata for a URL, or undef. An entry whose file is
#	gone, or whose size or mtime changed, is not valid and the
#	method reports it as absent.
sub lookup ( $self, $url )
{
	my $entry = $self->{entries}{$url} or return;

	my @stat = stat $entry->{path};
	return unless @stat;
	return unless $stat[7] == $entry->{size} && $stat[9] == $entry->{mtime};

	return $entry;
}

# $self->store($url, $path):
#	Build the metadata for a file. The method returns the entry, or
#	undef when the file does not stat.
sub store ( $self, $url, $path, $cache = undef )
{
	my @stat = stat $path;
	return unless @stat;

	my ( $size, $mtime ) = ( $stat[7], $stat[9] );

	my $entry = {
		path         => $path,
		size         => $size,
		mtime        => $mtime,
		content_type => $cache
		? $cache->content_type($path)
		: 'application/octet-stream',
		etag => sprintf( '"%x-%x"', $mtime, $size ),
	};
	$self->{entries}{$url} = $entry;

	return $entry;
}

# $self->count:
#	Return the number of entries.
sub count ($self)
{
	return scalar keys %{ $self->{entries} };
}

# $self->warm($cache):
#	Build an entry for every file already in the cache. The method
#	returns the count.
sub warm ( $self, $cache )
{
	$cache->walk(
		$cache->root,
		sub ($path) {
			my $url = $cache->path_to_url($path) or return;
			$self->store( $url, $path, $cache );
		} );

	return $self->count;
}

1;
