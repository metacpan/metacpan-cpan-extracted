# stubb
**stubb** is a command-line program written in Perl that allows you to create
stub files from pre-existing templates. **stubb** provides many facilities for
customizing the rendering of these templates, making it well-suited to use for
your templated file creation needs.

## Building

**stubb** should be able to run on most Unix-like and Windows operating systems.

**stubb** depends on the following:
* `perl` (>= `5.16`)

The commands to build and install **stubb** are as follows:
```bash
perl Makefile.PL
make
make test
make install
```
Consult the documentation for the `ExtUtils::MakeMaker` Perl module for more
information on how to configure the build process.

## Usage
```bash
stubb [options] file template
stubb [options] file.template
stubb [options] -t template file ...
```
**stubb** creates stub files from template files/directories. *template* can
either be the name of a template in one of **stubb**'s template directories or
a path to a template. By default, **stubb** will search for templates in
`~/.stubb`, but additional directories can be configured via the
`STUBB_TEMPLATES` environment variable or the `-d` command-line option.
Templates in the template directory should be named after the files they're
templating with the `.stubb` file suffix.
```
# *template* can be 'pl', 'pm', or 'py'.
STUBB_TEMPLATES
L pl.stubb
L pm.stubb
L py.stubb
```
When creating stubs, **stubb** will "render" them by scanning the template files
for substitution targets and performing text substitutions that will appear in
the created stub files. Substitution parameters can be supplied to **stubb** via
the `-s` option.

Let's say you have a file called `foo.stubb` in your **stubb** template
directory.
```
This is a ^^foo^^ file.
It does ^^bar^^.
```
And you create a stub from it using the following command:
```bash
stubb -s "foo => text, bar => stuff" output foo
```
The created stub file will look like this:
```
This is a text file.
It does stuff.
```
There are other kinds of substitutions **stubb** can perform on created files.
**stubb**'s manual contains complete documentation on the different kinds of
substitution targets.
```
# Conditional text substitution: will be blank if 'foo' isn't provided
?^^ foo ^^

# Perl code text substitution: $_{ bar } can be set via -s "bar => ..."
$^^ $_{ bar } =~ tr/a-z/n-za-m/r ^^

# Shell code text substitution: $baz can be set via -s "baz => ..."
#^^ printf "%x" "$baz" ^^
```

The `examples/` directory in **stubb**'s source directory contains some
example template files that some users might find useful for learning how to
write templates.

This was a rough overview of **stubb**'s capabilities. For more comprehensive
documentation, you should the **stubb** manual.
```bash
perldoc ./bin/stubb
man stubb # After installation
```

## Author
This program was written by Samuel Young, *\<samyoung12788 at gmail dot com\>*.

This project's source can be found on its
[Codeberg page](https://codeberg.org/1-1sam/stubb). Comments and pull
requests are welcome!

## Copyright
Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
