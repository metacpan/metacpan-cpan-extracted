# AGENTS.md - LightTCP::Server Project Guidelines

## Build, Lint, and Test Commands

### Running the Server
```bash
perl demo.pl [port]         # Run demo server (default port: 7002)
```

### Code Analysis
```bash
perl -c lib/LightTCP/Server.pm  # Syntax check module
perl -c demo.pl                 # Syntax check demo
perl -MO=Deparse,-p lib/LightTCP/Server.pm  # Parse tree for debugging
```

### Linting
```bash
perlcritic --severity=gentle lib/LightTCP/Server.pm       # Gentle severity check
perltidy lib/LightTCP/Server.pm                           # Format code
```

### Testing
```bash
prove -vl t/               # Run all tests with verbose output
prove -vl t/00_config_validation.t  # Run validation tests
prove -vl t/03_upload.t             # Run upload and rate limit tests
```

## File Upload Support

### Upload Configuration Attributes
```perl
use LightTCP::Server;

my $server = LightTCP::Server->new(
    upload_dir           => '/var/www/uploads',  # Required: directory for uploads
    upload_max_size      => 10 * 1024 * 1024,     # Default: 10MB max file size
    upload_allowed_types => [qw(image/jpeg image/png application/pdf)],  # Allowed MIME types
    func_upload          => \&handle_upload,       # Optional: callback after successful upload
);
```

### Upload Attributes
| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `upload_dir` | string | `/var/www/uploads` | Directory to save uploaded files (required) |
| `upload_max_size` | integer | 10MB | Maximum file size in bytes |
| `upload_allowed_types` | arrayref | empty | List of allowed MIME types |
| `func_upload` | coderef | undef | Callback: `sub($server, $upload_results)` |

### Upload Endpoints
- `GET /upload` - Returns HTML upload form
- `POST /upload` - Handles file upload via multipart/form-data

### Upload Security
- Filenames are sanitized: removes `..`, `/`, `\`, and special characters
- Path traversal attempts are blocked
- File size is enforced against `upload_max_size`
- MIME type is validated against `upload_allowed_types`
- Files are written atomically using temp file + rename

### Upload Callback
```perl
sub handle_upload {
    my ($server, $upload_results) = @_;
    # $upload_results is arrayref of upload info:
    # [{
    #     filename   => 'photo.jpg',
    #     size       => 1024,
    #     mime_type  => 'image/jpeg',
    #     saved_path => '/var/www/uploads/photo.jpg',
    #     success    => 1,
    # }, ...]
    return (201, 'Upload successful');  # Return HTTP status and message
}
```

## Rate Limiting

### Rate Limit Configuration Attributes
```perl
my $server = LightTCP::Server->new(
    rate_limit_enabled        => 1,           # Enable/disable rate limiting
    rate_limit_requests       => 100,         # Max requests per window (default: 100)
    rate_limit_window         => 60,          # Time window in seconds (default: 60)
    rate_limit_block_duration => 300,         # Block duration in seconds (default: 300)
    rate_limit_whitelist      => [qw(127.0.0.1 ::1 localhost)],  # IPs exempt from rate limiting
);
```

### Rate Limit Attributes
| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
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
- Includes `Retry-After` header with block duration
- Connection is closed after response

### Rate Limit Methods
```perl
# Check if request is within rate limit (returns true if allowed)
my $allowed = $server->_check_rate_limit($ip);

# Check if IP is currently blocked
my $block_info = $server->_is_blocked($ip);  # Returns undef or block info hashref

# Manually block an IP
$server->_block_ip($ip, $duration);
```

### Rate Limit Data Structure
The rate limit store uses a thread-safe design:
- `_rate_limit_lock`: Shared scalar lock for thread synchronization
- `_rate_limit_data`: Regular hashref for rate limit state
- Each IP has `{ count => N, first_request => timestamp }`
- Blocked IPs stored with key `"blocked:$ip"` containing block info

## Code Style Guidelines

### Package Declaration
```perl
package LightTCP::Server;

