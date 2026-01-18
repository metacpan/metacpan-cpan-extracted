# LightTCP::Server

A configurable TCP server package with HTTP support, file uploads, and rate limiting written in Perl.

## Features

- **Multiple server modes**: single, fork, or thread-based request handling
- **HTTP server**: Serve static files and dynamic content
- **File upload support**: Handle multipart form-data uploads with size limits and type validation
- **Rate limiting**: Configurable request limits per IP with automatic blocking
- **CGI support**: Run external CGI scripts
- **Authentication**: Token-based access control
- **IP access control**: Allow/deny lists for client filtering
- **Logging**: Configurable logging with daily log rotation
- **Perl-only mode**: Handle Perl scripts directly without CGI overhead

## Installation

### Manual Installation

```bash
# Clone or download the project
cd LightTCP

# Install dependencies
cpanm IO::Socket::INET IPC::Open3 threads threads::shared File::Temp

# Run tests
prove -vl t/

# Install
perl Makefile.PL
make
make install
```

### Dependencies

- Perl 5.8 or higher
- IO::Socket::INET (network sockets)
- IPC::Open3 (CGI support)
- threads / threads::shared (threaded mode)
- File::Temp (file uploads)

## Quick Start

```bash
# Clone or download the project
cd LightTCP

# Run the demo server on port 7002
perl examples/demo.pl 7002

# Or use default port
perl examples/demo.pl
```

Then visit http://localhost:7002 in your browser.

## Usage

### Basic Server

```perl
use LightTCP::Server;

my $server = LightTCP::Server->new(
    server_addr => '0.0.0.0:8080',
    server_name => 'MyServer',
    server_type => 'thread',
    max_threads => 5,
    verbose     => 2,
);

$server->start();
```

### Server with Callbacks

```perl
my $server = LightTCP::Server->new(
    server_addr   => '0.0.0.0:8080',
    server_type   => 'thread',
    max_threads   => 5,
    func_perl     => \&handle_request,
    func_log      => \&handle_log,
    func_done     => \&handle_done,
    func_timeout  => \&handle_timeout,
);

sub handle_request {
    my ($self, $client, $preq) = @_;
    my $method = $preq->{METHOD};
    my $uri    = $preq->{URI};

    my $response = "You requested: $method $uri";
    my $len = length($response);

    print $client "HTTP/1.1 200 OK\r\n";
    print $client "Content-Length: $len\r\n";
    print $client "Connection: close\r\n";
    print $client "\r\n";
    print $client $response;

    return (200, $len);
}
```

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `server_addr` | string | `0.0.0.0:8881` | Listen address and port |
| `server_name` | string | `tcpsrv` | Server name for responses |
| `server_type` | string | `single` | `single`, `fork`, or `thread` |
| `max_threads` | integer | 10 | Max threads (thread mode) |
| `server_timeout` | integer | -1 | Connection timeout in seconds |
| `server_dir` | string | `/var/www` | Base directory for files |
| `verbose` | integer | 0 | Verbosity level (0-3) |
| `logfn` | string | `''` | Log file name prefix |

### Authentication

```perl
my $server = LightTCP::Server->new(
    server_addr => '0.0.0.0:8080',
    server_auth => 1,
    server_keys => ['secret-token-1', 'secret-token-2'],
);

# Client must send header: X-Auth-Token: secret-token-1
```

### IP Access Control

```perl
my $server = LightTCP::Server->new(
    server_addr => '0.0.0.0:8080',
    server_etc  => '/etc/tcpserver',
    server_deny => 1,
);

# Create /etc/tcpserver/<ip>.allow and /etc/tcpserver/<ip>.deny files
# with one IP per line
```

## File Upload Support

### Basic Upload Server

```perl
my $server = LightTCP::Server->new(
    server_addr      => '0.0.0.0:8080',
    upload_dir       => '/var/www/uploads',
    upload_max_size  => 10 * 1024 * 1024,  # 10MB
    func_upload      => \&handle_upload,
);

sub handle_upload {
    my ($self, $upload_results) = @_;

    for my $upload (@$upload_results) {
        if ($upload->{success}) {
            print "Saved: $upload->{filename} -> $upload->{saved_path}\n";
        } else {
            print "Failed: $upload->{filename} - $upload->{error}\n";
        }
    }

    return (201, "Upload complete");
}
```

