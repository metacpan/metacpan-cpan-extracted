# NAME

Docbook::Convert::Markdown - custom Markdown renderer for Docbook::Convert

# DESCRIPTION

This internal renderer maps the parsed DocBook tree to Markdown for the
original `Docbook::Convert` implementation. It is selected by
`Docbook::Convert->markdown()` and `markdown_file()`.

For guides requiring includes, stable section identifiers, code attributes or
MkDocs admonitions, use `Docbook::Convert::Pandoc`.

# SEE ALSO

`Docbook::Convert`, `Docbook::Convert::Pandoc`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
