# NAME

Dev::Util::Query - Functions to prompt user for input, y/n, or menus.

# VERSION

Version v2.17.17

# SYNOPSIS

Dev::Util::Query - provides functions to ask the user for input.

    use Dev::Util::Query;

    banner( "Hello World", $outputFH );

    my $msg    = 'Pick a choice from the list:';
    my @items  = ( 'choice one', 'choice two', 'choice three', );
    my $choice = display_menu( $msg, \@items );


    my $action = yes_no_prompt(
                           { text    => "Rename Files?", default => 1, });

    my $dir = prompt(
                      { text    => "Enter Destination Dir",
                        valid   => \&dir_writable,
                      }
                    );

# EXPORT\_TAGS

- **:misc**
    - display\_menu
    - prompt
    - yes\_no\_prompt
    - banner

# SUBROUTINES

## **banner(MESSAGE, FH)**

Print a banner message on the supplied file handle (defaults to `STDOUT`)

    banner( "Hello World" );
    banner( "Hello World", $outputFH );

`MESSAGE` The message to display in the banner

`FH` is a file handle where the banner will be output, default: STDOUT

## **display\_menu(MSG,ITEMS)**

Display a simple menu of options. The choices come from an array.  Returns the index of the choice.

`MSG` a string or variable containing the prompt message to display.

`ITEMS` a reference to an array of the choices to list

    my $msg   = 'Pick one of the suits: ';
    my @items = qw( hearts clubs spades diamonds );
    display_menu( $msg, \@items );

## **yes\_no\_prompt(ARGS\_HASH)**

Prompt user for a yes or no response.  Takes a single character for input, must be `[yYnN\n]`.
A carriage return will return the default.  Returns 1 for yes, 0 for no.

**ARGS\_HASH:**
{ text => TEXT, default => DEFAULT\_BOOL, prepend => PREPEND, append => APPEND }

`TEXT` The text of the prompt.

`DEFAULT_BOOL` Set the default response: 1 -> Yes (\[Y\]/N), 0 -> No (Y/\[N\]), undef -> none

`PREPEND` Text to prepend to TEXT

`APPEND` Text to append to TEXT

    my $action = yes_no_prompt(
                           { text    => "Rename Files?",
                             default => 1,
                             prepend => '>' x 3,
                             append  => ': '
                           }
                         );

## **prompt(ARGS\_HASH)**

Prompt user for input. 

**ARGS\_HASH:**
{ text => TEXT, default => DEFAULT, valid => VALID, prepend => PREPEND, append => APPEND, noecho => ECHO\_BOOL }

`DEFAULT` Set the default response, optionally.

`VALID` Ensures the response is valid.  Can be a list or array reference, in which case 
the values will be presented as a menu.  Alternately, it can be a code ref, where the 
subroutine is run with `$_` set to the response.  An invalid response will re-prompt 
the user for input.

`ECHO_BOOL` Normally (the default 0) text will be echoed as it is typed.  If set to 1
text will not be echoed back to the screen.

    my $interval = prompt(
                           { text    => "Move Files Daily or Monthly",
                             valid   => [ 'daily', 'monthly' ],
                             default => 'daily',
                             prepend => '> ' x 3,
                             append  => ': ',
                             noecho  => 0
                           }
                         );
    my $dir = prompt(
                      { text    => "Enter Destination Dir",
                        valid   => \&dir_writable,
                        prepend => '<' x 3,
                        append  => ': '
                      }
                    );
    my $color = prompt(
                        { text    => "What is your favorite color",
                          prepend => '.' x 3,
                          append  => ': '
                        }
                      );

**Note**: The API for this function is maintained to support the existing code base that uses it.
It would probably be better to use `IO::Prompter` for new code.

# AUTHOR

Matt Martini, `<matt at imaginarywave.com>`

# BUGS

Please report any bugs or feature requests to `bug-dev-util at rt.cpan.org`, or through
the web interface at [https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util](https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dev-Util).  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dev::Util::Query

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util](https://rt.cpan.org/NoAuth/Bugs.html?Dist=Dev-Util)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Dev-Util](http://annocpan.org/dist/Dev-Util)

- CPAN Ratings

    [https://cpanratings.perl.org/d/Dev-Util](https://cpanratings.perl.org/d/Dev-Util)

- Search CPAN

    [https://metacpan.org/release/Dev-Util](https://metacpan.org/release/Dev-Util)

# ACKNOWLEDGMENTS

# LICENSE AND COPYRIGHT

This software is Copyright © 2019-2025 by Matt Martini.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
