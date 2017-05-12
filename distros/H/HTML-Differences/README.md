# NAME

HTML::Differences - Reasonable sane HTML diffing

# VERSION

version 0.01

# SYNOPSIS

    use HTML::Differences qw( html_text_diff );

    my $html1 = <<'EOF';
    <p>Some text</p>
    EOF

    my $html2 = <<'EOF';
    <p>Some <strong>strong</strong> text</p>
    EOF

    print html_text_diff( $html1, $html2 );

# DESCRIPTION

This module provides a reasonable sane way to get the diff between two HTML
documents or fragments. Under the hood, it uses [HTML::Parser](https://metacpan.org/pod/HTML::Parser).

## How the Diffing Works

Internally, this module converts the HTML it gets into an array reference
containing each unique HTML token. These tokens consists of things such as the
doctype declaration, tag start & end, text, etc.

All whitespace between two pieces of text is converted to a single space,
_except_ when inside a `<pre>` block. Leading and trailing space on text
is also stripped out.

Start tags are normalized so that attributes appear in sorted order, and all
quotes are converted to double quotes, with one space before each
attribute. Self-closing tags (like `<hr/>`) are converted to their
simpler form (`<hr>`).

Note that because [HTML::Parser](https://metacpan.org/pod/HTML::Parser) decodes HTML entities inside attribute
values, this module cannot distinguish between two attributes where one
contains an entity and one does not.

Missing end tags _are not_ added, and will show up in the diff.

Comments are included by default, but you can pass a flag to ignore them.

# IMPORTABLE SUBROUTINES

This module offers two optionally importable subroutines. Nothing is exported
by default.

## html\_text\_diff( $html1, $html2, %options )

This subroutine uses [Text::Diff](https://metacpan.org/pod/Text::Diff)'s `diff()` subroutine to provide a string
version of the diff between the two pieces of HTML provided.

The HTML can be passed as a plain scalar or as a reference to a scalar.

After the two HTML parameters, you can pass key/value pairs as options:

- ignore\_comments

    If this is true, then comments are ignored for the purpose of the diff. This
    defaults to false.

- style

    The style for the diff. This defaults to "Table". See [Text::Diff](https://metacpan.org/pod/Text::Diff) for the
    available options.

- context

    The amount of context to show in the diff. This defaults to `2**31` to
    include all the context. You can set this to some smaller value if you prefer.

## diffable\_html( $html1, $html2, %options )

This returns an array reference of strings suitable for passing to any of
[Algorithm::Diff](https://metacpan.org/pod/Algorithm::Diff)'s methods or exported subroutines.

The only option currently accepted is `ignore_comments`.

# WHY THIS MODULE EXISTS

There are a couple other modules out there that do HTML diffs, so why write
this one?

The [HTML::Diff](https://metacpan.org/pod/HTML::Diff) module uses regexes to parse HTML. This is crazy.

The [Test::HTML::Differences](https://metacpan.org/pod/Test::HTML::Differences) module attempts to fix up the HTML a little too
much for my purposes. It ends up ignoring missing end tags or breaking on them
in various ways.

# AUTHOR

Dave Rolsky <autarch@urth.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
