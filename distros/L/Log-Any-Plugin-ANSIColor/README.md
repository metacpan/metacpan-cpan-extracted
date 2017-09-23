[![Build Status](https://travis-ci.org/sdt/Log-Any-Plugin-ANSIColor.svg?branch=master)](https://travis-ci.org/sdt/Log-Any-Plugin-ANSIColor)
# NAME

Log::Any::Plugin::ANSIColor - Auto-colorize Log::Any logs with Term::ANSIColor

# SYNOPSIS

    use Log::Any::Adapter 'Stderr';     # Choose any adapter that makes sense

    use Log::Any::Plugin;
    Log::Any::Plugin->add('ANSIColor'); # Use the default colorscheme

    # In this or any other module
    use Log::Any qw( $log );

    $log->alert('Call the police!');    # Prints as red on white

# DESCRIPTION

Log::Any::Plugin::ANSIColor automatically applies ANSI colors to log messages depending on the log level.

For example, with the default colorscheme, `error` logs are red, `warning` logs are yellow.

If a given log level has no coloring, the original log method is left intact, and incurs no overhead.

# USAGE

Adding the plugin with no extra arguments gives the default colorscheme.

    Log::Any::Plugin->add('ANSIColor');

Note that `info` and `notice` messages have no special coloring in the default colorscheme.

Specify some colors to completely replace the default colorscheme. Only the specified colors are applied.

    Log::Any::Plugin->add('ANSIColor',
            error   => 'white on_red',
            warning => 'black on_yellow',
    );

Use `default => 1` to include the default colorscheme with customisations. Default colors can be switched off by specifying `'none'` as the color.

    Log::Any::Plugin->add('ANSIColor',
            default => 1,               # use default colors
            error   => 'white on_red',  # override error color
            warning => 'none',          # turn off warning color
    );

Valid colors are any strings acceptable to `colored` in [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor).
eg. `'blue'` `'bright_red on_white`

# LICENSE

Copyright (C) Stephen Thirlwall.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Stephen Thirlwall <sdt@cpan.org>
