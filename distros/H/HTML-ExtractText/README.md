# NAME

HTML::ExtractText - extract multiple text strings from HTML content, using CSS selectors

# SYNOPSIS

At its simplest; use CSS selectors:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract({ page_title => 'title' }, $html) or die "Error: $ext";
    print "Page title is $ext->{page_title}\n";

<div>
    </div></div>
</div>

We can go fancy pants with selectors as well as
extract more than one bit of text:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract(
        {
            article   => 'article#main_content',
            irc_links => 'article#main_content a[href^="irc://"]',
        },
        $html,
    ) or die "Error: $ext";

    print "IRC links:\n$ext->{irc_links}\n";
    print "Full text:\n$ext->{article}\n";

<div>
    </div></div>
</div>

We can also pass in an object and let the extractor call
setter methods on it when it extracts text:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract({ title => 'title' }, $html_code, $some_object )
        or die "Error: $ext";

    print "Our object's ->title method is now set to:",
        $some_object->title, "\n";

<div>
    </div></div>
</div>

# DESCRIPTION

The module allows to extract \[multiple\] text strings from HTML documents,
using CSS selectors to declare what text needs extracting. The module
can either return the results as a hashref or automatically call
setter methods on a provided object.

If you're looking for extra automatic post-processing and laxer
definition of what constitutes "text", see [HTML::ExtractText::Extra](https://metacpan.org/pod/HTML::ExtractText::Extra).

# OVERLOADED METHODS

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        bless {}, 'Foo',
    ) or die "Extraction error: $extractor";

    print "Title is: $extractor->{stuff}\n\n";

The module incorporates two overloaded methods `->error()`, which
is overloaded for interpolation (`use overload q|""| ...`),
and `->last_result()`,
which is overloaded for hash dereferencing
(`use overload q|%{}| ...`).

What this means is that you can interpolate the object in a string
to retrieve the error message and you can use the object as a hashref
to access the hashref returned by `->last_results()`.

# METHODS

## `->new()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">
</div>

    my $extractor = HTML::ExtractText->new;

    my $extractor = HTML::ExtractText->new(
        separator        => "\n",
        ignore_not_found => 1,
    ); # default values for arguments are shown

Creates and returns new `HTML::ExtractText` object. Takes optional
arguments as key/value pairs:

### `separator`

    my $extractor = HTML::ExtractText->new(
        separator => "\n", # default value
    );

    my $extractor = HTML::ExtractText->new(
        separator => undef,
    );

**Optional**. **Default:** `\n` (new line).
Takes `undef` or a string as a value.
Specifies what to do when CSS selector matches multiple
elements. If set to a string value, text from all the matching
elements will be joined using that string. If set to `undef`,
no joining will happen and results will be returned as arrayrefs
instead of strings (even if selector matches a single element).

### `ignore_not_found`

    my $extractor = HTML::ExtractText->new(
        ignore_not_found => 1,  # default value
    );

    my $extractor = HTML::ExtractText->new(
        ignore_not_found => 0,
    );

**Optional**. **Default:** `1` (true). Takes true or false values
as a value. Specifies whether to consider it an error when any
of the given selectors match nothing. If set to a true value,
any non-matching selectors will have empty strings as values and no
errors will be reported. If set to a false value, all selectors must
match at least one element or the module will error out.

## `->extract()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    my $results = $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        $some_object, # optional
    ) or die "Extraction error: $extractor";

    print "Title is: $extractor->{stuff}\n\n";
    # $extractor->{stuff} is the same as $results->{stuff}

Takes **two mandatory** and **one optional** arguments. Extracts text from
given HTML code and returns a hashref with results (
    see `->last_results()` method
). On error, returns
`undef` or empty list and the error will be available via
`->error()` method. Even if errors occurred, anything that
was successfully extracted will still be available through
`->last_results()` method.

### first argument

    $extractor->extract(
        { stuff => 'title', },
        ... ,
        ... ,
    ) or die "Extraction error: $extractor";

