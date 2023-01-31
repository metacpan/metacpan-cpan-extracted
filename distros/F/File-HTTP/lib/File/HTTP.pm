# open a filehanlde to an HTTP URL and read it as if it was a seekable file
package File::HTTP;
use strict;
use warnings;
use Carp;
use Symbol ();
use Socket ();
use Errno ();
use Fcntl ();
use Exporter;
use bytes ();
use Time::HiRes qw(time);
use constant 1.03; # hash ref, perl 5.7.2

# on demand modules:
# - Time::y2038 or Time::Local
# - IO::Socket::SSL

our $VERSION = '1.01';

our @EXPORT_OK = qw(
	open stat open_at open_stream slurp_stream get post
	opendir readdir rewinddir telldir seekdir closedir 
	opendir_slash
	_e _s
);

our %EXPORT_TAGS = ( 
	all	=> \@EXPORT_OK,
	open	=> [qw(open stat _s _e)],
	opendir	=> [qw(opendir readdir rewinddir telldir seekdir closedir)],
);

sub import {
	if (grep {$_ eq '-everywhere'} @_) {
		@_ = grep {$_ ne '-everywhere'} @_;
		eval join(';', map {"*CORE::GLOBAL::$_ = \\&File::HTTP::$_"} qw(open stat opendir readdir rewinddir telldir seekdir closedir));
	}
	goto \&Exporter::import;
}

use constant DEBUG => 0;

# define instance variables
use constant FIELDS => qw(
	URL
	PROTO
	HOST
	REMOTE_HOST
	OFFSET
	CURRENT_OFFSET
	CONTENT_LENGTH
	PORT
	PATH
	REAL_PATH
	IP
	NETLOC
	CONNECT_NETLOC
	MTIME
	LAST_MODIFIED
	CONTENT_TYPE
	HTTP_VERSION
	FH
	FH_STAT
	LAST_READ
	AUTH
	LAST_HEADERS_SIZE
	SSL
	
	REQUEST_TIME
	RESPONSE_TIME

	NO_CLOSE_ON_DESTROY
	
	DIR_LIST
	DIR_POS
);

# build instance variable constants (ala enum::fields)
use constant do {my $i=-1; +{ map {$_ => ++$i} FIELDS } };

# speed up socket constant calls by making them *really* constant
use constant AF_INET		=> &Socket::AF_INET;
use constant SOCK_STREAM	=> &Socket::SOCK_STREAM;
use constant IPPROTO_TCP	=> &Socket::IPPROTO_TCP;
use constant SOL_SOCKET		=> &Socket::SOL_SOCKET;
use constant SO_LINGER		=> &Socket::SO_LINGER;
use constant DONT_LINGER	=> pack(II => 1, 0);
use constant READ_MODE		=> &Fcntl::S_IRUSR | &Fcntl::S_IRGRP | &Fcntl::S_IROTH;

# user modifiable global parameters
our $REQUEST_HEADERS;
our $RESPONSE_HEADERS;
our $IGNORE_REDIRECTIONS;
our $IGNORE_ERRORS;
our $VERBOSE;
our $DEBUG_SLOW_CONNECTION;
our $MAX_REDIRECTIONS		= 7;
our $MAX_HEADER_LINES		= 50;
our $MAX_HEADER_SIZE		= 65536;
our $MAX_SEC_NO_CLOSE		= 3;
our $MAX_LENGTH_SKIP		= 256*1024;
our $USER_AGENT			= __PACKAGE__. '/'. $VERSION;
our $TUNNELING_USER_AGENT;	# default to $USER_AGENT when undefined

if (DEBUG) {
	$VERBOSE = 1;
	$DEBUG_SLOW_CONNECTION = 1;
}

my $SSL_LOADED;
my $TIME_GM_CODE;

my %Mon_str2num = do {
	my $i=-1;
	map {$_ => ++$i} qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
};

