[![Linux Build Status](https://travis-ci.org/nigelhorne/FCGI-Buffer.svg?branch=master)](https://travis-ci.org/nigelhorne/FCGI-Buffer)
[![Windows build status](https://ci.appveyor.com/api/projects/status/vd5loxl1k3dq7ad3?svg=true)](https://ci.appveyor.com/project/nigelhorne/fcgi-buffer)
[![Dependency Status](https://dependencyci.com/github/nigelhorne/FCGI-Buffer/badge)](https://dependencyci.com/github/nigelhorne/FCGI-Buffer)
[![Coverage Status](https://coveralls.io/repos/github/nigelhorne/FCGI-Buffer/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/FCGI-Buffer?branch=master)

# FCGI::Buffer

Verify, Cache and Optimise FCGI Output

# VERSION

Version 0.11

# SYNOPSIS

FCGI::Buffer verifies the HTML that you produce by passing it through
`HTML::Lint`.

FCGI::Buffer optimises FCGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data:

    use FCGI;
    use FCGI::Buffer;
    # ...
    my $request = FCGI::Request();
    while($request->FCGI::Accept() >= 0) {
        my $buffer = FCGI::Buffer->new();
        $buffer->init(
                optimise_content => 1,
                lint_content => 0,
        );
        # ...
    }

To also make use of server caches, that is to say to save regenerating
output when different clients ask you for the same data, you will need
to create a cache.
But that's simple:

    use FCGI;
    use CHI;
    use FCGI::Buffer;

    # ...
    my $request = FCGI::Request();
    while($request->FCGI::Accept() >= 0) {
        my $buffer = FCGI::Buffer->new();
        $buffer->init(
            optimise_content => 1,
            lint_content => 0,
            cache => CHI->new(driver => 'File')
        );
        if($buffer->is_cached()) {
            # Nothing has changed - use the version in the cache
            $request->Finish();
            next;
        # ...
    }

To temporarily prevent the use of server-side caches, for example whilst
debugging before publishing a code change, set the NO\_CACHE environment variable
to any non-zero value.
If you get errors about Wide characters in print it means that you've
forgotten to emit pure HTML on non-ascii characters.
See [HTML::Entities](https://metacpan.org/pod/HTML::Entities).
As a hack work around you could also remove accents and the like by using
[Text::Unidecode](https://metacpan.org/pod/Text::Unidecode),
which works well but isn't really what you want.

# SUBROUTINES/METHODS

## new

Create an FCGI::Buffer object.  Do one of these for each FCGI::Accept.

## init

Set various options and override default values.

    # Put this toward the top of your program before you do anything
    # By default, generate_tag, generate_304 and compress_content are ON,
    # optimise_content and lint_content are OFF.  Set optimise_content to 2 to
    # do aggressive JavaScript optimisations which may fail.
    use FCGI::Buffer;

    my $buffer = FCGI::Buffer->new()->init({
        generate_etag => 1,     # make good use of client's cache
        generate_last_modified => 1,    # more use of client's cache
        compress_content => 1,  # if gzip the output
        optimise_content => 0,  # optimise your program's HTML, CSS and JavaScript
        cache => CHI->new(driver => 'File'),    # cache requests
        cache_key => 'string',  # key for the cache
        cache_age => '10 minutes',      # how long to store responses in the cache
        logger => $self->{logger},
        lint_content => 0,      # Pass through HTML::Lint
        generate_304 => 1,      # When appropriate, generate 304: Not modified
        save_to => { directory => '/var/www/htdocs/save_to', ttl => 600, create_table => 1 },
        info => CGI::Info->new(),
        lingua => CGI::Lingua->new(),
    });

If no cache\_key is given, one will be generated which may not be unique.
The cache\_key should be a unique value dependent upon the values set by the
browser.

The cache object will be an object that understands get\_object(),
set(), remove() and created\_at() messages, such as an [CHI](https://metacpan.org/pod/CHI) object. It is
used as a server-side cache to reduce the need to rerun database accesses.

Items stay in the server-side cache by default for 10 minutes.
This can be overridden by the cache\_control HTTP header in the request, and
the default can be changed by the cache\_age argument to init().

Save\_to is feature which stores output of dynamic pages to your
htdocs tree and replaces future links that point to that page with static links
to avoid going through CGI at all.
Ttl is set to the number of seconds that the static pages are deemed to
be live for, the default is 10 minutes.
If set to 0, the page is live forever.
To enable save\_to, a info and lingua arguments must also be given.
It works best when cache is also given.
Only use where output is guaranteed to be the same with a given set of arguments
(the same criteria for enabling generate\_304).
You can turn it off on a case by case basis thus:

    my $params = CGI::Info->new()->params();
    if($params->{'send_private_email'}) {
        $buffer->init('save_to' => undef);
    }

Info is an optional argument to give information about the FCGI environment, e.g.
a [CGI::Info](https://metacpan.org/pod/CGI::Info) object.

Logger will be an object that understands debug() such as an [Log::Log4perl](https://metacpan.org/pod/Log::Log4perl)
object.

To generate a last\_modified header, you must give a cache object.

Init allows a reference of the options to be passed. So both of these work:
    use FCGI::Buffer;
    #...
    my $buffer = FCGI::Buffer->new();
    $b->init(generate\_etag => 1);
    $b->init({ generate\_etag => 1, info => CGI::Info->new() });

Generally speaking, passing by reference is better since it copies less on to
the stack.

If you give a cache to init() then later give cache => undef,
the server side cache is no longer used.
This is useful when you find an error condition when creating your HTML
and decide that you no longer wish to store the output in the cache.

## set\_options

Synonym for init, kept for historical reasons.

## can\_cache

Returns true if the server is allowed to store the results locally.

## is\_cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the FCGI script can be by-passed because we already have
the result stored in the cache.

    # Put this toward the top of your program before you do anything

    # Example key generation - use whatever you want as something
    # unique for this call, so that subsequent calls with the same
    # values match something in the cache
    use CGI::Info;
    use CGI::Lingua;
    use FCGI::Buffer;

    my $i = CGI::Info->new();
    my $l = CGI::Lingua->new(supported => ['en']);

    # To use server side caching you must give the cache argument, however
    # the cache_key argument is optional - if you don't give one then one will
    # be generated for you
    my $buffer = FCGI::Buffer->new();
    if($buffer->can_cache()) {
        $buffer->init(
            cache => CHI->new(driver => 'File'),
            cache_key => $i->domain_name() . '/' . $i->script_name() . '/' . $i->as_string() . '/' . $l->language()
        );
        if($buffer->is_cached()) {
            # Output will be retrieved from the cache and sent automatically
            exit;
        }
    }
    # Not in the cache, so now do our expensive computing to generate the
    # results
    print "Content-type: text/html\n";
    # ...

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

FCGI::Buffer should be safe even in scripts which produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge to setting generate\_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using [Template](https://metacpan.org/pod/Template), ensure that you don't use it to output to STDOUT,
instead you will need to capture into a variable and print that.
For example:

    my $output;
    $template->process($input, $vars, \$output) || ($output = $template->error());
    print $output;

Can produce buggy JavaScript if you use the &lt;!-- HIDING technique.
This is a bug in [JavaScript::Packer](https://metacpan.org/pod/JavaScript::Packer), not FCGI::Buffer.
See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790

Mod\_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary

If you request compressed output then uncompressed output (or vice
versa) on input that produces the same output, the status will be 304.
The letter of the spec says that's wrong, so I'm noting it here, but
in practice you should not see this happen or have any difficulties
because of it.

FCGI::Buffer has not been tested against FastCGI.

I advise adding FCGI::Buffer as the last use statement so that it is
cleared up first.  In particular it should be loaded after
[Log::Log4Perl](https://metacpan.org/pod/Log::Log4Perl), if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
FCGI::Buffer;

Save\_to doesn't understand links in JavaScript, which means that if you use self-calling
CGIs which are loaded as a static page they may point to the wrong place.
The workaround is to avoid self-calling CGIs in JavaScript

Please report any bugs or feature requests to `bug-fcgi-buffer at rt.cpan.org`,
or through the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer).
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

# SEE ALSO

CGI::Buffer, HTML::Packer, HTML::Lint

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FCGI::Buffer

You can also look for information at:

- RT: CPAN's request tracker

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer](http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/FCGI-Buffer](http://annocpan.org/dist/FCGI-Buffer)

- CPAN Ratings

    [http://cpanratings.perl.org/d/FCGI-Buffer](http://cpanratings.perl.org/d/FCGI-Buffer)

- Search CPAN

    [http://search.cpan.org/dist/FCGI-Buffer/](http://search.cpan.org/dist/FCGI-Buffer/)

# ACKNOWLEDGEMENTS

The inspiration and code for some of this is cgi\_buffer by Mark
Nottingham: http://www.mnot.net/cgi\_buffer.

# LICENSE AND COPYRIGHT

The licence for cgi\_buffer is:

    "(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

    This software may be freely distributed, modified and used,
    provided that this copyright notice remain intact.

    This software is provided 'as is' without warranty of any kind."

The rest of the program is Copyright 2015-2017 Nigel Horne,
and is released under the following licence: GPL
