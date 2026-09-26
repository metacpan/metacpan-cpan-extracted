# NAME

Docbook::Convert::Base - internal document-tree support for Docbook::Convert

# DESCRIPTION

This module supplies the constructor, tree traversal and handler dispatch used
by the retained custom DocBook renderer. It is an implementation class for
`Docbook::Convert`; applications should use `Docbook::Convert` or
`Docbook::Convert::Pandoc` instead.

# COMPATIBILITY

The custom renderer is retained for existing conversions. New guide conversion
should normally use the Pandoc pipeline.

# SEE ALSO

`Docbook::Convert`, `Docbook::Convert::Pandoc`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2025 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
