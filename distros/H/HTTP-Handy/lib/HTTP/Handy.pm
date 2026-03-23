package HTTP::Handy;
######################################################################
#
# HTTP::Handy - A tiny HTTP/1.0 server for Perl 5.5.3+
#
# https://metacpan.org/dist/HTTP-Handy
#
# Copyright (c) 2026 INABA Hitoshi <ina@cpan.org>
######################################################################
#
# Compatible : Perl 5.005_03 and later
# Platform   : Windows and UNIX/Linux
#
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use IO::Socket;
use Carp qw(croak);
use vars qw($VERSION $ACCESS_LOG_FH $CURRENT_LOG_FILE);
$VERSION = '1.01';
$VERSION = $VERSION;
# $VERSION self-assignment suppresses "used only once" warning under strict.

###############################################################################
# Status text map
###############################################################################
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

###############################################################################
# MIME type map
###############################################################################
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

# Access log variables (package variables for testability; declared via use vars above)
$ACCESS_LOG_FH    = undef;
$CURRENT_LOG_FILE = '';

###############################################################################
# run - Start the server (blocking)
###############################################################################
sub run {
    my ($class, %args) = @_;

    my $app           = $args{app}           or croak "HTTP::Handy->run: 'app' is required";
    my $host          = defined $args{host}          ? $args{host}          : '0.0.0.0';
    my $port          = defined $args{port}          ? $args{port}          : 8080;
    my $log           = defined $args{log}           ? $args{log}           : 1;
    my $max_post_size = defined $args{max_post_size} ? $args{max_post_size} : $DEFAULT_MAX_POST_SIZE;

    ref($app) eq 'CODE' or croak "HTTP::Handy->run: 'app' must be a code reference";
    $port =~ /^\d+$/ or croak "HTTP::Handy->run: 'port' must be a number";
    $max_post_size =~ /^\d+$/ or croak "HTTP::Handy->run: 'max_post_size' must be a number";

    my $server = IO::Socket::INET->new(
        LocalAddr => $host,
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => 10,
        ReuseAddr => 1,
    );
    unless ($server) {
        croak "HTTP::Handy: Cannot bind to $host:$port - $@";
    }

    # Create Apache-like directories
    _init_directories();

    _log_message("HTTP::Handy $HTTP::Handy::VERSION started on http://$host:$port/") if $log;
    _log_message("Press Ctrl+C to stop.") if $log;

    while (1) {
        my $client = $server->accept;
        unless ($client) {
            _log_message("Accept failed: $!") if $log;
            next;
        }

        # Disable CRLF translation on Windows
        binmode $client;

        eval {
            _handle_connection($client, $app, $log, $max_post_size, $port);
        };
        if ($@) {
            _log_message("Error handling connection: $@") if $log;
        }

        close $client;
    }
}

###############################################################################
# _handle_connection - Parse request and dispatch to app
###############################################################################
sub _handle_connection {
    my ($client, $app, $log, $max_post_size, $server_port) = @_;

    # Read request line
    my $request_line = _read_line($client);
    return unless defined $request_line && $request_line ne '';

    $request_line =~ s/\r?\n$//;

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
        my $line = _read_line($client);
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

    my $content_length = $headers{'content-length'} || 0;
    $content_length = int($content_length);

    if ($content_length > $max_post_size) {
        _send_error($client, 413, 'Request Entity Too Large');
        return;
    }

    # Read POST body
    my $post_body = '';
    if ($method eq 'POST' && $content_length > 0) {
        read($client, $post_body, $content_length);
    }

    # Build psgi.input as an in-memory filehandle
    # For 5.5.3 compatibility, use a temp file approach via a simple object
    my $input = HTTP::Handy::Input->new($post_body);

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
        'psgi.url_scheme' => 'http',
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
        _log_message("App error: $err");
        _send_error($client, 500, 'Internal Server Error');
        return;
    }

    # Validate response
    unless (ref($response) eq 'ARRAY' && scalar(@$response) == 3) {
        _send_error($client, 500, 'Internal Server Error');
        return;
    }

    my ($status, $resp_headers, $body) = @$response;

    # Send response
    my $status_text = $STATUS_TEXT{$status} || 'Unknown';
    my $response_str = "HTTP/1.0 $status $status_text\r\n";
    $response_str .= "Connection: close\r\n";

    # Process response headers (flat array: key, value, key, value, ...)
    my @header_list;
    if (ref($resp_headers) eq 'ARRAY') {
        my @h = @$resp_headers;
        while (@h) {
            my $k = shift(@h) || '';
            my $v = shift(@h) || '';
            push @header_list, "$k: $v";
        }
    }
    $response_str .= join("\r\n", @header_list) . "\r\n" if @header_list;
    $response_str .= "\r\n";

    # Build body
    my $body_str = '';
    if (ref($body) eq 'ARRAY') {
        $body_str = join('', @$body) if @$body;
    }

    my $body_length = length($body_str);
    $response_str .= $body_str;

    print $client $response_str;

    # Access log in LTSV format.
    # Sanitize field values: LTSV forbids tab and newline characters in values.
    if ($log) {
        my $ts      = _iso_time();
        my $ua      = $headers{'user-agent'} || '';
        my $referer = $headers{'referer'}    || '';
        $ua      =~ s/[\t\n\r]/ /g;
        $referer =~ s/[\t\n\r]/ /g;
        my $line = join("\t",
            "time:$ts",
            "method:$method",
            "path:$path",
            "status:$status",
            "size:$body_length",
            "ua:$ua",
            "referer:$referer",
        ) . "\n";
        print STDERR $line;

        _open_access_log();
        print $ACCESS_LOG_FH $line if $ACCESS_LOG_FH;
    }
}

