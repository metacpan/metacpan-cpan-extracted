# NAME

HTML::ExtractText::Extra - extra useful HTML::ExtractText

# SYNOPSIS

At its simplest; use CSS selectors:

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

    # Same usage as HTML::ExtractText, but now we have extra
    # optional options (default values are shown):
    use HTML::ExtractText::Extra;
    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1, # strip leading/trailing whitespace
        nbsp       => 1, # replace non-breaking spaces with regular ones
    );

    $ext->extract(
        {
            page_title => 'title', # same extraction as HTML::ExtractText
            links => ['a', qr{http://|www\.} ], # strip what matches
            bold  => ['b', sub { "<$_[0]>"; } ], # wrap what's found in <>
        },
        $html,
    ) or die "Error: $ext";
    print "Page title is $ext->{page_title}\nLinks are: $ext->{links}";

<div>
    </div></div>
</div>

# DESCRIPTION

The module offers extra options and post-processing that the vanilla
[HTML::ExtractText](https://metacpan.org/pod/HTML::ExtractText) does not provide.

# METHODS FROM `HTML::ExtractText`

This module offers all the standard methods and behaviour
[HTML::ExtractText](https://metacpan.org/pod/HTML::ExtractText) provides. See its documentation for details.

# EXTRA OPTIONS IN `->new`

    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1, # strip leading/trailing whitespace
        nbsp       => 1, # replace non-breaking spaces with regular ones
    );

## `whitespace`

    my $ext = HTML::ExtractText::Extra->new(
        whitespace => 1,
    );

**Optional**. **Defaults to:** `1`. When set to a true value,
leading and trailing whitespace will be trimmed from the results.

## `nbsp`

    my $ext = HTML::ExtractText::Extra->new(
        nbsp => 1,
    );

**Optional**. **Defaults to:** `1`. When set to a true value,
non-breaking spaces in the results will be converted into regular spaces.
Note that this does not affect how the normal white-space folding
operates, so `foo &nbsp; bar` will end up having 3 spaces between
`foo` and `bar`.

# EXTRA PROCESSING OPERATIONS IN `->extract`

    $ext->extract(
        {
            page_title => 'title', # same extraction as HTML::ExtractText
            links => ['a', qr{http://|www\.} ],  # strip what matches
            bold  => ['b', sub { "<$_[0]>"; } ], # wrap what's found in <>
        },
        $html,
    ) or die "Error: $ext";

This module extends possible values in the hashref given as the first
argument to `->extract` method. They are given by changing
the string containing the selector to an arrayref, where the first element
is the selector you want to match and the rest of the elements are as
follows:

## Regex reference

    $ext->extract({ links => ['a', qr{http://|www\.} ] }, $html )

When second element of the arrayref is a regex reference,
any text that matches the regex will be stripped from the text
that is being extracted.

## Code reference

     $ext->extract({ links => ['a', sub { "<$_[0]>"; } ] }, $html )

When second element of the arrayref is a code reference, it will be
called for each found bit of text we're extracting and its `@_` will
contain that text as the first element. Whatever the sub returns will
be used as the result of extraction.

# ACCESSORS

## `whitespace`

    $ext->whitespace(0);

Accessor method for the `whitespace` argument to `->new`.

## `nbsp`

    $ext->nbsp(0);

Accessor method for the `nbsp` argument to `->new`.

# SEE ALSO

[HTML::ExtractText](https://metacpan.org/pod/HTML::ExtractText) - a basic version of this extractor

[Mojo::DOM](https://metacpan.org/pod/Mojo::DOM), [Text::Balanced](https://metacpan.org/pod/Text::Balanced), [HTML::Extract](https://metacpan.org/pod/HTML::Extract)

<div>
    <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>
</div>

# REPOSITORY

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

Fork this module on GitHub:
[https://github.com/zoffixznet/HTML-ExtractText-Extra](https://github.com/zoffixznet/HTML-ExtractText-Extra)

<div>
    </div></div>
</div>

# BUGS

<div>
    <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">
</div>

To report bugs or request features, please use
[https://github.com/zoffixznet/HTML-ExtractText-Extra/issues](https://github.com/zoffixznet/HTML-ExtractText-Extra/issues)

If you can't access GitHub, you can email your request
to `bug-html-extracttext-extra at rt.cpan.org`

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

# LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the `LICENSE` file included in this distribution for complete
details.
