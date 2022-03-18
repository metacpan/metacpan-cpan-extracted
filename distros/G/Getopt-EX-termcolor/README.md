[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-termcolor/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-termcolor/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-termcolor.svg)](https://metacpan.org/release/Getopt-EX-termcolor)
# NAME

Getopt::EX::termcolor - Getopt::EX termcolor module

# SYNOPSIS

    use Getopt::EX::Loader;
    my $rcloader = Getopt::EX::Loader->new(
        BASECLASS => [ 'App::command', 'Getopt::EX' ],
        );

    or

    use Getopt::EX::Long qw(:DEFAULT ExConfigure);
    ExConfigure BASECLASS => [ "App::command", "Getopt::EX" ];

    then

    $ command -Mtermcolor::bg=

# VERSION

Version 1.08

# DESCRIPTION

This is a common module for command using [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) to manipulate
system dependent terminal color.

Actual action is done by sub-module under [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor),
such as [Getopt::EX::termcolor::Apple\_Terminal](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor%3A%3AApple_Terminal).

Each sub-module is expected to have `&get_color` function which
return the list of RGB values for requested name, but currently name
`background` is only supported.  Each RGB values are expected in a
range of 0 to 255 by default.  If the first entry of the list is a
HASH reference, it may include maximum number indication like `{
max => 65535 }`.

Terminal luminance is calculated from RGB values by this equation and
produces decimal value from 0 to 100.

    ( 30 * R + 59 * G + 11 * B ) / MAX

If the environment variable `TERM_BGCOLOR` is defined, it is used as
a background RGB value without calling sub-modules.  RGB value is a
combination of integer described in 24bit/12bit hex, 24bit decimal or
6x6x6 216 color format.  RGB color notation is compatible with
[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap).

    24bit hex     #000000 .. #FFFFFF
    12bit hex     #000    .. #FFF
    24bit decimal 0,0,0   .. 255,255,255
    6x6x6 216     000     .. 555

You can set `TERM_BGCOLOR` in you start up file of shell.  This
module has utility function `bgcolor` which can be used like this:

    export TERM_BGCOLOR=`perl -MGetopt::EX::termcolor=bgcolor -e bgcolor`
    : ${TERM_BGCOLOR:=#FFFFFF}

# MODULE FUNCTION

- **bg**

    Call this function with module option:

        $ command -Mtermcolor::bg=

    If the terminal luminance is unknown, nothing happens.  Otherwise, the
    module insert **--light-terminal** or **--dark-terminal** option
    according to the luminance value.

    You can change the behavior by optional parameters:

        threshold : threshold of light/dark  (default 50)
        default   : default luminance value  (default none)
        light     : light terminal option    (default "--light-terminal")
        dark      : dark terminal option     (default "--dark-terminal")

    Use like this:

        option default \
            -Mtermcolor::bg(default=100,light=--light,dark=--dark)

# SEE ALSO

[Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX)

[Getopt::EX::termcolor::Apple\_Terminal](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor%3A%3AApple_Terminal)

[Getopt::EX::termcolor::iTerm](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor%3A%3AiTerm)

[Getopt::EX::termcolor::XTerm](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor%3A%3AXTerm)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2021 Kazumasa Utashiro.

You can redistribute it and/or modify it under the same terms
as Perl itself.
