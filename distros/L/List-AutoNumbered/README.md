# List::AutoNumbered - Add sequential numbers to lists while creating them



This module adds sequential numbers to lists of lists so you don't have to
type all the numbers.  Its original use case was for adding line numbers
to lists of testcases.  For example:

    use List::AutoNumbered;                             # line 1
    my $list = List::AutoNumbered->new(__LINE__);       # line 2
    $list->load("a")->                                  # line 3
        ("b")                                           # line 4
        ("c")                                           # line 5
        ("d");                                          # line 6

    # Now $list->arr is [ [3,"a"], [4,"b"], [5,"c"], [6,"d"] ]

In general, you can pass any number to the constructor.  For example:

    use List::AutoNumbered;
    use Test::More tests => 1;

    my $list = List::AutoNumbered->new;     # First entry will be number 1
    $list->load("a")->      # Yes, trailing arrow
        ("b")               # Magic!  Don"t need any more arrows!
        ("c")
        ("d");

    is_deeply($list->arr, [
        [1, "a"], [2, "b"], [3, "c"], [4, "d"]
    ]);     # Yes, it is!

# METHODS

## new

Constructor.  Basic usage options:

    $list = List::AutoNumbered->new();      # first list item is number 1
    $list = List::AutoNumbered->new($num);  # first list item is $num+1
    $list = List::AutoNumbered->new(-at => $num);   # ditto

Each successive element
will have the next number, unless you say otherwise (e.g., using
[LSKIP()](#lskip)).  Specifically, the first item in the list will be numbered
one higher than the number passed to the `List::AutoNumbered` constructor.

Constructor parameters are processed using [Getargs::Mixed](https://metacpan.org/pod/Getargs::Mixed), so positional
and named parameters are both OK.

### The `how` function

You can give the constructor a "how" function that will make the list entry
for a single [load()](#load) or [add()](#add) call:

    $list = List::AutoNumbered->new(-how => sub { @_ });
        # Jam everything together to make a flat array
    $list = List::AutoNumbered->new(41, sub { @_ });
        # Positional is OK, too.

The `how` function is called as `how($num, @data)`.  `$num` is the
line number for [load()](#load) calls, or `undef` for [add()](#add) calls.
`@data` is whatever data you passed to `load()` or `add()`.  For example,
the default `how` function is:

    sub how {
        shift unless defined $_[0];     # add passes undef as the line number.
        [@_]                            # Wrap everything in an arrayref.
    }

See `t/05-custom-list-entry.t` for examples of custom `how` functions.

## size

Returns the size of the array.  Like `scalar @arr`.

## last

Returns the index of the last element in the array.  Like `$#array`.

## arr

Returns a reference to the array being built.  Please do not modify this
array directly until you are done loading it.  List::AutoNumbered may not
work if you do.

## last\_number

Returns the current number stored by the instance.  This is the number
of the most recently preceding [new()](#new) or [load()](#load) call.
This is **not** the number that will be given to the next record, since that
depends on whether or not the next record has a skip ([LSKIP()](#lskip)).

## load

Push a new record with the next number on the front.  Usage:

    $instance->load(whatever args you want to push);

Or, if the current record isn't associated with the number immediately after
the previous record,

    $instance->load(LSKIP $n, args);

where `$n` is the number of lines between this `load()` call and the last one.

Returns a coderef that you can call to chain loads.  For example, this works:

    $instance->load(...)->(...)(...)(...) ... ;
    # You need an arrow ^^ here, but don't need any after that.

## add

Add to the array being built, **without** inserting the number on the front.
Does increment the number and respect skips, for consistency.

Returns the instance.

# FUNCTIONS

## LSKIP

A convenience function to create a skipper.  Prototyped as `($)` so you can
use it conveniently with [load()](#load):

    $instance->load(LSKIP 1, whatever args...);

If you are using line numbers, the parameter to `LSKIP` should be the number
of lines above the current line and below the last [new()](#new) or
[load()](#load) call.  For example:

    my $instance = List::AutoNumbered->new(__LINE__);
    # A line
    # Another one
    $instance->load(LSKIP 2,    # two comment lines between new() and here
                    'some data');

# INTERNAL PACKAGES

## List::AutoNumbered::Skipper

This package represents a skip and is created by [LSKIP()](#lskip).
No user-serviceable parts inside.

### new

Creates a new skipper.  Parameters are for internal use only and are not
part of the public API.

# GLOBALS

## $TRACE

(Default falsy) If truthy, print trace output.  Must be accessed directly
unless requested on the `use` line.  Either of the following works:

    use List::AutoNumbered; $List::AutoNumbered::TRACE=1;
    use List::AutoNumbered q(*TRACE); $TRACE=1;

# AUTHOR

Christopher White, `<cxwembedded at gmail.com>`

# BUGS

Please report any bugs or feature requests through the web interface at
[https://github.com/cxw42/List-AutoNumbered/issues](https://github.com/cxw42/List-AutoNumbered/issues).  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc List::AutoNumbered

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/pod/List::AutoNumbered](https://metacpan.org/pod/List::AutoNumbered)

- CPAN Ratings

    [https://cpanratings.perl.org/d/List-AutoNumbered](https://cpanratings.perl.org/d/List-AutoNumbered)

# ACKNOWLEDGEMENTS

Thanks to [zdim](https://stackoverflow.com/users/4653379/zdim)
for discussion and ideas in the
[Stack Overflow question](https://stackoverflow.com/q/50510809/2877364)
that was the starting point for this module.

# LICENSE AND COPYRIGHT

Copyright 2019 Christopher White.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See [http://dev.perl.org/licenses/](http://dev.perl.org/licenses/) for more information.