Must be a hashref. The keys can be whatever you want; you will use them
to refer to the extracted text. The values must be CSS selectors that
match the elements you want to extract text from.
All the selectors listed on
[https://metacpan.org/pod/Mojo::DOM::CSS#SELECTORS](https://metacpan.org/pod/Mojo::DOM::CSS#SELECTORS) are supported.

Note: the values will be modified in place in the original
hashref you provided, so you can use that
to your advantage, if needed.

### second argument

    $extractor->extract(
        ... ,
        '<title>My html code!</title>',
        ... ,
    ) or die "Extraction error: $extractor";

Takes a string that is HTML code you're trying to extract text from.

### third argument

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        $some_object,
    ) or die "Extraction error: $extractor";

    # this is what is being done automatically, during extraction,
    # for each key in the first argument of ->extract():
    # $some_object->stuff( $extractor->{stuff} );

**Optional**. No defaults. For convenience, you can supply an object and
`HTML::ExtractText` will call methods on it. The called methods
will be the keys of the first argument given to `->extract()` and
the extracted text will be given to those methods as the first argument.

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# ACCESSORS

## `->error()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: " . $extractor->error;

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: $extractor";

Takes no arguments. Returns the error message as a string, if any occurred
during the last call to `->extract()`. Note that
`->error()` will only return one of the error messages, even
if more than one selector failed. Examine the hashref returned
by `->last_results()` to find all the errors;
for any selector that errored out, the value will begin with
`"ERROR: "` and the error message will be there.

## `->last_results()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: $extractor";

    print "Stuff is " . $extractor->last_results->{stuff} . "\n";

    # or

    print "Stuff is $extractor->{stuff}\n";

Takes no arguments. Returns the same hashref
the last call to `->extract` did. If `->extract`
failed, you can still use `->last_results()` to get
anything that didn't error out (the error messages will be in the values
of failed keys).

The hashref will contain the same keys as the first argument
to `->extract()` had and the values will be replaced with
whatever the selectors matched.

If `separator` (see `->new()`) is set to `undef`, the values
will be arrayrefs, with each item in those arrayrefs corresponding
to one matched element in HTML.

The module will attempt to DWIM (Do What I Mean) when selector matches
form controls or images, and use `value=""` or `alt=""` attributes
as text sources.

## `->separator()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $extractor->separator("\n");
    $extractor->separator(undef);

Accessor to `separator` option (see `->new()`).
Takes one optional argument, which if provided, will become the
new separator.

## `->ignore_not_found()`

<div>
    <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">
</div>

    $extractor->ignore_not_found(1);
    $extractor->ignore_not_found(0);

Accessor to `ignore_not_found` option (see `->new()`).
Takes one optional argument, which if provided, will become the
new value of `ignore_not_found` option.

# SUBCLASSING

    sub _extract {
        my ( $self, $dom, $selector, $what ) = @_;
        return $dom->find( $what->{ $selector } )
            ->map( sub { $self->_process( @_ ) } )->each;
    }

You can subclass this module by overriding either or both
`_extract` and `_process` methods. Their names and purpose
are guaranteed to remain unchanged. See source code for their default
implementation.

# NOTES AND CAVEATS

## Encoding

This module does not automatically encode extracted text, so the
examples in this documentation should really include something akin to:

    use Encode;

    my $title = encode 'utf8', $ext->{page_title};
    print "$title\n";

# SEE ALSO

[HTML::ExtractText::Extra](https://metacpan.org/pod/HTML::ExtractText::Extra) - a subclass that offers extra features

[Mojo::DOM](https://metacpan.org/pod/Mojo::DOM), [Text::Balanced](https://metacpan.org/pod/Text::Balanced), [HTML::Extract](https://metacpan.org/pod/HTML::Extract)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/HTML-ExtractText](https://github.com/zoffixznet/HTML-ExtractText)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/HTML-ExtractText/issues](https://github.com/zoffixznet/HTML-ExtractText/issues)

If you can't access GitHub, you can email your request
to `bug-html-extracttext at rt.cpan.org`

<div>
    </div></div>
</div>

# AUTHOR

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

<div>
    <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>
</div>

<div>
    </div></div>
</div>

# CONTRIBUTORS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
