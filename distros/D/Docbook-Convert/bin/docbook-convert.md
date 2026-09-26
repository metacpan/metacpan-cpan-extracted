# NAME #

docbook-convert - convert DocBook articles and reference pages to Markdown

# SYNOPSIS #

`docbook-convert --markdown file.xml`

# Description #

docbook-convert converts DocBook documents to Markdown. Use --pandoc for guides
with local includes, section IDs and MkDocs admonitions. Direct conversion to
POD and merging XML into Perl source are no longer supported.

This utility will work on Docbook 4+ Articles and Refentry templates. See Limitations in this document for information on
 capabilities of this program.

# Options #

* **--pandoc**

    Convert a filename to Markdown using Pandoc and the supplied Lua/XSL filters.
    Local includes are expanded and section IDs preserved. This mode requires
    pandoc, xmllint and xsltproc.

* **--dump**

    Dump internal parse tree of Docbook file. Useful for debugging.

* **--handler -h**

    Which output handler to use. Use --handler=markdown (or md).

* **--help**

    Short help file

* **-f --in -infile**

    Name of input file. If not supplied in options input file with be first command line argument \- or if not supplied STDIN

* **--man**

    Show this manpage

* **--markdown --md**

    Output as Markdown. Shorthand for \--handler=markdown

* **--meta_display_title_h_style**

    If rendering a metadata title which heading style should be applied. One of h1..h4

* **--meta_display_bottom**

    Render any metadata at the bottom of the document

* **--meta_display_title**

    Optional title to be rendered as a prefix to any metadata displayed

* **--meta_display_top**

    Render any metadata at the top of the document

* **--no_html**

    Do not incorporate any HTML in the output \(e.g. images). This may limit what can be converted.

* **--no_image_fetch**

    If an image incorporated into a Docbook file has attributes which indicate scaling should be applied the image will be fetched
 by the converter and the appropriate width calculated. This option
 will prevent fetching of remote images, and thus will nullify any
 scaling attributes associated with images.

* **--silent**

    Do not warn on any unhandled tags or other issues

* **-o --out -outfile**

    Name of file any output should be sent to. If specified as suffix only \(e.g. \--outfile=.foo) then the \.xml extension will be
 stripped from the input file name and the nominated suffix applied.
 The result will be used as the output file name. Userful with \--recurse

* **--recursedir|d**

    Convert all \.xml files in a nominated directory

* **--recurse**

    Convert all files in the current working directory and any sub-directories

* **-V -version**

    Display the version number of the utility

# Examples #

    # Convert a single file to markdown

    docbook-convert --markdown -f mydoc.xml -o mydoc.md

    # Convert all files in a directory to markdown

    docbook-convert --markdown --recursedir ~/mydoc/ -o .md

    # Include meta-data in output

    docbook-convert --markdown --meta_display_top myarticle.xml -o myarticle.md

# Limitations #

This utility and associated Perl module will only convert a subset of Docbook entities and tags.

# LICENSE and COPYRIGHT #

This file is part of Docbook::Convert.

This software is copyright \(c) 2025 by Andrew Speer &lt;andrew.speer@isolutions.com.au&gt;.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

Full license text is available at:

&lt;http://dev.perl.org/licenses/&gt;
