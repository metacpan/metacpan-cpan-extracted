use strict;
use warnings;

use 5.006;

package LWP::ConsoleLogger;
our $VERSION = '0.000042';
use Data::Printer { end_separator => 1, hash_separator => ' => ' };
use DateTime qw();
use HTML::Restrict qw();
use HTTP::Body ();
use HTTP::CookieMonster qw();
use JSON::MaybeXS qw( decode_json );
use List::AllUtils qw( any apply none );
use Log::Dispatch qw();
use Moo;
use MooX::StrictConstructor;
use Parse::MIME qw( parse_mime_type );
use Ref::Util qw( is_blessed_ref );
use Term::Size::Any qw( chars );
use Text::SimpleTable::AutoWidth 0.09 qw();
use Try::Tiny qw( catch try );
use Types::Common::Numeric qw( PositiveInt );
use Types::Standard qw( ArrayRef Bool CodeRef InstanceOf );
use URI::Query qw();
use URI::QueryParam qw();
use XML::Simple qw( XMLin );

my $json_regex = qr{vnd.*\+json};

sub BUILD {
    my $self = shift;
    $Text::SimpleTable::AutoWidth::WIDTH_LIMIT = $self->term_width();
}

has content_pre_filter => (
    is  => 'rw',
    isa => CodeRef,
);

has dump_content => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has dump_cookies => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has dump_headers => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has dump_params => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has dump_status => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has dump_text => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has dump_title => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has dump_uri => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has headers_to_redact => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_headers_to_redact',
);

has html_restrict => (
    is      => 'rw',
    isa     => InstanceOf ['HTML::Restrict'],
    lazy    => 1,
    default => sub { HTML::Restrict->new },
);

has logger => (
    is      => 'rw',
    isa     => InstanceOf ['Log::Dispatch'],
    lazy    => 1,
    handles => { _debug => 'debug' },
    default => sub {
        return Log::Dispatch->new(
            outputs => [
                [ 'Screen', min_level => 'debug', newline => 1, utf8 => 1, ],
            ],
        );
    },
);

has params_to_redact => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_params_to_redact',
);

has pretty => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has term_width => (
    is       => 'rw',
    isa      => PositiveInt,
    required => 0,
    lazy     => 1,
    trigger  => \&_term_set,
    builder  => '_build_term_width',
);

has text_pre_filter => (
    is  => 'rw',
    isa => CodeRef,
);

sub _build_headers_to_redact {
    my $self = shift;
    return $ENV{LWPCL_REDACT_HEADERS}
        ? [ split m{,}, $ENV{LWPCL_REDACT_HEADERS} ]
        : [];
}

sub _build_params_to_redact {
    my $self = shift;
    return $ENV{LWPCL_REDACT_PARAMS}
        ? [ split m{,}, $ENV{LWPCL_REDACT_PARAMS} ]
        : [];
}

sub _term_set {
    my $self  = shift;
    my $width = shift;
    $Text::SimpleTable::AutoWidth::WIDTH_LIMIT = $width;
}

sub request_callback {
    my $self = shift;
    my $req  = shift;
    my $ua   = shift;

    if ( $self->dump_uri ) {
        my $uri_without_query = $req->uri->clone;
        $uri_without_query->query(undef);

        $self->_debug( $req->method . q{ } . $uri_without_query . "\n" );
    }

    if ( $req->method eq 'GET' ) {
        $self->_log_params( $req, 'GET' );
    }
    else {
        $self->_log_params( $req, $_ ) for ( 'GET', $req->method );
    }

    $self->_log_headers( 'request (before sending)', $req->headers );

    # This request might have a body.
    return unless $req->content;

    $self->_log_content($req);
    $self->_log_text($req);
    return;
}