#for (keys %!) {
#	$! = Errno->$_;
#	print "$_ : ", 0+$!, " $!\n";
#}
#exit;

my %HTTP2FS_error = (
	# No such file or directory
	404	=> &Errno::ENOENT, 
	410	=> &Errno::ENOENT,
	503	=> &Errno::ENOENT,

	# Permission denied
	401	=> &Errno::EACCES,
	402	=> &Errno::EACCES,
	403	=> &Errno::EACCES,

	# Function not implemented
	200	=> &Errno::ENOSYS,
);

my %Proto2Port = (
	HTTP	=> 80,
	HTTPS	=> 443,
);

sub stat ($) {
	my $arg = shift;
	if (defined($arg) && ref($arg)) {
		if ($arg->isa('File::HTTP')) {
			$arg->STAT
		}
		elsif (my $self = tied(*$arg)) {
			$self->STAT
		}
		else {
			CORE::stat($arg)
		}
	}
	elsif ($arg =~ m!^https?://!i) {
		my $self = TIEHANDLE(__PACKAGE__, $arg, 0, \(my $err));
		if ($self) {
			$self->STAT
		} else {
			$! = $err;
			()
		}
	}
	else {
		CORE::stat($arg)
	}
}

sub _s ($) {
	[ File::HTTP::stat $_[0] ]->[7]
}

sub _e ($) {
	defined _s($_[0])
}

sub opendir_slash ($$) {
	my $dir = pop;

	if (($dir||'') =~ m!^https?://!) {
		$_[0] ||= Symbol::gensym();
		my $self = tie(*{$_[0]}, __PACKAGE__, $dir, undef, \(my $err));
		unless ($self) {
			$! = $err;
			return;
		}

		my $path = $self->[REAL_PATH];
		$path =~ s/\?.*$//;
	
		my $fh = $self->[FH];
		
		local $/;
		$self->[DIR_LIST] = [ '.', '..', grep {not m!^\.\.?/?!} <$fh> =~ m! href="(?:(?:$self->[PROTO]://)?$path)?([^/\?"]+/?)"!g ];
		$self->[DIR_POS] = 0;
		1	
	} else {
		CORE::opendir($_[0], $dir)
	}
}

sub opendir ($$) {
	my $dir = pop;
	
	if (($dir||'') =~ m!^https?://!) {
		$_[0] ||= Symbol::gensym();
		my $self = tie(*{$_[0]}, __PACKAGE__, $dir, undef, \(my $err));
		unless ($self) {
			$! = $err;
			return;
		}
		
		my $path = $self->[REAL_PATH];
		$path =~ s/\?.*$//;
	
		my $fh = $self->[FH];
		
		local $/;
		$self->[DIR_LIST] = [ '.', '..', grep {not m!^\.\.?/?!} <$fh> =~ m! href="(?:(?:$self->[PROTO]://)?$path)?([^/\?"]+)/?"!g ];
		$self->[DIR_POS] = 0;
		1	
	} else {
		CORE::opendir($_[0], $dir)
	}
}

