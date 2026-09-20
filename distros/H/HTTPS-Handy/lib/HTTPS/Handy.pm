package HTTPS::Handy;
######################################################################
#
# HTTPS::Handy - A tiny HTTPS/1.0 server, TLS included, in pure Perl
#
# https://metacpan.org/dist/HTTPS-Handy
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
######################################################################
#
# Compatible : Perl 5.005_03 and later
# Platform   : Windows and UNIX/Linux
#
# This single file contains everything the server needs, including the
# TLS 1.2 implementation itself: big integer arithmetic, the P-256
# elliptic curve, SHA-256, HMAC, the TLS pseudo random function,
# ChaCha20-Poly1305, DER and PEM encoding, X.509 certificate
# generation, and the TLS record layer and handshake. No other module
# and no external program is used, so the whole of HTTPS can be read
# in one sitting.
#
# The packages in this file, in the order they appear:
#
#   HTTPS::Handy           the web server and the PSGI subset
#   HTTPS::Handy::Input    an in memory handle for psgi.input
#   HTTPS::Handy::TLS      the record layer and the handshake
#   HTTPS::Handy::EC       the P-256 curve: ECDH and ECDSA
#   HTTPS::Handy::ChaCha   ChaCha20-Poly1305, the record cipher
#   HTTPS::Handy::Crypt    SHA-256, HMAC, the PRF, randomness
#   HTTPS::Handy::X509     DER, PEM and self-signed certificates
#   HTTPS::Handy::RSA      signing, for a certificate somebody else issued
#   HTTPS::Handy::BigInt   multiple precision integers
#
# Read them in that order: each one is used by the one above it.
#
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
# warnings.pm compatibility: stub with import() for Perl < 5.6

BEGIN { pop @INC if $INC[-1] eq '.' } # CVE-2016-1238: Important unsafe module load path flaw

use IO::Socket;
use POSIX qw(strftime);
use Carp qw(croak);

use vars qw($VERSION);
$VERSION = '1.01';
$VERSION = $VERSION;
# VERSION policy: avoid `our` for 5.005_03 compatibility.
# Self-assignment prevents "used only once" warning under `use strict`.

# ----------------------------------------------------------------
# Status text map
# ----------------------------------------------------------------
# HTTP status codes and their standard text phrases.
# Keeping this as a simple hash makes it easy for beginners to see
# how status lines like "200 OK" are constructed.
# ----------------------------------------------------------------
my %STATUS_TEXT = (
    200 => 'OK',
    201 => 'Created',
    204 => 'No Content',
    301 => 'Moved Permanently',
    302 => 'Found',
    304 => 'Not Modified',
    400 => 'Bad Request',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    413 => 'Request Entity Too Large',
    500 => 'Internal Server Error',
);

# ----------------------------------------------------------------
# MIME type map
# ----------------------------------------------------------------
my %MIME = (
    'html'  => 'text/html; charset=utf-8',
    'htm'   => 'text/html; charset=utf-8',
    'txt'   => 'text/plain; charset=utf-8',
    'text'  => 'text/plain; charset=utf-8',
    'css'   => 'text/css',
    'js'    => 'application/javascript',
    'json'  => 'application/json',
    'xml'   => 'application/xml',
    'png'   => 'image/png',
    'jpg'   => 'image/jpeg',
    'jpeg'  => 'image/jpeg',
    'gif'   => 'image/gif',
    'ico'   => 'image/x-icon',
    'svg'   => 'image/svg+xml',
    'pdf'   => 'application/pdf',
    'zip'   => 'application/zip',
    'gz'    => 'application/gzip',
    'ltsv'  => 'text/plain; charset=utf-8',
    'csv'   => 'text/csv; charset=utf-8',
    'tsv'   => 'text/tab-separated-values; charset=utf-8',
);

# Default max POST body size: 10MB
my $DEFAULT_MAX_POST_SIZE = 10 * 1024 * 1024;

# How long a generated certificate is valid. Browsers refuse a
# certificate whose lifetime is much longer than this.
my $CERT_DAYS = 397;

# ----------------------------------------------------------------
# run - Start the HTTPS server (blocking)
# ----------------------------------------------------------------
# This is the main entry point. It resolves the TLS certificate,
# listens on a plain TCP socket, and for every connection runs the
# TLS handshake before reading the HTTP request.
#
# Certificate resolution priority:
#   1. Explicit ssl_cert_file + ssl_key_file (user provided)
#   2. An existing Let's Encrypt certificate for the first of
#      'domains', if one is already installed on this machine
#   3. A self-signed certificate generated here, in Perl, and cached
#      in cert_dir so that later runs start immediately
# ----------------------------------------------------------------
sub run {
    my ($class, %args) = @_;

    my $app           = $args{app}           or croak "HTTPS::Handy->run: 'app' is required";
    my $host          = defined $args{host}          ? $args{host}          : '0.0.0.0';
    my $port          = defined $args{port}          ? $args{port}          : 8443;
    my $log           = defined $args{log}           ? $args{log}           : 1;
    my $max_post_size = defined $args{max_post_size} ? $args{max_post_size} : $DEFAULT_MAX_POST_SIZE;

    ref($app) eq 'CODE' or croak "HTTPS::Handy->run: 'app' must be a code reference";
    $port =~ /^\d+$/ or croak "HTTPS::Handy->run: 'port' must be a number";
    $max_post_size =~ /^\d+$/ or croak "HTTPS::Handy->run: 'max_post_size' must be a number";

    # Certificate resolution
    my $cert_file = $args{ssl_cert_file};
    my $key_file  = $args{ssl_key_file};
    my $domains   = $args{domains};
    my $cert_dir  = $args{cert_dir} || '.https_handy_certs';

    unless ($cert_file && $key_file) {
        ($cert_file, $key_file) = _resolve_certificate(
            domains  => $domains,
            cert_dir => $cert_dir,
            log      => $log,
        );
    }

    my $ctx = _load_context($cert_file, $key_file);

    # A plain TCP socket. Everything above it -- the handshake, the
    # record layer, the encryption -- is done by HTTPS::Handy::TLS.
    my $server = IO::Socket::INET->new(
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => 10,
        ReuseAddr => 1,
    );
    unless ($server) {
        croak "HTTPS::Handy: Cannot bind to $host:$port - $!";
    }

    _log_message("HTTPS::Handy $HTTPS::Handy::VERSION started on https://$host:$port/") if $log;
    _log_message("Press Ctrl+C to stop.") if $log;

    while (1) {
        my $client = $server->accept;
        unless ($client) {
            _log_message("Accept failed: $!") if $log;
            next;
        }

        # Disable CRLF translation on Windows
        binmode $client;

        # The TLS handshake happens here, after the TCP connection has
        # been accepted. If the client does not speak TLS 1.2, or
        # offers no cipher suite this module implements, it fails and
        # the connection is dropped.
        my $tls = HTTPS::Handy::TLS->server_handshake($client, $ctx);
        unless ($tls) {
            _log_message("TLS handshake failed: $@") if $log;
            close $client;
            next;
        }

        eval {
            _handle_connection($tls, $app, $log, $max_post_size, $port);
        };
        if ($@) {
            _log_message("Error handling connection: $@") if $log;
        }

        $tls->close_tls;
        close $client;
    }
}

# ----------------------------------------------------------------
# Certificate helpers
# ----------------------------------------------------------------
# A TLS server needs two things: a certificate to show to the client
# and the private key that belongs to it. Both are ordinary PEM files,
# and this module can either read the ones you already have or make a
# new self-signed pair itself.
# ----------------------------------------------------------------

# _resolve_certificate - Decide which certificate files to use
sub _resolve_certificate {
    my (%opt) = @_;
    my $domains  = $opt{domains};
    my $cert_dir = $opt{cert_dir} || '.https_handy_certs';
    my $log      = $opt{log};

    if ($domains) {
        my $domain = (ref($domains) eq 'ARRAY') ? $domains->[0] : $domains;
        my $le_dir = "/etc/letsencrypt/live/$domain";
        if (-f "$le_dir/fullchain.pem" && -f "$le_dir/privkey.pem") {
            _log_message("Using the Let's Encrypt certificate for $domain") if $log;
            return ("$le_dir/fullchain.pem", "$le_dir/privkey.pem");
        }
        _log_message("No certificate installed for $domain. "
                   . "Generating a self-signed one instead.") if $log;
    }
    return _generate_self_signed(%opt);
}

# _generate_self_signed - Create a self-signed certificate in Perl
#
# Self-signed certificates make a browser show a warning, but they
# need no certificate authority and no network, so a lesson can start
# with HTTPS working in the first minute. The key is an elliptic curve
# key, which takes about half a second to make here; an RSA key of
# comparable strength would take minutes of pure Perl. The pair is
# cached in cert_dir and reused on later runs.
sub _generate_self_signed {
    my (%opt) = @_;
    my $cert_dir  = $opt{cert_dir} || '.https_handy_certs';
    my $log       = $opt{log};
    my $key_file  = "$cert_dir/selfsigned-key.pem";
    my $cert_file = "$cert_dir/selfsigned-cert.pem";

    if (-f $cert_file && -f $key_file) {
        _log_message("Using existing self-signed certificate.") if $log;
        return ($cert_file, $key_file);
    }

    mkdir $cert_dir, 0700 unless -d $cert_dir;

    my @hosts = ('localhost', '127.0.0.1');
    my $cn = 'localhost';
    if ($opt{domains}) {
        my @d = (ref($opt{domains}) eq 'ARRAY') ? @{ $opt{domains} } : ($opt{domains});
        if (@d) {
            $cn = $d[0];
            @hosts = (@d, 'localhost', '127.0.0.1');
        }
    }

    _log_message("Generating a P-256 key and a self-signed certificate for $cn ...") if $log;
    my $key = HTTPS::Handy::EC::generate_key();
    my $der = HTTPS::Handy::X509::make_self_signed(
        key   => $key,
        cn    => $cn,
        hosts => [ @hosts ],
        days  => $CERT_DAYS,
    );

    _write_file($key_file,  HTTPS::Handy::X509::private_key_to_pem_any($key));
    _write_file($cert_file, HTTPS::Handy::X509::pem_wrap('CERTIFICATE', $der));
    chmod 0600, $key_file;

    _log_message("Self-signed certificate created at $cert_file") if $log;
    return ($cert_file, $key_file);
}

# _load_context - Read the certificate chain and the private key
#
# The key may be an elliptic curve key (BEGIN EC PRIVATE KEY) or an
# RSA key (BEGIN RSA PRIVATE KEY), in either case unencrypted, and
# either may also arrive in the PKCS #8 wrapper that simply says
# BEGIN PRIVATE KEY.
sub _load_context {
    my ($cert_file, $key_file) = @_;

    my $cert_pem = _read_file($cert_file);
    defined $cert_pem
        or croak "HTTPS::Handy: Cannot read certificate file $cert_file: $!";
    my @chain = HTTPS::Handy::X509::pem_blocks($cert_pem, 'CERTIFICATE');
    @chain
        or croak "HTTPS::Handy: No CERTIFICATE block found in $cert_file";

    my $key_pem = _read_file($key_file);
    defined $key_pem
        or croak "HTTPS::Handy: Cannot read private key file $key_file: $!";

    my $key;
    my @ec  = HTTPS::Handy::X509::pem_blocks($key_pem, 'EC PRIVATE KEY');
    my @rsa = HTTPS::Handy::X509::pem_blocks($key_pem, 'RSA PRIVATE KEY');
    my @p8  = HTTPS::Handy::X509::pem_blocks($key_pem, 'PRIVATE KEY');
    if (@ec) {
        $key = HTTPS::Handy::X509::ec_private_key_from_der($ec[0]);
    }
    elsif (@rsa) {
        $key = HTTPS::Handy::X509::private_key_from_der($rsa[0]);
    }
    elsif (@p8) {
        $key = HTTPS::Handy::X509::ec_private_key_from_der($p8[0]);
        $key = HTTPS::Handy::X509::private_key_from_der($p8[0]) unless $key;
    }
    else {
        croak "HTTPS::Handy: No PRIVATE KEY block found in $key_file";
    }
    $key
        or croak "HTTPS::Handy: $key_file is not a P-256 or RSA private key this module can read";

    return { 'cert_chain' => [ @chain ], 'key' => $key };
}

# _read_file - Slurp a file, or return undef
sub _read_file {
    my ($path) = @_;
    local *FH;
    open(FH, "<$path") or return undef;
    binmode FH;
    local $/;
    my $data = <FH>;
    close FH;
    return defined $data ? $data : '';
}

# _write_file - Write a file, or die
sub _write_file {
    my ($path, $data) = @_;
    local *FH;
    open(FH, ">$path") or croak "HTTPS::Handy: Cannot write $path: $!";
    binmode FH;
    print FH $data;
    close FH;
    return 1;
}

# ----------------------------------------------------------------
# _handle_connection - Parse request and dispatch to app
# ----------------------------------------------------------------
# By the time this runs, the TLS handshake is over and $client is a
# HTTPS::Handy::TLS connection: read_line, read_bytes and write_data
# on it encrypt and decrypt without this code knowing anything about
# it. What is left is plain HTTP/1.0 -- a request line, some headers,
# an optional body -- and it is the same code as HTTP::Handy's, except
# for four keys in the PSGI environment:
#   psgi.url_scheme    => "https"  (instead of "http")
#   psgi.ssl           => 1        (new key, indicates TLS is active)
#   psgix.tls_cipher   => the cipher suite this connection negotiated
#   psgix.tls_resumed  => 1 when the handshake was resumed, 0 when full
#
# The last two are there to be looked at: reload the demo page and watch
# psgix.tls_resumed turn from 0 into 1 as the session cache does its
# work. The "psgix." prefix is the conventional PSGI spelling for a
# key a particular server adds.
# ----------------------------------------------------------------
sub _handle_connection {
    my ($client, $app, $log, $max_post_size, $server_port) = @_;

    # Read request line
    my $request_line = $client->read_line();
    return unless defined $request_line && $request_line ne '';

    $request_line =~ s/\r?\n$//;

    # "GET /path HTTP/1.1" splits into three. The version the client
    # asked for is read but not used: this server always answers
    # HTTP/1.0 and closes the connection afterwards.
    my ($method, $request_uri, $http_version) = split /\s+/, $request_line, 3;

    # Only allow GET and POST
    unless (defined $method && ($method eq 'GET' || $method eq 'POST')) {
        _send_error($client, 405, 'Method Not Allowed');
        return;
    }

    # Parse URI into path and query
    my ($path, $query_string) = ('/', '');
    if (defined $request_uri) {
        if ($request_uri =~ /^([^?]*)\?(.*)$/) {
            $path         = $1;
            $query_string = $2;
        }
        else {
            $path = $request_uri;
        }
    }
    $path = '/' unless defined $path && $path ne '';

    # Read headers
    my %headers;
    while (1) {
        my $line = $client->read_line();
        last unless defined $line;
        $line =~ s/\r?\n$//;
        last if $line eq '';

        if ($line =~ /^([^:]+):\s*(.*)$/) {
            my ($name, $value) = ($1, $2);
            # Normalize: lowercase, then convert to HTTP_* style
            $name = lc $name;
            $headers{$name} = $value;
        }
    }

    # Build $env
    my $server_name = $headers{'host'} || 'localhost';
    $server_name =~ s/:\d+$//;  # strip port from Host header

    # SERVER_PORT: prefer the port from Host header if present,
    # otherwise use the actual bound port passed from run().
    my $env_port = ($headers{'host'} && $headers{'host'} =~ /:(\d+)$/)
        ? int($1)
        : $server_port;

    # Content-Length comes from the client, so it is believed only when
    # it is a plain number. Anything else counts as no body at all.
    my $content_length = defined $headers{'content-length'}
                       ? $headers{'content-length'} : 0;
    $content_length = ($content_length =~ /^\s*(\d+)\s*$/) ? $1 : 0;

    if ($content_length > $max_post_size) {
        _send_error($client, 413, 'Request Entity Too Large');
        return;
    }

    # Read POST body
    my $post_body = '';
    if ($method eq 'POST' && $content_length > 0) {
        $post_body = $client->read_bytes($content_length);
    }

    # Build psgi.input as an in-memory filehandle
    # For 5.5.3 compatibility, use a simple object instead of
    # open my $fh, '<', \$scalar (which requires Perl 5.8+)
    my $input = HTTPS::Handy::Input->new($post_body);

    my %env = (
        'REQUEST_METHOD'  => $method,
        'PATH_INFO'       => $path,
        'QUERY_STRING'    => $query_string,
        'SERVER_NAME'     => $server_name,
        'SERVER_PORT'     => $env_port,
        'CONTENT_TYPE'    => $headers{'content-type'}   || '',
        'CONTENT_LENGTH'  => $content_length,
        'psgi.input'      => $input,
        'psgi.errors'     => \*STDERR,
        'psgi.url_scheme' => 'https',
        'psgi.ssl'        => 1,
        'psgix.tls_cipher'  => $client->cipher_name,
        'psgix.tls_resumed' => $client->was_resumed,
    );

    # Add HTTP_* headers
    for my $name (keys %headers) {
        my $key = 'HTTP_' . uc($name);
        $key =~ s/-/_/g;
        $env{$key} = $headers{$name};
    }

    # Dispatch to app
    my $response;
    eval {
        $response = $app->(\%env);
    };
    if ($@) {
        my $err = $@;
        # Like every other message from this module, this one obeys the
        # log option. An application that wants to record its own
        # errors when logging is off can write to psgi.errors.
        _log_message("App error: $err") if $log;
        _send_error($client, 500, 'Internal Server Error');
        return;
    }

    # Validate response
    unless (ref($response) eq 'ARRAY' && scalar(@$response) == 3) {
        _send_error($client, 500, 'Internal Server Error');
        return;
    }

    my ($status, $resp_headers, $body) = @$response;

    # The status has to be a number, or the status line it is pasted
    # into would not be a status line any more.
    $status = (defined $status && ($status =~ /^\s*(\d{3})\s*$/)) ? $1 : 500;

    # Send response
    my $status_text = $STATUS_TEXT{$status} || 'Unknown';
    my $response_str = "HTTP/1.0 $status $status_text\r\n";
    $response_str .= "Connection: close\r\n";

    # Process response headers (flat array: key, value, key, value, ...)
    #
    # A carriage return or newline inside a header would end the header
    # and start something else -- another header, or the body. An
    # application that puts user input into a header without noticing
    # would then let that user write the rest of the response, an old
    # trick called response splitting. Removing those characters here
    # means no application can make that mistake.
    my @header_list;
    if (ref($resp_headers) eq 'ARRAY') {
        my @h = @$resp_headers;
        while (@h) {
            my $k = shift @h;
            my $v = shift @h;
            next unless defined $k;
            $v = '' unless defined $v;
            $k =~ s/[\r\n]//g;
            $v =~ s/[\r\n]//g;
            next if $k eq '';
            push @header_list, "$k: $v";
        }
    }
    $response_str .= join("\r\n", @header_list) . "\r\n" if @header_list;
    $response_str .= "\r\n";

    # Build body
    my $body_str = '';
    if (ref($body) eq 'ARRAY') {
        $body_str = join('', @$body);
    }

    my $body_length = length($body_str);
    $response_str .= $body_str;

    $client->write_data($response_str);

    # Access log in LTSV format.
    # Sanitize field values: LTSV forbids tab and newline characters in values.
    if ($log) {
        my $ts      = strftime('%Y-%m-%dT%H:%M:%S', localtime);
        my $ua      = $headers{'user-agent'} || '';
        my $referer = $headers{'referer'}    || '';
        $ua      =~ s/[\t\n\r]/ /g;
        $referer =~ s/[\t\n\r]/ /g;
        print STDERR join("\t",
            "time:$ts",
            "method:$method",
            "path:$path",
            "status:$status",
            "size:$body_length",
            "ua:$ua",
            "referer:$referer",
        ) . "\n";
    }
}

# ----------------------------------------------------------------
# _send_error - Send a simple HTTP error response
# ----------------------------------------------------------------
sub _send_error {
    my ($client, $code, $message) = @_;
    my $text = $STATUS_TEXT{$code} || $message;
    my $body = "<html><head><title>$code $text</title></head>"
             . "<body><h1>$code $text</h1><p>$message</p>"
             . "<hr><small>HTTPS::Handy/$HTTPS::Handy::VERSION</small></body></html>";
    $client->write_data("HTTP/1.0 $code $text\r\n"
                       . "Content-Type: text/html\r\n"
                       . "Content-Length: " . length($body) . "\r\n"
                       . "Connection: close\r\n"
                       . "\r\n"
                       . $body);
}

