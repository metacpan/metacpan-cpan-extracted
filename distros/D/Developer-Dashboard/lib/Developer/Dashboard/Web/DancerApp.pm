package Developer::Dashboard::Web::DancerApp;

use strict;
use warnings;

our $VERSION = '5.73';

use Dancer2 appname => 'DeveloperDashboard';
use Dancer2::Core::Hook ();
use Cwd qw(abs_path);
use File::Spec;
use Scalar::Util qw(refaddr);

our $BACKEND_APP;

# build_psgi_app(%args)
# Builds the Dancer2 PSGI application around the dashboard service routes.
# Input: backend web app object, optional default header hash, and path registry.
# Output: PSGI application code reference.
sub build_psgi_app {
    my ( $class, %args ) = @_;
    my $app = $args{app} || die 'Missing backend web app';
    my $default_headers = $args{default_headers} || {};
    $BACKEND_APP = {
        app             => $app,
        default_headers => { %{$default_headers} },
    };
    _load_skill_dashboard_modules( $args{paths} );
    return __PACKAGE__->to_app;
}

# _load_skill_dashboard_modules($paths)
# Loads each active skill's lib/Dashboard.pm into the shared Dancer2 app before
# the PSGI application is built, allowing skills to register routes/settings.
# Input: optional path registry implementing nested_skill_entries().
# Output: array reference of successfully loaded absolute module paths.
sub _load_skill_dashboard_modules {
    my ($paths) = @_;
    return [] if !ref($paths) || !$paths->can('nested_skill_entries');

    my ($dancer_app) = grep { $_->name eq 'DeveloperDashboard' } @{ Dancer2->runner->apps };
    die "Unable to find the DeveloperDashboard Dancer2 application for skill routes\n" if !$dancer_app;
    my %routes_before = map { $_ => [ @{ $dancer_app->routes->{$_} || [] } ] } keys %{ $dancer_app->routes };

    my @loaded;
    for my $entry ( $paths->nested_skill_entries ) {
        next if ref($entry) ne 'HASH' || !defined $entry->{dir} || $entry->{dir} eq '';
        my $lib = File::Spec->catdir( $entry->{dir}, 'lib' );
        my $module = File::Spec->catfile( $lib, 'Dashboard.pm' );
        next if !-f $module;

        my $real_lib = abs_path($lib);
        my $real_module = abs_path($module);
        die "Unable to resolve skill Dashboard module '$module'\n"
          if !defined $real_lib || !defined $real_module;
        my $relative_module = File::Spec->abs2rel( $real_module, $real_lib );
        die "Skill Dashboard module '$module' resolves outside its skill lib directory\n"
          if File::Spec->file_name_is_absolute($relative_module)
          || $relative_module eq '..'
          || $relative_module =~ m{\A\.\.(?:[\\/]|\z)};

        my $loaded = eval {
            local @INC = ( $real_lib, @INC );
            require $real_module;
            1;
        };
        die "Unable to load skill Dashboard module '$real_module': $@" if !$loaded;
        push @loaded, $real_module;
    }

    my @skill_routes;
    for my $method ( keys %{ $dancer_app->routes } ) {
        my %builtin = map { refaddr($_) => 1 } @{ $routes_before{$method} || [] };
        my @added = grep { !$builtin{ refaddr($_) } } @{ $dancer_app->routes->{$method} || [] };
        next if !@added;
        push @skill_routes, @added;

        my @original = @{ $routes_before{$method} || [] };
        my $fallback = ( $method eq 'get' || $method eq 'post' ) ? pop @original : undef;
        $dancer_app->routes->{$method} = [ @original, @added, ( defined $fallback ? ($fallback) : () ) ];
    }

    if (@skill_routes) {
        $dancer_app->add_hook(
            Dancer2::Core::Hook->new(
                name => 'core.app.before_request',
                code => sub { _authorize_skill_dashboard_routes( \@skill_routes, @_ ) },
            )
        );
    }

    return \@loaded;
}

