# NAME

Log::Dispatch - Dispatches messages to one or more outputs

# VERSION

version 2.69

# SYNOPSIS

    use Log::Dispatch;

    # Simple API
    #
    my $log = Log::Dispatch->new(
        outputs => [
            [ 'File',   min_level => 'debug', filename => 'logfile' ],
            [ 'Screen', min_level => 'warning' ],
        ],
    );

    $log->info('Blah, blah');

    # More verbose API
    #
    my $log = Log::Dispatch->new();
    $log->add(
        Log::Dispatch::File->new(
            name      => 'file1',
            min_level => 'debug',
            filename  => 'logfile'
        )
    );
    $log->add(
        Log::Dispatch::Screen->new(
            name      => 'screen',
            min_level => 'warning',
        )
    );

    $log->log( level => 'info', message => 'Blah, blah' );

    my $sub = sub { my %p = @_; return reverse $p{message}; };
    my $reversing_dispatcher = Log::Dispatch->new( callbacks => $sub );

# DESCRIPTION

This module manages a set of Log::Dispatch::\* output objects that can be
logged to via a unified interface.

The idea is that you create a Log::Dispatch object and then add various
logging objects to it (such as a file logger or screen logger). Then you
call the `log` method of the dispatch object, which passes the message to
each of the objects, which in turn decide whether or not to accept the
message and what to do with it.

This makes it possible to call single method and send a message to a
log file, via email, to the screen, and anywhere else, all with very
little code needed on your part, once the dispatching object has been
created.

# METHODS

This class provides the following methods:

## Log::Dispatch->new(...)

This method takes the following parameters:

