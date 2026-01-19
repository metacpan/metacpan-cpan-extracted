# LightTCP::SSLclient

SSL/TLS HTTP client library for Perl with proxy support, certificate pinning, and redirect following.

[![Tests](https://img.shields.io/badge/tests-33%20passed-green)](https://github.com/anomalyco/LightTCP-SSLclient.pm)

## Features

- **SSL/TLS Connections** - Secure HTTP client with configurable protocols and cipher suites
- **HTTP CONNECT Proxy Support** - Full support for HTTP proxy with Basic authentication
- **Certificate Pinning** - Save and verify certificate fingerprints
- **Redirect Following** - Automatic redirect handling with configurable limits
- **Keep-Alive Connections** - Reuse connections for better performance
- **Chunked Transfer Encoding** - Proper handling of chunked responses
- **Verbose Debug Mode** - Detailed debugging output

## Installation

### Prerequisites

```bash
# Install dependencies
cpanm --installdeps .
```

### Standard Installation

```bash
# Build and install
perl Makefile.PL
make
make install
```

### Direct Usage

```bash
# Run without installing
perl -I lib examples/ssltest.pl https://example.com
```

## Quick Start

```perl
use LightTCP::SSLclient;

# Create client with default options
my $client = LightTCP::SSLclient->new(
    timeout      => 30,
    insecure     => 0,
    verbose      => 0,
);

# Connect to host
my ($ok, $errors, $debug, $code) = $client->connect('example.com', 443);
die "Connect failed: @$errors" unless $ok;

# Send HTTP request
($ok, $errors, $debug, $code) = $client->request('GET', '/api/data', host => 'example.com');
die "Request failed: @$errors" unless $ok;

# Read response
my ($code, $state, $headers, $body, $resp_errors, $resp_debug, $resp_code) = $client->response();

print "Response: $code $state\n";
print $body;

$client->close();
```

## Constructor Options

```perl
my $client = LightTCP::SSLclient->new(
    timeout          => 10,                      # Request timeout in seconds
    insecure         => 0,                       # Skip SSL verification (0=verify, 1=skip)
    cert             => '/path/to/client',       # Client certificate base path
    verbose          => 0,                       # Enable debug output
    user_agent       => 'MyClient/1.0',          # User-Agent header
    ssl_protocols    => ['TLSv1.2', 'TLSv1.3'],  # Allowed SSL protocols
    ssl_ciphers      => 'HIGH:!aNULL:!MD5',      # Allowed cipher suites
    keep_alive       => 0,                       # Use HTTP keep-alive
    buffer_size      => 8192,                    # Read buffer size in bytes
    max_redirects    => 5,                       # Max redirects to follow
    follow_redirects => 1,                       # Follow 3xx redirects
);
```

## API Reference

### Connection Methods

#### connect($host, $port, $proxy, $proxy_auth)

Establish SSL connection to target host.

```perl
my ($ok, $errors, $debug, $code) = $client->connect(
    'example.com',      # Target host
    443,                # Target port
    'proxy.com:8080',   # Optional HTTP proxy
    'user:pass',        # Optional proxy auth
);
```

Returns: `(ok, errors_ref, debug_ref, error_code)`

#### reconnect()

Reconnect using previously used connection parameters.

```perl
my ($ok, $errors, $debug, $code) = $client->reconnect();
```

#### close()

Close the connection.

```perl
$client->close();
```

### Request Methods

#### request($method, $path, %options)

Send HTTP request.

```perl
my ($ok, $errors, $debug, $code) = $client->request(
    'GET',                    # Method
    '/api/data',              # Path
    host    => 'example.com', # Host header
    payload => $body,         # Request body (optional)
    headers => {              # Custom headers
        'X-Custom' => 'value',
    },
);
```

#### response()

Read HTTP response.

```perl
my ($code, $state, $headers, $body, $errors, $debug, $code) = $client->response();
```

#### request_with_redirects($method, $path, %options)

Send HTTP request and automatically follow redirects.

```perl
my ($code, $state, $headers, $body, $errors, $debug, $resp_code, $history)
    = $client->request_with_redirects(
        'POST',                   # Method
        '/submit',                # Path
        host    => 'example.com', # Host header
        payload => $form_data,    # Request body
    );

# Check redirect history
foreach my $redirect (@$history) {
    print "$redirect->{code}: $redirect->{from} -> $redirect->{to}\n";
}
```

**Redirect Behavior:**
- 301/302: POST requests converted to GET, payload dropped
- 303: Always converted to GET
- 307/308: Method preserved (POST stays POST)

### Fingerprint Methods

#### fingerprint_read($dir, $host, $port)

Read saved certificate fingerprint.

```perl
my $fp = $client->fingerprint_read('./certs', 'example.com', 443);
```

#### fingerprint_save($dir, $host, $port, $fp, $save)

Save certificate fingerprint.

```perl
my ($ok, $errors, $debug, $code) = $client->fingerprint_save(
    $dir, $host, $port, $fingerprint, $save
);
# $save = 1 to permanently save, 0 to save as .new file
```

### Accessor Methods

| Method | Description |
|--------|-------------|
| `socket()` | Returns underlying socket object |
| `is_connected()` | Returns 1 if connected, 0 otherwise |
| `get_timeout()`, `set_timeout($value)` | Get/set timeout |
| `get_user_agent()`, `set_user_agent($value)` | Get/set User-Agent |
| `get_insecure()`, `set_insecure($value)` | Get/set insecure mode |
| `get_keep_alive()`, `set_keep_alive($value)` | Get/set keep-alive |
| `is_keep_alive()` | Boolean keep-alive check |
| `get_cert()`, `set_cert($value)` | Get/set client certificate |
| `get_ssl_protocols()` | Get allowed SSL protocols |
| `get_ssl_ciphers()` | Get allowed cipher suites |
| `get_buffer_size()`, `set_buffer_size($value)` | Get/set buffer size |
| `get_max_redirects()`, `set_max_redirects($value)` | Get/set max redirects |
| `get_follow_redirects()`, `set_follow_redirects($value)` | Get/set redirect following |
| `get_redirect_count()` | Get redirects followed in last request |
| `get_redirect_history()` | Get redirect history arrayref |
| `is_verbose()` | Get verbose mode status |

## Return Values

### connect() and request()

```perl
my ($ok, $errors_ref, $debug_ref, $error_code) = $client->method(...);
```

| Value | Description |
|-------|-------------|
| `$ok` | Boolean success indicator (1=success, 0=failure) |
| `$errors_ref` | Reference to array of error messages |
| `$debug_ref` | Reference to array of debug messages (empty unless verbose) |
| `$error_code` | Error type constant (0 if successful) |

### Error Codes

```perl
use LightTCP::SSLclient qw(ECONNECT EREQUEST ERESPONSE ETIMEOUT ESSL);

my ($ok, $errors, $debug, $code) = $client->connect(...);
if (!$ok) {
    if ($code == ECONNECT)  { die "Connection error" }
    elsif ($code == EREQUEST)  { die "Request error" }
    elsif ($code == ERESPONSE) { die "Response error" }
    elsif ($code == ETIMEOUT)  { die "Timeout error" }
    elsif ($code == ESSL)      { die "SSL/TLS error" }
}
```

| Constant | Value | Description |
|----------|-------|-------------|
| `ECONNECT` | 1 | Connection error |
| `EREQUEST` | 2 | Request error |
| `ERESPONSE` | 3 | Response error |
| `ETIMEOUT` | 4 | Timeout error |
| `ESSL` | 5 | SSL/TLS error |

### response()

```perl
my ($code, $state, $headers_ref, $body, $errors_ref, $debug_ref, $error_code)
    = $client->response();
```

| Value | Description |
|-------|-------------|
| `$code` | HTTP status code (200, 404, etc.) |
| `$state` | HTTP status message (OK, Not Found) |
| `$headers_ref` | Reference to hash of response headers (lowercase keys) |
| `$body` | Response body as string |
| `$errors_ref`, `$debug_ref`, `$error_code` | Same as above |

## Examples

### Basic GET Request

```perl
use LightTCP::SSLclient;

my $client = LightTCP::SSLclient->new(timeout => 30);
my ($ok, $errors, $debug) = $client->connect('example.com', 443);
die "Connect failed: @$errors" unless $ok;

($ok, $errors, $debug) = $client->request('GET', '/');
die "Request failed: @$errors" unless $ok;

my ($code, $state, $headers, $body) = $client->response();
print "Response: $code $state\n";
print $body;

$client->close();
```

### With Proxy Authentication

```perl
my ($ok, $errors, $debug) = $client->connect(
    'api.example.com', 443,
    'proxy.corp.com:8080', 'user:pass'
);
```

### With Certificate Pinning

```perl
my $client = LightTCP::SSLclient->new(dir => './certs');
my ($ok, $errors, $debug) = $client->connect('example.com', 443);

# First connection - save fingerprint
$client->fingerprint_save('./certs', 'example.com', 443, $fp, 1);

# Subsequent connections will auto-verify
$client->fingerprint_save('./certs', 'example.com', 443, $fp, 0);
```

### Verbose Debug Mode

```perl
my $client = LightTCP::SSLclient->new(verbose => 1);
my ($ok, $errors, $debug) = $client->connect('example.com', 443);

print "=== DEBUG ===\n";
print @$debug;
print "=== ERRORS ===\n";
print @$errors;
```

### Following Redirects

```perl
my ($code, $state, $headers, $body, $errors, $debug, $resp_code, $history)
    = $client->request_with_redirects('GET', '/old-page', host => 'example.com');

print "Final URL: $headers->{'content-location'} // $body\n" if $code == 200;

# Show redirect chain
for my $r (@$history) {
    print "$r->{code}: $r->{from} -> $r->{to}\n";
}
```

## Testing

```bash
# Run all tests
make test

# Run single test file
prove t/00_load.t

# Run with verbose output
prove -v t/01_constructor.t

# Run without building first
perl -I lib t/00_load.t
```

## Requirements

- Perl 5.8.1+
- `IO::Socket::SSL`
- `IO::Socket::INET`
- `MIME::Base64`
- `URI`

## License

This module is free software and may be modified and distributed under the same terms as Perl itself.

