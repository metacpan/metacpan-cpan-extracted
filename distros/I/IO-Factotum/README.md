[![Actions Status](https://github.com/tecolicom/IO-Factotum/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/IO-Factotum/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/IO-Factotum.svg)](https://metacpan.org/release/IO-Factotum)
# NAME

IO::Factotum - read files through a converter chosen by their names

# SYNOPSIS

    use IO::Factotum;

    IO::Factotum::register(
        match   => qr/\.gz$/,
        command => [ 'gzip', '-dc' ],
    );

    my $fh = IO::Factotum::open_input($file) or die "$file: $!";
    while (<$fh>) {
        ...
    }

# VERSION

Version 0.04

# DESCRIPTION

A factotum is a person who does all kinds of work for someone.  This
module is one for the files a program reads: tell it what to do with
which files, and it gives them to the program ready to read.  A file
is opened through a converter chosen by its name, and the handle gives
the output of the converter instead of the content of the file.  The
file itself is not changed, and the program keeps its name.

Converters are registered with a condition on the file name.  A file
which no converter takes, and a file whose converter fails, is read
as it is.

# FUNCTIONS

Nothing is exported.

- **register**(**match** => _condition_, **command** => _command_)

    Register a converter.  Converters are tried in the order they were
    registered, and the first one that matches is used.

    _condition_ is a regex which the file name is matched against, or a
    code reference which is called with the file name and returns true
    for the file to convert.

    _command_ is an array reference in the form of [Command::Run](https://metacpan.org/pod/Command%3A%3ARun): an
    external command with its arguments, or a code reference with its
    arguments.  The file name is added as the last argument, and what the
    command writes to the standard output is the converted content, taken
    byte for byte.  The command is not given to the shell.

        register(match => qr/\.gz$/, command => [ 'gzip', '-dc' ]);

        register(match   => sub { -B $_[0] },
                 command => [ \&to_text, '--plain' ]);

    The command runs in a process of its own, with the standard error
    thrown away.  It fails by an exit status other than 0; a code
    reference fails by `die`.  A code reference prints bytes, and the
    `END` blocks of the program do not run in its process.

- **clear**()

    Remove all the converters.

- **open\_input**(_file_)

    Open the _file_ for reading and return the handle, an [IO::File](https://metacpan.org/pod/IO%3A%3AFile)
    object.  When a converter matches the name and exits with status 0,
    the handle reads its output, which is kept in a temporary file
    without a name.  Otherwise the handle reads the file itself.

    It returns `undef` with `$!` set when the file can not be opened.

    The handle has the `:raw` layer.  Set the encoding by `binmode`:

        my $fh = IO::Factotum::open_input($file) or die "$file: $!";
        binmode $fh, ':encoding(utf8)';

    The name `-` is the standard input, which is not converted: the
    handle is that of `STDIN` itself, with the layers it has.

- **load**(_name_, ...)

    Register the converters of the modules `IO::Factotum::`_name_, by
    calling their `setup` function.  It dies when there is no such
    module.

        IO::Factotum::load('Highlight::skylighting');

- **tie\_argv**()

    Tie `ARGV`, so that `<>` reads the files of `@ARGV` by
    `open_input`.  A program which reads by `<>` gets the
    converted content with no change in it:

        IO::Factotum::tie_argv();
        while (<>) {
            print "$ARGV: $_";
        }

    `@ARGV` is looked at when the first line is read, so the options can
    be taken from it before.  As with the plain `<>`, `$ARGV`
    is the name of the file, `$.` counts the lines of all the files,
    `eof()` is true at the end of the last file, `close ARGV` starts
    the line numbers again, and the standard input is read when there is
    no file.  `<<>>` and the `-i` option of perl are
    not supported.

# CONVERTERS

The converters which come with this module are under
`IO::Factotum::Highlight`.  They color source files by their syntax.

- [IO::Factotum::Highlight::skylighting](https://metacpan.org/pod/IO%3A%3AFactotum%3A%3AHighlight%3A%3Askylighting) (`Highlight::sky`)

    by the `skylighting` command, the highlighter of pandoc

- [IO::Factotum::Highlight::sourcehighlight](https://metacpan.org/pod/IO%3A%3AFactotum%3A%3AHighlight%3A%3Asourcehighlight) (`Highlight::gnu`)

    by the `source-highlight` command of GNU Source-highlight

    IO::Factotum::load('Highlight::sky');

# SEE ALSO

[IO::Factotum::Highlight::skylighting](https://metacpan.org/pod/IO%3A%3AFactotum%3A%3AHighlight%3A%3Askylighting),
[IO::Factotum::Highlight::sourcehighlight](https://metacpan.org/pod/IO%3A%3AFactotum%3A%3AHighlight%3A%3Asourcehighlight), [Getopt::EX::Factotum](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AFactotum)

[Command::Run](https://metacpan.org/pod/Command%3A%3ARun)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