use strict;
use warnings;
```
- Module uses `LightTCP::Server` package
- Functions are called with `LightTCP::Server::` prefix (e.g., `LightTCP::Server::validate_config()`)
- OOP methods use `$self` as first parameter

### Imports
```perl
use strict;
use warnings;
use IO::Socket::INET;
use IPC::Open3;
use threads;
use threads::shared;
```
- Group imports logically
- Use specific module exports instead of `use POSIX;`

### OOP Design (LightTCP::Server)
```perl
package LightTCP::Server;

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;

    $self->{server_addr} = '0.0.0.0:8881';
    $self->{server_name} = 'tcpsrv';

    return $self;
}

sub server_addr {
    my ($self, $value) = @_;
    if (@_ > 1) {
        die "server_addr is required" unless defined $value && $value ne '';
        $self->{server_addr} = $value;
    }
    return $self->{server_addr};
}
```
- Use pure Perl OOP with bless and getter/setter methods
- Constructor accepts hash or hashref: `LightTCP::Server->new(%config)` or `LightTCP::Server->new(\%config)`
- Methods use `$self` as first parameter
- Class methods support both `ClassName->method()` and `ClassName::method()` styles

### Naming Conventions
- Functions: Public functions in `LightTCP::Server::` namespace
- Variables: Use descriptive names (`$server_addr`, `$pCONF` for config hashref)
- Configuration: Use hashref `$pCONF` for all config access; avoid globals
- Constants: UPPER_CASE for constants
- Private helper functions: `_get_server_state`, `_set_server_state` (leading underscore)
- OOP attributes: lowercase with underscores (e.g., `server_addr`, `max_threads`)

### Types and Data Structures
- Configuration: Hashref passed to `new()` or `validate_config()`
- Request data: Hashref `$preq` with keys like `URI`, `METHOD`, `clip`, `clport`
- Return tuples: Use `(status_code, content_length)` for callbacks
- Use `my $var :shared` for thread-safe variables

### Error Handling
```perl
# Check for failures explicitly
if (! $server) {
    LightTCP::Server::logit($pCONF, "# Error: $!", 0);
    return 0;
}

# Use eval for risky operations
eval {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm(30);
    # operations
    alarm(0);
};
if ($@) {
    LightTCP::Server::logit($pCONF, "# Error: $@");
}
```

### Logging
- Use `$self->logit($msg, $lvl)` for OOP
- Verbosity levels: 0 (minimal), 1 (important), 2 (info), 3 (debug)
- Return early if `$lvl > $self->verbose`

### File Handling
```perl
if (open(my $fh, '<', $fn)) {
    # handle file
    close($fh);
} else {
    LightTCP::Server::logit($pCONF, "# Error opening $fn: $!");
}
```
- Always check open/close return values
- Use lexical filehandles (`my $fh`)
- Use 3-arg open

### Security
- Sanitize all user inputs (URI, headers)
- Check for path traversal (`..`) in file operations
- Use allow/deny files for IP-based access control
- Validate authentication tokens before access
- Use `LightTCP::Server::validate_config()` to validate configuration

### Threading
- Use `threads` and `threads::shared` for threaded mode
- Clean up threads on shutdown: `$thr->join()` or `threads->detach()`
- Limit max concurrent threads
- Use `lock()` for shared variable access

### Documentation
- Add POD `=head1 NAME`, `=head1 SYNOPSIS`, `=head1 DESCRIPTION`
- Document all config options and function signatures
- Include examples in POD
- Always end module with `1;` for successful loading

### Code Organization
- Main module: `lib/LightTCP/Server.pm` (~1400 lines)
- Demo script: `demo.pl`
- Tests in `t/` directory with `Test::More`
- Keep functions under 50 lines when possible
- Use subroutines for repeated operations

### Directory Structure
```
LightTCP/
├── lib/
│   └── LightTCP/
│       └── Server.pm          # Main module
├── examples/
│   └── demo.pl                # Demo server script
├── t/
│   ├── 00_config_validation.t
│   ├── 01_path_traversal.t
│   ├── 02_oo_validation.t
│   └── 03_upload.t
├── Makefile.PL
├── README.md
├── AGENTS.md
├── LICENSE
└── CHANGES
```
