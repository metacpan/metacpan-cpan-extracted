package HTTP::AnyUA;
# ABSTRACT: An HTTP user agent programming interface unification layer


use 5.010;
use warnings;
use strict;

our $VERSION = '0.902'; # VERSION

use HTTP::AnyUA::Util;
use Module::Loader;
use Scalar::Util;


our $BACKEND_NAMESPACE;
our $MIDDLEWARE_NAMESPACE;
our @BACKENDS;
our %REGISTERED_BACKENDS;

BEGIN {
    $BACKEND_NAMESPACE      = __PACKAGE__ . '::Backend';
    $MIDDLEWARE_NAMESPACE   = __PACKAGE__ . '::Middleware';
}


sub _debug_log { print STDERR join(' ', @_), "\n" if $ENV{PERL_HTTP_ANYUA_DEBUG} }

sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }



sub new {
    my $class = shift;
    unshift @_, 'ua' if @_ % 2;
    my %args = @_;
    $args{ua} or _usage(q{HTTP::AnyUA->new(ua => $user_agent, %attr)});

    my $self;
    my @attr = qw(ua backend response_is_future);

    for my $attr (@attr) {
        $self->{$attr} = $args{$attr} if defined $args{$attr};
    }

    bless $self, $class;

    $self->_debug_log('Created with user agent', $self->ua);

    # call accessors to get the checks to run
    $self->ua;
    $self->response_is_future($args{response_is_future}) if defined $args{response_is_future};

    return $self;
}


sub ua { shift->{ua} or _croak 'User agent is required' }


sub response_is_future {
    my $self = shift;
    my $val  = shift;

    if (defined $val) {
        $self->_debug_log('Set response_is_future to', $val ? 'ON' : 'OFF');

        $self->_check_response_is_future($val);
        $self->{response_is_future} = $val;

        $self->_module_loader->load('Future') if $self->{response_is_future};
    }
    elsif (!defined $self->{response_is_future} && $self->{backend}) {
        $self->{response_is_future} = $self->backend->response_is_future;

        $self->_module_loader->load('Future') if $self->{response_is_future};
    }

    return $self->{response_is_future} || '';
}


sub backend {
    my $self = shift;

    return $self->{backend} if defined $self->{backend};

    $self->{backend} = $self->_build_backend;
    $self->_check_response_is_future($self->response_is_future);

    return $self->{backend};
}


sub request {
    my ($self, $method, $url, $args) = @_;
    $args ||= {};
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
        or _usage(q{$any_ua->request($method, $url, \%options)});

    my $resp = eval { $self->backend->request(uc($method) => $url, $args) };
    if (my $err = $@) {
        return $self->_wrap_internal_exception($err);
    }

    return $self->_wrap_response($resp);
}


# adapted from HTTP/Tiny.pm
for my $sub_name (qw{get head put post delete}) {
    my %swap = (SUBNAME => $sub_name, METHOD => uc($sub_name));
    my $code = q[
sub {{SUBNAME}} {
    my ($self, $url, $args) = @_;
    @_ == 2 || (@_ == 3 && ref $args eq 'HASH')
        or _usage(q{$any_ua->{{SUBNAME}}($url, \%options)});
    return $self->request('{{METHOD}}', $url, $args);
}
    ];
    $code =~ s/\{\{([A-Z_]+)\}\}/$swap{$1}/ge;
    eval $code;     ## no critic
}


# adapted from HTTP/Tiny.pm
sub post_form {
    my ($self, $url, $data, $args) = @_;
    (@_ == 3 || @_ == 4 && ref $args eq 'HASH')
        or _usage(q{$any_ua->post_form($url, $formdata, \%options)});

    my $headers = HTTP::AnyUA::Util::normalize_headers($args->{headers});
    delete $args->{headers};

    return $self->request(POST => $url, {
        %$args,
        content => HTTP::AnyUA::Util::www_form_urlencode($data),
        headers => {
            %$headers,
            'content-type' => 'application/x-www-form-urlencoded',
        },
    });
}