# ----------------------------------------------------------------
# _log_message - Print timestamped log to STDERR
# ----------------------------------------------------------------
sub _log_message {
    my ($msg) = @_;
    my $ts = strftime('%Y-%m-%d %H:%M:%S', localtime);
    print STDERR "[$ts] $msg\n";
}

# ----------------------------------------------------------------
# serve_static - Serve files from a document root
# ----------------------------------------------------------------
sub serve_static {
    my ($class, $env, $docroot, %opts) = @_;

    $docroot ||= '.';
    # Remove trailing slash
    $docroot =~ s{[/\\]$}{};

    my $path = $env->{PATH_INFO} || '/';

    # Prevent path traversal via ".."
    if ($path =~ /\.\./) {
        return [403, ['Content-Type', 'text/plain'], ['Forbidden']];
    }

    # A null byte in a path once truncated file names inside the
    # operating system, which turned "secret.txt\0.html" into
    # "secret.txt". Perl is not fooled, but it warns, and a path with
    # control characters in it is not a real request in any case.
    if ($path =~ /[\x00-\x1F\x7F]/) {
        return [403, ['Content-Type', 'text/plain'], ['Forbidden']];
    }

    # Normalize separators on Windows
    $path =~ s{\\}{/}g;

    # Strip leading slashes to prevent absolute path injection
    $path =~ s{^/+}{/};

    my $file = $docroot . $path;

    # Directory: try index.html
    if (-d $file) {
        $file =~ s{/?$}{/index.html};
    }

    unless (-f $file) {
        return [404, ['Content-Type', 'text/plain'], ['Not Found']];
    }

    # Determine MIME type from extension
    my $ext = '';
    if ($file =~ /\.([^.]+)$/) {
        $ext = lc $1;
    }
    my $mime = $MIME{$ext} || 'application/octet-stream';

    # Read file
    local *FH;
    unless (open FH, "<$file") {
        return [403, ['Content-Type', 'text/plain'], ['Forbidden']];
    }
    binmode FH;
    local $/;
    my $content = <FH>;
    close FH;

    # Cache-Control header
    my @cache_headers;
    if (exists $opts{cache_max_age}) {
        my $age = int($opts{cache_max_age});
        if ($age > 0) {
            push @cache_headers, 'Cache-Control', "public, max-age=$age";
        }
        else {
            push @cache_headers, 'Cache-Control', 'no-cache';
        }
    }
    else {
        # Default: no-cache (safe for development use)
        push @cache_headers, 'Cache-Control', 'no-cache';
    }

    return [200,
        ['Content-Type',   $mime,
         'Content-Length', length($content),
         @cache_headers],
        [$content]];
}

# ----------------------------------------------------------------
# url_decode - Decode percent-encoded string
# ----------------------------------------------------------------
sub url_decode {
    my ($class, $str) = @_;
    return '' unless defined $str;
    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $str;
}

# ----------------------------------------------------------------
# parse_query - Parse query string into hash
# ----------------------------------------------------------------
sub parse_query {
    my ($class, $query) = @_;
    return () unless defined $query && $query ne '';
    my %params;
    for my $pair (split /&/, $query) {
        my ($key, $val) = split /=/, $pair, 2;
        next unless defined $key;
        $key = $class->url_decode($key);
        $val = defined $val ? $class->url_decode($val) : '';
        if (exists $params{$key}) {
            if (ref $params{$key} eq 'ARRAY') {
                push @{$params{$key}}, $val;
            }
            else {
                $params{$key} = [$params{$key}, $val];
            }
        }
        else {
            $params{$key} = $val;
        }
    }
    return %params;
}

# ----------------------------------------------------------------
# mime_type - Return MIME type for a file extension
# ----------------------------------------------------------------
sub mime_type {
    my ($class, $ext) = @_;
    $ext = lc $ext;
    $ext =~ s/^\.//;
    return $MIME{$ext} || 'application/octet-stream';
}

# ----------------------------------------------------------------
# is_htmx - Return true if the request was made by htmx
# ----------------------------------------------------------------
sub is_htmx {
    my ($class, $env) = @_;
    return (defined $env->{HTTP_HX_REQUEST} && $env->{HTTP_HX_REQUEST} eq 'true') ? 1 : 0;
}

# ----------------------------------------------------------------
# response_redirect - Build a redirect response
# ----------------------------------------------------------------
sub response_redirect {
    my ($class, $location, $code) = @_;
    $code ||= 302;
    return [$code,
        ['Location',     $location,
         'Content-Type', 'text/plain'],
        ["Redirect to $location"]];
}

# ----------------------------------------------------------------
# response_json - Build a JSON response (no JSON encoding, caller provides)
# ----------------------------------------------------------------
sub response_json {
    my ($class, $json_str, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'application/json',
         'Content-Length', length($json_str)],
        [$json_str]];
}

# ----------------------------------------------------------------
# response_html - Build an HTML response
# ----------------------------------------------------------------
sub response_html {
    my ($class, $html, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'text/html; charset=utf-8',
         'Content-Length', length($html)],
        [$html]];
}

# ----------------------------------------------------------------
# response_text - Build a plain text response
# ----------------------------------------------------------------
sub response_text {
    my ($class, $text, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'text/plain; charset=utf-8',
         'Content-Length', length($text)],
        [$text]];
}

# ----------------------------------------------------------------
# HTTPS::Handy::Input - Minimal in-memory filehandle for psgi.input
# Compatible with Perl 5.5.3 (no open with scalar ref)
# ----------------------------------------------------------------
# This is the same implementation as HTTP::Handy::Input.
# It exists because Perl 5.5.3 does not support:
#   open my $fh, '<', \$scalar;
# Instead, we implement read(), seek(), tell(), getline(), and
# getlines() as methods on a blessed hash.
# ----------------------------------------------------------------
package HTTPS::Handy::Input;

sub new {
    my ($class, $data) = @_;
    $data = '' unless defined $data;
    return bless { data => $data, pos => 0 }, $class;
}

sub read {
    # Note: $_[1] is the caller's buffer variable -- modified in place.
    # We do NOT include it in the my() list because:
    #   (a) we must write back via $_[1], not a copy, and
    #   (b) "my ($self, undef, $length)" requires Perl 5.10+.
    my $self   = $_[0];
    my $length = $_[2];
    my $offset = $_[3] || 0;
    my $remaining = length($self->{data}) - $self->{pos};
    $length = $remaining if $length > $remaining;
    return 0 if $length <= 0;
    my $chunk = substr($self->{data}, $self->{pos}, $length);
    $self->{pos} += $length;
    # Write into $_[1] at $offset (like POSIX read). The built-in read
    # populates the buffer regardless of its prior contents and does not
    # warn when the caller passes an undefined buffer; match that contract
    # by treating an undefined buffer as empty before the in-place substr.
    $_[1] = '' unless defined $_[1];
    substr($_[1], $offset) = $chunk;
    return $length;
}

sub seek {
    my ($self, $pos, $whence) = @_;
    $whence ||= 0;
    if ($whence == 0) {
        $self->{pos} = $pos;
    }
    elsif ($whence == 1) {
        $self->{pos} += $pos;
    }
    elsif ($whence == 2) {
        $self->{pos} = length($self->{data}) + $pos;
    }
    $self->{pos} = 0 if $self->{pos} < 0;
    return 1;
}

sub tell {
    my ($self) = @_;
    return $self->{pos};
}

sub getline {
    my ($self) = @_;
    return undef if $self->{pos} >= length($self->{data});
    my $nl = index($self->{data}, "\n", $self->{pos});
    my $line;
    if ($nl < 0) {
        $line = substr($self->{data}, $self->{pos});
        $self->{pos} = length($self->{data});
    }
    else {
        $line = substr($self->{data}, $self->{pos}, $nl - $self->{pos} + 1);
        $self->{pos} = $nl + 1;
    }
    return $line;
}

sub getlines {
    my ($self) = @_;
    my @lines;
    while (defined(my $line = $self->getline)) {
        push @lines, $line;
    }
    return @lines;
}

######################################################################
# HTTPS::Handy::TLS - A TLS 1.2 record layer and handshake
######################################################################
# This is the core of the module. Everything above it is an ordinary
# web server and everything below it is arithmetic; here is where the
# two meet.
#
# A full handshake, in the order it happens:
#
#   client -> ClientHello         which versions and ciphers it knows
#   server -> ServerHello         the version and cipher it picked
#   server -> Certificate         the server public key, signed
#   server -> ServerKeyExchange   a one time curve point, signed
#   server -> ServerHelloDone
#   client -> ClientKeyExchange   its own one time curve point
#   client -> ChangeCipherSpec    everything after this is encrypted
#   client -> Finished            a hash of the whole handshake
#   server -> ChangeCipherSpec
#   server -> Finished
#
# Both sides multiply their own secret number by the other side's
# point. The two results are equal, nobody watching can work out what
# it is, and neither side ever sends it. That shared value becomes the
# pre-master secret, the PRF turns it into keys, and every record from
# then on is sealed with ChaCha20-Poly1305.
#
# Because each side's secret number is thrown away when the connection
# ends, recorded traffic cannot be decrypted later even if the server
# key is stolen. That property is called forward secrecy, and it is the
# reason this module does the extra work of ECDHE instead of simply
# encrypting a secret to the server certificate.
######################################################################

package HTTPS::Handy::TLS;

# Record content types
my $CT_CCS       = 20;
my $CT_ALERT     = 21;
my $CT_HANDSHAKE = 22;
my $CT_APPDATA   = 23;

# Handshake message types
my $HS_CLIENT_HELLO      = 1;
my $HS_SERVER_HELLO      = 2;
my $HS_CERTIFICATE       = 11;
my $HS_SERVER_KEY_EXCH   = 12;
my $HS_SERVER_HELLO_DONE = 14;
my $HS_CLIENT_KEY_EXCH   = 16;
my $HS_FINISHED          = 20;

# TLS 1.2 on the wire
my $TLS12 = "\x03\x03";

# The two cipher suites understood here. Both use ECDHE for forward
# secrecy and ChaCha20-Poly1305 to protect the data; they differ only
# in the kind of key the server certificate holds.
#
#   0xCCA9  TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
#   0xCCA8  TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
# The number in front of each name is what travels on the wire; a
# packet capture shows exactly these two bytes.
my %SUITE = (
    0xCCA9 => { 'name' => 'TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256' },
    0xCCA8 => { 'name' => 'TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256' },
);

# Which suite goes with which kind of certificate key
my %SUITE_FOR_KEY = ( 'ec' => 0xCCA9, 'rsa' => 0xCCA8 );

# Key material: a 32 byte key and a 12 byte fixed nonce for each side
my $KEY_LEN = 32;
my $IV_LEN  = 12;

my $MAX_FRAGMENT = 16384;

# secp256r1, the one curve implemented here (RFC 8422 calls it 23)
my $NAMED_CURVE_P256 = 23;

# Sessions that may be resumed, as
#   session_id => { master, cipher, time, serial }
# where serial counts upwards on every store and every hit, so that the
# entry with the lowest serial is always the one used longest ago.
my %SESSION;
my $SESSION_SERIAL   = 0;
my $SESSION_LIMIT    = 64;
my $SESSION_LIFETIME = 3600;

# ----------------------------------------------------------------
# Small helpers
# ----------------------------------------------------------------

# _u24 - Three byte length field, as handshake messages use
sub _u24 {
    my ($n) = @_;
    return pack('C3', int($n / 65536) % 256, int($n / 256) % 256, $n % 256);
}

sub _get_u24 {
    my ($s, $off) = @_;
    my @b = unpack('C3', substr($s, $off, 3));
    return $b[0] * 65536 + $b[1] * 256 + $b[2];
}

# ----------------------------------------------------------------
# Connection object
# ----------------------------------------------------------------

sub _new {
    my ($class, $sock, $is_server) = @_;
    return bless {
        'sock'       => $sock,
        'is_server'  => $is_server,
        'rawbuf'     => '',       # bytes read from the socket, not yet parsed
        'appbuf'     => '',       # decrypted application data
        'hsbuf'      => '',       # handshake messages seen so far (for the hash)
        'hs_pending' => '',       # a partly received handshake message
        'read_seq'   => 0,
        'write_seq'  => 0,
        'read_on'    => 0,        # is the read side encrypted yet
        'write_on'   => 0,
        'closed'     => 0,
        'resumed'    => 0,
        'error'      => '',
    }, $class;
}

# ----------------------------------------------------------------
# Raw socket input and output
# ----------------------------------------------------------------

sub _fill {
    my ($self, $want) = @_;
    while (length($self->{'rawbuf'}) < $want) {
        my $buf = '';
        my $got = sysread($self->{'sock'}, $buf, 16384);
        if (!defined $got || ($got == 0)) {
            $self->{'closed'} = 1;
            return 0;
        }
        $self->{'rawbuf'} .= $buf;
    }
    return 1;
}

sub _send_raw {
    my ($self, $data) = @_;
    my $off = 0;
    while ($off < length($data)) {
        my $n = syswrite($self->{'sock'}, $data, length($data) - $off, $off);
        if (!defined $n || ($n <= 0)) {
            $self->{'closed'} = 1;
            return 0;
        }
        $off += $n;
    }
    return 1;
}

# ----------------------------------------------------------------
# Record layer
# ----------------------------------------------------------------
# A record is  type(1) version(2) length(2) payload.  Once the cipher
# is switched on, the payload is the sealed data: ciphertext followed
# by the 16 byte Poly1305 tag.
#
# The nonce is the fixed 12 byte value from the key block, exclusive
# ored with the record sequence number. Every record therefore gets a
# different nonce, which ChaCha20 requires absolutely: two records
# under one nonce would expose both.
# ----------------------------------------------------------------

# _seq_bytes - The eight byte record sequence number
#
# The halves are separated by division rather than by a remainder,
# because 2 ** 32 does not fit in a 32 bit integer and Perl would read
# such a modulus as zero there.
sub _seq_bytes {
    my ($n) = @_;
    my $hi = int($n / (65536 * 65536));
    return pack('NN', $hi, $n - $hi * 65536 * 65536);
}

sub _nonce {
    my ($iv, $seq) = @_;
    return $iv ^ ("\x00\x00\x00\x00" . _seq_bytes($seq));
}

sub _encrypt {
    my ($self, $type, $plain) = @_;
    my $key = $self->{'is_server'} ? $self->{'server_key'} : $self->{'client_key'};
    my $iv  = $self->{'is_server'} ? $self->{'server_iv'}  : $self->{'client_iv'};
    my $seq = $self->{'write_seq'};
    $self->{'write_seq'}++;

    # The additional data is authenticated but not encrypted, so an
    # attacker cannot move a record to another position or change its
    # declared type without the tag failing.
    my $aad = _seq_bytes($seq) . pack('C', $type) . $TLS12
            . pack('n', length($plain));
    return HTTPS::Handy::ChaCha::aead_encrypt($key, _nonce($iv, $seq),
                                              $aad, $plain);
}

sub _decrypt {
    my ($self, $type, $sealed) = @_;
    my $key = $self->{'is_server'} ? $self->{'client_key'} : $self->{'server_key'};
    my $iv  = $self->{'is_server'} ? $self->{'client_iv'}  : $self->{'server_iv'};
    return undef if length($sealed) < 16;
    my $seq = $self->{'read_seq'};
    $self->{'read_seq'}++;

    my $aad = _seq_bytes($seq) . pack('C', $type) . $TLS12
            . pack('n', length($sealed) - 16);
    return HTTPS::Handy::ChaCha::aead_decrypt($key, _nonce($iv, $seq),
                                              $aad, $sealed);
}

# _send_record - Write one record, encrypting it when the cipher is on
sub _send_record {
    my ($self, $type, $data) = @_;
    while (1) {
        my $chunk = substr($data, 0, $MAX_FRAGMENT);
        $data = (length($data) > $MAX_FRAGMENT) ? substr($data, $MAX_FRAGMENT) : '';
        my $payload = $self->{'write_on'} ? $self->_encrypt($type, $chunk) : $chunk;
        return 0 unless $self->_send_raw(pack('C', $type) . $TLS12
                                       . pack('n', length($payload)) . $payload);
        last if $data eq '';
    }
    return 1;
}

# _read_record - Read one record; returns (type, plaintext)
sub _read_record {
    my ($self) = @_;
    return () unless $self->_fill(5);
    my $type  = unpack('C', substr($self->{'rawbuf'}, 0, 1));
    my $major = unpack('C', substr($self->{'rawbuf'}, 1, 1));
    my $len   = unpack('n', substr($self->{'rawbuf'}, 3, 2));

    # A plain HTTP request sent to this port arrives here as a record
    # whose type is the letter "G". Refusing anything that is not a
    # valid record type keeps the server from waiting for the rest of a
    # record that will never come.
    if ((($type < $CT_CCS) || ($type > $CT_APPDATA)) || ($major != 3)) {
        $self->{'error'} = 'not a TLS record (is the client speaking plain HTTP?)';
        return ();
    }
    if ($len > $MAX_FRAGMENT + 2048) {
        $self->{'error'} = 'record too long';
        return ();
    }
    return () unless $self->_fill(5 + $len);
    my $payload = substr($self->{'rawbuf'}, 5, $len);
    $self->{'rawbuf'} = substr($self->{'rawbuf'}, 5 + $len);

    if ($self->{'read_on'} && ($type != $CT_CCS)) {
        $payload = $self->_decrypt($type, $payload);
        unless (defined $payload) {
            $self->{'error'} = 'record failed its authentication tag';
            return ();
        }
    }
    return ($type, $payload);
}

sub _send_alert {
    my ($self, $level, $desc) = @_;
    $self->_send_record($CT_ALERT, pack('CC', $level, $desc));
    return;
}

# ----------------------------------------------------------------
# Handshake message plumbing
# ----------------------------------------------------------------

sub _send_handshake {
    my ($self, $type, $body) = @_;
    my $msg = pack('C', $type) . _u24(length($body)) . $body;
    $self->{'hsbuf'} .= $msg;
    return $self->_send_record($CT_HANDSHAKE, $msg);
}

# _read_handshake - Read the next handshake message; returns (type, body)
sub _read_handshake {
    my ($self) = @_;
    while (1) {
        if (length($self->{'hs_pending'}) >= 4) {
            my $body_len = _get_u24($self->{'hs_pending'}, 1);
            if (length($self->{'hs_pending'}) >= 4 + $body_len) {
                my $msg = substr($self->{'hs_pending'}, 0, 4 + $body_len);
                $self->{'hs_pending'} = substr($self->{'hs_pending'}, 4 + $body_len);
                $self->{'hsbuf'} .= $msg;
                return (unpack('C', substr($msg, 0, 1)), substr($msg, 4));
            }
        }
        my ($type, $data) = $self->_read_record();
        return () unless defined $type;
        if ($type == $CT_ALERT) {
            $self->{'error'} = 'alert from peer: ' . join('/', unpack('C*', $data));
            return ();
        }
        unless ($type == $CT_HANDSHAKE) {
            $self->{'error'} = 'unexpected record type ' . $type;
            return ();
        }
        $self->{'hs_pending'} .= $data;
    }
}

# _expect_ccs - Read the ChangeCipherSpec record
sub _expect_ccs {
    my ($self) = @_;
    my ($type, $data) = $self->_read_record();
    return 0 unless defined $type;
    unless ($type == $CT_CCS) {
        $self->{'error'} = 'expected ChangeCipherSpec';
        return 0;
    }
    $self->{'read_on'} = 1;
    $self->{'read_seq'} = 0;
    return 1;
}

sub _send_ccs {
    my ($self) = @_;
    $self->_send_record($CT_CCS, "\x01");
    $self->{'write_on'} = 1;
    $self->{'write_seq'} = 0;
    return 1;
}

# ----------------------------------------------------------------
# Key derivation (RFC 5246 section 6.3)
# ----------------------------------------------------------------

sub _derive_keys {
    my ($self, $premaster) = @_;

    $self->{'master'} = HTTPS::Handy::Crypt::prf(
        $premaster, 'master secret',
        $self->{'client_random'} . $self->{'server_random'}, 48)
        if defined $premaster;

    my $block = HTTPS::Handy::Crypt::prf(
        $self->{'master'}, 'key expansion',
        $self->{'server_random'} . $self->{'client_random'},
        2 * $KEY_LEN + 2 * $IV_LEN);

    $self->{'client_key'} = substr($block, 0, $KEY_LEN);
    $self->{'server_key'} = substr($block, $KEY_LEN, $KEY_LEN);
    $self->{'client_iv'}  = substr($block, 2 * $KEY_LEN, $IV_LEN);
    $self->{'server_iv'}  = substr($block, 2 * $KEY_LEN + $IV_LEN, $IV_LEN);
    return 1;
}