sub response_callback {
    my $self = shift;
    my $res  = shift;
    my $ua   = shift;

    $self->_log_headers( 'request (after sending)', $res->request->headers );

    if ( $self->dump_status ) {
        $self->_debug( '==> ' . $res->status_line . "\n" );
    }
    if ( $self->dump_title && $ua->can('title') && $ua->title ) {
        $self->_debug( 'Title: ' . $ua->title . "\n" );
    }

    $self->_log_headers( 'response', $res->headers );
    $self->_log_cookies( 'response', $ua->cookie_jar, $res->request->uri );

    $self->_log_content($res);
    $self->_log_text($res);
    return;
}

sub _log_headers {
    my ( $self, $type, $headers ) = @_;

    return if !$self->dump_headers;

    unless ( $self->pretty ) {
        $self->_debug( $headers->as_string );
        return;
    }

    my $t = Text::SimpleTable::AutoWidth->new();
    $t->captions( [ ucfirst $type . ' Header', 'Value' ] );

    foreach my $name ( sort $headers->header_field_names ) {
        my $val = (
            any { $name eq $_ }
            @{ $self->headers_to_redact }
        ) ? '[REDACTED]' : $headers->header($name);
        $t->row( $name, $val );
    }

    $self->_draw($t);
}

sub _log_params {
    my ( $self, $req, $type ) = @_;

    return if !$self->dump_params;

    my %params;
    my $uri = $req->uri;

    if ( $type eq 'GET' ) {
        my @params = $uri->query_param;
        return unless @params;

        $params{$_} = [ $uri->query_param($_) ] for @params;
    }

    elsif ( $req->header('Content-Length') ) {
        my $content_type = $req->header('Content-Type');
        my $body         = HTTP::Body->new(
            $content_type,
            $req->header('Content-Length')
        );
        $body->add( $req->content );
        %params = %{ $body->param };

        unless ( keys %params ) {
            {
                my $t = Text::SimpleTable::AutoWidth->new;
                $t->captions( [ $type . ' Raw Body' ] );
                $t->row( $req->content );
                $self->_draw($t);
            }

            {
                my $t = Text::SimpleTable::AutoWidth->new;
                $t->captions( [ $type . ' Parsed Body' ] );
                $self->_parse_body( $req->content, $content_type, $t );
                $self->_draw($t);
            }
        }
    }

    my $t = Text::SimpleTable::AutoWidth->new();
    $t->captions( [ 'Key', 'Value' ] );
    foreach my $name ( sort keys %params ) {
        my @values = (
            any { $name eq $_ }
            @{ $self->params_to_redact }
            ) ? '[REDACTED]'
            : ref $params{$name} ? @{ $params{$name} }
            :                      $params{$name};

        $t->row( $name, $_ ) for sort @values;
    }

    $self->_draw( $t, "$type Params:\n" );
}

sub _log_cookies {
    my $self = shift;
    my $type = shift;
    my $jar  = shift;
    my $uri  = shift;

    return if !$self->dump_cookies || !$jar || !is_blessed_ref($jar);

    if ( $jar->isa('HTTP::Cookies') ) {
        my $monster = HTTP::CookieMonster->new($jar);
        my @cookies = $monster->all_cookies;

        my @methods = (
            'key',       'val',    'path', 'domain',
            'path_spec', 'secure', 'expires'
        );

        foreach my $cookie (@cookies) {

            my $t = Text::SimpleTable::AutoWidth->new;
            $t->captions( [ 'Key', 'Value' ] );

            foreach my $method (@methods) {
                my $val = $cookie->$method;
                if ($val) {
                    $val = DateTime->from_epoch( epoch => $val )
                        if $method eq 'expires';
                    $t->row( $method, $val );
                }
            }

            $self->_draw( $t, ucfirst $type . " Cookie:\n" );
        }
    }
    elsif ( $jar->isa('HTTP::CookieJar') ) {
        my @cookies = $jar->cookies_for($uri);
        for my $cookie (@cookies) {

            my $t = Text::SimpleTable::AutoWidth->new;
            $t->captions( [ 'Key', 'Value' ] );

            for my $key ( sort keys %{$cookie} ) {
                my $val = $cookie->{$key};
                if ( $val && $key =~ m{expires|_time} ) {
                    $val = DateTime->from_epoch( epoch => $val );
                }
                $t->row( $key, $val );
            }

            $self->_draw(
                $t,
                sprintf( '%s Cookie (%s)', ucfirst($type), $cookie->{name} )
            );
        }
    }
}