###############################################################################
# _read_line - Read one line from socket (CR+LF or LF terminated)
###############################################################################
sub _read_line {
    my ($fh) = @_;
    my $line = '';
    my $char;
    while (read($fh, $char, 1)) {
        $line .= $char;
        last if $char eq "\n";
        # Safety limit: no header line should exceed 8KB
        return undef if length($line) > 8192;
    }
    return $line eq '' ? undef : $line;
}

###############################################################################
# _send_error - Send a simple HTTP error response
###############################################################################
sub _send_error {
    my ($client, $code, $message) = @_;
    my $text = $STATUS_TEXT{$code} || $message;
    my $body = "<html><head><title>$code $text</title></head>"
             . "<body><h1>$code $text</h1><p>$message</p>"
             . "<hr><small>HTTP::Handy/$HTTP::Handy::VERSION</small></body></html>";
    print $client "HTTP/1.0 $code $text\r\n";
    print $client "Content-Type: text/html\r\n";
    print $client "Content-Length: " . length($body) . "\r\n";
    print $client "Connection: close\r\n";
    print $client "\r\n";
    print $client $body;
}

###############################################################################
# _log_message - Print timestamped log to STDERR
###############################################################################
sub _log_message {
    my ($msg) = @_;

    my $ts = _iso_time();
    print STDERR "[$ts] $msg\n";

    my $fh;
    if ($] >= 5.006) {
        # Avoid "Too many arguments for open at" error when running with Perl 5.005_03
        eval q{ open($fh, '>>', 'logs/error/error.log') } or return;
    }
    else {
        $fh = \do { local *_ };
        open($fh, ">> logs/error/error.log") or return;
    }
    binmode $fh;

    print $fh "[$ts] $msg\n";
    close $fh;
}

###############################################################################
# serve_static - Serve files from a document root
###############################################################################
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
    my $fh;
    if ($] >= 5.006) {
        # Avoid "Too many arguments for open at" error when running with Perl 5.005_03
        unless (eval q{ open($fh, '<', $file) }) {
            return [403, ['Content-Type', 'text/plain'], ['Forbidden']];
        }
    }
    else {
        $fh = \do { local *_ };
        unless (open($fh, "<$file")) {
            return [403, ['Content-Type', 'text/plain'], ['Forbidden']];
        }
    }
    binmode $fh;
    local $/;
    my $content = <$fh>;
    close $fh;

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

###############################################################################
# url_decode - Decode percent-encoded string
###############################################################################
sub url_decode {
    my ($class, $str) = @_;
    return '' unless defined $str;
    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $str;
}

###############################################################################
# parse_query - Parse query string into hash
###############################################################################
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

###############################################################################
# mime_type - Return MIME type for a file extension
###############################################################################
sub mime_type {
    my ($class, $ext) = @_;
    $ext = lc $ext;
    $ext =~ s/^\.//;
    return $MIME{$ext} || 'application/octet-stream';
}

###############################################################################
# is_htmx - Return true if the request was made by htmx
###############################################################################
sub is_htmx {
    my ($class, $env) = @_;
    return (defined $env->{HTTP_HX_REQUEST} && $env->{HTTP_HX_REQUEST} eq 'true') ? 1 : 0;
}

###############################################################################
# response_redirect - Build a redirect response
###############################################################################
sub response_redirect {
    my ($class, $location, $code) = @_;
    $code ||= 302;
    return [$code,
        ['Location',     $location,
         'Content-Type', 'text/plain'],
        ["Redirect to $location"]];
}