# _authorize_skill_dashboard_routes($routes, $dancer_app)
# Applies the dashboard's standard request authorization before a loaded skill
# route can execute; non-skill requests pass through unchanged.
# Input: array reference of skill route objects and active Dancer2 app context.
# Output: undef when the request is unrelated or authorized; halts the app with
# the authorization response when access is refused.
sub _authorize_skill_dashboard_routes {
    my ( $routes, $dancer_context ) = @_;
    die 'Missing skill route list' if ref($routes) ne 'ARRAY';
    die 'Missing Dancer2 request context' if !ref($dancer_context) || !$dancer_context->can('request');

    my $request = $dancer_context->request;
    my $method = lc( $request->method // '' );
    return if !grep {
        $_->method eq $method && $_->match($request)
    } @{$routes};

    my $backend = _current_backend();
    my $web_app = $backend->{app};
    die 'Backend app does not implement authorize_request for skill routes'
      if !$web_app->can('authorize_request');
    my $refusal = $web_app->authorize_request( %{ _request_args() } );
    return if !defined $refusal;

    my ( $status_code, $content_type, $body, $headers ) = @{$refusal};
    my $response = $dancer_context->response;
    $response->status($status_code);
    $response->content_type($content_type);
    $response->content( defined $body ? $body : '' );
    if ( ref($headers) eq 'HASH' ) {
        $response->push_header( $_ => $headers->{$_} ) for sort keys %{$headers};
    }
    $dancer_context->halt;
    return;
}

# _current_backend()
# Returns the configured backend service object and default headers.
# Input: none.
# Output: hash reference with app object and default headers.
sub _current_backend {
    return $BACKEND_APP || die 'Missing backend web app';
}

# _request_headers()
# Normalizes the subset of inbound headers the backend service expects. The
# Origin and Referer headers ride along so the backend's cross-site
# request forgery check can compare the browser context against the request
# host for every state-changing route, and Sec-Fetch-Site rides along with
# them because it is the only one of the three a GET can rely on — the browser
# sets it itself, and page script can neither forge nor suppress it.
# Input: none.
# Output: hash reference with host, cookie, api-key, origin, referer, and
# fetch-site values.
sub _request_headers {
    return {
        host              => scalar( request->header('Host') // '' ),
        cookie            => scalar( request->header('Cookie') // '' ),
        origin            => scalar( request->header('Origin') // '' ),
        referer           => scalar( request->header('Referer') // '' ),
        'sec-fetch-site'  => scalar( request->header('Sec-Fetch-Site') // '' ),
        'x-dd-api-key'    => scalar( request->header('X-DD-API-Key') // '' ),
        'x-dd-api-secret' => scalar( request->header('X-DD-API-Secret') // '' ),
    };
}

# _request_args()
# Normalizes the active Dancer2 request into the backend service request shape.
# Input: none.
# Output: hash reference with path, query, method, body, headers, and remote address.
sub _request_args {
    my $host = scalar( request->header('Host') // '' );
    if ( $host eq '' ) {
        my $server_name = scalar( request->env->{SERVER_NAME} // '' );
        my $server_port = scalar( request->env->{SERVER_PORT} // '' );
        $host = $server_name;
        $host .= ':' . $server_port if $host ne '' && $server_port ne '';
    }
    my $remote_addr = scalar( request->env->{REMOTE_ADDR} // request->env->{SERVER_ADDR} // '' );
    $remote_addr = scalar( request->env->{SERVER_NAME} // '' ) if $remote_addr eq '';
    return {
        path        => scalar( request->env->{PATH_INFO} // '/' ),
        query       => scalar( request->env->{QUERY_STRING} // '' ),
        method      => scalar( request->env->{REQUEST_METHOD} // 'GET' ),
        body        => scalar( request->body // '' ),
        remote_addr => $remote_addr,
        headers     => {
            %{ _request_headers() },
            host => $host,
        },
    };
}

# _capture($index)
# Returns one regex-route capture from the current Dancer2 request.
# Input: zero-based capture index.
# Output: captured path string or undef.
sub _capture {
    my ($index) = @_;
    my @parts = splat;
    @parts = @{ $parts[0] } if @parts == 1 && ref( $parts[0] ) eq 'ARRAY';
    return undef if !@parts;
    return $parts[$index];
}

# _response_header_overrides($default_headers)
# Reads response headers already set in the active Dancer2 request that match
# configured defaults, preserving settings from skill before hooks.
# Input: hash reference of default response headers.
# Output: hash reference of existing headers whose names occur in defaults.
sub _response_header_overrides {
    my ($default_headers) = @_;
    return {} if ref($default_headers) ne 'HASH' || !keys %{$default_headers};

    my $headers = response->headers;
    my %overrides;
    for my $name ( keys %{$default_headers} ) {
        my $value = $headers->header($name);
        $overrides{$name} = $value if defined $value;
    }
    return \%overrides;
}

# _response_from_result($result)
# Applies one backend response onto the active Dancer2 response object.
# Input: backend response array reference.
# Output: plain body or delayed streaming response suitable for Dancer2;
# existing before-hook headers override defaults and backend response headers
# override both.
sub _response_from_result {
    my ($result) = @_;
    my ( $code, $type, $body, $headers ) = @{$result};
    my $backend = _current_backend();
    my $default_headers = $backend->{default_headers} || {};
    my $hook_headers = _response_header_overrides($default_headers);
    my %merged_headers = (
        %{$default_headers},
        %{$hook_headers},
        %{ $headers || {} },
    );

    if ( ref($body) eq 'HASH' && ref( $body->{stream} ) eq 'CODE' ) {
        my $stream = $body->{stream};
        return delayed {
            my @headers = ( 'Content-Type' => $type );
            push @headers, map { $_ => $merged_headers{$_} } sort keys %merged_headers;
            my $responder = $Dancer2::Core::Route::RESPONDER
              or die "Missing delayed response writer\n";
            my $psgi_writer = $responder->([ $code, \@headers ]);
            my $writer = sub {
                my ($chunk) = @_;
                return 1 if !defined $chunk || $chunk eq '';
                my $ok = eval {
                    $psgi_writer->write($chunk);
                    1;
                };
                return 0 if !$ok && _looks_like_disconnect_error($@);
                die $@ if !$ok;
                return 1;
            };

            eval {
                $stream->($writer);
                1;
            } or do {
                my $error = $@ || "Streaming response failed\n";
                $writer->($error);
            };

            eval { $psgi_writer->close };
        };
    }

    status $code;
    content_type $type;
    for my $name ( sort keys %merged_headers ) {
        response_header $name => $merged_headers{$name};
    }

    return $body;
}

# _looks_like_disconnect_error($error)
# Detects writer/content failures that mean the HTTP client has already closed the stream.
# Input: raw exception text from Dancer content writes.
# Output: boolean true when the error matches a broken client connection.
sub _looks_like_disconnect_error {
    my ($error) = @_;
    return 0 if !defined $error || $error eq '';
    return $error =~ /(broken pipe|client disconnected|connection reset|stream closed|connection aborted|write failed)/i ? 1 : 0;
}

# _run_backend($method, %extra)
# Runs one backend service method and converts failures into 500 responses.
# Input: backend method name plus extra normalized request arguments.
# Output: Dancer2 route return value.
sub _run_backend {
    my ( $method, %extra ) = @_;
    my $backend = _current_backend();
    my %args = ( %{ _request_args() }, %extra );
    my $result = eval {
        return $backend->{app}->$method(%args) if $backend->{app}->can($method);
        return $backend->{app}->handle(%args) if $backend->{app}->can('handle');
        die "Backend app does not implement $method or handle";
    };
    if ($@) {
        $result = [ 500, 'text/plain; charset=utf-8', "$@", {} ];
    }
    return _response_from_result($result);
}

# _run_authorized($method, %extra)
# Runs one backend route after enforcing dashboard session authorization.
# Input: backend method name plus extra normalized request arguments.
# Output: Dancer2 route return value.
sub _run_authorized {
    my ( $method, %extra ) = @_;
    my $backend = _current_backend();
    my %args = ( %{ _request_args() }, %extra );
    my $result = eval {
        if ( $backend->{app}->can($method) ) {
            my $auth_response = $backend->{app}->can('authorize_request')
              ? $backend->{app}->authorize_request(%args)
              : undef;
            return $auth_response if $auth_response;
            return $backend->{app}->$method(%args);
        }
        return $backend->{app}->handle(%args) if $backend->{app}->can('handle');
        die "Backend app does not implement $method or handle";
    };
    if ($@) {
        $result = [ 500, 'text/plain; charset=utf-8', "$@", {} ];
    }
    return _response_from_result($result);
}

post '/login' => sub {
    return _run_backend('login_response');
};

any [qw(get post)] => '/' => sub {
    return _run_authorized('root_response');
};

get '/logout' => sub {
    return _run_backend('logout_response');
};

get '/apps' => sub {
    return _run_authorized('apps_redirect_response');
};

# Browsers request the tab icon on their own for every page load, including on
# the login page, so this route stays outside the authorization gate.
get '/favicon.ico' => sub {
    return _run_backend('favicon_response');
};

any [qw(get post)] => '/ajax' => sub {
    return _run_authorized('legacy_ajax_response');
};

any [qw(get post)] => '/ajax/singleton/stop' => sub {
    return _run_authorized('ajax_singleton_stop_response');
};

any [qw(get post)] => qr{^/ajax/(.+)$} => sub {
    return _run_authorized('dispatch_request');
};

get '/system/status' => sub {
    return _run_authorized('status_response');
};

get '/marked.min.js' => sub {
    return _run_authorized('marked_js_response');
};

get '/tiff.min.js' => sub {
    return _run_authorized('tiff_js_response');
};

get '/loading.webp' => sub {
    return _run_authorized('loading_image_response');
};

get qr{^/(js|css|others)/(.+)$} => sub {
    return _run_authorized('dispatch_request');
};

get qr{^/app/(.+)/source$} => sub {
    return _run_authorized('dispatch_request');
};

post qr{^/app/(.+)/edit$} => sub {
    return _run_authorized('dispatch_request');
};

get qr{^/app/(.+)/edit$} => sub {
    return _run_authorized('dispatch_request');
};

post qr{^/app/(.+)/action/([^/]+)$} => sub {
    return _run_authorized('dispatch_request');
};

get qr{^/app/(.+)$} => sub {
    return _run_authorized('dispatch_request');
};

post '/action' => sub {
    return _run_authorized('transient_action_response');
};
any [qw(get post)] => qr{.*} => sub {
    return _run_authorized('dispatch_request');
};

1;

__END__

=encoding UTF-8

=head1 NAME

Developer::Dashboard::Web::DancerApp - Dancer2 route layer for Developer Dashboard

=head1 SYNOPSIS

  my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
      app             => $web_app,
      default_headers => \%headers,
      paths           => $paths,
  );

=head1 DESCRIPTION

This module owns the HTTP route table for the dashboard web UI under Dancer2.
It loads active skill Dancer2 extensions before constructing the shared app,
normalizes each request, enforces authorization for dashboard and skill routes, and
delegates the page and action work to C<Developer::Dashboard::Web::App>. The
skill C<lib/Dashboard.pm> modules load while the PSGI app is constructed at
server startup, not once per request; their registered hooks still execute for
each matching request. A C<hook before =E<gt> sub { ... }> may set Dancer2 app
variables or response headers. The page CODE runtime can read a hook variable
when it imports C<Dancer2 appname =E<gt> 'DeveloperDashboard'>. When a hook
sets a header also present in the dashboard defaults, that existing hook value
wins; an explicit header returned by the backend wins over both.

For example, a skill extension can set a request-scoped value and a response
policy:

  use Dancer2 appname => 'DeveloperDashboard';
  hook before => sub {
      var foo => 'bar';
      response_header 'Content-Security-Policy'
          => "script-src 'self' 'unsafe-inline' 'unsafe-eval'";
  };

Skill bookmark CODE that needs the variable imports that same app:

  use Dancer2 appname => 'DeveloperDashboard';
  print var('foo');

The route adapter intentionally hands the namespaced C</app>, C</ajax>, C</js>,
C</css>, and C</others> surfaces back to the backend dispatcher so the
installed PSGI server stays in lock-step with the backend smart router. The
C</favicon.ico> route is deliberately registered without the authorization
wrapper, because browsers request the tab icon implicitly on every page load,
including on the login page itself. The header normalizer forwards the
C<Origin>, C<Referer>, and C<Sec-Fetch-Site> headers on every request so the
backend's cross-site request forgery check can refuse requests that arrive
from a foreign browser context — including the unauthorized C</login> POST
route, whose backend handler applies the same check itself. C<Sec-Fetch-Site>
has to ride along too because it is the only one of the three that defends a
C<GET>: the browser sets it, and page script can neither forge nor suppress
it, which is what stops a foreign page from executing a saved C</ajax> handler
on the cookie-less loopback-admin tier.

=head1 METHODS

=head2 build_psgi_app, _load_skill_dashboard_modules, _authorize_skill_dashboard_routes, _current_backend, _request_headers, _request_args, _response_header_overrides, _response_from_result, _run_backend, _run_authorized

Build and serve the Dancer2 application around the dashboard route handlers.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module adapts the dashboard route backend to PSGI/Dancer-style request handling. It turns the backend app object into a PSGI coderef, translates request and response state, and preserves the dashboard default headers while keeping the route logic out of the transport adapter.

=head1 WHY IT EXISTS

It exists because the transport adapter should be small and separate from the actual route behavior. The dashboard needs a bridge from PSGI requests to the backend app object without forcing the backend to know about Dancer internals.

=head1 WHEN TO USE

Use this file when changing PSGI wrapping, response translation, or the way the backend app is exposed to Plack and Starman.

=head1 HOW TO USE

Call C<build_psgi_app> with the backend app object, default headers, and path registry, then pass the returned coderef to a PSGI server. Active installed skills are scanned recursively; each C<lib/Dashboard.pm> is loaded with its own C<lib/> first in C<@INC> so it can add routes or settings using C<use Dancer2 appname =E<gt> 'DeveloperDashboard'>. Skill routes are inserted before the final catch-all and are checked through the dashboard authorization handler. These are trusted local Perl extensions; load failures stop startup with an explicit error. Route behavior and core auth logic should stay in C<Developer::Dashboard::Web::App>, including the smart namespaced route resolution for installed skill-local pages, Ajax handlers, and public assets.

=head1 WHAT USES IT

It is used by C<app.psgi>, by C<Developer::Dashboard::Web::Server>, and by tests that verify the PSGI adapter keeps dashboard headers and route responses intact.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Web::DancerApp -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/03-web-app.t t/08-web-update-coverage.t t/web_app_static_files.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
