package Limper;
$Limper::VERSION = '0.015';
use 5.10.0;
use strict;
use warnings;

use IO::Socket;

use Exporter qw/import/;
our @EXPORT = qw/get post put del trace options patch any status headers request response config hook limp/;
our @EXPORT_OK = qw/info warning rfc1123date/;

# data stored here
my $request = {};
my $response = {};
my $config = {};
my $hook = {};
my $conn;

# route subs
my $route = {};
sub get     { push @{$route->{GET}},     @_; @_ }
sub post    { push @{$route->{POST}},    @_; @_ }
sub put     { push @{$route->{PUT}},     @_; @_ }
sub del     { push @{$route->{DELETE}},  @_; @_ }
sub trace   { push @{$route->{TRACE}},   @_; @_ }
sub options { push @{$route->{OPTIONS}}, @_; @_ }
sub patch   { push @{$route->{PATCH}},   @_; @_ }
sub any     { push @{$route->{$_}},      @_ for keys %$route }
sub routes  { $_[0] ? $route->{uc $_[0]} : $route }

# for send_response()
my $reasons = {
    100 => 'Continue',
    101 => 'Switching Protocols',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Time-out',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Requested range not satisfiable',
    417 => 'Expectation Failed',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Time-out',
    505 => 'HTTP Version not supported',
};

# for get_request()
my $method_rx = qr/(?: OPTIONS | GET | HEAD | POST | PUT | DELETE | TRACE | CONNECT )/x;
my $version_rx = qr{HTTP/\d+\.\d+};
my $uri_rx = qr/[^ ]+/;

# Returns current time or passed timestamp as an HTTP 1.1 date
my @months = qw/Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec/;
my @days = qw/Sun Mon Tue Wed Thu Fri Sat/;
sub rfc1123date {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = @_ ? gmtime $_[0] : gmtime;
    sprintf '%s, %02d %s %4d %02d:%02d:%02d GMT', $days[$wday], $mday, $months[$mon], $year + 1900, $hour, $min, $sec;
}

# Formats date like "2014-08-17 00:12:41" in local time.
sub date {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
    sprintf '%04d-%02d-%02d %02d:%02d:%02d', $year + 1900, $mon + 1, $mday, $hour, $min, $sec;
}

# Trivially log to STDOUT or STDERR
sub info    { say  date, ' ', @_ }
sub warning { warn date, ' ', @_ }

sub timeout {
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm($config->{timeout} // 5);
        $_ = $_[0]->();
        alarm 0;
    };
    $@ ? ($conn->close and undef) : $_;
}