###############################################################################
# response_json - Build a JSON response (no JSON encoding, caller provides)
###############################################################################
sub response_json {
    my ($class, $json_str, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'application/json',
         'Content-Length', length($json_str)],
        [$json_str]];
}

###############################################################################
# response_html - Build an HTML response
###############################################################################
sub response_html {
    my ($class, $html, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'text/html; charset=utf-8',
         'Content-Length', length($html)],
        [$html]];
}

###############################################################################
# response_text - Build a plain text response
###############################################################################
sub response_text {
    my ($class, $text, $code) = @_;
    $code ||= 200;
    return [$code,
        ['Content-Type',   'text/plain; charset=utf-8',
         'Content-Length', length($text)],
        [$text]];
}

###############################################################################
# _init_directories - Create Apache-like directories
###############################################################################
sub _init_directories {
    for my $dir (qw(
        logs
        logs/access
        logs/error
        run
        htdocs
        conf
    )) {
        mkdir($dir, 0777) unless -d $dir;
    }
}

###############################################################################
# _open_access_log - Opens the access log file (YYYYMMDDHHm0.log.ltsv format)
###############################################################################
sub _open_access_log {
    my ($year, $month, $day, $hour, $min) = (localtime)[5, 4, 3, 2, 1];
    my $current_log_filename = sprintf("logs/access/%04d%02d%02d%02d%02d.log.ltsv",
        1900 + $year,
        $month + 1,
        $day,
        $hour,
        int($min / 10) * 10,
    );

    return if defined $ACCESS_LOG_FH && $current_log_filename eq $CURRENT_LOG_FILE;

    if ($ACCESS_LOG_FH) {
        close $ACCESS_LOG_FH;
    }

    my $fh;
    if ($] >= 5.006) {
        # Avoid "Too many arguments for open at" error when running with Perl 5.005_03
        eval q{ open($fh, '>>', $current_log_filename) } or do {
            warn "Cannot open access log: $current_log_filename: $!";
            return;
        };
    }
    else {
        $fh = \do { local *_ };
        open($fh, ">> $current_log_filename") or do {
            warn "Cannot open access log: $current_log_filename: $!";
            return;
        };
    }
    binmode $fh;

    select((select($fh), $| = 1)[0]); # autoflush

    $ACCESS_LOG_FH     = $fh;
    $CURRENT_LOG_FILE  = $current_log_filename;
}

###############################################################################
# _iso_time - Returns localtime as ISO style (YYYY-MM-DDTHH:mm:SS)
###############################################################################
sub _iso_time {
    my ($year, $month, $day, $hour, $min, $sec) = (localtime)[5, 4, 3, 2, 1, 0];
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
        1900 + $year,
        $month + 1,
        $day,
        $hour,
        $min,
        $sec,
    );
}

# ----------------------------------------------------------------
# HTTP::Handy::Input - Minimal in-memory filehandle for psgi.input
# Compatible with Perl 5.5.3 (no open with scalar ref)
# ----------------------------------------------------------------
package HTTP::Handy::Input;

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
    # Write into $_[1] at $offset (like POSIX read)
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

###############################################################################
# Back to main package -- demo/self-test when run directly
###############################################################################
package HTTP::Handy;

