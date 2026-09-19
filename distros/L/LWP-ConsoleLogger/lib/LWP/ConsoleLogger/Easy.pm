package LWP::ConsoleLogger::Easy;

use strict;
use warnings;

our $VERSION = '1.000003';

use Class::Method::Modifiers  ();
use Hash::Util::FieldHash     qw( fieldhash );
use HTTP::Headers             ();
use HTTP::Request             ();
use HTTP::Response            ();
use LWP::ConsoleLogger        ();
use Module::Load::Conditional qw( can_load );
use Ref::Util                 qw( is_plain_arrayref is_ref );
use Sub::Exporter -setup => { exports => ['debug_ua'] };
use String::Trim qw( trim );
use URI          ();

fieldhash my %http_tiny_loggers;
my $http_tiny_wrapped;

my %VERBOSITY = (
    dump_content => 8,
    dump_cookies => 6,
    dump_headers => 5,
    dump_params  => 4,
    dump_status  => 2,
    dump_text    => 7,
    dump_title   => 3,
    dump_uri     => 1,
);

sub debug_ua {
    my $ua    = shift;
    my $level = shift;
    $level //= 10;

    my %args = map { $_ => $VERBOSITY{$_} <= $level } keys %VERBOSITY;
    my $console_logger = LWP::ConsoleLogger->new(%args);

    add_ua_handlers( $ua, $console_logger );

    if ( can_load( modules => { 'HTML::FormatText::Lynx' => 23 } ) ) {
        $console_logger->text_pre_filter(
            sub {
                my $text         = shift;
                my $content_type = shift;
                my $base_url     = shift;

                return $text
                    unless $content_type && $content_type =~ m{html}i;

                return (
                    trim(
                        HTML::FormatText::Lynx->format_string(
                            $text,
                            base => $base_url,
                        )
                    ),
                    'text/plain'
                );
            }
        );
    }

    return $console_logger;
}

sub add_ua_handlers {
    my $ua             = shift;
    my $console_logger = shift;

    if ( $ua->isa('Test::WWW::Mechanize::Mojo') ) {
        $ua = $ua->tester->ua;
    }
    if ( $ua->isa('Mojo::UserAgent') ) {
        $ua->on(
            'start',
            sub {
                my $the_ua = shift;
                my $tx     = shift;

                my $request = HTTP::Request->parse( $tx->req->to_string );
                $console_logger->request_callback(
                    $request,
                    $the_ua,
                );

                $tx->on(
                    'finish',
                    sub {
                        my $tx = shift;
                        my $res
                            = HTTP::Response->parse( $tx->res->to_string );
                        $res->request($request);
                        $console_logger->response_callback( $res, $the_ua );
                    }
                );
            }
        );
        return;
    }
    if ( $ua->isa('HTTP::Tiny') ) {
        _instrument_http_tiny( $ua, $console_logger );
        return;
    }

    $ua->add_handler(
        'response_done',
        sub { $console_logger->response_callback(@_) }
    );
    $ua->add_handler(
        'request_send',
        sub { $console_logger->request_callback(@_) }
    );
}

sub _instrument_http_tiny {
    my $ua             = shift;
    my $console_logger = shift;

    push @{ $http_tiny_loggers{$ua} ||= [] }, $console_logger;

    return if $http_tiny_wrapped;
    $http_tiny_wrapped = 1;

    Class::Method::Modifiers::install_modifier(
        'HTTP::Tiny', 'around', 'request',
        sub {
            my $orig = shift;
            my $self = shift;
            my ( $method, $url, $args ) = @_;

            my $console_loggers
                = is_ref($self) ? $http_tiny_loggers{$self} : undef;
            return $self->$orig(@_) unless $console_loggers;

            # Logging must never break the caller: any die while translating
            # the request or running the request_callback is caught here so
            # the real HTTP call still happens below.  Seed $request with a
            # minimal object first so that, even if the richer translation
            # below dies, the response can still be logged against a valid
            # request rather than being discarded too.
            my $request = HTTP::Request->new( $method, $url );
            eval {
                $request = _http_tiny_request_object(
                    $self, $method, $url,
                    $args
                );
                $_->request_callback( $request, $self )
                    for @{$console_loggers};
                1;
            } or do {
                warn
                    "LWP::ConsoleLogger: HTTP::Tiny request logging failed: $@";
            };

            # Always perform the real request and always return its response,
            # even if logging blew up above.
            my $response = $self->$orig(@_);

            # Likewise, never let response translation or the response_callback
            # discard an already-completed HTTP response. $request is always a
            # valid object here (seeded above), even if the richer translation
            # died, so the response is still logged against a real request.
            eval {
                my $res = _http_tiny_response_object( $response, $request );
                $_->response_callback( $res, $self ) for @{$console_loggers};
                1;
            } or do {
                warn
                    "LWP::ConsoleLogger: HTTP::Tiny response logging failed: $@";
            };

            return $response;
        }
    );
}

