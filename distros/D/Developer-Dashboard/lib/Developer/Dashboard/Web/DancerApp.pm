package Developer::Dashboard::Web::DancerApp;

use strict;
use warnings;

our $VERSION = '3.09';

use Dancer2 appname => 'DeveloperDashboard';

our $BACKEND_APP;

# build_psgi_app(%args)
# Builds the Dancer2 PSGI application around the dashboard service routes.
# Input: backend web app object plus optional default header hash reference.
# Output: PSGI application code reference.
sub build_psgi_app {
    my ( $class, %args ) = @_;
    my $app = $args{app} || die 'Missing backend web app';
    my $default_headers = $args{default_headers} || {};
    $BACKEND_APP = {
        app             => $app,
        default_headers => { %{$default_headers} },
    };
    return __PACKAGE__->to_app;
}

# _current_backend()
# Returns the configured backend service object and default headers.
# Input: none.
# Output: hash reference with app object and default headers.
sub _current_backend {
    return $BACKEND_APP || die 'Missing backend web app';
}

# _request_headers()
# Normalizes the subset of inbound headers the backend service expects.
# Input: none.
# Output: hash reference with host and cookie values.
sub _request_headers {
    return {
        host   => scalar( request->header('Host') // '' ),
        cookie => scalar( request->header('Cookie') // '' ),
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

# _response_from_result($result)
# Applies one backend response onto the active Dancer2 response object.
# Input: backend response array reference.
# Output: plain body or delayed streaming response suitable for Dancer2.
sub _response_from_result {
    my ($result) = @_;
    my ( $code, $type, $body, $headers ) = @{$result};
    my $backend = _current_backend();
    my %merged_headers = (
        %{ $backend->{default_headers} || {} },
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

any [qw(get post)] => '/ajax' => sub {
    return _run_authorized('legacy_ajax_response');
};

any [qw(get post)] => '/ajax/singleton/stop' => sub {
    return _run_authorized('ajax_singleton_stop_response');
};

any [qw(get post)] => qr{^/ajax/(.+)$} => sub {
    return _run_authorized( 'legacy_ajax_file_response', ajax_file => _capture(0) );
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
    return _run_authorized(
        'static_file_response',
        type => _capture(0),
        file => _capture(1),
    );
};

get qr{^/app/(.+)/source$} => sub {
    return _run_authorized( 'page_source_response', id => _capture(0) );
};

post qr{^/app/(.+)/edit$} => sub {
    return _run_authorized( 'page_edit_post_response', id => _capture(0) );
};

get qr{^/app/(.+)/edit$} => sub {
    return _run_authorized( 'page_edit_response', id => _capture(0) );
};

post qr{^/app/(.+)/action/([^/]+)$} => sub {
    return _run_authorized(
        'page_action_response',
        id        => _capture(0),
        action_id => _capture(1),
    );
};

get qr{^/app/(.+)$} => sub {
    return _run_authorized( 'legacy_app_response', id => _capture(0) );
};

post '/action' => sub {
    return _run_authorized('transient_action_response');
};
any [qw(get post)] => qr{.*} => sub {
    return _run_authorized('dispatch_request');
};

1;

__END__

=head1 NAME

Developer::Dashboard::Web::DancerApp - Dancer2 route layer for Developer Dashboard

=head1 SYNOPSIS

  my $psgi_app = Developer::Dashboard::Web::DancerApp->build_psgi_app(
      app             => $web_app,
      default_headers => \%headers,
  );

=head1 DESCRIPTION

This module owns the HTTP route table for the dashboard web UI under Dancer2.
It normalizes each request, enforces authorization for protected routes, and
delegates the page and action work to C<Developer::Dashboard::Web::App>.

=head1 METHODS

=head2 build_psgi_app, _current_backend, _request_headers, _request_args, _response_from_result, _run_backend, _run_authorized

Build and serve the Dancer2 application around the dashboard route handlers.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module adapts the dashboard route backend to PSGI/Dancer-style request handling. It turns the backend app object into a PSGI coderef, translates request and response state, and preserves the dashboard default headers while keeping the route logic out of the transport adapter.

=head1 WHY IT EXISTS

It exists because the transport adapter should be small and separate from the actual route behavior. The dashboard needs a bridge from PSGI requests to the backend app object without forcing the backend to know about Dancer internals.

=head1 WHEN TO USE

Use this file when changing PSGI wrapping, response translation, or the way the backend app is exposed to Plack and Starman.

=head1 HOW TO USE

Call C<build_psgi_app> with the backend app object and default headers, then pass the returned coderef to a PSGI server. Route behavior and auth logic should stay in C<Developer::Dashboard::Web::App>.

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