sub bad_request {
    warning "[$request->{remote_host}] bad request: $_[0]";
    $response = { status => 400, body => 'Bad Request' };
    send_response($request->{method} // '' eq 'HEAD', 'close');
}

# Returns a processed request as a hash, or sends a 400 and closes if invalid.
sub get_request {
    $request = { headers => {}, remote_host => $conn->peerhost // 'localhost' };
    $response = { headers => {} };
    my ($request_line, $headers_done, $chunked);
    while (1) {
        defined(my $line = timeout(sub { $conn->getline })) or last;
        if (!defined $request_line) {
            next if $line eq "\r\n";
            ($request->{method}, $request->{uri}, $request->{version}) = $line =~ /^($method_rx) ($uri_rx) ($version_rx)\r\n/;
            return bad_request $line unless defined $request->{method};
            ($request->{scheme}, $request->{authority}, $request->{path}, $request->{query}, $request->{fragment}) =
                    $request->{uri} =~ m|(?:([^:/?#]+):)?(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?|;	# from https://metacpan.org/pod/URI
            $request_line = 1;
        } elsif (!defined $headers_done) {
            if ($line =~ /^\r\n/) {
                $headers_done = 1;
            } else {
                my ($name, $value) = split /:[ \t]*/, $line, 2;
                if ($name =~ /\r\n/) {
                    return bad_request $line;
                }
                $value =~ s/\r\n//;
                $value = $1 if lc $name eq 'host' and $request->{version} eq 'HTTP/1.1' and $request->{uri} =~ s{^https?://(.+?)/}{/};
                if (exists $request->{headers}{lc $name}) {
                    if (ref $request->{headers}{lc $name}) {
                        push @{$request->{headers}{lc $name}}, $value;
                    } else {
                        $request->{headers}{lc $name} = [$request->{headers}{lc $name}, $value];
                    }
                } else {
                    $request->{headers}{lc $name} = $value;
                }
            }
        }
        if (defined $headers_done) {
            return if defined $chunked;
            info "[$request->{remote_host}] $request->{method} $request->{uri} $request->{version} [", $request->{headers}{'user-agent'} // '', ']';
            return bad_request 'Host header missing' if $request->{version} eq 'HTTP/1.1' and (!exists $request->{headers}{host} or ref $request->{headers}{host});
            for (keys %{$request->{headers}}) {
                if ($_ eq 'expect' and lc $request->{headers}{$_} eq '100-continue' and $request->{version} eq 'HTTP/1.1') {
                    $conn->print("HTTP/1.1 100 Continue\r\n\r\n");	# this does not check if route is valid. just here to comply.
                } elsif ($_ eq 'content-length') {
                    timeout(sub { $conn->read($request->{body}, $request->{headers}{$_}) });
                    last;
                } elsif ($_ eq 'transfer-encoding' and lc $request->{headers}{$_} eq 'chunked') {
                    my $length = my $offset = $chunked = 0;
                    do {
                        $_ = timeout(sub { $conn->getline });
                        $length = hex((/^([A-Fa-f0-9]+)(?:;.*)?\r\n/)[0]);
                        timeout(sub { $conn->read($request->{body}, $length + 2, $offset) }) if $length;
                        $offset += $length;
                    } while $length;
                    $request->{body} =~ s/\r\n$//;
                    undef $headers_done; # to get optional footers, and another blank line
                }
            }
            last if defined $headers_done;
        }
    }
}

# Finds and calls the appropriate route sub, or sends a 404 response.
sub handle_request {
    my $head = 1;
    (defined $request->{method} and $request->{method} eq 'HEAD') ? ($request->{method} = 'GET') : ($head = 0);
    if (defined $request->{method} and exists $route->{$request->{method}}) {
        for (my $i = 0; $i < @{$route->{$request->{method}}}; $i += 2) {
            if ($route->{$request->{method}}[$i] eq $request->{path} ||
                        ref $route->{$request->{method}}[$i] eq 'Regexp' and $request->{path} =~ $route->{$request->{method}}[$i]) {
                $response->{body} = & { $route->{$request->{method}}[$i+1] };
                return send_response($head);
            }
        }
    }
    $response->{body} = 'This is the void';
    $response->{status} = 404;
    send_response($head);
}

# Sends a response to client. Default status is 200.
sub send_response {
    my ($head, $connection) = @_;
    $connection //= (($request->{version} // '') eq 'HTTP/1.1')
            ? lc($request->{headers}{connection} // '')
            : lc($request->{headers}{connection} // 'close') eq 'keep-alive' ? 'keep-alive' : 'close';
    $response->{status} //= 200;
    $response->{headers}{Date} = rfc1123date();
    if (defined $response->{body} and !ref $response->{body}) {
        $response->{headers}{'Content-Length'} //= length $response->{body};
        $response->{headers}{'Content-Type'} //= 'text/plain';
    }
    delete $response->{body} if $head // 0;
    $response->{headers}{Connection} = $connection if $connection eq 'close' or ($connection eq 'keep-alive' and $request->{version} ne 'HTTP/1.1');
    $response->{headers}{Server} = 'limper/' . ($Limper::VERSION // 'pre-release');
    $_->($request, $response) for @{$hook->{after}};
    return $hook->{response_handler}[0]->() if exists $hook->{response_handler};
    {
        local $\ = "\r\n";
        $conn->print(join ' ', $request->{version} // 'HTTP/1.1', $response->{status}, $response->{reason} // $reasons->{$response->{status}});
        return unless $conn->connected;
        my @headers = headers();
        $conn->print( join(': ', splice(@headers, 0, 2)) ) while @headers;
        $conn->print();
    }
    $conn->print($response->{body} // '') if defined $response->{body};
    $conn->close if $connection eq 'close';
}

sub status {
    if (defined wantarray) {
        wantarray ? ($response->{status}, $response->{reason}) : $response->{status};
    } else {
        $response->{status} = shift;
        $response->{reason} = shift if @_;
    }
}

sub headers {
    if (!defined wantarray) {
        $response->{headers}{+pop} = pop while @_;
    } else {
        my @headers;
        for my $key (keys %{ $response->{headers} }) {
            if (ref $response->{headers}{$key}) {
                push @headers, $key, $_ for @{$response->{headers}{$key}};
            } else {
                push @headers, $key, $response->{headers}{$key};
            }
        }
        @headers;
    }
}

sub request { $request }

sub response { $response }

sub config { $config }

sub hook { push @{$hook->{$_[0]}}, $_[1] }

sub limp {
    $config = shift @_ if ref $_[0] eq 'HASH';
    return $hook->{request_handler}[0] if exists $hook->{request_handler};
    my $sock = IO::Socket::INET->new(Listen => SOMAXCONN, ReuseAddr => 1, LocalAddr => 'localhost', LocalPort => 8080, Proto => 'tcp', @_)
            or die "cannot bind to port: $!";

    info 'limper started';

    for (1 .. $config->{workers} // 5) {
        defined(my $pid = fork) or die "fork failed: $!";
        while (!$pid) {
            if ($conn = $sock->accept()) {
                do {
                    eval {
                        get_request;
                        handle_request if $conn->connected;
                    };
                    if ($@) {
                        $response = { status => 500, body => $config->{debug} // 0 ? $@ : 'Internal Server Error' };
                        send_response 0, 'close';
                        warning $@;
                    }
                } while ($conn->connected);
            }
        }
    }
    1 while (wait != -1);

    my $shutdown = $sock->shutdown(2);
    my $closed = $sock->close();
    info 'shutdown ', $shutdown ? 'successful' : 'unsuccessful';
    info 'closed ', $closed ? 'successful' : 'unsuccessful';
}

1;

__END__

=for Pod::Coverage bad_request date get_request handle_request send_response timeout

=head1 NAME

Limper - extremely lightweight but not very powerful web application framework

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  use Limper;

  my $generic = sub { 'yay' };

  get '/' => $generic;
  post '/' => $generic;

  post qr{^/foo/} => sub {
      status 202, 'whatevs';
      headers Foo => 'bar', Fizz => 'buzz';
      'you posted something: ' . request->{body};
  };

  get '/baz' => sub {
      'your non-decoded query, if any: ' . request->{query};	# URIs of '/baz?fizz=buzz&foo=bar' now work
  };

  limp;

=head1 DESCRIPTION

B<Limper> was originally designed to primarily be a simple HTTP/1.1 test
server in perl, but I realized it can be much more than that while still
remaining simple.

B<Limper> has a simple syntax like L<Dancer> yet no dependencies at all,
unlike the dozens that L<Dancer> pulls in.

B<Limper> is modular - support for serving files, easily returning JSON, or
using PSGI can be included if and only if needed (and these features already
exist on CPAN).

B<Limper> is fast - about 2-3 times faster than Dancer.

B<Limper> also fatpacks beautifully (at least on 5.10.1):

  fatpack pack example.pl > example-packed.pl

Do not taunt B<Limper>.

=head1 EXPORTS

The following are all exported by default:

  get post put del trace options patch any
  status headers request response config hook limp

Also exportable:

  info warning rfc1123date

Not exportable, because it is a footgun:

  routes

=head1 FUNCTIONS

=head2 get

=head2 post

=head2 put

=head2 del

=head2 trace

=head2 options

=head2 patch

Defines a route handler for METHOD to the given path:

  get '/' => sub { 'Hello world!' };

These can be chained together like so:

  get post del '/' => sub { 'Hello world!' };

Note that a route to match B<HEAD> requests is automatically created as well for B<get>.

=head2 any

Defines a route handler for B<all> METHODs to the given path:

  any '/' => sub { 'Hello world!' };

=head2 routes

Returns all routes for all verbs, or if passed an argument the routes for that verb.

WARNING: this is the actual routing data, not a copy. Meaning you can completely break everything by modifying this unless you know what you're doing.

=head2 status

Get or set the response status, and optionally reason.

  status 404;
  status 401, 'Nope';
  my $status = status;
  my ($status, $reason) = status;

=head2 headers

Get or set the response headers.

  headers Foo => 'bar', Fizz => 'buzz';
  headers Foo => ['this', 'that'];                # change Foo to two values
  headers Oops => 'inserted', Oops => 'ignored';  # don't do this
  my @headers = headers;

Note: Changed in 0.012. The headers are now stored in a hashref, where the
value is either a string or array of strings.  Calling B<headers> in list
mode returns a flattened list.  If you want the hashref of headers, use B<
response->{headers} >>.  Setting header pairs no longer overwrites all
previously defined headers.

=head2 request

Returns a B<HASH> of the request. Request keys are: B<method>, B<uri>, and
B<version>.  B<uri> is now broken down and there are additional keys:
B<scheme>, B<authority>, B<path>, B<query>, and B<fragment>.  It may also
contain B<headers> which is a B<HASH> and B<body>.

There is no decoding of the body content nor URL parameters.

=head2 response

Returns response B<HASH>. Keys are B<status>, B<reason>, B<headers> (a
B<HASH> of key/value pairs), and B<body>.

=head2 config

Returns config B<HASH>. See B<limp> below for known config settings.

=head2 hook

Adds a hook at some position.

Three hooks are currently defined: B<after>, B<request_handler>, and B<response_handler>.

=head3 after

Runs after all other processing, just before response is sent.

  hook after => sub {
    my ($request, $response) = @_;
    # modify response as needed
  };

=head3 request_handler

Runs when B<limp> is called, after only setting passed config settings, and returns
the result instead of starting up the built-in web server.  A simplified
example for PSGI (including the B<response_handler> below) is:

  hook request_handler => sub {
    get_psgi @_;
    handle_request;
  };

=head3 response_handler

Runs right after the B<after> hook, and returns the result instead of using
the built-in web server for sending the response. For PSGI, this is:

  hook response_handler => sub {
    [ response->{status}, [headers], ref response->{body} ? response->{body} : [response->{body}] ];
  };

=head2 limp

Starts the server. You can pass it the same options as L<IO::Socket::INET>
takes.  The default options are:

  Listen => SOMAXCONN, ReuseAddr => 1, LocalAddr => 'localhost', LocalPort => 8080, Proto => 'tcp'

In addition, the first argument can be a B<HASH> to pass config settings:

  limp({debug => 1, timeout => 60, workers => 10}, LocalAddr => '0.0.0.0', LocalPort => 3001);

Default debug is B<0>, default timeout is B<5> (seconds), and default
workers is B<10>.  A timeout of B<0> means never timeout.

This keyword should be called at the very end of the script, once all routes
are defined.  At this point, Limper takes over control.

=head1 ADDITIONAL FUNCTIONS

=head2 info

=head2 warning

Log given list to B<STDOUT> or B<STDERR>. Prepends the current local time in
format "YYYY-MM-DD HH:MM:SS".

=head2 rfc1123date

Returns the current time or passed timestamp as an HTTP 1.1 date (RFC 1123).

=head1 EVEN MORE

For additional (discouraged) functions to aid in transitioning to Limper, see L<Limper::Sugar>.

For sending files and easily sending JSON, see L<Limper::SendFile> and L<Limper::SendJSON>.

For differences between Limper and Dancer, see L<Limper::Differences>.

For extending Limper, see L<Limper::Extending>.

=head1 NOTICE

This framework is still under development. Things B<may> change without
warning.  Version 0.012 has such changes, but I hope I have what is in this
version stable.

=head1 BREAKING CHANGES IN 0.012

B<options> is now B<config>, and there is a new function B<options> for the
HTTP method.

B<note> has been changed to B<info>.

B<headers> now will update just the fields given, and not replace all the
headers.  The headers are now stored as a B<HASH> instead of an B<ARRAY>.
Hence, C<< response->{headers} >> cannot be directly passed to PSGI.  Instead
C<< [headers] >> meets this need.

C<< request->{header} >> is now what C<< request->{hheader} >> was - no more
ARRAY form.

=head1 CONTRIBUTING

=head2 Patches and Bug Fixes

Preferably, clone the repo (uses L<Dist::Zilla>) and create one or more
patch files with:

  git format patch <latest commit>

Email me the patch, or otherwise let me know how to find it.

Or if it's a simple patch and you don't want to mess with L<Dist::Zilla>,
patch the latest release and send me a patch file.

=head2 Module Namespaces

See L<Limper::Extending/NAMESPACES>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ashley Willis E<lt>ashley+perl@gitable.orgE<gt>

B<rabcyr> on irc and L<twitter|https://twitter.com/rabcyr>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<Limper::Differences>

L<Limper::Extending>

L<Limper::Engine::PSGI>

L<Limper::SendFile>

L<Limper::SendJSON>

L<Limper::Sugar>

L<App::FatPacker>

L<IO::Socket::INET>

L<Web::Simple>