sub _get_content {
    my $self = shift;
    my $r    = shift;

    my $content
        = $r->can('decoded_content') ? $r->decoded_content : $r->content;
    return unless $content;

    my $content_type = $r->header('Content-Type');
    return $content unless $content_type;

    my ( $type, $subtype ) = apply { lc $_ } parse_mime_type($content_type);
    if (
        ( $type ne 'text' )
        && (
            none { $_ eq $subtype }
            ( 'javascript', 'html', 'json', 'xml', 'x-www-form-urlencoded', )
        )
        && $subtype !~ m{$json_regex}
    ) {
        $content = $self->_redaction_message($content_type);
    }
    elsif ( $self->content_pre_filter ) {
        $content = $self->content_pre_filter->( $content, $content_type );
    }

    return $content;
}

sub _log_content {
    my $self = shift;
    my $r    = shift;

    return unless $self->dump_content;

    my $content = $self->_get_content($r);

    return unless $content;

    unless ( $self->pretty ) {
        $self->_debug("Content\n\n$content\n\n");
        return;
    }

    my $t = Text::SimpleTable::AutoWidth->new();
    $t->captions( ['Content'] );

    $t->row($content);
    $self->_draw($t);
}

sub _log_text {
    my $self = shift;
    my $r    = shift;    # HTTP::Request or HTTP::Response

    return unless $self->dump_text;
    my $content = $self->_get_content($r);
    return unless $content;

    my $content_type = $r->header('Content-Type');

    # If a pre_filter converts HTML to text, for example, we don't want to
    # reprocess the text as HTML.

    if ( $self->text_pre_filter && $r->isa('HTTP::Response') ) {
        ( $content, my $type )
            = $self->text_pre_filter->( $content, $content_type, $r->base );
        $content_type = $type if $type;
    }

    return unless $content;

    unless ( $self->pretty ) {
        $self->_debug("Text\n\n$content\n\n");
        return;
    }

    my $t = Text::SimpleTable::AutoWidth->new();
    $t->captions( ['Text'] );

    $self->_parse_body( $content, $content_type, $t );

    $self->_draw($t);
}

sub _parse_body {
    my $self         = shift;
    my $content      = shift;
    my $content_type = shift;
    my $t            = shift;

    # Is this maybe JSON?
    try {
        decode_json($content);

        # If we get this far, it's valid JSON.
        $content_type = 'application/json';
    };

    # nothing to do here
    unless ($content_type) {
        $t->row($content);
        return;
    }

    my ( $type, $subtype ) = apply { lc $_ } parse_mime_type($content_type);
    unless ($subtype) {
        $t->row($content);
        return;
    }

    if ( $subtype eq 'html' ) {
        $content = $self->html_restrict->process($content);
        $content =~ s{\s+}{ }g;
        $content =~ s{\n{2,}}{\n\n}g;

        return if !$content;
    }
    elsif ( $subtype eq 'xml' ) {
        try {
            my $pretty = XMLin( $content, KeepRoot => 1 );
            $content = np( $pretty, return_value => 'dump' );
        }
        catch { $t->row("Error parsing XML: $_") };
    }
    elsif ( $subtype eq 'json' || $subtype =~ m{$json_regex} ) {
        try {
            $content = decode_json($content);
            $content = np( $content, return_value => 'dump' );
        }
        catch { $t->row("Error parsing JSON: $_") };
    }
    elsif ( $type && $type eq 'application' && $subtype eq 'javascript' ) {

        # clean it up a bit, and print some of it
        $content =~ s{^\s*}{}mg;
        if ( length $content > 253 ) {
            $content = substr( $content, 0, 252 ) . '...';
        }
    }
    elsif ($type
        && $type eq 'application'
        && $subtype eq 'x-www-form-urlencoded' ) {

        # Pretend we have query params.
        my $uri = URI->new( '?' . $content );
        $content = np( $uri->query_form_hash );
    }
    elsif ( !$type || $type ne 'text' ) {

        # Avoid things like dumping gzipped content to the screen
        $content = $self->_redaction_message($content_type);
    }

    $content =~ s{^\\ }{};   # don't prefix HashRef with Data::Printer's slash
    $t->row($content);
}

