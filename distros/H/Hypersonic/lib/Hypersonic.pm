package Hypersonic;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.03';

use XS::JIT;
use XS::JIT::Builder;
use Hypersonic::Socket;
use B::Deparse;

# Cache deparser instance for handler analysis
my $DEPARSER;

# Optional TLS support
my $HAS_TLS = 0;
eval { require Hypersonic::TLS; $HAS_TLS = Hypersonic::TLS::check_openssl(); };

sub new {
    my ($class, %opts) = @_;
    
    # Validate TLS options
    if ($opts{tls}) {
        die "TLS support not available (OpenSSL not found)" unless $HAS_TLS;
        die "cert_file required for TLS" unless $opts{cert_file};
        die "key_file required for TLS" unless $opts{key_file};
        die "cert_file not found: $opts{cert_file}" unless -f $opts{cert_file};
        die "key_file not found: $opts{key_file}" unless -f $opts{key_file};
    }
    
    # Security headers configuration
    my $security_headers = $opts{security_headers} // {};
    
    return bless {
        routes    => [],
        compiled  => 0,
        cache_dir => $opts{cache_dir} // '_hypersonic_cache',
        id        => int(rand(100000)),
        # TLS options
        tls       => $opts{tls} // 0,
        cert_file => $opts{cert_file},
        key_file  => $opts{key_file},
        # Security hardening options
        max_connections    => $opts{max_connections} // 10000,
        max_request_size   => $opts{max_request_size} // 8192,
        keepalive_timeout  => $opts{keepalive_timeout} // 30,
        recv_timeout       => $opts{recv_timeout} // 30,
        # Graceful shutdown
        drain_timeout      => $opts{drain_timeout} // 5,
        # Security headers (JIT optimized - pre-computed at compile time)
        security_headers   => {
            'X-Frame-Options'           => $security_headers->{'X-Frame-Options'} // 'DENY',
            'X-Content-Type-Options'    => $security_headers->{'X-Content-Type-Options'} // 'nosniff',
            'X-XSS-Protection'          => $security_headers->{'X-XSS-Protection'} // '1; mode=block',
            'Referrer-Policy'           => $security_headers->{'Referrer-Policy'} // 'strict-origin-when-cross-origin',
            'Content-Security-Policy'   => $security_headers->{'Content-Security-Policy'},  # User must set this
            'Strict-Transport-Security' => ($opts{tls} ? ($security_headers->{'Strict-Transport-Security'} // 'max-age=31536000; includeSubDomains') : undef),
            'Permissions-Policy'        => $security_headers->{'Permissions-Policy'},  # User can optionally set
        },
        enable_security_headers => $opts{enable_security_headers} // 1,  # Enabled by default
        # Middleware support
        before_middleware => [],  # Global before hooks
        after_middleware  => [],  # Global after hooks
    }, $class;
}

# Route registration methods
sub get    { shift->_add_route('GET',    @_) }
sub post   { shift->_add_route('POST',   @_) }
sub put    { shift->_add_route('PUT',    @_) }
sub del    { shift->_add_route('DELETE', @_) }
sub patch  { shift->_add_route('PATCH',  @_) }
sub head   { shift->_add_route('HEAD',   @_) }
sub options { shift->_add_route('OPTIONS', @_) }

# Static file serving - JIT-compiled for maximum performance
# Files are read at compile time and baked into C constants
sub static {
    my ($self, $url_prefix, $directory, $opts) = @_;
    
    $opts //= {};
    die "URL prefix must start with /" unless $url_prefix =~ m{^/};
    die "Directory does not exist: $directory" unless -d $directory;
    
    # Normalize paths
    $url_prefix =~ s{/$}{};  # Remove trailing slash
    $directory =~ s{/$}{};
    
    # Store static config for compile-time processing
    push @{$self->{static_dirs} //= []}, {
        prefix    => $url_prefix,
        directory => $directory,
        # Options
        max_age   => $opts->{max_age} // 3600,      # Cache-Control max-age
        index     => $opts->{index} // 'index.html', # Directory index file
        etag      => $opts->{etag} // 1,             # Generate ETags
        gzip      => $opts->{gzip} // 0,             # Serve .gz files if available
    };
    
    return $self;
}

# MIME type lookup - JIT baked into C at compile time
my %MIME_TYPES = (
    # Text
    html => 'text/html; charset=utf-8',
    htm  => 'text/html; charset=utf-8',
    css  => 'text/css; charset=utf-8',
    js   => 'application/javascript; charset=utf-8',
    mjs  => 'application/javascript; charset=utf-8',
    json => 'application/json; charset=utf-8',
    xml  => 'application/xml; charset=utf-8',
    txt  => 'text/plain; charset=utf-8',
    csv  => 'text/csv; charset=utf-8',
    md   => 'text/markdown; charset=utf-8',
    # Images
    png  => 'image/png',
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    gif  => 'image/gif',
    svg  => 'image/svg+xml',
    ico  => 'image/x-icon',
    webp => 'image/webp',
    avif => 'image/avif',
    # Fonts
    woff  => 'font/woff',
    woff2 => 'font/woff2',
    ttf   => 'font/ttf',
    otf   => 'font/otf',
    eot   => 'application/vnd.ms-fontobject',
    # Media
    mp3  => 'audio/mpeg',
    mp4  => 'video/mp4',
    webm => 'video/webm',
    ogg  => 'audio/ogg',
    wav  => 'audio/wav',
    # Documents
    pdf  => 'application/pdf',
    zip  => 'application/zip',
    gz   => 'application/gzip',
    tar  => 'application/x-tar',
    # Web
    wasm => 'application/wasm',
    map  => 'application/json',
);

sub _get_mime_type {
    my ($path) = @_;
    my ($ext) = $path =~ /\.(\w+)$/;
    return $MIME_TYPES{lc($ext // '')} // 'application/octet-stream';
}

# Middleware registration methods
# before() - runs before route handler, can short-circuit by returning a response
# after() - runs after route handler, can modify response
sub before {
    my ($self, $handler) = @_;
    die "Middleware must be a code ref" unless ref($handler) eq 'CODE';
    push @{$self->{before_middleware}}, $handler;
    return $self;
}

sub after {
    my ($self, $handler) = @_;
    die "Middleware must be a code ref" unless ref($handler) eq 'CODE';
    push @{$self->{after_middleware}}, $handler;
    return $self;
}

# Session configuration - enables session support with signed cookies
# Only loads session module when called (JIT philosophy)
sub session_config {
    my ($self, %opts) = @_;
    
    require Hypersonic::Session;
    
    # Configure the session module
    my $config = Hypersonic::Session->configure(%opts);
    
    # Inject session middleware
    # Before: Load session from cookie/store
    unshift @{$self->{before_middleware}}, Hypersonic::Session::before_middleware();
    
    # After: Save session to cookie/store
    push @{$self->{after_middleware}}, Hypersonic::Session::after_middleware();
    
    # Mark that we need cookies parsed for all dynamic routes
    $self->{_session_enabled} = 1;
    
    return $self;
}

# Compression configuration - JIT-compiled gzip compression in C
# Only loads compression module when called (JIT philosophy)
sub compress {
    my ($self, %opts) = @_;
    
    require Hypersonic::Compress;
    
    # Check for zlib
    unless (Hypersonic::Compress::check_zlib()) {
        warn "Warning: zlib not found, compression disabled\n";
        return $self;
    }
    
    # Configure compression
    my $config = Hypersonic::Compress->configure(%opts);
    
    # Mark that compression is enabled - JIT code gen will include zlib code
    $self->{_compression_enabled} = 1;
    $self->{_compression_config} = $config;
    
    return $self;
}

sub _add_route {
    my ($self, $method, $path, $handler, $opts) = @_;

    die "Path must start with /" unless $path =~ m{^/};
    die "Handler must be a code ref" unless ref($handler) eq 'CODE';

    # Check for dynamic option and feature flags
    my $dynamic = 0;
    my %features = (
        parse_query   => 0,  # Parse ?key=value query strings
        parse_headers => 0,  # Parse HTTP headers
        parse_cookies => 0,  # Parse Cookie header
        parse_json    => 0,  # Parse JSON body (requires Cpanel::JSON::XS)
        parse_form    => 0,  # Parse form-urlencoded body
    );
    
    if (ref($opts) eq 'HASH') {
        $dynamic = $opts->{dynamic} ? 1 : 0;
        # Copy feature flags from options
        for my $feat (keys %features) {
            $features{$feat} = $opts->{$feat} ? 1 : 0 if exists $opts->{$feat};
        }
    }

    # Parse path parameters (supports multiple: /users/:user_id/posts/:post_id)
    my @params;
    my @segments = split '/', $path;
    shift @segments;  # Remove leading empty string
    
    for my $i (0 .. $#segments) {
        if ($segments[$i] =~ /^:(\w+)$/) {
            push @params, { name => $1, position => $i };
            $dynamic = 1;  # Path params imply dynamic
        }
    }

    push @{$self->{routes}}, {
        method   => $method,
        path     => $path,
        handler  => $handler,
        dynamic  => $dynamic,
        params   => \@params,
        segments => \@segments,
        features => \%features,
        # Per-route middleware (optional)
        before   => $opts->{before} // [],
        after    => $opts->{after} // [],
    };

    return $self;
}

sub compile {
    my ($self) = @_;

    die "No routes defined" unless @{$self->{routes}} || @{$self->{static_dirs} // []};
    die "Already compiled" if $self->{compiled};

    # ============================================================
    # STATIC FILE PROCESSING - bake files into C at compile time
    # ============================================================
    if (my $static_dirs = $self->{static_dirs}) {
        $self->_compile_static_files($static_dirs);
    }

    # Compile JIT request accessors for array-based request objects
    require Hypersonic::Request;
    Hypersonic::Request->compile_accessors(cache_dir => $self->{cache_dir});

    # ============================================================
    # ROUTE ANALYSIS - determine what code to generate (JIT philosophy)
    # ============================================================
    my %analysis = (
        methods_used     => {},   # GET => 1, POST => 1, etc.
        has_dynamic      => 0,    # Any dynamic routes?
        has_static       => 0,    # Any static routes?
        has_path_params  => 0,    # Any routes with :param?
        has_body_access  => 0,    # Any routes that need body?
        route_count      => scalar(@{$self->{routes}}),
        all_same_prefix  => undef,  # Common prefix like /api/*
        single_method    => undef,  # Only one HTTP method used?
        # JIT feature flags - only generate code for features actually used
        needs_query      => 0,    # Any route needs query string parsing?
        needs_headers    => 0,    # Any route needs header access?
        needs_cookies    => 0,    # Any route needs cookie parsing?
        needs_json       => 0,    # Any route needs JSON body parsing?
        needs_form       => 0,    # Any route needs form data parsing?
        # Middleware flags - JIT: only generate middleware code if actually used
        has_global_before => scalar(@{$self->{before_middleware}}) > 0,
        has_global_after  => scalar(@{$self->{after_middleware}}) > 0,
        has_route_middleware => 0,  # Any route has before/after hooks?
        has_any_middleware   => 0,  # Global OR per-route middleware?
    );

    # First pass: collect method usage and route characteristics
    for my $route (@{$self->{routes}}) {
        $analysis{methods_used}{$route->{method}} = 1;

        if ($route->{dynamic}) {
            $analysis{has_dynamic} = 1;
            # Dynamic routes might need body access (POST/PUT/PATCH typically do)
            if ($route->{method} =~ /^(POST|PUT|PATCH)$/) {
                $analysis{has_body_access} = 1;
            }
            
            # JIT FEATURE DETECTION: Analyze handler code to detect what request
            # features it actually uses. This avoids generating unused parsing code.
            my $f = $route->{features} // {};
            
            # Explicit flags take precedence
            $analysis{needs_query}   = 1 if $f->{parse_query};
            $analysis{needs_headers} = 1 if $f->{parse_headers};
            $analysis{needs_cookies} = 1 if $f->{parse_cookies};
            $analysis{needs_json}    = 1 if $f->{parse_json};
            $analysis{needs_form}    = 1 if $f->{parse_form};
            
            # Auto-detect by analyzing handler code
            my $handler_code = _deparse_handler($route->{handler});
            if ($handler_code) {
                # Look for $req->{query} or ->{query} access patterns
                $analysis{needs_query}   = 1 if $handler_code =~ /\{['"]*query['"]*\}/;
                $analysis{needs_headers} = 1 if $handler_code =~ /\{['"]*headers['"]*\}/;
                $analysis{needs_cookies} = 1 if $handler_code =~ /\{['"]*cookies['"]*\}/;
                $analysis{needs_json}    = 1 if $handler_code =~ /\{['"]*json['"]*\}/;
                $analysis{needs_form}    = 1 if $handler_code =~ /\{['"]*form['"]*\}/;
            }
        } else {
            $analysis{has_static} = 1;
        }

        if (@{$route->{params}}) {
            $analysis{has_path_params} = 1;
        }
        
        # Check for per-route middleware
        if (@{$route->{before}} || @{$route->{after}}) {
            $analysis{has_route_middleware} = 1;
        }
    }
    
    # Session support: force cookie parsing when sessions are enabled
    if ($self->{_session_enabled}) {
        $analysis{needs_cookies} = 1;
    }
    
    # Compression support: force header parsing to check Accept-Encoding
    if ($self->{_compression_enabled}) {
        $analysis{needs_headers} = 1;
    }
    
    # Determine if any middleware is present (global or per-route)
    $analysis{has_any_middleware} = $analysis{has_global_before} || 
                                    $analysis{has_global_after} ||
                                    $analysis{has_route_middleware};

    # Check if only one method is used
    my @methods = keys %{$analysis{methods_used}};
    if (@methods == 1) {
        $analysis{single_method} = $methods[0];
    }

    # Check for common prefix (e.g., all routes start with /api)
    my @paths = map { $_->{path} } @{$self->{routes}};
    if (@paths > 1) {
        my $prefix = _find_common_prefix(@paths);
        if (length($prefix) > 1) {  # More than just "/"
            $analysis{all_same_prefix} = $prefix;
        }
    }

    # Store analysis for use in code generation
    $self->{route_analysis} = \%analysis;

    # Pre-evaluate all static handlers and build FULL HTTP responses
    my @full_responses;
    my @dynamic_handlers;  # Store CV refs for dynamic routes
    my @route_param_info;  # Store param info for dynamic routes

    for my $i (0 .. $#{$self->{routes}}) {
        my $route = $self->{routes}[$i];

        if (!$route->{dynamic}) {
            # Check if this is a pre-built static file response
            if ($route->{_static_file}) {
                push @full_responses, $route->{_static_response};
                $route->{response_idx} = $#full_responses;
                next;
            }
            
            # RUN THE HANDLER ONCE - this is the magic
            my $result = $route->{handler}->();
            
            # Support both string and [status, headers, body] format
            my ($status, $headers, $body);
            if (ref($result) eq 'ARRAY') {
                ($status, $headers, $body) = @$result;
                $status //= 200;
                $headers //= {};
            } elsif (ref($result) eq 'HASH') {
                $status = $result->{status} // 200;
                $headers = $result->{headers} // {};
                $body = $result->{body} // '';
            } else {
                $status = 200;
                $headers = {};
                $body = $result;
            }
            
            die "Handler for $route->{method} $route->{path} must return a string or response structure"
                unless defined $body && !ref($body);

            # Determine content type (from headers or auto-detect)
            my $ct = $headers->{'Content-Type'} 
                  // (($body =~ /^\s*[\[{]/) ? 'application/json' : 'text/plain');
            
            # Get status text
            my $status_text = _status_text($status);

            # Build COMPLETE HTTP response at compile time (with custom status)
            my $full_response = "HTTP/1.1 $status $status_text\r\n"
                              . "Content-Type: $ct\r\n"
                              . "Content-Length: " . length($body) . "\r\n"
                              . "Connection: keep-alive\r\n";
            
            # Add security headers (JIT pre-computed at compile time)
            if ($self->{enable_security_headers}) {
                $full_response .= $self->_get_security_headers_string();
            }
            
            # Add custom headers
            for my $h (keys %$headers) {
                next if $h eq 'Content-Type' || $h eq 'Content-Length' || $h eq 'Connection';
                # Skip security headers if already added
                next if $self->{enable_security_headers} && exists $self->{security_headers}{$h};
                $full_response .= "$h: $headers->{$h}\r\n";
            }
            
            $full_response .= "\r\n" . $body;

            push @full_responses, $full_response;
            $route->{response_idx} = $#full_responses;
        } else {
            # Dynamic route - store handler index and param info
            push @dynamic_handlers, $route->{handler};
            push @route_param_info, $route->{params};
            $route->{handler_idx} = $#dynamic_handlers;
        }
    }

    # Store dynamic handlers and param info for runtime access
    $self->{dynamic_handlers} = \@dynamic_handlers;
    $self->{route_param_info} = \@route_param_info;
    
    # JIT: Build per-route middleware arrays (only if route middleware is present)
    my $analysis = $self->{route_analysis};
    if ($analysis->{has_route_middleware}) {
        my @route_before_mw;
        my @route_after_mw;
        for my $route (@{$self->{routes}}) {
            next unless $route->{dynamic};
            # Store arrays of middleware handlers per route (by handler_idx)
            push @route_before_mw, $route->{before};
            push @route_after_mw, $route->{after};
        }
        $self->{_route_before_mw} = \@route_before_mw;
        $self->{_route_after_mw} = \@route_after_mw;
    }

    # Generate C code with pure C event loop
    my $c_code = $self->_generate_server_code(\@full_responses);

    # Compile via XS::JIT
    my $module_name = 'Hypersonic::_Server_' . $self->{id};
    
    # Build compile options - add TLS flags if enabled
    my %compile_opts = (
        code      => $c_code,
        name      => $module_name,
        cache_dir => $self->{cache_dir},
        functions => {
            "${module_name}::run_event_loop" => {
                source       => 'hypersonic_run_event_loop',
                is_xs_native => 1,
            },
            "${module_name}::dispatch" => {
                source       => 'hypersonic_dispatch',
                is_xs_native => 1,
            },
        },
    );
    
    # Add OpenSSL flags for TLS support
    if ($self->{tls}) {
        $compile_opts{extra_cflags} = Hypersonic::TLS::get_extra_cflags();
        $compile_opts{extra_ldflags} = Hypersonic::TLS::get_extra_ldflags();
    }
    
    # Add zlib flags for compression support
    if ($self->{_compression_enabled}) {
        require Hypersonic::Compress;
        my ($cflags, $ldflags) = Hypersonic::Compress::get_zlib_flags();
        $compile_opts{extra_cflags} = ($compile_opts{extra_cflags} // '') . " $cflags";
        $compile_opts{extra_ldflags} = ($compile_opts{extra_ldflags} // '') . " $ldflags";
    }

    XS::JIT->compile(%compile_opts);

    # Store function references
    {
        no strict 'refs';
        $self->{run_loop_fn} = \&{"${module_name}::run_event_loop"};
        $self->{dispatch_fn} = \&{"${module_name}::dispatch"};
    }

    $self->{compiled} = 1;
    return $self;
}

sub _generate_server_code {
    my ($self, $full_responses) = @_;

    my $backend = Hypersonic::Socket::event_backend();
    my $builder = XS::JIT::Builder->new;

    # Check if we have any dynamic routes
    my $has_dynamic = grep { $_->{dynamic} } @{$self->{routes}};

    # Includes
    $builder->line('#include <string.h>')
      ->line('#include <unistd.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <sys/types.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <netinet/tcp.h>');

    if ($backend eq 'kqueue') {
        $builder->line('#include <sys/event.h>');
    } else {
        $builder->line('#include <sys/epoll.h>');
    }
    
    # Add signal and time headers for graceful shutdown
    $builder->line('#include <signal.h>')
      ->line('#include <time.h>');
    
    # Compression support - include zlib if compression is enabled
    if ($self->{_compression_enabled}) {
        $builder->line('#include <zlib.h>')
          ->line('#define HYPERSONIC_COMPRESSION 1');
    }
    
    # TLS support - include OpenSSL headers if TLS is enabled
    if ($self->{tls}) {
        $builder->raw(Hypersonic::TLS::gen_includes())
          ->line('#define HYPERSONIC_TLS 1');
    }

    # Security hardening configuration
    my $max_connections = $self->{max_connections};
    my $max_request_size = $self->{max_request_size};
    my $keepalive_timeout = $self->{keepalive_timeout};
    my $recv_timeout = $self->{recv_timeout};
    my $drain_timeout = $self->{drain_timeout};

    $builder->blank
      ->line('#define MAX_EVENTS 1024')
      ->line("#define RECV_BUF_SIZE $max_request_size")
      ->line("#define MAX_CONNECTIONS $max_connections");
    
    # Enable security headers macro if configured
    if ($self->{enable_security_headers} && $has_dynamic) {
        $builder->line('#define HYPERSONIC_SECURITY_HEADERS 1');
    }
    
    $builder
      ->line("#define KEEPALIVE_TIMEOUT $keepalive_timeout")
      ->line("#define RECV_TIMEOUT $recv_timeout")
      ->line("#define DRAIN_TIMEOUT $drain_timeout")
      ->blank;
    
    # TLS-aware I/O macros - compile-time decision, zero runtime overhead
    $builder->comment('TLS-aware I/O wrappers - compile-time branching')
      ->line('#ifdef HYPERSONIC_TLS')
      ->line('#define HYPERSONIC_SEND(fd, buf, len) do { \\')
      ->line('    TLSConnection* _tc = get_tls_connection(fd); \\')
      ->line('    if (_tc) tls_send(_tc, buf, len); \\')
      ->line('    else send(fd, buf, len, 0); \\')
      ->line('} while(0)')
      ->line('#define HYPERSONIC_CLOSE(fd) tls_close(fd)')
      ->line('#else')
      ->line('#define HYPERSONIC_SEND(fd, buf, len) send(fd, buf, len, 0)')
      ->line('#define HYPERSONIC_CLOSE(fd) close(fd)')
      ->line('#endif')
      ->blank;

    # Graceful shutdown support
    $builder->comment('Graceful shutdown support')
      ->line('static volatile sig_atomic_t g_shutdown = 0;')
      ->line('static volatile int g_active_connections = 0;')
      ->blank
      ->line('static void handle_shutdown_signal(int sig) {')
      ->line('    (void)sig;')
      ->line('    g_shutdown = 1;')
      ->line('}')
      ->blank;
    
    # Compression support - JIT compiled zlib functions
    if ($self->{_compression_enabled}) {
        my $config = $self->{_compression_config};
        my $min_size = $config->{min_size} // 1024;
        my $level = $config->{level} // 6;
        
        $builder->comment('Gzip compression support - JIT compiled')
          ->line('static __thread unsigned char gzip_out_buf[131072];')
          ->blank
          ->line('static int accepts_gzip(const char* accept_encoding, size_t len) {')
          ->line('    if (!accept_encoding || len == 0) return 0;')
          ->line('    const char* p = accept_encoding;')
          ->line('    const char* end = accept_encoding + len;')
          ->line('    while (p < end - 3) {')
          ->line('        if (p[0] == \'g\' && p[1] == \'z\' && p[2] == \'i\' && p[3] == \'p\') return 1;')
          ->line('        p++;')
          ->line('    }')
          ->line('    return 0;')
          ->line('}')
          ->blank
          ->line('static size_t gzip_compress(const char* input, size_t input_len, unsigned char** output) {')
          ->line("    if (input_len < $min_size) return 0;")
          ->line('    size_t max_out = compressBound(input_len) + 18;')
          ->line('    if (max_out > sizeof(gzip_out_buf)) return 0;')
          ->line('    z_stream strm;')
          ->line('    memset(&strm, 0, sizeof(strm));')
          ->line("    if (deflateInit2(&strm, $level, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) return 0;")
          ->line('    strm.next_in = (Bytef*)input;')
          ->line('    strm.avail_in = input_len;')
          ->line('    strm.next_out = gzip_out_buf;')
          ->line('    strm.avail_out = sizeof(gzip_out_buf);')
          ->line('    int ret = deflate(&strm, Z_FINISH);')
          ->line('    size_t compressed_len = strm.total_out;')
          ->line('    deflateEnd(&strm);')
          ->line('    if (ret != Z_STREAM_END || compressed_len >= input_len) return 0;')
          ->line('    *output = gzip_out_buf;')
          ->line('    return compressed_len;')
          ->line('}')
          ->blank;
    }
    
    # Connection tracking for keep-alive timeout - O(1) using fd as index
    $builder->comment('Connection tracking - O(1) using fd as direct index')
      ->line('#define MAX_FD 65536')
      ->line('static time_t g_conn_time[MAX_FD];')
      ->line('static time_t g_current_time = 0;')
      ->blank
      ->line('static inline void track_connection(int fd, time_t now) {')
      ->line('    if (fd >= 0 && fd < MAX_FD) {')
      ->line('        g_conn_time[fd] = now;')
      ->line('        g_active_connections++;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('static inline void update_connection(int fd, time_t now) {')
      ->line('    if (fd >= 0 && fd < MAX_FD) {')
      ->line('        g_conn_time[fd] = now;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line('static inline void remove_connection(int fd) {')
      ->line('    if (fd >= 0 && fd < MAX_FD && g_conn_time[fd] > 0) {')
      ->line('        g_conn_time[fd] = 0;')
      ->line('        g_active_connections--;')
      ->line('    }')
      ->line('}')
      ->blank;

    # TLS code generation - SSL context, accept, read/write wrappers
    if ($self->{tls}) {
        $builder->comment('TLS/HTTPS support via OpenSSL')
          ->raw(Hypersonic::TLS::gen_ssl_ctx_init())
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_accept())
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_io())
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_close())
          ->blank;
    }

    # Global storage for dynamic handler dispatch (only if needed)
    if ($has_dynamic) {
        $builder->comment('Storage for dynamic handler callbacks')
          ->line('static SV* g_handler_array = NULL;')
          ->line('static SV* g_server_obj = NULL;');
        
        # JIT: Only generate middleware storage if middleware is present
        my $analysis = $self->{route_analysis};
        if ($analysis->{has_any_middleware}) {
            $builder->line('static SV* g_before_middleware = NULL;')
              ->line('static SV* g_after_middleware = NULL;')
              ->line('static SV* g_route_before_middleware = NULL;')
              ->line('static SV* g_route_after_middleware = NULL;');
        }
        $builder->blank;
        
        # Generate param info table for named path parameters
        # Structure: { param_name, segment_position } per handler
        $builder->comment('Path parameter info per dynamic handler')
          ->line('typedef struct { const char* name; int position; } ParamInfo;')
          ->line('typedef struct { int count; ParamInfo params[8]; } RouteParamInfo;')
          ->blank;
        
        my @route_params = @{$self->{route_param_info} // []};
        my $handler_count = scalar @route_params;
        
        $builder->line("static RouteParamInfo g_route_params[$handler_count] = {");
        for my $i (0 .. $#route_params) {
            my $params = $route_params[$i] // [];
            my $count = scalar @$params;
            my @param_strs;
            for my $p (@$params) {
                push @param_strs, qq({ "$p->{name}", $p->{position} });
            }
            # Pad to 8 elements with {NULL, 0}
            my $padding = 8 - scalar(@param_strs);
            for (1 .. $padding) {
                push @param_strs, '{NULL, 0}';
            }
            my $params_str = join(', ', @param_strs);
            $builder->line("    { $count, { $params_str } },");
        }
        $builder->line('};')
          ->blank;
    }

    # Emit FULL pre-computed HTTP responses (headers + body)
    for my $i (0 .. $#$full_responses) {
        my $resp = $full_responses->[$i];
        my $escaped = _escape_c_string($resp);
        my $len = length($resp);
        $builder->line("static const char RESP_$i\[] = \"$escaped\";")
          ->line("static const int RESP_${i}_LEN = $len;");
    }
    $builder->blank;

    # 404 response with security headers
    my $resp_404 = "HTTP/1.1 404 Not Found\r\n"
                 . "Content-Type: text/plain\r\n"
                 . "Content-Length: 9\r\n"
                 . "Connection: close\r\n";
    $resp_404 .= $self->_get_security_headers_string() if $self->{enable_security_headers};
    $resp_404 .= "\r\n" . "Not Found";
    
    my $escaped_404 = _escape_c_string($resp_404);
    $builder->line("static const char RESP_404[] = \"$escaped_404\";")
      ->line("static const int RESP_404_LEN = " . length($resp_404) . ";")
      ->blank;
    
    # Security headers constant for dynamic responses
    if ($self->{enable_security_headers} && $has_dynamic) {
        $builder->raw($self->_gen_security_headers_c_constant())
          ->blank;
    }

    # Generate dynamic handler caller if needed
    if ($has_dynamic) {
        $builder->raw($self->_gen_dynamic_handler_caller())
          ->blank;
    }

    # Group routes by method for dispatch generation
    my %methods;
    for my $route (@{$self->{routes}}) {
        push @{$methods{$route->{method}}}, $route;
    }

    # Generate inline C dispatch function
    $builder->comment('Inline dispatch - returns response pointer and length')
      ->comment('For dynamic routes: returns handler_idx in *handler_idx_out, sets *resp_out to NULL')
      ->line('static inline int dispatch_request(const char* method, int method_len, const char* path, int path_len, const char** resp_out, int* resp_len_out, int* handler_idx_out) {')
      ->line('    *handler_idx_out = -1;');

    for my $method (sort keys %methods) {
        my $mlen = length($method);
        $builder->if("method_len == $mlen && memcmp(method, \"$method\", $mlen) == 0");

        for my $r (@{$methods{$method}}) {
            my $path = $r->{path};
            my $plen = length($path);

            if (!$r->{dynamic}) {
                # Static route - return pre-computed response
                my $escaped_path = _escape_c_string($path);
                my $idx = $r->{response_idx};

                $builder->if("path_len == $plen && memcmp(path, \"$escaped_path\", $plen) == 0")
                  ->line("*resp_out = RESP_$idx;")
                  ->line("*resp_len_out = RESP_${idx}_LEN;")
                  ->line("return 0;")
                  ->endif;
            } else {
                # Dynamic route - check for path params or exact match
                my $handler_idx = $r->{handler_idx};

                if ($path =~ /:(\w+)/) {
                    # Path has parameters - generate pattern matching
                    my ($prefix) = $path =~ m{^([^:]+)};
                    my $prefix_len = length($prefix);
                    my $escaped_prefix = _escape_c_string($prefix);

                    $builder->if("path_len >= $prefix_len && memcmp(path, \"$escaped_prefix\", $prefix_len) == 0")
                      ->line("*resp_out = NULL;")
                      ->line("*handler_idx_out = $handler_idx;")
                      ->line("return 1;")
                      ->endif;
                } else {
                    # Exact match dynamic route
                    my $escaped_path = _escape_c_string($path);
                    $builder->if("path_len == $plen && memcmp(path, \"$escaped_path\", $plen) == 0")
                      ->line("*resp_out = NULL;")
                      ->line("*handler_idx_out = $handler_idx;")
                      ->line("return 1;")
                      ->endif;
                }
            }
        }

        $builder->endif;
    }

    $builder->line('*resp_out = RESP_404;')
      ->line('*resp_len_out = RESP_404_LEN;')
      ->line('return -1;')
      ->line('}')
      ->blank;

    # Generate the pure C event loop (pass Builder directly)
    if ($backend eq 'kqueue') {
        $self->_gen_event_loop_kqueue($builder);
    } else {
        $self->_gen_event_loop_epoll($builder);
    }
    $builder->blank;

    # Keep the Perl-callable dispatch for testing/compatibility
    $builder->comment('Perl-callable dispatch wrapper')
      ->xs_function('hypersonic_dispatch')
      ->xs_preamble
      ->line('if (items != 1) croak_xs_usage(cv, "req_ref");')
      ->declare_sv('req_ref', 'ST(0)')
      ->if('!SvROK(req_ref) || SvTYPE(SvRV(req_ref)) != SVt_PVAV')
        ->line('ST(0) = &PL_sv_undef;')
        ->line('XSRETURN(1);')
      ->endif
      ->declare_av('req', '(AV*)SvRV(req_ref)')
      ->line('SV** ary = AvARRAY(req);')
      ->line('STRLEN method_len, path_len;')
      ->line('const char* method = SvPV(ary[0], method_len);')
      ->line('const char* path = SvPV(ary[1], path_len);')
      ->line('const char* resp;')
      ->line('int resp_len;')
      ->line('int handler_idx;')
      ->line('int rc = dispatch_request(method, (int)method_len, path, (int)path_len, &resp, &resp_len, &handler_idx);')
      ->if('rc == 0')
        ->comment('Static route')
        ->line('ST(0) = sv_2mortal(newSVpvn(resp, resp_len));')
      ->elsif('rc == 1')
        ->comment('Dynamic route - for testing, just return undef')
        ->line('ST(0) = &PL_sv_undef;')
      ->else
        ->line('ST(0) = &PL_sv_undef;')
      ->endif
      ->xs_return('1')
      ->xs_end;

    return $builder->code;
}

# Generate optimized method parser using Builder API
sub _gen_method_parser {
    my ($self, $builder) = @_;
    my $analysis = $self->{route_analysis};
    my %methods_used = %{$analysis->{methods_used}};

    # Method lengths: GET=3, PUT=3, POST=4, HEAD=4, PATCH=5, DELETE=6, OPTIONS=7
    my %method_lens = (
        GET => 3, PUT => 3, POST => 4, HEAD => 4,
        PATCH => 5, DELETE => 6, OPTIONS => 7
    );

    # Group methods by length
    my %by_length;
    for my $method (keys %methods_used) {
        my $len = $method_lens{$method} // length($method);
        push @{$by_length{$len}}, $method;
    }

    # If single method, generate super-optimized check
    if ($analysis->{single_method}) {
        my $method = $analysis->{single_method};
        my $len = $method_lens{$method};
        my $first_char = substr($method, 0, 1);
        my $path_offset = $len + 1;

        $builder->comment("OPTIMIZED: Single method ($method) - verify first char only")
          ->line('const char* method = recv_buf;')
          ->line("int method_len = $len;")
          ->line("const char* path = recv_buf + $path_offset;")
          ->blank
          ->comment("Quick validation: first char must be '$first_char'")
          ->if("recv_buf[0] != '$first_char'")
            ->line('HYPERSONIC_SEND(fd, RESP_404, RESP_404_LEN);')
            ->line('continue;')
          ->endif;

        return $builder;
    }

    # Multiple methods - generate only the length checks we need
    $builder->comment('OPTIMIZED: Only check for methods actually used')
      ->line('const char* method = recv_buf;')
      ->line('int method_len;')
      ->line('const char* path;')
      ->blank;

    my $first = 1;
    for my $len (sort { $a <=> $b } keys %by_length) {
        my @methods_at_len = @{$by_length{$len}};
        my $comment = join(', ', @methods_at_len);
        my $path_offset = $len + 1;

        if ($first) {
            $builder->if("recv_buf[$len] == ' '");
            $first = 0;
        } else {
            $builder->elsif("recv_buf[$len] == ' '");
        }
        $builder->line("method_len = $len;  /* $comment */")
          ->line("path = recv_buf + $path_offset;");
    }

    # Add fallback for unknown methods
    $builder->else
      ->comment('Fallback for unknown methods')
      ->line('const char* sp = recv_buf;')
      ->while('*sp && *sp != \' \'')
        ->line('sp++;')
      ->endwhile
      ->line('method_len = sp - recv_buf;')
      ->line('path = sp + 1;')
    ->endif;

    return $builder;
}

sub _gen_event_loop_kqueue {
    my ($self, $builder) = @_;
    my $has_dynamic = grep { $_->{dynamic} } @{$self->{routes}};
    my $analysis = $self->{route_analysis};
    my $has_body_access = $analysis->{has_body_access} // 0;

    $builder->comment('Pure C event loop using kqueue - WITH SECURITY HARDENING')
      ->xs_function('hypersonic_run_event_loop')
      ->xs_preamble
      ->check_items(2, 2, 'listen_fd, server_obj')
      ->blank
      ->declare('int', 'listen_fd', '(int)SvIV(ST(0))')
      ->declare_sv('server_obj', 'ST(1)')
      ->blank;

    # Handler storage (only if dynamic routes)
    if ($has_dynamic) {
        $builder->comment('Store server object for dynamic handler access')
          ->if('SvROK(server_obj)')
            ->declare_hv('self', '(HV*)SvRV(server_obj)')
            ->line('SV** handlers_ref = hv_fetch(self, "dynamic_handlers", 16, 0);')
            ->if('handlers_ref && SvROK(*handlers_ref)')
              ->line('g_handler_array = *handlers_ref;')
              ->line('SvREFCNT_inc(g_handler_array);')
            ->endif
            ->line('g_server_obj = server_obj;')
            ->line('SvREFCNT_inc(g_server_obj);');
        
        # JIT: Only fetch middleware if any middleware is present
        if ($analysis->{has_any_middleware}) {
            $builder->blank
              ->comment('JIT: Middleware storage (middleware detected)')
              ->line('SV** before_ref = hv_fetch(self, "before_middleware", 17, 0);')
              ->if('before_ref && SvROK(*before_ref)')
                ->line('g_before_middleware = *before_ref;')
                ->line('SvREFCNT_inc(g_before_middleware);')
              ->endif
              ->line('SV** after_ref = hv_fetch(self, "after_middleware", 16, 0);')
              ->if('after_ref && SvROK(*after_ref)')
                ->line('g_after_middleware = *after_ref;')
                ->line('SvREFCNT_inc(g_after_middleware);')
              ->endif;
            
            # Per-route middleware arrays
            if ($analysis->{has_route_middleware}) {
                $builder->line('SV** route_before_ref = hv_fetch(self, "_route_before_mw", 16, 0);')
                  ->if('route_before_ref && SvROK(*route_before_ref)')
                    ->line('g_route_before_middleware = *route_before_ref;')
                    ->line('SvREFCNT_inc(g_route_before_middleware);')
                  ->endif
                  ->line('SV** route_after_ref = hv_fetch(self, "_route_after_mw", 15, 0);')
                  ->if('route_after_ref && SvROK(*route_after_ref)')
                    ->line('g_route_after_middleware = *route_after_ref;')
                    ->line('SvREFCNT_inc(g_route_after_middleware);')
                  ->endif;
            }
        }
        
        $builder->endif;
    } else {
        $builder->line('(void)server_obj;  /* Not needed for static-only routes */');
    }
    $builder->blank;

    # Signal handlers and initialization
    $builder->comment('Setup graceful shutdown signal handlers')
      ->line('signal(SIGTERM, handle_shutdown_signal);')
      ->line('signal(SIGINT, handle_shutdown_signal);')
      ->blank
      ->comment('Initialize connection tracking')
      ->line('memset(g_conn_time, 0, sizeof(g_conn_time));')
      ->line('g_active_connections = 0;')
      ->blank;
    
    # TLS initialization
    if ($self->{tls}) {
        my $cert_file = _escape_c_string($self->{cert_file});
        my $key_file = _escape_c_string($self->{key_file});
        $builder->comment('Initialize TLS/HTTPS')
          ->line('#ifdef HYPERSONIC_TLS')
          ->line("if (init_ssl_ctx(\"$cert_file\", \"$key_file\") != 0) {")
          ->line('    croak("Failed to initialize TLS context - check cert/key files");')
          ->line('}')
          ->line('memset(g_tls_connections, 0, sizeof(g_tls_connections));')
          ->line('#endif')
          ->blank;
    }
    
    $builder->comment('Thread-local receive buffer - each worker gets its own')
      ->line('static __thread char recv_buf[RECV_BUF_SIZE];')
      ->blank;

    # kqueue setup
    $builder->line('int kq = kqueue();')
      ->if('kq < 0')
        ->line('croak("kqueue() failed");')
      ->endif
      ->blank
      ->line('struct kevent ev;')
      ->blank
      ->comment('Add listen socket')
      ->line('EV_SET(&ev, listen_fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);')
      ->if('kevent(kq, &ev, 1, NULL, 0, NULL) < 0')
        ->line('close(kq);')
        ->line('croak("kevent() failed to add listen socket");')
      ->endif
      ->blank
      ->line('struct kevent events[MAX_EVENTS];')
      ->line('time_t last_cleanup = time(NULL);')
      ->line('int accepting = 1;  /* Flag to control accepting new connections */')
      ->blank;

    # Main event loop
    $builder->while('!g_shutdown || g_active_connections > 0')
        ->comment('Use timeout for keep-alive cleanup and shutdown check')
        ->line('struct timespec timeout = { 1, 0 };  /* 1 second */')
        ->line('int n = kevent(kq, NULL, 0, events, MAX_EVENTS, &timeout);')
        ->blank
        ->if('n < 0')
          ->if('errno == EINTR')
            ->line('continue;')
          ->endif
          ->line('break;')
        ->endif
        ->blank
        ->comment('Check for graceful shutdown - stop accepting new connections')
        ->if('g_shutdown && accepting')
          ->line('EV_SET(&ev, listen_fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);')
          ->line('kevent(kq, &ev, 1, NULL, 0, NULL);')
          ->line('accepting = 0;')
        ->endif
        ->blank
        ->comment('Get time once per event batch')
        ->line('time_t now = time(NULL);')
        ->line('g_current_time = now;')
        ->blank;

    # Keep-alive cleanup
    $builder->comment('Periodic keep-alive timeout cleanup')
      ->if('now - last_cleanup >= 5')
        ->declare('int', 'i', '0')
        ->for('i = 0', 'i < MAX_FD', 'i++')
          ->if('g_conn_time[i] > 0')
            ->if('now - g_conn_time[i] > KEEPALIVE_TIMEOUT')
              ->comment('Close idle connection')
              ->line('int idle_fd = i;')
              ->line('EV_SET(&ev, idle_fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);')
              ->line('kevent(kq, &ev, 1, NULL, 0, NULL);')
              ->line('HYPERSONIC_CLOSE(idle_fd);')
              ->line('remove_connection(idle_fd);')
            ->endif
          ->endif
        ->endfor
        ->line('last_cleanup = now;')
      ->endif
      ->blank;

    # Event processing loop
    $builder->declare('int', 'i', '0')
      ->for('i = 0', 'i < n', 'i++')
        ->line('int fd = (int)events[i].ident;')
        ->blank
        ->if('fd == listen_fd && accepting');

    # Accept loop
    $builder->comment('Accept new connections with limit check')
      ->while('1')
        ->comment('Check connection limit before accepting')
        ->if('g_active_connections >= MAX_CONNECTIONS')
          ->line('break;  /* At capacity, stop accepting */')
        ->endif
        ->blank
        ->line('struct sockaddr_in client_addr;')
        ->line('socklen_t client_len = sizeof(client_addr);')
        ->line('int client_fd = accept(listen_fd, (struct sockaddr*)&client_addr, &client_len);')
        ->if('client_fd < 0')
          ->line('break;')
        ->endif
        ->blank
        ->comment('Set non-blocking')
        ->line('int flags = fcntl(client_fd, F_GETFL, 0);')
        ->line('fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);')
        ->blank
        ->comment('Disable Nagle')
        ->line('int one = 1;')
        ->line('setsockopt(client_fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));')
        ->blank
        ->comment('Set receive timeout for security')
        ->line('struct timeval tv;')
        ->line('tv.tv_sec = RECV_TIMEOUT;')
        ->line('tv.tv_usec = 0;')
        ->line('setsockopt(client_fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));')
        ->blank
        ->comment('Track connection for keep-alive timeout')
        ->line('track_connection(client_fd, now);')
        ->blank
        ->comment('TLS handshake if enabled')
        ->line('#ifdef HYPERSONIC_TLS')
        ->line('if (tls_accept(client_fd) < 0) {')
        ->line('    close(client_fd);')
        ->line('    remove_connection(client_fd);')
        ->line('    continue;')
        ->line('}')
        ->line('#endif')
        ->blank
        ->comment('Add to kqueue')
        ->line('EV_SET(&ev, client_fd, EVFILT_READ, EV_ADD | EV_ENABLE, 0, 0, NULL);')
        ->line('kevent(kq, &ev, 1, NULL, 0, NULL);')
      ->endwhile;

    # Handle client request
    $builder->elsif('fd != listen_fd')
      ->comment('Handle client request')
      ->line('#ifdef HYPERSONIC_TLS')
      ->line('TLSConnection* tls_conn = get_tls_connection(fd);')
      ->line('ssize_t len = tls_conn ? tls_recv(tls_conn, recv_buf, RECV_BUF_SIZE - 1) : -1;')
      ->line('#else')
      ->line('ssize_t len = recv(fd, recv_buf, RECV_BUF_SIZE - 1, 0);')
      ->line('#endif')
      ->blank
      ->if('len <= 0')
        ->comment('Connection closed or error')
        ->line('EV_SET(&ev, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);')
        ->line('kevent(kq, &ev, 1, NULL, 0, NULL);')
        ->line('#ifdef HYPERSONIC_TLS')
        ->line('tls_close(fd);')
        ->line('#else')
        ->line('close(fd);')
        ->line('#endif')
        ->line('remove_connection(fd);')
        ->line('continue;')
      ->endif
      ->blank
      ->comment('Update connection activity for keep-alive timeout')
      ->line('update_connection(fd, now);')
      ->blank
      ->line('recv_buf[len] = \'\\0\';')
      ->blank;

    # Method parser (uses Builder)
    $self->_gen_method_parser($builder);
    $builder->blank;

    # Path parsing - include query string for dynamic handlers to parse
    $builder->comment('Find end of path (include query string for dynamic handlers)')
      ->line('const char* path_end = path;')
      ->while('*path_end && *path_end != \' \'')
        ->line('path_end++;')
      ->endwhile
      ->line('int full_path_len = path_end - path;')
      ->blank
      ->comment('For dispatch, strip query string - routes match path only')
      ->line('const char* query_pos = memchr(path, \'?\', full_path_len);')
      ->line('int path_len = query_pos ? (query_pos - path) : full_path_len;')
      ->blank;

    # Dispatch
    $builder->comment('Dispatch request')
      ->line('const char* resp;')
      ->line('int resp_len;')
      ->line('int handler_idx;')
      ->line('int dispatch_result = dispatch_request(method, method_len, path, path_len, &resp, &resp_len, &handler_idx);')
      ->blank;

    # Dynamic dispatch
    if ($has_dynamic) {
        $builder->if('dispatch_result == 1')
          ->comment('Dynamic route - call Perl handler');

        if ($has_body_access) {
            $builder->comment('Find body in request')
              ->line('const char* body_start = strstr(recv_buf, "\\r\\n\\r\\n");')
              ->line('const char* body = "";')
              ->line('int body_len = 0;')
              ->if('body_start')
                ->line('body = body_start + 4;')
                ->line('body_len = len - (body - recv_buf);')
              ->endif;
        } else {
            $builder->comment('OPTIMIZED: No body parsing needed (GET/HEAD/DELETE only)')
              ->line('const char* body = "";')
              ->line('int body_len = 0;');
        }

        $builder->blank
          ->line('char* dyn_resp;')
          ->line('int dyn_resp_len;')
          ->line('call_dynamic_handler(aTHX_ handler_idx, method, method_len, path, full_path_len, body, body_len, recv_buf, len, &dyn_resp, &dyn_resp_len);')
          ->line('HYPERSONIC_SEND(fd, dyn_resp, dyn_resp_len);')
        ->else
          ->line('HYPERSONIC_SEND(fd, resp, resp_len);')
        ->endif;
    } else {
        $builder->line('HYPERSONIC_SEND(fd, resp, resp_len);');
    }
    $builder->blank;

    # Keep-alive check
    $builder->comment('Check for Connection: close')
      ->line('int keep_alive = 1;')
      ->if('len > 20')
        ->line('const char* conn = strstr(recv_buf + 16, "onnection:");')
        ->if('conn && (conn[-1] == \'C\' || conn[-1] == \'c\')')
          ->if('strstr(conn, "close") || strstr(conn, "Close")')
            ->line('keep_alive = 0;')
          ->endif
        ->endif
      ->endif
      ->blank
      ->if('!keep_alive')
        ->line('EV_SET(&ev, fd, EVFILT_READ, EV_DELETE, 0, 0, NULL);')
        ->line('kevent(kq, &ev, 1, NULL, 0, NULL);')
        ->line('HYPERSONIC_CLOSE(fd);')
        ->line('remove_connection(fd);')
      ->endif;

    # Close event processing
    $builder->endif  # fd == listen_fd
      ->endfor  # for i
      ->endwhile  # main loop
      ->blank
      ->line('close(kq);')
      ->xs_return('0')
      ->xs_end;

    return $builder;
}

sub _gen_event_loop_epoll {
    my ($self, $builder) = @_;
    my $has_dynamic = grep { $_->{dynamic} } @{$self->{routes}};
    my $analysis = $self->{route_analysis};
    my $has_body_access = $analysis->{has_body_access} // 0;

    $builder->comment('Pure C event loop using epoll - WITH SECURITY HARDENING')
      ->xs_function('hypersonic_run_event_loop')
      ->xs_preamble
      ->check_items(2, 2, 'listen_fd, server_obj')
      ->blank
      ->declare('int', 'listen_fd', '(int)SvIV(ST(0))')
      ->declare_sv('server_obj', 'ST(1)')
      ->blank;

    # Handler storage (only if dynamic routes)
    if ($has_dynamic) {
        $builder->comment('Store server object for dynamic handler access')
          ->if('SvROK(server_obj)')
            ->declare_hv('self', '(HV*)SvRV(server_obj)')
            ->line('SV** handlers_ref = hv_fetch(self, "dynamic_handlers", 16, 0);')
            ->if('handlers_ref && SvROK(*handlers_ref)')
              ->line('g_handler_array = *handlers_ref;')
              ->line('SvREFCNT_inc(g_handler_array);')
            ->endif
            ->line('g_server_obj = server_obj;')
            ->line('SvREFCNT_inc(g_server_obj);');
        
        # JIT: Only fetch middleware if any middleware is present
        if ($analysis->{has_any_middleware}) {
            $builder->blank
              ->comment('JIT: Middleware storage (middleware detected)')
              ->line('SV** before_ref = hv_fetch(self, "before_middleware", 17, 0);')
              ->if('before_ref && SvROK(*before_ref)')
                ->line('g_before_middleware = *before_ref;')
                ->line('SvREFCNT_inc(g_before_middleware);')
              ->endif
              ->line('SV** after_ref = hv_fetch(self, "after_middleware", 16, 0);')
              ->if('after_ref && SvROK(*after_ref)')
                ->line('g_after_middleware = *after_ref;')
                ->line('SvREFCNT_inc(g_after_middleware);')
              ->endif;
            
            # Per-route middleware arrays
            if ($analysis->{has_route_middleware}) {
                $builder->line('SV** route_before_ref = hv_fetch(self, "_route_before_mw", 16, 0);')
                  ->if('route_before_ref && SvROK(*route_before_ref)')
                    ->line('g_route_before_middleware = *route_before_ref;')
                    ->line('SvREFCNT_inc(g_route_before_middleware);')
                  ->endif
                  ->line('SV** route_after_ref = hv_fetch(self, "_route_after_mw", 15, 0);')
                  ->if('route_after_ref && SvROK(*route_after_ref)')
                    ->line('g_route_after_middleware = *route_after_ref;')
                    ->line('SvREFCNT_inc(g_route_after_middleware);')
                  ->endif;
            }
        }
        
        $builder->endif;
    } else {
        $builder->line('(void)server_obj;  /* Not needed for static-only routes */');
    }
    $builder->blank;

    # Signal handlers and initialization
    $builder->comment('Setup graceful shutdown signal handlers')
      ->line('signal(SIGTERM, handle_shutdown_signal);')
      ->line('signal(SIGINT, handle_shutdown_signal);')
      ->blank
      ->comment('Initialize connection tracking')
      ->line('memset(g_conn_time, 0, sizeof(g_conn_time));')
      ->line('g_active_connections = 0;')
      ->blank;
    
    # TLS initialization
    if ($self->{tls}) {
        my $cert_file = _escape_c_string($self->{cert_file});
        my $key_file = _escape_c_string($self->{key_file});
        $builder->comment('Initialize TLS/HTTPS')
          ->line('#ifdef HYPERSONIC_TLS')
          ->line("if (init_ssl_ctx(\"$cert_file\", \"$key_file\") != 0) {")
          ->line('    croak("Failed to initialize TLS context - check cert/key files");')
          ->line('}')
          ->line('memset(g_tls_connections, 0, sizeof(g_tls_connections));')
          ->line('#endif')
          ->blank;
    }
    
    $builder->comment('Thread-local receive buffer')
      ->line('static __thread char recv_buf[RECV_BUF_SIZE];')
      ->blank;

    # epoll setup
    $builder->line('int epoll_fd = epoll_create1(0);')
      ->if('epoll_fd < 0')
        ->line('croak("epoll_create1() failed");')
      ->endif
      ->blank
      ->line('struct epoll_event ev;')
      ->line('ev.events = EPOLLIN | EPOLLET;')
      ->line('ev.data.fd = listen_fd;')
      ->if('epoll_ctl(epoll_fd, EPOLL_CTL_ADD, listen_fd, &ev) < 0')
        ->line('close(epoll_fd);')
        ->line('croak("epoll_ctl() failed to add listen socket");')
      ->endif
      ->blank
      ->line('struct epoll_event events[MAX_EVENTS];')
      ->line('time_t last_cleanup = time(NULL);')
      ->line('int accepting = 1;  /* Flag to control accepting new connections */')
      ->blank;

    # Main event loop
    $builder->while('!g_shutdown || g_active_connections > 0')
        ->comment('Use timeout for keep-alive cleanup and shutdown check')
        ->line('int n = epoll_wait(epoll_fd, events, MAX_EVENTS, 1000);  /* 1 second timeout */')
        ->if('n < 0')
          ->if('errno == EINTR')
            ->line('continue;')
          ->endif
          ->line('break;')
        ->endif
        ->blank
        ->comment('Check for graceful shutdown - stop accepting new connections')
        ->if('g_shutdown && accepting')
          ->line('epoll_ctl(epoll_fd, EPOLL_CTL_DEL, listen_fd, NULL);')
          ->line('accepting = 0;')
        ->endif
        ->blank
        ->comment('Get time once per event batch')
        ->line('time_t now = time(NULL);')
        ->line('g_current_time = now;')
        ->blank;

    # Keep-alive cleanup
    $builder->comment('Periodic keep-alive timeout cleanup')
      ->if('now - last_cleanup >= 5')
        ->declare('int', 'i', '0')
        ->for('i = 0', 'i < MAX_FD', 'i++')
          ->if('g_conn_time[i] > 0')
            ->if('now - g_conn_time[i] > KEEPALIVE_TIMEOUT')
              ->comment('Close idle connection')
              ->line('int idle_fd = i;')
              ->line('epoll_ctl(epoll_fd, EPOLL_CTL_DEL, idle_fd, NULL);')
              ->line('HYPERSONIC_CLOSE(idle_fd);')
              ->line('remove_connection(idle_fd);')
            ->endif
          ->endif
        ->endfor
        ->line('last_cleanup = now;')
      ->endif
      ->blank;

    # Event processing loop
    $builder->declare('int', 'i', '0')
      ->for('i = 0', 'i < n', 'i++')
        ->line('int fd = events[i].data.fd;')
        ->blank
        ->if('fd == listen_fd && accepting');

    # Accept loop
    $builder->comment('Accept new connections with limit check')
      ->while('1')
        ->comment('Check connection limit before accepting')
        ->if('g_active_connections >= MAX_CONNECTIONS')
          ->line('break;  /* At capacity, stop accepting */')
        ->endif
        ->blank
        ->line('struct sockaddr_in client_addr;')
        ->line('socklen_t client_len = sizeof(client_addr);')
        ->line('int client_fd = accept(listen_fd, (struct sockaddr*)&client_addr, &client_len);')
        ->if('client_fd < 0')
          ->line('break;')
        ->endif
        ->blank
        ->comment('Set non-blocking')
        ->line('int flags = fcntl(client_fd, F_GETFL, 0);')
        ->line('fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);')
        ->blank
        ->comment('Disable Nagle')
        ->line('int one = 1;')
        ->line('setsockopt(client_fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));')
        ->blank
        ->comment('Set receive timeout for security')
        ->line('struct timeval tv;')
        ->line('tv.tv_sec = RECV_TIMEOUT;')
        ->line('tv.tv_usec = 0;')
        ->line('setsockopt(client_fd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));')
        ->blank
        ->comment('Track connection for keep-alive timeout')
        ->line('track_connection(client_fd, now);')
        ->blank
        ->comment('TLS handshake if enabled')
        ->line('#ifdef HYPERSONIC_TLS')
        ->line('if (tls_accept(client_fd) < 0) {')
        ->line('    close(client_fd);')
        ->line('    remove_connection(client_fd);')
        ->line('    continue;')
        ->line('}')
        ->line('#endif')
        ->blank
        ->comment('Add to epoll')
        ->line('ev.events = EPOLLIN | EPOLLET;')
        ->line('ev.data.fd = client_fd;')
        ->line('epoll_ctl(epoll_fd, EPOLL_CTL_ADD, client_fd, &ev);')
      ->endwhile;

    # Handle client request
    $builder->elsif('fd != listen_fd')
      ->comment('Handle client request')
      ->line('#ifdef HYPERSONIC_TLS')
      ->line('TLSConnection* tls_conn = get_tls_connection(fd);')
      ->line('ssize_t len = tls_conn ? tls_recv(tls_conn, recv_buf, RECV_BUF_SIZE - 1) : -1;')
      ->line('#else')
      ->line('ssize_t len = recv(fd, recv_buf, RECV_BUF_SIZE - 1, 0);')
      ->line('#endif')
      ->blank
      ->if('len <= 0')
        ->comment('Connection closed or error')
        ->line('epoll_ctl(epoll_fd, EPOLL_CTL_DEL, fd, NULL);')
        ->line('HYPERSONIC_CLOSE(fd);')
        ->line('remove_connection(fd);')
        ->line('continue;')
      ->endif
      ->blank
      ->comment('Update connection activity for keep-alive timeout')
      ->line('update_connection(fd, now);')
      ->blank
      ->line('recv_buf[len] = \'\\0\';')
      ->blank;

    # Method parser (uses Builder)
    $self->_gen_method_parser($builder);
    $builder->blank;

    # Path parsing - include query string for dynamic handlers to parse
    $builder->comment('Find end of path (include query string for dynamic handlers)')
      ->line('const char* path_end = path;')
      ->while('*path_end && *path_end != \' \'')
        ->line('path_end++;')
      ->endwhile
      ->line('int full_path_len = path_end - path;')
      ->blank
      ->comment('For dispatch, strip query string - routes match path only')
      ->line('const char* query_pos = memchr(path, \'?\', full_path_len);')
      ->line('int path_len = query_pos ? (query_pos - path) : full_path_len;')
      ->blank;

    # Dispatch
    $builder->comment('Dispatch request')
      ->line('const char* resp;')
      ->line('int resp_len;')
      ->line('int handler_idx;')
      ->line('int dispatch_result = dispatch_request(method, method_len, path, path_len, &resp, &resp_len, &handler_idx);')
      ->blank;

    # Dynamic dispatch
    if ($has_dynamic) {
        $builder->if('dispatch_result == 1')
          ->comment('Dynamic route - call Perl handler');

        if ($has_body_access) {
            $builder->comment('Find body in request')
              ->line('const char* body_start = strstr(recv_buf, "\\r\\n\\r\\n");')
              ->line('const char* body = "";')
              ->line('int body_len = 0;')
              ->if('body_start')
                ->line('body = body_start + 4;')
                ->line('body_len = len - (body - recv_buf);')
              ->endif;
        } else {
            $builder->comment('OPTIMIZED: No body parsing needed (GET/HEAD/DELETE only)')
              ->line('const char* body = "";')
              ->line('int body_len = 0;');
        }

        $builder->blank
          ->line('char* dyn_resp;')
          ->line('int dyn_resp_len;')
          ->line('call_dynamic_handler(aTHX_ handler_idx, method, method_len, path, full_path_len, body, body_len, recv_buf, len, &dyn_resp, &dyn_resp_len);')
          ->line('HYPERSONIC_SEND(fd, dyn_resp, dyn_resp_len);')
        ->else
          ->line('HYPERSONIC_SEND(fd, resp, resp_len);')
        ->endif;
    } else {
        $builder->line('HYPERSONIC_SEND(fd, resp, resp_len);');
    }
    $builder->blank;

    # Keep-alive check
    $builder->comment('Check for Connection: close')
      ->line('int keep_alive = 1;')
      ->if('len > 20')
        ->line('const char* conn = strstr(recv_buf + 16, "onnection:");')
        ->if('conn && (conn[-1] == \'C\' || conn[-1] == \'c\')')
          ->if('strstr(conn, "close") || strstr(conn, "Close")')
            ->line('keep_alive = 0;')
          ->endif
        ->endif
      ->endif
      ->blank
      ->if('!keep_alive')
        ->line('epoll_ctl(epoll_fd, EPOLL_CTL_DEL, fd, NULL);')
        ->line('HYPERSONIC_CLOSE(fd);')
        ->line('remove_connection(fd);')
      ->endif;

    # Close event processing
    $builder->endif  # fd == listen_fd
      ->endfor  # for i
      ->endwhile  # main loop
      ->blank
      ->line('close(epoll_fd);')
      ->xs_return('0')
      ->xs_end;

    return $builder;
}

sub _gen_dynamic_handler_caller {
    my ($self) = @_;
    
    my $analysis = $self->{route_analysis};
    my $builder = XS::JIT::Builder->new;
    
    # ============================================================
    # JIT PHILOSOPHY: Only generate code for features actually used
    # ============================================================
    
    # Status code helper - always needed for dynamic routes
    $builder->comment('Status code to text mapping')
      ->line('static const char* get_status_text(int code) {')
      ->line('    switch(code) {')
      ->line('        case 200: return "OK";')
      ->line('        case 201: return "Created";')
      ->line('        case 202: return "Accepted";')
      ->line('        case 204: return "No Content";')
      ->line('        case 301: return "Moved Permanently";')
      ->line('        case 302: return "Found";')
      ->line('        case 303: return "See Other";')
      ->line('        case 304: return "Not Modified";')
      ->line('        case 400: return "Bad Request";')
      ->line('        case 401: return "Unauthorized";')
      ->line('        case 403: return "Forbidden";')
      ->line('        case 404: return "Not Found";')
      ->line('        case 405: return "Method Not Allowed";')
      ->line('        case 408: return "Request Timeout";')
      ->line('        case 409: return "Conflict";')
      ->line('        case 413: return "Payload Too Large";')
      ->line('        case 422: return "Unprocessable Entity";')
      ->line('        case 429: return "Too Many Requests";')
      ->line('        case 500: return "Internal Server Error";')
      ->line('        case 502: return "Bad Gateway";')
      ->line('        case 503: return "Service Unavailable";')
      ->line('        default: return "Unknown";')
      ->line('    }')
      ->line('}')
      ->blank;
    
    # Path segment parser - always needed for path params
    $builder->comment('Parse path segments into array - stops at ? for query string')
      ->line('static int parse_path_segments(const char* path, int path_len,')
      ->line('                               const char** segments, int* seg_lens, int max_segs) {')
      ->line('    int count = 0;')
      ->line('    const char* start = path;')
      ->line('    const char* end = path + path_len;')
      ->line('    const char* query = memchr(path, \'?\', path_len);')
      ->line('    if (query) end = query;')
      ->line('    while (start < end && count < max_segs) {')
      ->line('        if (*start == \'/\') start++;')
      ->line('        if (start >= end) break;')
      ->line('        const char* seg_end = start;')
      ->line('        while (seg_end < end && *seg_end != \'/\') seg_end++;')
      ->line('        segments[count] = start;')
      ->line('        seg_lens[count] = seg_end - start;')
      ->line('        count++;')
      ->line('        start = seg_end;')
      ->line('    }')
      ->line('    return count;')
      ->line('}')
      ->blank;
    
    # URL decoder - only if query/form parsing needed
    if ($analysis->{needs_query} || $analysis->{needs_form}) {
        $builder->comment('JIT: URL decode helper (query/form parsing enabled)')
          ->line('static int url_decode(char* str, int len) {')
          ->line('    char* dst = str;')
          ->line('    const char* src = str;')
          ->line('    const char* end = str + len;')
          ->line('    while (src < end) {')
          ->line('        if (*src == \'%\' && src + 2 < end) {')
          ->line('            int hi = src[1];')
          ->line('            int lo = src[2];')
          ->line('            hi = (hi >= \'0\' && hi <= \'9\') ? hi - \'0\' :')
          ->line('                 (hi >= \'A\' && hi <= \'F\') ? hi - \'A\' + 10 :')
          ->line('                 (hi >= \'a\' && hi <= \'f\') ? hi - \'a\' + 10 : -1;')
          ->line('            lo = (lo >= \'0\' && lo <= \'9\') ? lo - \'0\' :')
          ->line('                 (lo >= \'A\' && lo <= \'F\') ? lo - \'A\' + 10 :')
          ->line('                 (lo >= \'a\' && lo <= \'f\') ? lo - \'a\' + 10 : -1;')
          ->line('            if (hi >= 0 && lo >= 0) {')
          ->line('                *dst++ = (char)((hi << 4) | lo);')
          ->line('                src += 3;')
          ->line('                continue;')
          ->line('            }')
          ->line('        } else if (*src == \'+\') {')
          ->line('            *dst++ = \' \';')
          ->line('            src++;')
          ->line('            continue;')
          ->line('        }')
          ->line('        *dst++ = *src++;')
          ->line('    }')
          ->line('    return dst - str;')
          ->line('}')
          ->blank;
        
        $builder->comment('JIT: Query string parser (query/form parsing enabled)')
          ->line('static void parse_query_string(pTHX_ const char* query, int query_len, HV* hv) {')
          ->line('    const char* start = query;')
          ->line('    const char* end = query + query_len;')
          ->line('    while (start < end) {')
          ->line('        const char* eq = memchr(start, \'=\', end - start);')
          ->line('        const char* amp = memchr(start, \'&\', end - start);')
          ->line('        if (!amp) amp = end;')
          ->line('        if (eq && eq < amp) {')
          ->line('            int key_len = eq - start;')
          ->line('            const char* val = eq + 1;')
          ->line('            int val_len = amp - val;')
          ->line('            char val_buf[1024];')
          ->line('            if (val_len < (int)sizeof(val_buf)) {')
          ->line('                memcpy(val_buf, val, val_len);')
          ->line('                val_len = url_decode(val_buf, val_len);')
          ->line('                hv_store(hv, start, key_len, newSVpvn(val_buf, val_len), 0);')
          ->line('            }')
          ->line('        } else if (amp > start) {')
          ->line('            hv_store(hv, start, amp - start, newSVpvn("", 0), 0);')
          ->line('        }')
          ->line('        start = amp + 1;')
          ->line('    }')
          ->line('}')
          ->blank;
    }
    
    # Header parser - only if headers/cookies/json/form needed
    if ($analysis->{needs_headers} || $analysis->{needs_cookies} || 
        $analysis->{needs_json} || $analysis->{needs_form}) {
        $builder->comment('JIT: Header parser (headers/cookies/json/form enabled)')
          ->line('static void parse_headers(pTHX_ const char* raw, int raw_len, HV* hv) {')
          ->line('    const char* line = memchr(raw, \'\\n\', raw_len);')
          ->line('    if (!line) return;')
          ->line('    line++;')
          ->line('    const char* end = raw + raw_len;')
          ->line('    while (line < end) {')
          ->line('        const char* line_end = memchr(line, \'\\r\', end - line);')
          ->line('        if (!line_end) line_end = memchr(line, \'\\n\', end - line);')
          ->line('        if (!line_end || line_end == line) break;')
          ->line('        const char* colon = memchr(line, \':\', line_end - line);')
          ->line('        if (colon) {')
          ->line('            int name_len = colon - line;')
          ->line('            const char* value = colon + 1;')
          ->line('            while (value < line_end && (*value == \' \' || *value == \'\\t\')) value++;')
          ->line('            int value_len = line_end - value;')
          ->line('            char name_buf[128];')
          ->line('            if (name_len < (int)sizeof(name_buf)) {')
          ->line('                int i;')
          ->line('                for (i = 0; i < name_len; i++) {')
          ->line('                    char c = line[i];')
          ->line('                    name_buf[i] = (c >= \'A\' && c <= \'Z\') ? c + 32 : (c == \'-\') ? \'_\' : c;')
          ->line('                }')
          ->line('                hv_store(hv, name_buf, name_len, newSVpvn(value, value_len), 0);')
          ->line('            }')
          ->line('        }')
          ->line('        line = line_end;')
          ->line('        if (*line == \'\\r\') line++;')
          ->line('        if (line < end && *line == \'\\n\') line++;')
          ->line('    }')
          ->line('}')
          ->blank;
    }
    
    # JIT: Generate middleware helper function BEFORE call_dynamic_handler
    if ($analysis->{has_any_middleware}) {
        $builder->comment('JIT: Middleware helper - call array of handlers, short-circuit on defined return')
          ->line('static SV* call_middleware_chain(pTHX_ AV* handlers, SV* req_ref) {')
          ->line('    dSP;')
          ->line('    SSize_t len = av_len(handlers) + 1;')
          ->line('    SSize_t i;')
          ->line('    for (i = 0; i < len; i++) {')
          ->line('        SV** handler_sv = av_fetch(handlers, i, 0);')
          ->line('        if (!handler_sv || !SvROK(*handler_sv)) continue;')
          ->line('        PUSHMARK(SP);')
          ->line('        XPUSHs(req_ref);')
          ->line('        PUTBACK;')
          ->line('        int count = call_sv(*handler_sv, G_SCALAR | G_EVAL);')
          ->line('        SPAGAIN;')
          ->line('        if (SvTRUE(ERRSV)) {')
          ->line('            POPs;')
          ->line('            continue;')
          ->line('        }')
          ->line('        if (count == 1) {')
          ->line('            SV* result = POPs;')
          ->line('            PUTBACK;')
          ->line('            if (SvOK(result)) {')
          ->line('                return SvREFCNT_inc(result);')
          ->line('            }')
          ->line('        }')
          ->line('        PUTBACK;')
          ->line('    }')
          ->line('    return NULL;')
          ->line('}')
          ->blank;
    }
    
    # Main handler function
    $builder->comment('Call dynamic Perl handler and format HTTP response')
      ->line('static void call_dynamic_handler(pTHX_ int handler_idx,')
      ->line('                                  const char* method, int method_len,')
      ->line('                                  const char* path, int path_len,')
      ->line('                                  const char* body, int body_len,')
      ->line('                                  const char* raw_request, int raw_request_len,')
      ->line('                                  char** resp_out, int* resp_len_out) {')
      ->line('    dSP;')
      ->line('    int count;')
      ->line('    SV* result;')
      ->line('    STRLEN len;')
      ->line('    const char* body_str;')
      ->line('    int status = 200;')
      ->line('    const char* content_type = "text/plain";')
      ->blank
      ->line('    if (!g_handler_array) {')
      ->line('        *resp_out = (char*)RESP_404;')
      ->line('        *resp_len_out = RESP_404_LEN;')
      ->line('        return;')
      ->line('    }')
      ->blank
      ->line('    AV* handlers = (AV*)SvRV(g_handler_array);')
      ->line('    SV** handler_sv = av_fetch(handlers, handler_idx, 0);')
      ->line('    if (!handler_sv || !SvROK(*handler_sv)) {')
      ->line('        *resp_out = (char*)RESP_404;')
      ->line('        *resp_len_out = RESP_404_LEN;')
      ->line('        return;')
      ->line('    }')
      ->blank;
    
    # Query string separation
    $builder->comment('Separate path from query string')
      ->line('    const char* query_start = memchr(path, \'?\', path_len);')
      ->line('    int clean_path_len = query_start ? (query_start - path) : path_len;')
      ->blank
      ->comment('Build array-based request object (JIT slots)')
      ->comment('Slot layout: METHOD=0, PATH=1, BODY=2, PARAMS=3, QUERY=4, QUERY_STRING=5,')
      ->comment('             HEADERS=6, COOKIES=7, JSON=8, FORM=9, SEGMENTS=10, ID=11')
      ->line('    AV* req = newAV();')
      ->line('    av_extend(req, 11);')  # Pre-allocate 12 slots (0-11)
      ->line('    av_store(req, 0, newSVpvn(method, method_len));')       # SLOT_METHOD
      ->line('    av_store(req, 1, newSVpvn(path, clean_path_len));')     # SLOT_PATH
      ->line('    av_store(req, 2, newSVpvn(body, body_len));')           # SLOT_BODY
      ->blank;

    # Path segments and params - always needed
    $builder->comment('Parse path segments and named params')
      ->line('    const char* segments[16];')
      ->line('    int seg_lens[16];')
      ->line('    int seg_count = parse_path_segments(path, path_len, segments, seg_lens, 16);')
      ->line('    AV* seg_av = newAV();')
      ->line('    int i;')
      ->line('    for (i = 0; i < seg_count; i++) {')
      ->line('        av_push(seg_av, newSVpvn(segments[i], seg_lens[i]));')
      ->line('    }')
      ->line('    av_store(req, 10, newRV_noinc((SV*)seg_av));')  # SLOT_SEGMENTS
      ->blank
      ->comment('Build named params from route_param_info table')
      ->line('    HV* params_hv = newHV();')
      ->line('    RouteParamInfo* param_info = &g_route_params[handler_idx];')
      ->line('    for (i = 0; i < param_info->count && i < seg_count; i++) {')
      ->line('        int pos = param_info->params[i].position;')
      ->line('        if (pos < seg_count) {')
      ->line('            hv_store(params_hv, param_info->params[i].name,')
      ->line('                     strlen(param_info->params[i].name),')
      ->line('                     newSVpvn(segments[pos], seg_lens[pos]), 0);')
      ->line('        }')
      ->line('    }')
      ->line('    av_store(req, 3, newRV_noinc((SV*)params_hv));')  # SLOT_PARAMS
      ->line('    if (seg_count > 0) {')
      ->line('        av_store(req, 11, newSVpvn(segments[seg_count-1], seg_lens[seg_count-1]));')  # SLOT_ID
      ->line('    } else {')
      ->line('        av_store(req, 11, newSVpvn("", 0));')  # SLOT_ID (empty)
      ->line('    }')
      ->blank;
    
    # Query string parsing - JIT conditional
    if ($analysis->{needs_query}) {
        $builder->comment('JIT: Parse query string (parse_query enabled)')
          ->line('    if (query_start) {')
          ->line('        HV* query_hv = newHV();')
          ->line('        int query_len = path_len - (query_start - path) - 1;')
          ->line('        parse_query_string(aTHX_ query_start + 1, query_len, query_hv);')
          ->line('        av_store(req, 4, newRV_noinc((SV*)query_hv));')  # SLOT_QUERY
          ->line('        av_store(req, 5, newSVpvn(query_start + 1, query_len));')  # SLOT_QUERY_STRING
          ->line('    } else {')
          ->line('        av_store(req, 4, newRV_noinc((SV*)newHV()));')  # SLOT_QUERY
          ->line('        av_store(req, 5, newSVpvn("", 0));')  # SLOT_QUERY_STRING
          ->line('    }')
          ->blank;
    } else {
        $builder->comment('JIT: Query parsing SKIPPED (no routes use parse_query)')
          ->line('    av_store(req, 4, newRV_noinc((SV*)newHV()));')  # SLOT_QUERY
          ->line('    av_store(req, 5, newSVpvn("", 0));')  # SLOT_QUERY_STRING
          ->blank;
    }
    
    # Header parsing - JIT conditional
    my $needs_header_parse = $analysis->{needs_headers} || $analysis->{needs_cookies} ||
                             $analysis->{needs_json} || $analysis->{needs_form};
    
    if ($needs_header_parse) {
        $builder->comment('JIT: Parse headers (headers/cookies/json/form enabled)')
          ->line('    HV* headers_hv = newHV();')
          ->line('    parse_headers(aTHX_ raw_request, raw_request_len, headers_hv);')
          ->line('    av_store(req, 6, newRV_noinc((SV*)headers_hv));')  # SLOT_HEADERS
          ->blank;
        
        # Cookie parsing
        if ($analysis->{needs_cookies}) {
            $builder->comment('JIT: Parse cookies (parse_cookies enabled)')
              ->line('    SV** cookie_sv = hv_fetch(headers_hv, "cookie", 6, 0);')
              ->line('    if (cookie_sv && SvOK(*cookie_sv)) {')
              ->line('        HV* cookies_hv = newHV();')
              ->line('        STRLEN cookie_len;')
              ->line('        const char* cookie_str = SvPV(*cookie_sv, cookie_len);')
              ->line('        const char* start = cookie_str;')
              ->line('        const char* end = cookie_str + cookie_len;')
              ->line('        while (start < end) {')
              ->line('            while (start < end && (*start == \' \' || *start == \';\')) start++;')
              ->line('            if (start >= end) break;')
              ->line('            const char* eq = memchr(start, \'=\', end - start);')
              ->line('            const char* semi = memchr(start, \';\', end - start);')
              ->line('            if (!semi) semi = end;')
              ->line('            if (eq && eq < semi) {')
              ->line('                int name_len = eq - start;')
              ->line('                const char* val = eq + 1;')
              ->line('                int val_len = semi - val;')
              ->line('                hv_store(cookies_hv, start, name_len, newSVpvn(val, val_len), 0);')
              ->line('            }')
              ->line('            start = semi + 1;')
              ->line('        }')
              ->line('        av_store(req, 7, newRV_noinc((SV*)cookies_hv));')  # SLOT_COOKIES
              ->line('    } else {')
              ->line('        av_store(req, 7, newRV_noinc((SV*)newHV()));')  # SLOT_COOKIES
              ->line('    }')
              ->blank;
        } else {
            $builder->comment('JIT: Cookie parsing SKIPPED')
              ->line('    av_store(req, 7, newRV_noinc((SV*)newHV()));')  # SLOT_COOKIES
              ->blank;
        }
        
        # Form/JSON parsing
        if ($analysis->{needs_form} || $analysis->{needs_json}) {
            $builder->comment('JIT: Form/JSON body parsing')
              ->line('    SV** ct_sv = hv_fetch(headers_hv, "content_type", 12, 0);')
              ->line('    if (ct_sv && SvOK(*ct_sv) && body_len > 0) {')
              ->line('        STRLEN ct_len;')
              ->line('        const char* ct_str = SvPV(*ct_sv, ct_len);');
            
            if ($analysis->{needs_form}) {
                $builder->line('        if (ct_len >= 33 && memcmp(ct_str, "application/x-www-form-urlencoded", 33) == 0) {')
                  ->line('            HV* form_hv = newHV();')
                  ->line('            parse_query_string(aTHX_ body, body_len, form_hv);')
                  ->line('            av_store(req, 9, newRV_noinc((SV*)form_hv));')  # SLOT_FORM
                  ->line('        } else {')
                  ->line('            av_store(req, 9, newRV_noinc((SV*)newHV()));')  # SLOT_FORM
                  ->line('        }');
            } else {
                $builder->line('        av_store(req, 9, newRV_noinc((SV*)newHV()));');  # SLOT_FORM
            }

            if ($analysis->{needs_json}) {
                $builder->line('        if (ct_len >= 16 && memcmp(ct_str, "application/json", 16) == 0) {')
                  ->line('            dSP;')
                  ->line('            PUSHMARK(SP);')
                  ->line('            XPUSHs(sv_2mortal(newSVpvn(body, body_len)));')
                  ->line('            PUTBACK;')
                  ->line('            int json_count = call_pv("Hypersonic::_decode_json", G_SCALAR | G_EVAL);')
                  ->line('            SPAGAIN;')
                  ->line('            if (json_count == 1 && !SvTRUE(ERRSV)) {')
                  ->line('                SV* json_sv = POPs;')
                  ->line('                av_store(req, 8, SvREFCNT_inc(json_sv));')  # SLOT_JSON
                  ->line('            } else {')
                  ->line('                if (SvTRUE(ERRSV)) POPs;')
                  ->line('                av_store(req, 8, &PL_sv_undef);')  # SLOT_JSON
                  ->line('            }')
                  ->line('            PUTBACK;')
                  ->line('        } else {')
                  ->line('            av_store(req, 8, &PL_sv_undef);')  # SLOT_JSON
                  ->line('        }');
            } else {
                $builder->line('        av_store(req, 8, &PL_sv_undef);');  # SLOT_JSON
            }

            $builder->line('    } else {')
              ->line('        av_store(req, 9, newRV_noinc((SV*)newHV()));')  # SLOT_FORM
              ->line('        av_store(req, 8, &PL_sv_undef);')  # SLOT_JSON
              ->line('    }')
              ->blank;
        } else {
            $builder->comment('JIT: Form/JSON parsing SKIPPED')
              ->line('    av_store(req, 9, newRV_noinc((SV*)newHV()));')  # SLOT_FORM
              ->line('    av_store(req, 8, &PL_sv_undef);')  # SLOT_JSON
              ->blank;
        }
    } else {
        $builder->comment('JIT: All header-based parsing SKIPPED (no routes use these features)')
          ->line('    av_store(req, 6, newRV_noinc((SV*)newHV()));')  # SLOT_HEADERS
          ->line('    av_store(req, 7, newRV_noinc((SV*)newHV()));')  # SLOT_COOKIES
          ->line('    av_store(req, 8, &PL_sv_undef);')  # SLOT_JSON
          ->line('    av_store(req, 9, newRV_noinc((SV*)newHV()));')  # SLOT_FORM
          ->blank;
    }

    # Call handler and build response
    $builder->comment('Bless array into Hypersonic::Request and call Perl handler')
      ->line('    SV* req_ref = newRV_noinc((SV*)req);')
      ->line('    sv_bless(req_ref, gv_stashpv("Hypersonic::Request", GV_ADD));')
      ->line('    ENTER;')
      ->line('    SAVETMPS;');
    
    # JIT: Add middleware short-circuit variable only if middleware present
    if ($analysis->{has_any_middleware}) {
        $builder->line('    SV* mw_result = NULL;')
          ->line('    int short_circuit = 0;');
    }
    
    # JIT: Call global before middleware
    if ($analysis->{has_global_before}) {
        $builder->blank
          ->comment('JIT: Call global before middleware')
          ->line('    if (g_before_middleware && SvROK(g_before_middleware)) {')
          ->line('        AV* before_arr = (AV*)SvRV(g_before_middleware);')
          ->line('        mw_result = call_middleware_chain(aTHX_ before_arr, req_ref);')
          ->line('        if (mw_result) {')
          ->line('            result = mw_result;')
          ->line('            short_circuit = 1;')
          ->line('        }')
          ->line('    }');
    }
    
    # JIT: Call per-route before middleware
    if ($analysis->{has_route_middleware}) {
        $builder->blank
          ->comment('JIT: Call per-route before middleware')
          ->line('    if (!short_circuit && g_route_before_middleware && SvROK(g_route_before_middleware)) {')
          ->line('        AV* route_before = (AV*)SvRV(g_route_before_middleware);')
          ->line('        SV** handler_arr_ref = av_fetch(route_before, handler_idx, 0);')
          ->line('        if (handler_arr_ref && SvROK(*handler_arr_ref)) {')
          ->line('            AV* handler_arr = (AV*)SvRV(*handler_arr_ref);')
          ->line('            if (av_len(handler_arr) >= 0) {')
          ->line('                mw_result = call_middleware_chain(aTHX_ handler_arr, req_ref);')
          ->line('                if (mw_result) {')
          ->line('                    result = mw_result;')
          ->line('                    short_circuit = 1;')
          ->line('                }')
          ->line('            }')
          ->line('        }')
          ->line('    }');
    }
    
    # Call the main handler (conditionally if middleware present)
    if ($analysis->{has_any_middleware}) {
        $builder->blank
          ->comment('Call main handler (unless middleware short-circuited)')
          ->line('    if (!short_circuit) {')
          ->line('        PUSHMARK(SP);')
          ->line('        XPUSHs(req_ref);')
          ->line('        PUTBACK;')
          ->line('        count = call_sv(*handler_sv, G_SCALAR | G_EVAL);')
          ->line('        SPAGAIN;')
          ->line('        if (count == 1) result = POPs;')
          ->line('        PUTBACK;')
          ->line('    }');
    } else {
        $builder->line('    PUSHMARK(SP);')
          ->line('    XPUSHs(sv_2mortal(req_ref));')
          ->line('    PUTBACK;')
          ->line('    count = call_sv(*handler_sv, G_SCALAR | G_EVAL);')
          ->line('    SPAGAIN;');
    }
    
    # JIT: Call per-route after middleware
    if ($analysis->{has_route_middleware}) {
        $builder->blank
          ->comment('JIT: Call per-route after middleware')
          ->line('    if (g_route_after_middleware && SvROK(g_route_after_middleware)) {')
          ->line('        AV* route_after = (AV*)SvRV(g_route_after_middleware);')
          ->line('        SV** handler_arr_ref = av_fetch(route_after, handler_idx, 0);')
          ->line('        if (handler_arr_ref && SvROK(*handler_arr_ref)) {')
          ->line('            AV* handler_arr = (AV*)SvRV(*handler_arr_ref);')
          ->line('            if (av_len(handler_arr) >= 0) {')
          ->line('                SV* after_result = call_middleware_chain(aTHX_ handler_arr, req_ref);')
          ->line('                if (after_result) {')
          ->line('                    result = after_result;')
          ->line('                }')
          ->line('            }')
          ->line('        }')
          ->line('    }');
    }
    
    # JIT: Call global after middleware
    if ($analysis->{has_global_after}) {
        $builder->blank
          ->comment('JIT: Call global after middleware')
          ->line('    if (g_after_middleware && SvROK(g_after_middleware)) {')
          ->line('        AV* after_arr = (AV*)SvRV(g_after_middleware);')
          ->line('        SV* after_result = call_middleware_chain(aTHX_ after_arr, req_ref);')
          ->line('        if (after_result) {')
          ->line('            result = after_result;')
          ->line('        }')
          ->line('    }');
    }
    
    $builder->blank
      ->line('    if (SvTRUE(ERRSV)) {')
      ->line('        static char error_resp[512];')
      ->line('        int err_len = snprintf(error_resp, sizeof(error_resp),')
      ->line('            "HTTP/1.1 500 Internal Server Error\\r\\n"')
      ->line('            "Content-Type: text/plain\\r\\n"')
      ->line('            "Content-Length: 21\\r\\n"')
      ->line('            "Connection: close\\r\\n\\r\\n"')
      ->line('            "Internal Server Error");')
      ->line('        *resp_out = error_resp;')
      ->line('        *resp_len_out = err_len;');
    
    # Middleware version already has result set, no-middleware version needs POPs
    if ($analysis->{has_any_middleware}) {
        $builder->line('    } else if (SvOK(result)) {')
          ->line('            HV* custom_headers = NULL;');
    } else {
        $builder->line('        POPs;')
          ->line('    } else if (count == 1) {')
          ->line('        result = POPs;')
          ->line('        if (SvOK(result)) {')
          ->line('            HV* custom_headers = NULL;');
    }

    $builder
      ->comment('            Handle arrayref [status, headers, body]')
      ->line('            if (SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVAV) {')
      ->line('                AV* arr = (AV*)SvRV(result);')
      ->line('                SV** status_sv = av_fetch(arr, 0, 0);')
      ->line('                SV** headers_sv = av_fetch(arr, 1, 0);')
      ->line('                SV** body_sv = av_fetch(arr, 2, 0);')
      ->line('                if (status_sv) status = (int)SvIV(*status_sv);')
      ->line('                if (body_sv) body_str = SvPV(*body_sv, len);')
      ->line('                else { body_str = ""; len = 0; }')
      ->line('                if (headers_sv && SvROK(*headers_sv) && SvTYPE(SvRV(*headers_sv)) == SVt_PVHV) {')
      ->line('                    custom_headers = (HV*)SvRV(*headers_sv);')
      ->line('                    SV** ct_sv = hv_fetch(custom_headers, "Content-Type", 12, 0);')
      ->line('                    if (ct_sv && SvOK(*ct_sv)) {')
      ->line('                        STRLEN ct_len;')
      ->line('                        content_type = SvPV(*ct_sv, ct_len);')
      ->line('                    }')
      ->line('                }')
      ->line('            }')
      ->comment('            Handle hashref {status, headers, body}')
      ->line('            else if (SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVHV) {')
      ->line('                HV* hash = (HV*)SvRV(result);')
      ->line('                SV** status_sv = hv_fetch(hash, "status", 6, 0);')
      ->line('                SV** headers_sv = hv_fetch(hash, "headers", 7, 0);')
      ->line('                SV** body_sv = hv_fetch(hash, "body", 4, 0);')
      ->line('                if (status_sv) status = (int)SvIV(*status_sv);')
      ->line('                if (body_sv) body_str = SvPV(*body_sv, len);')
      ->line('                else { body_str = ""; len = 0; }')
      ->line('                if (headers_sv && SvROK(*headers_sv) && SvTYPE(SvRV(*headers_sv)) == SVt_PVHV) {')
      ->line('                    custom_headers = (HV*)SvRV(*headers_sv);')
      ->line('                    SV** ct_sv = hv_fetch(custom_headers, "Content-Type", 12, 0);')
      ->line('                    if (ct_sv && SvOK(*ct_sv)) {')
      ->line('                        STRLEN ct_len;')
      ->line('                        content_type = SvPV(*ct_sv, ct_len);')
      ->line('                    }')
      ->line('                }')
      ->line('            }')
      ->comment('            Plain string response')
      ->line('            else {')
      ->line('                body_str = SvPV(result, len);')
      ->line('            }')
      ->blank
      ->comment('            Auto-detect JSON content type')
      ->line('            if (strcmp(content_type, "text/plain") == 0 && len > 0 &&')
      ->line('                (body_str[0] == \'{\' || body_str[0] == \'[\')) {')
      ->line('                content_type = "application/json";')
      ->line('            }')
      ->blank;
    
    # JIT: Add compression logic only if compression is enabled
    if ($self->{_compression_enabled}) {
        my $config = $self->{_compression_config};
        my $min_size = $config->{min_size} // 1024;
        
        $builder
          ->comment('            Gzip compression - check Accept-Encoding')
          ->line('#ifdef HYPERSONIC_COMPRESSION')
          ->line('            int use_gzip = 0;')
          ->line('            unsigned char* compressed_body = NULL;')
          ->line('            size_t compressed_len = 0;')
          ->blank
          ->comment('            Get Accept-Encoding from request (from SLOT_HEADERS)')
          ->line('            SV** req_arr = AvARRAY(req);')
          ->line('            HV* hdrs = NULL;')
          ->line('            if (req_arr[6] && SvROK(req_arr[6])) {')
          ->line('                hdrs = (HV*)SvRV(req_arr[6]);')
          ->line('            }')
          ->line('            if (hdrs && len >= ' . $min_size . ') {')
          ->line('                SV** ae = hv_fetch(hdrs, "accept_encoding", 15, 0);')
          ->line('                if (ae && SvOK(*ae)) {')
          ->line('                    STRLEN ae_len;')
          ->line('                    const char* ae_str = SvPV(*ae, ae_len);')
          ->line('                    if (accepts_gzip(ae_str, ae_len)) {')
          ->line('                        compressed_len = gzip_compress(body_str, len, &compressed_body);')
          ->line('                        if (compressed_len > 0) {')
          ->line('                            use_gzip = 1;')
          ->line('                            body_str = (const char*)compressed_body;')
          ->line('                            len = compressed_len;')
          ->line('                        }')
          ->line('                    }')
          ->line('                }')
          ->line('            }')
          ->line('#endif')
          ->blank;
    }
    
    $builder
      ->comment('            Build response with custom headers support')
      ->line('            static __thread char resp_buf[65536];')
      ->line('            int hdr_len;')
      ->line('#ifdef HYPERSONIC_SECURITY_HEADERS')
      ->line('            hdr_len = snprintf(resp_buf, 2048,')
      ->line('                "HTTP/1.1 %d %s\\r\\n"')
      ->line('                "Content-Type: %s\\r\\n"')
      ->line('                "Content-Length: %zu\\r\\n"')
      ->line('                "Connection: keep-alive\\r\\n"')
      ->line('                "%s",')
      ->line('                status, get_status_text(status), content_type, len, SECURITY_HEADERS);')
      ->line('#else')
      ->line('            hdr_len = snprintf(resp_buf, 512,')
      ->line('                "HTTP/1.1 %d %s\\r\\n"')
      ->line('                "Content-Type: %s\\r\\n"')
      ->line('                "Content-Length: %zu\\r\\n"')
      ->line('                "Connection: keep-alive\\r\\n",')
      ->line('                status, get_status_text(status), content_type, len);')
      ->line('#endif')
      ->blank
      ->comment('            Add custom headers from response (Location, Set-Cookie, etc.)')
      ->line('            if (custom_headers) {')
      ->line('                HE* entry;')
      ->line('                hv_iterinit(custom_headers);')
      ->line('                while ((entry = hv_iternext(custom_headers))) {')
      ->line('                    I32 klen;')
      ->line('                    const char* key = hv_iterkey(entry, &klen);')
      ->comment('                    Skip Content-Type/Content-Length (already added)')
      ->line('                    if (klen == 12 && memcmp(key, "Content-Type", 12) == 0) continue;')
      ->line('                    if (klen == 14 && memcmp(key, "Content-Length", 14) == 0) continue;')
      ->line('                    SV* val = hv_iterval(custom_headers, entry);')
      ->comment('                    Handle Set-Cookie array (multiple cookies)')
      ->line('                    if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {')
      ->line('                        AV* arr = (AV*)SvRV(val);')
      ->line('                        SSize_t arr_len = av_len(arr) + 1;')
      ->line('                        SSize_t j;')
      ->line('                        for (j = 0; j < arr_len; j++) {')
      ->line('                            SV** item = av_fetch(arr, j, 0);')
      ->line('                            if (item && SvOK(*item)) {')
      ->line('                                STRLEN vlen;')
      ->line('                                const char* vstr = SvPV(*item, vlen);')
      ->line('                                hdr_len += snprintf(resp_buf + hdr_len, sizeof(resp_buf) - hdr_len,')
      ->line('                                    "%.*s: %.*s\\r\\n", (int)klen, key, (int)vlen, vstr);')
      ->line('                            }')
      ->line('                        }')
      ->line('                    } else if (SvOK(val)) {')
      ->line('                        STRLEN vlen;')
      ->line('                        const char* vstr = SvPV(val, vlen);')
      ->line('                        hdr_len += snprintf(resp_buf + hdr_len, sizeof(resp_buf) - hdr_len,')
      ->line('                            "%.*s: %.*s\\r\\n", (int)klen, key, (int)vlen, vstr);')
      ->line('                    }')
      ->line('                }')
      ->line('            }')
      ->blank
      ->comment('            Add Content-Encoding header if gzip was used')
      ->line('#ifdef HYPERSONIC_COMPRESSION')
      ->line('            if (use_gzip) {')
      ->line('                hdr_len += snprintf(resp_buf + hdr_len, sizeof(resp_buf) - hdr_len,')
      ->line('                    "Content-Encoding: gzip\\r\\n");')
      ->line('            }')
      ->line('#endif')
      ->blank
      ->comment('            End headers')
      ->line('            memcpy(resp_buf + hdr_len, "\\r\\n", 2);')
      ->line('            hdr_len += 2;')
      ->blank
      ->line('            if (hdr_len + len < sizeof(resp_buf)) {')
      ->line('                memcpy(resp_buf + hdr_len, body_str, len);')
      ->line('                *resp_out = resp_buf;')
      ->line('                *resp_len_out = hdr_len + (int)len;')
      ->line('            } else {')
      ->line('                *resp_out = (char*)RESP_404;')
      ->line('                *resp_len_out = RESP_404_LEN;')
      ->line('            }');
    
    # Different closing braces based on middleware presence
    if ($analysis->{has_any_middleware}) {
        # Middleware: } else if (SvOK(result)) { ... } else { 404 }
        $builder->line('    } else {')
          ->line('        *resp_out = (char*)RESP_404;')
          ->line('        *resp_len_out = RESP_404_LEN;')
          ->line('    }');
    } else {
        # No middleware: } else if (count == 1) { result = POPs; if (SvOK(result)) { ... } } else { 404 }
        $builder->line('        } else {')
          ->line('            *resp_out = (char*)RESP_404;')
          ->line('            *resp_len_out = RESP_404_LEN;')
          ->line('        }')
          ->line('    } else {')
          ->line('        *resp_out = (char*)RESP_404;')
          ->line('        *resp_len_out = RESP_404_LEN;')
          ->line('    }');
    }
    
    $builder->blank
      ->line('    PUTBACK;')
      ->line('    FREETMPS;')
      ->line('    LEAVE;')
      ->line('}');
    
    return $builder->code;
}

# JSON decoder helper - called from C via call_pv
sub _decode_json {
    my ($json_str) = @_;
    require Cpanel::JSON::XS;
    return Cpanel::JSON::XS::decode_json($json_str);
}

sub _escape_c_string {
    my ($str) = @_;
    $str =~ s/\\/\\\\/g;
    $str =~ s/"/\\"/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\r/\\r/g;
    $str =~ s/\t/\\t/g;
    return $str;
}

# Deparse a handler coderef to analyze what request features it uses
# Returns deparsed code as string, or undef on failure
sub _deparse_handler {
    my ($coderef) = @_;
    return undef unless ref($coderef) eq 'CODE';
    
    my $code = eval {
        $DEPARSER //= B::Deparse->new('-q');  # -q = don't quote simple strings
        $DEPARSER->coderef2text($coderef);
    };
    return $@ ? undef : $code;
}

# Find common prefix of multiple paths
sub _find_common_prefix {
    my @paths = @_;
    return '' unless @paths;
    return $paths[0] if @paths == 1;

    my $prefix = $paths[0];
    for my $path (@paths[1..$#paths]) {
        while (index($path, $prefix) != 0) {
            $prefix = substr($prefix, 0, -1);
            return '' if $prefix eq '';
        }
    }
    # Don't include trailing non-slash char as prefix
    # e.g., /api/hello and /api/health -> /api/ not /api/he
    if ($prefix !~ m{/$} && $prefix =~ m{^(.*/)[^/]+$}) {
        $prefix = $1;
    }
    return $prefix;
}

# HTTP status code to text mapping
my %STATUS_TEXT = (
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    204 => 'No Content',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    307 => 'Temporary Redirect',
    308 => 'Permanent Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    413 => 'Payload Too Large',
    415 => 'Unsupported Media Type',
    422 => 'Unprocessable Entity',
    429 => 'Too Many Requests',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
);

sub _status_text {
    my ($code) = @_;
    return $STATUS_TEXT{$code} // 'Unknown';
}

# ============================================================
# STATIC FILE SERVING - JIT compiled for maximum performance
# Files are read at compile time and baked into C string constants
# ============================================================

sub _compile_static_files {
    my ($self, $static_dirs) = @_;
    
    require File::Find;
    require Digest::MD5;
    
    my @static_files;
    
    for my $config (@$static_dirs) {
        my $prefix = $config->{prefix};
        my $dir = $config->{directory};
        my $max_age = $config->{max_age};
        my $gen_etag = $config->{etag};
        
        # Recursively find all files
        File::Find::find({
            no_chdir => 1,
            wanted => sub {
                return unless -f $_;
                my $file_path = $_;
                my $rel_path = $file_path;
                $rel_path =~ s{^\Q$dir\E/?}{};
                
                # URL path for this file
                my $url_path = "$prefix/$rel_path";
                $url_path =~ s{//+}{/}g;
                
                # Read file content
                open my $fh, '<:raw', $file_path or return;
                local $/;
                my $content = <$fh>;
                close $fh;
                
                # Get MIME type
                my $mime = _get_mime_type($file_path);
                
                # Generate ETag (MD5 of content)
                my $etag = '';
                if ($gen_etag) {
                    $etag = Digest::MD5::md5_hex($content);
                }
                
                # Store file info
                push @static_files, {
                    url_path => $url_path,
                    content  => $content,
                    mime     => $mime,
                    etag     => $etag,
                    max_age  => $max_age,
                    length   => length($content),
                };
            },
        }, $dir);
    }
    
    # Store for code generation
    $self->{_static_files} = \@static_files;
    
    # Create static routes - these are essentially pre-computed responses
    for my $file (@static_files) {
        my $url_path = $file->{url_path};
        my $content = $file->{content};
        my $mime = $file->{mime};
        my $etag = $file->{etag};
        my $max_age = $file->{max_age};
        my $len = $file->{length};
        
        # Build complete HTTP response at compile time
        my $response = "HTTP/1.1 200 OK\r\n"
                     . "Content-Type: $mime\r\n"
                     . "Content-Length: $len\r\n"
                     . "Connection: keep-alive\r\n";
        $response .= "Cache-Control: public, max-age=$max_age\r\n" if $max_age;
        $response .= "ETag: \"$etag\"\r\n" if $etag;
        
        # Add security headers
        if ($self->{enable_security_headers}) {
            $response .= $self->_get_security_headers_string();
        }
        
        $response .= "\r\n" . $content;
        
        # Store as static route
        push @{$self->{routes}}, {
            method   => 'GET',
            path     => $url_path,
            handler  => sub { $content },  # Dummy handler for static
            dynamic  => 0,
            params   => [],
            segments => [split('/', $url_path)],
            features => {},
            before   => [],
            after    => [],
            # Mark as static file with pre-built response
            _static_response => $response,
            _static_file     => 1,
        };
    }
}

# Generate security headers string for HTTP responses
# Pre-computed at compile time - zero runtime overhead
sub _get_security_headers_string {
    my ($self) = @_;
    my $headers = '';
    
    for my $name (sort keys %{$self->{security_headers}}) {
        my $value = $self->{security_headers}{$name};
        next unless defined $value && length($value);
        $headers .= "$name: $value\r\n";
    }
    
    return $headers;
}

# Generate security headers as C string constant for dynamic routes
sub _gen_security_headers_c_constant {
    my ($self) = @_;
    return '' unless $self->{enable_security_headers};
    
    my $headers = $self->_get_security_headers_string();
    return '' unless length($headers);
    
    my $escaped = _escape_c_string($headers);
    return "static const char SECURITY_HEADERS[] = \"$escaped\";\n"
         . "static const int SECURITY_HEADERS_LEN = " . length($headers) . ";\n";
}

sub dispatch {
    my ($self, $req) = @_;
    die "Must call compile() first" unless $self->{compiled};
    return $self->{dispatch_fn}->($req);
}

sub run {
    my ($self, %opts) = @_;

    die "Must call compile() before run()" unless $self->{compiled};

    my $host    = $opts{host}    // '0.0.0.0';
    my $port    = $opts{port}    // 8080;
    my $workers = $opts{workers} // 1;
    
    # TLS mode indication
    my $mode = $self->{tls} ? "HTTPS/TLS" : "HTTP";
    print "Hypersonic listening on $host:$port ($mode, pure C event loop, $workers workers)\n";

    # Fork workers if requested
    # Each worker creates its OWN listening socket with SO_REUSEPORT
    # This avoids thundering herd and lets kernel distribute connections
    if ($workers > 1) {
        for my $i (1 .. $workers - 1) {
            my $pid = fork();
            if (!defined $pid) {
                die "Fork failed: $!";
            }
            if ($pid == 0) {
                # Child - create own listen socket and run event loop
                my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
                die "Worker $i: Failed to create listen socket" if $listen_fd < 0;
                $self->{run_loop_fn}->($listen_fd, $self);
                exit(0);
            }
        }
    }

    # Parent (or single worker) - create listen socket and run event loop
    my $listen_fd = Hypersonic::Socket::create_listen_socket($port);
    die "Failed to create listen socket on port $port" if $listen_fd < 0;
    $self->{run_loop_fn}->($listen_fd, $self);
}


1;

__END__

=head1 NAME

Hypersonic - Blazing fast HTTP server with JIT-compiled C event loop

=head1 SYNOPSIS

    use Hypersonic;

    my $server = Hypersonic->new();

    # Handlers return STRINGS - they run ONCE at compile time
    $server->get('/api/hello' => sub {
        '{"message":"Hello, World!"}'
    });

    $server->get('/health' => sub {
        'OK'
    });

    # Compile routes - generates C code and compiles via XS::JIT
    $server->compile();

    # Run the server
    $server->run(
        port    => 8080,
        workers => 4,
    );

=head1 DESCRIPTION

Hypersonic is a benchmark-focused micro HTTP server that uses XS::JIT to
generate and compile C code at runtime. The entire event loop runs in C
with no Perl in the hot path.

B<What it does:>

=over 4

=item 1. Static route handlers run ONCE at C<compile()> time

=item 2. Response strings (including HTTP headers) are baked into C as static constants

=item 3. Dynamic routes run Perl handlers per-request with JIT-compiled request objects

=item 4. A pure C event loop (kqueue/epoll) is generated and compiled

=item 5. Security headers are pre-computed and baked into responses at compile time

=item 6. Optional TLS/HTTPS support via OpenSSL with JIT-compiled wrappers

=back

B<Performance:> ~290,000 requests/second on a single core (macOS/kqueue).

=head1 METHODS

=head2 new

    my $server = Hypersonic->new(%options);

Create a new Hypersonic server instance.

B<Options:>

=over 4

=item cache_dir

Directory for caching compiled XS modules. Default: C<_hypersonic_cache>

=item tls

Enable TLS/HTTPS support. Requires C<cert_file> and C<key_file>. Default: C<0>

=item cert_file

Path to TLS certificate file (PEM format). Required if C<tls> is enabled.

=item key_file

Path to TLS private key file (PEM format). Required if C<tls> is enabled.

=item max_connections

Maximum number of concurrent connections. Default: C<10000>

=item max_request_size

Maximum request size in bytes. Default: C<8192>

=item keepalive_timeout

Keep-alive connection timeout in seconds. Default: C<30>

=item recv_timeout

Receive timeout in seconds. Default: C<30>

=item drain_timeout

Graceful shutdown drain timeout in seconds. Default: C<5>

=item enable_security_headers

Enable security headers (X-Frame-Options, X-Content-Type-Options, etc.). Default: C<1>

=item security_headers

HashRef of custom security header values. Example:

    security_headers => {
        'X-Frame-Options'         => 'SAMEORIGIN',
        'Content-Security-Policy' => "default-src 'self'",
    }

=back

B<Example with TLS:>

    my $server = Hypersonic->new(
        tls       => 1,
        cert_file => '/path/to/cert.pem',
        key_file  => '/path/to/key.pem',
    );

=head2 get

    $server->get('/path' => sub { ... });
    $server->get('/path' => sub { ... }, \%options);

Register a GET route handler.

=head2 post

    $server->post('/path' => sub { ... });

Register a POST route handler.

=head2 put

    $server->put('/path' => sub { ... });

Register a PUT route handler.

=head2 del

    $server->del('/path' => sub { ... });

Register a DELETE route handler.

=head2 patch

    $server->patch('/path' => sub { ... });

Register a PATCH route handler.

=head2 head

    $server->head('/path' => sub { ... });

Register a HEAD route handler.

=head2 options

    $server->options('/path' => sub { ... });

Register an OPTIONS route handler.

=head2 Route Handler Options

All route methods accept an optional hashref as the third argument:

    $server->get('/path' => sub { ... }, {
        dynamic       => 1,           # Force dynamic handler
        parse_query   => 1,           # Parse query string
        parse_headers => 1,           # Parse HTTP headers
        parse_cookies => 1,           # Parse Cookie header
        parse_json    => 1,           # Parse JSON body
        parse_form    => 1,           # Parse form-urlencoded body
        before        => [\&mw1],     # Per-route before middleware
        after         => [\&mw2],     # Per-route after middleware
    });

=head2 static

    $server->static('/static' => './public');
    $server->static('/assets' => './assets', \%options);

Serve static files from a directory. Files are read at compile time and
baked into C string constants for maximum performance.

B<Arguments:>

=over 4

=item url_prefix

URL path prefix for static files (e.g., C</static>)

=item directory

Filesystem directory containing files

=item options (optional)

HashRef with options:

=over 4

=item max_age

Cache-Control max-age in seconds. Default: C<3600>

=item etag

Generate ETag headers (MD5 hash). Default: C<1>

=item index

Directory index file. Default: C<index.html>

=item gzip

Serve C<.gz> files if available. Default: C<0>

=back

=back

B<Example:>

    # Serve files from ./public at /static/*
    $server->static('/static' => './public', {
        max_age => 86400,    # Cache for 1 day
        etag    => 1,        # Enable ETags
    });

    # Multiple static directories
    $server->static('/assets' => './assets');
    $server->static('/images' => './img');

B<Supported MIME types:>

HTML, CSS, JavaScript, JSON, XML, PNG, JPEG, GIF, SVG, WebP, WOFF2,
PDF, and many more. Unknown extensions default to C<application/octet-stream>.

B<Performance:>

Static files are fully JIT-compiled - the complete HTTP response
(headers + body) is baked into C as a string constant. Zero Perl
overhead at request time.

=head2 Static vs Dynamic Routes

B<Static routes> have handlers that run once at compile time:

    # Handler runs ONCE, response is baked into C
    $server->get('/health' => sub { '{"status":"ok"}' });

B<Dynamic routes> have handlers that run per-request:

    # Automatic: path parameters make it dynamic
    $server->get('/users/:id' => sub {
        my ($req) = @_;
        return '{"id":"' . $req->param('id') . '"}';
    });

    # Explicit: force dynamic with option
    $server->post('/api/data' => sub {
        my ($req) = @_;
        return '{"received":"' . $req->body . '"}';
    }, { dynamic => 1 });

Dynamic handlers receive a L<Hypersonic::Request> object with:

    $req->method         # HTTP method
    $req->path           # Request path
    $req->body           # Request body
    $req->param('name')  # Path parameter by name
    $req->query_param('key')  # Query string parameter
    $req->header('name') # Request header
    $req->cookie('name') # Cookie value
    $req->json           # Parsed JSON body (hashref)
    $req->form_param('key')   # Form field value

=head2 Response Formats

Handlers can return several formats:

    # Simple string (status 200, text/plain or auto-detect JSON)
    return '{"status":"ok"}';

    # ArrayRef: [status, headers, body]
    return [201, { 'Content-Type' => 'application/json' }, '{"id":1}'];

    # HashRef: { status, headers, body }
    return { status => 200, headers => {}, body => 'hello' };

    # Hypersonic::Response object
    use Hypersonic::Response 'res';
    return res->status(201)->json({ id => 1 });

=head2 before

    $server->before(sub {
        my ($req) = @_;
        # Return undef to continue, or a response to short-circuit
        return;
    });

Register global before middleware. Runs before every dynamic route handler.
Return a response to short-circuit (skip the handler and after middleware).
Return C<undef> to continue to the handler.

=head2 after

    $server->after(sub {
        my ($req, $response) = @_;
        # Can modify and return the response
        return $response;
    });

Register global after middleware. Runs after every dynamic route handler.
Receives the request and response, can modify and return the response.

=head2 session_config

    $server->session_config(
        secret      => 'your-secret-key-at-least-16-chars',
        cookie_name => 'sid',           # Default: 'hsid'
        max_age     => 86400,           # Default: 86400 (1 day)
        path        => '/',             # Default: '/'
        httponly    => 1,               # Default: 1
        secure      => 1,               # Default: 0
        samesite    => 'Strict',        # Default: 'Lax'
    );

Enable session support with signed cookies and in-memory storage.
Sessions are automatically loaded before each request and saved after.

B<Configuration options:>

=over 4

=item * B<secret> (required) - HMAC-SHA256 signing key (minimum 16 chars)

=item * B<cookie_name> - Session cookie name (default: 'hsid')

=item * B<max_age> - Session lifetime in seconds (default: 86400)

=item * B<path> - Cookie path (default: '/')

=item * B<httponly> - Set HttpOnly flag (default: 1)

=item * B<secure> - Set Secure flag for HTTPS (default: 0)

=item * B<samesite> - SameSite attribute: 'Strict', 'Lax', 'None' (default: 'Lax')

=back

B<Usage in handlers:>

    $server->post('/login' => sub {
        my ($req) = @_;
        my $data = $req->json;
        
        if (authenticate($data->{user}, $data->{pass})) {
            $req->session('user', $data->{user});
            $req->session('logged_in', 1);
            $req->session_regenerate;  # Security: regenerate after login
            return res->json({ success => 1 });
        }
        return res->unauthorized('Invalid credentials');
    }, { dynamic => 1, parse_json => 1 });

    $server->get('/profile' => sub {
        my ($req) = @_;
        my $user = $req->session('user') // 'guest';
        return res->json({ user => $user });
    }, { dynamic => 1 });

    $server->post('/logout' => sub {
        my ($req) = @_;
        $req->session_clear;
        return res->json({ logged_out => 1 });
    }, { dynamic => 1 });

See L<Hypersonic::Session> for more details.

=head2 compress

    $server->compress(
        min_size => 1024,    # Default: 1024 bytes
        level    => 6,       # Default: 6 (1=fastest, 9=smallest)
    );

Enable JIT-compiled gzip compression for dynamic responses. Responses are
compressed in C using zlib for maximum performance.

B<Configuration options:>

=over 4

=item * B<min_size> - Minimum response size to compress (default: 1024 bytes)

=item * B<level> - Compression level 1-9 (default: 6)

=back

B<How it works:>

=over 4

=item 1. At compile time, zlib compression code is JIT-compiled into the server

=item 2. For each request, the C code checks C<Accept-Encoding: gzip> header

=item 3. If response body is larger than C<min_size>, it's gzip compressed

=item 4. C<Content-Encoding: gzip> header is added automatically

=back

B<Requirements:> zlib library must be installed (standard on most systems).

See L<Hypersonic::Compress> for more details.

=head2 Middleware Examples

    # Authentication middleware
    $server->before(sub {
        my ($req) = @_;
        my $token = $req->header('Authorization');
        unless ($token && validate_token($token)) {
            return res->unauthorized('Invalid token');
        }
        return;  # Continue to handler
    });

    # Logging middleware
    $server->after(sub {
        my ($req, $res) = @_;
        warn "[" . $req->method . "] " . $req->path . "\n";
        return $res;
    });

    # Per-route middleware
    $server->get('/admin/:id' => sub { ... }, {
        before => [\&require_admin],
        after  => [\&audit_log],
    });

=head2 compile

    $server->compile();

Compile all registered routes into JIT'd native code. This:

=over 4

=item 1. Executes static handlers once to get response strings

=item 2. Analyzes which features each route needs (JIT philosophy)

=item 3. Generates C code with responses as static constants

=item 4. Generates dynamic handler caller with only needed parsing

=item 5. Compiles via XS::JIT

=back

Must be called after all routes are registered, before C<run()>.

=head2 dispatch

    my $response = $server->dispatch($request_arrayref);

Dispatch a request and return the response. Primarily for testing.

Request is an arrayref: C<[method, path, body, keep_alive, fd]>

=head2 run

    $server->run(port => 8080, workers => 4);

Start the HTTP server event loop.

B<Options:>

=over 4

=item port

Port to listen on. Default: C<8080>

=item workers

Number of worker processes. Default: C<1>

=back

=head1 FULL EXAMPLE

    use Hypersonic;
    use Hypersonic::Response 'res';

    my $server = Hypersonic->new(
        max_request_size => 16384,
        enable_security_headers => 1,
    );

    # Global middleware
    $server->before(sub {
        my ($req) = @_;
        # Log request
        warn $req->method . ' ' . $req->path . "\n";
        return;  # Continue
    });

    # Static route (runs once at compile time)
    $server->get('/health' => sub {
        '{"status":"ok"}'
    });

    # Dynamic route with path parameter
    $server->get('/users/:id' => sub {
        my ($req) = @_;
        my $id = $req->param('id');
        return res->json({ id => $id, name => "User $id" });
    });

    # POST with JSON body
    $server->post('/users' => sub {
        my ($req) = @_;
        my $data = $req->json;
        return res->status(201)->json({ created => $data->{name} });
    }, { parse_json => 1 });

    # Query parameters
    $server->get('/search' => sub {
        my ($req) = @_;
        my $q = $req->query_param('q') // '';
        return res->json({ query => $q });
    }, { dynamic => 1, parse_query => 1 });

    $server->compile();
    $server->run(port => 8080, workers => 4);

=head1 BENCHMARK

    ======================================================================
    Benchmark: Route matching for GET /api/hello
    ======================================================================

    Comparison (higher is better):
             Rate     Dancer2 HTTP_Router Mojolicious       Plack Hypersonic
    Dancer2       17713/s          --        -83%        -91%       -100%      -100%
    HTTP_Router  107178/s        505%          --        -45%        -97%       -99%
    Mojolicious  196110/s       1007%         83%          --        -95%       -98%
    Plack       3937159/s      22127%       3573%       1908%          --       -58%
    Hypersonic  9336325/s      52608%       8611%       4661%        137%         --

=head1 SEE ALSO

L<Hypersonic::Request> - JIT-compiled request object

L<Hypersonic::Response> - Fluent response builder

L<Hypersonic::Socket> - Low-level socket operations

L<Hypersonic::TLS> - TLS/HTTPS support

L<XS::JIT> - The JIT compiler used by Hypersonic

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
