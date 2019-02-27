# NAME

Log::MixedColor - Outputs messages in multiple colors

# VERSION

version 0.001

# SYNOPSIS

Output log messages in color while emphasizing parts of the message in a different color.
Although colour codes witin a message string can be done manually, this module is providing a 
simplified approach to colour logging hopefully saving time and code
(and colour codes can also be inserted manually if required - i.e. they won't be stripped).

    use Log::MixedColor;
    my $log = Log::MixedColor->new;

    $log->verbose(1);
    $log->info_msg( "This is a ".$log->quote('general info')." message." );

    $log->debug(1);
    $log->debug_msg( "This is a ".$log->q('debug')." message" );

There are four types of messages:

- `info_msg` (or `info`) - displayed when debug or verbose are turned on
- `debug_msg` (or `dmsg`) - displayed when debug is turned on
- `err_msg` (or `err`) - displayed all the time on STDERR
- `fatal_msg` (or `fatal`) - displayed all the time on STDERR and will cause the script to exit

The `debug` and `verbose` methods are intended so that the script utilising this module can
pass the command line option values specifying whether to operate the script logging in verbose or debug mode.

    use Getopt::Std;
    use Log::MixedColor;

    our( $opt_v, $opt_d );
    getopts('vd');

    my $log = Log::MixedColor->new( verbose => $opt_v, debug => $opt_d );

    $log->info_msg( "This is a ".$log->quote('general info')." message." );
    $log->debug_msg( "This is a ".$log->q('debug')." message" );

The debug log messages will only display when the script is run with `-d` and the verbose messages will
be display when the script is run with `-d` or `-v`.

# METHODS

## new

Create the _Log::MixedColor_ object.  The following can be set at creation time (defaults shown):

    my $log = Log::MixedColor->new( verbose => 0, debug => 0, fatal_is_fatal => 1 );

which is equivalent to:

    my $log = Log::MixedColor->new;

## verbose

Put the log object in verbose mode.

    $log->verbose(1);

## v

Alias for `verbose`.

## debug

Put the log object in debug mode.

    $log->debug(1);

## d

Alias for `debug`.

## quote

Quote a portion of the message in a different color to the rest of the message

    $log->debug_msg( "This is a ".$log->quote('quoted bit')." inside a message." );

Alternatively, instead of using this method, you could just use the quoting strings directly, e.g.:

    $log->debug_msg( "This is a %%quoted bit## inside a message." );

## q

Alias for `quote`.

## quote\_start

Sets the string used to denote the start of the text to be quoted in a different color. Default shown

    $log->quote_start( '%%' );

It needs to be different from that specified by `quote_end`.

## quote\_end

Sets the string used to denote the end of the text to be quoted in a different color. Default shown.

    $log->quote_end( '##' );

It needs to be different from that specified by `quote_start`.

## info\_msg

Display a message on `STDOUT` when the log object is in debug or verbose mode.

    $log->info_msg( "This is a ".$log->quote('general')." message." );

## info

Alias for `info_msg`.

## debug\_msg

Display a message on `STDOUT` when the log object is in debug mode.

    $log->debug_msg( "This is a ".$log->quote('low level')." message." );

## dmsg

Alias for `debug_msg`.

## err\_msg

Display a message on `STDERR`.

    $log->err_msg( "This is a ".$log->quote('warning')." message." );

## err

Alias for `err_msg`.

## warn

Alias for `err_msg`.

## fatal\_err

Display a message on `STDERR` and then exit the script.

    $log->fatal_err( "This is a ".$log->quote('critical')." message so we have to stop.", 2 );

The optional second argument is the exit code the script will exit with.  It defaults to `1`.

The _exit_ feature can be turned off by setting `$log->fatal_is_fatal` to false.

## fatal

Alias for `fatal_err`.

## fatal\_is\_fatal

Determines whether the `fatal_msg` method actually causes the script to exit.  It
will by default.

    $log->fatal_is_fatal(0);

Turning it off will make it equivalent to `err_msg`, but might be helpful when developing a script
during which time you may not want it to be fatal, but you do when your script goes into production.

## COLORS

To customise the colors, pass the color strings as recognised by [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor) to the following 
relevant methods or set the equivalent properties as part of `new` (the default is shown in brackets):

- `info_color` (green)
- `debug_color` (magenta)
- `err_color` (red)
- `info_quote_color` (black on\_white)
- `debug_quote_color` (blue)
- `err_quote_color` (yellow)

The `fatal_err` method will use the same colours as the `err_msg` method.

## Message Prefixes

To allow for language variations and individual preferences the prefix before the output message can 
be customised with the following methods (defaults shown in brackets):

- `info_prefix` (Info:)
- `debug_prefix` (Debug:)
- `err_prefix` (Error:)

The `fatal_err` method will use the same prefix as the `err_msg` method.

# BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
[https://github.com/Q-Technologies/perl-Log-MixedColor](https://github.com/Q-Technologies/perl-Log-MixedColor). Ideally, submit a Pull Request.

# AUTHOR

Matthew Mallard <mqtech@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
