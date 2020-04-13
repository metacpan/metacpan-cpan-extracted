# NAME

Getopt::EX::autocolor - Getopt::EX autocolor module

# SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = new Getopt::EX::Loader
        BASECLASS => [ 'App::command', 'Getopt::EX' ];

    $ command -Mautocolor

# VERSION

Version 0.01

# DESCRIPTION

This is a common module for command using [Getopt::EX](https://metacpan.org/pod/Getopt::EX) to set system
dependent autocolor option.

Each module is expected to set **--light-terminal** or
**--dark-terminal** option according to the brightness of a terminal
program.

If the environment variable `BRIGHTNESS` is defined, its value is
used as a brightness without calling submodules.  The value of
`BRIGHTNESS` is expected in range of 0 to 100.

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt::EX)

[Getopt::EX::autocolor::Apple\_Terminal](https://metacpan.org/pod/Getopt::EX::autocolor::Apple_Terminal)

[Getopt::EX::autocolor::iTerm2](https://metacpan.org/pod/Getopt::EX::autocolor::iTerm2)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.
