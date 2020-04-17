# NAME

Getopt::EX::termcolor - Getopt::EX termcolor module

# SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = new Getopt::EX::Loader
        BASECLASS => [ 'App::command', 'Getopt::EX' ];

    $ command -Mtermcolor

# VERSION

Version 1.01

# DESCRIPTION

This is a common module for command using [Getopt::EX](https://metacpan.org/pod/Getopt::EX) to set system
dependent termcolor option.

Actual action is done by sub-module under [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt::EX::termcolor),
such as [Getopt::EX::termcolor::Apple\_Terminal](https://metacpan.org/pod/Getopt::EX::termcolor::Apple_Terminal).

Each sub-module is expected to have `&brightness` function which
returns integer value between 0 and 100.  If the sub-module was found
and `&brightness` function exists, its result is taken as a
brightness of the terminal.

However, if the environment variable `BRIGHTNESS` is defined, its
value is used as a brightness without calling sub-modules.  The value
of `BRIGHTNESS` is expected in range of 0 to 100.

If the brightness can not be taken, nothing happens.  Otherwise, the
module insert **--light-terminal** or **--dark-terminal** option
according to the brightness value.  These options are defined as
C$<move(0,0)> in this module and do nothing.  They can be overridden
by other module or user definition.

You can change the behavior of this module by calling `&set` function
with module option.  It takes some parameters and they override
default values.

    threshold : threshold of light/dark  (default 50)
    default   : default brightness value (default none)
    light     : light terminal option    (default "--light-terminal")
    dark      : dark terminal option     (default "--dark-terminal")

For example, use like:

    option default \
        -Mtermcolor::set(default=100,light=--light,dark=--dark)

# FUNCTIONS

- **rgb\_to\_brightness**

    This exportable function caliculates brightness (luminane) from RGB
    values.  It accepts three parameters of 0 to 65535 integer.

    Maximum value can be specified by optional hash argument.

        rgb_to_brightness( { max => 255 }, 255, 255, 255);

    Brightness is caliculated from RGB values by this equation.

        Y = 0.30 * R + 0.59 * G + 0.11 * B

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt::EX)

[Getopt::EX::termcolor::Apple\_Terminal](https://metacpan.org/pod/Getopt::EX::termcolor::Apple_Terminal)

[Getopt::EX::termcolor::iTerm](https://metacpan.org/pod/Getopt::EX::termcolor::iTerm)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.
