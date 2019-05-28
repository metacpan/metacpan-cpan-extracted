# NAME

Devel::StackTrace - An object representing a stack trace

# VERSION

version 2.04

# SYNOPSIS

    use Devel::StackTrace;

    my $trace = Devel::StackTrace->new;

    print $trace->as_string; # like carp

    # from top (most recent) of stack to bottom.
    while ( my $frame = $trace->next_frame ) {
        print "Has args\n" if $frame->hasargs;
    }

    # from bottom (least recent) of stack to top.
    while ( my $frame = $trace->prev_frame ) {
        print "Sub: ", $frame->subroutine, "\n";
    }

# DESCRIPTION

The `Devel::StackTrace` module contains two classes, `Devel::StackTrace` and
[Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame). These objects encapsulate the information that
can retrieved via Perl's `caller` function, as well as providing a simple
interface to this data.

The `Devel::StackTrace` object contains a set of `Devel::StackTrace::Frame`
objects, one for each level of the stack. The frames contain all the data
available from `caller`.

This code was created to support my [Exception::Class::Base](https://metacpan.org/pod/Exception::Class::Base) class (part of
[Exception::Class](https://metacpan.org/pod/Exception::Class)) but may be useful in other contexts.

# 'TOP' AND 'BOTTOM' OF THE STACK

When describing the methods of the trace object, I use the words 'top' and
'bottom'. In this context, the 'top' frame on the stack is the most recent
frame and the 'bottom' is the least recent.

Here's an example:

    foo();  # bottom frame is here

    sub foo {
       bar();
    }

    sub bar {
       Devel::StackTrace->new;  # top frame is here.
    }

# METHODS

This class provide the following methods:

## Devel::StackTrace->new(%named\_params)

Returns a new Devel::StackTrace object.

Takes the following parameters:

- frame\_filter => $sub

    By default, Devel::StackTrace will include all stack frames before the call to
    its constructor.

    However, you may want to filter out some frames with more granularity than
    'ignore\_package' or 'ignore\_class' allow.

    You can provide a subroutine which is called with the raw frame data for each
    frame. This is a hash reference with two keys, "caller", and "args", both of
    which are array references. The "caller" key is the raw data as returned by
    Perl's `caller` function, and the "args" key are the subroutine arguments
    found in `@DB::args`.

    The filter should return true if the frame should be included, or false if it
    should be skipped.

- filter\_frames\_early => $boolean

    If this parameter is true, `frame_filter` will be called as soon as the
    stacktrace is created, and before refs are stringified (if
    `unsafe_ref_capture` is not set), rather than being filtered lazily when
    [Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame) objects are first needed.

    This is useful if you want to filter based on the frame's arguments and want
    to be able to examine object properties, for example.

- ignore\_package => $package\_name OR \\@package\_names

    Any frames where the package is one of these packages will not be on the
    stack.

- ignore\_class => $package\_name OR \\@package\_names

    Any frames where the package is a subclass of one of these packages (or is the
    same package) will not be on the stack.

    Devel::StackTrace internally adds itself to the 'ignore\_package' parameter,
    meaning that the Devel::StackTrace package is **ALWAYS** ignored. However, if
    you create a subclass of Devel::StackTrace it will not be ignored.

- skip\_frames => $integer

    This will cause this number of stack frames to be excluded from top of the
    stack trace. This prevents the frames from being captured at all, and applies
    before the `frame_filter`, `ignore_package`, or `ignore_class` options,
    even with `filter_frames_early`.

- unsafe\_ref\_capture => $boolean

    If this parameter is true, then Devel::StackTrace will store references
    internally when generating stacktrace frames.

    **This option is very dangerous, and should never be used with exception
    objects**. Using this option will keep any objects or references alive past
    their normal lifetime, until the stack trace object goes out of scope. It can
    keep objects alive even after their `DESTROY` sub is called, resulting it it
    being called multiple times on the same object.

    If not set, Devel::StackTrace replaces any references with their stringified
    representation.

- no\_args => $boolean

    If this parameter is true, then Devel::StackTrace will not store caller
    arguments in stack trace frames at all.

- respect\_overload => $boolean

    By default, Devel::StackTrace will call `overload::AddrRef` to get the
    underlying string representation of an object, instead of respecting the
    object's stringification overloading. If you would prefer to see the
    overloaded representation of objects in stack traces, then set this parameter
    to true.

- max\_arg\_length => $integer

    By default, Devel::StackTrace will display the entire argument for each
    subroutine call. Setting this parameter causes truncates each subroutine
    argument's string representation if it is longer than this number of
    characters.

- message => $string

    By default, Devel::StackTrace will use 'Trace begun' as the message for the
    first stack frame when you call `as_string`. You can supply an alternative
    message using this option.

- indent => $boolean

    If this parameter is true, each stack frame after the first will start with a
    tab character, just like `Carp::confess`.

## $trace->next\_frame

Returns the next [Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame) object on the stack, going
down. If this method hasn't been called before it returns the first frame. It
returns `undef` when it reaches the bottom of the stack and then resets its
pointer so the next call to `$trace->next_frame` or `$trace->prev_frame` will work properly.

## $trace->prev\_frame

Returns the next [Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame) object on the stack, going up. If
this method hasn't been called before it returns the last frame. It returns
undef when it reaches the top of the stack and then resets its pointer so the
next call to `$trace->next_frame` or `$trace->prev_frame` will work
properly.

## $trace->reset\_pointer

Resets the pointer so that the next call to `$trace->next_frame` or `$trace->prev_frame` will start at the top or bottom of the stack, as
appropriate.

## $trace->frames

When this method is called with no arguments, it returns a list of
[Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame) objects. They are returned in order from top (most
recent) to bottom.

This method can also be used to set the object's frames if you pass it a list
of [Devel::StackTrace::Frame](https://metacpan.org/pod/Devel::StackTrace::Frame) objects.

This is useful if you want to filter the list of frames in ways that are more
complex than can be handled by the `$trace->filter_frames` method:

    $stacktrace->frames( my_filter( $stacktrace->frames ) );

## $trace->frame($index)

Given an index, this method returns the relevant frame, or undef if there is
no frame at that index. The index is exactly like a Perl array. The first
frame is 0 and negative indexes are allowed.

## $trace->frame\_count

Returns the number of frames in the trace object.

## $trace->as\_string(\\%p)

Calls `$frame->as_string` on each frame from top to bottom, producing
output quite similar to the Carp module's cluck/confess methods.

The optional `\%p` parameter only has one option. The `max_arg_length`
parameter truncates each subroutine argument's string representation if it is
longer than this number of characters.

If all the frames in a trace are skipped then this just returns the `message`
passed to the constructor or the string `"Trace begun"`.

## $trace->message

Returns the message passed to the constructor. If this wasn't passed then this
method returns `undef`.

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Devel-StackTrace/issues](https://github.com/houseabsolute/Devel-StackTrace/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Devel-StackTrace can be found at [https://github.com/houseabsolute/Devel-StackTrace](https://github.com/houseabsolute/Devel-StackTrace).

# DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that **I am not suggesting that you must do this** in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at [http://www.urth.org/~autarch/fs-donation.html](http://www.urth.org/~autarch/fs-donation.html).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>
- David Cantrell <david@cantrell.org.uk>
- Graham Knop <haarg@haarg.org>
- Ivan Bessarabov <ivan@bessarabov.ru>
- Mark Fowler <mark@twoshortplanks.com>
- Pali <pali@cpan.org>
- Ricardo Signes <rjbs@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2000 - 2019 by David Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