# Run as script: perl lib/HTTP/Handy.pm [port]
unless (caller) {
    my $port = $ARGV[0] || 8080;

    my $demo_app = sub {
        my $env = shift;
        my $method = $env->{REQUEST_METHOD};
        my $path   = $env->{PATH_INFO};
        my $query  = $env->{QUERY_STRING};

        # Route: GET /
        if ($method eq 'GET' && $path eq '/') {
            my $html = <<'HTML';
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>HTTP::Handy Demo</title>
<style>
  body { font-family: sans-serif; max-width: 600px; margin: 40px auto; padding: 0 20px; }
  h1 { color: #336699; }
  code { background: #f0f0f0; padding: 2px 6px; border-radius: 3px; }
  form { margin: 20px 0; }
  input, textarea { display: block; margin: 8px 0; padding: 6px; width: 100%; box-sizing: border-box; }
  button { padding: 8px 20px; background: #336699; color: white; border: none; cursor: pointer; }
</style>
</head>
<body>
<h1>HTTP::Handy Demo</h1>
<p>A tiny HTTP/1.0 server running on Perl 5.5.3+.</p>
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
            return HTTP::Handy->response_html($html);
        }

        # Route: GET or POST /echo
        if ($path eq '/echo') {
            my %params;
            if ($method eq 'GET') {
                %params = HTTP::Handy->parse_query($query);
            }
            elsif ($method eq 'POST') {
                my $body = '';
                $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0);
                %params = HTTP::Handy->parse_query($body);
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
            return HTTP::Handy->response_html($html);
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
            return HTTP::Handy->response_html($html);
        }

        # 404 fallback
        return [404,
            ['Content-Type', 'text/html'],
            ["<h1>404 Not Found</h1><p>$path</p><a href='/'>Home</a>"]];
    };

    HTTP::Handy->run(app => $demo_app, port => $port);
}

1;

__END__

=head1 NAME

HTTP::Handy - A tiny HTTP/1.0 server for Perl 5.5.3 and later

=head1 VERSION

1.01

=head1 SYNOPSIS

  use HTTP::Handy;

  my $app = sub {
      my $env = shift;
      return [200, ['Content-Type', 'text/plain'], ['Hello, World!']];
  };

  HTTP::Handy->run(app => $app, port => 8080);

=head1 DESCRIPTION

HTTP::Handy is a single-file, zero-dependency HTTP/1.0 server for Perl.
It implements a subset of the PSGI specification and is designed for
personal use, local tools, and rapid development.

The goals of the project are simplicity and portability. The entire
implementation fits in one file with no installation step beyond copying
it into your project directory.

=head2 What is PSGI?

B<PSGI> (Perl Web Server Gateway Interface) is a standard interface between
Perl web applications and web servers, inspired by Python's WSGI and Ruby's
Rack.  A PSGI application is a plain code reference:

  my $app = sub {
      my $env = shift;          # request environment hashref
      # ... process the request ...
      return [$status, \@headers, \@body];   # response arrayref
  };

Because the interface is a simple data structure (hashref in, arrayref out),
PSGI applications are portable across any PSGI-compatible server -- from the
minimal HTTP::Handy to the full-featured Plack toolkit.

Official PSGI specification:
  https://github.com/plack/psgi-specs/blob/master/PSGI.pod

PSGI on MetaCPAN:
  https://metacpan.org/pod/PSGI

=head1 INCLUDED DOCUMENTATION

The C<eg/> directory contains sample programs demonstrating PSGI features:

  eg/01_hello_world.pl     Minimal app: routing, query string, env dump
  eg/02_static_files.pl    serve_static, cache_max_age, mime_type
  eg/03_form_post.pl       POST body, parse_query, multi-value fields,
                           Post-Redirect-Get pattern
  eg/04_ltsv_viewer.pl     is_htmx, LTSV log parsing, multiple status codes

The C<doc/> directory contains PSGI cheat sheets in 21 languages:

  doc/psgi_cheatsheet.EN.txt   English
  doc/psgi_cheatsheet.JA.txt   Japanese
  doc/psgi_cheatsheet.ZH.txt   Chinese (Simplified)
  doc/psgi_cheatsheet.TW.txt   Chinese (Traditional)
  doc/psgi_cheatsheet.KO.txt   Korean
  doc/psgi_cheatsheet.FR.txt   French
  doc/psgi_cheatsheet.ID.txt   Indonesian
  doc/psgi_cheatsheet.VI.txt   Vietnamese
  doc/psgi_cheatsheet.TH.txt   Thai
  doc/psgi_cheatsheet.HI.txt   Hindi
  doc/psgi_cheatsheet.BN.txt   Bengali
  doc/psgi_cheatsheet.TR.txt   Turkish
  doc/psgi_cheatsheet.MY.txt   Malay
  doc/psgi_cheatsheet.TL.txt   Filipino
  doc/psgi_cheatsheet.KM.txt   Khmer
  doc/psgi_cheatsheet.MN.txt   Mongolian
  doc/psgi_cheatsheet.NE.txt   Nepali
  doc/psgi_cheatsheet.SI.txt   Sinhala
  doc/psgi_cheatsheet.UR.txt   Urdu
  doc/psgi_cheatsheet.UZ.txt   Uzbek
  doc/psgi_cheatsheet.BM.txt   Burmese

Each cheat sheet covers: starting the server, C<$env> keys, response
format, reading the POST body, utility methods, response builders,
static files, routing patterns, error handling, log files, and links
to the official PSGI specification.

=head1 REQUIREMENTS

  Perl     : 5.5.3 or later -- all versions, all platforms
  OS       : Any (Windows, Unix, macOS, and others)
  Modules  : Core only -- IO::Socket, Carp
  Model    : Single process, single thread

No CPAN modules are required. No C compiler or external library is needed.

=head1 SUPPORTED PROTOCOL

=over 4

=item * HTTP/1.0 only (no Keep-Alive)

=item * Methods: GET and POST only

=item * Connection is closed immediately after each response

=back

=head1 PSGI SUBSET SPECIFICATION

=head2 Application Interface

A HTTP::Handy application is a plain code reference that receives a request
environment hash and returns a three-element response arrayref:

  my $app = sub {
      my ($env) = @_;
      return [$status, \@headers, \@body];
  };

=head2 Request Environment -- C<$env>

The following keys are provided in the environment hashref passed to the app:

  Key               Description
  ----------------  ------------------------------------------------
  REQUEST_METHOD    "GET" or "POST"
  PATH_INFO         URL path (e.g. "/index.html")
  QUERY_STRING      Query string ("key=val&..."), without leading "?"
  SERVER_NAME       Server hostname
  SERVER_PORT       Port number (integer)
  CONTENT_TYPE      Content-Type header of POST request
  CONTENT_LENGTH    Content-Length of POST body (integer)
  HTTP_*            Request headers, uppercased, hyphens as underscores
  psgi.input        Object with read() for the POST body (see below)
  psgi.errors       \*STDERR
  psgi.url_scheme   Always "http"

=head2 C<psgi.input> Object

The C<psgi.input> value is a C<HTTP::Handy::Input> object. It provides:

  $env->{'psgi.input'}->read($buf, $length)   # read up to $length bytes
  $env->{'psgi.input'}->read($buf, $len, $off) # read with offset
  $env->{'psgi.input'}->seek($pos, $whence)   # reposition
  $env->{'psgi.input'}->tell()                # current position
  $env->{'psgi.input'}->getline()             # read one line
  $env->{'psgi.input'}->getlines()            # read all lines

This object works on Perl 5.5.3, which does not support
C<open my $fh, '<', \$scalar>.

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
      ['<h1>Hello HTTP::Handy</h1>']];

=head1 SERVER STARTUP

=head2 C<run(%args)>

Starts the HTTP server. This call blocks indefinitely (until the process
is killed).

  HTTP::Handy->run(
      app           => $app,     # required: PSGI app code reference
      host          => '127.0.0.1', # optional: bind address (default: 0.0.0.0)
      port          => 8080,     # optional: port number  (default: 8080)
      log           => 1,        # optional: access log to STDERR (default: 1)
      max_post_size => 10485760, # optional: max POST bytes (default: 10MB)
  );

C<max_post_size> controls how large a POST body the server will accept.
Requests exceeding this limit receive a 413 response. The value is in bytes.

  # Accept POST bodies up to 50 MB (e.g. for LTSV log file uploads)
  HTTP::Handy->run(app => $app, port => 8080, max_post_size => 50 * 1024 * 1024);

=head2 Directory Initialisation

C<run()> automatically creates an Apache-like directory structure under the
current working directory if the directories do not already exist:

  logs/          parent directory for all log files
  logs/access/   access logs (LTSV format, 10-minute rotation)
  logs/error/    error log
  run/           PID files and other runtime files
  htdocs/        suggested document root for serve_static
  conf/          configuration files

=head2 Access Log Format (LTSV)

When C<log> is enabled, each request is written both to STDERR and to a
rotating LTSV file under C<logs/access/>.

File naming: C<logs/access/YYYYMMDDHHm0.log.ltsv> where C<m0> is the
10-minute interval (00, 10, 20, 30, 40, or 50). The file is rotated
automatically when the interval changes.

Each log line is a single LTSV record:

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

=head2 Error Log

Server startup messages and application errors are written both to STDERR
and to C<logs/error/error.log>. Each line is prefixed with an ISO 8601
timestamp in brackets:

  [2026-01-01T12:00:00] HTTP::Handy 1.01 started on http://0.0.0.0:8080/

=head1 METHODS

=head2 C<serve_static($env, $docroot [, %opts])>

Serve a static file from C<$docroot> using C<PATH_INFO> as the file path.
Returns a complete PSGI response arrayref.

  my $res = HTTP::Handy->serve_static($env, './htdocs');

  # With cache control (e.g. for htmx apps: cache JS/CSS, never cache HTML)
  my $res = HTTP::Handy->serve_static($env, './htdocs', cache_max_age => 3600);

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

  my $str = HTTP::Handy->url_decode('hello+world%21');
  # returns: "hello world!"

=head2 C<parse_query($query_string)>

Parse a URL query string into a hash. When the same key appears more than
once, its value becomes an arrayref.

  my %p = HTTP::Handy->parse_query('name=ina&tag=perl&tag=cpan');
  # $p{name} eq 'ina'
  # $p{tag}  is ['perl', 'cpan']

=head2 C<mime_type($ext)>

Return the MIME type string for a given file extension.
The leading dot is optional.

  HTTP::Handy->mime_type('html');   # 'text/html; charset=utf-8'
  HTTP::Handy->mime_type('.json');  # 'application/json'
  HTTP::Handy->mime_type('xyz');    # 'application/octet-stream'

=head2 C<is_htmx($env)>

Returns 1 if the request was made by htmx (i.e. the C<HX-Request: true>
header is present), or 0 otherwise.

  if (HTTP::Handy->is_htmx($env)) {
      # Return an HTML fragment only
      return HTTP::Handy->response_html($fragment);
  } else {
      # Return the full page for direct browser access
      return HTTP::Handy->response_html($full_page);
  }

htmx sets C<HX-Request: true> on all requests it initiates (C<hx-get>,
C<hx-post>, etc.), making this the standard way to distinguish partial
updates from full page loads.

=head2 C<response_html($html [, $code])>

Build an HTML response. Sets C<Content-Type> to C<text/html; charset=utf-8>
and C<Content-Length> automatically. Default status is 200.

  return HTTP::Handy->response_html('<h1>Hello</h1>');
  return HTTP::Handy->response_html('<h1>Created</h1>', 201);

=head2 C<response_text($text [, $code])>

Build a plain text response. Sets C<Content-Type> to
C<text/plain; charset=utf-8>. Default status is 200.

  return HTTP::Handy->response_text('Hello, World!');

=head2 C<response_json($json_str [, $code])>

Build a JSON response. Sets C<Content-Type> to C<application/json>.
The caller is responsible for encoding the JSON string.
Default status is 200.

  use mb::JSON;  # or any JSON encoder that works with Perl 5.5.3
  return HTTP::Handy->response_json(encode_json(\%data));

=head2 C<response_redirect($location [, $code])>

Build a redirect response with a C<Location> header.
Default status is 302.

  return HTTP::Handy->response_redirect('/new/path');
  return HTTP::Handy->response_redirect('https://example.com/', 301);

=head1 ERROR HANDLING

=over 4

=item * If the application C<die>s, a 500 response is sent to the client
and the error message is printed to STDERR. The server continues running.

=item * An unsupported HTTP method returns a 405 response.

=item * A POST body exceeding C<max_post_size> (default 10 MB) returns a 413 response.

=item * Socket errors are printed to STDERR and the server continues
to the next request.

=back

=head1 STATIC FILES, CGI, AND HTMX

HTTP::Handy can serve static files and handle dynamic routes in the same
application, making it self-contained with no external web server needed.

  my $app = sub {
      my $env = shift;
      my $path = $env->{PATH_INFO};

      # Dynamic API route (used as HTMX target)
      if ($path =~ m{^/api/}) {
          my $html_fragment = compute_fragment($env);
          return HTTP::Handy->response_html($html_fragment);
      }

      # Static files (HTML, CSS, JS)
      return HTTP::Handy->serve_static($env, './htdocs');
  };

When used with HTMX, the server simply returns HTML fragments for
C<hx-get> / C<hx-post> requests. No special support is required.

Reading POST body (equivalent to CGI's C<STDIN>):

  my $body = '';
  $env->{'psgi.input'}->read($body, $env->{CONTENT_LENGTH} || 0);
  my %post = HTTP::Handy->parse_query($body);

=head1 HTTPS

HTTP::Handy does not support HTTPS. TLS requires C<IO::Socket::SSL> and
OpenSSL, which depend on Perl 5.8+ and external C libraries.

For local personal use, this is not a problem: modern browsers treat
C<127.0.0.1> and C<localhost> as secure contexts and do not show
HTTPS warnings for HTTP on these addresses.

For LAN or internet use, place a reverse proxy in front of HTTP::Handy:

  Browser <--HTTPS--> Caddy / nginx / Apache <--HTTP--> HTTP::Handy

A minimal Caddy configuration:

  localhost {
      reverse_proxy 127.0.0.1:8080
  }

=head1 PSGI COMPATIBILITY NOTES

HTTP::Handy implements a strict I<subset> of the PSGI/1.1 specification.
The following keys defined by the PSGI spec are B<not> set in C<$env>:

  psgi.version        (PSGI requires [1,1]; not set)
  psgi.multithread    (not set; effectively false)
  psgi.multiprocess   (not set; effectively false)
  psgi.run_once       (not set; effectively false)
  psgi.nonblocking    (not set; always blocking)
  psgi.streaming      (not set; not supported)

Applications that check for these keys must treat their absence as false.
For full PSGI/1.1 compliance use L<Plack> (requires Perl 5.8+).

=head1 SECURITY

HTTP::Handy is designed for B<personal use and local development only>.
It is not hardened for production or internet-facing deployment.

=over 4

=item * B<No authentication or access control.>
Any client that can reach the listening port has unrestricted access.

=item * B<No rate limiting or DoS protection.>
A slow or malicious client can occupy the single-threaded server indefinitely.

=item * B<No HTTPS.>
All traffic is transmitted in plaintext (see L</HTTPS>).

=item * B<POST body capped at 10 MB by default.>
Requests exceeding C<max_post_size> receive a 413 response, but there is no
timeout on slow uploads.

=back

Recommended practice: bind to C<127.0.0.1> (loopback only) and place a
hardened reverse proxy in front of HTTP::Handy for any LAN or internet use.

=head1 LIMITATIONS

=over 4

=item * HTTP/1.0 only -- no Keep-Alive, no HTTP/1.1, no HTTP/2

=item * GET and POST only -- HEAD, PUT, DELETE, etc. return 405

=item * Single process, single thread -- requests are handled one at a time

=item * No HTTPS (see above)

=item * No chunked transfer encoding

=item * No streaming -- POST body and response body are fully buffered in memory

=item * Maximum POST body size: 10 MB by default (configurable via C<max_post_size>)

=item * No cookie or session management (implement in the application layer)

=back

=head1 DEMO

Run directly to start a self-contained demo server:

  perl lib/HTTP/Handy.pm           # from the distribution directory
  perl lib/HTTP/Handy.pm 9090      # on port 9090

Then open C<http://localhost:8080/> (or the port you specified) in your
browser. The demo provides three built-in pages:

=over 4

=item C</>

Top page with a GET query form and a POST form.

=item C</echo>

Echoes GET query parameters or POST form fields in a table.
Demonstrates C<parse_query> for both methods.

=item C</info>

Displays the full PSGI C<$env> hash for the current request.
Useful for understanding what HTTP::Handy provides to the application,
and for debugging routing logic.

=back

To start a minimal server after installation via C<cpan> or C<make install>:

  perl -MHTTP::Handy -e 'HTTP::Handy->run(app=>sub{[200,[],["ok"]]})'

=head1 INTERNALS -- HTTP::Handy::Input

C<HTTP::Handy::Input> is a lightweight in-memory object that acts as a
readable filehandle. It is used as the value of C<psgi.input> in the
request environment.

The reason for a custom object rather than a real filehandle is
compatibility with Perl 5.5.3: the convenient idiom
C<open my $fh, 'E<lt>', \$scalar> (opening a filehandle on an in-memory
string) was not introduced until Perl 5.6.0. C<HTTP::Handy::Input> provides
the same interface without relying on that feature.

The object is not exported and is not intended to be instantiated directly
by application code. Applications should access POST body data through
C<$env-E<gt>{'psgi.input'}> as described in L</PSGI SUBSET SPECIFICATION>.

Available methods:

  new($data)                        construct from a string
  read($buf, $length)               read up to $length bytes into $buf
  read($buf, $length, $offset)      read with byte offset into $buf
  seek($pos, $whence)               reposition (whence: 0=SET, 1=CUR, 2=END)
  tell()                            return current byte position
  getline()                         read and return one line (with newline)
  getlines()                        read and return all remaining lines

=head1 INTERNALS -- Private Functions

=over 4

=item C<_iso_time()>

Returns the current local time formatted as C<YYYY-MM-DDTHH:MM:SS> using
only C<localtime> and C<sprintf>. This replaces the earlier dependency on
C<POSIX::strftime>, making the module free of C<POSIX> entirely.

=item C<_init_directories()>

Called once at server startup by C<run()>. Creates the standard directory
layout (C<logs/>, C<logs/access/>, C<logs/error/>, C<run/>, C<htdocs/>,
C<conf/>) under the current working directory if they do not exist.

=item C<_open_access_log()>

Called after each request when logging is enabled. Opens (or rotates to)
the current 10-minute LTSV access log file under C<logs/access/>.
The filehandle is kept open between requests for efficiency and is only
reopened when the 10-minute window rolls over.

=back

=head1 DIAGNOSTICS

=head2 Startup errors

=over 4

=item C<HTTP::Handy-E<gt>run: 'app' is required>

C<run()> was called without an C<app> argument.

=item C<HTTP::Handy-E<gt>run: 'app' must be a code reference>

The value passed to C<app> is not a code reference.

=item C<HTTP::Handy-E<gt>run: 'port' must be a number>

The C<port> argument contains non-digit characters.

=item C<HTTP::Handy-E<gt>run: 'max_post_size' must be a number>

The value passed to C<max_post_size> contains non-digit characters.

=item C<HTTP::Handy: Cannot bind to HOST:PORT>

The server could not bind to the requested address and port.
The most common cause is that another process is already listening on
that port.

=back

=head2 Runtime messages (STDERR and logs/error/error.log)

=over 4

=item C<[TIMESTAMP] App error: MESSAGE>

The application code died with MESSAGE. A 500 response was sent to
the client. The server continues running.

=item C<[TIMESTAMP] Accept failed: MESSAGE>

C<IO::Socket::INET-E<gt>accept> returned an error. The server continues
to the next request.

=item C<Cannot open access log: FILENAME: MESSAGE>

C<_open_access_log()> could not open or create the rotating access log
file. Access log entries are still written to STDERR.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests by e-mail to
E<lt>ina@cpan.orgE<gt>.

When reporting a bug, please include:

=over 4

=item *

A minimal, self-contained test script that reproduces the problem.

=item *

The version of HTTP::Handy:

  perl -MHTTP::Handy -e 'print HTTP::Handy->VERSION, "\n"'

=item *

Your Perl version:

  perl -V

=item *

Your operating system.

=back

Known limitations (see also L</LIMITATIONS>):

=over 4

=item *

B<Single-process, single-thread.> Requests are handled one at a time.
A slow client blocks all other clients for the duration of that request.

=item *

B<No HTTPS.> See L</HTTPS>.

=item *

B<POST body fully buffered.> The entire POST body is read into memory
before the application is called.

=item *

B<Log files use the current working directory.> C<logs/>, C<htdocs/>,
and other directories created by C<_init_directories()> are relative to
the process working directory at the time C<run()> is called.

=back

=head1 DESIGN PHILOSOPHY

HTTP::Handy adheres to the B<Perl 5.005_03 specification> -- not because
we target the old interpreter, but because this specification represents
the simple, original Perl programming model that makes programming
enjoyable.

=over 4

=item B<Simplicity>

One file, no build step, no installation required beyond copying.
The entire server fits in a single C<.pm> file.

=item B<Portability>

Runs on every Perl from 5.005_03 through the latest release, on every
operating system that Perl supports.

=item B<Zero dependencies>

Only core modules (C<IO::Socket>, C<Carp>) are used.  No CPAN
installation is required.

=item B<US-ASCII source>

All source files contain only US-ASCII characters (0x00-0x7F).
This avoids encoding issues on any platform or terminal.

=back

=head1 SEE ALSO

=head2 PSGI Specification

L<PSGI> -- the Perl Web Server Gateway Interface specification (on MetaCPAN).

Official PSGI specification document:

  https://github.com/plack/psgi-specs/blob/master/PSGI.pod

HTTP::Handy implements a strict subset of PSGI/1.1. Applications written for
HTTP::Handy can be ported to full PSGI-compatible servers (such as Plack)
with little or no modification, because the C<$env> hash and response format
are identical.

=head2 Related Modules

L<Plack> -- a full-featured PSGI toolkit and server collection. Requires
Perl 5.8+. For production use or more demanding workloads, migrating from
HTTP::Handy to Plack is straightforward.

  https://plackperl.org/

L<HTTP::Server::Simple> -- another minimal HTTP server for Perl, with a
different (non-PSGI) interface.

L<LTSV::LINQ> -- LINQ-style queries for LTSV data, by the same author.
HTTP::Handy was originally developed to serve local tools built on top of
LTSV::LINQ.

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</INCLUDED DOCUMENTATION> -- eg/ samples and doc/ cheat sheets

=item * L</REQUIREMENTS>

=item * L</SUPPORTED PROTOCOL>

=item * L</PSGI SUBSET SPECIFICATION> -- C<$env> keys, response format, psgi.input

=item * L</SERVER STARTUP> -- C<run()>, directory init, log files

=item * L</METHODS> -- C<serve_static>, C<url_decode>, C<parse_query>,
C<mime_type>, C<is_htmx>, response builders

=item * L</ERROR HANDLING>

=item * L</STATIC FILES, CGI, AND HTMX>

=item * L</HTTPS>

=item * L</PSGI COMPATIBILITY NOTES>

=item * L</SECURITY>

=item * L</LIMITATIONS>

=item * L</DEMO>

=item * L</INTERNALS -- HTTP::Handy::Input>

=item * L</INTERNALS -- Private Functions>

=item * L</DIAGNOSTICS> -- error messages and runtime warnings

=item * L</BUGS AND LIMITATIONS>

=item * L</DESIGN PHILOSOPHY>

=item * L</SEE ALSO>

=back

=head1 AUTHOR

INABA Hitoshi E<lt>ina@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