sub _copy_headers {
    my $headers = shift;
    my $hashref = shift;

    return unless $hashref;

    foreach my $name ( keys %{$hashref} ) {
        my $val = $hashref->{$name};
        $headers->push_header(
            $name,
            is_plain_arrayref($val) ? @{$val} : $val
        );
    }
    return;
}

sub _http_tiny_request_object {
    my $self   = shift;
    my $method = shift;
    my $url    = shift;
    my $args   = shift;
    $args ||= {};

    my $headers = HTTP::Headers->new;

    # HTTP::Tiny merges default_headers first, then per-request headers, with
    # the per-request value winning (last-wins) rather than being appended.
    # Merge both sources into one hash so a duplicated name produces a single
    # overriding row, then copy once. Header names are compared
    # case-insensitively (as HTTP::Tiny and HTTP::Headers both treat them) so
    # that e.g. a default "Content-Type" and a per-request "content-type"
    # collapse to one value instead of two appended rows. Arrayref values (a
    # single header carrying multiple values) are preserved.
    my %merged;    # lc name => [ display name => value ]
    foreach my $source ( $self->default_headers, $args->{headers} ) {
        next unless $source;
        $merged{ lc $_ } = [ $_ => $source->{$_} ] for keys %{$source};
    }
    my %clean = map { @{$_} } values %merged;
    _copy_headers( $headers, \%clean );

    # HTTP::Tiny synthesizes a Host header at send time.
    unless ( defined $headers->header('Host') ) {
        my $uri  = URI->new($url);
        my $host = eval { $uri->host };
        $host = "[$host]" if defined $host && $host =~ /:/;
        if ( defined $host ) {
            my %default_port = ( http => 80, https => 443 );
            my $scheme       = lc( $uri->scheme // q{} );
            my $port         = eval { $uri->port };
            if (   defined $port
                && defined $default_port{$scheme}
                && $port != $default_port{$scheme} ) {
                $host .= ":$port";
            }
            $headers->header( Host => $host );
        }
    }

    # HTTP::Tiny synthesizes a User-Agent header from its agent attribute.
    if ( defined $self->agent
        && !defined $headers->header('User-Agent') ) {
        $headers->header( 'User-Agent' => $self->agent );
    }

    my $content = $args->{content};

    # A coderef content is a streaming body we cannot capture.
    $content = undef if is_ref($content);

    my $request = HTTP::Request->new( $method, $url, $headers, $content );

    if ( defined $content ) {

        # HTTP::Tiny computes Content-Length internally, so it is absent from
        # the request options.  Supply it so the body params get logged.  Use
        # a byte length (not a character length) to match what HTTP::Tiny
        # actually sends on the wire.
        if ( !defined $request->header('Content-Length') ) {
            my $length = do { use bytes; length $content };
            $request->header( 'Content-Length' => $length );
        }

        # HTTP::Tiny defaults raw content to application/octet-stream when no
        # Content-Type is supplied; _log_params/_log_text rely on it.
        if ( !defined $request->header('Content-Type') ) {
            $request->header( 'Content-Type' => 'application/octet-stream' );
        }
    }

    elsif ( ( $method eq 'POST' || $method eq 'PUT' )
        && !is_ref( $args->{content} )
        && !defined $request->header('Content-Length') ) {

        # HTTP::Tiny sends an explicit zero length for empty POST and PUT
        # requests so that servers do not wait for a body. A coderef body is
        # excluded: HTTP::Tiny streams it with chunked transfer-encoding
        # rather than a zero Content-Length.
        $request->header( 'Content-Length' => 0 );
    }
    return $request;
}

sub _http_tiny_response_object {
    my $response = shift;
    my $request  = shift;

    my $headers = HTTP::Headers->new;
    _copy_headers( $headers, $response->{headers} );

    my $res = HTTP::Response->new(
        $response->{status}, $response->{reason},
        $headers,            $response->{content},
    );
    $res->protocol( $response->{protocol} ) if $response->{protocol};
    $res->request($request);

    return $res;
}

1;

=pod

=encoding UTF-8

=head1 NAME

LWP::ConsoleLogger::Easy - Easy LWP tracing and debugging

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use WWW::Mechanize;

    my $mech = WWW::Mechanize->new;
    my $logger = debug_ua( $mech );
    $mech->get('https://google.com');

    # now watch the console for debugging output

    # ...
    # stop dumping headers
    $logger->dump_headers( 0 );

    # Redact sensitive data
    $ENV{LWPCL_REDACT_HEADERS} = 'Authorization,Foo,Bar';
    $ENV{LWPCL_REDACT_PARAMS} = 'seekrit,password,credit_card';

    my $quiet_logger = debug_ua( $mech, 1 );

    my $noisy_logger = debug_ua( $mech, 5 );

=head1 DESCRIPTION

This module gives you the easiest possible introduction to
L<LWP::ConsoleLogger>.  It offers one wrapper around L<LWP::ConsoleLogger>:
C<debug_ua>.  This function allows you to get up and running quickly with just
a couple of lines of code. It instantiates user-agent logging and also returns
a L<LWP::ConsoleLogger> object, which you may then tweak to your heart's
desire.

If you're able to install L<HTML::FormatText::Lynx> then you'll get highly
readable HTML to text conversions.

=head1 FUNCTIONS

=head2 debug_ua( $ua, $verbosity )

When called without a verbosity argument, this function turns on all logging.
I'd suggest going with this to start with and then turning down the verbosity
after that.   This method returns an L<LWP::ConsoleLogger> object, which you
may tweak to your heart's desire.

    my $ua_logger = debug_ua( $ua );
    $ua_logger->content_pre_filter( sub {...} );
    $ua_logger->logger( Log::Dispatch->new(...) );

    $ua->get(...);

C<$ua> may be one of several user-agents, including C<LWP::UserAgent>,
C<Mojo::UserAgent>, C<HTTP::Tiny>, and C<WWW::Mechanize>.

When C<$ua> is an L<HTTP::Tiny> object, be aware of a few limitations that
the L<LWP::UserAgent> and L<Mojo::UserAgent> paths do not share: redirect
chains are collapsed so only the final response is logged, C<< $ua->mirror >>
streams the body to a file so the body and text tables are empty, and some
transport-layer headers (for example C<Connection>, or an C<Authorization>
header synthesized from C<userinfo> in the URL) are reconstructed on a
best-effort basis and may not match what goes out on the wire. See
L<LWP::ConsoleLogger::Everywhere/CAVEATS> for the full list.

You can provide a verbosity level of 0 or more.  (Currently 0 - 8 supported.)
This will turn up the verbosity on your output gradually.  A verbosity of 0
will display nothing.  8 will display all available outputs.

    # don't get too verbose
    my $ua_logger = debug_ua( $ua, 4 );

=head2 add_ua_handlers

This method sets up response and request handlers on your user agent.  This is
done for you automatically if you're using C<debug_ua>.

=head1 ENVIRONMENT VARIABLES

=head2 LWPCL_REDACT_HEADERS

A comma-separated list of header values to redact from output.

    $ENV{LWPCL_REDACT_HEADERS} = 'Authorization,Foo,Bar';

Output will be something like:

    .----------------+------------------.
    | Request Header | Value            |
    +----------------+------------------+
    | Authorization  | [REDACTED]       |
    | Content-Length | 0                |
    | User-Agent     | libwww-perl/6.15 |
    '----------------+------------------'

Use at the command line.

    LWPCL_REDACT_HEADERS='Authorization,Foo,Bar' perl script.pl

=head2 LWPCL_REDACT_PARAMS

A comma-separated list of parameter values to redact from output.

    $ENV{LWPCL_REDACT_PARAMS} = 'credit_card,foo,bar';

Use at the command line.

    LWPCL_REDACT_PARAMS='credit_card,foo,bar' perl script.pl

    .-------------+------------.
    | Key         | Value      |
    +-------------+------------+
    | credit_card | [REDACTED] |
    '-------------+------------'

=head2 CAVEATS

Text formatting now defaults to attempting to use L<HTML::FormatText::Lynx> to
format HTML as text.  If you do not have this installed, we'll fall back to
using HTML::Restrict to remove any HTML tags which you have not specifically
whitelisted.

If you have L<HTML::FormatText::Lynx> installed, but you don't want to use it,
override the default filter:

    my $logger = debug_ua( $mech );
    $logger->text_pre_filter( sub { return shift } );

=head2 EXAMPLES

Please see the "examples" folder in this distribution for more ideas on how to
use this module.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: Easy LWP tracing and debugging


# ABSTRACT: Start logging your LWP useragent the easy way.
