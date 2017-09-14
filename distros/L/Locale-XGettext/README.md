# Locale-XGettext

Extract strings from arbitrary formats into PO files

## Description

When using 
[GNU gettext](https://www.gnu.org/software/gettext/)
you often find yourself extracting translatable
strings from more or less exotic file formats that cannot be handled
by xgettext from the
[GNU gettext](https://www.gnu.org/software/gettext/)
suite directly.  This package simplifies
the task of writing a string extractor in Perl, Python, Java, Ruby or
other languages by providing a common base needed for such scripts.

## Usage

Included is a sample string extractor [xgettext-txt](bin/xgettext-txt) for plain text files.  It simply
splits the input into paragraphs, and turns each paragraph into an
entry of a PO file.

## Common Workflow

The idea of the package is that you just a write a parser plug-in for
`Locale::XGettext` and use all the boilerplate code for generating the
PO file and for processing script options from this library.  One such
example is a parser plug-in for strings in templates for the
Template Toolkit version 2 included in the package 
[Template-Plugin-Gettext](https://github.com/gflohr/Template-Plugin-Gettext).
that contains a script `xgettext-tt2` which can only extract
strings from that particular template language.

If this is the only source of translatable strings you are mostly done.
Often times you will, however, have to merge strings from all different
input formats into one single PO file.  Let's assume that your project
is written in Perl and C and that it also contains Template Toolkit
templates and plain text files that have to be translated.

1. Use `xgettext-txt` from this package to extract strings from all
   plain text files and write the output into `text.pot`.

2. Use `xgettext-tt2` from 
   [Template-Plugin-Gettext](https://github.com/gflohr/Template-Plugin-Gettext)
   to extract all strings
   from your templates into another file `templates.pot`.

3. Finally use `xgettext` from
   [GNU gettext](https://www.gnu.org/software/gettext/)
   for extracting strings from
   all source files written in Perl and C, _and_ from the previously
   created pot files `text.pot` and `templates.pot`.  This works
   because `xgettext` natively understands `.po` resp. `.pot` files.
 
By the way, all xgettext flavors based on `Locale::XGettext`
are also able to extract strings from `.po` or `.pot` files.  So you
can also make do completely without GNU gettext and use any `Locale::XGettext`
extractor instead of GNU gettext for the last step.

## Writing Extractors

Writing an extractor is as easy as implementing one single method that
takes a filename argument and extract strings from that file.  See 
the manual page
[Locale::XGettext(3pm)](http://search.cpan.org/~guido/Locale-XGettext/lib/Locale/XGettext.pm)
for more information.  See [samples/README.md](samples/README.md)
as a starting point for writing an extractor in Perl or many
other languages.  The distribution currently contains fully functional
examples written in [C](samples/C/README.md), [Java](samples/Java/README.md), 
[Python](samples/Python/README.md), [Perl](samples/Perl/README.md),
and [Ruby](samples/Ruby/README.md).

## Differences To `xgettext` From GNU Gettext

There a couple of subtle differences in the handling of command-line
arguments between extractors based on `Locale::XGettext` and
the original `xgettext` program.  Report a bug if you think that
a particular difference is a bug and not an improvement.

One thing that `Locale::XGettext` does not support is the prefix
"pass-" for flag definitions.  While it is possible for an
extractor to implement the behavior of GNU gettext, this is not
directly supported by `Locale::XGettext`.  Instead, that
prefix is simply ignored, when specified on the command-line
for an option argument to "--flag" or as part of the set of 
default flags for a particular extractor.

Additionally, while `xgettext` from GNU gettext has a hard-coded,
fixed set of supported formats, you can specify arbitrary formats
with "--flag" for extractors based on `Locale::XGettext`.

## Installation

### From CPAN

You can install the latest version of `Locale::XGettext` from
[CPAN](http://search.cpan.org/) with:

```
$ cpan Locale::XGettext
```

If the command `cpan` is not installed, try instead:

```
$ perl -MCPAN -e 'install Locale::XGettext'
```

### From Sources

Download the sources from 
[Locale-XGettext](https://github.com/gflohr/Locale-XGettext) and

```
$ tar cxf Locale-XGettext-VERSION.tar.gz
$ cd Locale-XGettext-VERSION
$ perl Makefile.PL
$ make
$ make test
$ make install
```

### From Git

```
$ git clone https://github.com/gflohr/Locale-XGettext.git
$ cd Locale-XGettext
$ dzil build
$ cd Locale-XGettext-VERSION
```

From here, follow the instructions for installation from sources.

The command `dzil` is part of [Dist::Zilla](http://search.cpan.org/~rjbs/Dist-Zilla/).

## TODO

The module should ship with its own PO parser and writer.

## Bugs

Please report bugs at 
[https://github.com/gflohr/Locale-XGettext/issues](https://github.com/gflohr/Locale-XGettext/issues)

## Copyright

Copyright (C) 2016-2017, Guido Flohr, <guido.flohr@cantanea.com>, 
all rights reserved.
