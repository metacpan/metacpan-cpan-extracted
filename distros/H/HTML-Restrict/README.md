# NAME

HTML::Restrict - Strip unwanted HTML tags and attributes

# VERSION

version v2.4.1

# SYNOPSIS

    use HTML::Restrict;

    my $hr = HTML::Restrict->new();

    # use default rules to start with (strip away all HTML)
    my $processed = $hr->process('  <b>i am bold</b>  ');

    # $processed now equals: 'i am bold'

    # Now, a less restrictive example:
    $hr = HTML::Restrict->new(
        rules => {
            b   => [],
            img => [qw( src alt / )]
        }
    );

    my $html = q[<body><b>hello</b> <img src="pic.jpg" alt="me" id="test" /></body>];
    $processed = $hr->process( $html );

    # $processed now equals: <b>hello</b> <img src="pic.jpg" alt="me" />

# DESCRIPTION

This module uses [HTML::Parser](https://metacpan.org/pod/HTML::Parser) to strip HTML from text in a restrictive
manner.  By default all HTML is restricted.  You may alter the default
behaviour by supplying your own tag rules.

# CONSTRUCTOR AND STARTUP

## new()

Creates and returns a new HTML::Restrict object.

    my $hr = HTML::Restrict->new()

HTML::Restrict doesn't require any params to be passed to new.  If your goal is
to remove all HTML from text, then no further setup is required.  Just pass
your text to the process() method and you're done:

    my $plain_text = $hr->process( $html );

If you need to set up specific rules, have a look at the params which
HTML::Restrict recognizes:

- `rules => \%rules`

    Sets the rules which will be used to process your data.  By default all HTML
    tags are off limits.  Use this argument to define the HTML elements and
    corresponding attributes you'd like to use.  Essentially, consider the default
    behaviour to be:

        rules => {}

    Rules should be passed as a HASHREF of allowed tags.  Each hash value should
    represent the allowed attributes for the listed tag.  For example, if you want
    to allow a fair amount of HTML, you can try something like this:

        my %rules = (
            a       => [qw( href target )],
            b       => [],
            caption => [],
            center  => [],
            em      => [],
            i       => [],
            img     => [qw( alt border height width src style )],
            li      => [],
            ol      => [],
            p       => [qw(style)],
            span    => [qw(style)],
            strong  => [],
            sub     => [],
            sup     => [],
            table   => [qw( style border cellspacing cellpadding align )],
            tbody   => [],
            td      => [],
            tr      => [],
            u       => [],
            ul      => [],
        );

        my $hr = HTML::Restrict->new( rules => \%rules )

    Or, to allow only bolded text:

        my $hr = HTML::Restrict->new( rules => { b => [] } );

    Allow bolded text, images and some (but not all) image attributes:

        my %rules = (
            b   => [ ],
            img => [qw( src alt width height border / )
        );
        my $hr = HTML::Restrict->new( rules => \%rules );

    Since [HTML::Parser](https://metacpan.org/pod/HTML::Parser) treats a closing slash as an attribute, you'll need to
    add "/" to your list of allowed attributes if you'd like your tags to retain
    closing slashes.  For example:

        my $hr = HTML::Restrict->new( rules =>{ hr => [] } );
        $hr->process( "<hr />"); # returns: <hr>

        my $hr = HTML::Restrict->new( rules =>{ hr => [qw( / )] } );
        $hr->process( "<hr />"); # returns: <hr />

    HTML::Restrict strips away any tags and attributes which are not explicitly
    allowed. It also rebuilds your explicitly allowed tags and places their
    attributes in the order in which they appear in your rules.

    So, if you define the following rules:

        my %rules = (
            ...
            img => [qw( src alt title width height id / )]
            ...
        );

    then your image tags will all be built like this:

        <img src=".." alt="..." title="..." width="..." height="..." id=".." />

    This gives you greater consistency in your tag layout.  If you don't care about
    element order you don't need to pay any attention to this, but you should be
    aware that your elements are being reconstructed rather than just stripped
    down.

    As of 2.1.0, you can also specify a regex to be tested against the attribute
    value. This feature should be considered experimental for the time being:

        my $hr = HTML::Restrict->new(
            rules => {
                iframe => [
                    qw( width height allowfullscreen ),
                    {   src         => qr{^http://www\.youtube\.com},
                        frameborder => qr{^(0|1)$},
                    }
                ],
                img => [ qw( alt ), { src => qr{^/my/images/} }, ],
            },
        );

        my $html = '<img src="http://www.example.com/image.jpg" alt="Alt Text">';
        my $processed = $hr->process( $html );

        # $processed now equals: <img alt="Alt Text">

    As of 2.3.0, the value to be tested against can also be a code reference.  The
    code reference will be passed the value of the attribute, and should return
    either a string to use for the attribute value, or undef to remove the attribute.

        my $hr = HTML::Restrict->new(
            rules => {
                span => [
                    { style     => sub {
                        my $value = shift;
                        # all colors are orange
                        $value =~ s/\bcolor\s*:\s*[^;]+/color: orange/g;
                        return $value;
                    } }
                ],
            },
        );

        my $html = '<span style="color: #0000ff;">This is blue</span>';
        my $processed = $hr->process( $html );

        # $processed now equals: <span style="color: orange;">

- `trim => [0|1]`

    By default all leading and trailing spaces will be removed when text is
    processed.  Set this value to 0 in order to disable this behaviour.

- `uri_schemes => [undef, 'http', 'https', 'irc', ... ]`

    As of version 1.0.3, URI scheme checking is performed on all href and src tag
    attributes. The following schemes are allowed out of the box.  No action is
    required on your part:

        [ undef, 'http', 'https' ]

    (undef represents relative URIs). These restrictions have been put in place to
    prevent XSS in the form of:

        <a href="javascript:alert(document.cookie)">click for cookie!</a>

    See [URI](https://metacpan.org/pod/URI) for more detailed info on scheme parsing.  If, for example, you
    wanted to filter out every scheme barring SSL, you would do it like this:

        uri_schemes => ['https']

    This feature is new in 1.0.3.  Previous to this, there was no schema checking
    at all.  Moving forward, you'll need to whitelist explicitly all URI schemas
    which are not supported by default.  This is in keeping with the whitelisting
    behaviour of this module and is also the safest possible approach.  Keep in
    mind that changes to uri\_schemes are not additive, so you'll need to include
    the defaults in any changes you make, should you wish to keep them:

        # defaults + irc + mailto
        uri_schemes => [ 'undef', 'http', 'https', 'irc', 'mailto' ]

- allow\_declaration => \[0|1\]

    Set this value to true if you'd like to allow/preserve DOCTYPE declarations in
    your content.  Useful when cleaning up your own static files or templates. This
    feature is off by default.

        my $html = q[<!doctype html><body>foo</body>];

        my $hr = HTML::Restrict->new( allow_declaration => 1 );
        $html = $hr->process( $html );
        # $html is now: "<!doctype html>foo"

- allow\_comments => \[0|1\]

    Set this value to true if you'd like to allow/preserve HTML comments in your
    content.  Useful when cleaning up your own static files or templates. This
    feature is off by default.

        my $html = q[<body><!-- comments! -->foo</body>];

        my $hr = HTML::Restrict->new( allow_comments => 1 );
        $html = $hr->process( $html );
        # $html is now: "<!-- comments! -->foo"

- max\_parser\_loops => \[Integer\]

    Defaults to 25.  Should never be less than 2.

    As of v2.4.0, calling `process()` will force the parser to clean the text
    multiple times, stopping only once the text is no longer changed or once
    `max_parser_loops` has been reached.

    The reason for this is that [HTML::Parser](https://metacpan.org/pod/HTML::Parser) could take malformed HTML and turn
    it into well formed HTML.  This can defeat our processing logic and allow
    malicious input to be returned.  In order to mitigate this, we will clean all
    input at least two times.  If the second attempt at cleaning does not match
    the previous attempt, we will make a third attempt and so on.  This helps to
    ensure that we get the expected output.

    If we are unable to get unchanged values after reaching `max_parser_loops`, an
    exception will be thrown.  Returning partially cleaned text would be wrong, as
    would be returning `undef` or an empty string.  Throwing an exception forces
    the user to choose the appropriate way of dealing with this.

    If you choose to set this value, please note that it can be no less than 2, or
    the parser will never be able to make a comparison with a previous value.  An
    exception will be thrown if you attempt to set this to a value less than 2.

- replace\_img => \[0|1|CodeRef\]

    Set the value to true if you'd like to have img tags replaced with
    `[IMAGE: ...]` containing the alt attribute text.  If you set it to a
    code reference, you can provide your own replacement (which may
    even contain HTML).

        sub replacer {
            my ($tagname, $attr, $text) = @_; # from HTML::Parser
            return qq{<a href="$attr->{src}">IMAGE: $attr->{alt}</a>};
        }

        my $hr = HTML::Restrict->new( replace_img => \&replacer );

    This attribute will only take effect if the img tag is not included
    in the allowed HTML.

- strip\_enclosed\_content => \[0|1\]

    The default behaviour up to 1.0.4 was to preserve the content between script
    and style tags, even when the tags themselves were being deleted.  So, you'd be
    left with a bunch of JavaScript or CSS, just with the enclosing tags missing.
    This is almost never what you want, so starting at 1.0.5 the default will be to
    remove any script or style info which is enclosed in these tags, unless they
    have specifically been whitelisted in the rules.  This will be a sane default
    when cleaning up content submitted via a web form.  However, if you're using
    HTML::Restrict to purge your own HTML you can be more restrictive.

        # strip the head section, in addition to JS and CSS
        my $html = '<html><head>...</head><body>...<script>JS here</script>foo';

        my $hr = HTML::Restrict->new(
            strip_enclosed_content => [ 'script', 'style', 'head' ]
        );

        $html = $hr->process( $html );
        # $html is now '<html><body>...foo';

    The caveat here is that HTML::Restrict will not try to fix broken HTML. In the
    above example, if you have any opening script, style or head tags which don't
    also include matching closing tags, all following content will be stripped
    away, regardless of any parent tags.

    Keep in mind that changes to strip\_enclosed\_content are not additive, so if you
    are adding additional tags you'll need to include the entire list of tags whose
    enclosed content you'd like to remove.  This feature strips script and style
    tags by default.

# SUBROUTINES/METHODS

## process( $html )

This is the method which does the real work.  It parses your data, removes any
tags and attributes which are not specifically allowed and returns the
resulting text.  Requires and returns a SCALAR.

## get\_rules

Accessor which returns a hash ref of the current rule set.

## get\_uri\_schemes

Accessor which returns an array ref of the current valid uri schemes.

# CAVEATS

Please note that all tag and attribute names passed via the rules param must be
supplied in lower case.

    # correct
    my $hr = HTML::Restrict->new( rules => { body => ['onload'] } );

    # throws a fatal error
    my $hr = HTML::Restrict->new( rules => { Body => ['onLoad'] } );

# MOTIVATION

There are already several modules on the CPAN which accomplish much of the same
thing, but after doing a lot of poking around, I was unable to find a solution
with a simple setup which I was happy with.

The most common use case might be stripping HTML from user submitted data
completely or allowing just a few tags and attributes to be displayed.  With
the exception of URI scheme checking, this module doesn't do any validation on
the actual content of the tags or attributes.  If this is a requirement, you
can either mess with the parser object, post-process the text yourself or have
a look at one of the more feature-rich modules in the SEE ALSO section below.

My aim here is to keep things easy and, hopefully, cover a lot of the less
complex use cases with just a few lines of code and some brief documentation.
The idea is to be up and running quickly.

# SEE ALSO

[HTML::TagFilter](https://metacpan.org/pod/HTML::TagFilter), [HTML::Defang](https://metacpan.org/pod/HTML::Defang), [MojoMojo::Declaw](https://metacpan.org/pod/MojoMojo::Declaw), [HTML::StripScripts](https://metacpan.org/pod/HTML::StripScripts),
[HTML::Detoxifier](https://metacpan.org/pod/HTML::Detoxifier), HTML::Sanitizer, [HTML::Scrubber](https://metacpan.org/pod/HTML::Scrubber)

# ACKNOWLEDGEMENTS

Thanks to Raybec Communications [http://www.raybec.com](http://www.raybec.com) for funding my
work on this module and for releasing it to the world.

Thanks also to the following for patches, bug reports and assistance:

Mark Jubenville (ioncache)

Duncan Forsyth

Rick Moore

Arthur Axel 'fREW' Schmidt

perlpong

David Golden

Graham TerMarsch

Dagfinn Ilmari Mannsåker

Graham Knop

Carwyn Ellis

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