# _finished_value - The 12 byte proof that both sides saw the same
# handshake and hold the same master secret
sub _finished_value {
    my ($self, $label) = @_;
    return HTTPS::Handy::Crypt::prf($self->{'master'}, $label,
               HTTPS::Handy::Crypt::sha256($self->{'hsbuf'}), 12);
}

# ----------------------------------------------------------------
# Reading a ClientHello
# ----------------------------------------------------------------

# _parse_hello - Pull apart a ClientHello; returns a hash reference,
# or undef when the message is too short to be one
#
# Every length in here comes from the other end of a socket, so each
# one is checked against what actually arrived before it is used. A
# message that stops in the middle is refused rather than parsed into
# nonsense; that is the whole reason for the repeated length tests.
sub _parse_hello {
    my ($body) = @_;
    my $len = length($body);
    return undef if $len < 38;          # version, random, and two lengths

    my $h = {
        'version' => substr($body, 0, 2),
        'random'  => substr($body, 2, 32),
        'suites'  => [],
        'ext'     => {},
    };
    my $pos = 34;
    my $sid_len = unpack('C', substr($body, $pos, 1));
    $pos++;
    return undef if $pos + $sid_len + 2 > $len;
    $h->{'session_id'} = substr($body, $pos, $sid_len);
    $pos += $sid_len;

    my $cs_len = unpack('n', substr($body, $pos, 2));
    $pos += 2;
    return undef if ($cs_len % 2) || ($pos + $cs_len + 1 > $len);
    $h->{'suites'} = [ unpack('n*', substr($body, $pos, $cs_len)) ];
    $pos += $cs_len;

    my $comp_len = unpack('C', substr($body, $pos, 1));
    $pos += 1 + $comp_len;

    # Extensions are optional; each is  type(2) length(2) data.
    # A block that does not add up is a malformed message, not a
    # message without extensions, so it is refused outright.
    if ($pos + 2 <= $len) {
        my $ext_len = unpack('n', substr($body, $pos, 2));
        $pos += 2;
        return undef if $pos + $ext_len > $len;
        my $ext = substr($body, $pos, $ext_len);
        my $p = 0;
        while ($p < length($ext)) {
            return undef if $p + 4 > length($ext);
            my $t = unpack('n', substr($ext, $p, 2));
            my $l = unpack('n', substr($ext, $p + 2, 2));
            return undef if $p + 4 + $l > length($ext);
            $h->{'ext'}{$t} = substr($ext, $p + 4, $l);
            $p += 4 + $l;
        }
    }
    return $h;
}

# _client_supports_p256 - Does the client accept the curve we implement
sub _client_supports_p256 {
    my ($hello) = @_;
    my $groups = $hello->{'ext'}{10};
    return 1 unless defined $groups;      # no opinion means anything goes
    return 0 if length($groups) < 2;
    my $len = unpack('n', substr($groups, 0, 2));
    $len = length($groups) - 2 if $len > length($groups) - 2;
    for my $g (unpack('n*', substr($groups, 2, $len - ($len % 2)))) {
        return 1 if $g == $NAMED_CURVE_P256;
    }
    return 0;
}

# ----------------------------------------------------------------
# Session cache
# ----------------------------------------------------------------
# A full handshake costs three elliptic curve multiplications, which is
# about a second and a half of pure Perl. Remembering the master secret
# under a session id lets the next connection skip all of it. Browsers
# open several connections per page, so without this a demonstration
# would crawl.
# ----------------------------------------------------------------

sub _session_store {
    my ($id, $master, $cipher) = @_;
    my $now = time();

    # Throw away anything too old to be offered again
    for my $k (keys %SESSION) {
        delete $SESSION{$k} if ($now - $SESSION{$k}{'time'}) > $SESSION_LIFETIME;
    }

    # Then, if the table is still full, throw away whatever was used
    # longest ago until there is room. Counting with a serial number
    # rather than a clock keeps the order exact even when several
    # sessions are made within the same second.
    while (scalar(keys %SESSION) >= $SESSION_LIMIT) {
        my $oldest;
        for my $k (keys %SESSION) {
            $oldest = $k
                if !defined $oldest
                || ($SESSION{$k}{'serial'} < $SESSION{$oldest}{'serial'});
        }
        delete $SESSION{$oldest};
    }

    $SESSION_SERIAL++;
    $SESSION{$id} = {
        'master' => $master,
        'cipher' => $cipher,
        'time'   => $now,
        'serial' => $SESSION_SERIAL,
    };
    return;
}

sub _session_find {
    my ($id) = @_;
    return undef unless defined $id && (length($id) == 32);
    my $s = $SESSION{$id};
    return undef unless $s;
    if ((time() - $s->{'time'}) > $SESSION_LIFETIME) {
        delete $SESSION{$id};
        return undef;
    }
    # Using a session keeps it alive and moves it to the front
    $SESSION_SERIAL++;
    $s->{'time'}   = time();
    $s->{'serial'} = $SESSION_SERIAL;
    return $s;
}

# ----------------------------------------------------------------
# Server side handshake
# ----------------------------------------------------------------
# $ctx is { cert_chain => [ DER, ... ], key => private key }
# Returns the connection object, or undef with the reason in $@.
# ----------------------------------------------------------------

sub server_handshake {
    my ($class, $sock, $ctx) = @_;
    my $self = _new('HTTPS::Handy::TLS', $sock, 1);

    # --- ClientHello ---
    my ($type, $body) = $self->_read_handshake();
    unless (defined $type && ($type == $HS_CLIENT_HELLO)) {
        $@ = $self->{'error'} || 'no ClientHello received';
        return undef;
    }
    my $hello = _parse_hello($body);
    unless ($hello) {
        $self->_send_alert(2, 50);          # decode_error
        $@ = 'the ClientHello was too short to read';
        return undef;
    }

    if ($hello->{'version'} lt $TLS12) {
        $self->_send_alert(2, 70);          # protocol_version
        $@ = 'client offered an older protocol than TLS 1.2';
        return undef;
    }
    $self->{'client_random'} = $hello->{'random'};

    # The cipher suite follows from the kind of key the server holds
    my $want = $SUITE_FOR_KEY{ $ctx->{'key'}{'type'} };
    my $chosen;
    for my $have (@{ $hello->{'suites'} }) {
        if ($have == $want) {
            $chosen = $want;
            last;
        }
    }
    unless (defined $chosen && _client_supports_p256($hello)) {
        $self->_send_alert(2, 40);          # handshake_failure
        $@ = 'no cipher suite in common (this server speaks '
           . $SUITE{$want}{'name'} . ' over the P-256 curve)';
        return undef;
    }
    $self->{'cipher'} = $chosen;
    $self->{'suite'}  = $SUITE{$chosen};
    $self->{'server_random'} = pack('N', time())
                             . HTTPS::Handy::Crypt::random_bytes(28);

    # --- An abbreviated handshake, when the client knows this session ---
    my $old = _session_find($hello->{'session_id'});
    if ($old && ($old->{'cipher'} == $chosen)) {
        $self->{'master'}  = $old->{'master'};
        $self->{'resumed'} = 1;
        return undef unless $self->_send_handshake($HS_SERVER_HELLO,
            $self->_server_hello_body($hello->{'session_id'}, $chosen));
        $self->_derive_keys(undef);
        $self->_send_ccs();
        return undef unless $self->_send_handshake($HS_FINISHED,
                                $self->_finished_value('server finished'));
        return undef unless $self->_expect_ccs();
        my $expect = $self->_finished_value('client finished');
        ($type, $body) = $self->_read_handshake();
        unless (defined $type && ($type == $HS_FINISHED) && ($body eq $expect)) {
            $@ = $self->{'error'} || 'client Finished did not verify';
            return undef;
        }
        return $self;
    }

    # --- ServerHello ---
    my $session_id = HTTPS::Handy::Crypt::random_bytes(32);
    $self->{'session_id'} = $session_id;
    return undef unless $self->_send_handshake($HS_SERVER_HELLO,
        $self->_server_hello_body($session_id, $chosen));

    # --- Certificate ---
    my $certs = '';
    for my $der (@{ $ctx->{'cert_chain'} }) {
        $certs .= _u24(length($der)) . $der;
    }
    return undef unless $self->_send_handshake($HS_CERTIFICATE,
                            _u24(length($certs)) . $certs);

    # --- ServerKeyExchange ---
    # A fresh curve key for this connection only, and a signature over
    # it with the certificate key so the client knows who sent it.
    my $eph = HTTPS::Handy::EC::generate_key();
    my $point = HTTPS::Handy::EC::point_to_bin($eph->{'x'}, $eph->{'y'});
    my $params = "\x03" . pack('n', $NAMED_CURVE_P256)
               . pack('C', length($point)) . $point;
    my $sig_alg = ($ctx->{'key'}{'type'} eq 'ec') ? "\x04\x03" : "\x04\x01";
    my $sig = HTTPS::Handy::X509::sign_data($ctx->{'key'},
                  $self->{'client_random'} . $self->{'server_random'} . $params);
    return undef unless $self->_send_handshake($HS_SERVER_KEY_EXCH,
        $params . $sig_alg . pack('n', length($sig)) . $sig);

    # --- ServerHelloDone ---
    return undef unless $self->_send_handshake($HS_SERVER_HELLO_DONE, '');

    # --- ClientKeyExchange ---
    ($type, $body) = $self->_read_handshake();
    unless (defined $type && ($type == $HS_CLIENT_KEY_EXCH)) {
        $@ = $self->{'error'} || 'no ClientKeyExchange received';
        return undef;
    }
    my $plen = unpack('C', substr($body, 0, 1));
    my ($px, $py) = HTTPS::Handy::EC::point_from_bin(substr($body, 1, $plen));
    unless (defined $px) {
        $self->_send_alert(2, 47);          # illegal_parameter
        $@ = 'the client sent a curve point this server cannot read';
        return undef;
    }
    my $premaster = HTTPS::Handy::EC::ecdh_shared($eph->{'d'}, $px, $py);
    unless (defined $premaster) {
        $self->_send_alert(2, 47);
        $@ = 'the client sent a point that is not on the P-256 curve';
        return undef;
    }
    $self->_derive_keys($premaster);

    # --- ChangeCipherSpec and Finished from the client ---
    return undef unless $self->_expect_ccs();
    my $expect = $self->_finished_value('client finished');
    ($type, $body) = $self->_read_handshake();
    unless (defined $type && ($type == $HS_FINISHED)) {
        $@ = $self->{'error'} || 'no Finished received';
        return undef;
    }
    unless ($body eq $expect) {
        $self->_send_alert(2, 51);          # decrypt_error
        $@ = 'client Finished did not verify';
        return undef;
    }

    # --- ChangeCipherSpec and Finished from the server ---
    $self->_send_ccs();
    return undef unless $self->_send_handshake($HS_FINISHED,
                            $self->_finished_value('server finished'));

    _session_store($session_id, $self->{'master'}, $chosen);
    return $self;
}

# _server_hello_body - version, random, session id, cipher, extensions
sub _server_hello_body {
    my ($self, $session_id, $chosen) = @_;
    my $ext = pack('n', 0xFF01) . pack('n', 1) . "\x00";   # renegotiation_info
    $ext   .= pack('n', 11) . pack('n', 2) . "\x01\x00";   # ec_point_formats
    return $TLS12 . $self->{'server_random'}
         . pack('C', length($session_id)) . $session_id
         . pack('n', $chosen) . "\x00"
         . pack('n', length($ext)) . $ext;
}

# ----------------------------------------------------------------
# Client side handshake
# ----------------------------------------------------------------
# The module brings its own client so that the test suite can talk to
# the server without any other TLS implementation present, and so that
# both halves of the conversation can be read side by side. It does not
# check the server certificate; see the SECURITY section.
# ----------------------------------------------------------------

sub client_handshake {
    my ($class, $sock, %opt) = @_;
    my $self = _new('HTTPS::Handy::TLS', $sock, 0);

    $self->{'client_random'} = pack('N', time())
                             . HTTPS::Handy::Crypt::random_bytes(28);
    my $suites = pack('n', 0xCCA9) . pack('n', 0xCCA8);
    my $hello = $TLS12 . $self->{'client_random'} . "\x00"
              . pack('n', length($suites)) . $suites
              . "\x01\x00";                       # one compression method: none

    my $ext = '';
    if (defined $opt{'host'} && ($opt{'host'} !~ /^[\d.]+$/)) {
        my $sni = "\x00" . pack('n', length($opt{'host'})) . $opt{'host'};
        $sni = pack('n', length($sni)) . $sni;
        $ext .= pack('n', 0) . pack('n', length($sni)) . $sni;
    }
    my $groups = pack('n', 2) . pack('n', $NAMED_CURVE_P256);
    $ext .= pack('n', 10) . pack('n', length($groups)) . $groups;
    $ext .= pack('n', 11) . pack('n', 2) . "\x01\x00";     # uncompressed points
    my $sa = pack('n', 4) . "\x04\x03\x04\x01";            # ECDSA and RSA, SHA-256
    $ext .= pack('n', 13) . pack('n', length($sa)) . $sa;
    $hello .= pack('n', length($ext)) . $ext;
    return undef unless $self->_send_handshake($HS_CLIENT_HELLO, $hello);

    # --- ServerHello ---
    my ($type, $body) = $self->_read_handshake();
    unless (defined $type && ($type == $HS_SERVER_HELLO)) {
        $@ = $self->{'error'} || 'no ServerHello received';
        return undef;
    }
    $self->{'server_random'} = substr($body, 2, 32);
    my $pos = 34;
    my $sid_len = unpack('C', substr($body, $pos, 1));
    $pos += 1 + $sid_len;
    my $chosen = unpack('n', substr($body, $pos, 2));
    unless (exists $SUITE{$chosen}) {
        $@ = 'server chose a cipher suite this client does not know';
        return undef;
    }
    $self->{'cipher'} = $chosen;
    $self->{'suite'}  = $SUITE{$chosen};

    # --- Certificate, ServerKeyExchange, ServerHelloDone ---
    my $eph = HTTPS::Handy::EC::generate_key();
    my $premaster;
    while (1) {
        ($type, $body) = $self->_read_handshake();
        unless (defined $type) {
            $@ = $self->{'error'} || 'handshake ended early';
            return undef;
        }
        if ($type == $HS_CERTIFICATE) {
            my $first_len = _get_u24($body, 3);
            $self->{'peer_cert'} = substr($body, 6, $first_len);
            next;
        }
        if ($type == $HS_SERVER_KEY_EXCH) {
            unless (substr($body, 0, 1) eq "\x03") {
                $@ = 'the server did not offer a named curve';
                return undef;
            }
            my $plen = unpack('C', substr($body, 3, 1));
            my ($px, $py) = HTTPS::Handy::EC::point_from_bin(substr($body, 4, $plen));
            unless (defined $px) {
                $@ = 'the server sent a curve point this client cannot read';
                return undef;
            }
            $premaster = HTTPS::Handy::EC::ecdh_shared($eph->{'d'}, $px, $py);
            next;
        }
        last if $type == $HS_SERVER_HELLO_DONE;
    }
    unless (defined $premaster) {
        $@ = 'no usable ServerKeyExchange received';
        return undef;
    }

    # --- ClientKeyExchange ---
    my $point = HTTPS::Handy::EC::point_to_bin($eph->{'x'}, $eph->{'y'});
    return undef unless $self->_send_handshake($HS_CLIENT_KEY_EXCH,
                            pack('C', length($point)) . $point);
    $self->_derive_keys($premaster);

    # --- Finished, then the server answer ---
    $self->_send_ccs();
    return undef unless $self->_send_handshake($HS_FINISHED,
                            $self->_finished_value('client finished'));
    return undef unless $self->_expect_ccs();
    my $expect = $self->_finished_value('server finished');
    ($type, $body) = $self->_read_handshake();
    unless (defined $type && ($type == $HS_FINISHED) && ($body eq $expect)) {
        $@ = $self->{'error'} || 'server Finished did not verify';
        return undef;
    }
    return $self;
}

# cert_public_key - Pull the public key out of a DER certificate
# Returns an EC key { type, x, y } or an RSA key { type, n, e, size }.
sub cert_public_key {
    my ($der) = @_;
    my ($tag, $cert) = HTTPS::Handy::X509::der_next($der, 0);
    return undef unless defined $tag && ($tag == 0x30);
    my ($t2, $tbs) = HTTPS::Handy::X509::der_next($cert, 0);
    return undef unless defined $t2;

    # Walk the fields of the TBSCertificate to the seventh one,
    # subjectPublicKeyInfo. The optional [0] version comes first when
    # it is present, which is why the fields are counted, not indexed.
    my @field = ();
    my $pos = 0;
    while ($pos < length($tbs)) {
        my ($t, $c, $next) = HTTPS::Handy::X509::der_next($tbs, $pos);
        last unless defined $t;
        push @field, [ $t, $c ];
        $pos = $next;
    }
    my $offset = (scalar(@field) && ($field[0][0] == 0xA0)) ? 1 : 0;
    my $spki = $field[5 + $offset];
    return undef unless $spki;

    # SubjectPublicKeyInfo = SEQUENCE { algorithm, BIT STRING key }
    my @inner = ();
    $pos = 0;
    while ($pos < length($spki->[1])) {
        my ($t, $c, $next) = HTTPS::Handy::X509::der_next($spki->[1], $pos);
        last unless defined $t;
        push @inner, [ $t, $c ];
        $pos = $next;
    }
    return undef unless (scalar(@inner) >= 2) && ($inner[1][0] == 0x03);
    my $bits = substr($inner[1][1], 1);          # drop the unused bits byte

    # Which algorithm? The first object identifier inside the algorithm
    # field says whether this is an elliptic curve or an RSA key.
    my ($at, $aoid) = HTTPS::Handy::X509::der_next($inner[0][1], 0);
    my $is_ec = (defined $aoid)
             && (unpack('H*', $aoid) eq '2a8648ce3d0201');   # 1.2.840.10045.2.1
    if ($is_ec) {
        my ($x, $y) = HTTPS::Handy::EC::point_from_bin($bits);
        return undef unless defined $x;
        return { 'type' => 'ec', 'x' => $x, 'y' => $y };
    }

    my ($t3, $seq) = HTTPS::Handy::X509::der_next($bits, 0);
    return undef unless defined $t3;
    my ($tn, $n, $p2) = HTTPS::Handy::X509::der_next($seq, 0);
    my ($te, $e) = HTTPS::Handy::X509::der_next($seq, $p2);
    return undef unless defined $tn && defined $te;
    my $nn = HTTPS::Handy::BigInt::b_from_bin($n);
    return {
        'type' => 'rsa',
        'n'    => $nn,
        'e'    => HTTPS::Handy::BigInt::b_from_bin($e),
        'size' => length(HTTPS::Handy::BigInt::b_to_bin($nn)),
    };
}

# ----------------------------------------------------------------
# Reading and writing application data
# ----------------------------------------------------------------

# read_bytes - Return up to $n bytes, or '' at end of stream
sub read_bytes {
    my ($self, $n) = @_;
    while (length($self->{'appbuf'}) < $n) {
        my ($type, $data) = $self->_read_record();
        last unless defined $type;
        if ($type == $CT_ALERT) {
            $self->{'closed'} = 1;
            last;
        }
        next unless $type == $CT_APPDATA;
        $self->{'appbuf'} .= $data;
    }
    my $out = substr($self->{'appbuf'}, 0, $n);
    $self->{'appbuf'} = (length($self->{'appbuf'}) > $n)
                      ? substr($self->{'appbuf'}, $n)
                      : '';
    return $out;
}

# read_line - Return one line, including its terminator
sub read_line {
    my ($self, $limit) = @_;
    $limit = 8192 unless defined $limit;
    my $line = '';
    while (1) {
        my $nl = index($self->{'appbuf'}, "\n");
        if ($nl >= 0) {
            $line .= substr($self->{'appbuf'}, 0, $nl + 1);
            $self->{'appbuf'} = substr($self->{'appbuf'}, $nl + 1);
            return $line;
        }
        $line .= $self->{'appbuf'};
        $self->{'appbuf'} = '';
        return (($line eq '') ? undef : $line) if $self->{'closed'};
        return undef if length($line) > $limit;
        my ($type, $data) = $self->_read_record();
        unless (defined $type) {
            $self->{'closed'} = 1;
            return ($line eq '') ? undef : $line;
        }
        if ($type == $CT_ALERT) {
            $self->{'closed'} = 1;
            return ($line eq '') ? undef : $line;
        }
        $self->{'appbuf'} .= $data if $type == $CT_APPDATA;
    }
}