- outputs( \[ \[ class, params, ... \], \[ class, params, ... \], ... \] )

    This parameter is a reference to a list of lists. Each inner list consists of
    a class name and a set of constructor params. The class is automatically
    prefixed with 'Log::Dispatch::' unless it begins with '+', in which case the
    string following '+' is taken to be a full classname. e.g.

        outputs => [ [ 'File',          min_level => 'debug', filename => 'logfile' ],
                     [ '+My::Dispatch', min_level => 'info' ] ]

    For each inner list, a new output object is created and added to the
    dispatcher (via the `add()` method).

    See ["OUTPUT CLASSES"](#output-classes) for the parameters that can be used when creating an
    output object.

- callbacks( \\& or \[ \\&, \\&, ... \] )

    This parameter may be a single subroutine reference or an array
    reference of subroutine references. These callbacks will be called in
    the order they are given and passed a hash containing the following keys:

        ( message => $log_message, level => $log_level )

    In addition, any key/value pairs passed to a logging method will be
    passed onto your callback.

    The callbacks are expected to modify the message and then return a
    single scalar containing that modified message. These callbacks will
    be called when either the `log` or `log_to` methods are called and
    will only be applied to a given message once. If they do not return
    the message then you will get no output. Make sure to return the
    message!

## $dispatch->clone()

This returns a _shallow_ clone of the original object. The underlying output
objects and callbacks are shared between the two objects. However any changes
made to the outputs or callbacks that the object contains are not shared.

## $dispatch->log( level => $, message => $ or \\& )

Sends the message (at the appropriate level) to all the output objects that
the dispatcher contains (by calling the `log_to` method repeatedly).

The level can be specified by name or by an integer from 0 (debug) to 7
(emergency).

This method also accepts a subroutine reference as the message
argument. This reference will be called only if there is an output
that will accept a message of the specified level.

## $dispatch->debug (message), info (message), ...

You may call any valid log level (including valid abbreviations) as a method
with a single argument that is the message to be logged. This is converted
into a call to the `log` method with the appropriate level.

For example:

    $log->alert('Strange data in incoming request');

translates to:

    $log->log( level => 'alert', message => 'Strange data in incoming request' );

If you pass an array to these methods, it will be stringified as is:

    my @array = ('Something', 'bad', 'is', 'here');
    $log->alert(@array);

    # is equivalent to

    $log->alert("@array");

You can also pass a subroutine reference, just like passing one to the
`log()` method.

## $dispatch->log\_and\_die( level => $, message => $ or \\& )

Has the same behavior as calling `log()` but calls
`_die_with_message()` at the end.

You can throw exception objects by subclassing this method.

If the `carp_level` parameter is present its value will be added to
the current value of `$Carp::CarpLevel`.

## $dispatch->log\_and\_croak( level => $, message => $ or \\& )

A synonym for `$dispatch-`log\_and\_die()>.

## $dispatch->log\_to( name => $, level => $, message => $ )

Sends the message only to the named object. Note: this will not properly
handle a subroutine reference as the message.

## $dispatch->add\_callback( $code )

Adds a callback (like those given during construction). It is added to the end
of the list of callbacks. Note that this can also be called on individual
output objects.

## $dispatch->remove\_callback( $code )

Remove the given callback from the list of callbacks. Note that this can also
be called on individual output objects.

## $dispatch->callbacks()

Returns a list of the callbacks in a given output.

## $dispatch->level\_is\_valid( $string )

Returns true or false to indicate whether or not the given string is a
valid log level. Can be called as either a class or object method.

## $dispatch->would\_log( $string )

Given a log level, returns true or false to indicate whether or not
anything would be logged for that log level.

## $dispatch->is\_`$level`

There are methods for every log level: `is_debug()`, `is_warning()`, etc.

This returns true if the logger will log a message at the given level.

## $dispatch->add( Log::Dispatch::\* OBJECT )

Adds a new [output object](#output-classes) to the dispatcher. If an object
of the same name already exists, then that object is replaced, with
a warning if `$^W` is true.

## $dispatch->remove($)

Removes the output object that matches the name given to the remove method.
The return value is the object being removed or undef if no object
matched this.

## $dispatch->outputs()

Returns a list of output objects.

## $dispatch->output( $name )

Returns the output object of the given name. Returns undef or an empty
list, depending on context, if the given output does not exist.

## $dispatch->\_die\_with\_message( message => $, carp\_level => $ )

This method is used by `log_and_die` and will either die() or croak()
depending on the value of `message`: if it's a reference or it ends
with a new line then a plain die will be used, otherwise it will
croak.

# OUTPUT CLASSES

An output class - e.g. [Log::Dispatch::File](https://metacpan.org/pod/Log::Dispatch::File) or
[Log::Dispatch::Screen](https://metacpan.org/pod/Log::Dispatch::Screen) - implements a particular way
of dispatching logs. Many output classes come with this distribution,
and others are available separately on CPAN.

The following common parameters can be used when creating an output class.
All are optional. Most output classes will have additional parameters beyond
these, see their documentation for details.

- name ($)

    A name for the object (not the filename!). This is useful if you want to
    refer to the object later, e.g. to log specifically to it or remove it.

    By default a unique name will be generated. You should not depend on the
    form of generated names, as they may change.

- min\_level ($)

    The minimum [logging level](#log-levels) this object will accept. Required.

- max\_level ($)

    The maximum [logging level](#log-levels) this object will accept. By default
    the maximum is the highest possible level (which means functionally that the
    object has no maximum).

- callbacks( \\& or \[ \\&, \\&, ... \] )

    This parameter may be a single subroutine reference or an array
    reference of subroutine references. These callbacks will be called in
    the order they are given and passed a hash containing the following keys:

        ( message => $log_message, level => $log_level )

    The callbacks are expected to modify the message and then return a
    single scalar containing that modified message. These callbacks will
    be called when either the `log` or `log_to` methods are called and
    will only be applied to a given message once. If they do not return
    the message then you will get no output. Make sure to return the
    message!

- newline (0|1)

    If true, a callback will be added to the end of the callbacks list that adds
    a newline to the end of each message. Default is false, but some
    output classes may decide to make the default true.

# LOG LEVELS

The log levels that Log::Dispatch uses are taken directly from the
syslog man pages (except that I expanded them to full words). Valid
levels are:

- debug
- info
- notice
- warning
- error
- critical
- alert
- emergency

Alternately, the numbers 0 through 7 may be used (debug is 0 and emergency is
7). The syslog standard of 'err', 'crit', and 'emerg' is also acceptable. We
also allow 'warn' as a synonym for 'warning'.

# SUBCLASSING

This module was designed to be easy to subclass. If you want to handle
messaging in a way not implemented in this package, you should be able to add
this with minimal effort. It is generally as simple as subclassing
Log::Dispatch::Output and overriding the `new` and `log_message`
methods. See the [Log::Dispatch::Output](https://metacpan.org/pod/Log::Dispatch::Output) docs for more details.

If you would like to create your own subclass for sending email then
it is even simpler. Simply subclass [Log::Dispatch::Email](https://metacpan.org/pod/Log::Dispatch::Email) and
override the `send_email` method. See the [Log::Dispatch::Email](https://metacpan.org/pod/Log::Dispatch::Email)
docs for more details.

The logging levels that Log::Dispatch uses are borrowed from the standard
UNIX syslog levels, except that where syslog uses partial words ("err")
Log::Dispatch also allows the use of the full word as well ("error").

# RELATED MODULES

## Log::Dispatch::DBI

Written by Tatsuhiko Miyagawa. Log output to a database table.

## Log::Dispatch::FileRotate

Written by Mark Pfeiffer. Rotates log files periodically as part of
its usage.

## Log::Dispatch::File::Stamped

Written by Eric Cholet. Stamps log files with date and time
information.

## Log::Dispatch::Jabber

Written by Aaron Straup Cope. Logs messages via Jabber.

## Log::Dispatch::Tk

Written by Dominique Dumont. Logs messages to a Tk window.

## Log::Dispatch::Win32EventLog

Written by Arthur Bergman. Logs messages to the Windows event log.

## Log::Log4perl

An implementation of Java's log4j API in Perl. Log messages can be limited by
fine-grained controls, and if they end up being logged, both native Log4perl
and Log::Dispatch appenders can be used to perform the actual logging
job. Created by Mike Schilli and Kevin Goess.

## Log::Dispatch::Config

Written by Tatsuhiko Miyagawa. Allows configuration of logging via a
text file similar (or so I'm told) to how it is done with log4j.
Simpler than Log::Log4perl.

## Log::Agent

A very different API for doing many of the same things that
Log::Dispatch does. Originally written by Raphael Manfredi.

# SEE ALSO

[Log::Dispatch::ApacheLog](https://metacpan.org/pod/Log::Dispatch::ApacheLog), [Log::Dispatch::Email](https://metacpan.org/pod/Log::Dispatch::Email),
[Log::Dispatch::Email::MailSend](https://metacpan.org/pod/Log::Dispatch::Email::MailSend), [Log::Dispatch::Email::MailSender](https://metacpan.org/pod/Log::Dispatch::Email::MailSender),
[Log::Dispatch::Email::MailSendmail](https://metacpan.org/pod/Log::Dispatch::Email::MailSendmail), [Log::Dispatch::Email::MIMELite](https://metacpan.org/pod/Log::Dispatch::Email::MIMELite),
[Log::Dispatch::File](https://metacpan.org/pod/Log::Dispatch::File), [Log::Dispatch::File::Locked](https://metacpan.org/pod/Log::Dispatch::File::Locked),
[Log::Dispatch::Handle](https://metacpan.org/pod/Log::Dispatch::Handle), [Log::Dispatch::Output](https://metacpan.org/pod/Log::Dispatch::Output), [Log::Dispatch::Screen](https://metacpan.org/pod/Log::Dispatch::Screen),
[Log::Dispatch::Syslog](https://metacpan.org/pod/Log::Dispatch::Syslog)

# SUPPORT

Bugs may be submitted at [https://github.com/houseabsolute/Log-Dispatch/issues](https://github.com/houseabsolute/Log-Dispatch/issues).

I am also usually active on IRC as 'autarch' on `irc://irc.perl.org`.

# SOURCE

The source code repository for Log-Dispatch can be found at [https://github.com/houseabsolute/Log-Dispatch](https://github.com/houseabsolute/Log-Dispatch).

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

- Anirvan Chatterjee <anirvan@users.noreply.github.com>
- Carsten Grohmann <mail@carstengrohmann.de>
- Doug Bell <doug@preaction.me>
- Graham Knop <haarg@haarg.org>
- Graham Ollis <plicease@cpan.org>
- Gregory Oschwald <goschwald@maxmind.com>
- hartzell <hartzell@alerce.com>
- Johann Rolschewski <jorol@cpan.org>
- Jonathan Swartz <swartz@pobox.com>
- Karen Etheridge <ether@cpan.org>
- Kerin Millar <kfm@plushkava.net>
- Kivanc Yazan <kivancyazan@gmail.com>
- Konrad Bucheli <kb@open.ch>
- Michael Schout <mschout@gkg.net>
- Olaf Alders <olaf@wundersolutions.com>
- Olivier Mengué <dolmen@cpan.org>
- Rohan Carly <se456@rohan.id.au>
- Ross Attrill <ross.attrill@gmail.com>
- Salvador Fandiño <sfandino@yahoo.com>
- Sergey Leschenko <sergle.ua@gmail.com>
- Slaven Rezic <srezic@cpan.org>
- Steve Bertrand <steveb@cpan.org>
- Whitney Jackson <whitney.jackson@baml.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dave Rolsky.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
`LICENSE` file included with this distribution.
