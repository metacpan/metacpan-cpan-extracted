package LWP::ConsoleLogger::Easy;
our $VERSION = '0.000042';
use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;
use LWP::ConsoleLogger;
use Module::Load::Conditional qw( can_load );
use Sub::Exporter -setup => { exports => ['debug_ua'] };
use String::Trim;

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
    my $level = shift || 10;

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

    $ua->add_handler(
        'response_done',
        sub { $console_logger->response_callback(@_) }
    );
    $ua->add_handler(
        'request_send',
        sub { $console_logger->request_callback(@_) }
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

LWP::ConsoleLogger::Easy - Easy LWP tracing and debugging

=head1 VERSION

version 0.000042

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

=head2 debug_ua( $mech, $verbosity )

When called without a verbosity argument, this function turns on all logging.
I'd suggest going with this to start with and then turning down the verbosity
after that.   This method returns an L<LWP::ConsoleLogger> object, which you
may tweak to your heart's desire.

    my $ua_logger = debug_ua( $ua );
    $ua_logger->content_pre_filter( sub {...} );
    $ua_logger->logger( Log::Dispatch->new(...) );

    $ua->get(...);

C<$ua> may be one of several user-agents, including C<LWP::UserAgent>,
C<Mojo::UserAgent>, and C<WWW::Mechanize>.

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

This software is Copyright (c) 2014-2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: Easy LWP tracing and debugging


# ABSTRACT: Start logging your LWP useragent the easy way.
