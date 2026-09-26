# Docbook::Convert {#docbook-convert}

## Purpose {#purpose}

Docbook::Convert turns maintained DocBook articles and reference pages into Markdown. The Markdown can be published directly or passed to Markdown::Pod::Embed when it documents Perl source.

The preferred guide path uses Pandoc with the filters supplied in this distribution. The original Perl renderer remains available for existing documents and is selected explicitly.

## Pandoc pipeline {#pandoc-pipeline}

``` perl
use Docbook::Convert::Pandoc;

my $converter_or=Docbook::Convert::Pandoc->new();
my $output_fn=$converter_or->convert_file('doc/guide.xml');
```

This path expands local includes and preserves section identifiers, admonitions and fenced-code attributes. Conversion failure is reported; it does not silently select another renderer.

## Custom renderer {#custom-renderer}

``` perl
use Docbook::Convert;

my $markdown=Docbook::Convert->markdown_file('doc/guide.xml');
```

The custom renderer supports the subset of DocBook used by the original module and utility documentation. It is retained for compatibility and is not intended as a complete DocBook implementation.

## Documentation workflow {#workflow}

1.  Maintain articles under the doc directory.

2.  Convert DocBook sources to sibling Markdown files.

3.  Merge Markdown sidecars into Perl source where required.

4.  Assemble and publish the Markdown with the selected site backend.

!!! note

    Direct DocBook-to-POD conversion is retired. Markdown is the durable
    boundary between authoring, Perl documentation and site publication.