sub write_data {
    my ($self, $data) = @_;
    return 0 if $self->{'closed'};
    return $self->_send_record($CT_APPDATA, $data);
}

# ----------------------------------------------------------------
# Looking at a finished connection
# ----------------------------------------------------------------
# Both of these end up in the PSGI environment, as psgix.tls_cipher and
# psgix.tls_resumed, so an application -- or the demo page -- can show
# what the handshake actually did.
# ----------------------------------------------------------------

# cipher_name - The name of the cipher suite in use
sub cipher_name {
    my ($self) = @_;
    return $self->{'suite'} ? $self->{'suite'}{'name'} : 'none';
}

# was_resumed - 1 when this connection reused a remembered session and
# skipped the curve arithmetic, 0 when it did the full handshake
sub was_resumed {
    my ($self) = @_;
    return $self->{'resumed'} ? 1 : 0;
}

sub close_tls {
    my ($self) = @_;
    return if $self->{'closed'};
    $self->_send_alert(1, 0);               # warning, close_notify
    $self->{'closed'} = 1;
    return;
}

######################################################################
# HTTPS::Handy::EC - The P-256 elliptic curve
######################################################################
# TLS uses an elliptic curve for two jobs: agreeing on a shared secret
# (ECDH) and proving who the server is (ECDSA). Both are built from one
# operation, "multiply a point by a number":
#
#   public key = private number * G        (G is a fixed point)
#   shared secret = my private number * your public point
#
# Multiplying is easy, dividing is not, and that asymmetry is the whole
# of the security. The curve here is NIST P-256 (also called
# secp256r1 or prime256v1), the one every browser supports.
#
# Points are held in Jacobian coordinates (X, Y, Z), where the affine
# point is (X / Z**2, Y / Z**3). Carrying Z along means the expensive
# modular inverse is done once at the end instead of once per step.
# Field elements are kept in Montgomery form so that every
# multiplication is a b_mont_mul with no division at all.
######################################################################

package HTTPS::Handy::EC;

# Curve parameters, from FIPS 186-4 / SEC 2
my $P256_P  = 'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff';
my $P256_N  = 'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551';
my $P256_B  = '5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b';
my $P256_GX = '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296';
my $P256_GY = '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5';

# The curve is set up once and cached here.
my $CURVE;

sub curve {
    return $CURVE if $CURVE;
    my $p = HTTPS::Handy::BigInt::b_from_hex($P256_P);
    my $n = HTTPS::Handy::BigInt::b_from_hex($P256_N);
    my $mp = HTTPS::Handy::BigInt::b_mont_context($p);
    $CURVE = {
        'p'     => $p,
        'n'     => $n,
        'mp'    => $mp,                                  # field arithmetic
        'mn'    => HTTPS::Handy::BigInt::b_mont_context($n),  # arithmetic mod the order
        'gx'    => HTTPS::Handy::BigInt::b_from_hex($P256_GX),
        'gy'    => HTTPS::Handy::BigInt::b_from_hex($P256_GY),
        'b'     => HTTPS::Handy::BigInt::b_from_hex($P256_B),
    };
    # The generator, in Montgomery form, ready for point arithmetic
    $CURVE->{'g'} = [
        HTTPS::Handy::BigInt::b_to_mont($mp, $CURVE->{'gx'}),
        HTTPS::Handy::BigInt::b_to_mont($mp, $CURVE->{'gy'}),
    ];
    return $CURVE;
}

# ----------------------------------------------------------------
# Field arithmetic, modulo the curve prime, in Montgomery form
# ----------------------------------------------------------------

sub _f_add {
    my ($c, $a, $b) = @_;
    my $r = HTTPS::Handy::BigInt::b_add($a, $b);
    $r = HTTPS::Handy::BigInt::b_sub($r, $c->{'p'})
        if HTTPS::Handy::BigInt::b_cmp($r, $c->{'p'}) >= 0;
    return $r;
}

sub _f_sub {
    my ($c, $a, $b) = @_;
    return HTTPS::Handy::BigInt::b_sub($a, $b)
        if HTTPS::Handy::BigInt::b_cmp($a, $b) >= 0;
    return HTTPS::Handy::BigInt::b_sub(
               HTTPS::Handy::BigInt::b_add($a, $c->{'p'}), $b);
}

sub _f_mul {
    my ($c, $a, $b) = @_;
    return HTTPS::Handy::BigInt::b_mont_mul($c->{'mp'}, $a, $b);
}

# _f_inv - Inverse in the field, by Fermat: a ** (p - 2) = a ** -1
sub _f_inv {
    my ($c, $a) = @_;
    my $e = HTTPS::Handy::BigInt::b_sub($c->{'p'}, [ 2 ]);
    return HTTPS::Handy::BigInt::b_mont_pow($c->{'mp'}, $a, $e);
}

# ----------------------------------------------------------------
# Point arithmetic in Jacobian coordinates
# ----------------------------------------------------------------
# The point at infinity, which acts as zero, is written as Z = 0.
# ----------------------------------------------------------------

sub _jac_infinity {
    my ($c) = @_;
    return [ $c->{'mp'}{'one'}, $c->{'mp'}{'one'}, [ 0 ] ];
}

sub _is_infinity {
    my ($pt) = @_;
    return HTTPS::Handy::BigInt::b_is_zero($pt->[2]) ? 1 : 0;
}

# _jac_double - Add a point to itself, using a = -3 (true for P-256)
sub _jac_double {
    my ($c, $pt) = @_;
    return $pt if _is_infinity($pt);
    my ($x, $y, $z) = @$pt;

    my $delta = _f_mul($c, $z, $z);
    my $gamma = _f_mul($c, $y, $y);
    my $beta  = _f_mul($c, $x, $gamma);

    my $t     = _f_mul($c, _f_sub($c, $x, $delta), _f_add($c, $x, $delta));
    my $alpha = _f_add($c, _f_add($c, $t, $t), $t);          # 3 * t

    my $beta4 = _f_add($c, $beta, $beta);
    $beta4    = _f_add($c, $beta4, $beta4);                  # 4 * beta
    my $x3 = _f_sub($c, _f_mul($c, $alpha, $alpha),
                        _f_add($c, $beta4, $beta4));         # alpha^2 - 8 beta

    my $yz = _f_add($c, $y, $z);
    my $z3 = _f_sub($c, _f_sub($c, _f_mul($c, $yz, $yz), $gamma), $delta);

    my $g2 = _f_mul($c, $gamma, $gamma);
    my $g8 = _f_add($c, $g2, $g2);
    $g8 = _f_add($c, $g8, $g8);
    $g8 = _f_add($c, $g8, $g8);                              # 8 * gamma^2
    my $y3 = _f_sub($c, _f_mul($c, $alpha, _f_sub($c, $beta4, $x3)), $g8);

    return [ $x3, $y3, $z3 ];
}

# _jac_add_affine - Add an affine point (x, y) to a Jacobian point
sub _jac_add_affine {
    my ($c, $pt, $ax, $ay) = @_;
    return [ $ax, $ay, $c->{'mp'}{'one'} ] if _is_infinity($pt);
    my ($x1, $y1, $z1) = @$pt;

    my $zz = _f_mul($c, $z1, $z1);
    my $u2 = _f_mul($c, $ax, $zz);
    my $s2 = _f_mul($c, $ay, _f_mul($c, $z1, $zz));
    my $h  = _f_sub($c, $u2, $x1);
    my $r  = _f_sub($c, $s2, $y1);

    if (HTTPS::Handy::BigInt::b_is_zero($h)) {
        return _jac_double($c, $pt) if HTTPS::Handy::BigInt::b_is_zero($r);
        return _jac_infinity($c);
    }

    my $hh = _f_mul($c, $h, $h);
    my $i  = _f_add($c, $hh, $hh);
    $i = _f_add($c, $i, $i);                                 # 4 * h^2
    my $j  = _f_mul($c, $h, $i);
    my $r2 = _f_add($c, $r, $r);                             # 2 * r
    my $v  = _f_mul($c, $x1, $i);

    my $x3 = _f_sub($c, _f_sub($c, _f_mul($c, $r2, $r2), $j),
                        _f_add($c, $v, $v));
    my $y1j = _f_mul($c, $y1, $j);
    my $y3 = _f_sub($c, _f_mul($c, $r2, _f_sub($c, $v, $x3)),
                        _f_add($c, $y1j, $y1j));
    my $zh = _f_add($c, $z1, $h);
    my $z3 = _f_sub($c, _f_sub($c, _f_mul($c, $zh, $zh), $zz), $hh);

    return [ $x3, $y3, $z3 ];
}

# _jac_to_affine - Divide out Z, giving ordinary (x, y) in Montgomery form
sub _jac_to_affine {
    my ($c, $pt) = @_;
    return (undef, undef) if _is_infinity($pt);
    my $zi  = _f_inv($c, $pt->[2]);
    my $zi2 = _f_mul($c, $zi, $zi);
    my $zi3 = _f_mul($c, $zi2, $zi);
    return (_f_mul($c, $pt->[0], $zi2), _f_mul($c, $pt->[1], $zi3));
}

# ----------------------------------------------------------------
# Scalar multiplication
# ----------------------------------------------------------------

# _mul_point - Multiply the affine point (ax, ay) by the number $k
# Returns the result as a pair of ordinary big integers, or undef for
# the point at infinity.
sub _mul_point {
    my ($c, $k, $ax, $ay) = @_;
    my $acc = _jac_infinity($c);
    for (my $i = HTTPS::Handy::BigInt::b_bits($k) - 1; $i >= 0; $i--) {
        $acc = _jac_double($c, $acc);
        $acc = _jac_add_affine($c, $acc, $ax, $ay)
            if HTTPS::Handy::BigInt::b_bit($k, $i);
    }
    my ($x, $y) = _jac_to_affine($c, $acc);
    return (undef, undef) unless defined $x;
    return (HTTPS::Handy::BigInt::b_from_mont($c->{'mp'}, $x),
            HTTPS::Handy::BigInt::b_from_mont($c->{'mp'}, $y));
}

# mul_generator - Multiply the curve generator G by $k
sub mul_generator {
    my ($k) = @_;
    my $c = curve();
    return _mul_point($c, $k, $c->{'g'}[0], $c->{'g'}[1]);
}

# ----------------------------------------------------------------
# Keys and points on the wire
# ----------------------------------------------------------------
# TLS sends a point as 0x04 followed by x and y, each 32 bytes
# (RFC 8422, uncompressed form).
# ----------------------------------------------------------------

sub point_to_bin {
    my ($x, $y) = @_;
    return "\x04" . HTTPS::Handy::BigInt::b_to_bin($x, 32)
                  . HTTPS::Handy::BigInt::b_to_bin($y, 32);
}

sub point_from_bin {
    my ($bin) = @_;
    return () unless length($bin) == 65;
    return () unless substr($bin, 0, 1) eq "\x04";
    return (HTTPS::Handy::BigInt::b_from_bin(substr($bin, 1, 32)),
            HTTPS::Handy::BigInt::b_from_bin(substr($bin, 33, 32)));
}

# generate_key - A private number and the public point it gives
sub generate_key {
    my $c = curve();
    while (1) {
        my $d = HTTPS::Handy::BigInt::b_from_bin(
                    HTTPS::Handy::Crypt::random_bytes(32));
        next if HTTPS::Handy::BigInt::b_is_zero($d);
        next if HTTPS::Handy::BigInt::b_cmp($d, $c->{'n'}) >= 0;
        my ($x, $y) = mul_generator($d);
        next unless defined $x;
        return { 'type' => 'ec', 'd' => $d, 'x' => $x, 'y' => $y };
    }
}

# is_on_curve - Check y**2 = x**3 - 3x + b, so that a hostile peer
# cannot push us onto a weaker curve of its own choosing
sub is_on_curve {
    my ($x, $y) = @_;
    my $c = curve();
    return 0 if HTTPS::Handy::BigInt::b_cmp($x, $c->{'p'}) >= 0;
    return 0 if HTTPS::Handy::BigInt::b_cmp($y, $c->{'p'}) >= 0;
    my $mx = HTTPS::Handy::BigInt::b_to_mont($c->{'mp'}, $x);
    my $my = HTTPS::Handy::BigInt::b_to_mont($c->{'mp'}, $y);
    my $mb = HTTPS::Handy::BigInt::b_to_mont($c->{'mp'}, $c->{'b'});
    my $lhs = _f_mul($c, $my, $my);
    my $x3  = _f_mul($c, $mx, _f_mul($c, $mx, $mx));
    my $x3a = _f_sub($c, $x3, _f_add($c, $mx, _f_add($c, $mx, $mx)));  # - 3x
    my $rhs = _f_add($c, $x3a, $mb);
    return (HTTPS::Handy::BigInt::b_cmp($lhs, $rhs) == 0) ? 1 : 0;
}

# ecdh_shared - The x coordinate of (my private number * peer point),
# which is the pre-master secret in TLS
sub ecdh_shared {
    my ($d, $px, $py) = @_;
    my $c = curve();
    return undef unless is_on_curve($px, $py);
    my $mx = HTTPS::Handy::BigInt::b_to_mont($c->{'mp'}, $px);
    my $my = HTTPS::Handy::BigInt::b_to_mont($c->{'mp'}, $py);
    my ($x, $y) = _mul_point($c, $d, $mx, $my);
    return undef unless defined $x;
    return HTTPS::Handy::BigInt::b_to_bin($x, 32);
}

# ----------------------------------------------------------------
# ECDSA
# ----------------------------------------------------------------
# A signature is a pair (r, s):
#
#   r = x coordinate of (k * G)      for a fresh random k
#   s = (hash + r * private) / k     all modulo the curve order n
#
# k must never repeat and never be guessable: two signatures made with
# the same k reveal the private key outright.
# ----------------------------------------------------------------

# _n_mul / _n_inv - Arithmetic modulo the curve order
sub _n_mul {
    my ($c, $a, $b) = @_;
    my $mn = $c->{'mn'};
    return HTTPS::Handy::BigInt::b_from_mont($mn,
        HTTPS::Handy::BigInt::b_mont_mul($mn,
            HTTPS::Handy::BigInt::b_to_mont($mn, $a),
            HTTPS::Handy::BigInt::b_to_mont($mn, $b)));
}

sub _n_inv {
    my ($c, $a) = @_;
    return HTTPS::Handy::BigInt::b_modinv($a, $c->{'n'});
}

# sign - Sign a message with SHA-256 and the private number $d
# Returns the signature as the DER SEQUENCE { INTEGER r, INTEGER s }
# that TLS and X.509 both expect.
sub sign {
    my ($key, $message) = @_;
    my $c = curve();
    my $hash = HTTPS::Handy::BigInt::b_from_bin(
                   HTTPS::Handy::Crypt::sha256($message));
    $hash = HTTPS::Handy::BigInt::b_mod($hash, $c->{'n'});

    while (1) {
        my $k = HTTPS::Handy::BigInt::b_from_bin(
                    HTTPS::Handy::Crypt::random_bytes(32));
        next if HTTPS::Handy::BigInt::b_is_zero($k);
        next if HTTPS::Handy::BigInt::b_cmp($k, $c->{'n'}) >= 0;

        my ($x, $y) = mul_generator($k);
        next unless defined $x;
        my $r = HTTPS::Handy::BigInt::b_mod($x, $c->{'n'});
        next if HTTPS::Handy::BigInt::b_is_zero($r);

        my $rd = _n_mul($c, $r, $key->{'d'});
        my $sum = HTTPS::Handy::BigInt::b_add($hash, $rd);
        $sum = HTTPS::Handy::BigInt::b_sub($sum, $c->{'n'})
            if HTTPS::Handy::BigInt::b_cmp($sum, $c->{'n'}) >= 0;
        my $s = _n_mul($c, _n_inv($c, $k), $sum);
        next if HTTPS::Handy::BigInt::b_is_zero($s);

        return HTTPS::Handy::X509::der_sequence(
            HTTPS::Handy::X509::der_integer_big($r),
            HTTPS::Handy::X509::der_integer_big($s));
    }
}

######################################################################
# HTTPS::Handy::ChaCha - ChaCha20-Poly1305 authenticated encryption
######################################################################
# This is the cipher that protects every byte after the handshake.
# It does two things at once:
#
#   ChaCha20   turns a key, a nonce and a counter into a keystream,
#              which is XORed with the data. Encryption and decryption
#              are the same operation.
#   Poly1305   computes a 16 byte tag over the ciphertext, so that a
#              record that was altered in transit is rejected instead
#              of decrypted.
#
# ChaCha20 is built from nothing but 32 bit addition, exclusive or and
# rotation, which is why it is short enough to read and quick enough to
# run in Perl. Poly1305 is one multiplication modulo 2**130 - 5 per
# 16 bytes, and it borrows that arithmetic from HTTPS::Handy::BigInt.
#
# Reference: RFC 8439.
######################################################################

package HTTPS::Handy::ChaCha;

# 2 ** 32. It is written as a product because a 32 bit integer cannot
# hold it: on such a build Perl would read a literal that large as a
# remainder modulus of zero. Nothing below takes a remainder by it;
# carries are removed by subtraction, which is exact and portable.
my $TWO32 = 65536 * 65536;

# ----------------------------------------------------------------
# ChaCha20
# ----------------------------------------------------------------

# _quarter_round - The core mixing step, applied to four state words
sub _quarter_round {
    my ($s, $a, $b, $c, $d) = @_;
    my $x;

    $s->[$a] += $s->[$b];
    $s->[$a] -= $TWO32 if $s->[$a] >= $TWO32;
    $x = $s->[$d] ^ $s->[$a];
    $s->[$d] = (($x << 16) | ($x >> 16)) & 0xFFFFFFFF;

    $s->[$c] += $s->[$d];
    $s->[$c] -= $TWO32 if $s->[$c] >= $TWO32;
    $x = $s->[$b] ^ $s->[$c];
    $s->[$b] = (($x << 12) | ($x >> 20)) & 0xFFFFFFFF;

    $s->[$a] += $s->[$b];
    $s->[$a] -= $TWO32 if $s->[$a] >= $TWO32;
    $x = $s->[$d] ^ $s->[$a];
    $s->[$d] = (($x << 8) | ($x >> 24)) & 0xFFFFFFFF;

    $s->[$c] += $s->[$d];
    $s->[$c] -= $TWO32 if $s->[$c] >= $TWO32;
    $x = $s->[$b] ^ $s->[$c];
    $s->[$b] = (($x << 7) | ($x >> 25)) & 0xFFFFFFFF;
    return;
}

# block - One 64 byte block of keystream
#   $key     32 bytes
#   $nonce   12 bytes
#   $counter block number, starting at 0 or 1
sub block {
    my ($key, $counter, $nonce) = @_;

    # "expand 32-byte k", the constant that starts every state
    my @s = (0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
             unpack('V8', $key),
             $counter - $TWO32 * int($counter / $TWO32),
             unpack('V3', $nonce));
    my @initial = @s;

    # Ten double rounds: four columns, then four diagonals
    for (my $i = 0; $i < 10; $i++) {
        _quarter_round(\@s, 0, 4,  8, 12);
        _quarter_round(\@s, 1, 5,  9, 13);
        _quarter_round(\@s, 2, 6, 10, 14);
        _quarter_round(\@s, 3, 7, 11, 15);
        _quarter_round(\@s, 0, 5, 10, 15);
        _quarter_round(\@s, 1, 6, 11, 12);
        _quarter_round(\@s, 2, 7,  8, 13);
        _quarter_round(\@s, 3, 4,  9, 14);
    }

    for (my $i = 0; $i < 16; $i++) {
        $s[$i] += $initial[$i];
        $s[$i] -= $TWO32 if $s[$i] >= $TWO32;
    }
    return pack('V16', @s);
}

# encrypt - XOR the data with the keystream (decryption is the same)
sub encrypt {
    my ($key, $counter, $nonce, $data) = @_;
    my $out = '';
    my $len = length($data);
    for (my $off = 0; $off < $len; $off += 64) {
        my $chunk = substr($data, $off, 64);
        my $stream = block($key, $counter + int($off / 64), $nonce);
        $out .= $chunk ^ substr($stream, 0, length($chunk));
    }
    return $out;
}

# ----------------------------------------------------------------
# Poly1305
# ----------------------------------------------------------------
# The tag is  ((m1 * r**n + m2 * r**(n-1) + ... ) mod (2**130 - 5)) + s
# where each mi is 16 bytes of the message with a 1 bit appended.
# ----------------------------------------------------------------

my $POLY_CTX;      # Montgomery context for 2**130 - 5, built once

