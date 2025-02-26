# ishmael
**ishmael** is a Perl program that reads given ebook documents and converts
their contents to formatted plain text, which should be suitable for
piping into other programs for further processing. It accomplishes this
by converting the ebook contents to HTML and then formatting that HTML
using the dump feature found in many text web browsers, like `lynx(1)`.

**ishmael** currently supports the following ebook formats:
* EPUB
* MOBI
* AZW
* HTML/XHTML
* PDF
* FictionBook2
* PalmDoc
* zTXT
* Text

## Building
**ishmael** should be able to run on most Unix-like systems, as long as they
support the dependencies listed below. It should also be able to run on
Windows, although I haven't extensively tested it.

**ishmael** requires at least perl `5.16`.

**ishmael** depends on the following Perl modules, which can be installed via
either CPAN or your system's package manager:
* `Archive::Zip`
* `File::Which`
* `JSON`
* `XML::LibXML`

**ishmael** also depends on the following programs to be installed on your
system:
* `perl` (>= `5.16`)
* `poppler-utils` (optional; for PDF support)

The following text web browsers can be installed for **ishmael** to use for
formatting HTML. If none are installed, **ishmael** will use its own HTML
formatting script called **queequeg**.
* `elinks`
* `links`
* `lynx`
* `w3m`

Once the aforementioned dependencies are installed, **ishmael** can then be
installed via the following commands:
```bash
perl Makefile.PL
make
make test
make install
```
See the documentation for `ExtUtils::MakeMaker` for more information on how to
configure the build process.

## Usage
**ishmael**'s usage is pretty simple; you give it an ebook file as argument and
it dumps its formatted text contents to *stdout*. For more comprehensive
documentation, one should consult **ishmael**'s manual.
```bash
perldoc bin/ishmael
man 1 ishmael # If ishmael is already installed
```
## Author
Written by Samuel Young, *\<samyoung12788 at gmail dot com\>*.

This project's source can be found on its
[Codeberg page](https://codeberg.org/1-1sam/ishmael). Comments and pull
requests are welcome!

## History

This is the fifth iteration of this program, and hopefully the last :-).

This program originally went by the name of **ebread**. The first iteration was
written in C and only supported EPUBs, it was quite buggy. The second
iteration was written as a learning exercise for Perl, it too only supported
EPUBs, it was also where I got the idea to delegate the text formatting task to
another program. The third iteration was again in C, but this time supported
a bunch of other ebook formats. It wasn't nearly as buggy as the first, but the
code was quite sloppy and had gotten to the point where I couldn't extend it
much. The fourth iteration was written in Raku, it only supported EPUBs. This
iteration, I renamed the project to **ishmael** because I got bored of the last
name. This iteration supports multiple different ebook formats, but is written
in Perl so it should (hopefully) be less buggy and more maintainable.

## Copyright
Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
