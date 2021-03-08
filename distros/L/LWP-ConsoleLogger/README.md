# NAME

LWP::ConsoleLogger - LWP tracing and debugging

# VERSION

version 0.000043

# SYNOPSIS

The simplest way to get started is by adding [LWP::ConsoleLogger::Everywhere](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEverywhere)
to your code and then just watching your output.

    use LWP::ConsoleLogger::Everywhere ();

If you need more control, look at [LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEasy).

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

# DESCRIPTION

BETA BETA BETA.  This is currently an experiment.  Things could change.  Please
adjust accordingly.

It can be hard (or at least tedious) to debug mechanize scripts.  LWP::Debug is
deprecated.  It suggests you write your own debugging handlers, set up a proxy
or install Wireshark.  Those are all workable solutions, but this module exists
to save you some of that work.  The guts of this module are stolen from
[Plack::Middleware::DebugLogging](https://metacpan.org/pod/Plack%3A%3AMiddleware%3A%3ADebugLogging), which in turn stole most of its internals
from [Catalyst](https://metacpan.org/pod/Catalyst).  If you're new to LWP::ConsoleLogger, I suggest getting
started with the [LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEasy) wrapper.  This will get you up and
running in minutes.  If you need to tweak the settings that
[LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEasy) chooses for you (or if you just want to be fancy),
please read on.

Since this is a debugging library, I've left as much mutable state as possible,
so that you can easily toggle output on and off and otherwise adjust how you
deal with the output.

# CONSTRUCTOR

## new()

The following arguments can be passed to new(), although none are required.
They can also be called as methods on an instantiated object.  I'll list them
here and discuss them in detail below.

- `dump_content => 0|1`
- `dump_cookies => 0|1`
- `dump_headers => 0|1`
- `dump_params => 0|1`
- `dump_status => 0|1`
- `dump_text => 0|1`
- `dump_title => 0|1`
- `dump_text => 0|1`
- `dump_uri => 0|1`
- `content_pre_filter => sub { ... }`
- `headers_to_redact => ['Authentication', 'Foo']`
- `params_to_redact => ['token', 'password']`
- `text_pre_filter => sub { ... }`
- `html_restrict => HTML::Restrict->new( ... )`
- `logger => Log::Dispatch->new( ... )`
- `pretty => 0|1`
- `term_width => $integer`

# SUBROUTINES/METHODS

## dump\_content( 0|1 )

Boolean value. If true, the actual content of your response (HTML, JSON, etc)
will be dumped to your screen.  Defaults to false.

## dump\_cookies( 0|1 )

Boolean value. If true, the content of your cookies will be dumped to your
screen.  Defaults to false.

## dump\_headers( 0|1 )

Boolean value. If true, both request and response headers will be dumped to
your screen.  Defaults to true.

Headers are dumped in alphabetical order.

## dump\_params( 0|1 )

Boolean value. If true, both GET and POST params will be dumped to your screen.
Defaults to true.

Params are dumped in alphabetical order.

## dump\_status( 0|1 )

Boolean value. If true, dumps the HTTP response code for each page being
visited.  Defaults to true.

## dump\_text( 0|1 )

Boolean value. If true, dumps the text of your page after both the
content\_pre\_filter and text\_pre\_filters have been applied.  Defaults to true.

## dump\_title( 0|1 )

Boolean value. If true, dumps the titles of HTML pages if your UserAgent has
a `title` method and if it returns something useful. Defaults to true.

## dump\_uri( 0|1 )

Boolean value. If true, dumps the URI of each page being visited. Defaults to
true.

## pretty ( 0|1 )

Boolean value. If disabled, request headers, response headers, content and text
sections will be dumped without using tables. Handy for copy/pasting JSON etc
for faking responses later. Defaults to true.

## content\_pre\_filter( sub { ... } )

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
may not play well with [HTML::Restrict](https://metacpan.org/pod/HTML%3A%3ARestrict).

## request\_callback

Use this handler to set up console logging on your requests.

    my $ua = LWP::UserAgent->new;
    $ua->add_handler(
        'request_send',
        sub { $console_logger->request_callback(@_) }
    );

This is done for you by default if you set up your logging via
[LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEasy).

## response\_callback

Use this handler to set up console logging on your responses.

    my $ua = LWP::UserAgent->new;
    $ua->add_handler(
        'response_done',
        sub { $console_logger->response_callback(@_) }
    );

This is done for you by default if you set up your logging via
[LWP::ConsoleLogger::Easy](https://metacpan.org/pod/LWP%3A%3AConsoleLogger%3A%3AEasy).

## text\_pre\_filter( sub { ... } )

Subroutine reference.  This allows you to manipulate text before it is dumped.
A common use case might be stripping away duplicate whitespace and/or newlines
in order to improve formatting.  Keep in mind that the `content_pre_filter`
will have been applied to the content which is passed to the text\_pre\_filter.
The idea is that you can strip away an HTML you don't care about in the
content\_pre\_filter phase and then process the remainder of the content in the
text\_pre\_filter.

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

If your `text_pre_filter()` converts from HTML to plain text, be sure to
return the new content type (text/plain) when you exit the sub.  If you do not
do this, HTML formatting will then be applied to your plain text as is
explained below.

If this is HTML content, [HTML::Restrict](https://metacpan.org/pod/HTML%3A%3ARestrict) will be applied after the
text\_pre\_filter has been run.  LWP::ConsoleLogger will then strip away some
whitespace and newlines from processed HTML in its own opinionated way, in
order to present you with more readable text.

## html\_restrict( HTML::Restrict->new( ... ) )

If the content\_type indicates HTML then HTML::Restrict will be used to strip
tags from your content in the text rendering process.  You may pass your own
HTML::Restrict object, if you like.  This would be helpful in situations where
you still do want to have some tags in your text.

## logger( Log::Dispatch->new( ... ) )

By default all data will be dumped to your console (as the name of this module
implies) using Log::Dispatch.  However, you may use your own Log::Dispatch
module in order to facilitate logging to files or any other output which
Log::Dispatch supports.

## term\_width( $integer )

By default this module will try to find the maximum width of your terminal and
use all available space when displaying tabular data.  You may use this
parameter to constrain the tables to an arbitrary width.

# CAVEATS

Aside from the BETA warnings, I should say that I've written this to suit my
needs and there are a lot of things I haven't considered.  For example, I'm
mostly assuming that the content will be text, HTML, JSON or XML.

The test suite is not very robust either.  If you'd like to contribute to this
module and you can't find an appropriate test, do add something to the example
folder (either a new script or alter an existing one), so that I can see what
your patch does.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2019 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