sub readdir ($) {
	my $dirh = shift;
	my $self = tied(*$dirh) || return CORE::readdir($dirh);
	unless($self->[DIR_LIST]) {
		$! = &Errno::ENOSYS; # XXX should be 'Inappropriate ioctl for device'
		return
	}
	
	if (wantarray) {
		if ($self->[DIR_POS]) {
			@{$self->[DIR_LIST]}[$self->[DIR_POS]..$#{$self->[DIR_LIST]}];
		} else {
			@{$self->[DIR_LIST]}
		}
	} else {
		$self->[DIR_LIST]->[$self->[DIR_POS]++];
	}
}

sub rewinddir ($) {
	my $dirh = shift;
	my $self = tied(*$dirh) || return CORE::rewinddir($dirh);
	unless($self->[DIR_LIST]) {
		$! = &Errno::ENOSYS; # XXX should be 'Inappropriate ioctl for device'
		return
	}
	$self->[DIR_POS] = 0;
	1
}

sub telldir ($) {
	my $dirh = shift;
	my $self = tied(*$dirh) || return CORE::telldir($dirh);
	unless($self->[DIR_LIST]) {
		$! = &Errno::ENOSYS; # XXX should be 'Inappropriate ioctl for device'
		return
	}
	$self->[DIR_POS]
}

sub seekdir ($$) {
	my ($dirh, $pos) = @_;
	my $self = tied(*$dirh) || return CORE::seekdir($dirh, $pos);
	unless($self->[DIR_LIST]) {
		$! = &Errno::ENOSYS; # XXX should be 'Inappropriate ioctl for device'
		return
	}
	$self->[DIR_POS] = $pos;
	1
}

sub closedir ($) {
	my $dirh = shift;
	my $self = tied(*$dirh) || return CORE::closedir($dirh);
	unless($self->[DIR_LIST]) {
		$! = &Errno::ENOSYS; # XXX should be 'Inappropriate ioctl for device'
		return
	}
	$self->[FH] = undef;
	$self->[DIR_LIST] = undef;
	$self->[DIR_POS] = undef;
}

sub open ($;$$) {
	return CORE::open($_[0]) if @_==1;
	my $file = pop;
	my $mode;
	
	if (@_==2) {
		$mode = pop;
	}
	elsif ($file =~ s/^([+<>|]+)\s*//) {
		$mode = $1;
	}
	else {
		$mode = '<';
	}
	
	if (($file||'') =~ m!^https?://!) {
		if ($mode =~ /^\s*<(?:\s*\:raw)?\s*$/) {
			$_[0] ||= Symbol::gensym();
			tie(*{$_[0]}, __PACKAGE__, $file, 0, \(my $err)) && return 1;
			$! = $err;
			return;
		}
		elsif ($mode =~ /<|\+/) {
			$! = &Errno::EROFS; # Read-only file system
			return undef;
		}
		else {
			# pipes, layers other than raw, and anything else is invalid
			$! = &Errno::EINVAL; # Invalid argument
			return undef
		}
	} else {
		CORE::open($_[0], $mode, $file)
	}
}

sub open_at ($$;$) {
	my (undef, $file, $offset) = @_;
	$offset ||= 0; # no undef

	if (($file||'') =~ m!^https?://!) {
		$_[0] ||= Symbol::gensym();
		tie(*{$_[0]}, __PACKAGE__, $file, $offset, \(my $err)) && return 1;
		$! = $err;
		return;
	} else {
		CORE::open($_[0], '<', $file);
		no warnings;
		seek($_[0], $offset, 0) if $offset && $_[0];
		return $_[0];
	}
}

sub open_stream ($;$) {
	my ($url, $offset) = @_;
	$url = "http://$url" unless $url =~ m!^https?://!i;
	my $self = TIEHANDLE(__PACKAGE__, $url, $offset, \(my $err), 1);
	unless ($self) {
		$! = $err;
		return;
	}
	@$self[CONTENT_LENGTH, FH]
}

sub slurp_stream {
	my $url = shift;
	my $fh = open_stream($url) || return;
	if (wantarray) {
		<$fh>
	} else {
		local $/;
		<$fh>
	}
}

sub get {
	# args: url, follow redirections
	my $url = shift;
	local $IGNORE_REDIRECTIONS = not shift;
	local $IGNORE_ERRORS = 1;
	local $REQUEST_HEADERS;
	local $RESPONSE_HEADERS;
	my $fh = open_stream($url);
	return (
		$REQUEST_HEADERS,
		$RESPONSE_HEADERS || "HTTP/1.0 502 Bad Gateway\015\012Content-Length: 0\015\012\015\012",
		$fh ? do {local $/; <$fh>} : ''
	)
}

sub post {
	# args: url, type, body
	# does not follow redirections
	my $url = shift;
	my $type = shift;

	my ($proto, undef, $host, $port, $path) = $url =~ m!^(https?)://(?:([^/:]+:[^/@]+)@)?([^/:]+)(?:\:(\d+))?(/[^#]+)?!i;

	$proto = uc $proto;
	$port ||= $Proto2Port{$proto};
	$path ||= '/';
	my $netloc = ($port==$Proto2Port{$proto}) ? $host : "$host:$port";

	local $IGNORE_REDIRECTIONS = 1;
	local $IGNORE_ERRORS = 1;
	local $RESPONSE_HEADERS;
	local $REQUEST_HEADERS = \join("\015\012",
		"POST $path HTTP/1.0",
		"Host: $netloc",
		"User-Agent: $USER_AGENT",
		($type ? ("Content-Type: $type") : ()),
		'Content-Length: '. bytes::length($_[0]),
		"Connection: close",
		'',
		$_[0]
	);
	my $fh = open_stream($url);
	return (
		$REQUEST_HEADERS,
		$RESPONSE_HEADERS || "HTTP/1.0 502 Bad Gateway\015\012Content-Length: 0\015\012\015\012",
		$fh ? do {local $/; <$fh>} : ''
	)
}

sub _connected {
	my $self = shift;
	no warnings;
	return $self->[FH] && time - $self->[LAST_READ] <= $MAX_SEC_NO_CLOSE;
}

sub _handshake {
	my ($self, $req_headers) = @_;

	my $fh = $self->[FH];
	DEBUG && warn $req_headers;
	my $headers;
	{
		no warnings;
		print($fh $req_headers) || die "error: ".&Errno::EIO."\nwhen sending request:\n$req_headers"; # Input/output error;
		# shutdown($fh, 1);
		$self->_read($headers, 5) || die "error: ".&Errno::EIO."\nwhen reading response headers from request:\n$req_headers"; # Input/output error;
	}
	unless (defined($headers) && $headers eq 'HTTP/') {
		die "error: wrong HTTP headers\n";
	}
	local $/ = "\n";
	$headers .= <$fh>; # first line complete
	if ($headers !~ m!^HTTP/[\d\.]+ (\d+)! or bytes::length($headers) > $MAX_HEADER_SIZE) {
		die "error: wrong HTTP headers\n"
	}
	my $code = $1;
	my $nb_lines = 1;
	for (;;) {
		my $line = <$fh>;
		die "error: wrong HTTP headers\n" unless defined $line;
		$headers .= $line;
		last unless $line =~ /\S/;
		if (++$nb_lines > $MAX_HEADER_LINES or bytes::length($headers) > $MAX_HEADER_SIZE) {
			die "error: HTTP headers too long\n"
		}
	}
	$self->[LAST_HEADERS_SIZE] += bytes::length($headers);
	DEBUG && warn $headers;
	DEBUG && warn time - $self->[REQUEST_TIME];
	
	return ($code, $headers);
}

sub _initiate {
	my $self = shift;
	return 0 if $self->EOF;
	$self->[LAST_HEADERS_SIZE] ||= 0;
	if ($self->_connected) {
		if ($self->[CURRENT_OFFSET] == $self->[OFFSET]) {
			DEBUG && print STDERR "[same offset]";
			$self->[LAST_READ] = time;
			return 1;
		}
		elsif ($self->[OFFSET] > $self->[CURRENT_OFFSET] && $self->[OFFSET]-$self->[CURRENT_OFFSET] < $MAX_LENGTH_SKIP+$self->[LAST_HEADERS_SIZE]) {
			DEBUG && warn "skip\n";
			my $to_skip = $self->[OFFSET]-$self->[CURRENT_OFFSET];
			$self->_read(my $buf, $to_skip)==$to_skip or return;
			$self->[CURRENT_OFFSET] = $self->[OFFSET];
			$self->[LAST_READ] = time;
			return 1;
		}
		DEBUG && print STDERR "[close]";
	}
	elsif (DEBUG) {
		warn "not connected";
	}

	$REQUEST_HEADERS = ($REQUEST_HEADERS && ref $REQUEST_HEADERS) ? $$REQUEST_HEADERS : do {
		my @h = (
			"GET $self->[PATH] HTTP/1.0",
			"Host: $self->[NETLOC]",
			"User-Agent: $USER_AGENT",
			"Connection: close",
		);
		# push @h, "Proxy-Connection: close" if $self->[CONNECT_NETLOC] && $self->[PROTO] ne 'HTTPS';
		push @h, "Range: bytes=$self->[OFFSET]-" if defined $self->[OFFSET];
		push @h, "Authorization: Basic ". MIME::Base64::encode_base64($self->[AUTH]) if $self->[AUTH];
	
	 	join("\015\012", @h, '', '')
	};

	die "error: ".&Errno::EFAULT unless $self->[IP]; # Bad address

	if ($self->[FH]) {
		# shutdown($self->[FH], 2);
		CORE::close($self->[FH]);
		# select(undef, undef, undef, 0.1);
	}
	$self->[FH] = undef;
	$self->[REQUEST_TIME] = time;
	($self->[HTTP_VERSION]) = $REQUEST_HEADERS =~m! HTTP/(\d+\.\d+)\r?\n!;
	$self->[HTTP_VERSION] += 0;
	$self->[LAST_HEADERS_SIZE] = 0;
	socket($self->[FH], AF_INET, SOCK_STREAM, IPPROTO_TCP) || die $!;
	# setsockopt($self->[FH], SOL_SOCKET, SO_LINGER, DONT_LINGER) || die $!;

	select((select($self->[FH]), $|=1)[0]); # autoflush
	for (1..10) {
		my $t = $DEBUG_SLOW_CONNECTION && time;
		my $status = connect($self->[FH], Socket::sockaddr_in($self->[PORT], $self->[IP]));
		if ($DEBUG_SLOW_CONNECTION && time-$t >= .4) {
			warn sprintf "\nSLOW %s CONNECTION to %s:%d: %s", ($status ? 'SUCCESS' : 'FAILED'), $self->[HOST], $self->[PORT], time-$t;
		}
		last if $status;
		die $! unless $_ < 3 && $! =~ /Interrupted system call/i;
	}
	
	$self->[FH_STAT] ||= [ CORE::stat($self->[FH]) ];

	if ($self->[PROTO] eq 'HTTPS') {
		$self->[SSL] = 1;
		unless ($SSL_LOADED) {
			eval {require IO::Socket::SSL;1} || croak "HTTPS support requires IO::Socket::SSL: $@";
			$SSL_LOADED = 1;
		}
		if ($self->[CONNECT_NETLOC]) {
			my ($code, $headers) = $self->_handshake(
				join("\015\012",
					"CONNECT $self->[CONNECT_NETLOC] HTTP/1.0",
					"User-Agent: ". ($TUNNELING_USER_AGENT||$USER_AGENT),
					'',
					''
				)
			);
			die "error: HTTP error $code from proxy during CONNECT\n" unless $code == 200;
		}

		IO::Socket::SSL->start_SSL($self->[FH],
			SSL_verifycn_name => $self->[REMOTE_HOST],
			SSL_hostname => $self->[REMOTE_HOST],
			SSL_session_cache_size => 100,
			SSL_verify_mode => &IO::Socket::SSL::SSL_VERIFY_NONE,
		);
	}

	(my $code, $RESPONSE_HEADERS) = $self->_handshake($REQUEST_HEADERS);

	$self->[RESPONSE_TIME] = time;

	my $code_ok = do {
		if (defined $self->[OFFSET]) {
			$code == 206
		} else {
			$code == 200 || $code == 204
		}
	};

	if (!$code_ok) {
		if ($code =~ /^3/ && $RESPONSE_HEADERS =~ /\015?\012Location: ([^\015\012]+)/i) {
			die "redirection: $1\n" unless $IGNORE_REDIRECTIONS;
		}
		elsif (!$IGNORE_ERRORS) {
			$self->[CONTENT_LENGTH] ||= ($RESPONSE_HEADERS =~ /\015?\012Content-Length: (\d+)/i && $1);
			if ($code =~ /^200$|^416$/ && $self->[OFFSET] >= $self->[CONTENT_LENGTH]) {
				DEBUG && warn "out of range\n";
				CORE::open($self->[FH] = undef, '<', '/dev/null') || CORE::open($self->[FH] = undef, '<', 'nul');
			} else {
				$! = $HTTP2FS_error{$code} || &Errno::ENOSYS; # ENOSYS: Function not implemented
				$VERBOSE && $code==200 && carp "Server does not support range queries. Consider using open_stream() instead of open()";
				die "error: ", 0+$!, "\n";
			}
		}
	}
	if ($RESPONSE_HEADERS =~ m!\015?\012Transfert-Encoding: +chunked!i && $self->[HTTP_VERSION] <= 1) {
		$! = $HTTP2FS_error{$code} || &Errno::ENOSYS; # ENOSYS: Function not implemented
		die "error: ", 0+$!, "\n";
	}
	
	unless (defined $self->[CONTENT_LENGTH]) {
		($self->[CONTENT_LENGTH]) = $RESPONSE_HEADERS =~ m!\015?\012Content-Range: +bytes +\d*-\d*/(\d+)!i;
		unless (defined $self->[CONTENT_LENGTH]) {
			($self->[CONTENT_LENGTH]) = $RESPONSE_HEADERS =~ m!\015?\012Content-Length: (\d+)!i;
		}
	}
	unless (defined $self->[CONTENT_TYPE]) {
		($self->[CONTENT_TYPE]) = $RESPONSE_HEADERS =~ m!\015?\012Content-Type: +([^\015\012]+)!i;
	}
	unless (defined $self->[LAST_MODIFIED]) {
		($self->[LAST_MODIFIED]) = $RESPONSE_HEADERS =~ m!\015?\012Last-Modified: +([^\015\012]+)!i;
	}
	
	return unless defined $self->[OFFSET];
	
	$self->[LAST_READ] = $self->[RESPONSE_TIME];
	$self->[CURRENT_OFFSET] = $self->[OFFSET];
	return 1;
}

# read() reimplementation to overcome IO::Socket::SSL behavior of read() acting as sysread()
# <> is ok though
sub _read {
	my ($self, undef, $len, $off) = @_;
	
	if (not defined $off)  {
		$off = 0;
	}
	elsif ($off < 0) {
		$off += bytes::length($_[1])
	}
	
	my $n = read($self->[FH], $_[1], $len, $off);
	return $n unless $n;
	
	if ($self->[SSL] && $len && $n < $len) {
		# strange IO::Socket::SSL behavior: read() acts as sysread()
		while ($n < $len) {
			my $n_part = read($self->[FH], $_[1], $len-$n, $off+$n);
			return $n unless $n_part;
			$n += $n_part;
		}
	}
	
	return $n;
}

sub TIEHANDLE {
	my ($class, $url, $offset, $err_ref, $no_close_on_destroy) = @_;
	my $self = bless [], $class;
	my $redirections = 0;

	$self->[NO_CLOSE_ON_DESTROY] = $no_close_on_destroy;

	SET_URL: {
		$self->[URL] = $url;
		$self->[OFFSET] = $offset;
		$self->[CURRENT_OFFSET] = $offset;
		($self->[PROTO], $self->[AUTH], $self->[HOST], $self->[PORT], $self->[PATH]) = $url =~ m!^(https?)://(?:([^/:]+:[^/@]+)@)?([^/:]+)(?:\:(\d+))?(/[^#]+)?!i;
		$self->[REMOTE_HOST] = $self->[HOST];

		if ($self->[AUTH]) {
			require MIME::Base64;
			#$VERBOSE && carp "authentication in URI is not supported";
			#$$err_ref = &Errno::EFAULT; # Bad address
			#return undef;
		}
		$self->[PROTO] = uc($self->[PROTO]);
		$self->[PORT] ||= $Proto2Port{$self->[PROTO]};
		$self->[PATH] ||= '/';
		$self->[NETLOC] = ($self->[PORT]==$Proto2Port{$self->[PROTO]}) ? $self->[HOST] : "$self->[HOST]:$self->[PORT]";
		$self->[CONNECT_NETLOC] = '';
		
		# PATH will change in case of proxy
		$self->[REAL_PATH] = $self->[PATH]; 
		
		# handle proxy
		my $proxy = $self->[PROTO] eq 'HTTPS' ? $ENV{HTTPS_PROXY}||$ENV{HTTP_PROXY} : $ENV{HTTP_PROXY};
		if ($proxy) {
			my $no_proxy = join('|', map {s/^\*?\.//;$_} split(/[, ]+/, $ENV{NO_PROXY}||''));
			
			unless (
				($self->[HOST] eq '127.0.0.1')
				||
				($self->[HOST] eq 'localhost')
				||
				($no_proxy && $self->[HOST] =~ /$no_proxy$/i)
			) {
				# apply proxy
				if ($proxy =~ m!^https://!) {
					$VERBOSE && carp "proxies with HTTPS address are not supported";
					$$err_ref = &Errno::EFAULT; # Bad address
					return undef;
				}
				$self->[CONNECT_NETLOC] = "$self->[HOST]:$self->[PORT]";
				($self->[HOST], $self->[PORT]) = $proxy =~ m!^(?:http://)?([^/:]+)(?:\:(\d+))?!i;
				$self->[PORT] ||= $Proto2Port{$self->[PROTO]};
				$self->[PATH] = $self->[URL];
				DEBUG && warn "Proxy: $self->[HOST]:$self->[PORT]\n";
			}
		}

		$self->[IP] = Socket::inet_aton($self->[HOST]);
		eval { $self->_initiate };

		if ($@) {
			if ($@ =~ /^redirection: ([^\n]+)/) {
				my $location = $1;
				if (++$redirections > $MAX_REDIRECTIONS) {
					$VERBOSE && carp "too many redirections";
					$$err_ref = &Errno::EFAULT; # Bad address
					return undef;
				}
				if ($location =~ m!^https?://!i) {
					$url = $location;
				}
				elsif ($location =~ m!^//!) {
					$url =~ m!^(https?:)//!;
					$url = $1.$location;
				}
				elsif ($location =~ m!^/!) {
					$url =~ m!^(https?://[^/]+)!;
					$url = $1.$location;
				}
				else {
					$url =~ s!#.*!!;
					$url =~ s![^/]+$!!;
					$url .= $location;
				}
				redo SET_URL;
			}
			elsif ($@ =~ /^error: (\d+)/) {
				$VERBOSE && carp $@;
				$$err_ref = $1;
				return undef;
			}
			elsif ($@ =~ /^HTTPS support/) {
				die $@;
			}
			else {
				$VERBOSE && carp $@;
				$$err_ref = &Errno::EIO; # Input/output error
				return undef;
			}			
		}
		
		if (defined($self->[OFFSET]) && not defined $self->[CONTENT_LENGTH]) {
			$$err_ref = &Errno::ENOSYS; # Function not implemented
			return undef;
		}
	}

	$self
}

sub GETC {
	my $self = shift;
	$self->_initiate || return undef;
	my $n = read($self->[FH], my $buf, 1); # no need for _read(), reading one byte is ok
	return unless $n; # eof or error
	++$self->[OFFSET];
	$self->[CURRENT_OFFSET] = $self->[OFFSET];
	return $buf;
}

sub READ {
	my ($self, undef, $len, $off) = @_;
	my $state = $self->_initiate;
	return $state unless $state; # 0 if eof, undef on error
	my $n = $self->_read($_[1], $len, $off);
	unless ($n) {
		$! = &Errno::EIO if defined $n; # unsuspected close => Input/output error
		return undef;
	}
	$self->[OFFSET] += $n;
	$self->[CURRENT_OFFSET] = $self->[OFFSET];
	return $n;
}

sub READLINE {
	my $self = shift;
	$self->_initiate || return;
	my $fh = $self->[FH];
	if (wantarray) {
		$self->[OFFSET] = $self->[CONTENT_LENGTH];
		$self->[CURRENT_OFFSET] = $self->[OFFSET];
		return <$fh>;
	} else {
		my $line = <$fh>;
		$self->[OFFSET] += bytes::length($line);
		$self->[CURRENT_OFFSET] = $self->[OFFSET];
		return $line;
	}
}

sub EOF {
	my $self = shift;
	defined($self->[CONTENT_LENGTH]) && $self->[OFFSET] >= $self->[CONTENT_LENGTH]
}

sub TELL {
	$_[0]->[OFFSET]
}

sub SEEK {
	my ($self, $offset, $whence) = @_;
	unless ($whence) {
		$self->[OFFSET] = $offset
	}
	elsif ($whence == 1) {
		$self->[OFFSET] += $offset
	}
	elsif ($whence == 2) {
		$self->[OFFSET] = $self->[CONTENT_LENGTH] - $offset
	}
	else {
		return undef
	}
	1
}

sub WRITE {
	croak "Filehandle opened only for input"
}

sub PRINT {
	croak "Filehandle opened only for input"
}

sub PRINTF {
	croak "Filehandle opened only for input"
}

sub BINMODE {
	1
}

sub CLOSE {
	my $self = shift;
	return unless $self->[FH];
	# CORE::shutdown($self->[FH], 2);
	CORE::close($self->[FH]);
	$self->[FH] = undef
}

sub DESTROY {
	DEBUG && warn "\nDESTROY";
	my $self = shift || return;
	return if $self->[NO_CLOSE_ON_DESTROY];
	$self->CLOSE
}

# STAT, ISATTY, ISBINARY => used in perl 5.11 ?

sub STAT {
	my $self = shift;
	$self->[FH_STAT]->[3] = READ_MODE;
	$self->[FH_STAT]->[7] ||= $self->[CONTENT_LENGTH];
	$self->[FH_STAT]->[9] ||= $self->_mtime;
	return @{$self->[FH_STAT]};
}

sub _mtime {
	my $self = shift;
	return $self->[MTIME] if $self->[MTIME];
	return 0 unless $self->[LAST_MODIFIED];
	return 0 unless $TIME_GM_CODE ||= do {
		if (eval {require Time::y2038;1}) {
			\&Time::y2038::timegm
		}
		elsif (eval {require Time::Local;1}) {
			\&Time::Local::timegm
		}
	};
	if ($self->[LAST_MODIFIED] =~ /^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat), (\d{1,2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$/) {
		# eg: Wed, 11 Jun 2008 12:41:09 GMT
		return $self->[MTIME] = $TIME_GM_CODE->($6, $5, $4, $1, $Mon_str2num{$2}, $3-1900)
	}
	return 0
}

sub ISATTY {
	''
}

sub ISBINARY {
	my $self = shift;
	return $self->[CONTENT_TYPE] !~ m!text/!;
}

# some other method that might be used

sub SIZE {
	$_[0]->[CONTENT_LENGTH]
}

sub size {
	$_[0]->[CONTENT_LENGTH]
}

1