sub _redaction_message {
    my $self         = shift;
    my $content_type = shift;
    return sprintf '[ REDACTED by %s.  Do not know how to display %s. ]',
        __PACKAGE__, $content_type;
}

sub _build_term_width {
    my ($self) = @_;

    # cargo culted from Plack::Middleware::DebugLogging
    my $width = eval '
        my ($columns, $rows) = Term::Size::Any::chars;
        return $columns;
    ';

    if ($@) {
        $width = $ENV{COLUMNS}
            if exists( $ENV{COLUMNS} )
            && $ENV{COLUMNS} =~ m/^\d+$/;
    }

    $width = 80 unless ( $width && $width >= 80 );
    return $width;
}

sub _draw {
    my $self     = shift;
    my $t        = shift;
    my $preamble = shift;

    return if !$t->rows;
    $self->_debug($preamble) if $preamble;
    $self->_debug( $t->draw );
}

1;

=pod

=encoding UTF-8

=head1 NAME

LWP::ConsoleLogger - LWP tracing and debugging

=head1 VERSION

version 0.000042

=head1 SYNOPSIS

The simplest way to get started is by adding L<LWP::ConsoleLogger::Everywhere>
to your code and then just watching your output.

    use LWP::ConsoleLogger::Everywhere ();

If you need more control, look at L<LWP::ConsoleLogger::Easy>.

    use LWP::ConsoleLogger::Easy qw( debug_ua );
    use WWW::Mechanize;

    my $mech           = WWW::Mechanize->new;   # or LWP::UserAgent->new() etc
    my $console_logger = debug_ua( $mech );
    $mech->get( 'https://metacpan.org' );

    # now watch the console for debugging output
    # turn off header dumps
    $console_logger->dump_headers( 0 );

    $mech->get( $some_other_url );

To get down to the lowest level, use LWP::ConsoleLogger directly.

    my $ua = LWP::UserAgent->new( cookie_jar => {} );
    my $console_logger = LWP::ConsoleLogger->new(
        dump_content       => 1,
        dump_text          => 1,
        content_pre_filter => sub {
            my $content      = shift;
            my $content_type = shift;

            # mangle content here
            # ...

            return $content;
        },
    );

    $ua->default_header(
        'Accept-Encoding' => scalar HTTP::Message::decodable() );

    $ua->add_handler( 'response_done',
        sub { $console_logger->response_callback( @_ ) } );
    $ua->add_handler( 'request_send',
        sub { $console_logger->request_callback( @_ ) } );

    # now watch debugging output to your screen
    $ua->get( 'http://nytimes.com/' );

Sample output might look like this.

    GET http://www.nytimes.com/2014/04/24/technology/fcc-new-net-neutrality-rules.html

    GET params:
    .-----+-------.
    | Key | Value |
    +-----+-------+
    | _r  | 1     |
    | hp  |       |
    '-----+-------'

    .-----------------+--------------------------------.
    | Request Header  | Value                          |
    +-----------------+--------------------------------+
    | Accept-Encoding | gzip                           |
    | Cookie2         | $Version="1"                   |
    | Referer         | http://www.nytimes.com?foo=bar |
    | User-Agent      | WWW-Mechanize/1.73             |
    '-----------------+--------------------------------'

    ==> 200 OK

    Title: The New York Times - Breaking News, World News & Multimedia

    .--------------------------+-------------------------------.
    | Response Header          | Value                         |
    +--------------------------+-------------------------------+
    | Accept-Ranges            | bytes                         |
    | Age                      | 176                           |
    | Cache-Control            | no-cache                      |
    | Channels                 | NytNow                        |
    | Client-Date              | Fri, 30 May 2014 22:37:42 GMT |
    | Client-Peer              | 170.149.172.130:80            |
    | Client-Response-Num      | 1                             |
    | Client-Transfer-Encoding | chunked                       |
    | Connection               | keep-alive                    |
    | Content-Encoding         | gzip                          |
    | Content-Type             | text/html; charset=utf-8      |
    | Date                     | Fri, 30 May 2014 22:37:41 GMT |
    | NtCoent-Length           | 65951                         |
    | Server                   | Apache                        |
    | Via                      | 1.1 varnish                   |
    | X-Cache                  | HIT                           |
    | X-Varnish                | 1142859770 1142854917         |
    '--------------------------+-------------------------------'

    .--------------------------+-------------------------------.
    | Text                                                     |
    +--------------------------+-------------------------------+
    | F.C.C., in a Shift, Backs Fast Lanes for Web Traffic...  |
    '--------------------------+-------------------------------'

