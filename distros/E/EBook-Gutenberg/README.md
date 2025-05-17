# gutenberg
**gutenberg** is a Perl program that provides a command-line interface for
fetching ebook files from [Project Gutenberg](https://www.gutenberg.org/), a
project dedicated to cataloging and archiving public-domain ebooks.

## Building
**gutenberg** should be able to run on most Unix-like operating systems, as long
as they support the dependencies listed below. It should also be able to run on
Windows, although I have not extensively tested it.

**gutenberg** depends on the following:
* `perl` (>= `5.16`)
* `Text::CSV_XS`
* One of the following programs/libraries for fetching remote files via
`File::Fetch`:
  - `LWP`
  - `HTTP::Tiny`
  - `wget`
  - `curl`
  - `lftp`
  - `fetch`
  - `HTTP::Lite`
  - `lynx`
  - `iosock`
* `dialog` (optional; for the `menu` command)

Once the aforementioned dependencies are installed, **gutenberg** can built and
installed via the following commands:
```bash
perl Makefile.PL
make
make test
make install
```
Please consult the documentation for `ExtUtils::MakeMaker` for more information
on configuring the build process.

## Usage
Before you can use **gutenberg**, you must first fetch a local copy of the
Project Gutenberg ebook catalog. This is done via the `update` command.
```bash
gutenberg update
```
Once the catalog is obtained, you can begin searching for ebooks and
downloading them from Project Gutenberg.

**gutenberg** performs operations by being given commands. **gutenberg**
currently implements the following commands:
* `update`: Update the local Project Gutenberg ebook catalog. This command
should be ran periodically so that **gutenberg** can be informed of any new
ebooks or changes to existing ebook metadata.
* `get <target>`: Fetch an ebook file matching *target*. *target* can be an
ebook ID, title string, or title regex.
* `search <target>`: Search for a list of ebooks matching *target*.
* `meta <id>`: Print the metadata for the ebook corresponding to *id*.
* `menu`: Launch the dialog-based TUI.

This section was meant to be a quick overview of **gutenberg**'s capabilities.
For more detailed documentation, you should consult the **gutenberg** manual.
```bash
gutenberg -h
man 1 gutenberg
```

## Caveats/Restrictions
This program was **NOT** designed to scrape or bulk download files from
Project Gutenberg. Attempting to use this program to do so may result in Project
Gutenberg banning you from using their services. Download responsibly!

This program does not currently support fetching non-text ebooks, like audio
books. Support for non-text formats may be implemented in the future if there
is demand.

## Author
This program was written by Samuel Young, *\<samyoung12788 at gmail dot com\>*.

This project's source can be found on its
[Codeberg page](https://codeberg.org/1-1sam/gutenberg). Comments and pull
requests are welcome!

## Copyright
Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
