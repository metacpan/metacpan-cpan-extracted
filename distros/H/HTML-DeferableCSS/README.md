# NAME

HTML::DeferableCSS - Simplify management of stylesheets in your HTML

# VERSION

version v0.2.0

# SYNOPSIS

```perl
use HTML::DeferableCSS;

my $css = HTML::DeferableCSS->new(
    css_root      => '/var/www/css',
    url_base_path => '/css',
    inline_max    => 512,
    aliases => {
      reset => 1,
      jqui  => 'jquery-ui',
      site  => 'style',
    },
    cdn => {
      jqui  => '//cdn.example.com/jquery-ui.min.css',
    },
);

...

print $css->deferred_link_html( qw[ jqui site ] );
```

# DESCRIPTION

This is an experimental module for generating HTML-snippets for
deferable stylesheets.

This allows the stylesheets to be loaded asynchronously, allowing the
page to be rendered faster.

Ideally, this would be a simple matter of changing stylesheet links
to something like

```
<link rel="preload" as="stylesheet" href="....">
```

but this is not well supported by all web browsers. So a web page
needs some JavaScript to handle this, as well as a `noscript` block
as a fallback.

This module allows you to simplify the management of stylesheets for a
web application, from development to production by

- declaring all stylesheets used by your web application;
- specifying remote aliases for stylesheets, e.g. from a CDN;
- enable or disable the use of minified stylesheets;
- switch between local copies of stylesheets or CDN versions;
- automatically inline small stylesheets;
- use deferred-loading stylesheets, which requires embedding JavaScript
code as a workaround for web browsers that do not support these
natively.

# ATTRIBUTES

## aliases

This is a required hash reference of names and their relative
filenames to ["css\_root"](#css_root).

It is recommended that the `.css` and `.min.css` suffixes be
omitted.

If the name is the same as the filename (without the extension) than
you can simply use `1`.  (Likewise, an empty string or `0` disables
the alias.)

Absolute paths cannot be used.

You may specify URLs instead of files, but this is not recommended,
except for cases when the files are not available locally.

## css\_root

This is the required root directory where all stylesheets can be
found.

## url\_base\_path

This is the URL prefix for stylesheets.

It can be a full URL prefix.

## prefer\_min

If true (default), then a file with the `.min.css` suffix will be
preferred, if it exists in the same directory.

Note that this does not do any minification. You will need separate
tools for that.

## css\_files

This is a hash reference used internally to translate ["aliases"](#aliases)
into the actual files or URLs.

If files cannot be found, then it will throw an error.

## cdn\_links

This is a hash reference of ["aliases"](#aliases) to URLs.

When ["use\_cdn\_links"](#use_cdn_links) is true, then these URLs will be used instead
of local versions.

## has\_cdn\_links

This is true when there are ["cdn\_links"](#cdn_links).

## use\_cdn\_links

When true, this will prefer CDN URLs instead of local files.

## inline\_max

This specifies the maximum size of an file to inline.

Local files under the size will be inlined using the
["link\_or\_inline\_html"](#link_or_inline_html) or ["deferred\_link\_html"](#deferred_link_html) methods.

Setting this to 0 disables the use of inline links, unless
["inline\_html"](#inline_html) is called explicitly.

## defer\_css

True by default.

This is used by ["deferred\_link\_html"](#deferred_link_html) to determine whether to emit
code for deferred stylesheets.

## include\_noscript

When true, a `noscript` element will be included with non-deffered
links.

This defaults to the same value as ["defer\_css"](#defer_css).

## preload\_script

This is the pathname of the `cssrelpreload.js` file that will be
embedded in the resulting code.

You do not need to modify this unless you want to use a different
script from the one included with this module.

## link\_template

This is a code reference for a subroutine that returns a stylesheet link.

## preload\_template

This is a code reference for a subroutine that returns a stylesheet
preload link.

## asset\_id

This is an optional static asset id to append to local links. It may
refer to a version number or commit-id, for example.

This is useful to ensure that changes to stylesheets are picked up by
web browsers that would otherwise use cached copies of older versions
of files.

## has\_asset\_id

True if there is an ["asset\_id"](#asset_id).

# METHODS

## href

```perl
my $href = $css->href( $alias );
```

This returns this URL for an alias.

## link\_html

```perl
my $html = $css->link_html( $alias );
```

This returns the link HTML markup for the stylesheet referred to by
`$alias`.

## inline\_html

```perl
my $html = $css->inline_html( $alias );
```

This returns an embedded stylesheet referred to by `$alias`.

## link\_or\_inline\_html

```perl
my $html = $css->link_or_inline_html( @aliases );
```

This returns either the link HTML markup, or the embedded stylesheet,
if the file size is not greater than ["inline\_max"](#inline_max).

## deferred\_link\_html

```perl
my $html = $css->deferred_link_html( @aliases );
```

This returns the HTML markup for the stylesheets specified by
["aliases"](#aliases), as appropriate for each stylesheet.

If the stylesheets are not greater than ["inline\_max"](#inline_max), then it will
embed them.  Otherwise it will return the appropriate markup,
depending on ["defer\_css"](#defer_css).

# KNOWN ISSUES

## XHTML Support

This module is written for HTML5.

It does not support XHTML self-closing elements or embedding styles
and scripts in CDATA sections.

## Encoding

All files are embedded as raw files.

No URL encoding is done on the HTML links or ["asset\_id"](#asset_id).

## It's spelled "Deferrable"

It's also spelled "Deferable".

# SOURCE

The development version is on github at [https://github.com/robrwo/HTML-DeferableCSS](https://github.com/robrwo/HTML-DeferableCSS)
and may be cloned from [git://github.com/robrwo/HTML-DeferableCSS.git](git://github.com/robrwo/HTML-DeferableCSS.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/HTML-DeferableCSS/issues](https://github.com/robrwo/HTML-DeferableCSS/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

`reset.css` comes from [http://meyerweb.com/eric/tools/css/reset/](http://meyerweb.com/eric/tools/css/reset/).

`cssrelpreload.js` comes from [https://github.com/filamentgroup/loadCSS/](https://github.com/filamentgroup/loadCSS/).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Robert Rothenberg.

This is free software, licensed under:

```
The MIT (X11) License
```