=head1 DESCRIPTION

BETA BETA BETA.  This is currently an experiment.  Things could change.  Please
adjust accordingly.

It can be hard (or at least tedious) to debug mechanize scripts.  LWP::Debug is
deprecated.  It suggests you write your own debugging handlers, set up a proxy
or install Wireshark.  Those are all workable solutions, but this module exists
to save you some of that work.  The guts of this module are stolen from
L<Plack::Middleware::DebugLogging>, which in turn stole most of its internals
from L<Catalyst>.  If you're new to LWP::ConsoleLogger, I suggest getting
started with the L<LWP::ConsoleLogger::Easy> wrapper.  This will get you up and
running in minutes.  If you need to tweak the settings that
L<LWP::ConsoleLogger::Easy> chooses for you (or if you just want to be fancy),
please read on.

Since this is a debugging library, I've left as much mutable state as possible,
so that you can easily toggle output on and off and otherwise adjust how you
deal with the output.

=head1 CONSTRUCTOR

=head2 new()

The following arguments can be passed to new(), although none are required.
They can also be called as methods on an instantiated object.  I'll list them
here and discuss them in detail below.

=over 4

=item * C<< dump_content => 0|1 >>

=item * C<< dump_cookies => 0|1 >>

=item * C<< dump_headers => 0|1 >>

=item * C<< dump_params => 0|1 >>

=item * C<< dump_status => 0|1 >>

=item * C<< dump_text => 0|1 >>

=item * C<< dump_title => 0|1 >>

=item * C<< dump_text => 0|1 >>

=item * C<< dump_uri => 0|1 >>

=item * C<< content_pre_filter => sub { ... } >>

=item * C<< headers_to_redact => ['Authentication', 'Foo'] >>

=item * C<< params_to_redact => ['token', 'password'] >>

=item * C<< text_pre_filter => sub { ... } >>

=item * C<< html_restrict => HTML::Restrict->new( ... ) >>

=item * C<< logger => Log::Dispatch->new( ... ) >>

=item * C<< pretty => 0|1 >>

=item * C<< term_width => $integer >>

=back

=head1 SUBROUTINES/METHODS

=head2 dump_content( 0|1 )

Boolean value. If true, the actual content of your response (HTML, JSON, etc)
will be dumped to your screen.  Defaults to false.

=head2 dump_cookies( 0|1 )

Boolean value. If true, the content of your cookies will be dumped to your
screen.  Defaults to false.

=head2 dump_headers( 0|1 )

Boolean value. If true, both request and response headers will be dumped to
your screen.  Defaults to true.

Headers are dumped in alphabetical order.

=head2 dump_params( 0|1 )

Boolean value. If true, both GET and POST params will be dumped to your screen.
Defaults to true.

Params are dumped in alphabetical order.

=head2 dump_status( 0|1 )

Boolean value. If true, dumps the HTTP response code for each page being
visited.  Defaults to true.

=head2 dump_text( 0|1 )

Boolean value. If true, dumps the text of your page after both the
content_pre_filter and text_pre_filters have been applied.  Defaults to true.

=head2 dump_title( 0|1 )

