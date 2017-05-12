# NAME

Docopt - Command-line interface description language

# SYNOPSIS

    use Docopt;

    my $opts = docopt();
    ...

    __END__

    =head1 SYNOPSIS

        log-aggregate [--date=<ymd>]

# DESCRIPTION

__Docopt.pm is still under development. I may change interface without notice.__

Docopt is command-line interface description language.

docopt helps you:

- define interface for your command-line app, and
- automatically generate parser for it.

docopt is based on conventions that are used for decades in help messages and man pages for program interface description. Interface description in docopt is such a help message, but formalized. Here is an example:

    Naval Fate.

    Usage:
        naval_fate ship new <name>...
        naval_fate ship <name> move <x> <y> [--speed=<kn>]
        naval_fate ship shoot <x> <y>
        naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
        naval_fate -h | --help
        naval_fate --version

    Options:
        -h --help     Show this screen.
        --version     Show version.
        --speed=<kn>  Speed in knots [default: 10].
        --moored      Moored (anchored) mine.
        --drifting    Drifting mine.

The example describes interface of executable naval\_fate, which can be invoked with different combinations of commands (ship, new, move, etc.), options (-h, --help, --speed=<kn>, etc.) and positional arguments (<name>, <x>, <y>).

Example uses brackets "\[ \]", parens "( )", pipes "|" and ellipsis "..." to describe optional, required, mutually exclusive, and repeating elements. Together, these elements form valid usage patterns, each starting with program's name naval\_fate.

Below the usage patterns, there is a list of options with descriptions. They describe whether an option has short/long forms (-h, --help), whether an option has an argument (--speed=<kn>), and whether that argument has a default value (\[default: 10\]).

docopt implementation will extract all that information and generate a command-line arguments parser, with text of the example above being the help message, which is shown to a user when the program is invoked with -h or --help options.

# Usage patterns

You can read official document: [http://docopt.org/](http://docopt.org/)

# FUNCTIONS

- `my $opts = docopt(%args)`

    Analyze argv by Docopt!

    Return value is HashRef.

    You can pass following options in `%args`:

    - doc

        It's Docopt documentation.

        If you don't provide this argument, Docopt.pm uses pod SYNOPSIS section in $0.

    - argv

        Argument in arrayref.

        Default: `\@ARGV`

    - help

        If it's true value, Docopt.pm enables ` --help ` option automatically.

        Default: true.

    - version

        Version number of the script. If it's not undef, Docopt.pm enables ` --version ` option.

        Default: undef

    - option\_first

            if (options_first) {
                argv ::= [ long | shorts ]* [ argument ]* [ '--' [ argument ]* ] ;
            } else {
                argv ::= [ long | shorts | argument ]* [ '--' [ argument ]* ] ;
            }

        Default: undef

# BASED ON

This version is based on docopt-py e495aaaf0b9dcea6bc8bc97d9143a0d7a649fa06.

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
