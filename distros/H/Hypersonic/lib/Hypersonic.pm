package Hypersonic;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

use Scalar::Util qw(blessed);
use XS::JIT;
use XS::JIT::Builder;
use Hypersonic::Socket;
use Hypersonic::Protocol::HTTP1;
use Hypersonic::JIT::Util;

# Cache deparser instance for handler analysis (B::Deparse lazy-loaded)
my $DEPARSER;

# Protocol module for HTTP/1.1 (extensible for HTTP/2 in future)
my $PROTOCOL = 'Hypersonic::Protocol::HTTP1';

# Optional TLS support
my $HAS_TLS = 0;
eval { require Hypersonic::TLS; $HAS_TLS = Hypersonic::TLS::check_openssl(); };

# Check for HTTP/2 support (nghttp2)
my $HAS_HTTP2 = 0;
eval { require Hypersonic::Protocol::HTTP2; $HAS_HTTP2 = Hypersonic::Protocol::HTTP2::check_nghttp2() ? 1 : 0; };

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
    
    # Validate HTTP/2 options
    if ($opts{http2}) {
        die "HTTP/2 requires TLS (set tls => 1)" unless $opts{tls};
        die "HTTP/2 not available (nghttp2 not found)" unless $HAS_HTTP2;
    }
    
    # Security headers configuration
    my $security_headers = $opts{security_headers} // {};
    
    return bless {
        routes    => [],
        compiled  => 0,
        cache_dir => $opts{cache_dir} // '_hypersonic_cache',
        id        => int(rand(100000)),
        # Server options
        host      => $opts{host} // '0.0.0.0',
        port      => $opts{port} // 8080,
        # TLS options
        tls       => $opts{tls} // 0,
        cert_file => $opts{cert_file},
        key_file  => $opts{key_file},
        # HTTP/2 support
        http2     => $opts{http2} // 0,
        # Security hardening options
        max_connections    => $opts{max_connections} // 10000,
        max_request_size   => $opts{max_request_size} // 8192,
        keepalive_timeout  => $opts{keepalive_timeout} // 30,
        recv_timeout       => $opts{recv_timeout} // 30,
        # WebSocket JIT options - granular control
        websocket_rooms      => $opts{websocket_rooms} // 0,  # Enable Room support
        max_rooms            => $opts{max_rooms} // 1000,
        max_clients_per_room => $opts{max_clients_per_room} // 10000,
        # Graceful shutdown
        drain_timeout      => $opts{drain_timeout} // 5,
        # JIT extension points
        c_helpers          => $opts{c_helpers},  # User C helper functions
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
        # Event backend (optional override)
        event_backend => $opts{event_backend},
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

# Health check endpoint - built-in route for load balancer / k8s probes
sub health_check {
    my ($self, $path, $handler) = @_;
    $path //= '/health';
    
    # Default handler returns JSON string (JIT compiled as constant)
    $handler //= sub {
        return '{"status":"ok"}';
    };
    
    return $self->get($path => $handler);
}

# Readiness check endpoint - separate from health for k8s
sub ready_check {
    my ($self, $path, $handler) = @_;
    $path //= '/ready';
    
    $handler //= sub {
        return '{"ready":true}';
    };
    
    return $self->get($path => $handler);
}

# WebSocket route registration
sub websocket {
    my ($self, $path, $handler) = @_;
    
    die "WebSocket path must start with /" unless $path =~ m{^/};
    die "WebSocket handler must be a coderef" unless ref($handler) eq 'CODE';
    
    push @{$self->{websocket_routes} //= []}, {
        path    => $path,
        handler => $handler,
        pattern => $self->_compile_path_pattern($path),
    };
    
    return $self;
}