# adapted from HTTP/Tiny.pm
sub mirror {
    my ($self, $url, $file, $args) = @_;
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
        or _usage(q{$any_ua->mirror($url, $filepath, \%options)});

    $args->{headers} = HTTP::AnyUA::Util::normalize_headers($args->{headers});

    if (-e $file and my $mtime = (stat($file))[9]) {
        $args->{headers}{'if-modified-since'} ||= HTTP::AnyUA::Util::http_date($mtime);
    }
    my $tempfile = $file . int(rand(2**31));

    # set up the response body to be written to the file
    require Fcntl;
    sysopen(my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY())
        or return $self->_wrap_internal_exception(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;
    $args->{data_callback} = sub { print $fh $_[0] };

    my $resp = $self->request(GET => $url, $args);

    my $finish = sub {
        my $resp = shift;

        close $fh
            or return HTTP::AnyUA::Util::internal_exception(qq/Error: Caught error closing temporary file $tempfile: $!\n/);

        if ($resp->{success}) {
            rename($tempfile, $file)
                or return HTTP::AnyUA::Util::internal_exception(qq/Error replacing $file with $tempfile: $!\n/);
            my $lm = $resp->{headers}{'last-modified'};
            if ($lm and my $mtime = HTTP::AnyUA::Util::parse_http_date($lm)) {
                utime($mtime, $mtime, $file);
            }
        }
        unlink($tempfile);

        $resp->{success} ||= $resp->{status} eq '304';

        return $resp;
    };

    if ($self->response_is_future) {
        return $resp->followed_by(sub {
            my $future = shift;
            my @resp = $future->is_done ? $future->get : $future->failure;
            my $resp = $finish->(@resp);
            if ($resp->{success}) {
                return Future->done(@resp);
            }
            else {
                return Future->fail(@resp);
            }
        });
    }
    else {
        return $finish->($resp);
    }
}


sub apply_middleware {
    my $self    = shift;
    my $class   = shift;

    if (!ref $class) {
        $class = "${MIDDLEWARE_NAMESPACE}::${class}" unless $class =~ s/^\+//;
        $self->_module_loader->load($class);
    }

    $self->{backend} = $class->wrap($self->backend, @_);
    $self->_check_response_is_future($self->response_is_future);

    return $self;
}


sub register_backend {
    my ($class, $ua_type, $backend_class) = @_;
    @_ == 3 or _usage(q{HTTP::AnyUA->register_backend($ua_type, $backend_package)});

    if ($backend_class) {
        $backend_class = "${BACKEND_NAMESPACE}::${backend_class}" unless $backend_class =~ s/^\+//;
        $REGISTERED_BACKENDS{$ua_type} = $backend_class;
    }
    else {
        delete $REGISTERED_BACKENDS{$ua_type};
    }
}


# turn a response into a Future if it needs to be
sub _wrap_response {
    my $self = shift;
    my $resp = shift;

    if ($self->response_is_future && !$self->backend->response_is_future) {
        # wrap the response in a Future
        if ($resp->{success}) {
            $self->_debug_log('Wrapped successful response in a Future');
            $resp = Future->done($resp);
        }
        else {
            $self->_debug_log('Wrapped failed response in a Future');
            $resp = Future->fail($resp);
        }
    }

    return $resp;
}

sub _wrap_internal_exception { shift->_wrap_response(HTTP::AnyUA::Util::internal_exception(@_)) }

# get a module loader object
sub _module_loader { shift->{_module_loader} ||= Module::Loader->new }

# get a list of potential backends that may be able to handle the user agent
sub _build_backend {
    my $self = shift;
    my $ua   = shift || $self->ua or _croak 'User agent is required';

    my $ua_type = Scalar::Util::blessed($ua);

    my @classes;

    if ($ua_type) {
        push @classes, $REGISTERED_BACKENDS{$ua_type} if $REGISTERED_BACKENDS{$ua_type};

        push @classes, "${BACKEND_NAMESPACE}::${ua_type}";

        if (!@BACKENDS) {
            # search for some backends to try
            @BACKENDS = sort $self->_module_loader->find_modules($BACKEND_NAMESPACE);
            $self->_debug_log('Found backends to try (' . join(', ', @BACKENDS) . ')');
        }

        for my $backend_type (@BACKENDS) {
            my $plugin = $backend_type;
            $plugin =~ s/^\Q${BACKEND_NAMESPACE}\E:://;
            push @classes, $backend_type if $ua->isa($plugin);
        }
    }
    else {
        push @classes, $REGISTERED_BACKENDS{$ua} if $REGISTERED_BACKENDS{$ua};
        push @classes, "${BACKEND_NAMESPACE}::${ua}";
    }

    for my $class (@classes) {
        if (eval { $self->_module_loader->load($class); 1 }) {
            $self->_debug_log("Found usable backend (${class})");
            return $class->new($self->ua);
        }
        else {
            $self->_debug_log($@);
        }
    }

    _croak 'Cannot find a usable backend that supports the given user agent';
}

# make sure the response_is_future setting is compatible with the backend
sub _check_response_is_future {
    my $self = shift;
    my $val  = shift;

    # make sure the user agent is not non-blocking
    if (!$val && $self->{backend} && $self->backend->response_is_future) {
        _croak 'Cannot disable response_is_future with a non-blocking user agent';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::AnyUA - An HTTP user agent programming interface unification layer

=head1 VERSION

version 0.902

=head1 SYNOPSIS

    my $any_ua = HTTP::AnyUA->new(ua => LWP::UserAgent->new);
    # OR: my $any_ua = HTTP::AnyUA->new(ua => Furl->new);
    # OR: my $any_ua = HTTP::AnyUA->new(ua => HTTP::Tiny->new);
    # etc...

    my $response = $any_ua->get('http://www.example.com/');

    print "$response->{status} $response->{reason}\n";

    while (my ($k, $v) = each %{$response->{headers}}) {
        for (ref $v eq 'ARRAY' ? @$v : $v) {
            print "$k: $_\n";
        }
    }

    print $response->{content} if length $response->{content};

    ### Non-blocking user agents cause Future objects to be returned:

    my $any_ua = HTTP::AnyUA->new(ua => HTTP::Tiny->new, response_is_future => 1);
    # OR: my $any_ua = HTTP::AnyUA->new(ua => 'AnyEvent::HTTP');
    # OR: my $any_ua = HTTP::AnyUA->new(ua => Mojo::UserAgent->new);
    # etc...

    my $future = $any_ua->get('http://www.example.com/');

    $future->on_done(sub {
        my $response = shift;

        print "$response->{status} $response->{reason}\n";

        while (my ($k, $v) = each %{$response->{headers}}) {
            for (ref $v eq 'ARRAY' ? @$v : $v) {
                print "$k: $_\n";
            }
        }

        print $response->{content} if length $response->{content};
    });

    $future->on_fail(sub { print STDERR "Oh no!!\n" });

=head1 DESCRIPTION

This module provides a small wrapper for unifying the programming interfaces of several different
actual user agents (HTTP clients) under one B<familiar> interface.

Rather than providing yet another programming interface for you to learn, HTTP::AnyUA follows the
L<HTTP::Tiny> interface. This also means that you can plug in any supported HTTP client
(L<LWP::UserAgent>, L<Furl>, etc.) and use it as if it were L<HTTP::Tiny>.

There are a lot of great HTTP clients available for Perl, each with different goals, different
feature sets, and of course different programming interfaces! If you're an end user, you can just
pick one of these clients according to the needs of your project (or personal preference). But if
you're writing a module that needs to interface with a web server (like perhaps a RESTful API
wrapper) and you want your users to be able to use whatever HTTP client they want, HTTP::AnyUA can
help you support that!

It's a good idea to let the end user pick whatever HTTP client they want to use, because they're the
one who knows the requirements of their application or script. If you're writing an event-driven
application, you'll need to use a non-blocking user agent like L<Mojo::UserAgent>. If you're writing
a simple command-line script, you may decide that your priority is to minimize dependencies and so
may want to go with L<HTTP::Tiny>.

Unfortunately, many modules on CPAN are hardcoded to work with specific HTTP clients, leaving the
end user unable to use the HTTP client that would be best for them. Although the end user won't --
or at least doesn't need to -- use HTTP::AnyUA directly, they will benefit from client choice if
their third-party modules use HTTP::AnyUA or something like it.

The primary goal of HTTP::AnyUA is to make it easy for module developers to write HTTP code once
that can work with any HTTP client the end user may decide to plug in. A secondary goal is to make
it easy for anyone to add support for new or yet-unsupported user agents.

=head1 ATTRIBUTES

=head2 ua

Get the user agent that was passed to L</new>.

=head2 response_is_future

Get and set whether or not responses are L<Future> objects.

=head2 backend

Get the backend instance. You normally shouldn't need this.

=head1 METHODS

=head2 new

    $any_ua = HTTP::AnyUA->new(ua => $user_agent, %attr);
    $any_ua = HTTP::AnyUA->new($user_agent, %attr);

Construct a new HTTP::AnyUA.

=head2 request

    $response = $any_ua->request($method, $url);
    $response = $any_ua->request($method, $url, \%options);

Make a L<request|/"The Request">, get a L<response|/"The Response">.

Compare to L<HTTP::Tiny/request>.

=head2 get, head, put, post, delete

    $response = $any_ua->get($url);
    $response = $any_ua->get($url, \%options);
    $response = $any_ua->head($url);
    $response = $any_ua->head($url, \%options);
    # etc.

Shortcuts for L</request> where the method is the method name rather than the first argument.

Compare to L<HTTP::Tiny/getE<verbar>headE<verbar>putE<verbar>postE<verbar>delete>.

=head2 post_form

    $response = $any_ua->post_form($url, $formdata);
    $response = $any_ua->post_form($url, $formdata, \%options);

Does a C<POST> request with the form data encoded and sets the C<Content-Type> header to
C<application/x-www-form-urlencoded>.

Compare to L<HTTP::Tiny/post_form>.

=head2 mirror

    $response = $http->mirror($url, $filepath, \%options);
    if ($response->{success}) {
        print "$filepath is up to date\n";
    }

Does a C<GET> request and saves the downloaded document to a file. If the file already exists, its
timestamp will be sent using the C<If-Modified-Since> request header (which you can override). If
the server responds with a C<304> (Not Modified) status, the C<success> field will be true; this is
usually only the case for C<2XX> statuses. If the server responds with a C<Last-Modified> header,
the file will be updated to have the same modification timestamp.

Compare to L<HTTP::Tiny/mirror>. This version differs slightly in that this returns internal
exception responses (for cases like being unable to write the file locally, etc.) rather than
actually throwing the exceptions. The reason for this is that exceptions as responses are easier to
deal with for non-blocking HTTP clients, and the fact that this method throws exceptions in
L<HTTP::Tiny> seems like an inconsistency in its interface.

=head2 apply_middleware

    $any_ua->apply_middleware($middleware_package);
    $any_ua->apply_middleware($middleware_package, %args);
    $any_ua->apply_middleware($middleware_obj);

Wrap the backend with some new middleware. Middleware packages are relative to the
C<HTTP::AnyUA::Middleware::> namespace unless prefixed with a C<+>.

This effectively replaces the L</backend> with a new object that wraps the previous backend.

This can be used multiple times to add multiple layers of middleware, and order matters. The last
middleware applied is the first one to see the request and last one to get the response. For
example, if you apply middleware that does logging and middleware that does caching (and
short-circuits on a cache hit), applying your logging middleware I<first> will cause only cache
misses to be logged whereas applying your cache middleware first will allow all requests to be
logged.

See L<HTTP::AnyUA::Middleware> for more information about what middleware is and how to write your
own middleware.

=head2 register_backend

    HTTP::AnyUA->register_backend($user_agent_package => $backend_package);
    HTTP::AnyUA->register_backend('MyAgent' => 'MyBackend');    # HTTP::AnyUA::Backend::MyBackend
    HTTP::AnyUA->register_backend('LWP::UserAgent' => '+SpecialBackend');   # SpecialBackend

Register a backend for a new user agent type or override a default backend. Backend packages are
relative to the C<HTTP::AnyUA::Backend::> namespace unless prefixed with a C<+>.

If you only need to set a backend as a one-off thing, you could also pass an instantiated backend to
L</new>.

=head1 SPECIFICATION

This section specifies a standard set of data structures that can be used to make a request and get
a response from a user agent. This is the specification HTTP::AnyUA uses for its programming
interface. It is heavily based on L<HTTP::Tiny>'s interface, and parts of this specification were
adapted or copied verbatim from that module's documentation. The intent is for this specification to
be written such that L<HTTP::Tiny> is already a compliant implementor of the specification (at least
as of the specification's publication date).

=head2 The Request

A request is a tuple of the form C<(Method, URL)> or C<(Method, URL, Options)>.

=head3 Method

Method B<MUST> be a string representing the HTTP verb. This is commonly C<"GET">, C<"POST">,
C<"HEAD">, C<"DELETE">, etc.

=head3 URL

URL B<MUST> be a string representing the remote resource to be acted upon. The URL B<MUST> have
unsafe characters escaped and international domain names encoded before being passed to the user
agent. A user agent B<MUST> generate a C<"Host"> header based on the URL in accordance with RFC
2616; a user agent B<MAY> throw an error if a C<"Host"> header is given with the L</headers>.

=head3 Options

Options, if present, B<MUST> be a hash reference containing zero or more of the following keys with
appropriate values. A user agent B<MAY> support more options than are specified here.

=head4 headers

The value for the C<headers> key B<MUST> be a hash reference containing zero or more HTTP header
names (as keys) and header values. The value for a header B<MUST> be either a string containing the
header value OR an array reference where each item is a string. If the value for a header is an
array reference, the user agent B<MUST> output the header multiple times with each value in the
array.

User agents B<MAY> may add headers, but B<SHOULD NOT> replace user-specified headers unless
otherwise documented.

=head4 content

The value for the C<content> key B<MUST> be a string OR a code reference. If the value is a string,
its contents will be included with the request as the body. If the value is a code reference, the
referenced code will be called iteratively to produce the body of the request, and the code B<MUST>
return an empty string or undef value to indicate the end of the request body. If the value is
a code reference, a user agent B<SHOULD> use chunked transfer encoding if it supports it, otherwise
a user agent B<MAY> completely drain the code of content before sending the request.

=head4 data_callback

The value for the C<data_callback> key B<MUST> be a code reference that will be called zero or more
times, once for each "chunk" of response body received. A user agent B<MAY> send the entire response
body in one call. The referenced code B<MUST> be given two arguments; the first is a string
containing a chunk of the response body, the second is an in-progress L<response|/The Response>.

=head2 The Response

A response B<MUST> be a hash reference containg some required keys and values. A response B<MAY>
contain some optional keys and values.

=head3 success

A response B<MUST> include a C<success> key, the value of which is a boolean indicating whether or
not the request is to be considered a success (true is a success). Unless otherwise documented,
a successful result means that the operation returned a 2XX status code.

=head3 url

A response B<MUST> include a C<url> key, the value of which is the URL that provided the response.
This is the URL used in the request unless there were redirections, in which case it is the last URL
queried in a redirection chain.

=head3 status

A response B<MUST> include a C<status> key, the value of which is the HTTP status code of the
response. If an internal exception occurs (e.g. connection error), then the status code B<MUST> be
C<599>.

=head3 reason

A response B<MUST> include a C<reason> key, the value of which is the response phrase returned by
the server OR "Internal Exception" if an internal exception occurred.

=head3 content

A response B<MAY> include a C<content> key, the value of which is the response body returned by the
server OR the text of the exception if an internal exception occurred. This field B<MUST> be missing
or empty if the server provided no response OR if the body was already provided via
L</data_callback>.

=head3 headers

A response B<SHOULD> include a C<headers> key, the value of which is a hash reference containing
zero or more HTTP header names (as keys) and header values. Keys B<MUST> be lowercased. The value
for a header B<MUST> be either a string containing the header value OR an array reference where each
item is the value of one of the repeated headers.

=head3 redirects

A response B<MAY> include a C<redirects> key, the value of which is an array reference of one or
more responses from redirections that occurred to fulfill the current request, in chronological
order.

=head1 FREQUENTLY ASKED QUESTIONS

=head2 How do I set up proxying, SSL, cookies, timeout, etc.?

HTTP::AnyUA provides a common interface for I<using> HTTP clients, not for instantiating or
configuring them. Proxying, SSL, and other custom settings can be configured directly through the
underlying HTTP client; see the documentation for your particular user agent to learn how to
configure these things.

L<AnyEvent::HTTP> is a bit of a special case because there is no instantiated object representing
the client. For this particular user agent, you can configure the backend to pass a default set of
options whenever it calls C<http_request>. See L<HTTP::AnyUA::Backend::AnyEvent::HTTP/options>:

    $any_ua->backend->options({recurse => 5, timeout => 15});

If you are a module writer, you should probably receive a user agent from your end user and leave
this type of configuration up to them.

=head2 Why use HTTP::AnyUA instead of some other HTTP client?

Maybe you shouldn't. If you're an end user writing a script or application, you can just pick the
HTTP client that suits you best and use it. For example, if you're writing a L<Mojolicious> app,
you're not going wrong by using L<Mojo::UserAgent>; it's loaded with features and is well-integrated
with that particular environment.

As an end user, you I<could> wrap the HTTP client you pick in an HTTP::AnyUA object, but the only
reason to do this is if you prefer using the L<HTTP::Tiny> interface.

The real benefit of HTTP::AnyUA (or something like it) is if module writers use it to allow end
users of their modules to be able to plug in whatever HTTP client they want. For example, a module
that implements an API wrapper that has a hard dependency on L<LWP::UserAgent> or even L<HTTP::Tiny>
is essentially useless for non-blocking applications. If the same hypothetical module had been
written using HTTP::AnyUA then it would be useful in any scenario.

=head2 Why use the HTTP::Tiny interface?

The L<HTTP::Tiny> interface is simple but provides all the essential functionality needed for
a capable HTTP client and little more. That makes it easy to provide an implementation for, and it
also makes it straightforward for module authors to use.

Marrying the L<HTTP::Tiny> interface with L<Future> gives us these benefits for both blocking and
non-blocking modules and applications.

=head1 SUPPORTED USER AGENTS

=over 4

=item *

L<AnyEvent::HTTP>

=item *

L<Furl>

=item *

L<HTTP::AnyUA> - a little bit meta, but why not?

=item *

L<HTTP::Tiny>

=item *

L<LWP::UserAgent>

=item *

L<Mojo::UserAgent>

=item *

L<Net::Curl::Easy>

=back

Any HTTP client that inherits from one of these in a well-behaved manner should also be supported.

Of course, there are many other HTTP clients on CPAN that HTTP::AnyUA doesn't yet support. I'm more
than happy to help add support for others, so send me a message if you know of an HTTP client that
needs support. See L<HTTP::AnyUA::Backend> for how to write support for a new HTTP client.

=head1 NON-BLOCKING USER AGENTS

HTTP::AnyUA tries to target the L<HTTP::Tiny> interface, which is a blocking interface. This means
that when you call L</request>, it is supposed to not return until either the response is received
or an error occurs. This doesn't jive well with non-blocking HTTP clients which expect the flow to
reenter an event loop so that the request can complete concurrently.

In order to reconcile this, a L<Future> will be returned instead of the normal hashref response if
the wrapped HTTP client is non-blocking (such as L<Mojo::UserAgent> or L<AnyEvent::HTTP>). This
L<Future> object may be used to set up callbacks that will be called when the request is completed.
You can call L</response_is_future> to know if the response is or will be a L<Future>.

This is typically okay for the end user; since they're the one who chose which HTTP client to use in
the first place, they should know whether they should expect a L<Future> or a direct response when
they make an HTTP request, but it does add some burden on you as a module writer because if you ever
need to examine the response, you may need to write code like this:

    my $resp = $any_ua->get('http://www.perl.org/');

    if ($any_ua->response_is_future) {
        $resp->on_done(sub {
            my $real_resp = shift;
            handle_response($real_resp);
        });
    }
    else {
        handle_response($resp);     # response is the real response already
    }

This actually isn't too annoying to deal with in practice, but you can avoid it if you like by
forcing the response to always be a L<Future>. Just set the L</response_is_future> attribute. Then
you don't need to do an if-else because the response will always be the same type:

    $any_ua->response_is_future(1);

    my $resp = $any_ua->get('http://www.perl.org/');

    $resp->on_done(sub {            # response is always a Future
        my $real_resp = shift;
        handle_response($real_resp);
    });

Note that this doesn't make a blocking HTTP client magically non-blocking. The call to L</request>
will still block if the client is blocking, and your "done" callback will simply be fired
immediately. But this does let you write the same code in your module and have it work regardless of
whether the underlying HTTP client is blocking or non-blocking.

The default behavior is to return a direct hashref response if the HTTP client is blocking and
a L<Future> if the client is non-blocking. It's up to you to decide whether or not to set
C<response_is_future>, and you should also consider whether you want to expose the possibility of
either type of response or always returning L<Future> objects to the end user of your module. It
doesn't matter for users who choose non-blocking HTTP clients because they will be using L<Future>
objects either way, but users who know they are using a blocking HTTP client may appreciate not
having to deal with L<Future> objects at all.

=head1 ENVIRONMENT

=over 4

=item *

C<PERL_HTTP_ANYUA_DEBUG> - If 1, print some info useful for debugging to C<STDERR>.

=back

=head1 CAVEATS

Not all HTTP clients implement the same features or in the same ways. While the point of HTTP::AnyUA
is to hide those differences, you may notice some (hopefully) I<insignificant> differences when
plugging in different clients. For example, L<LWP::UserAgent> sets some headers on the response such
as C<client-date> and C<client-peer> that won't appear when using other clients. Little differences
like these probably aren't a big deal. Other differences may be a bigger deal, depending on what's
important to you. For example, some clients (like L<HTTP::Tiny>) may do chunked transfer encoding in
situations where other clients won't (probably because they don't support it). It's not a goal of
this project to eliminate I<all> of the differences, but if you come across a difference that is
significant enough that you think you need to detect the user agent and write special logic, I would
like to learn about your use case.

=head1 SEE ALSO

These modules share similar goals or provide overlapping functionality:

=over 4

=item *

L<Future::HTTP>

=item *

L<HTTP::Any>

=item *

L<HTTP::Tinyish>

=item *

L<Plient>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/HTTP-AnyUA/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
