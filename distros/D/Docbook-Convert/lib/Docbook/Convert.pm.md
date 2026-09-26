# NAME

Docbook::Convert - convert DocBook articles and reference pages to Markdown

# SYNOPSIS

For the retained custom renderer:

```perl
use Docbook::Convert;

my $markdown=Docbook::Convert->markdown_file('doc/guide.xml');
```

For guides using the packaged Pandoc pipeline:

```perl
use Docbook::Convert::Pandoc;

my $converter_or=Docbook::Convert::Pandoc->new();
my $output_fn=$converter_or->convert_file('doc/guide.xml');
```

# DESCRIPTION

`Docbook::Convert` retains the original Perl renderer for DocBook articles and
reference pages. `Docbook::Convert::Pandoc` is the preferred path for larger
guides: it expands local includes and preserves section identifiers,
admonitions and fenced-code attributes.

The converter produces Markdown. Perl documentation is subsequently handled by
`Markdown::Pod::Embed`; direct DocBook-to-POD conversion is retired.

# METHODS

## process($xml, \%options)

Converts an XML string or filehandle using the selected handler. Markdown is
the default output.

## process_file($filename, \%options)

Reads and converts a DocBook file.

## markdown($xml, \%options)

Converts an XML string or filehandle with the custom Markdown renderer.

## markdown_file($filename, \%options)

Reads a DocBook file and converts it with the custom Markdown renderer.

# OPTIONS

The custom renderer accepts `meta_display_top`, `meta_display_bottom`,
`meta_display_title`, `meta_display_title_h_style`, `no_html`,
`no_image_fetch`, and `no_warn_unhandled`. The matching uppercase environment
variables provide process-wide defaults.

# LIMITATIONS

The custom renderer supports the subset of DocBook used by the original module
and utility documentation. It is not a complete DocBook implementation. The
Pandoc pipeline is explicit and does not silently fall back to the custom
renderer when an external command fails.

# SEE ALSO

`Docbook::Convert::Pandoc`, `docbook-convert`, `Markdown::Pod::Embed`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.