Boolean value. If true, dumps the titles of HTML pages if your UserAgent has
a C<title> method and if it returns something useful. Defaults to true.

=head2 dump_uri( 0|1 )

Boolean value. If true, dumps the URI of each page being visited. Defaults to
true.

=head2 pretty ( 0|1 )

Boolean value. If disabled, request headers, response headers, content and text
sections will be dumped without using tables. Handy for copy/pasting JSON etc
for faking responses later. Defaults to true.

=head2 content_pre_filter( sub { ... } )

Subroutine reference.  This allows you to manipulate content before it is
dumped.  A common use case might be stripping headers and footers away from
HTML content to make it easier to detect changes in the body of the page.

    $easy_logger->content_pre_filter(
    sub {
        my $content      = shift;
        my $content_type = shift; # the value of the Content-Type header
        if (   $content_type =~ m{html}i
            && $content =~ m{<!--\scontent\s-->(.*)<!--\sfooter}msx ) {
            return $1;
        }
        return $content;
    }
    );

Try to make sure that your content mangling doesn't return broken HTML as that
may not play well with L<HTML::Restrict>.

=head2 request_callback

Use this handler to set up console logging on your requests.

    my $ua = LWP::UserAgent->new;
    $ua->add_handler(
        'request_send',
        sub { $console_logger->request_callback(@_) }
    );

This is done for you by default if you set up your logging via
L<LWP::ConsoleLogger::Easy>.

=head2 response_callback

Use this handler to set up console logging on your responses.

    my $ua = LWP::UserAgent->new;
    $ua->add_handler(
        'response_done',
        sub { $console_logger->response_callback(@_) }
    );

This is done for you by default if you set up your logging via
L<LWP::ConsoleLogger::Easy>.

=head2 text_pre_filter( sub { ... } )

Subroutine reference.  This allows you to manipulate text before it is dumped.
A common use case might be stripping away duplicate whitespace and/or newlines
in order to improve formatting.  Keep in mind that the C<content_pre_filter>
will have been applied to the content which is passed to the text_pre_filter.
The idea is that you can strip away an HTML you don't care about in the
content_pre_filter phase and then process the remainder of the content in the
text_pre_filter.

    $easy_logger->text_pre_filter(
    sub {
        my $content      = shift;
        my $content_type = shift; # the value of the Content-Type header
        my $base_url     = shift;

        # do something with the content
        # ...

        return ( $content, $new_content_type );
    }
    );

If your C<text_pre_filter()> converts from HTML to plain text, be sure to
return the new content type (text/plain) when you exit the sub.  If you do not
do this, HTML formatting will then be applied to your plain text as is
explained below.

If this is HTML content, L<HTML::Restrict> will be applied after the
text_pre_filter has been run.  LWP::ConsoleLogger will then strip away some
whitespace and newlines from processed HTML in its own opinionated way, in
order to present you with more readable text.

=head2 html_restrict( HTML::Restrict->new( ... ) )

If the content_type indicates HTML then HTML::Restrict will be used to strip
tags from your content in the text rendering process.  You may pass your own
HTML::Restrict object, if you like.  This would be helpful in situations where
you still do want to have some tags in your text.

=head2 logger( Log::Dispatch->new( ... ) )

By default all data will be dumped to your console (as the name of this module
implies) using Log::Dispatch.  However, you may use your own Log::Dispatch
module in order to facilitate logging to files or any other output which
Log::Dispatch supports.

=head2 term_width( $integer )

By default this module will try to find the maximum width of your terminal and
use all available space when displaying tabular data.  You may use this
parameter to constrain the tables to an arbitrary width.

=head1 CAVEATS

Aside from the BETA warnings, I should say that I've written this to suit my
needs and there are a lot of things I haven't considered.  For example, I'm
mostly assuming that the content will be text, HTML, JSON or XML.

The test suite is not very robust either.  If you'd like to contribute to this
module and you can't find an appropriate test, do add something to the example
folder (either a new script or alter an existing one), so that I can see what
your patch does.

=for Pod::Coverage BUILD

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2019 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: LWP tracing and debugging