sub _poly_ctx {
    return $POLY_CTX if $POLY_CTX;
    # 2**130 - 5
    my $p = HTTPS::Handy::BigInt::b_from_hex('3fffffffffffffffffffffffffffffffb');
    $POLY_CTX = HTTPS::Handy::BigInt::b_mont_context($p);
    return $POLY_CTX;
}

# _le_to_big / _big_to_le - Poly1305 reads and writes little endian
sub _le_to_big {
    my ($bin) = @_;
    return HTTPS::Handy::BigInt::b_from_bin(scalar reverse $bin);
}

sub _big_to_le {
    my ($big, $len) = @_;
    return scalar reverse HTTPS::Handy::BigInt::b_to_bin($big, $len);
}

# mac - The 16 byte Poly1305 tag of $msg under the 32 byte $key
sub mac {
    my ($key, $msg) = @_;
    my $ctx = _poly_ctx();

    # r is clamped: some bits are cleared so that the multiplication
    # cannot overflow the reduction that follows.
    my @rb = unpack('C16', substr($key, 0, 16));
    $rb[3]  = $rb[3]  & 15;
    $rb[7]  = $rb[7]  & 15;
    $rb[11] = $rb[11] & 15;
    $rb[15] = $rb[15] & 15;
    $rb[4]  = $rb[4]  & 252;
    $rb[8]  = $rb[8]  & 252;
    $rb[12] = $rb[12] & 252;
    my $r = _le_to_big(pack('C16', @rb));
    my $s = _le_to_big(substr($key, 16, 16));

    # r stays in Montgomery form, the accumulator stays ordinary, so
    # one b_mont_mul per block gives exactly (acc + n) * r mod p.
    my $r_mont = HTTPS::Handy::BigInt::b_to_mont($ctx, $r);
    my $acc = [ 0 ];

    my $len = length($msg);
    for (my $off = 0; $off < $len; $off += 16) {
        my $chunk = substr($msg, $off, 16);
        # Append a 1 bit just above the block
        my $n = _le_to_big($chunk . "\x01");
        $acc = HTTPS::Handy::BigInt::b_add($acc, $n);
        $acc = HTTPS::Handy::BigInt::b_mont_mul($ctx, $acc, $r_mont);
    }

    $acc = HTTPS::Handy::BigInt::b_add($acc, $s);
    return substr(_big_to_le($acc, 20), 0, 16);     # keep the low 128 bits
}

# ----------------------------------------------------------------
# The AEAD construction (RFC 8439 section 2.8)
# ----------------------------------------------------------------

sub _pad16 {
    my ($n) = @_;
    return ($n % 16) ? ("\x00" x (16 - ($n % 16))) : '';
}

# _le64 - An eight byte little endian length, split for 32 bit Perl
sub _le64 {
    my ($n) = @_;
    my $hi = int($n / $TWO32);
    return pack('VV', $n - $hi * $TWO32, $hi);
}

sub _tag {
    my ($key, $nonce, $aad, $cipher) = @_;
    # The one time Poly1305 key is the first block of the keystream
    my $poly_key = substr(block($key, 0, $nonce), 0, 32);
    my $data = $aad . _pad16(length($aad))
             . $cipher . _pad16(length($cipher))
             . _le64(length($aad)) . _le64(length($cipher));
    return mac($poly_key, $data);
}

# aead_encrypt - Returns ciphertext with the 16 byte tag appended
sub aead_encrypt {
    my ($key, $nonce, $aad, $plain) = @_;
    my $cipher = encrypt($key, 1, $nonce, $plain);
    return $cipher . _tag($key, $nonce, $aad, $cipher);
}

# aead_decrypt - Returns the plaintext, or undef if the tag is wrong
sub aead_decrypt {
    my ($key, $nonce, $aad, $sealed) = @_;
    return undef if length($sealed) < 16;
    my $cipher = substr($sealed, 0, length($sealed) - 16);
    my $tag    = substr($sealed, length($sealed) - 16);
    return undef if _tag($key, $nonce, $aad, $cipher) ne $tag;
    return encrypt($key, 1, $nonce, $cipher);
}

######################################################################
# HTTPS::Handy::Crypt - Hashing, message authentication, randomness
######################################################################
# Everything here is written in plain Perl with no module and no
# external program. Each routine takes and returns byte strings.
#
#   sha256       a one way hash function (FIPS 180-4)
#   hmac_sha256  a keyed hash (RFC 2104)
#   prf          the TLS 1.2 pseudo random function (RFC 5246)
#   random_bytes bytes for keys, nonces and serial numbers
#
# All arithmetic is done on 32 bit values kept inside Perl numbers.
# Nothing here takes a remainder modulo 2 ** 32, and nothing relies on
# a bit mask to discard a carry: where an integer is only 32 bits wide,
# 2 ** 32 itself does not fit in one, and Perl would turn such a
# modulus into zero. Carries are removed by subtraction instead, which
# is exact in a floating point number and behaves the same everywhere.
######################################################################

package HTTPS::Handy::Crypt;

my $WRAP32 = 65536 * 65536;     # 2 ** 32, which a 32 bit integer cannot hold

# _add32 - Add numbers, keeping only the low 32 bits
sub _add32 {
    my $sum = 0;
    for my $v (@_) {
        $sum += $v;
        $sum -= $WRAP32 while $sum >= $WRAP32;
    }
    return $sum;
}

# _split32 - Split a number into its high and low 32 bit halves
sub _split32 {
    my ($n) = @_;
    my $hi = int($n / $WRAP32);
    return ($hi, $n - $hi * $WRAP32);
}

# _rotr32 - Rotate a 32 bit value to the right
sub _rotr32 {
    my ($x, $n) = @_;
    return ((($x >> $n) | ($x << (32 - $n))) & 0xFFFFFFFF);
}

# ----------------------------------------------------------------
# SHA-256
# ----------------------------------------------------------------

my @SHA256_K = (
    0x428A2F98, 0x71374491, 0xB5C0FBCF, 0xE9B5DBA5, 0x3956C25B, 0x59F111F1,
    0x923F82A4, 0xAB1C5ED5, 0xD807AA98, 0x12835B01, 0x243185BE, 0x550C7DC3,
    0x72BE5D74, 0x80DEB1FE, 0x9BDC06A7, 0xC19BF174, 0xE49B69C1, 0xEFBE4786,
    0x0FC19DC6, 0x240CA1CC, 0x2DE92C6F, 0x4A7484AA, 0x5CB0A9DC, 0x76F988DA,
    0x983E5152, 0xA831C66D, 0xB00327C8, 0xBF597FC7, 0xC6E00BF3, 0xD5A79147,
    0x06CA6351, 0x14292967, 0x27B70A85, 0x2E1B2138, 0x4D2C6DFC, 0x53380D13,
    0x650A7354, 0x766A0ABB, 0x81C2C92E, 0x92722C85, 0xA2BFE8A1, 0xA81A664B,
    0xC24B8B70, 0xC76C51A3, 0xD192E819, 0xD6990624, 0xF40E3585, 0x106AA070,
    0x19A4C116, 0x1E376C08, 0x2748774C, 0x34B0BCB5, 0x391C0CB3, 0x4ED8AA4A,
    0x5B9CCA4F, 0x682E6FF3, 0x748F82EE, 0x78A5636F, 0x84C87814, 0x8CC70208,
    0x90BEFFFA, 0xA4506CEB, 0xBEF9A3F7, 0xC67178F2,
);

sub sha256 {
    my ($msg) = @_;
    my $ml = length($msg) * 8;
    $msg .= "\x80";
    $msg .= "\x00" while (length($msg) % 64) != 56;
    $msg .= pack('NN', _split32($ml));

    my @h = (0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
             0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19);

    for (my $off = 0; $off < length($msg); $off += 64) {
        my @w = unpack('N16', substr($msg, $off, 64));
        for (my $i = 16; $i < 64; $i++) {
            my $s0 = _rotr32($w[$i-15],  7) ^ _rotr32($w[$i-15], 18) ^ ($w[$i-15] >>  3);
            my $s1 = _rotr32($w[$i-2],  17) ^ _rotr32($w[$i-2],  19) ^ ($w[$i-2]  >> 10);
            $w[$i] = _add32($w[$i-16], $s0, $w[$i-7], $s1);
        }
        my ($a, $b, $c, $d, $e, $f, $g, $hh) = @h;
        for (my $i = 0; $i < 64; $i++) {
            my $S1 = _rotr32($e, 6) ^ _rotr32($e, 11) ^ _rotr32($e, 25);
            my $ch = ($e & $f) ^ ((~$e & 0xFFFFFFFF) & $g);
            my $t1 = _add32($hh, $S1, $ch, $SHA256_K[$i], $w[$i]);
            my $S0 = _rotr32($a, 2) ^ _rotr32($a, 13) ^ _rotr32($a, 22);
            my $mj = ($a & $b) ^ ($a & $c) ^ ($b & $c);
            my $t2 = _add32($S0, $mj);
            $hh = $g;
            $g  = $f;
            $f  = $e;
            $e  = _add32($d, $t1);
            $d  = $c;
            $c  = $b;
            $b  = $a;
            $a  = _add32($t1, $t2);
        }
        @h = (_add32($h[0], $a), _add32($h[1], $b), _add32($h[2], $c),
              _add32($h[3], $d), _add32($h[4], $e), _add32($h[5], $f),
              _add32($h[6], $g), _add32($h[7], $hh));
    }
    return pack('N8', @h);
}

# ----------------------------------------------------------------
# HMAC (RFC 2104)
# ----------------------------------------------------------------
# A hash keyed with a secret: nobody without the key can produce the
# same value, which is what makes the Finished message and the PRF
# below trustworthy.
# ----------------------------------------------------------------

sub hmac_sha256 {
    my ($key, $data) = @_;
    $key = sha256($key) if length($key) > 64;
    $key .= "\x00" x (64 - length($key));
    my $ipad = $key ^ ("\x36" x 64);
    my $opad = $key ^ ("\x5c" x 64);
    return sha256($opad . sha256($ipad . $data));
}

# ----------------------------------------------------------------
# TLS 1.2 pseudo random function (RFC 5246 section 5)
# ----------------------------------------------------------------
# PRF(secret, label, seed) = P_SHA256(secret, label + seed)
#
#   P_hash(secret, seed) = HMAC(secret, A(1) + seed)
#                        + HMAC(secret, A(2) + seed) + ...
#   A(0) = seed,  A(i) = HMAC(secret, A(i-1))
#
# Every key, IV and Finished value in the handshake comes out of this
# one function, which is why it is the heart of TLS key derivation.
# ----------------------------------------------------------------

sub prf {
    my ($secret, $label, $seed, $want) = @_;
    my $full = $label . $seed;
    my $a    = $full;
    my $out  = '';
    while (length($out) < $want) {
        $a = hmac_sha256($secret, $a);
        $out .= hmac_sha256($secret, $a . $full);
    }
    return substr($out, 0, $want);
}

# ----------------------------------------------------------------
# Randomness
# ----------------------------------------------------------------
# Keys and nonces must be unpredictable. The operating system random
# device is used when it can be read. Otherwise the module falls back
# to a hash of whatever varying values are at hand, which is enough for
# a classroom but not for protecting anything of value; see the
# SECURITY section of the documentation.
# ----------------------------------------------------------------

my $RAND_POOL = '';
my $RAND_COUNT = 0;

sub random_bytes {
    my ($n) = @_;
    my $out = '';

    # Preferred source: the operating system
    local *RANDDEV;
    if (open(RANDDEV, '</dev/urandom')) {
        binmode RANDDEV;
        my $buf = '';
        my $got = read(RANDDEV, $buf, $n);
        close RANDDEV;
        return $buf if defined $got && ($got == $n);
    }

    # Fallback: stir a pool with everything that varies and hash it
    unless ($RAND_POOL) {
        $RAND_POOL = join('|', $$, time(), rand(), $0, scalar(%ENV),
                          scalar(localtime), 'HTTPS::Handy');
        for (my $i = 0; $i < 64; $i++) {
            $RAND_POOL .= pack('d', rand());
        }
    }
    while (length($out) < $n) {
        $RAND_COUNT++;
        $RAND_POOL = sha256($RAND_POOL . pack('NN', $RAND_COUNT, time())
                          . pack('d', rand()));
        $out .= $RAND_POOL;
    }
    return substr($out, 0, $n);
}

######################################################################
# HTTPS::Handy::X509 - DER and PEM encoding, self-signed certificates
######################################################################
# A certificate is a nest of ASN.1 structures encoded with DER, which
# writes every value as three parts: a tag byte, a length, and the
# contents. Nesting is what makes it look complicated; each individual
# step is simple, as the builders below show.
#
# This package can
#
#   * build a self-signed certificate and its RSA private key,
#   * write and read the PEM files that hold them,
#   * read a certificate or key that was made by another tool.
######################################################################

package HTTPS::Handy::X509;

# ----------------------------------------------------------------
# Base64 (RFC 4648), written out so that MIME::Base64 is not needed
# ----------------------------------------------------------------

my $B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

sub b64_encode {
    my ($data, $eol) = @_;
    $eol = "\n" unless defined $eol;
    my $out = '';
    for (my $i = 0; $i < length($data); $i += 3) {
        my $chunk = substr($data, $i, 3);
        my $n = length($chunk);
        my @b = unpack('C3', $chunk . "\x00\x00");
        my $v = $b[0] * 65536 + $b[1] * 256 + $b[2];
        my @c = (int($v / 262144) % 64, int($v / 4096) % 64,
                 int($v / 64) % 64,     $v % 64);
        my $group = '';
        for (my $j = 0; $j < 4; $j++) {
            $group .= substr($B64_CHARS, $c[$j], 1);
        }
        substr($group, 3, 1) = '=' if $n < 3;
        substr($group, 2, 1) = '=' if $n < 2;
        $out .= $group;
    }
    # Wrap at 64 characters, as PEM requires
    my $wrapped = '';
    for (my $i = 0; $i < length($out); $i += 64) {
        $wrapped .= substr($out, $i, 64) . $eol;
    }
    return $wrapped;
}

sub b64_decode {
    my ($text) = @_;
    $text =~ s/[^A-Za-z0-9+\/=]//g;
    $text =~ s/=+$//;
    my $out = '';
    my $bits = 0;
    my $acc = 0;
    for (my $i = 0; $i < length($text); $i++) {
        my $v = index($B64_CHARS, substr($text, $i, 1));
        next if $v < 0;
        $acc = $acc * 64 + $v;
        $bits += 6;
        if ($bits >= 8) {
            $bits -= 8;
            my $div = 2 ** $bits;
            $out .= chr(int($acc / $div) % 256);
            $acc = $acc % $div;
        }
    }
    return $out;
}

# ----------------------------------------------------------------
# DER building blocks
# ----------------------------------------------------------------

# _der - Wrap contents in a tag and a length
sub _der {
    my ($tag, $contents) = @_;
    my $len = length($contents);
    my $enc;
    if ($len < 128) {
        $enc = pack('C', $len);
    }
    else {
        my $bytes = '';
        my $n = $len;
        while ($n > 0) {
            $bytes = pack('C', $n % 256) . $bytes;
            $n = int($n / 256);
        }
        $enc = pack('C', 0x80 + length($bytes)) . $bytes;
    }
    return pack('C', $tag) . $enc . $contents;
}

sub der_sequence { return _der(0x30, join('', @_)) }
sub der_set      { return _der(0x31, join('', @_)) }

# der_integer - A non negative integer, from a big endian byte string
sub der_integer {
    my ($bin) = @_;
    $bin =~ s/^\x00+//;
    $bin = "\x00" if $bin eq '';
    # A leading bit of 1 would mean a negative number, so pad with zero
    $bin = "\x00" . $bin if unpack('C', substr($bin, 0, 1)) >= 0x80;
    return _der(0x02, $bin);
}

sub der_integer_big {
    my ($big) = @_;
    return der_integer(HTTPS::Handy::BigInt::b_to_bin($big));
}

sub der_bitstring {
    my ($bin) = @_;
    return _der(0x03, "\x00" . $bin);        # zero unused bits
}

sub der_octetstring { return _der(0x04, $_[0]) }
sub der_null        { return _der(0x05, '')  }
sub der_printable   { return _der(0x13, $_[0]) }
sub der_utctime     { return _der(0x17, $_[0]) }
sub der_boolean     { return _der(0x01, $_[0] ? "\xFF" : "\x00") }

# der_oid - Encode an object identifier such as "1.2.840.113549.1.1.11"
sub der_oid {
    my ($oid) = @_;
    my @n = split /\./, $oid;
    my $out = pack('C', $n[0] * 40 + $n[1]);
    for (my $i = 2; $i < scalar(@n); $i++) {
        my $v = $n[$i];
        my @seven = ($v % 128);
        $v = int($v / 128);
        while ($v > 0) {
            unshift @seven, ($v % 128) + 128;
            $v = int($v / 128);
        }
        $out .= pack('C*', @seven);
    }
    return _der(0x06, $out);
}

# der_context - A context specific, constructed tag such as [0] or [3]
sub der_context {
    my ($number, $contents) = @_;
    return _der(0xA0 + $number, $contents);
}

# ----------------------------------------------------------------
# A very small DER reader, enough to walk a certificate or a key
# ----------------------------------------------------------------

# der_next - Read one TLV at $pos; returns (tag, contents, next position)
sub der_next {
    my ($der, $pos) = @_;
    return () if $pos + 2 > length($der);
    my $tag = unpack('C', substr($der, $pos, 1));
    my $b   = unpack('C', substr($der, $pos + 1, 1));
    my $len;
    my $hdr = 2;
    if ($b < 128) {
        $len = $b;
    }
    else {
        my $n = $b - 128;
        $len = 0;
        for (my $i = 0; $i < $n; $i++) {
            $len = $len * 256 + unpack('C', substr($der, $pos + 2 + $i, 1));
        }
        $hdr = 2 + $n;
    }
    return ($tag, substr($der, $pos + $hdr, $len), $pos + $hdr + $len);
}

# ----------------------------------------------------------------
# PEM files
# ----------------------------------------------------------------

sub pem_wrap {
    my ($label, $der) = @_;
    return "-----BEGIN $label-----\n" . b64_encode($der) . "-----END $label-----\n";
}

# pem_blocks - Return every DER block of the given label found in $text
sub pem_blocks {
    my ($text, $label) = @_;
    my @out = ();
    my $re = defined $label ? quotemeta($label) : '[A-Z0-9 ]+';
    while ($text =~ /-----BEGIN ($re)-----(.*?)-----END \1-----/gs) {
        push @out, b64_decode($2);
    }
    return @out;
}

# ----------------------------------------------------------------
# RSA private keys in PKCS #1 and PKCS #8 form
# ----------------------------------------------------------------

sub private_key_to_der {
    my ($key) = @_;
    return der_sequence(
        der_integer("\x00"),                     # version 0
        der_integer_big($key->{'n'}),
        der_integer_big($key->{'e'}),
        der_integer_big($key->{'d'}),
        der_integer_big($key->{'p'}),
        der_integer_big($key->{'q'}),
        der_integer_big($key->{'dp'}),
        der_integer_big($key->{'dq'}),
        der_integer_big($key->{'qinv'}),
    );
}

sub private_key_to_pem {
    my ($key) = @_;
    return pem_wrap('RSA PRIVATE KEY', private_key_to_der($key));
}

# private_key_from_der - Read a PKCS #1 (or PKCS #8 wrapped) RSA key
sub private_key_from_der {
    my ($der) = @_;
    my ($tag, $body) = der_next($der, 0);
    return undef unless defined $tag && $tag == 0x30;

    my @field = ();
    my $pos = 0;
    while (1) {
        my ($t, $c, $next) = der_next($body, $pos);
        last unless defined $t;
        push @field, [ $t, $c ];
        $pos = $next;
        last if $pos >= length($body);
    }
    return undef unless scalar(@field) >= 3;

    # PKCS #8: version, AlgorithmIdentifier, OCTET STRING with the key
    if (($field[1][0] == 0x30) && ($field[2][0] == 0x04)) {
        return private_key_from_der($field[2][1]);
    }
    return undef unless scalar(@field) >= 9;

    my @v = map { HTTPS::Handy::BigInt::b_from_bin($_->[1]) } @field[1 .. 8];
    return {
        'type' => 'rsa',
        'n'    => $v[0],
        'e'    => $v[1],
        'd'    => $v[2],
        'p'    => $v[3],
        'q'    => $v[4],
        'dp'   => $v[5],
        'dq'   => $v[6],
        'qinv' => $v[7],
        'size' => length(HTTPS::Handy::BigInt::b_to_bin($v[0])),
    };
}

# ----------------------------------------------------------------
# Elliptic curve keys (SEC 1, and PKCS #8 wrapped)
# ----------------------------------------------------------------