### Upload Endpoints

- `GET /upload` - Returns HTML upload form
- `POST /upload` - Handles file upload via multipart/form-data

### Upload Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `upload_dir` | string | `/var/www/uploads` | Directory for uploads |
| `upload_max_size` | integer | 10MB | Max file size in bytes |
| `upload_allowed_types` | arrayref | `[]` | Allowed MIME types |
| `func_upload` | coderef | undef | Upload callback |

### Upload Security

- Filenames are sanitized (removes `..`, `/`, `\`, special characters)
- Path traversal attempts are blocked
- File size is enforced against `upload_max_size`
- MIME type is validated against `upload_allowed_types`
- Files are written atomically using temp file + rename

## Rate Limiting

### Basic Rate Limiting

```perl
my $server = LightTCP::Server->new(
    server_addr              => '0.0.0.0:8080',
    rate_limit_enabled       => 1,
    rate_limit_requests      => 100,       # Max requests
    rate_limit_window        => 60,        # Per 60 seconds
    rate_limit_block_duration => 300,       # Block for 5 minutes
    rate_limit_whitelist     => [qw(127.0.0.1 ::1 localhost)],
);
```

### Rate Limit Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rate_limit_enabled` | bool | 1 | Enable rate limiting |
| `rate_limit_requests` | integer | 100 | Max requests per window |
| `rate_limit_window` | integer | 60 | Time window in seconds |
| `rate_limit_block_duration` | integer | 300 | Block duration in seconds |
| `rate_limit_whitelist` | arrayref | `[127.0.0.1, ::1, localhost]` | IPs to exempt |

### Rate Limit Headers

Responses include rate limit headers:

```
X-RateLimit-Limit: 100        # Maximum requests allowed
X-RateLimit-Remaining: 95     # Remaining requests in window
X-RateLimit-Reset: 45         # Seconds until window resets
Retry-After: 300              # Seconds until unblocked (on 429)
```

### Rate Limit Response

When rate limit is exceeded:
- Returns HTTP 429 Too Many Requests
- Includes `X-RateLimit-*` headers
- Includes `Retry-After` header
- Connection is closed after response

## Demo Server Endpoints

The demo server (`demo.pl`) includes these endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | HTML home page |
| `/json` | GET | JSON API response |
| `/status` | GET | Server status information |
| `/stop` | GET | Stop the server |
| `/echo` | GET | Echo query parameters |
| `/upload` | GET | File upload form |
| `/upload` | POST | File upload handler |
| `/rate-limit-test` | GET | Rate limit testing page |

## Testing

```bash
# Run all tests
prove -vl t/

# Run specific test file
prove -vl t/03_upload.t

# Run with coverage
perl -MDevel::Cover=-ignore,^t/ prove -vl t/
```

### Test Files

- `t/00_config_validation.t` - Configuration validation tests
- `t/01_path_traversal.t` - Path traversal protection tests
- `t/02_oo_validation.t` - OOP validation tests
- `t/03_upload.t` - Upload and rate limiting tests

## Logging

### Log Levels

| Level | Description |
|-------|-------------|
| 0 | Minimal (errors only) |
| 1 | Important events |
| 2 | Informational |
| 3 | Debug (verbose) |

### Custom Log Handler

```perl
my $server = LightTCP::Server->new(
    server_addr => '0.0.0.0:8080',
    logfn       => 'myapp',
    func_log    => \&custom_log,
);

sub custom_log {
    my ($self, $msg, $lvl) = @_;
    return if $lvl > $self->{verbose};

    my $timestamp = localtime();
    print STDERR "[$timestamp] $msg\n";
}
```

## License

This software is licensed under the same terms as Perl itself.

## See Also

- [IO::Socket::INET](https://metacpan.org/pod/IO::Socket::INET) - TCP socket handling
- [threads](https://metacpan.org/pod/threads) - Threading support
