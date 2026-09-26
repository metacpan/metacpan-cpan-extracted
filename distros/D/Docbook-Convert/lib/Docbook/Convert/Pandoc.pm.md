# NAME

Docbook::Convert::Pandoc - convert DocBook guides to Markdown

# SYNOPSIS

```perl
use Docbook::Convert::Pandoc;
my $converter_or=Docbook::Convert::Pandoc->new();
my $markdown=$converter_or->convert_file('doc/guide.xml');
$converter_or->convert_articles('doc');
```

# PUBLIC METHODS

`new(\%options)` creates a converter. Optional pandoc, xmllint and xsltproc
values select executable paths.

`convert_file($filename)` returns Markdown bytes. It expands local XIncludes
and entities, promotes title IDs to sections, and runs Pandoc with the supplied
admonition filter. It requires a real filename so relative includes resolve
against the source document. Intermediate XML lives in temporary files. Literal
angle brackets in prose are emitted as HTML entities so the Markdown renders
consistently with Pandoc and Python-Markdown based tools such as MkDocs.

`discover_articles($directory)` recursively returns DocBook article XML files.
Generated, site, MkDocs, example and image directories are excluded. Discovery
does not depend on a Perl distribution's `MANIFEST`.

`convert_articles($directory)` converts every discovered `article.xml` to its
sibling `article.md` name and returns the paths changed. Existing output is
replaced only when its content differs. Set `dry_run` when constructing the
converter to report changes without writing them. Symlink outputs are refused.

Commands use argument arrays and failures throw exceptions containing diagnostics.
The source document is never modified. Images remain references, so copy their
associated assets when assembling a site. Network document retrieval is disabled
for the XML preprocessing commands.

The package supplies its Lua and XSL filters under the adjacent Pandoc directory.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