# Object identifiers used for P-256 keys and signatures
my $OID_EC_PUBLIC_KEY = '1.2.840.10045.2.1';
my $OID_PRIME256V1    = '1.2.840.10045.3.1.7';
my $OID_ECDSA_SHA256  = '1.2.840.10045.4.3.2';
my $OID_RSA_ENC       = '1.2.840.113549.1.1.1';
my $OID_RSA_SHA256    = '1.2.840.113549.1.1.11';

sub ec_private_key_to_der {
    my ($key) = @_;
    my $point = HTTPS::Handy::EC::point_to_bin($key->{'x'}, $key->{'y'});
    return der_sequence(
        der_integer("\x01"),                                   # version 1
        der_octetstring(HTTPS::Handy::BigInt::b_to_bin($key->{'d'}, 32)),
        der_context(0, der_oid($OID_PRIME256V1)),
        der_context(1, der_bitstring($point)),
    );
}

sub ec_private_key_to_pem {
    my ($key) = @_;
    return pem_wrap('EC PRIVATE KEY', ec_private_key_to_der($key));
}

# ec_private_key_from_der - Read a SEC 1 (or PKCS #8 wrapped) EC key
sub ec_private_key_from_der {
    my ($der) = @_;
    my ($tag, $body) = der_next($der, 0);
    return undef unless defined $tag && ($tag == 0x30);

    my @field = ();
    my $pos = 0;
    while ($pos < length($body)) {
        my ($t, $c, $next) = der_next($body, $pos);
        last unless defined $t;
        push @field, [ $t, $c ];
        $pos = $next;
    }
    return undef unless scalar(@field) >= 2;

    # PKCS #8: version, AlgorithmIdentifier, OCTET STRING with the key
    if (($field[1][0] == 0x30) && (scalar(@field) >= 3)
     && ($field[2][0] == 0x04)) {
        return ec_private_key_from_der($field[2][1]);
    }
    return undef unless $field[1][0] == 0x04;

    my $d = HTTPS::Handy::BigInt::b_from_bin($field[1][1]);
    my ($x, $y) = HTTPS::Handy::EC::mul_generator($d);
    return undef unless defined $x;
    return { 'type' => 'ec', 'd' => $d, 'x' => $x, 'y' => $y };
}

# ----------------------------------------------------------------
# Public keys
# ----------------------------------------------------------------

# public_key_der - SubjectPublicKeyInfo, for either kind of key
sub public_key_der {
    my ($key) = @_;
    if ($key->{'type'} eq 'ec') {
        return der_sequence(
            der_sequence(der_oid($OID_EC_PUBLIC_KEY), der_oid($OID_PRIME256V1)),
            der_bitstring(HTTPS::Handy::EC::point_to_bin($key->{'x'}, $key->{'y'})),
        );
    }
    my $rsa = der_sequence(der_integer_big($key->{'n'}),
                           der_integer_big($key->{'e'}));
    return der_sequence(
        der_sequence(der_oid($OID_RSA_ENC), der_null()),
        der_bitstring($rsa),
    );
}

# signature_algorithm_der - The AlgorithmIdentifier a certificate signed
# with this key carries
sub signature_algorithm_der {
    my ($key) = @_;
    return der_sequence(der_oid($OID_ECDSA_SHA256)) if $key->{'type'} eq 'ec';
    return der_sequence(der_oid($OID_RSA_SHA256), der_null());
}

# sign_data - Sign with SHA-256, whichever kind of key this is
sub sign_data {
    my ($key, $data) = @_;
    return HTTPS::Handy::EC::sign($key, $data) if $key->{'type'} eq 'ec';
    return HTTPS::Handy::RSA::sign_pkcs1_sha256($key, $data);
}

# private_key_to_pem_any - PEM for either kind of key
sub private_key_to_pem_any {
    my ($key) = @_;
    return ec_private_key_to_pem($key) if $key->{'type'} eq 'ec';
    return private_key_to_pem($key);
}

# ----------------------------------------------------------------
# Building a self-signed certificate
# ----------------------------------------------------------------

# _utctime - Format a time stamp as YYMMDDHHMMSSZ in UTC
sub _utctime {
    my ($t) = @_;
    my @g = gmtime($t);
    return sprintf('%02d%02d%02d%02d%02d%02dZ',
                   $g[5] % 100, $g[4] + 1, $g[3], $g[2], $g[1], $g[0]);
}

# _name - An X.500 name holding a single common name
sub _name {
    my ($cn) = @_;
    return der_sequence(
        der_set(der_sequence(der_oid('2.5.4.3'), der_printable($cn))));
}

# _subject_alt_name - The extension browsers use to match the host name
sub _subject_alt_name {
    my (@host) = @_;
    my $names = '';
    for my $h (@host) {
        if ($h =~ /^\d+\.\d+\.\d+\.\d+$/) {
            # iPAddress [7]
            $names .= _der(0x87, pack('C4', split(/\./, $h)));
        }
        else {
            # dNSName [2]
            $names .= _der(0x82, $h);
        }
    }
    return der_sequence(der_oid('2.5.29.17'),
                        der_octetstring(der_sequence($names)));
}

# make_self_signed - Build a certificate and sign it with its own key
#
#   key      RSA key from HTTPS::Handy::RSA::generate_key
#   cn       common name, usually the host name
#   hosts    list of names or addresses for subjectAltName
#   days     validity in days
#
# Returns the certificate as DER.
sub make_self_signed {
    my (%opt) = @_;
    my $key   = $opt{'key'};
    my $cn    = defined $opt{'cn'} ? $opt{'cn'} : 'localhost';
    my $days  = defined $opt{'days'} ? $opt{'days'} : 3650;
    my @hosts = (defined $opt{'hosts'} && ref($opt{'hosts'}) eq 'ARRAY')
              ? @{ $opt{'hosts'} }
              : ($cn);

    my $now = time();
    my $serial = HTTPS::Handy::Crypt::random_bytes(8);
    substr($serial, 0, 1) = pack('C', unpack('C', substr($serial, 0, 1)) & 0x7F);

    my $sig_alg = signature_algorithm_der($key);

    my $extensions = der_context(3, der_sequence(
        # basicConstraints: not a certificate authority
        der_sequence(der_oid('2.5.29.19'), der_boolean(1),
                     der_octetstring(der_sequence())),
        # keyUsage: digitalSignature + keyEncipherment
        der_sequence(der_oid('2.5.29.15'), der_boolean(1),
                     der_octetstring(_der(0x03, "\x05\xA0"))),
        # extendedKeyUsage: TLS server authentication
        der_sequence(der_oid('2.5.29.37'),
                     der_octetstring(der_sequence(der_oid('1.3.6.1.5.5.7.3.1')))),
        _subject_alt_name(@hosts),
    ));

    my $tbs = der_sequence(
        der_context(0, der_integer("\x02")),      # version 3
        der_integer($serial),
        $sig_alg,
        _name($cn),                               # issuer (itself)
        der_sequence(der_utctime(_utctime($now - 86400)),
                     der_utctime(_utctime($now + $days * 86400))),
        _name($cn),                               # subject
        public_key_der($key),
        $extensions,
    );

    my $sig = sign_data($key, $tbs);
    return der_sequence($tbs, $sig_alg, der_bitstring($sig));
}

######################################################################
# HTTPS::Handy::RSA - Signing with an RSA key
######################################################################
# This module generates elliptic curve keys of its own, so the RSA
# code here exists for one purpose: to use an RSA certificate and key
# that somebody else issued, for instance from a certificate
# authority. Only the private operation is needed for that, which is
# raising the message to the power d modulo n. It is split with the
# Chinese Remainder Theorem, which works on numbers of half the size
# and is about four times faster.
#
# A key is a hash reference whose values are big integers as defined
# by HTTPS::Handy::BigInt:
#
#   n e d p q dp dq qinv   and   size (modulus length in bytes)
######################################################################

package HTTPS::Handy::RSA;

# ----------------------------------------------------------------
# The private operation
# ----------------------------------------------------------------

# private_op - m = c ** d mod n, computed with the CRT when possible
sub private_op {
    my ($key, $c) = @_;
    unless (defined $key->{'p'} && defined $key->{'dp'}) {
        return HTTPS::Handy::BigInt::b_modexp($c, $key->{'d'}, $key->{'n'});
    }
    my $m1 = HTTPS::Handy::BigInt::b_modexp(
                 HTTPS::Handy::BigInt::b_mod($c, $key->{'p'}),
                 $key->{'dp'}, $key->{'p'});
    my $m2 = HTTPS::Handy::BigInt::b_modexp(
                 HTTPS::Handy::BigInt::b_mod($c, $key->{'q'}),
                 $key->{'dq'}, $key->{'q'});
    # h = qinv * (m1 - m2) mod p ; m = m2 + h * q
    my $diff;
    if (HTTPS::Handy::BigInt::b_cmp($m1, $m2) >= 0) {
        $diff = HTTPS::Handy::BigInt::b_sub($m1, $m2);
    }
    else {
        my $t = HTTPS::Handy::BigInt::b_sub($m2, $m1);
        $t = HTTPS::Handy::BigInt::b_mod($t, $key->{'p'});
        $diff = HTTPS::Handy::BigInt::b_is_zero($t)
              ? $t
              : HTTPS::Handy::BigInt::b_sub($key->{'p'}, $t);
    }
    my $h = HTTPS::Handy::BigInt::b_mod(
                HTTPS::Handy::BigInt::b_mul($key->{'qinv'}, $diff),
                $key->{'p'});
    return HTTPS::Handy::BigInt::b_add($m2,
               HTTPS::Handy::BigInt::b_mul($h, $key->{'q'}));
}

# ----------------------------------------------------------------
# PKCS #1 v1.5 signatures (RFC 8017)
# ----------------------------------------------------------------
# The block that gets raised to the power d is
#
#   0x00 0x01 <0xFF padding> 0x00 <algorithm id and hash>
#
# so that it is as wide as the modulus and cannot be confused with
# any other value of the same length.
# ----------------------------------------------------------------

# DER prefix of DigestInfo for SHA-256, as required by RFC 8017
my $SHA256_DIGESTINFO = pack('H*', '3031300d060960864801650304020105000420');

# sign_pkcs1_sha256 - Sign data with the private key
sub sign_pkcs1_sha256 {
    my ($key, $data) = @_;
    my $k = $key->{'size'};
    my $t = $SHA256_DIGESTINFO . HTTPS::Handy::Crypt::sha256($data);
    my $block = "\x00\x01" . ("\xFF" x ($k - 3 - length($t))) . "\x00" . $t;
    my $s = private_op($key, HTTPS::Handy::BigInt::b_from_bin($block));
    return HTTPS::Handy::BigInt::b_to_bin($s, $k);
}

######################################################################
# HTTPS::Handy::BigInt - Multiple precision integer arithmetic
######################################################################
# Public key cryptography needs numbers far larger than a Perl scalar
# can hold exactly, so this package stores an integer as a reference to
# an array of 16 bit "limbs", least significant limb first:
#
#   65537  ->  [ 1, 1 ]          #  1 + 1 * 65536
#
# Only ordinary arithmetic (+ - * / %) is used, never bit operations.
# A 16 bit limb keeps every intermediate product below 2**53, which is
# the largest integer a floating point number represents exactly, so
# the same code gives identical results on 32 bit and 64 bit Perl, and
# on Perl 5.005_03 which has no 64 bit integers at all.
######################################################################

package HTTPS::Handy::BigInt;

# Limb base. Products of two limbs stay below 2**32, and the CIOS loop
# below adds at most two more limbs to such a product, so intermediate
# values never exceed 2**53.
my $BASE = 65536;

# ----------------------------------------------------------------
# Construction and conversion
# ----------------------------------------------------------------

# b_norm - Remove leading zero limbs (in place) and return the number
sub b_norm {
    my ($a) = @_;
    pop @$a while (scalar(@$a) > 1) && ($a->[-1] == 0);
    return $a;
}

# b_from_int - Convert a Perl integer (0 .. 2**48) to a big integer
sub b_from_int {
    my ($n) = @_;
    my @limb = ();
    $n = int($n);
    while ($n > 0) {
        push @limb, $n % $BASE;
        $n = int($n / $BASE);
    }
    push @limb, 0 unless @limb;
    return [ @limb ];
}

# b_to_int - Convert a small big integer back to a Perl integer
sub b_to_int {
    my ($a) = @_;
    my $n = 0;
    for (my $i = scalar(@$a) - 1; $i >= 0; $i--) {
        $n = $n * $BASE + $a->[$i];
    }
    return $n;
}

# b_copy - Duplicate a big integer
sub b_copy {
    my ($a) = @_;
    return [ @$a ];
}

# b_from_bin - Convert a big endian byte string to a big integer
sub b_from_bin {
    my ($bin) = @_;
    my @limb = ();
    my $len = length($bin);
    # Read the string from the right, two bytes at a time.
    for (my $i = $len; $i > 0; $i -= 2) {
        my $pair = ($i >= 2) ? substr($bin, $i - 2, 2) : ("\x00" . substr($bin, 0, 1));
        push @limb, unpack('n', $pair);
    }
    push @limb, 0 unless @limb;
    return b_norm([ @limb ]);
}

# b_to_bin - Convert a big integer to a big endian byte string
# With $want_len the result is zero padded (or truncated) to that length.
sub b_to_bin {
    my ($a, $want_len) = @_;
    my $bin = '';
    for (my $i = scalar(@$a) - 1; $i >= 0; $i--) {
        $bin .= pack('n', $a->[$i]);
    }
    $bin =~ s/^\x00+//;          # strip leading zero bytes
    $bin = "\x00" if $bin eq '';
    if (defined $want_len) {
        if (length($bin) < $want_len) {
            $bin = ("\x00" x ($want_len - length($bin))) . $bin;
        }
        elsif (length($bin) > $want_len) {
            $bin = substr($bin, length($bin) - $want_len);
        }
    }
    return $bin;
}

# b_from_hex - Convert a hexadecimal string to a big integer
sub b_from_hex {
    my ($hex) = @_;
    $hex =~ s/[^0-9A-Fa-f]//g;
    $hex = "0$hex" if length($hex) % 2;
    return b_from_bin(pack('H*', $hex));
}

# b_to_hex - Convert a big integer to a lower case hexadecimal string
sub b_to_hex {
    my ($a) = @_;
    return unpack('H*', b_to_bin($a));
}

# ----------------------------------------------------------------
# Tests and comparisons
# ----------------------------------------------------------------

sub b_is_zero {
    my ($a) = @_;
    return ((scalar(@$a) == 1) && ($a->[0] == 0)) ? 1 : 0;
}

sub b_is_odd {
    my ($a) = @_;
    return ($a->[0] % 2) ? 1 : 0;
}

# b_cmp - Return -1, 0 or 1 like the spaceship operator
sub b_cmp {
    my ($a, $b) = @_;
    my $la = scalar(@$a);
    my $lb = scalar(@$b);
    $la-- while ($la > 1) && ($a->[$la - 1] == 0);
    $lb-- while ($lb > 1) && ($b->[$lb - 1] == 0);
    return  1 if $la > $lb;
    return -1 if $la < $lb;
    for (my $i = $la - 1; $i >= 0; $i--) {
        return  1 if $a->[$i] > $b->[$i];
        return -1 if $a->[$i] < $b->[$i];
    }
    return 0;
}

# b_bits - Number of significant bits
sub b_bits {
    my ($a) = @_;
    my $top = scalar(@$a) - 1;
    $top-- while ($top > 0) && ($a->[$top] == 0);
    return 0 if ($top == 0) && ($a->[0] == 0);
    my $bits = $top * 16;
    my $v = $a->[$top];
    while ($v > 0) {
        $bits++;
        $v = int($v / 2);
    }
    return $bits;
}

# b_bit - Value (0 or 1) of bit number $n, counted from the bottom
sub b_bit {
    my ($a, $n) = @_;
    my $limb = int($n / 16);
    return 0 if $limb >= scalar(@$a);
    return int($a->[$limb] / (2 ** ($n % 16))) % 2;
}

# ----------------------------------------------------------------
# Addition, subtraction, multiplication
# ----------------------------------------------------------------

sub b_add {
    my ($a, $b) = @_;
    my @r = ();
    my $carry = 0;
    my $len = (scalar(@$a) > scalar(@$b)) ? scalar(@$a) : scalar(@$b);
    for (my $i = 0; $i < $len; $i++) {
        my $t = (defined $a->[$i] ? $a->[$i] : 0)
              + (defined $b->[$i] ? $b->[$i] : 0)
              + $carry;
        if ($t >= $BASE) {
            $r[$i] = $t - $BASE;
            $carry = 1;
        }
        else {
            $r[$i] = $t;
            $carry = 0;
        }
    }
    push @r, 1 if $carry;
    return b_norm([ @r ]);
}

# b_sub - Subtract $b from $a. The caller guarantees $a >= $b.
sub b_sub {
    my ($a, $b) = @_;
    my @r = ();
    my $borrow = 0;
    my $len = scalar(@$a);
    for (my $i = 0; $i < $len; $i++) {
        my $t = $a->[$i] - (defined $b->[$i] ? $b->[$i] : 0) - $borrow;
        if ($t < 0) {
            $r[$i] = $t + $BASE;
            $borrow = 1;
        }
        else {
            $r[$i] = $t;
            $borrow = 0;
        }
    }
    return b_norm([ @r ]);
}

sub b_mul {
    my ($a, $b) = @_;
    my $la = scalar(@$a);
    my $lb = scalar(@$b);
    my @r = (0) x ($la + $lb);
    for (my $i = 0; $i < $la; $i++) {
        my $ai = $a->[$i];
        next if $ai == 0;
        my $carry = 0;
        for (my $j = 0; $j < $lb; $j++) {
            my $t = $r[$i + $j] + $ai * $b->[$j] + $carry;
            $carry = int($t / $BASE);
            $r[$i + $j] = $t - $carry * $BASE;
        }
        my $k = $i + $lb;
        while ($carry > 0) {
            my $t = $r[$k] + $carry;
            $carry = int($t / $BASE);
            $r[$k] = $t - $carry * $BASE;
            $k++;
        }
    }
    return b_norm([ @r ]);
}

# b_shl1 - Double a number (shift left one bit)
sub b_shl1 {
    my ($a) = @_;
    my @r = ();
    my $carry = 0;
    for (my $i = 0; $i < scalar(@$a); $i++) {
        my $t = $a->[$i] * 2 + $carry;
        if ($t >= $BASE) {
            $r[$i] = $t - $BASE;
            $carry = 1;
        }
        else {
            $r[$i] = $t;
            $carry = 0;
        }
    }
    push @r, 1 if $carry;
    return b_norm([ @r ]);
}

# ----------------------------------------------------------------
# Division
# ----------------------------------------------------------------
# Plain shift and subtract long division in binary. It is not the
# fastest algorithm, but it is short enough to read, and the hot path
# of RSA uses Montgomery multiplication below, which needs no division
# at all.
# ----------------------------------------------------------------

sub b_divmod {
    my ($a, $b) = @_;
    die "HTTPS::Handy::BigInt: division by zero" if b_is_zero($b);
    return ([ 0 ], [ 0 ]) if b_is_zero($a);
    return ([ 0 ], b_copy($a)) if b_cmp($a, $b) < 0;

    my $bits = b_bits($a);
    my @q = (0) x scalar(@$a);
    my $r = [ 0 ];
    for (my $i = $bits - 1; $i >= 0; $i--) {
        $r = b_shl1($r);
        $r->[0] += b_bit($a, $i);
        if (b_cmp($r, $b) >= 0) {
            $r = b_sub($r, $b);
            $q[int($i / 16)] += 2 ** ($i % 16);
        }
    }
    return (b_norm([ @q ]), $r);
}

sub b_mod {
    my ($a, $b) = @_;
    my ($q, $r) = b_divmod($a, $b);
    return $r;
}

# ----------------------------------------------------------------
# Montgomery multiplication
# ----------------------------------------------------------------
# Montgomery arithmetic replaces the division in "multiply, then take
# the remainder" with a shift. Numbers are kept in "Montgomery form",
# that is multiplied by R = 65536 ** k (mod n), where k is the number
# of limbs of the modulus n. mont_mul(a, b) then computes
#
#   a * b * R ** -1  (mod n)
#
# so Montgomery form is preserved. n must be odd, which is always true
# for an RSA modulus and for the primes tested during key generation.
# ----------------------------------------------------------------