# Check if any WebSocket routes are registered
sub _has_websocket_routes {
    my ($self) = @_;
    return scalar @{$self->{websocket_routes} // []};
}

# Match a path against WebSocket routes
sub _match_websocket_route {
    my ($self, $path) = @_;
    
    for my $route (@{$self->{websocket_routes} // []}) {
        my $pattern = $route->{pattern};
        if ($path =~ $pattern) {
            # Extract params
            my %params;
            my @captures = ($path =~ $pattern);
            my @param_names = $route->{path} =~ /:(\w+)/g;
            for my $i (0..$#param_names) {
                $params{$param_names[$i]} = $captures[$i] if defined $captures[$i];
            }
            return ($route->{handler}, \%params);
        }
    }
    return;
}

# Compile path pattern (reuse for HTTP routes)
sub _compile_path_pattern {
    my ($self, $path) = @_;
    
    my $pattern = $path;
    $pattern =~ s{:(\w+)}{([^/]+)}g;  # :param -> capture group
    $pattern =~ s{\*}{(.+)}g;          # * -> greedy capture
    return qr{^$pattern$};
}

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
# Accepts either:
#   - CODE ref (traditional Perl middleware, called via call_sv at runtime)
#   - Builder object (has build_before/build_after methods, generates inline C at compile time)
sub before {
    my ($self, $handler) = @_;
    my $is_builder = blessed($handler) && ($handler->can('build_before') || $handler->can('build_after'));
    die "Middleware must be a code ref or builder object"
        unless ref($handler) eq 'CODE' || $is_builder;
    push @{$self->{before_middleware}}, $handler;
    return $self;
}

sub after {
    my ($self, $handler) = @_;
    my $is_builder = blessed($handler) && ($handler->can('build_before') || $handler->can('build_after'));
    die "Middleware must be a code ref or builder object"
        unless ref($handler) eq 'CODE' || $is_builder;
    push @{$self->{after_middleware}}, $handler;
    return $self;
}

# Enable request ID tracing - adds X-Request-ID header
# Only loads middleware module when called (JIT philosophy)
sub enable_request_id {
    my ($self, %opts) = @_;

    require Hypersonic::Middleware::RequestId;

    # Builder pattern: middleware() returns a builder object, not a coderef
    # The builder generates inline C at compile time - zero Perl in hot path
    push @{$self->{before_middleware}}, Hypersonic::Middleware::RequestId::middleware(%opts);
    push @{$self->{after_middleware}}, Hypersonic::Middleware::RequestId::after_middleware(%opts);

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

# Async/Future Pool configuration - JIT-compiled thread pool for async operations
# Only loads Future/Pool when called (JIT philosophy)
sub async_pool {
    my ($self, %opts) = @_;

    require Hypersonic::Future;
    require Hypersonic::Future::Pool;

    # Create a Pool instance (OO - allows multiple pools)
    my $pool = Hypersonic::Future::Pool->new(
        workers    => $opts{workers}    // 8,
        queue_size => $opts{queue_size} // 4096,
    );

    # Store in array for event loop registration
    push @{$self->{_async_pools} //= []}, $pool;

    # Mark that async pool is enabled - JIT code gen will include thread pool
    $self->{_async_enabled} = 1;

    # Return the Pool object (not $self anymore)
    return $pool;
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
        parse_query      => 0,  # Parse ?key=value query strings
        parse_headers    => 0,  # Parse HTTP headers
        parse_cookies    => 0,  # Parse Cookie header
        parse_json       => 0,  # Parse JSON body (requires Cpanel::JSON::XS)
        parse_form       => 0,  # Parse form-urlencoded body
        response_helpers => 0,  # JIT compile response helper methods
        streaming        => 0,  # Streaming response handler
        need_xs_builder  => 0,  # Handler receives XS::JIT::Builder
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

    # Streaming handlers are always dynamic
    if ($features{streaming}) {
        $dynamic = 1;
    }

    # need_xs_builder handlers are always dynamic (but handled specially at compile time)
    if ($features{need_xs_builder}) {
        $dynamic = 1;
    }

    push @{$self->{routes}}, {
        method          => $method,
        path            => $path,
        handler         => $handler,
        dynamic         => $dynamic,
        streaming       => $features{streaming},
        need_xs_builder => $features{need_xs_builder},
        params          => \@params,
        segments        => \@segments,
        features        => \%features,
        # Per-route middleware (optional)
        before    => $opts->{before} // [],
        after     => $opts->{after} // [],
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
        needs_response_helpers => 0,  # Any route needs response helper methods?
        needs_streaming  => 0,    # Any route uses streaming responses?
        needs_xs_builder => 0,    # Any route uses need_xs_builder?
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
            $analysis{needs_response_helpers} = 1 if $f->{response_helpers};
            $analysis{needs_streaming} = 1 if $f->{streaming};
            $analysis{needs_xs_builder} = 1 if $f->{need_xs_builder};
            
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

    # Async Pool support: enable thread pool integration
    if ($self->{_async_enabled}) {
        $analysis{needs_async_pool} = 1;
    }

    # Classify middleware as builder (inline C) or Perl (call_sv)
    # Builder middleware has build_before/build_after methods and generates C at compile time
    my (@builder_before, @perl_before, @builder_after, @perl_after);
    for my $mw (@{$self->{before_middleware}}) {
        if (blessed($mw) && ($mw->can('build_before') || $mw->can('build_after'))) {
            push @builder_before, $mw;
        } else {
            push @perl_before, $mw;
        }
    }
    for my $mw (@{$self->{after_middleware}}) {
        if (blessed($mw) && ($mw->can('build_before') || $mw->can('build_after'))) {
            push @builder_after, $mw;
        } else {
            push @perl_after, $mw;
        }
    }

    $analysis{builder_before} = \@builder_before;
    $analysis{builder_after}  = \@builder_after;
    $analysis{perl_before}    = \@perl_before;
    $analysis{perl_after}     = \@perl_after;
    $analysis{has_builder_before} = @builder_before > 0;
    $analysis{has_builder_after}  = @builder_after > 0;
    # Update flags: has_global_* now refers to Perl middleware only (for call_sv)
    $analysis{has_global_before} = @perl_before > 0;
    $analysis{has_global_after}  = @perl_after > 0;

    # Allocate slots for builder middleware
    # Request slots 0-15 are reserved for core fields (see Hypersonic::Request)
    # Middleware slots start at 16
    my $next_slot = 16;
    my %middleware_slots;
    for my $mw (@builder_before, @builder_after) {
        next unless $mw->can('slot_requirements');
        my $reqs = $mw->slot_requirements;
        for my $name (keys %$reqs) {
            next if exists $middleware_slots{$name};  # Deduplicate
            $middleware_slots{$name} = $next_slot;
            $next_slot += $reqs->{$name};
        }
    }
    $analysis{middleware_slots} = \%middleware_slots;

    # Determine if any middleware is present (global or per-route)
    $analysis{has_any_middleware} = $analysis{has_global_before} ||
                                    $analysis{has_global_after} ||
                                    $analysis{has_builder_before} ||
                                    $analysis{has_builder_after} ||
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

    # Compile JIT request accessors (after analysis so we know what features are needed)
    require Hypersonic::Request;
    Hypersonic::Request->compile_accessors(
        cache_dir        => $self->{cache_dir},
        response_helpers => $analysis{needs_response_helpers},
    );

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
            
            # need_xs_builder routes are handled later in code generation
            if ($route->{need_xs_builder}) {
                $route->{dynamic} = 1;  # Treat as dynamic for dispatch
                push @dynamic_handlers, $route->{handler};
                push @route_param_info, $route->{params};
                $route->{handler_idx} = $#dynamic_handlers;
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

            # Build COMPLETE HTTP response via Protocol module (JIT at compile time)
            my $security_hdrs = $self->{enable_security_headers} 
                              ? $self->_get_security_headers_string() 
                              : '';
            
            my $full_response = $PROTOCOL->build_response(
                status           => $status,
                headers          => $headers,
                body             => $body,
                keep_alive       => 1,
                security_headers => $security_hdrs,
            );

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

    # JIT: Build streaming handlers lookup table (only if streaming is enabled)
    if ($self->{route_analysis}{needs_streaming}) {
        my @streaming_flags;
        for my $route (@{$self->{routes}}) {
            next unless $route->{dynamic};
            push @streaming_flags, $route->{streaming} ? 1 : 0;
        }
        $self->{_streaming_flags} = \@streaming_flags;
    }

    # JIT: Build WebSocket handlers lookup table
    if ($self->_has_websocket_routes()) {
        my @ws_handlers;
        my @ws_paths;
        for my $route (@{$self->{websocket_routes}}) {
            push @ws_handlers, $route->{handler};
            push @ws_paths, $route->{path};
            # Check for Room usage in route options
            if ($route->{opts}{rooms}) {
                $self->{route_analysis}{needs_websocket_rooms} = 1;
            }
        }
        $self->{_websocket_handlers} = \@ws_handlers;
        $self->{_websocket_paths} = \@ws_paths;
        $self->{route_analysis}{needs_websocket} = 1;
        # Handler is needed if we have websocket routes
        $self->{route_analysis}{needs_websocket_handler} = 1;
        # WebSocket uses Stream for connection handling
        $self->{route_analysis}{needs_streaming} = 1;
    }

    # JIT: Explicit opt-in for Room support (can also be set in new())
    if ($self->{websocket_rooms}) {
        $self->{route_analysis}{needs_websocket_rooms} = 1;
    }

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

    # JIT: Store Perl-only middleware for runtime call_sv dispatch
    # Builder middleware is handled at compile time (inline C), not runtime
    if ($analysis->{has_global_before} || $analysis->{has_global_after}) {
        $self->{_perl_before_mw} = $analysis->{perl_before};
        $self->{_perl_after_mw}  = $analysis->{perl_after};
    }

    # Generate C code with pure C event loop
    my $c_code = $self->_generate_server_code(\@full_responses);

    # Compile via XS::JIT
    my $module_name = 'Hypersonic::_Server_' . $self->{id};
    
    # Build compile options - add TLS flags if enabled
    my %functions = (
        "${module_name}::run_event_loop" => {
            source       => 'hypersonic_run_event_loop',
            is_xs_native => 1,
        },
        "${module_name}::dispatch" => {
            source       => 'hypersonic_dispatch',
            is_xs_native => 1,
        },
    );

    # Add Stream and SSE XS functions if streaming is enabled
    if ($self->{route_analysis}{needs_streaming}) {
        %functions = (%functions, %{Hypersonic::Stream->get_xs_functions()});
        %functions = (%functions, %{Hypersonic::SSE->get_xs_functions()});
    }

    # Add WebSocket XS functions if WebSocket routes are registered
    if ($self->{route_analysis}{needs_websocket}) {
        require Hypersonic::WebSocket;
        %functions = (%functions, %{Hypersonic::WebSocket->get_xs_functions()});
    }

    # Add WebSocket Handler XS functions
    if ($self->{route_analysis}{needs_websocket_handler}) {
        require Hypersonic::WebSocket::Handler;
        %functions = (%functions, %{Hypersonic::WebSocket::Handler->get_xs_functions()});
    }

    # Add WebSocket Room XS functions
    if ($self->{route_analysis}{needs_websocket_rooms}) {
        require Hypersonic::WebSocket::Room;
        %functions = (%functions, %{Hypersonic::WebSocket::Room->get_xs_functions()});
    }

    # Add Future/Pool XS functions if async pool is enabled
    if ($self->{route_analysis}{needs_async_pool}) {
        require Hypersonic::Future;
        require Hypersonic::Future::Pool;
        %functions = (%functions, %{Hypersonic::Future->get_xs_functions()});
        %functions = (%functions, %{Hypersonic::Future::Pool->get_xs_functions()});
    }

    # Add need_xs_builder route additional XS functions (if any)
    # Note: The main handler functions are C functions called by call_xs_builder_handler,
    # NOT XS functions callable from Perl, so we don't register them.
    if (my $xsr = $self->{_xs_builder_routes}) {
        for my $entry (@$xsr) {
            my $result = $entry->{result};
            
            # Add any additional XS functions the handler defined
            if ($result->{xs_functions}) {
                %functions = (%functions, %{$result->{xs_functions}});
            }
        }
    }

    my %compile_opts = (
        code      => $c_code,
        name      => $module_name,
        cache_dir => $self->{cache_dir},
        functions => \%functions,
    );
    
    # Add OpenSSL flags for TLS support
    if ($self->{tls}) {
        $compile_opts{extra_cflags} = Hypersonic::TLS::get_extra_cflags();
        $compile_opts{extra_ldflags} = Hypersonic::TLS::get_extra_ldflags();
    }
    
    # Add nghttp2 flags for HTTP/2 support
    if ($self->{http2}) {
        require Hypersonic::Protocol::HTTP2;
        my $h2_cflags = Hypersonic::Protocol::HTTP2::get_extra_cflags();
        my $h2_ldflags = Hypersonic::Protocol::HTTP2::get_extra_ldflags();
        $compile_opts{extra_cflags} = ($compile_opts{extra_cflags} // '') . " $h2_cflags";
        $compile_opts{extra_ldflags} = ($compile_opts{extra_ldflags} // '') . " $h2_ldflags";
    }
    
    # Add zlib flags for compression support
    if ($self->{_compression_enabled}) {
        require Hypersonic::Compress;
        my ($cflags, $ldflags) = Hypersonic::Compress::get_zlib_flags();
        $compile_opts{extra_cflags} = ($compile_opts{extra_cflags} // '') . " $cflags";
        $compile_opts{extra_ldflags} = ($compile_opts{extra_ldflags} // '') . " $ldflags";
    }

    # Add pthread flags for async pool (thread pool)
    if ($self->{route_analysis}{needs_async_pool}) {
        $compile_opts{extra_cflags} = ($compile_opts{extra_cflags} // '') . " -pthread";
        $compile_opts{extra_ldflags} = ($compile_opts{extra_ldflags} // '') . " -lpthread";
    }

    # Add event backend flags (e.g., io_uring needs -luring)
    if ($self->{_event_backend}) {
        my $backend = $self->{_event_backend};
        if ($backend->can('extra_cflags')) {
            my $ev_cflags = $backend->extra_cflags // '';
            $compile_opts{extra_cflags} = ($compile_opts{extra_cflags} // '') . " $ev_cflags"
                if $ev_cflags;
        }
        if ($backend->can('extra_ldflags')) {
            my $ev_ldflags = $backend->extra_ldflags // '';
            $compile_opts{extra_ldflags} = ($compile_opts{extra_ldflags} // '') . " $ev_ldflags"
                if $ev_ldflags;
        }
    }

    XS::JIT->compile(%compile_opts);

    # Store function references
    {
        no strict 'refs';
        $self->{run_loop_fn} = \&{"${module_name}::run_event_loop"};
        $self->{dispatch_fn} = \&{"${module_name}::dispatch"};
    }

    # Mark Future/Pool as compiled if async pool is enabled
    # (prevents them from trying to compile separately)
    if ($self->{route_analysis}{needs_async_pool}) {
        $Hypersonic::Future::COMPILED = 1;
        $Hypersonic::Future::Pool::COMPILED = 1;
        # Register custom ops for Future after compilation
        Hypersonic::Future->_register_ops();
    }

    $self->{compiled} = 1;
    return $self;
}

sub _generate_server_code {
    my ($self, $full_responses) = @_;

    # Load event backend module
    require Hypersonic::Event;
    my $backend_name = $self->{event_backend} // Hypersonic::Event->best_backend;
    my $backend = Hypersonic::Event->backend($backend_name);

    # Store backend for use in event loop generation
    $self->{_event_backend} = $backend;
    $self->{_event_backend_name} = $backend_name;

    my $builder = XS::JIT::Builder->new;

    # C99 detection for inline keyword
    my $inline = Hypersonic::JIT::Util->inline_keyword;

    # Check if we have any dynamic routes
    my $has_dynamic = grep { $_->{dynamic} } @{$self->{routes}};

    # Common includes
    $builder->line('#include <string.h>')
      ->line('#include <unistd.h>')
      ->line('#include <fcntl.h>')
      ->line('#include <errno.h>')
      ->line('#include <sys/socket.h>')
      ->line('#include <sys/types.h>')
      ->line('#include <netinet/in.h>')
      ->line('#include <netinet/tcp.h>');

    # Backend-specific includes
    $builder->line($backend->includes);
    
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
    
    # HTTP/2 support - include nghttp2 if enabled
    if ($self->{http2}) {
        require Hypersonic::Protocol::HTTP2;
        Hypersonic::Protocol::HTTP2->gen_includes($builder);
    }

    # Security hardening configuration
    my $max_connections = $self->{max_connections};
    my $max_request_size = $self->{max_request_size};
    my $keepalive_timeout = $self->{keepalive_timeout};
    my $recv_timeout = $self->{recv_timeout};
    my $drain_timeout = $self->{drain_timeout};

    # Backend-specific defines
    $builder->blank
      ->line($backend->defines)
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

    # User-defined C helpers (early, so they're available to all routes)
    if (my $helpers = $self->{c_helpers}) {
        $builder->comment('User-defined C helpers');
        if (ref $helpers eq 'CODE') {
            my $helper_builder = XS::JIT::Builder->new;
            $helpers->($helper_builder);
            $builder->raw($helper_builder->code);
        } else {
            # Raw C string
            $builder->raw($helpers);
        }
        $builder->blank;
    }

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
          ->line('    size_t max_out;')
          ->line('    z_stream strm;')
          ->line('    int ret;')
          ->line('    size_t compressed_len;')
          ->line("    if (input_len < $min_size) return 0;")
          ->line('    max_out = compressBound(input_len) + 18;')
          ->line('    if (max_out > sizeof(gzip_out_buf)) return 0;')
          ->line('    memset(&strm, 0, sizeof(strm));')
          ->line("    if (deflateInit2(&strm, $level, Z_DEFLATED, 15 + 16, 8, Z_DEFAULT_STRATEGY) != Z_OK) return 0;")
          ->line('    strm.next_in = (Bytef*)input;')
          ->line('    strm.avail_in = input_len;')
          ->line('    strm.next_out = gzip_out_buf;')
          ->line('    strm.avail_out = sizeof(gzip_out_buf);')
          ->line('    ret = deflate(&strm, Z_FINISH);')
          ->line('    compressed_len = strm.total_out;')
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
      ->line("static $inline void track_connection(int fd, time_t now) {")
      ->line('    if (fd >= 0 && fd < MAX_FD) {')
      ->line('        g_conn_time[fd] = now;')
      ->line('        g_active_connections++;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line("static $inline void update_connection(int fd, time_t now) {")
      ->line('    if (fd >= 0 && fd < MAX_FD) {')
      ->line('        g_conn_time[fd] = now;')
      ->line('    }')
      ->line('}')
      ->blank
      ->line("static $inline void remove_connection(int fd) {")
      ->line('    if (fd >= 0 && fd < MAX_FD && g_conn_time[fd] > 0) {')
      ->line('        g_conn_time[fd] = 0;')
      ->line('        g_active_connections--;')
      ->line('    }')
      ->line('}')
      ->blank;

    # TLS code generation - SSL context, accept, read/write wrappers
    if ($self->{tls}) {
        $builder->comment('TLS/HTTPS support via OpenSSL')
          ->raw(Hypersonic::TLS::gen_ssl_ctx_init(http2 => $self->{http2}))
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_accept())
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_io())
          ->blank
          ->raw(Hypersonic::TLS::gen_ssl_close())
          ->blank;
    }
    
    # HTTP/2 code generation - nghttp2 callbacks, session init, dispatchers
    if ($self->{http2}) {
        require Hypersonic::Protocol::HTTP2;
        $builder->comment('HTTP/2 support via nghttp2');
        Hypersonic::Protocol::HTTP2->gen_connection_struct($builder);
        Hypersonic::Protocol::HTTP2->gen_connection_preface_check($builder);
        Hypersonic::Protocol::HTTP2->gen_response_sender($builder);
        Hypersonic::Protocol::HTTP2->gen_404_response($builder);
        Hypersonic::Protocol::HTTP2->gen_callbacks($builder);
        Hypersonic::Protocol::HTTP2->gen_session_init($builder);
        Hypersonic::Protocol::HTTP2->gen_dispatcher($builder);
        Hypersonic::Protocol::HTTP2->gen_input_processor($builder);
        $builder->blank;
    }

    # Streaming support - JIT: only generate when streaming handlers detected
    my $analysis = $self->{route_analysis};
    if ($analysis->{needs_streaming}) {
        require Hypersonic::Stream;
        Hypersonic::Stream->generate_c_code($builder, {
            max_streams => $self->{max_connections},
        });

        # SSE support - compile SSE methods when streaming is enabled
        require Hypersonic::SSE;
        Hypersonic::SSE->generate_c_code($builder, {
            max_sse_instances => $self->{max_connections},
        });
    }

    # WebSocket support - JIT: only generate when WebSocket routes exist
    if ($analysis->{needs_websocket}) {
        require Hypersonic::WebSocket;
        require Hypersonic::Protocol::WebSocket;
        require Hypersonic::Protocol::WebSocket::Frame;

        # Generate WebSocket frame encoding functions
        Hypersonic::Protocol::WebSocket::Frame->generate_c_code($builder, {
            max_connections => $self->{max_connections},
        });

        # Generate WebSocket connection management
        Hypersonic::WebSocket->generate_c_code($builder, {
            max_websockets => $self->{max_connections},
        });
    }

    # WebSocket Handler - JIT: connection registry, only when websocket routes exist
    if ($analysis->{needs_websocket_handler}) {
        require Hypersonic::WebSocket::Handler;
        Hypersonic::WebSocket::Handler->generate_c_code($builder, {
            max_connections => $self->{max_connections},
        });
    }

    # WebSocket Rooms - JIT: broadcast groups, only when explicitly enabled
    if ($analysis->{needs_websocket_rooms}) {
        require Hypersonic::WebSocket::Room;
        Hypersonic::WebSocket::Room->generate_c_code($builder, {
            max_rooms => $self->{max_rooms},
            max_clients_per_room => $self->{max_clients_per_room},
        });
    }

    # Future/Pool - JIT: async thread pool for blocking operations
    if ($analysis->{needs_async_pool}) {
        require Hypersonic::Future;
        require Hypersonic::Future::Pool;
        my $async_config = $self->{_async_config} // {};
        Hypersonic::Future->generate_c_code($builder, {
            max_futures => $async_config->{max_futures} // 65536,
        });
        Hypersonic::Future::Pool->generate_c_code($builder, {
            workers    => $async_config->{workers}    // 8,
            queue_size => $async_config->{queue_size} // 4096,
        });
    }

    # need_xs_builder routes - call handlers with fresh builder
    if ($analysis->{needs_xs_builder}) {
        my @xs_builder_routes;
        for my $i (0 .. $#{$self->{routes}}) {
            my $route = $self->{routes}[$i];
            next unless $route->{need_xs_builder};
            
            # Create fresh builder for this handler
            my $ext_builder = XS::JIT::Builder->new;
            
            # Call handler with clean builder
            my $result = $route->{handler}->($ext_builder);
            
            die "need_xs_builder handler for $route->{method} $route->{path} must return hashref with xs_function"
                unless ref($result) eq 'HASH' && $result->{xs_function};
            
            # Store result
            $route->{_xs_result} = $result;
            push @xs_builder_routes, {
                route_idx   => $i,
                route       => $route,
                result      => $result,
                code        => $ext_builder->code,
            };
        }
        
        # Emit generated code
        if (@xs_builder_routes) {
            $builder->comment('User XS builder routes');
            for my $xsr (@xs_builder_routes) {
                $builder->comment("Route: $xsr->{route}{method} $xsr->{route}{path}")
                        ->raw($xsr->{code})
                        ->blank;
            }
        }
        
        # Store for function merging later
        $self->{_xs_builder_routes} = \@xs_builder_routes;
    }

    # JIT: WebSocket handler storage (independent of dynamic routes)
    if ($analysis->{needs_websocket}) {
        $builder->comment('WebSocket handler storage')
          ->line('static SV* g_websocket_handlers = NULL;')
          ->blank;
    }

    # Global storage for dynamic handler dispatch (only if needed)
    if ($has_dynamic) {
        $builder->comment('Storage for dynamic handler callbacks')
          ->line('static SV* g_handler_array = NULL;')
          ->line('static SV* g_server_obj = NULL;');

        # JIT: Only generate middleware storage if middleware is present
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

        # JIT: Streaming handler flags array (only if streaming is enabled)
        if ($analysis->{needs_streaming} && $self->{_streaming_flags}) {
            my @flags = @{$self->{_streaming_flags}};
            my $flags_str = join(', ', @flags);
            $builder->comment('Streaming handler flags - 1 = streaming, 0 = normal')
              ->line("static int g_streaming_handlers[$handler_count] = { $flags_str };")
              ->blank;
        }
    }

    # JIT: WebSocket route paths array (only if WebSocket routes exist)
    if ($analysis->{needs_websocket} && $self->{_websocket_paths}) {
        my @paths = @{$self->{_websocket_paths}};
        my $ws_count = scalar @paths;
        $builder->comment('WebSocket route paths');
        for my $i (0 .. $#paths) {
            my $escaped = _escape_c_string($paths[$i]);
            $builder->line(qq{static const char WS_PATH_$i\[] = "$escaped";});
        }
        $builder->line("static const char* g_ws_paths[$ws_count] = {");
        for my $i (0 .. $#paths) {
            my $comma = ($i < $#paths) ? ',' : '';
            $builder->line("    WS_PATH_$i$comma");
        }
        $builder->line('};')
          ->line("static const int g_ws_path_count = $ws_count;")
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

    # 404 response via Protocol module
    my $security_hdrs_404 = $self->{enable_security_headers} 
                          ? $self->_get_security_headers_string() 
                          : '';
    my $resp_404 = $PROTOCOL->build_404_response(
        security_headers => $security_hdrs_404,
    );
    
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

    # Generate XS builder route dispatcher if needed
    if ($analysis->{needs_xs_builder} && $self->{_xs_builder_routes} && @{$self->{_xs_builder_routes}}) {
        $builder->raw($self->_gen_xs_builder_dispatcher())
          ->blank;
    }

    # Generate WebSocket handler caller if needed
    if ($analysis->{needs_websocket}) {
        $builder->raw($self->_gen_websocket_handler_caller())
          ->blank;
        $builder->raw($self->_gen_websocket_data_processor())
          ->blank;
    }

    # Group routes by method for dispatch generation
    my %methods;
    for my $route (@{$self->{routes}}) {
        push @{$methods{$route->{method}}}, $route;
    }

    # Generate inline C dispatch function
    $builder->comment('Inline dispatch - returns response pointer and length')
      ->comment('Returns: 0=static response, 1=dynamic route, 2=XS builder route, -1=404')
      ->comment('For dynamic/XS routes: returns handler_idx in *handler_idx_out')
      ->line("static $inline int dispatch_request(const char* method, int method_len, const char* path, int path_len, const char** resp_out, int* resp_len_out, int* handler_idx_out) {")
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

                # Check if this is a need_xs_builder route - dispatch to XS directly
                if ($r->{need_xs_builder} && $r->{_xs_result}) {
                    my $xs_func = $r->{_xs_result}{xs_function};
                    my $escaped_path = _escape_c_string($path);
                    
                    if ($path =~ /:(\w+)/) {
                        # Path has parameters
                        my ($prefix) = $path =~ m{^([^:]+)};
                        my $prefix_len = length($prefix);
                        my $escaped_prefix = _escape_c_string($prefix);
                        
                        $builder->if("path_len >= $prefix_len && memcmp(path, \"$escaped_prefix\", $prefix_len) == 0")
                          ->comment("XS builder route - call $xs_func directly")
                          ->line("*handler_idx_out = $handler_idx;")
                          ->line("return 2;")  # Special return code for XS builder routes
                          ->endif;
                    } else {
                        # Exact match
                        $builder->if("path_len == $plen && memcmp(path, \"$escaped_path\", $plen) == 0")
                          ->comment("XS builder route - call $xs_func directly")
                          ->line("*handler_idx_out = $handler_idx;")
                          ->line("return 2;")  # Special return code for XS builder routes
                          ->endif;
                    }
                } elsif ($path =~ /:(\w+)/) {
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

    # Generate the pure C event loop using backend module
    $self->_gen_event_loop($builder, $backend);
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

# Generate optimized method parser - delegates to Protocol module
sub _gen_method_parser {
    my ($self, $builder) = @_;
    my $analysis = $self->{route_analysis};

    # Delegate to Protocol module for HTTP/1.1 parsing
    # This separation allows future HTTP/2 support without changing core logic
    return $PROTOCOL->gen_method_parser($builder, $analysis);
}

# Generate WebSocket frame handling for established connections
sub _gen_websocket_frame_handler {
    my ($self, $builder) = @_;

    $builder->comment('Check if this is an established WebSocket connection')
      ->if('fd >= 0 && fd < WS_MAX && ws_registry[fd].state == WS_STATE_OPEN')
        ->comment('This is a WebSocket connection - process frames')
        ->line('process_websocket_data(aTHX_ fd, recv_buf, len);')
        ->line('continue;')
      ->endif
      ->blank;
}

# Generate WebSocket upgrade detection and dispatch
sub _gen_websocket_dispatch {
    my ($self, $builder) = @_;

    $builder->comment('WebSocket upgrade detection')
      ->comment('Check for Upgrade: websocket header')
      ->line('int is_websocket = 0;')
      ->line('int ws_handler_idx = -1;')
      ->line('const char* ws_key = NULL;')
      ->line('int ws_key_len = 0;')
      ->blank
      ->comment('Look for Upgrade header in raw request')
      ->line('const char* upgrade_pos = strstr(recv_buf, "Upgrade:");')
      ->if('!upgrade_pos')
        ->line('upgrade_pos = strstr(recv_buf, "upgrade:");')
      ->endif
      ->if('upgrade_pos')
        ->line('const char* val_start = upgrade_pos + 8;')
        ->line('while (*val_start == \' \') val_start++;')
        ->comment('Check for websocket (case-insensitive)')
        ->if('strncasecmp(val_start, "websocket", 9) == 0')
          ->line('is_websocket = 1;')
        ->endif
      ->endif
      ->blank
      ->if('is_websocket')
        ->comment('Extract Sec-WebSocket-Key')
        ->line('const char* key_pos = strstr(recv_buf, "Sec-WebSocket-Key:");')
        ->if('!key_pos')
          ->line('key_pos = strstr(recv_buf, "sec-websocket-key:");')
        ->endif
        ->if('key_pos')
          ->line('const char* key_start = key_pos + 18;')
          ->line('while (*key_start == \' \') key_start++;')
          ->line('const char* key_end = key_start;')
          ->line('while (*key_end && *key_end != \'\\r\' && *key_end != \'\\n\') key_end++;')
          ->line('ws_key = key_start;')
          ->line('ws_key_len = key_end - key_start;')
        ->endif
        ->blank
        ->comment('Match path to WebSocket routes')
        ->line('int clean_path_len = path_len;')
        ->line('const char* qmark = memchr(path, \'?\', path_len);')
        ->if('qmark')
          ->line('clean_path_len = qmark - path;')
        ->endif
        ->for('int i = 0', 'i < g_ws_path_count', 'i++')
          ->line('int ws_path_len = strlen(g_ws_paths[i]);')
          ->if('clean_path_len == ws_path_len && memcmp(path, g_ws_paths[i], ws_path_len) == 0')
            ->line('ws_handler_idx = i;')
            ->line('break;')
          ->endif
        ->endfor
        ->blank
        ->if('ws_handler_idx >= 0 && ws_key')
          ->comment('WebSocket upgrade - call Perl handler')
          ->line('call_websocket_handler(aTHX_ ws_handler_idx, fd, path, path_len, ws_key, ws_key_len, recv_buf, len);')
          ->line('continue;')  # Skip normal dispatch, connection stays open
        ->endif
      ->endif
      ->blank;
}

# Unified event loop generator - uses backend module for platform-specific code
sub _gen_event_loop {
    my ($self, $builder, $backend) = @_;
    my $has_dynamic = grep { $_->{dynamic} } @{$self->{routes}};
    my $analysis = $self->{route_analysis};
    my $has_body_access = $analysis->{has_body_access} // 0;
    my $backend_name = $backend->name;
    my $event_struct = $backend->event_struct;

    $builder->comment("Pure C event loop using $backend_name backend - WITH SECURITY HARDENING")
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
              ->comment('JIT: Middleware storage (Perl coderefs only - builders are inline C)');

            # Only fetch Perl middleware if we have any
            if ($analysis->{has_global_before}) {
                $builder->line('SV** before_ref = hv_fetch(self, "_perl_before_mw", 15, 0);')
                  ->if('before_ref && SvROK(*before_ref)')
                    ->line('g_before_middleware = *before_ref;')
                    ->line('SvREFCNT_inc(g_before_middleware);')
                  ->endif;
            }
            if ($analysis->{has_global_after}) {
                $builder->line('SV** after_ref = hv_fetch(self, "_perl_after_mw", 14, 0);')
                  ->if('after_ref && SvROK(*after_ref)')
                    ->line('g_after_middleware = *after_ref;')
                    ->line('SvREFCNT_inc(g_after_middleware);')
                  ->endif;
            }

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

    # WebSocket handler storage (only if WebSocket routes)
    if ($analysis->{needs_websocket}) {
        $builder->comment('Store WebSocket handlers for dispatch')
          ->if('SvROK(server_obj)')
            ->declare_hv('ws_self', '(HV*)SvRV(server_obj)')
            ->line('SV** ws_handlers_ref = hv_fetch(ws_self, "_websocket_handlers", 19, 0);')
            ->if('ws_handlers_ref && SvROK(*ws_handlers_ref)')
              ->line('g_websocket_handlers = *ws_handlers_ref;')
              ->line('SvREFCNT_inc(g_websocket_handlers);')
            ->endif
          ->endif
          ->blank;
    }

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

    # Backend-specific: Create event loop and add listen socket
    $backend->gen_create($builder, 'listen_fd');

    # Async Pool: Initialize thread pool and add notify fd to event loop
    if ($analysis->{needs_async_pool}) {
        $builder->blank
          ->comment('Initialize async thread pool')
          ->line('pool_init();')
          ->line('int pool_notify_fd = pool_get_notify_fd();');
        $backend->gen_add_pool_notify($builder, 'ev_fd', 'pool_notify_fd');
    }

    # Declare event structure variable based on backend
    if ($backend_name eq 'kqueue') {
        # kqueue's gen_create already declares 'ev', but we need events array
        $builder->line('struct kevent events[MAX_EVENTS];');
    } elsif ($backend_name eq 'epoll') {
        # epoll's gen_create already declares 'ev'
        $builder->line('struct epoll_event events[MAX_EVENTS];');
    } elsif ($backend_name eq 'io_uring') {
        # io_uring uses completion queue entries
        $builder->line('struct io_uring_cqe** events = NULL;');
    } else {
        # poll/select manage their own fd arrays internally
        # Declare a dummy events pointer to satisfy gen_wait signature
        $builder->line('void* events = NULL;');
    }

    $builder->line('time_t last_cleanup = time(NULL);')
      ->line('int accepting = 1;  /* Flag to control accepting new connections */')
      ->blank;

    # Main event loop
    $builder->while('!g_shutdown || g_active_connections > 0')
        ->comment('Use timeout for keep-alive cleanup and shutdown check');

    # Backend-specific: Wait for events
    $backend->gen_wait($builder, 'ev_fd', 'events', 'n', '1000');

    $builder->blank
        ->comment('Check for graceful shutdown - stop accepting new connections')
        ->if('g_shutdown && accepting');

    # Backend-specific: Remove listen socket from event loop
    $backend->gen_del($builder, 'ev_fd', 'listen_fd');
    $builder->line('accepting = 0;')
        ->endif
        ->blank
        ->comment('Get time once per event batch')
        ->line('time_t now = time(NULL);')
        ->line('g_current_time = now;')
        ->blank;

    # Keep-alive cleanup
    $builder->comment('Periodic keep-alive timeout cleanup')
      ->if('now - last_cleanup >= 5')
        ->declare('int', 'cleanup_i', '0')
        ->for('cleanup_i = 0', 'cleanup_i < MAX_FD', 'cleanup_i++')
          ->if('g_conn_time[cleanup_i] > 0')
            ->if('now - g_conn_time[cleanup_i] > KEEPALIVE_TIMEOUT')
              ->comment('Close idle connection')
              ->line('int idle_fd = cleanup_i;');

    # Backend-specific: Remove idle connection
    $backend->gen_del($builder, 'ev_fd', 'idle_fd');
    $builder->line('HYPERSONIC_CLOSE(idle_fd);')
              ->line('remove_connection(idle_fd);')
            ->endif
          ->endif
        ->endfor
        ->line('last_cleanup = now;')
      ->endif
      ->blank;

    # Event processing loop
    $builder->declare('int', 'i', '0')
      ->for('i = 0', 'i < n', 'i++');

    # Backend-specific: Get fd from event
    $backend->gen_get_fd($builder, 'events', 'i', 'fd');

    $builder->blank
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
        ->comment('Add to event loop');

    # Backend-specific: Add client to event loop
    $backend->gen_add($builder, 'ev_fd', 'client_fd');
    $builder->endwhile;

    # Async Pool: Handle pool notify fd - process completed futures
    if ($analysis->{needs_async_pool}) {
        $builder->elsif('fd == pool_notify_fd')
          ->comment('Thread pool notification - process completed async operations')
          ->line('pool_process_ready();');
    }

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
        ->comment('Connection closed or error');

    # Backend-specific: Remove from event loop
    $backend->gen_del($builder, 'ev_fd', 'fd');
    $builder->line('#ifdef HYPERSONIC_TLS')
        ->line('tls_close(fd);')
        ->line('#else')
        ->line('close(fd);')
        ->line('#endif');

    # Reset WebSocket state if WebSocket routes exist
    if ($analysis->{needs_websocket}) {
        $builder->line('ws_reset(fd);');
    }

    $builder->line('remove_connection(fd);')
        ->line('continue;')
      ->endif
      ->blank
      ->comment('Update connection activity for keep-alive timeout')
      ->line('update_connection(fd, now);')
      ->blank
      ->line('recv_buf[len] = \'\\0\';')
      ->blank;

    # WebSocket frame handling - JIT: only generate if WebSocket routes exist
    if ($analysis->{needs_websocket}) {
        $self->_gen_websocket_frame_handler($builder);
    }

    # Method parser - delegates to Protocol module
    $self->_gen_method_parser($builder);
    $builder->blank;

    # Path parsing - delegates to Protocol module
    $PROTOCOL->gen_path_parser($builder);
    $builder->blank;

    # WebSocket upgrade detection - JIT: only generate if WebSocket routes exist
    if ($analysis->{needs_websocket}) {
        $self->_gen_websocket_dispatch($builder);
    }

    # Dispatch
    $builder->comment('Dispatch request')
      ->line('const char* resp;')
      ->line('int resp_len;')
      ->line('int handler_idx;')
      ->line('int dispatch_result = dispatch_request(method, method_len, path, path_len, &resp, &resp_len, &handler_idx);')
      ->blank;

    # Dynamic dispatch
    if ($has_dynamic) {
        # Check for XS builder routes first (dispatch_result == 2)
        if ($analysis->{needs_xs_builder} && $self->{_xs_builder_routes} && @{$self->{_xs_builder_routes}}) {
            $builder->if('dispatch_result == 2')
              ->comment('XS builder route - call generated XS function directly');
            
            # Body parsing for XS builder routes (they may need body access)
            $PROTOCOL->gen_body_parser($builder, has_body_access => $has_body_access);
            
            $builder->blank
              ->line('char* xs_resp;')
              ->line('int xs_resp_len;')
              ->line('call_xs_builder_handler(aTHX_ handler_idx, fd, method, method_len, path, path_len, body, body_len, &xs_resp, &xs_resp_len);')
              ->line('HYPERSONIC_SEND(fd, xs_resp, xs_resp_len);')
            ->elsif('dispatch_result == 1');
        } else {
            $builder->if('dispatch_result == 1');
        }
        
        $builder->comment('Dynamic route - call Perl handler');

        # Body parsing - delegates to Protocol module
        $PROTOCOL->gen_body_parser($builder, has_body_access => $has_body_access);

        $builder->blank
          ->line('char* dyn_resp;')
          ->line('int dyn_resp_len;')
          ->line('call_dynamic_handler(aTHX_ handler_idx, fd, method, method_len, path, full_path_len, body, body_len, recv_buf, len, &dyn_resp, &dyn_resp_len);')
          ->comment('dyn_resp_len == -1 means streaming handler (response already sent)')
          ->line('if (dyn_resp_len >= 0) {')
          ->line('    HYPERSONIC_SEND(fd, dyn_resp, dyn_resp_len);')
          ->line('}')
        ->else
          ->line('HYPERSONIC_SEND(fd, resp, resp_len);')
        ->endif;
    } else {
        $builder->line('HYPERSONIC_SEND(fd, resp, resp_len);');
    }
    $builder->blank;

    # Keep-alive check - delegates to Protocol module
    $PROTOCOL->gen_keepalive_check($builder);
    $builder->blank
      ->if('!keep_alive');

    # Backend-specific: Remove from event loop on close
    $backend->gen_del($builder, 'ev_fd', 'fd');
    $builder->line('HYPERSONIC_CLOSE(fd);');

    # Reset WebSocket state if WebSocket routes exist
    if ($analysis->{needs_websocket}) {
        $builder->line('ws_reset(fd);');
    }

    $builder->line('remove_connection(fd);')
      ->endif;

    # Close event processing
    $builder->endif  # fd == listen_fd
      ->endfor  # for i
      ->endwhile  # main loop
      ->blank;

    # Async Pool: Shutdown thread pool on server exit
    if ($analysis->{needs_async_pool}) {
        $builder->comment('Shutdown async thread pool')
          ->line('pool_shutdown();');
    }

    $builder->line('close(ev_fd);')
      ->xs_return('0')
      ->xs_end;

    return $builder;
}

sub _gen_xs_builder_dispatcher {
    my ($self) = @_;
    
    my $builder = XS::JIT::Builder->new;
    my $xs_routes = $self->{_xs_builder_routes} || [];
    
    return '' unless @$xs_routes;
    
    $builder->comment('XS Builder route dispatcher')
      ->comment('Dispatches to user-defined XS functions based on handler_idx')
      ->line('static void call_xs_builder_handler(pTHX_ int handler_idx, int fd,')
      ->line('                                     const char* method, int method_len,')
      ->line('                                     const char* path, int path_len,')
      ->line('                                     const char* body, int body_len,')
      ->line('                                     char** resp_out, int* resp_len_out) {')
      ->line('    switch (handler_idx) {');
    
    for my $entry (@$xs_routes) {
        my $handler_idx = $entry->{route}{handler_idx};
        my $xs_func = $entry->{result}{xs_function};
        
        $builder->line("        case $handler_idx:")
          ->line("            $xs_func(aTHX_ fd, method, method_len, path, path_len, body, body_len, resp_out, resp_len_out);")
          ->line("            break;");
    }
    
    $builder->line('        default:')
      ->line('            *resp_out = (char*)RESP_404;')
      ->line('            *resp_len_out = RESP_404_LEN;')
      ->line('            break;')
      ->line('    }')
      ->line('}')
      ->blank;
    
    return $builder->code;
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
      ->line('    const char* start;')
      ->line('    const char* end;')
      ->line('    const char* query;')
      ->line('    const char* seg_end;')
      ->line('    start = path;')
      ->line('    end = path + path_len;')
      ->line('    query = memchr(path, \'?\', path_len);')
      ->line('    if (query) end = query;')
      ->line('    while (start < end && count < max_segs) {')
      ->line('        if (*start == \'/\') start++;')
      ->line('        if (start >= end) break;')
      ->line('        seg_end = start;')
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
    
    # JIT: Generate C helpers from builder middleware (static functions at file scope)
    if ($analysis->{has_builder_before} || $analysis->{has_builder_after}) {
        my %seen_classes;
        $builder->comment('JIT: Builder middleware C helpers (zero Perl in hot path)');
        for my $mw (@{$analysis->{builder_before}}, @{$analysis->{builder_after}}) {
            my $class = ref($mw);
            next if $seen_classes{$class}++;  # Deduplicate by class
            if ($mw->can('build_helpers')) {
                $mw->build_helpers($builder);
                $builder->blank;
            }
        }
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
      ->line('static void call_dynamic_handler(pTHX_ int handler_idx, int client_fd,')
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
      ->line('    AV* handlers;')
      ->line('    SV** handler_sv;')
      ->line('    const char* query_start;')
      ->line('    int clean_path_len;')
      ->line('    AV* req;')
      ->line('    const char* segments[16];')
      ->line('    int seg_lens[16];')
      ->line('    int seg_count;')
      ->line('    AV* seg_av;')
      ->line('    int i;')
      ->line('    HV* params_hv;')
      ->line('    RouteParamInfo* param_info;')
      ->line('    SV* req_ref;')
      ->line('    SV* mw_result = NULL;')
      ->line('    int short_circuit = 0;')
      ->line('    HV* headers_hv = NULL;')
      ->line('    int is_streaming = 0;')
      ->line('    SV* stream_sv = NULL;')
      ->blank
      ->line('    if (!g_handler_array) {')
      ->line('        *resp_out = (char*)RESP_404;')
      ->line('        *resp_len_out = RESP_404_LEN;')
      ->line('        return;')
      ->line('    }')
      ->blank
      ->line('    handlers = (AV*)SvRV(g_handler_array);')
      ->line('    handler_sv = av_fetch(handlers, handler_idx, 0);')
      ->line('    if (!handler_sv || !SvROK(*handler_sv)) {')
      ->line('        *resp_out = (char*)RESP_404;')
      ->line('        *resp_len_out = RESP_404_LEN;')
      ->line('        return;')
      ->line('    }')
      ->blank;
    
    # Query string separation
    $builder->comment('Separate path from query string')
      ->line('    query_start = memchr(path, \'?\', path_len);')
      ->line('    clean_path_len = query_start ? (query_start - path) : path_len;')
      ->blank
      ->comment('Build array-based request object (JIT slots)')
      ->comment('Slot layout: METHOD=0, PATH=1, BODY=2, PARAMS=3, QUERY=4, QUERY_STRING=5,')
      ->comment('             HEADERS=6, COOKIES=7, JSON=8, FORM=9, SEGMENTS=10, ID=11')
      ->line('    req = newAV();')
      ->line('    av_extend(req, 11);')  # Pre-allocate 12 slots (0-11)
      ->line('    av_store(req, 0, newSVpvn(method, method_len));')       # SLOT_METHOD
      ->line('    av_store(req, 1, newSVpvn(path, clean_path_len));')     # SLOT_PATH
      ->line('    av_store(req, 2, newSVpvn(body, body_len));')           # SLOT_BODY
      ->blank;

    # Path segments and params - always needed
    $builder->comment('Parse path segments and named params')
      ->line('    seg_count = parse_path_segments(path, path_len, segments, seg_lens, 16);')
      ->line('    seg_av = newAV();')
      ->line('    for (i = 0; i < seg_count; i++) {')
      ->line('        av_push(seg_av, newSVpvn(segments[i], seg_lens[i]));')
      ->line('    }')
      ->line('    av_store(req, 10, newRV_noinc((SV*)seg_av));')  # SLOT_SEGMENTS
      ->blank
      ->comment('Build named params from route_param_info table')
      ->line('    params_hv = newHV();')
      ->line('    param_info = &g_route_params[handler_idx];')
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
          ->line('    headers_hv = newHV();')
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
      ->line('    req_ref = newRV_noinc((SV*)req);')
      ->line('    sv_bless(req_ref, gv_stashpv("Hypersonic::Request", GV_ADD));')
      ->line('    ENTER;')
      ->line('    SAVETMPS;');
    
    # JIT: Add middleware short-circuit variable only if middleware present
    # (mw_result and short_circuit already declared at function top)
    
    # JIT: Builder-based before middleware (inline C - no Perl calls)
    if ($analysis->{has_builder_before}) {
        my $ctx = {
            req_var     => 'req',
            req_ref_var => 'req_ref',
            slots       => $analysis->{middleware_slots},
        };
        $builder->blank
          ->comment('JIT: Builder before middleware (inline C - zero Perl overhead)');
        for my $mw (@{$analysis->{builder_before}}) {
            if ($mw->can('build_before')) {
                $mw->build_before($builder, $ctx);
            }
        }
    }

    # JIT: Call global before middleware (Perl coderefs via call_sv)
    if ($analysis->{has_global_before}) {
        $builder->blank
          ->comment('JIT: Call global before middleware (Perl)')
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
    
    # JIT: Streaming handler support
    if ($analysis->{needs_streaming}) {
        $builder->blank
          ->comment('JIT: Check if this is a streaming handler')
          ->line('    is_streaming = g_streaming_handlers[handler_idx];')
          ->if('is_streaming')
            ->comment('Create Hypersonic::Stream object for streaming handler')
            ->line('dSP;')
            ->line('PUSHMARK(SP);')
            ->line('XPUSHs(sv_2mortal(newSVpv("Hypersonic::Stream", 0)));')
            ->line('XPUSHs(sv_2mortal(newSVpv("fd", 0)));')
            ->line('XPUSHs(sv_2mortal(newSViv(client_fd)));')
            ->line('PUTBACK;')
            ->line('int stream_count = call_method("new", G_SCALAR);')
            ->line('SPAGAIN;')
            ->if('stream_count > 0')
              ->line('stream_sv = POPs;')
              ->line('SvREFCNT_inc(stream_sv);')
            ->endif
            ->line('PUTBACK;')
          ->endif;
    }

    # Call the main handler (conditionally if middleware present)
    if ($analysis->{has_any_middleware}) {
        $builder->blank
          ->comment('Call main handler (unless middleware short-circuited)')
          ->line('    if (!short_circuit) {')
          ->line('        PUSHMARK(SP);')
          ->line('        XPUSHs(req_ref);');

        # For streaming handlers with middleware
        if ($analysis->{needs_streaming}) {
            $builder->line('        if (is_streaming && stream_sv) XPUSHs(stream_sv);');
        }

        $builder->line('        PUTBACK;')
          ->line('        count = call_sv(*handler_sv, G_SCALAR | G_EVAL);')
          ->line('        SPAGAIN;')
          ->line('        if (count == 1) result = POPs;')
          ->line('        PUTBACK;')
          ->line('    }');
    } else {
        $builder->line('    PUSHMARK(SP);')
          ->line('    XPUSHs(sv_2mortal(req_ref));');

        # For streaming handlers without middleware
        if ($analysis->{needs_streaming}) {
            $builder->line('    if (is_streaming && stream_sv) XPUSHs(stream_sv);');
        }

        $builder->line('    PUTBACK;')
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
    
    # JIT: Call global after middleware (Perl coderefs via call_sv)
    if ($analysis->{has_global_after}) {
        $builder->blank
          ->comment('JIT: Call global after middleware (Perl)')
          ->line('    if (g_after_middleware && SvROK(g_after_middleware)) {')
          ->line('        AV* after_arr = (AV*)SvRV(g_after_middleware);')
          ->line('        SV* after_result = call_middleware_chain(aTHX_ after_arr, req_ref);')
          ->line('        if (after_result) {')
          ->line('            result = after_result;')
          ->line('        }')
          ->line('    }');
    }

    # JIT: Builder-based after middleware (inline C - no Perl calls)
    if ($analysis->{has_builder_after}) {
        my $ctx = {
            req_var     => 'req',
            req_ref_var => 'req_ref',
            res_var     => 'result',
            slots       => $analysis->{middleware_slots},
        };
        $builder->blank
          ->comment('JIT: Builder after middleware (inline C - zero Perl overhead)');
        for my $mw (@{$analysis->{builder_after}}) {
            if ($mw->can('build_after')) {
                $mw->build_after($builder, $ctx);
            }
        }
    }

    # JIT: Streaming handlers - early return (response already sent via Stream)
    if ($analysis->{needs_streaming}) {
        $builder->blank
          ->comment('JIT: Streaming handlers return early - response sent via Stream object')
          ->if('is_streaming')
            ->line('if (stream_sv) SvREFCNT_dec(stream_sv);')
            ->line('FREETMPS;')
            ->line('LEAVE;')
            ->line('*resp_out = NULL;')
            ->line('*resp_len_out = -1;')
            ->comment('Signal streaming response - caller should not send')
            ->line('return;')
          ->endif;
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

# Generate WebSocket handler caller function
sub _gen_websocket_handler_caller {
    my ($self) = @_;

    my $builder = XS::JIT::Builder->new;

    $builder->comment('WebSocket handler caller - performs handshake and calls Perl handler')
      ->line('static void call_websocket_handler(pTHX_ int handler_idx, int fd,')
      ->line('                                    const char* path, int path_len,')
      ->line('                                    const char* ws_key, int ws_key_len,')
      ->line('                                    const char* raw_request, int raw_request_len) {')
      ->line('    dSP;')
      ->blank
      ->if('!g_websocket_handlers || !SvROK(g_websocket_handlers)')
        ->line('return;')
      ->endif
      ->blank
      ->line('AV* handlers = (AV*)SvRV(g_websocket_handlers);')
      ->line('SV** handler_sv = av_fetch(handlers, handler_idx, 0);')
      ->if('!handler_sv || !SvROK(*handler_sv)')
        ->line('return;')
      ->endif
      ->blank
      ->comment('Generate WebSocket accept key')
      ->line('ENTER;')
      ->line('SAVETMPS;')
      ->blank
      ->comment('Build handshake response via Protocol::WebSocket')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::Protocol::WebSocket")));')
      ->line('XPUSHs(sv_2mortal(newSVpvs("key")));')
      ->line('XPUSHs(sv_2mortal(newSVpvn(ws_key, ws_key_len)));')
      ->line('PUTBACK;')
      ->line('int count = call_method("build_response", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count != 1')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('return;')
      ->endif
      ->blank
      ->line('SV* response_sv = POPs;')
      ->line('STRLEN resp_len;')
      ->line('const char* response = SvPV(response_sv, resp_len);')
      ->blank
      ->comment('Send WebSocket handshake response')
      ->line('send(fd, response, resp_len, 0);')
      ->blank
      ->comment('Create Stream object for WebSocket')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::Stream")));')
      ->line('XPUSHs(sv_2mortal(newSVpvs("fd")));')
      ->line('XPUSHs(sv_2mortal(newSViv(fd)));')
      ->line('PUTBACK;')
      ->line('count = call_method("new", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count != 1')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('return;')
      ->endif
      ->blank
      ->line('SV* stream_sv = POPs;')
      ->line('SvREFCNT_inc(stream_sv);')
      ->blank
      ->comment('Create WebSocket object')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::WebSocket")));')
      ->line('XPUSHs(stream_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("fd")));')
      ->line('XPUSHs(sv_2mortal(newSViv(fd)));')
      ->line('PUTBACK;')
      ->line('count = call_method("new", G_SCALAR);')
      ->line('SPAGAIN;')
      ->blank
      ->if('count != 1')
        ->line('SvREFCNT_dec(stream_sv);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->line('return;')
      ->endif
      ->blank
      ->line('SV* ws_sv = POPs;')
      ->line('SvREFCNT_inc(ws_sv);')
      ->blank
      ->comment('Set WebSocket state to OPEN and store object in registry')
      ->if('fd >= 0 && fd < WS_MAX')
        ->line('ws_registry[fd].state = WS_STATE_OPEN;')
        ->line('ws_registry[fd].ws_object = ws_sv;')
        ->line('SvREFCNT_inc(ws_sv);')
      ->endif
      ->blank
      ->comment('Register with Handler for global broadcast support')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::WebSocket::Handler")));')
      ->line('XPUSHs(sv_2mortal(newSViv(fd)));')
      ->line('XPUSHs(ws_sv);')
      ->line('PUTBACK;')
      ->line('call_method("new", G_DISCARD);')
      ->blank
      ->comment('Call the Perl WebSocket handler with the WebSocket object')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(ws_sv);')
      ->line('PUTBACK;')
      ->line('call_sv(*handler_sv, G_DISCARD | G_EVAL);')
      ->blank
      ->if('SvTRUE(ERRSV)')
        ->line('warn("WebSocket handler error: %s", SvPV_nolen(ERRSV));')
      ->endif
      ->blank
      ->comment('Emit open event')
      ->line('PUSHMARK(SP);')
      ->line('XPUSHs(ws_sv);')
      ->line('XPUSHs(sv_2mortal(newSVpvs("open")));')
      ->line('PUTBACK;')
      ->line('call_method("emit", G_DISCARD | G_EVAL);')
      ->blank
      ->line('SvREFCNT_dec(stream_sv);')
      ->line('SvREFCNT_dec(ws_sv);')
      ->line('FREETMPS;')
      ->line('LEAVE;')
      ->line('}')
      ->blank;

    return $builder->code;
}

# Generate WebSocket data processor for established connections
sub _gen_websocket_data_processor {
    my ($self) = @_;

    my $builder = XS::JIT::Builder->new;

    $builder->comment('Process incoming WebSocket data on established connection')
      ->line('static void process_websocket_data(pTHX_ int fd, const char* data, ssize_t len) {')
      ->line('    dSP;')
      ->blank
      ->comment('Get WebSocket object from registry')
      ->if('fd < 0 || fd >= WS_MAX || !ws_registry[fd].ws_object')
        ->line('return;')
      ->endif
      ->blank
      ->line('SV* ws_sv = ws_registry[fd].ws_object;')
      ->blank
      ->comment('Parse WebSocket frame')
      ->line('WSFrame frame;')
      ->line('int result = ws_decode_frame((const uint8_t*)data, len, &frame);')
      ->blank
      ->if('result < 0')
        ->comment('Incomplete frame or error - wait for more data')
        ->line('return;')
      ->endif
      ->blank
      ->comment('Handle different opcodes')
      ->if('frame.opcode == WS_OP_TEXT || frame.opcode == WS_OP_BINARY')
        ->comment('Data frame - emit message event')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(ws_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvs("message")));')
        ->line('XPUSHs(sv_2mortal(newSVpvn((const char*)frame.payload, frame.payload_length)));')
        ->line('PUTBACK;')
        ->line('call_method("emit", G_DISCARD | G_EVAL);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
      ->elsif('frame.opcode == WS_OP_CLOSE')
        ->comment('Close frame - emit close event and respond')
        ->line('int close_code = 1000;')
        ->if('frame.payload_length >= 2')
          ->line('close_code = (frame.payload[0] << 8) | frame.payload[1];')
        ->endif
        ->blank
        ->comment('Send close response')
        ->line('uint8_t close_frame[4];')
        ->line('close_frame[0] = 0x88;')  # FIN + Close opcode
        ->line('close_frame[1] = 2;')     # Length 2 (just the code)
        ->line('close_frame[2] = (close_code >> 8) & 0xFF;')
        ->line('close_frame[3] = close_code & 0xFF;')
        ->line('send(fd, close_frame, 4, 0);')
        ->blank
        ->comment('Emit close event')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(ws_sv);')
        ->line('XPUSHs(sv_2mortal(newSVpvs("close")));')
        ->line('XPUSHs(sv_2mortal(newSViv(close_code)));')
        ->line('PUTBACK;')
        ->line('call_method("emit", G_DISCARD | G_EVAL);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->blank
        ->comment('Unregister from Handler')
        ->line('ENTER;')
        ->line('SAVETMPS;')
        ->line('PUSHMARK(SP);')
        ->line('XPUSHs(sv_2mortal(newSVpvs("Hypersonic::WebSocket::Handler")));')
        ->line('XPUSHs(sv_2mortal(newSViv(fd)));')
        ->line('PUTBACK;')
        ->line('call_method("close", G_DISCARD);')
        ->line('FREETMPS;')
        ->line('LEAVE;')
        ->blank
        ->comment('Mark connection as closed')
        ->line('ws_registry[fd].state = WS_STATE_CLOSED;')
      ->elsif('frame.opcode == WS_OP_PING')
        ->comment('Ping - auto pong')
        ->line('uint8_t pong_frame[256];')
        ->line('size_t pong_len = ws_encode_pong(pong_frame, sizeof(pong_frame), frame.payload, frame.payload_length);')
        ->if('pong_len > 0')
          ->line('send(fd, pong_frame, pong_len, 0);')
        ->endif
      ->endif
      ->line('}')
      ->blank;

    return $builder->code;
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
        require B::Deparse unless $DEPARSER;
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

    my $host    = $opts{host}    // $self->{host};
    my $port    = $opts{port}    // $self->{port};
    my $workers = $opts{workers} // 1;
    
    # Protocol mode indication
    my $mode = $self->{http2} ? "HTTP/2" : ($self->{tls} ? "HTTPS/TLS" : "HTTP");
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

=item websocket_rooms

Enable WebSocket Room support for broadcast groups. Default: C<0>

Only set to C<1> if you need L<Hypersonic::WebSocket::Room> for broadcasting
to groups of connections. This adds Room-specific XS code to your compiled server.

=item max_rooms

Maximum number of rooms when C<websocket_rooms> is enabled. Default: C<1000>

=item max_clients_per_room

Maximum clients per room when C<websocket_rooms> is enabled. Default: C<10000>

=item c_helpers

C helper functions to inject early in the generated code, making them available
to all routes. Can be a coderef that receives an L<XS::JIT::Builder>, or a raw
C string.

    # Using a coderef
    c_helpers => sub {
        my ($builder) = @_;
        $builder->line('static int double_value(int x) { return x * 2; }');
    }

    # Or raw C string
    c_helpers => 'static int double_value(int x) { return x * 2; }'

These helpers are available to C<need_xs_builder> routes.

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

=head2 websocket

    $server->websocket('/ws' => sub {
        my ($ws) = @_;

        $ws->on(open => sub {
            $ws->send('Welcome!');
        });

        $ws->on(message => sub {
            my ($data) = @_;
            $ws->send("Echo: $data");
        });

        $ws->on(close => sub {
            my ($code, $reason) = @_;
            # Connection closed
        });
    });

Register a WebSocket route handler. The handler receives a
L<Hypersonic::WebSocket> object when a client upgrades to WebSocket.

B<WebSocket Object Methods:>

=over 4

=item $ws->on($event, $handler)

Register event handlers. Events: C<open>, C<message>, C<binary>, C<ping>,
C<pong>, C<close>, C<error>.

=item $ws->send($data)

Send a text message to the client.

=item $ws->send_binary($data)

Send binary data to the client.

=item $ws->ping($data)

Send a ping frame (optional payload).

=item $ws->close($code, $reason)

Initiate close handshake. Default code: 1000.

=item $ws->is_open, $ws->is_closing, $ws->is_closed

Check connection state.

=item $ws->param($name), $ws->header($name)

Access request parameters and headers from the upgrade request.

=back

B<Example - Chat Server:>

    $server->websocket('/chat' => sub {
        my ($ws) = @_;

        $ws->on(open => sub {
            # New user connected
        });

        $ws->on(message => sub {
            my ($msg) = @_;
            # Broadcast to other clients...
        });
    });

=head2 WebSocket Handler Registry

L<Hypersonic::WebSocket::Handler> provides a global connection registry for 
managing all active WebSocket connections. Connections are automatically 
registered when created and unregistered when closed.

B<Class Methods:>

=over 4

=item Hypersonic::WebSocket::Handler->count

Returns total number of active WebSocket connections.

=item Hypersonic::WebSocket::Handler->get($fd)

Get the WebSocket object for a file descriptor.

=item Hypersonic::WebSocket::Handler->is_websocket($fd)

Check if a file descriptor is a registered WebSocket.

=item Hypersonic::WebSocket::Handler->broadcast($message, [$exclude])

Send text message to ALL connected WebSocket clients. Optional second
argument is a WebSocket to exclude (typically the sender).

=back

B<Example - Global Broadcast:>

    use Hypersonic::WebSocket::Handler;
    
    $server->websocket('/ws' => sub {
        my ($ws) = @_;
        
        $ws->on(open => sub {
            my $count = Hypersonic::WebSocket::Handler->count;
            $ws->send("You are connection #$count");
            Hypersonic::WebSocket::Handler->broadcast("A user joined!", $ws);
        });
        
        $ws->on(message => sub {
            my ($msg) = @_;
            # Broadcast to ALL WebSocket clients except sender
            Hypersonic::WebSocket::Handler->broadcast("User: $msg", $ws);
        });
        
        $ws->on(close => sub {
            Hypersonic::WebSocket::Handler->broadcast("A user left");
        });
    });

=head2 WebSocket with Rooms

L<Hypersonic::WebSocket::Room> provides broadcast groups for sending messages
to subsets of connections. You must enable rooms explicitly:

    my $server = Hypersonic->new(
        websocket_rooms      => 1,      # Enable Room support
        max_rooms            => 100,    # Max rooms (default: 1000)
        max_clients_per_room => 1000,   # Max clients per room (default: 10000)
    );

B<Example - Multi-Room Chat:>

    use Hypersonic::WebSocket::Room;
    
    $server->websocket('/chat/:room' => sub {
        my ($ws) = @_;
        my $room_name = $ws->param('room');
        
        # Create or get existing room
        my $room = Hypersonic::WebSocket::Room->new($room_name);
        
        $ws->on(open => sub {
            $room->join($ws);
            $room->broadcast("Someone joined $room_name", $ws);  # Exclude sender
            $ws->send("Welcome to $room_name! (" . $room->count . " users)");
        });
        
        $ws->on(message => sub {
            my ($msg) = @_;
            # Broadcast to everyone in this room except sender
            $room->broadcast($msg, $ws);
        });
        
        $ws->on(close => sub {
            $room->leave($ws);
            $room->broadcast("Someone left $room_name");
        });
    });

B<Room Methods:>

=over 4

=item Hypersonic::WebSocket::Room->new($name)

Create or get a room by name.

=item $room->name

Get room name.

=item $room->join($ws)

Add a WebSocket connection to the room.

=item $room->leave($ws)

Remove a WebSocket connection from the room.

=item $room->has($ws)

Check if a connection is in the room.

=item $room->count

Get number of connections in the room.

=item $room->count_open

Get number of OPEN (not closing/closed) connections in the room.

=item $room->broadcast($message, $exclude)

Send text message to all room members. Optional C<$exclude> WebSocket
connection to skip (typically the sender).

=item $room->broadcast_binary($data, $exclude)

Send binary data to all room members.

=item $room->close_all($code, $reason)

Close all connections in the room with given code and reason.

=item $room->clear

Remove all connections from the room (without closing them).

=item $room->clients

Get list of all WebSocket connections in the room.

=back

B<Global Broadcast Pattern:>

To broadcast to ALL connected WebSocket clients, use a global room:

    my $global = Hypersonic::WebSocket::Room->new('__global__');
    
    $server->websocket('/ws' => sub {
        my ($ws) = @_;
        
        $ws->on(open => sub {
            $global->join($ws);
            $global->broadcast("A user joined! (" . $global->count . " online)");
        });
        
        $ws->on(message => sub {
            my ($msg) = @_;
            $global->broadcast($msg, $ws);  # Send to all except sender
        });
        
        $ws->on(close => sub {
            $global->leave($ws);
            $global->broadcast("A user left");
        });
    });

=head2 streaming

    $server->get('/events' => sub {
        my ($stream) = @_;

        # Send SSE events
        my $sse = $stream->sse;
        $sse->event(type => 'update', data => 'Hello');
        $sse->keepalive;
        $sse->close;
    }, { streaming => 1 });

Enable streaming responses for a route. The handler receives a
L<Hypersonic::Stream> object instead of returning a static response.

B<Stream Object Methods:>

=over 4

=item $stream->write($data)

Write data to the response (chunked encoding).

=item $stream->end($data)

Write final data and close the stream.

=item $stream->sse

Get an L<Hypersonic::SSE> object for Server-Sent Events.

=back

B<SSE Object Methods:>

=over 4

=item $sse->event(type => $type, data => $data, id => $id)

Send an SSE event with optional type and id.

=item $sse->data($data)

Send a data-only event (no type field).

=item $sse->retry($ms)

Set client reconnection interval in milliseconds.

=item $sse->keepalive

Send a keepalive comment to prevent timeout.

=item $sse->comment($text)

Send an SSE comment.

=item $sse->close

Close the SSE stream.

=back

B<Example - Server-Sent Events:>

    $server->get('/notifications' => sub {
        my ($stream) = @_;
        my $sse = $stream->sse;

        $sse->retry(3000);  # Reconnect after 3s
        $sse->event(
            type => 'notification',
            data => '{"message":"New update!"}',
            id   => '12345',
        );

        # Keep connection alive...
        $sse->keepalive;
    }, { streaming => 1 });

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
        need_xs_builder => 1,         # Generate C code at compile time
    });

=head2 need_xs_builder Routes

When C<need_xs_builder =E<gt> 1>, the route handler is called at compile time
with a fresh L<XS::JIT::Builder> object instead of a request object. The handler
must generate C code and return a hashref with the XS function name:

    $server->get('/xs/counter' => sub {
        my ($builder) = @_;
        
        # Generate C code for this route
        $builder->line('static int counter = 0;')
          ->line('static void handle_counter(pTHX_ int fd,')
          ->line('    const char* method, int method_len,')
          ->line('    const char* path, int path_len,')
          ->line('    const char* body, int body_len,')
          ->line('    char** resp_out, int* resp_len_out) {')
          ->line('    counter++;')
          ->line('    static char response[256];')
          ->line('    int n = snprintf(response, sizeof(response),')
          ->line('        "HTTP/1.1 200 OK\\r\\nContent-Type: application/json\\r\\n"')
          ->line('        "Content-Length: 14\\r\\n\\r\\n{\\"count\\":%d}", counter);')
          ->line('    *resp_out = response;')
          ->line('    *resp_len_out = n;')
          ->line('}');
        
        return { xs_function => 'handle_counter' };
    }, { need_xs_builder => 1 });

The XS function signature must match:

    void func_name(pTHX_ int fd,
                   const char* method, int method_len,
                   const char* path, int path_len,
                   const char* body, int body_len,
                   char** resp_out, int* resp_len_out);

The function should write a complete HTTP response to C<*resp_out> and set
C<*resp_len_out> to the response length.

Use with C<c_helpers> to share utility functions:

    my $server = Hypersonic->new(
        c_helpers => sub {
            my ($builder) = @_;
            $builder->line('static int double_it(int x) { return x * 2; }');
        },
    );

    $server->get('/double/:n' => sub {
        my ($builder) = @_;
        # Can use double_it() from c_helpers!
        # ...
    }, { need_xs_builder => 1 });

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

=head2 async_pool

    $server->async_pool(
        workers    => 8,       # Thread pool size (default: 8)
        queue_size => 4096,    # Max queued operations (default: 4096)
    );

Enable the JIT-compiled async thread pool for non-blocking operations.
When enabled, the event loop integrates with L<Hypersonic::Future::Pool>
to process completed async operations.

B<Example - Async route with Future:>

    use Hypersonic;
    use Hypersonic::Future;
    use Hypersonic::Future::Pool;
    use Hypersonic::Response 'res';

    my $server = Hypersonic->new;

    # Enable async pool
    $server->async_pool(workers => 4);

    # Dynamic route that uses Future for async work
    $server->get('/compute/:n' => sub {
        my ($req) = @_;
        my $n = $req->param('n');

        # Create a future and submit work to thread pool
        my $f = Hypersonic::Future->new;

        Hypersonic::Future::Pool->submit($f, sub {
            # This runs in thread pool
            my $result = 0;
            $result += $_ for 1..$n;
            return $result;
        }, []);

        # Return future - response sent when resolved
        return $f->then(sub {
            my ($result) = @_;
            return res->json({ sum => $result });
        });
    });

    $server->compile;
    $server->run(port => 8080);

B<Future API:>

    # Create futures
    my $f = Hypersonic::Future->new;
    my $f2 = Hypersonic::Future->new_done(@values);
    my $f3 = Hypersonic::Future->new_fail($error, $category);

    # Resolve/reject
    $f->done(@values);
    $f->fail($message, $category);

    # State checks
    $f->is_ready;     # True if done, failed, or cancelled
    $f->is_done;      # True if resolved with values
    $f->is_failed;    # True if rejected
    $f->is_cancelled; # True if cancelled

    # Get results
    my @values = $f->result;     # Returns result values
    my ($msg, $cat) = $f->failure;  # Returns error info

    # Chaining
    $f->then(sub { ... })
      ->catch(sub { ... })
      ->finally(sub { ... });

    # Callbacks
    $f->on_done(sub { my @vals = @_; ... });
    $f->on_fail(sub { my ($msg, $cat) = @_; ... });
    $f->on_ready(sub { ... });  # Called for any completion

    # Convergent futures
    Hypersonic::Future->needs_all($f1, $f2, $f3);  # All must succeed
    Hypersonic::Future->needs_any($f1, $f2);       # First success wins
    Hypersonic::Future->wait_all($f1, $f2, $f3);   # Wait for all (success or fail)
    Hypersonic::Future->wait_any($f1, $f2);        # Wait for first completion

See L<Hypersonic::Future> and L<Hypersonic::Future::Pool> for full documentation.

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

=head2 JIT Feature Detection

Hypersonic uses a "JIT philosophy" - only code that's actually needed gets
compiled. The C<compile()> method analyzes your routes and sets these flags:

=over 4

=item needs_streaming

Set when any route has C<streaming =E<gt> 1>. Compiles L<Hypersonic::Stream>
and L<Hypersonic::SSE> XS code.

=item needs_websocket

Set when any C<websocket()> routes are registered. Compiles
L<Hypersonic::WebSocket> and L<Hypersonic::Protocol::WebSocket::Frame> XS code.

=item needs_websocket_handler

Automatically set when C<needs_websocket> is true. Compiles
L<Hypersonic::WebSocket::Handler> for connection registry.

=item needs_websocket_rooms

Set when C<websocket_rooms =E<gt> 1> is passed to C<new()>, or when any
WebSocket route has C<rooms =E<gt> 1> in its options. Compiles
L<Hypersonic::WebSocket::Room> for broadcast groups.

=item has_any_middleware

Set when global C<before()> or C<after()> middleware is registered.

=item has_route_middleware

Set when any route has per-route C<before> or C<after> options.

=item needs_async_pool

Set when C<async_pool()> is called. Compiles L<Hypersonic::Future> and
L<Hypersonic::Future::Pool> for async thread pool operations.

=back

You can inspect these flags after compile:

    $server->compile();
    my $analysis = $server->{route_analysis};
    
    say "Has streaming: ", $analysis->{needs_streaming} ? "yes" : "no";
    say "Has WebSocket: ", $analysis->{needs_websocket} ? "yes" : "no";
    say "Has Rooms: ", $analysis->{needs_websocket_rooms} ? "yes" : "no";

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

=head2 HTTP Server Performance (wrk, 2 threads, 100 connections, 10s)

Native execution on Apple M1, single worker, plaintext "Hello, World!" response:

    Framework       Language        Req/sec     Latency     Relative
    ----------------------------------------------------------------
    Hypersonic      Perl (JIT→C)    266,076     0.34ms      1.87x
    Actix-web       Rust            238,454     0.40ms      1.68x
    Gin             Go              141,943     1.02ms      1.00x
    FastAPI         Python/uvicorn   11,677     8.56ms      0.08x

=head2 Perl Route Matching Benchmark

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

L<Hypersonic::Stream> - Streaming response object

L<Hypersonic::SSE> - Server-Sent Events API

L<Hypersonic::WebSocket> - WebSocket connection API

L<Hypersonic::WebSocket::Handler> - WebSocket global registry and broadcast

L<Hypersonic::WebSocket::Room> - WebSocket broadcast groups

L<Hypersonic::Future> - High-performance async Future

L<Hypersonic::Future::Pool> - Thread pool for async operations

L<Hypersonic::Socket> - Low-level socket operations

L<Hypersonic::TLS> - TLS/HTTPS support

L<XS::JIT> - The JIT compiler used by Hypersonic

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
