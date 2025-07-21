# NAME

Encode::Wide - Convert wide characters (Unicode) into HTML or XML-safe ASCII entities

# VERSION

0.03

# SYNOPSIS

    use Encode::Wide qw(wide_to_html wide_to_xml);

    my $html = wide_to_html(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade'

    my $xml = wide_to_xml(string => "Café déjà vu – naïve façade");
    # returns: 'Caf&#xE9; d&#xE9;j&#xE0; vu &#x2013; na&#xEF;ve fa&#xE7;ade'

# DESCRIPTION

Encode::Wide provides functions for converting wide (Unicode) characters into ASCII-safe
formats suitable for embedding in HTML or XML documents. It is especially useful
when dealing with text containing accented or typographic characters that need
to be safely represented in markup.

The module offers two exportable functions:

- `wide_to_html(string =` $text)>

    Converts Unicode characters in the input string to their named HTML entities if available,
    or hexadecimal numeric entities otherwise. Common characters such as \`é\`, \`à\`, \`&\`, \`<\`, \`>\` are
    converted to their standard HTML representations like \`&amp;eacute;\`, \`&amp;agrave;\`, \`&amp;amp;\`, etc.

- `wide_to_xml(string =` $text)>

    Converts all non-ASCII characters in the input string to hexadecimal numeric entities.
    Unlike HTML, XML does not support many named entities, so this function ensures compliance
    by using numeric representations such as \`&amp;#xE9;\` for \`é\`.

# PARAMETERS

Both functions accept a named parameter:

- `string` — The Unicode string to convert.

# ENCODING

Input strings are expected to be valid UTF-8. If a byte string is passed, the module will attempt
to decode it appropriately. Output is guaranteed to be pure ASCII.

# EXPORT

None by default.

Optionally exportable:

    wide_to_html
    wide_to_xml

# SEE ALSO

[HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities), [Encode](https://metacpan.org/pod/Encode), [XML::Entities](https://metacpan.org/pod/XML%3A%3AEntities), [Unicode::Escape](https://metacpan.org/pod/Unicode%3A%3AEscape).

[https://www.compart.com/en/unicode/](https://www.compart.com/en/unicode/).

# AUTHOR

Nigel Horne <njh@nigelhorne.com>

# LICENCE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