# _mont_n0inv - Compute (-n) ** -1 mod 65536 by Newton iteration
sub _mont_n0inv {
    my ($n) = @_;
    my $n0  = $n->[0];
    my $inv = 1;
    for (my $i = 0; $i < 5; $i++) {
        # inv <- inv * (2 - n0 * inv) mod 65536
        # The products reach 2 ** 32, so the remainder is taken by
        # subtracting a multiple rather than with the % operator,
        # which would have to cast them into a 32 bit integer first.
        my $p = $n0 * $inv;
        my $t = 2 - ($p - $BASE * int($p / $BASE));
        $t += $BASE while $t < 0;
        $p = $inv * $t;
        $inv = $p - $BASE * int($p / $BASE);
    }
    return ($BASE - $inv) - $BASE * int((($BASE - $inv)) / $BASE);
}

# b_mont_context - Everything the Montgomery routines need for a modulus
#
# The context is built once per modulus and then reused, which matters
# because the elliptic curve code below does tens of thousands of
# multiplications with the same prime.
sub b_mont_context {
    my ($n) = @_;
    my $k = scalar(@$n);
    my $ctx = {
        'n'     => $n,
        'k'     => $k,
        'n0inv' => _mont_n0inv($n),
    };
    # rr = R ** 2 mod n, by doubling 1 exactly 2 * k * 16 times
    my $rr = [ 1 ];
    for (my $i = 0; $i < 2 * $k * 16; $i++) {
        $rr = b_shl1($rr);
        $rr = b_sub($rr, $n) if b_cmp($rr, $n) >= 0;
    }
    $ctx->{'rr'}  = $rr;
    $ctx->{'one'} = b_mont_mul($ctx, [ 1 ], $rr);   # R mod n
    return $ctx;
}

# b_mont_mul - Montgomery product using the CIOS method
sub b_mont_mul {
    my ($ctx, $a, $b) = @_;
    my $n     = $ctx->{'n'};
    my $k     = $ctx->{'k'};
    my $n0inv = $ctx->{'n0inv'};
    my @t = (0) x ($k + 2);
    for (my $i = 0; $i < $k; $i++) {
        my $ai = (defined $a->[$i]) ? $a->[$i] : 0;
        my $carry = 0;
        my $t0;
        for (my $j = 0; $j < $k; $j++) {
            $t0 = $t[$j] + $ai * ((defined $b->[$j]) ? $b->[$j] : 0) + $carry;
            $carry = int($t0 / $BASE);
            $t[$j] = $t0 - $carry * $BASE;
        }
        $t0 = $t[$k] + $carry;
        $carry = int($t0 / $BASE);
        $t[$k] = $t0 - $carry * $BASE;
        $t[$k + 1] += $carry;

        # t[0] * n0inv reaches 2 ** 32, so again no % operator here
        my $mp = $t[0] * $n0inv;
        my $m = $mp - $BASE * int($mp / $BASE);
        $t0 = $t[0] + $m * $n->[0];
        $carry = int($t0 / $BASE);
        for (my $j = 1; $j < $k; $j++) {
            $t0 = $t[$j] + $m * $n->[$j] + $carry;
            $carry = int($t0 / $BASE);
            $t[$j - 1] = $t0 - $carry * $BASE;
        }
        $t0 = $t[$k] + $carry;
        $carry = int($t0 / $BASE);
        $t[$k - 1] = $t0 - $carry * $BASE;
        $t[$k] = $t[$k + 1] + $carry;
        $t[$k + 1] = 0;
    }
    my $r = b_norm([ @t[0 .. $k] ]);
    $r = b_sub($r, $n) if b_cmp($r, $n) >= 0;
    return $r;
}

# b_to_mont / b_from_mont - Move in and out of Montgomery form
sub b_to_mont {
    my ($ctx, $a) = @_;
    return b_mont_mul($ctx, b_mod($a, $ctx->{'n'}), $ctx->{'rr'});
}

sub b_from_mont {
    my ($ctx, $a) = @_;
    return b_mont_mul($ctx, $a, [ 1 ]);
}

# b_mont_pow - Exponentiation with the base already in Montgomery form
sub b_mont_pow {
    my ($ctx, $a, $e) = @_;
    my $r = $ctx->{'one'};
    for (my $i = b_bits($e) - 1; $i >= 0; $i--) {
        $r = b_mont_mul($ctx, $r, $r);
        $r = b_mont_mul($ctx, $r, $a) if b_bit($e, $i);
    }
    return $r;
}

# b_modexp - Modular exponentiation: $a ** $e mod $n
sub b_modexp {
    my ($a, $e, $n) = @_;
    return [ 0 ] if b_is_zero($n);
    return [ 1 ] if b_is_zero($e);
    if (!b_is_odd($n)) {
        # Even modulus: Montgomery does not apply, so fall back to the
        # slow but general square and multiply.
        my $r = [ 1 ];
        my $base = b_mod($a, $n);
        for (my $i = 0; $i < b_bits($e); $i++) {
            $r = b_mod(b_mul($r, $base), $n) if b_bit($e, $i);
            $base = b_mod(b_mul($base, $base), $n);
        }
        return $r;
    }
    my $ctx = b_mont_context($n);
    return b_from_mont($ctx, b_mont_pow($ctx, b_to_mont($ctx, $a), $e));
}

# ----------------------------------------------------------------
# Extended Euclid
# ----------------------------------------------------------------

# b_modinv - Modular inverse: find x with a * x = 1 (mod m)
# The signs of the Bezout coefficients are tracked by hand because
# these big integers are unsigned.
sub b_modinv {
    my ($a, $m) = @_;
    my $old_r = b_mod($a, $m);
    my $r     = b_copy($m);
    my $old_s = [ 1 ]; my $old_sign = 1;
    my $s     = [ 0 ]; my $sign     = 1;

    while (!b_is_zero($r)) {
        my ($q, $rem) = b_divmod($old_r, $r);
        $old_r = $r;
        $r     = $rem;
        # (old_s, s) <- (s, old_s - q * s) with explicit signs
        my $qs = b_mul($q, $s);
        my ($new, $new_sign);
        if ($old_sign == $sign) {
            if (b_cmp($old_s, $qs) >= 0) {
                $new = b_sub($old_s, $qs);
                $new_sign = $old_sign;
            }
            else {
                $new = b_sub($qs, $old_s);
                $new_sign = -$old_sign;
            }
        }
        else {
            $new = b_add($old_s, $qs);
            $new_sign = $old_sign;
        }
        $old_s = $s; $old_sign = $sign;
        $s = $new;   $sign = $new_sign;
    }
    return [ 0 ] if b_cmp($old_r, [ 1 ]) != 0;   # not invertible

    my $inv = b_mod($old_s, $m);
    $inv = b_sub($m, $inv) if ($old_sign < 0) && !b_is_zero($inv);
    return $inv;
}


# ----------------------------------------------------------------
# Back to main package -- demo/self-test when run directly
# ----------------------------------------------------------------
package HTTPS::Handy;

# Run as script: perl HTTPS::Handy.pm [port]
unless (caller) {
    my $port = $ARGV[0] || 8443;

    my $demo_app = sub {
        my $env = shift;
        my $method = $env->{REQUEST_METHOD};
        my $path   = $env->{PATH_INFO};
        my $query  = $env->{QUERY_STRING};

        # Route: GET /
        if ($method eq 'GET' && $path eq '/') {
            my $scheme  = $env->{'psgi.url_scheme'};
            my $cipher  = $env->{'psgix.tls_cipher'};
            # Reloading this page shows the second line change: the
            # first connection does the full handshake, the ones after
            # it resume the session and skip the curve arithmetic.
            my $shake   = $env->{'psgix.tls_resumed'}
                        ? 'resumed from the session cache'
                        : 'full, including the curve arithmetic';
            my $html = <<"HTML";
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>HTTPS::Handy Demo</title>
<style>
  body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
  h1 { color: #336699; }
  .secure { color: green; font-weight: bold; }
  code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; }
  form { margin: 20px 0; }
  input, textarea { display: block; margin: 8px 0; padding: 6px; width: 100%; box-sizing: border-box; }
  button { padding: 8px 20px; background: #336699; color: white; border: none; cursor: pointer; }
</style>
</head>
<body>
<h1>HTTPS::Handy Demo</h1>
<p class="secure">&#x1F512; Secure connection: $scheme</p>
<p>A tiny HTTPS/1.0 server for Perl 5.5.3 and later. Everything below
this page &mdash; the handshake, the certificate, the encryption &mdash;
is written in pure Perl in one file, with no other module and no
external program.</p>
<p>Cipher suite: <code>$cipher</code><br>
Handshake: <code>$shake</code> (reload this page and watch it change)</p>
<h2>GET with query string</h2>
<form method="get" action="/echo">
  <input type="text" name="message" placeholder="Type something...">
  <button type="submit">Send GET</button>
</form>
<h2>POST form</h2>
<form method="post" action="/echo">
  <input type="text" name="name" placeholder="Name">
  <textarea name="body" placeholder="Message" rows="3"></textarea>
  <button type="submit">Send POST</button>
</form>
<p><a href="/info">Server info</a></p>
</body>
</html>
HTML
            return HTTPS::Handy->response_html($html);
        }

        # Route: GET or POST /echo
        if ($path eq '/echo') {
            my %params;
            if ($method eq 'GET') {
                %params = HTTPS::Handy->parse_query($query);
            }
            elsif ($method eq 'POST') {
                my $body = '';
                $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0);
                %params = HTTPS::Handy->parse_query($body);
            }

            my $params_html = '';
            for my $key (sort keys %params) {
                my $val = $params{$key};
                $val = ref($val) eq 'ARRAY' ? join(', ', @$val) : $val;
                # simple HTML escape
                $val =~ s/&/&amp;/g;
                $val =~ s/</&lt;/g;
                $val =~ s/>/&gt;/g;
                $key =~ s/&/&amp;/g;
                $key =~ s/</&lt;/g;
                $params_html .= "<tr><td><b>$key</b></td><td>$val</td></tr>";
            }
            $params_html ||= '<tr><td colspan="2">(no parameters)</td></tr>';

            my $html = <<"HTML";
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Echo</title>
<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 20px}
table{border-collapse:collapse;width:100%}td{padding:6px 10px;border:1px solid #ccc}
</style></head>
<body>
<h1>Echo: $method $path</h1>
<table>$params_html</table>
<p><a href="/">Back</a></p>
</body></html>
HTML
            return HTTPS::Handy->response_html($html);
        }

        # Route: GET /info
        if ($method eq 'GET' && $path eq '/info') {
            my $env_html = '';
            for my $key (sort keys %$env) {
                next if $key eq 'psgi.input' || $key eq 'psgi.errors';
                my $val = $env->{$key};
                $val = '' unless defined $val;
                $val =~ s/&/&amp;/g;
                $val =~ s/</&lt;/g;
                $env_html .= "<tr><td><code>$key</code></td><td>$val</td></tr>";
            }
            my $html = <<"HTML";
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Server Info</title>
<style>body{font-family:sans-serif;max-width:700px;margin:40px auto;padding:0 20px}
table{border-collapse:collapse;width:100%}td{padding:4px 8px;border:1px solid #ddd;font-size:13px}
tr:nth-child(even){background:#f8f8f8}code{font-size:12px}
</style></head>
<body>
<h1>PSGI Environment</h1>
<table>$env_html</table>
<p><a href="/">Back</a></p>
</body></html>
HTML
            return HTTPS::Handy->response_html($html);
        }

        # 404 fallback
        return [404,
            ['Content-Type', 'text/html'],
            ["<h1>404 Not Found</h1><p>$path</p><a href='/'>Home</a>"]];
    };

    HTTPS::Handy->run(app => $demo_app, port => $port);
}

1;

__END__

=head1 NAME

HTTPS::Handy - A tiny HTTPS/1.0 server with TLS written in pure Perl

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

  use HTTPS::Handy;

  my $app = sub {
      my ($env) = @_;
      return [200,
          ['Content-Type', 'text/html; charset=utf-8'],
          ['<h1>Hello, HTTPS World!</h1>']];
  };

  # Starts on https://0.0.0.0:8443/ with a self-signed certificate
  # that the module generates by itself, in Perl, in about a second.
  HTTPS::Handy->run(app => $app);

  # With your own certificate
  HTTPS::Handy->run(
      app           => $app,
      port          => 8443,
      ssl_cert_file => 'server-cert.pem',
      ssl_key_file  => 'server-key.pem',
  );

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</REQUIREMENTS>

=item * L</DIFFERENCES FROM HTTP::HANDY>

=item * L</SUPPORTED PROTOCOL>

=item * L</HOW TLS IS IMPLEMENTED> -- the packages inside this file

=item * L</PSGI SUBSET SPECIFICATION> -- C<$env> keys, response format, psgi.input

=item * L</SERVER STARTUP> -- C<run()>, access log

=item * L</CERTIFICATES> -- how the certificate and key are found or made

=item * L</METHODS> -- C<serve_static>, C<url_decode>, C<parse_query>,
C<mime_type>, C<is_htmx>, and the C<response_*> builders

=item * L</SECURITY>

=item * L</PERFORMANCE>

=item * L</LIMITATIONS>

=item * L</DEMO>

=item * L</DIAGNOSTICS> -- error messages and runtime warnings

=item * L</BUGS AND LIMITATIONS>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

=head2 The shortest way in

  perl lib/HTTPS/Handy.pm

That starts a demonstration server. The first run spends about a second
making a key and a certificate, then prints the address to open. The
browser will warn that the certificate vouches for itself; say to
continue, and the page appears. Nothing had to be installed, and no
other program ran.

=head2 What it is

HTTPS::Handy is a small HTTPS/1.0 server for teaching, for reading, and
for local development. It speaks a subset of PSGI, so an application is
a single code reference that takes C<$env> and returns a three element
array reference.

What makes this version unusual is that the TLS layer is not borrowed
from anywhere. The whole of it -- big integer arithmetic, the P-256
elliptic curve, SHA-256, HMAC, the TLS pseudo random function,
ChaCha20-Poly1305, DER and PEM encoding, X.509 certificate generation,
the record layer and the handshake -- is written in Perl inside this
one file. The distribution contains no binary file, no XS code, and no
compiled component of any kind; the module loads nothing outside the
Perl core and runs no external program.

Two things follow from that, and they are the reason the module exists.

The first is that an ordinary browser opens the pages it serves. The
cipher suites here are the ones Chrome, Firefox, Safari and Edge still
accept: ECDHE for key agreement, ChaCha20-Poly1305 for the data, and
an ECDSA certificate. A lesson can therefore start with a real
C<https://> URL in a real browser rather than with a command line tool.

The second is that every step from the first byte of a ClientHello to
the HTML the browser displays can be read, printed out, and traced with
a print statement. Nothing is hidden behind a library.

If no certificate is supplied, the module generates an elliptic curve
key and a self-signed certificate itself, in about a second, and caches
them on disk. There is nothing to install and nothing to prepare.

=head1 REQUIREMENTS

  Perl     : 5.005_03 or later
  Modules  : Core only (IO::Socket, POSIX, Carp)
  Platform : Windows, UNIX/Linux, and anywhere else Perl runs
  External : Nothing. No OpenSSL, no certbot, no compiler.
  Clients  : Current browsers, curl, and openssl s_client

=head1 DIFFERENCES FROM HTTP::HANDY

=over 4

=item * Transport is HTTPS instead of HTTP.

=item * C<psgi.url_scheme> is C<"https"> instead of C<"http">.

=item * C<psgi.ssl> is set to C<1> in the PSGI environment.

=item * Default port is 8443 instead of 8080.

=item * A certificate and a private key are needed, and are generated
automatically when they are not supplied.

=back

The C<$env> keys, the response format, and every utility method are the
same in both modules, so an application written for one runs unchanged
on the other.

=head1 SUPPORTED PROTOCOL

=over 4

=item * HTTPS/1.0 only (no Keep-Alive)

=item * Methods: GET and POST only

=item * Connection is closed immediately after each response

=item * TLS 1.2 only

=item * Key agreement: ECDHE on the P-256 curve, which gives forward
secrecy

=item * Cipher suites:
C<TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256> (0xCCA9) with a
generated certificate, and
C<TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256> (0xCCA8) when the
supplied certificate holds an RSA key

=item * Certificates are signed with SHA-256

=item * Session resumption by session id, so that only the first
connection of a session pays for the public key arithmetic

=item * One certificate per server. The name a client asks for through
the Server Name Indication extension is not looked at.

=back

These are the suites current browsers still accept, which is the point:
C<https://localhost:8443/> opens in Chrome, Firefox, Safari and Edge, as
well as in C<curl> and C<openssl s_client>, with no special options on
either side. A self-signed certificate still produces the usual warning
page, where the visitor chooses to continue.

=head1 HOW TLS IS IMPLEMENTED

=head2 Where to start reading

The file holds eight packages, laid out in the order they are meant to
be read: each one uses the one below it, so reading downwards is
reading from the protocol towards the arithmetic.

  Package                 Lines   What it does
  ----------------------- ------- --------------------------------------
  HTTPS::Handy            923     the web server, and the demo at the end
  HTTPS::Handy::Input     109     an in memory handle for psgi.input
  HTTPS::Handy::TLS       896     the record layer and the handshake
  HTTPS::Handy::EC        332     the P-256 curve: ECDH and ECDSA
  HTTPS::Handy::ChaCha    211     ChaCha20-Poly1305, the record cipher
  HTTPS::Handy::Crypt     187     SHA-256, HMAC, the PRF, randomness
  HTTPS::Handy::X509      447     DER, PEM, self-signed certificates
  HTTPS::Handy::RSA       77      signing with a certificate from elsewhere
  HTTPS::Handy::BigInt    465     multiple precision integers

Comments and blank lines are counted too; about a third of each figure
is prose. A test in the distribution compares this table with the file,
so it cannot quietly go out of date.

The core is one subroutine: C<HTTPS::Handy::TLS::server_handshake>. It
is about a hundred and fifty lines and it contains the whole protocol.
Everything else in the file is a part it calls. A reader in a hurry
should read that one subroutine, then follow whichever part looks
interesting.

=head2 What a handshake does

  client -> ClientHello         which versions and ciphers it knows
  server -> ServerHello         the version and cipher it picked
  server -> Certificate         the server public key, signed
  server -> ServerKeyExchange   a one time curve point, signed
  server -> ServerHelloDone
  client -> ClientKeyExchange   its own one time curve point
  client -> ChangeCipherSpec    everything after this is encrypted
  client -> Finished            a hash of the whole handshake
  server -> ChangeCipherSpec
  server -> Finished

Each side multiplies its own secret number by the other side's point.
The two results are equal, neither side ever sends it, and nobody
watching can work it out. That shared value becomes the pre-master
secret; the PRF expands it into two keys and two nonces; and every
record after that is sealed with ChaCha20-Poly1305.

Because each side throws its secret number away when the connection
ends, traffic recorded today cannot be decrypted later even if the
server key is stolen afterwards. That property is called forward
secrecy.

=head2 Why these algorithms

Every choice here was made twice: once for what browsers accept, and
once for what fits in a file a student can read.

=over 4

=item * B<ECDHE on P-256> is the only key agreement current browsers
offer that this module could implement in a few hundred lines. It also
brings forward secrecy, which RSA key transport does not.

=item * B<ChaCha20-Poly1305> is the fastest AEAD to write in pure Perl:
ChaCha20 is nothing but 32 bit addition, exclusive or and rotation, and
Poly1305 is one multiplication modulo 2**130 - 5 per 16 bytes, which
the big integer package already provides. AES-GCM would need an S-box,
a key schedule and multiplication in GF(2**128), and would run slower.

=item * B<An ECDSA certificate> can be generated in about a second. An
RSA key of comparable strength takes minutes of pure Perl, because it
has to search for primes.

=back

=head1 PSGI SUBSET SPECIFICATION

PSGI is the agreed shape of a Perl web application: a subroutine that
takes one hash of request information and returns one array of response
information. Writing to that shape means the same application runs
under this module, under HTTP::Handy, and under a full server such as
Plack, unchanged. Only the part of PSGI described here is implemented.

=head2 Application Interface

A HTTPS::Handy application is a plain code reference that receives a request
environment hash and returns a three-element response arrayref:

  my $app = sub {
      my ($env) = @_;
      return [$status, \@headers, \@body];
  };

=head2 Request Environment -- C<$env>

The following keys are provided in the environment hashref passed to the app:

  Key                 Description
  ------------------  ----------------------------------------------
  REQUEST_METHOD      "GET" or "POST"
  PATH_INFO           URL path (e.g. "/index.html")
  QUERY_STRING        Query string ("key=val&..."), without leading "?"
  SERVER_NAME         Server hostname
  SERVER_PORT         Port number (integer)
  CONTENT_TYPE        Content-Type header of POST request
  CONTENT_LENGTH      Content-Length of POST body (integer)
  HTTP_*              Request headers, uppercased, hyphens as underscores
  psgi.input          Object with read() for the POST body (see below)
  psgi.errors         \*STDERR
  psgi.url_scheme     Always "https"
  psgi.ssl            Always 1 (indicates TLS is active)
  psgix.tls_cipher    Name of the cipher suite this connection uses
  psgix.tls_resumed   1 if the handshake was resumed, 0 if it was full

=head2 C<psgi.input> Object

The C<psgi.input> value is a C<HTTPS::Handy::Input> object. It provides:

  $env->{'psgi.input'}->read($buf, $length)   # read up to $length bytes
  $env->{'psgi.input'}->read($buf, $len, $off) # read with offset
  $env->{'psgi.input'}->seek($pos, $whence)   # reposition
  $env->{'psgi.input'}->tell()                # current position
  $env->{'psgi.input'}->getline()             # read one line
  $env->{'psgi.input'}->getlines()            # read all lines

This object works on Perl 5.5.3, which does not support
C<open my $fh, '<', \$scalar>.

=head2 The two C<psgix.> Keys

C<psgix.> is the conventional prefix for a key that a particular PSGI
server adds, and these two are here to be looked at rather than acted
on. C<psgix.tls_cipher> is the name of the cipher suite in use.
C<psgix.tls_resumed> is 0 on a connection that did the full handshake
and 1 on one that resumed a remembered session.

The demo page at C</info> prints the whole environment, so reloading it
shows C<psgix.tls_resumed> turning from 0 into 1 as the session cache
starts doing its work. That is the fastest way to see, rather than read
about, what session resumption is for.

=head2 Response Format

The application must return an arrayref of exactly three elements:

  [$status_code, \@headers, \@body]

=over 4

=item C<$status_code>

An integer HTTP status code (e.g. 200, 404, 500).

=item C<\@headers>

A flat arrayref of header name/value pairs, alternating:

  ['Content-Type', 'text/html', 'X-Custom', 'value']

=item C<\@body>

An arrayref of strings. All elements are joined and sent as the response body.

  ['<html>', '<body>Hello</body>', '</html>']

=back

Example:

  return [200,
      ['Content-Type', 'text/html; charset=utf-8'],
      ['<h1>Hello HTTPS::Handy</h1>']];

=head1 SERVER STARTUP

=head2 C<run(%args)>

Starts the HTTPS server. This call blocks indefinitely (until the
process is killed). In order, it

=over 4

=item 1.

finds a certificate and a private key, generating them if it must;

=item 2.

listens on a plain TCP socket;

=item 3.

for each connection in turn: runs the TLS handshake, reads one HTTP
request, calls the application, writes the response, and closes the
connection.

=back

One connection is handled at a time. The next client waits.

  HTTPS::Handy->run(
      app           => $app,     # required: PSGI app code reference
      host          => '127.0.0.1', # optional: bind address (default: 0.0.0.0)
      port          => 8443,     # optional: port number  (default: 8443)
      log           => 1,        # optional: messages to STDERR (default: 1)
      max_post_size => 10485760, # optional: max POST bytes (default: 10MB)

      # TLS certificate options
      ssl_cert_file => 'server-cert.pem',    # optional
      ssl_key_file  => 'server-key.pem',     # optional
      domains       => 'example.com',        # optional
      cert_dir      => '.https_handy_certs', # optional
  );

=over 4

=item C<log>

When true, which it is by default, this module writes to STDERR: the
two lines it prints at startup, one access log line per request, and a
line for each certificate step, failed handshake or application error.
When false it writes nothing at all, and an application that still
wants to record something can write to C<psgi.errors> itself.

=item C<ssl_cert_file> / C<ssl_key_file>

Paths to an existing TLS certificate and private key, in PEM form. When
both are given, no certificate is generated. The key may be an elliptic
curve key on the P-256 curve (C<BEGIN EC PRIVATE KEY>) or an RSA key
(C<BEGIN RSA PRIVATE KEY>), and either may arrive in the PKCS #8
wrapper that says C<BEGIN PRIVATE KEY>. An encrypted key is not
supported. The certificate file may hold a chain, and every certificate
in it is sent.

=item C<domains>

Host name, or an arrayref of host names, that this server answers for.
If a Let's Encrypt certificate for the first name is already installed
below F</etc/letsencrypt/live/>, it is used. Otherwise the names go into
the self-signed certificate that is generated instead.

=item C<cert_dir>

Directory for the generated certificate and key.
Default: F<.https_handy_certs>

=back

=head2 Access Log Format (LTSV)

When C<log> is enabled, each request is written to STDERR as a single
LTSV (Labeled Tab-separated Values) line:

  time:2026-01-01T12:00:00\tmethod:GET\tpath:/index.html\tstatus:200\tsize:1234\tua:Mozilla/5.0\treferer:

Fields:

  time      ISO 8601 local timestamp (YYYY-MM-DDTHH:MM:SS)
  method    HTTP method (GET or POST)
  path      Request path (PATH_INFO, without query string)
  status    HTTP status code
  size      Response body size in bytes
  ua        User-Agent header value (empty string if absent)
  referer   Referer header value (empty string if absent)

LTSV can be parsed line by line with C<split /\t/> and each field with
C<split /:/, $field, 2>. It is directly compatible with L<LTSV::LINQ>.

=head1 CERTIFICATES

=head2 How the certificate is chosen

=over 4

=item 1.

C<ssl_cert_file> and C<ssl_key_file>, when both are given.

=item 2.

An existing Let's Encrypt certificate for the first name in C<domains>,
when one is installed on this machine.

=item 3.

A self-signed certificate generated by this module and cached in
C<cert_dir> as F<selfsigned-cert.pem> and F<selfsigned-key.pem>. Later
runs find those files and start at once.

=back

=head2 The generated certificate

The certificate is a version 3 X.509 certificate holding a P-256 public
key, signed with ECDSA and SHA-256 by the matching private key. It is
valid for 397 days, because browsers refuse a certificate whose
lifetime is much longer than that. It carries the host name as the
common name and as a subjectAltName, together with C<localhost> and
C<127.0.0.1>, so that a browser matches it for local use.

Browsers still warn about it, because nothing vouches for it but
itself. In Chrome the warning is C<ERR_CERT_AUTHORITY_INVALID> and the
way past it is "Advanced", then "Proceed"; Firefox and Safari have the
same door under different labels. That warning is the only obstacle
between a class and a working C<https://> page.

=head2 Using a certificate from elsewhere

Certificates made by other tools work, as long as the key is a P-256
elliptic curve key or an RSA key, and the file is not encrypted. For
example:

  openssl ecparam -genkey -name prime256v1 -out server-key.pem
  openssl req -x509 -new -key server-key.pem -days 397 \
      -subj /CN=localhost -out server-cert.pem

The same files are then passed to C<ssl_cert_file> and
C<ssl_key_file>. Obtaining a certificate from a certificate authority
over ACME is not implemented here; it needs a client of its own.

=head1 METHODS

Everything below is called as a class method, with an arrow and the
module name in front:

  HTTPS::Handy->response_text('hello');

They are helpers for writing the application, and none of them touch
the network. C<run()>, which does, is described under
L</SERVER STARTUP> above.

=head2 C<serve_static($env, $docroot [, %opts])>

Serve a static file from C<$docroot> using C<PATH_INFO> as the file path.
Returns a complete PSGI response arrayref.

  my $res = HTTPS::Handy->serve_static($env, './htdocs');

  # With cache control (e.g. for htmx apps: cache JS/CSS, never cache HTML)
  my $res = HTTPS::Handy->serve_static($env, './htdocs', cache_max_age => 3600);

Options:

=over 4

=item C<cache_max_age>

Sets the C<Cache-Control> header.

  cache_max_age => 3600   # Cache-Control: public, max-age=3600
  cache_max_age => 0      # Cache-Control: no-cache
  (not specified)         # Cache-Control: no-cache  (default)

For htmx applications, setting a positive C<cache_max_age> for static assets
(CSS, JS, images) while leaving HTML fragments at the default C<no-cache>
prevents stale scripts from being reused after a partial page update.

=back

Behaviour:

=over 4

=item * MIME type is detected automatically from the file extension

=item * Supported types: html, htm, txt, css, js, json, xml, png, jpg,
jpeg, gif, ico, svg, pdf, zip, gz, ltsv, csv, tsv

=item * Directory access attempts to serve C<index.html>

=item * Returns 404 if the file does not exist

=item * Returns 403 if the file cannot be opened

=item * Path traversal (C<..>) is blocked with a 403 response

=back

=head2 C<url_decode($str)>

Decode a percent-encoded URL string. C<+> is decoded as a space.

  my $str = HTTPS::Handy->url_decode('hello+world%21');
  # returns: "hello world!"

=head2 C<parse_query($query_string)>

Parse a URL query string into a hash. When the same key appears more than
once, its value becomes an arrayref.

  my %p = HTTPS::Handy->parse_query('name=ina&tag=perl&tag=cpan');
  # $p{name} eq 'ina'
  # $p{tag}  is ['perl', 'cpan']

=head2 C<mime_type($ext)>

Return the MIME type string for a given file extension.
The leading dot is optional.

  HTTPS::Handy->mime_type('html');   # 'text/html; charset=utf-8'
  HTTPS::Handy->mime_type('.json');  # 'application/json'
  HTTPS::Handy->mime_type('xyz');    # 'application/octet-stream'

=head2 C<is_htmx($env)>

Returns 1 if the request was made by htmx (i.e. the C<HX-Request: true>
header is present), or 0 otherwise.

  if (HTTPS::Handy->is_htmx($env)) { ... }

=head2 C<response_redirect($location, [$code])>

Build a redirect response. Default status is 302.

  HTTPS::Handy->response_redirect('/new/path');
  HTTPS::Handy->response_redirect('/new/path', 301);

=head2 C<response_json($json_str, [$code])>

Build a JSON response. The caller must provide already-encoded JSON.

  HTTPS::Handy->response_json('{"ok":true}');
  HTTPS::Handy->response_json('{"error":"bad"}', 400);

=head2 C<response_html($html, [$code])>

Build an HTML response.

  HTTPS::Handy->response_html('<h1>Hello</h1>');

=head2 C<response_text($text, [$code])>

Build a plain text response.

  HTTPS::Handy->response_text('Hello, World!');

=head1 SECURITY

B<Do not use this module to protect anything of value.> It is written
to be read, and a cryptographic implementation that is easy to read is
not the same thing as one that is safe to rely on. Use it on a private
network, on a development machine, or in a classroom, and put a mature
server such as nginx or Apache in front of anything that matters.

The rest of this section says exactly what is weak about it, because a
list of specific weaknesses teaches more than a general warning does.

=over 4

=item * B<The implementation is not hardened.> Comparisons, the
authentication tag check and the curve arithmetic are written for
clarity, so they take different amounts of time for different inputs.
An attacker who can measure those times on the same network can learn
things a constant time implementation would hide.

=item * B<Randomness depends on the platform.> Keys, nonces and the
per signature value k come from F</dev/urandom> when it can be read.
Where it cannot -- on Windows, for instance -- the module falls back to
hashing the process id, the clock and C<rand>, which is far weaker. For
ECDSA that is worse than it sounds: two signatures made with the same k
give away the private key. Supply your own certificate on such systems
if the key matters.

=item * B<Self-signed certificates make browsers warn.> That warning is
correct: nothing vouches for the certificate. It is fine for local work
and wrong for the public internet.

=item * B<Certificates are not verified by the built-in client.> The
client side exists for the test suite, and it accepts whatever
certificate it is shown. It is not a general purpose TLS client.

=item * B<One process, one connection at a time.> A slow or hostile
client blocks every other client while it is connected.

=item * B<The session cache is in memory and not shared.> It holds at
most sixty-four sessions for an hour each, and it disappears when the
process does.

=back

On the other hand, the protocol itself is the current one: TLS 1.2 with
forward secrecy and an authenticated cipher. A record that is altered
in transit is refused rather than decrypted, and traffic recorded today
stays unreadable even if the server key is taken tomorrow.

=head1 PERFORMANCE

All cryptography here runs in Perl. On a current machine:

=over 4

=item * Generating the key and the self-signed certificate takes about
a second, once, and the result is cached in C<cert_dir>.

=item * A full handshake costs three elliptic curve multiplications,
which is between one and two seconds.

=item * A resumed handshake costs none of them and is effectively
instant. Since a browser opens several connections and makes several
requests per page, this is what makes a demonstration usable: the first
connection is slow and the rest are not.

=item * Bulk data goes through ChaCha20-Poly1305 at roughly two hundred
kilobytes per second. Pages of a few kilobytes are comfortable; large
downloads are not.

=item * Because HTTP/1.0 closes the connection after every response,
every request needs a new handshake, though a resumed one. Keeping
demonstration pages self-contained, with no external images or scripts,
makes them appear at once.

=back

=head1 LIMITATIONS

=over 4

=item * B<Single-process, single-thread.> Requests are handled one at a
time. Not suitable for production or for high load.

=item * B<One curve and one cipher.> P-256 and ChaCha20-Poly1305 only.
A client that offers neither cannot connect; every current browser
offers both.

=item * B<TLS 1.2 only.> TLS 1.3 is a different handshake and is not
implemented. Browsers fall back to 1.2 without complaint.

=item * B<No ALPN, no renegotiation, no client certificates, no OCSP,
no session tickets> (session ids only).

=item * B<No Server Name Indication.> One certificate is served to
every client, whatever host name was asked for.

=item * B<The built-in client does not resume sessions and does not
check certificates.> It exists for the test suite.

=item * B<No ACME client.> Certificates from a certificate authority
must be obtained by other means and passed in.

=item * B<POST body fully buffered.> The entire POST body is read into
memory before the application runs.

=item * B<No Keep-Alive.> Every request closes the connection.

=item * B<No cookie or session management> (implement in the
application layer).

=item * B<Headers a client sends more than once> keep only the last
value.

=back

None of this affects the application: it sees an ordinary PSGI
environment and returns an ordinary PSGI response, with the encryption
and the certificate entirely behind it.

=head1 DEMO

Run directly to start a self-contained demo server:

  perl lib/HTTPS/Handy.pm           # from the distribution directory
  perl lib/HTTPS/Handy.pm 9443      # on port 9443

The first run generates a key and a self-signed certificate and stores
them in F<.https_handy_certs>, which takes about a second; later runs
start at once. Then open C<https://localhost:8443/> (or the port you
specified) in a browser, and click past the certificate warning. The
demo provides three built-in pages:

=over 4

=item C</>

Top page with a GET query form and a POST form.

=item C</echo>

Echoes GET query parameters or POST form fields in a table.
Demonstrates C<parse_query> for both methods.

=item C</info>

Displays the full PSGI C<$env> hash for the current request, including
C<psgi.url_scheme> and C<psgi.ssl>.

=back

=head1 DIAGNOSTICS

=head2 Startup errors

=over 4

=item C<HTTPS::Handy-E<gt>run: 'app' is required>

C<run()> was called without an C<app> argument.

=item C<HTTPS::Handy-E<gt>run: 'app' must be a code reference>

The C<app> argument was not a code reference.

=item C<HTTPS::Handy-E<gt>run: 'port' must be a number>

The C<port> argument contained something other than digits.

=item C<HTTPS::Handy-E<gt>run: 'max_post_size' must be a number>

The C<max_post_size> argument contained something other than digits.

=item C<HTTPS::Handy: Cannot bind to E<lt>hostE<gt>:E<lt>portE<gt> - E<lt>reasonE<gt>>

The listening socket could not be created. The port may be in use, or
below 1024 without the privilege to bind it.

=item C<HTTPS::Handy: Cannot read certificate file E<lt>fileE<gt>: E<lt>reasonE<gt>>

C<ssl_cert_file> could not be opened.

=item C<HTTPS::Handy: No CERTIFICATE block found in E<lt>fileE<gt>>

The certificate file contains no C<-----BEGIN CERTIFICATE-----> block.
A DER file must be converted to PEM first.

=item C<HTTPS::Handy: Cannot read private key file E<lt>fileE<gt>: E<lt>reasonE<gt>>

C<ssl_key_file> could not be opened.

=item C<HTTPS::Handy: No PRIVATE KEY block found in E<lt>fileE<gt>>

The key file contains none of C<BEGIN EC PRIVATE KEY>,
C<BEGIN RSA PRIVATE KEY> or C<BEGIN PRIVATE KEY>.

=item C<HTTPS::Handy: E<lt>fileE<gt> is not a P-256 or RSA private key this module can read>

The key is encrypted, or it is on a curve other than P-256. Decrypt it,
or make a key this module understands, with

  openssl ec -in old-key.pem -out server-key.pem

=item C<HTTPS::Handy: Cannot write E<lt>fileE<gt>: E<lt>reasonE<gt>>

The generated certificate or key could not be saved. Check that
C<cert_dir> exists and is writable.

=back

=head2 Internal errors

These come from the cryptographic packages and indicate a bug or a
damaged key file rather than a configuration mistake.

=over 4

=item C<HTTPS::Handy::BigInt: division by zero>

A modulus of zero reached the arithmetic, which a valid key never does.

=back

=head2 Runtime messages (STDERR)

These are written only when the C<log> option is true, which is the
default.

=over 4

=item C<[TIMESTAMP] App error: MESSAGE>

The application died. A 500 response was sent.

=item C<[TIMESTAMP] Accept failed: MESSAGE>

C<accept> failed. The server continues.

=item C<[TIMESTAMP] TLS handshake failed: MESSAGE>

A client connected but the handshake did not finish. The connection is
closed and the server continues. MESSAGE is one of:

=over 4

=item C<not a TLS record (is the client speaking plain HTTP?)>

The first bytes were not a TLS record. Almost always an C<http://> URL
aimed at the HTTPS port.

=item C<client offered an older protocol than TLS 1.2>

The client is older than this module supports.

=item C<no cipher suite in common (this server speaks NAME over the P-256 curve)>

The client offered neither of the two suites here, or does not support
the P-256 curve.

=item C<the ClientHello was too short to read>

The first handshake message was truncated or malformed.

=item C<the client sent a curve point this server cannot read>

=item C<the client sent a point that is not on the P-256 curve>

The ClientKeyExchange did not hold a valid P-256 point. A correct
client does not do this.

=item C<client Finished did not verify>

The two sides did not arrive at the same keys, or the handshake was
tampered with in transit.

=item C<record failed its authentication tag>

An encrypted record was altered, reordered or replayed.

=item C<alert from peer: LEVEL/DESCRIPTION>

The client gave up and said why, in the numbers of RFC 5246 section 7.2.
The commonest is C<2/48>, which means the client would not accept the
certificate.

=back

=item C<[TIMESTAMP] Generating a P-256 key and a self-signed certificate for HOST ...>

No cached certificate was found in C<cert_dir>, so one is being made.
It takes about a second, and the next line appears when it is done.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests by e-mail to
E<lt>ina.cpan@gmail.comE<gt>.

When reporting a bug, please include:

=over 4

=item *

A minimal, self-contained test script that reproduces the problem.

=item *

The version of HTTPS::Handy:

  perl -MHTTPS::Handy -e 'print HTTPS::Handy->VERSION, "\n"'

=item *

Your Perl version:

  perl -V

=item *

Your operating system, and, for a handshake problem, the client you used
and the output of

  openssl s_client -connect localhost:8443 -tls1_2

=back

See L</LIMITATIONS> above for known design limitations.

=head1 SEE ALSO

=head2 Related Modules

L<HTTP::Handy> -- the plain-HTTP sibling of this module, by the same
author. HTTPS::Handy is HTTP::Handy plus TLS; the C<$env> hash, response
format, and all utility methods are identical.

L<IO::Socket::SSL> -- the usual way to add TLS to a Perl socket, backed
by OpenSSL. Faster, safer and far larger than the TLS layer here; the
right choice whenever the goal is to protect something rather than to
study the protocol.

L<Plack> -- a full-featured PSGI toolkit and server collection. Requires
Perl 5.8+. For production use or more demanding workloads, migrating from
HTTPS::Handy to Plack (with a reverse proxy such as nginx terminating TLS)
is straightforward.

=head2 Standards implemented here

RFC 5246 (TLS 1.2), RFC 8422 (elliptic curves in TLS), RFC 7905
(ChaCha20-Poly1305 in TLS), RFC 8439 (ChaCha20 and Poly1305), RFC 5746
(renegotiation indication, the empty extension only), RFC 8017
(PKCS #1 v1.5), RFC 5280 (X.509), SEC 1 (elliptic curve keys),
RFC 2104 (HMAC), RFC 4648 (Base64), FIPS 180-4 (SHA-256), FIPS 186-4
(the P-256 curve and ECDSA).

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
