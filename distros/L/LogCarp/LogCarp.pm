package CGI::LogCarp;

# SCCS INFO: @(#) CGI::LogCarp.pm 1.12 98/08/14
#  RCS INFO: $Id: CGI::LogCarp.pm,v 1.12 1998/08/14 mak Exp $
#
# Copyright (C) 1997,1998 Michael King (mike808@mo.net)
# Saint Louis, MO USA.
#
# This module is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

CGI::LogCarp - Error, log and debug streams, httpd style format

CGI::LogCarp redefines the STDERR stream and allows the definition
of new STDBUG and STDLOG streams in such a way that all messages are
formatted similar to an HTTPD error log.

Methods are defined for directing messages to STDERR, STDBUG, and STDLOG.
Each stream can be directed to its own location independent of the others.

It can be used as a version-compatible drop-in replacement for the
CGI::Carp module.  This means that version 1.10 of CGI::LogCarp provides
the same functionality, usage, and features as at least version 1.10
of CGI::Carp.

=head1 SYNOPSIS

    use CGI::LogCarp qw( :STDBUG fatalsToBrowser );

    print "CGI::LogCarp version: ", CGI::LogCarp::VERSION;
    DEBUGLEVEL 2;

    confess "It was my fault: $!";
    cluck "What's going on here?";

    warn "This is most unusual.";
    carp "It was your fault!";

    croak "We're outta here!";
    die "I'm dying.\n";

    debug "Just for debugging: somevar=", $somevar, "\n";
    logmsg "Just for logging: We're here.\n";
    trace "detail=", $detail, "\n";

    carpout \*ERRFILE;
    debugout \*DEBUGFILE;
    logmsgout \*LOGFILE;

    is_STDOUT(\*ERRFILE)
    is_STDERR(\*LOGFILE)
    is_STDBUG(\*LOGFILE)
    is_STDLOG(\*ERRFILE)

=head1 DESCRIPTION

CGI::LogCarp is a Perl package defining methods for directing
the existing STDERR stream as well as creating and directing
two new messaging streams, STDBUG and STDLOG.

Their use was intended mainly for a CGI development environment,
or where separate facilities for errors, logging, and debugging
output are needed.

This is because CGI scripts have a nasty habit of leaving warning messages
in the error logs that are neither time stamped nor fully identified.
Tracking down the script that caused the error is a pain. Differentiating
debug output or activity logging from actual error messages is a pain.
Logging application activity or producing debugging output are quite different
tasks than (ab)using the server's error log for this purpose.
This module fixes all of these problems.

Replace the usual

    use Carp;

or

    use CGI::Carp;

with

    use CGI::LogCarp;

And the standard C<warn()>, C<die()>, C<croak()>, C<confess()>,
C<cluck()>, and C<carp()> calls will automagically be replaced with methods
that write out nicely time-, process-, program-, and stream- stamped messages
to the STDERR, STDLOG, and STDBUG streams.

The method to generate messages on the new STDLOG stream
is C<logmsg()>. Calls to C<logmsg()> will write out the same nicely
time-, process-, program-, and stream-stamped messages
described above to both the STDLOG and the STDBUG streams.

The process number and the stream on which the message appeared
is embedded in the default message in order to disambiguate multiple
simultaneous executions as well as multiple streams directed
to the same location.

Messages on multiple streams directed to the same location
do not receive multiple copies.

Methods to generate messages on the new STDBUG stream
are C<debug()> and C<trace()>.

=head2 Creating the New Streams

In order to create the new streams, you must name them on the C<use> line.
This is also referred to as importing a symbol. For example:

    use CGI::LogCarp qw( :STDERR :STDLOG :STDBUG );

Note the :STDERR is not really necessary, as it is already defined in perl.
Importing the :STDERR symbol will not generate an error.

By default, the STDLOG stream is duplicated from the STDERR stream,
and the STDBUG stream is duplicated from the STDOUT stream.

=head2 Redirecting Error Messages

By default, error messages are sent to STDERR. Most HTTPD servers
direct STDERR to the server's error log. Some applications may wish
to keep private error logs, distinct from the server's error log, or
they may wish to direct error messages to STDOUT so that the browser
will receive them (for debugging, not for public consumption).

The C<carpout()> method is provided for this purpose.

Because C<carpout()> is not exported by default,
you must import it explicitly by saying:

    use CGI::LogCarp qw( carpout );

Note that for C<carpout()>, the STDERR stream is already defined,
so there is no need to explicitly create it by importing the STDERR symbol.
However,

    use CGI::LogCarp qw( :STDERR );

will not generate an error, and will also import carpout for you.

For CGI programs that need to send something to the HTTPD server's
real error log, the original STDERR stream has not been closed,
it has been saved as _STDERR. The reason for this is twofold.

The first is that your CGI application might really need to write something
to the server's error log, unrelated to your own error log. To do so,
simply write directly to the _STDERR stream.

The second is that some servers, when dealing with CGI scripts,
close their connection to the browser when the script closes
either STDOUT or STDERR. Some consider this a (mis)feature.

Saving the program's initial STDERR in _STDERR is used
to prevent this from happening prematurely.

Do not manipulate the _STDERR filehandle in any other way other than writing
to it.
For CGI applications, the C<serverwarn()> method formats and sends your message
to the HTTPD error log (on the _STDERR stream).

=head2 Redirecting Log Messages

A new stream, STDLOG, can be defined and used for log messages.
By default, STDLOG will be routed to STDERR. Most HTTPD servers
direct STDERR (and thus the default STDLOG also) to the server's error log.
Some applications may wish to keep private activity logs,
distinct from the server's error log, or they may wish to direct log messages
to STDOUT so that the browser will receive them (for debugging,
not for public consumption).

The C<logmsgout()> method is provided for this purpose.

Because C<logmsgout()> is not exported by default,
you must create the STDLOG stream and import them explicitly by saying:

    use CGI::LogCarp qw( :STDLOG );

=head2 Redirecting Debug Messages

A new stream, STDBUG, can be defined and used for debugging messages.
Since this stream is for producing debugging output,
the default STDBUG will be routed to STDOUT. Some applications may wish
to keep private debug logs, distinct from the application output, or
CGI applications may wish to leave debug messages directed to STDOUT
so that the browser will receive them (only when debugging).
Your program may also control the output by manipulating DEBUGLEVEL
in the application.

The C<debugout()> method is provided for this purpose.

Because the C<debugout()> method is not exported by default,
you must create the STDBUG stream and import them explicitly by saying:

    use CGI::LogCarp qw( :STDBUG );

=head2 Redirecting Messages in General

Each of these methods, C<carpout()>, C<logmsgout()>, and C<debugout()>,
requires one argument, which should be a reference to an open filehandle
for writing.
They should be called in a C<BEGIN> block at the top of the application
so that compiler errors will be caught.

This example creates and redirects the STDLOG stream,
as well as redirecting the STDERR stream to a browser,
formatting the error message as an HTML document:

    BEGIN {
        use CGI::LogCarp qw( :STDLOG fatalsToBrowser );
        # fatalsToBrowser doesn't stop messages going to STDERR,
        # rather it replicates them on STDOUT. So we stop them here.
        open(_STDERR,'>&STDERR'); close STDERR;
        open(LOG,">>/var/logs/cgi-logs/mycgi-log")
            or die "Unable to open mycgi-log: $!\n";
        logmsgout \*LOG;
    }

NOTE: C<carpout()>, C<logmsgout()>, and C<debugout()> handle file locking
on systems that support flock so multiple simultaneous CGIs are not an issue.
However, flock might not operate as desired over network-mounted filesystems.

If you want to send errors to the browser, give C<carpout()> a reference
to STDOUT:

   BEGIN {
     use CGI::LogCarp qw( carpout );
     carpout \*STDOUT;
   }

If you do this, be sure to send a Content-Type header immediately --
perhaps even within the BEGIN block -- to prevent server errors.
However, you probably want to take a look at importing the
C<fatalsToBrowser> symbol and closing STDERR instead of doing this.
See the example above on how to do this.

=head2 Passing filehandles

You can pass filehandles to C<carpout()>, C<logmsgout()>, and C<debugout()>
in a variety of ways. The "correct" way according to Tom Christiansen
is to pass a reference to a filehandle GLOB (or if you are using the
FileHandle module, a reference to a anonymous filehandle GLOB):

    carpout \*LOG;

This looks a little weird if you haven't mastered Perl's syntax,
so the following syntaxes are accepted as well:

    carpout(LOG)          -or-  carpout(\LOG)
    carpout('LOG')        -or-  carpout(\'LOG')
    carpout(main::LOG)    -or-  carpout(\main::LOG)
    carpout('main::LOG')  -or-  carpout(\'main::LOG')
    ... and so on

FileHandle and other objects work as well.

Using C<carpout()>, C<logmsgout()>, and C<debugout()>,
is not great for performance, so they are recommended for debugging purposes
or for moderate-use applications. You can also manipulate DEBUGLEVEL
to control the output during the execution of your program.

=head2 Changing the Default Message Formats

By default, the messages sent to the respective streams are formatted
as helpful time-, process-, program-, and stream-stamped messages.

The process number (represented in the example output below as $$)
and the stream on which the message appears are displayed in the default
message format and serve to disambiguate multiple simultaneous executions
as well as multiple streams directed to the same location.

For example:

    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: I'm confused at test.pl line 3.
    [Mon Sep 15 09:04:55 1997] $$ test.pl BUG: answer=42.
    [Mon Sep 15 09:04:55 1997] $$ test.pl LOG: I did something.
    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: Got a warning: Permission denied.
    [Mon Sep 15 09:04:55 1997] $$ test.pl ERR: I'm dying.

You can, however, redefine your own message formats for each stream
if you don't like this one by using the C<set_message()> method.
This is not imported by default; you should import it on the use() line
like thus:

    use CGI::LogCarp qw( fatalsToBrowser set_message );
    # fatalsToBrowser doesn't stop messages going to STDERR,
    # rather it replicates them on STDOUT. So we stop them here.
    open(_STDERR,'>&STDERR'); close STDERR;
    set_message("It's not a bug, it's a feature!");

    use CGI::LogCarp qw( :STDLOG );
    set_message(STDLOG, "Control: I'm here.");

Note the varying syntax for C<set_message()>.

The first parameter, if it is a filehandle, identifies the stream whose
message is being defined. Otherwise it specifies the message for the STDERR
stream. This non-filehandle first parameter form preserves compatibility with
CGI::Carp syntax.

You may also pass in a code reference in order to create a custom
error message. At run time, your code will be called with the text
of the error message that caused the script

    BEGIN {
        use CGI::LogCarp qw( fatalsToBrowser set_message );
        # fatalsToBrowser doesn't stop messages going to STDERR,
        # rather it replicates them on STDOUT. So we stop them here.
        open(_STDERR,'>&STDERR'); close STDERR;
        sub handle_errors {
            my $msg = shift;
            $msg =~ s/\&/&amp;/gs;
            $msg =~ s/</&lt;/gs;
            $msg =~ s/>/&gt;/gs;
            $msg =~ s/"/&quot;/gs;
            join("\n",
                "<h1>Aw shucks</h1>",
                "Got an error:",
                "<pre>", $msg, "</pre>",
            "");
        }
        set_message(\&handle_errors);
    }

In order to correctly intercept compile-time errors, you should
call C<set_message()> from within a C<BEGIN> block.

=head2 Making perl Errors Appear in the Browser Window

If you want to send fatal (C<die> or C<confess>) errors to the browser,
ask to import the special C<fatalsToBrowser> symbol:

    BEGIN {
        use CGI::LogCarp qw( fatalsToBrowser );
        # fatalsToBrowser doesn't stop messages going to STDERR,
        # rather it replicates them on STDOUT. So we stop them here.
        open(_STDERR,'>&STDERR'); close STDERR;
    }
    die "Bad error here";

Fatal errors will now be sent to the browser. Any messages sent to the
STDERR stream are now I<also> reproduced on the STDOUT stream.
Using C<fatalsToBrowser> also causes CGI::LogCarp to define a new message
format that arranges to send a minimal HTTP header and HTML document to the
browser so that even errors that occur early in the compile phase will be
shown. Any fatal (C<die>) and nonfatal (C<warn>) messages are I<still> produced
on the STDERR stream. They just also go to STDOUT.

Certain web servers (Netscape) also send CGI STDERR output to the browser.
This causes a problem for CGI's because the STDERR stream is not buffered,
and thus if something gets sent to the STDERR stream before the normal
document header is produced, the browser will get very confused.

The following line solves this problem. See above for examples with context.

    open(_STDERR,'>&STDERR'); close STDERR;

=head2 Changing the fatalsToBrowser message format or document

The default message generated by C<fatalsToBrowser> is not the normal
C<LogCarp> logging message, but instead displays the error message followed by
a short note to contact the Webmaster by e-mail with the time and date of the
error. You can use the C<set_message()> method to change it as described above.

The default message generated on the STDLOG and STDBUG streams is formatted
differently, and is as described earlier.

=head2 What are the Carp methods?

The Carp methods that are replaced by CGI::LogCarp are useful in your
own modules, scripts, and CGI applications because they act like C<die()>
or C<warn()>, but report where the error was in the code they were called from.
Thus, if you have a routine C<Foo()> that has a C<carp()> in it,
then the C<carp()> will report the error as occurring where C<Foo()> was
called, not where C<carp()> was called.

=head2 Forcing a Stack Trace

As a debugging aid, you can force C<LogCarp> to treat a C<croak>
as a C<confess> and a C<carp> as a C<cluck> across I<all> modules.
In other words, force a detailed stack trace to be given.
This can be very helpful when trying to understand why, or from where,
a warning or error is being generated.

This feature is enabled by 'importing' the non-existant symbol
'verbose'. You would typically enable it on the command line by saying:

    perl -MCGI::LogCarp=verbose script.pl

or by including the string C<MCGI::LogCarp=verbose> in the C<PERL5OPT>
environment variable.

You would typically enable it in a CGI application by saying:

    use CGI::LogCarp qw( verbose );

Or, during your program's run by saying:

    CGI::LogCarp::import( 'verbose' );

and calling C<CGI::LogCarp>'s import function directly.

NOTE: This is a feature that is in Carp but apparently was not
implemented in CGI::Carp (as of v1.10).

=head1 METHODS

Unless otherwise stated all methods return either a true or false value,
with true meaning that the operation was a success.
When a method states that it returns a value,
failure will be returned as undef or an empty list.

=head2 Streams and their methods

The following methods are for generating a message on the respective stream:

    The  STDERR stream: warn() and die()
    The  STDLOG stream: logmsg()
    The  STDBUG stream: debug() and trace()
    The _STDERR stream: serverwarn()

The following methods are for generating a message on the respective stream,
but will indicate the message location from the caller's perspective.
See the standard B<Carp.pm> module for details.

    The STDERR stream: carp(), croak(), cluck() and confess()

The following methods are for manipulating the respective stream:

    The STDERR stream: carpout()
    The STDLOG stream: logmsgout()
    The STDBUG stream: debugout()

The following methods are for manipulating the amount (or level)
of output filtering on the respective stream:

    The STDBUG stream: DEBUGLEVEL()
    The STDLOG stream: LOGLEVEL()

The following method defines the format of messages directed to a stream.
Often used by and/or in conjunction with C<fatalsToBrowser>:

    set_message()

=head2 Exported Package Methods

By default, the only methods exported into your namespace are:

    warn, die, carp, croak, confess, and cluck

When you import the :STDBUG tag, these additional symbols are exported:

    *STDBUG, debugmsgout, debug, trace, and DEBUGLEVEL

When you import the :STDLOG tag, these additional symbols are exported:

    *STDLOG, logmsgout, logmsg and LOGLEVEL

When you import the :STDERR tag, these additional symbols are exported:

    carpout

These additional methods are not exported by default, and must be named:

    carpout, logmsgout, debugout, set_message

The following are pseudo-symbols, in that they change the way CGI::LogCarp
works, but to not export any symbols in and of themselves.

    verbose, fatalsToBrowser

=head2 Internal Package Methods

The following methods are not exported but can be accessed directly
in the CGI::LogCarp package.

The following methods are for comparing a filehandle to the respective stream:

    is_STDOUT()
    is_STDERR()
    is_STDBUG()
    is_STDLOG()
    is_realSTDERR()

Each is explained in its own section below.

=head2 Exported Package Variables

No variables are exported into the caller's namespace.
However, the STDLOG and STDBUG streams are defined using typeglobs
in the C<main> namespace.

=head2 Internal Package Variables

=over

=item $DEBUGLEVEL

A number indicating the level of debugging output that is to occur.
At each increase in level, additional debugging output is allowed.

Currently three levels are defined:

    0 - No messages are output on the STDBUG stream.
    1 - debug() messages are output on the STDBUG stream.
    2 - debug() and trace() messages are output on the STDBUG stream.

It is recommended to use the DEBUGLEVEL method to get/set this value.

=item $LOGLEVEL

A number indicating the level of logging output that is to occur.
At each increase in level, additional logging output is allowed.

Currently two levels are defined:

    0 - No messages are output on the STDLOG stream.
    1 - logmsg() messages are output on the STDLOG stream.

It is recommended to use the LOGLEVEL method to get/set this value.

=back

=head1 RETURN VALUE

The value returned by executing the package is 1 (or true).

=head1 ENVIRONMENT

=head1 FILES

=head1 ERRORS

=head1 WARNINGS

Operation on Win32 platforms has not been tested.

CGI::Carp has some references to a C<wrap> import symbol,
which appears to be an alternate name for C<fatalsToBrowser>.
Internal comments refer to errorWrap. Since this is poorly
documented, I am speculating this is legacy and/or previous
implementation coding, and as such, have chosen not implement
the C<wrap> symbol import in C<CGI::LogCarp>. If some massively
popular module(s) I am currently unaware of is/are indeed using
this undocumented interface, please let me know.

=head1 DIAGNOSTICS

See importing the C<verbose> pseudo-symbol in B<Forcing a Stack Trace>.

=head1 BUGS

Check out what's left in the TODO file.

=head1 RESTRICTIONS

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 CPAN DEPENDENCIES

=head1 LOCAL DEPENDENCIES

=head1 SEE ALSO

Carp, CGI::Carp

=head1 NOTES

carpout(), debugout(), and logmsgout() now perform file locking.

I've attempted to track the features in C<CGI::LogCarp> to the features in
the C<CGI::Carp> module by Lincoln Stein. The version number of C<CGI::LogCarp>
corresponds to the highest version of C<CGI::Carp> module that this module
replicates all features and functionality. Thus version 1.10 of C<CGI::LogCarp>
can be used as a drop-in replacement for versions 1.10 or lower of C<CGI::Carp>.

Due to the implementation of the Symbol.pm module, I have no choice but to
replace it with a version that supports extending the list of "global"
symbols. It is part of the CGI::LogCarp distribution.

For speed reasons, the autoflush method is implemented here instead of
pulling in the entire FileHandle module.

=head1 ACKNOWLEDGEMENTS

Based heavily on the C<CGI::Carp> module by Lincoln D. Stein ( lstein@genome.wi.mit.edu ).
Thanks to Andy Wardley ( abw@kfs.org ) for commenting the original C<Carp.pm>
module.

Thanks to Michael G Schwern ( schwern@starmedia.net ) for the constructive input.

=head1 AUTHORZ<>(S)

mak - Michael King ( mike808@mo.net )

=head1 HISTORY

 CGI::LogCarp.pm
 v1.01 09/15/97 mak
 v1.12 08/14/98 mak

=head1 CHANGE LOG

 1.05 first posting to CPAN
 1.12 major revision, tracking CGI::Carp

=head1 MODIFICATIONS

=head1 COPYRIGHT

 Copyright (C) 1997,1998 Michael King ( mike808@mo.net )
 Saint Louis, MO USA.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This module is copyright (c) 1997,1998 by Michael King ( mike808@mo.net ) and is
made available to the Perl public under terms of the Artistic License used to
cover Perl itself. See the file Artistic in the distribution  of Perl 5.002 or
later for details of copy and distribution terms.

=head1 AVAILABILITY

The latest version of this module is likely to be available from:

 http://walden.mo.net/~mike808/LogCarp

The best place to discuss this code is via email with the author.

=cut

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Play nice
require 5.004;
use strict;

# The package name
package CGI::LogCarp;

# Define external interface
use vars qw( @ISA @EXPORT @EXPORT_OK @EXPORT_FAIL %EXPORT_TAGS );
use Exporter;

# Inherit normal import/export mechanism from Exporter
@ISA = qw( Exporter );

# Always exported into caller namespace
@EXPORT = qw( *STDERR confess croak carp cluck );

# Externally visible if specified
@EXPORT_OK = qw(
    logmsg trace debug
    carpout logmsgout debugout
    serverwarn
    DEBUGLEVEL LOGLEVEL
    is_STDOUT is_STDERR is_STDBUG is_STDLOG is_realSTDERR
    set_message
    *STDBUG *STDLOG
);

# Export Tags
%EXPORT_TAGS = (
    'STDBUG' => [ qw( *STDBUG debug trace debugout DEBUGLEVEL ), @EXPORT ],
    'STDLOG' => [ qw( *STDLOG logmsg logmsgout LOGLEVEL ), @EXPORT ],
    'STDERR' => [ qw( *STDERR carpout ), @EXPORT ],
);

# Hook for psuedo-symbols (or modes)
@EXPORT_FAIL = qw( verbose *STDERR *STDLOG *STDBUG );
push @EXPORT_FAIL, qw( fatalsToBrowser ); # from CGI::Carp
push @EXPORT_OK, @EXPORT_FAIL;

sub export_fail {
    MODE: {
        shift;
        last MODE unless scalar @_;
        if ($_[0] eq 'verbose') {
            Carp->import($_[0]); # Let Carp know what's going on
            redo MODE;
        } elsif ($_[0] eq '*STDLOG') { # Create the STDLOG stream
            unless ($CGI::LogCarp::STDLOG) {
                open(CGI::LogCarp::STDLOG,'>&STDERR')
                    or realdie("Could not create STDLOG stream: $!");
                $CGI::LogCarp::STDLOG = $CGI::LogCarp::STDLOG = 1;
                #Symbol::add_global('STDLOG');
            }
            redo MODE;
        } elsif ($_[0] eq '*STDBUG') { # Create the STDBUG stream
            unless ($CGI::LogCarp::STDBUG) {
                open(CGI::LogCarp::STDBUG,'>&STDOUT')
                    or realdie("Could not create STDBUG stream: $!");
                $CGI::LogCarp::STDBUG = $CGI::LogCarp::STDBUG = 1;
                #Symbol::add_global('STDBUG');
            }
            redo MODE;
        } elsif ($_[0] eq '*STDERR') { # Create the STDERR stream
            unless (fileno(\*CGI::LogCarp::STDERR)) {
                open(CGI::LogCarp::STDERR,'>&STDERR') or realdie();
                $CGI::LogCarp::STDERR = $CGI::LogCarp::STDERR = 1;
            }
            redo MODE;
        } elsif ($_[0] eq 'fatalsToBrowser') { # Turn it on
            $CGI::LogCARP::fatalsToBrowser = 1;
            redo MODE;
        }
    }
    return @_;
}

# Standard packages
BEGIN { require Carp; } # We *DON'T* want to import Carp's symbols

# CPAN packages

# Local packages
use Symbol; # 1.0201; # Make sure we are using the new one
use SelectSaver;   # This must be *after* use Symbol 1.0201

# Package Version
$CGI::LogCarp::VERSION = "1.12";
sub VERSION () { $CGI::LogCarp::VERSION; };

# Constants

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Compile-time initialization code
BEGIN {
    # Save the real STDERR
    open(main::_STDERR,'>&STDERR') or realdie();
    #Symbol::add_global("_STDERR");
    # Alias STDERR to ours
    #*STDERR = *main::STDERR;
}

# Initialize the debug level (ON)
$CGI::LogCarp::DEBUGLEVEL = 1;

# Initialize the log level (ON)
$CGI::LogCarp::LOGLEVEL = 1;

# Initialize fatalsToBrowser flag (OFF)
$CGI::LogCARP::fatalsToBrowser = 0;
# Does Lincoln Stein use this elsewhere? What's wrap and errorWrap?

# Initialize to default fatalsToBrowser message
$CGI::LogCarp::CUSTOM_STDERR_MSG = undef;
$CGI::LogCarp::CUSTOM_STDBUG_MSG = undef;
$CGI::LogCarp::CUSTOM_STDLOG_MSG = undef;

# Grab Perl's signal handlers
# Note: Do we want to stack ours on top of whatever was there?
$main::SIG{'__WARN__'} = \&CGI::LogCarp::warn;
$main::SIG{'__DIE__'}  = \&CGI::LogCarp::die;

# Take over top-level definitions
# Not sure if we need this anymore with new Symbol.pm - mak
if ($CGI::LogCarp::STDLOG) {
    *main::logmsg = *main::logmsg = \&CGI::LogCarp::logmsg;
}
if ($CGI::LogCarp::STDBUG) {
    *main::debug  = *main::debug  = \&CGI::LogCarp::debug;
    *main::trace  = *main::trace  = \&CGI::LogCarp::trace;
}

# Predeclare and prototype our methods
sub stamp ($);
sub lock (*);
sub unlock (*);
sub streams_are_equal (**);
sub is_STDOUT (*);
sub is_STDERR (*);
sub is_STDLOG (*);
sub is_STDBUG (*);
sub is_realSTDERR (*);
sub realdie (@);
sub realwarn (@);
sub realbug (@);
sub reallog (@);
sub realserverwarn (@);
sub DEBUGLEVEL (;$);
sub LOGLEVEL (;$);
sub warn (@);
sub die (@);
sub logmsg (@);
sub debug (@);
sub trace (@);
sub serverwarn (@);
sub carp;
sub croak;
sub confess;
sub cluck;
sub carpout (;*);
sub logmsgout (;*);
sub debugout (;*);
sub autoflush (*);
sub to_filehandle;
sub set_message;

# These are private aliases for various "levels"
# Alter these to your language/dialect if you'd like
my $NO    = [ qw( no  false off ) ];
my $YES   = [ qw( yes true  on  ) ];
my $TRACE = [ qw( trace tracing ) ];

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head1 PACKAGE PUBLIC METHODS

=head2 DEBUGLEVEL $LEVEL

DEBUGLEVEL is a normal get/set method.

When the scalar argument LEVEL is present, the DEBUGLEVEL will be set to LEVEL.
LEVEL is expected to be numeric, with the following case-insensitive
character-valued translations:

 NO,  FALSE, and OFF all equate to a value of 0 (ZERO).
 YES, TRUE,  and ON  all equate to a value of 1 (ONE).
 TRACE or TRACING equate to a value of 2 (TWO).

 Values in scientific notation equate to their numeric equivalent.

NOTE:

    All other character values of LEVEL equate to 0 (ZERO). This
will have the effect of turning off debug output.

After this translation to a numeric value is performed,
the DEBUGLEVEL is set to LEVEL.

Whenever the DEBUGLEVEL is set to a non-zero value (i.e. ON or TRACE),
the LOGLEVEL will be also set to 1 (ONE).

The value of DEBUGLEVEL is then returned to the caller,
whether or not LEVEL is present.

=cut

sub DEBUGLEVEL (;$)
{
    my ($value) = shift;
    if (defined $value)
    {
        # Allow the usual non-numeric values
        $value = 0 if scalar grep { m/^$value$/i } @$NO;
        $value = 1 if scalar grep { m/^$value$/i } @$YES;
        $value = 2 if scalar grep { m/^$value$/i } @$TRACE;

        # Coerce to numeric - note scientific notation is OK
        $CGI::LogCarp::DEBUGLEVEL = 0 + $value;

        # Also turn on logging if we are debugging
        LOGLEVEL(1) if ($CGI::LogCarp::DEBUGLEVEL
            and not $CGI::LogCarp::LOGLEVEL);
    }
    $CGI::LogCarp::DEBUGLEVEL;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 LOGLEVEL $LEVEL

LOGLEVEL is a normal get/set method.

When the scalar argument LEVEL is present, the LOGLEVEL will be set to LEVEL.
LEVEL is expected to be numeric, with the following case-insensitive
character-valued translations:

 NO,  FALSE, and OFF all equate to a value of 0 (ZERO).
 YES, TRUE,  and ON  all equate to a value of 1 (ONE).

 Values in scientific notation equate to their numeric equivalent.

NOTE:

    All other character values of LEVEL equate to 0 (ZERO). This
will have the effect of turning off log output.

After this translation to a numeric value is performed,
the LOGLEVEL is set to LEVEL.

The value of LOGLEVEL is then returned to the caller,
whether or not LEVEL is present.

=cut

sub LOGLEVEL (;$)
{
    my ($value) = shift;
    if (defined $value)
    {
        # Allow the usual non-numeric values
        $value = 0 if scalar grep { m/^$value$/i } @$NO;
        $value = 1 if scalar grep { m/^$value$/i } @$YES;

        # Coerce to numeric - note scientific notation is OK
        $CGI::LogCarp::LOGLEVEL = 0 + $value;
    }
    $CGI::LogCarp::LOGLEVEL;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 warn @message

This method is a replacement for Perl's builtin C<warn()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub warn (@)
{
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "ERR";
    $message =~ s/^/$stamp/gm;

    if ($CGI::LogCarp::STDBUG) {
        realbug $message unless is_STDERR \*main::STDBUG;
    }
    if ($CGI::LogCarp::STDLOG) {
        reallog $message unless (
            is_STDERR(\*main::STDLOG)
            or
            is_STDBUG(\*main::STDLOG)
        );
    }
    realwarn $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 die @message

This method is a replacement for Perl's builtin C<die()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub die (@)
{
    my $message = join "", @_; # Flatten the list
    my $time = scalar localtime;
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    fatalsToBrowser($message) if (
        $CGI::LogCARP::fatalsToBrowser
        and
        CGI::LogCarp::_longmess() !~ /eval [{']/m
    );
    my $stamp = stamp "ERR";
    $message =~ s/^/$stamp/gm;

    if ($CGI::LogCarp::STDBUG) {
        realbug $message unless is_STDERR \*main::STDBUG;
    }
    if ($CGI::LogCarp::STDLOG) {
        reallog $message unless (
            is_STDERR(\*main::STDLOG)
            or
            is_STDBUG(\*main::STDLOG)
        );
    }
    realdie $message;
}

# The mod_perl package Apache::Registry loads CGI programs by calling eval.
# These evals don't count when looking at the stack backtrace.
# I've also allowed Netscape::Registry this functionality.
# You're welcome, Ben Sugars, nsapi_perl author. :)

sub _longmess {
    my $message = Carp::longmess();
    my $mod_perl = (
        $ENV{'GATEWAY_INTERFACE'} 
        and
        $ENV{'GATEWAY_INTERFACE'} =~ /^CGI-Perl\//
    );
    $message =~ s,eval[^\n]+(Apache|Netscape)/Registry\.pm.*,,s if $mod_perl;
    return( $message );    
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Take over carp(), croak(), confess(), and cluck();
# We never imported them from Carp, so we're ok

=head2 carp @message

This method is a replacement for C<Carp::carp()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

# mak - this fixes a problem when you passed Carp::carp a list
# like the documentation says ( shortmess uses $_[0] and not @_ ).
# This has been fixed in later (post-1997) versions of Carp.pm.
# Since Carp.pm has no version, I can't tell which one you have.

=cut

sub carp
{
    CGI::LogCarp::warn( Carp::shortmess(join("",@_)) );
}

=head2 croak @message

This method is a replacement for C<Carp::croak()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

# mak - this fixes a problem when you passed Carp::croak a list
# like the documentation says ( shortmess uses $_[0] and not @_ ).
# This has been fixed in later (post-1997) versions of Carp.pm.
# Since Carp.pm has no version, I can't tell which one you have.

=cut

sub croak
{
    CGI::LogCarp::die( Carp::shortmess(join("",@_)) );
}

=head2 confess @message

This method is a replacement for C<Carp::confess()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub confess
{ 
    CGI::LogCarp::die( Carp::longmess(join("",@_)) );
}

=head2 cluck @message

This method is a replacement for C<Carp::cluck()>.
The message is sent to the STDERR, STDLOG, and STDBUG streams.

=cut

sub cluck
{
    CGI::LogCarp::warn( Carp::longmess(join("",@_)) );
}

=head2 set_message $message

=head2 set_message FILEHANDLE $message

This method is a replacement for the CGI::Carp method of the same name.
It defines the message format for the STDERR stream if FILEHANDLE is
not specified. FILEHANDLE specifies which stream is having its message
redefined. C<$message> is typically a reference to a subroutine.

=cut

sub set_message
{
    my $message = shift;
    # CGI::Carp compatibility
    unless (scalar @_) {
        $CGI::LogCarp::CUSTOM_STDERR_MSG = $message;
        return $message;
    }

    my $fh = $message;
    $message = shift;
    if (is_STDERR $fh) {
        $CGI::LogCarp::CUSTOM_STDERR_MSG = $message;
    } elsif (is_STDLOG $fh) {
        $CGI::LogCarp::CUSTOM_STDLOG_MSG = $message;
    } elsif (is_STDBUG $fh) {
        $CGI::LogCarp::CUSTOM_STDBUG_MSG = $message;
    }
    return $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 logmsg @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDLOG and STDBUG streams.

=cut

sub logmsg (@)
{
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "LOG";
    $message =~ s/^/$stamp/gm;

    if ($CGI::LogCarp::STDBUG) {
        realbug $message unless is_STDLOG \*main::STDBUG;
    }
    reallog $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 debug @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDBUG stream when DEBUGLEVEL > 0.

=cut

sub debug (@)
{
    return unless DEBUGLEVEL > 0;
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "BUG";
    $message =~ s/^/$stamp/gm;

    realbug $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 trace @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDBUG stream
when DEBUGLEVEL is greater than one.

=cut

sub trace (@)
{
    return unless DEBUGLEVEL > 1;
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "TRC";
    $message =~ s/^/$stamp/gm;

    realbug $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 serverwarn @message

This method operates similarly to the C<warn()> method.
The message is sent to the STDBUG, STDLOG, STDERR and _STDERR streams.
The _STDERR stream is typically is sent to a webserver's error log
if used in a CGI program.

=cut

sub serverwarn (@)
{
    my $message = join "", @_; # Flatten the list
    my ($file,$line) = id(1);
    $message .= " at $file line $line.\n" unless $message =~ /\n$/;
    my $stamp = stamp "SRV";
    $message =~ s/^/$stamp/gm;

    if ($CGI::LogCarp::STDBUG) {
        realbug $message unless (
            is_STDERR(\*main::STDBUG)
            or
            is_realSTDERR(\*main::STDBUG)
            );
    }
    if ($CGI::LogCarp::STDLOG) {
        reallog $message unless (
            is_STDERR(\*main::STDLOG)
            or
            is_STDBUG(\*main::STDLOG)
            or
            is_realSTDERR(\*main::STDLOG)
        );
    }
    realwarn $message unless is_realSTDERR \*STDERR;
    realserverwarn $message;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 carpout FILEHANDLE

A method to redirect the STDERR stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on B<REDIRECTING ERROR MESSAGES>
and the section on B<REDIRECTING MESSAGES IN GENERAL>.

=cut

sub carpout (;*)
{
    my ($fh) = shift || \*STDERR;
    $fh = to_filehandle($fh) or realdie "Invalid filehandle $fh\n";
    if (is_STDERR $fh) {
        open(STDERR,'>&main::_STDERR')
            or realdie "Unable to redirect STDERR: $!\n";
    } else {
        my $no = fileno($fh) or realdie "Invalid filehandle $fh\n";
        open(STDERR,'>&'.$no)
            or realdie "Unable to redirect STDERR: $!\n";
    }
    autoflush \*STDERR;
    \*STDERR;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 logmsgout FILEHANDLE

A method to redirect the STDLOG stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on B<REDIRECTING ERROR MESSAGES>
and the section on B<REDIRECTING MESSAGES IN GENERAL>.

=cut

sub logmsgout (;*)
{
    my ($fh) = shift || \*main::STDLOG;
    $fh = to_filehandle($fh) or realdie "Invalid filehandle $fh\n";
    if (is_STDLOG $fh) {
        open(main::STDLOG,'>&main::_STDERR')
            or realdie "Unable to redirect STDLOG: $!\n";
    } else {
        my $no = fileno($fh) or realdie "Invalid filehandle $fh\n";
        open(main::STDLOG,'>&'.$no)
            or realdie "Unable to redirect STDLOG: $!\n";
    }
    autoflush \*main::STDLOG;
    \*main::STDLOG;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 debugout FILEHANDLE

A method to redirect the STDBUG stream to the given FILEHANDLE.
It accepts FILEHANDLE as a reference or a string.

See the section on B<REDIRECTING ERROR MESSAGES>
and the section on B<REDIRECTING MESSAGES IN GENERAL>.

=cut

sub debugout (;*)
{
    my ($fh) = shift || \*main::STDBUG;
    $fh = to_filehandle($fh) or realdie "Invalid filehandle $fh\n";
    if (is_STDBUG $fh) {
        open(main::STDBUG,'>&STDOUT')
            or realdie "Unable to redirect STDBUG: $!\n";
    } else {
        my $no = fileno($fh) or realdie "Invalid filehandle $fh\n";
        open(main::STDBUG,'>&'.$no)
            or realdie "Unable to redirect STDBUG: $!\n";
    }
    autoflush \*main::STDBUG;
    \*main::STDBUG;
}

sub fatalsToBrowser
{
    my ($msg) = @_;
    $msg =~ s/&/&amp;/gs;
    $msg =~ s/>/&gt;/gs;
    $msg =~ s/</&lt;/gs;
    $msg =~ s/\"/&quot;/gs;
    my ($wm) = $ENV{'SERVER_ADMIN'} ?
        qq[the webmaster (<a href="mailto:$ENV{SERVER_ADMIN}">$ENV{'SERVER_ADMIN'}</a>)] :
        "this site's webmaster";
    my ($outer_message) = <<END;
For help, please send mail to $wm, giving this error message
and the time and date of the error.
END

    print STDOUT "Content-type: text/html\013\010";
    if ($CGI::LogCarp::CUSTOM_STDERR_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDERR_MSG) eq "CODE") {
            print STDOUT &{$CGI::LogCarp::CUSTOM_STDERR_MSG}($msg);
            return;
        } else {
            $outer_message = $CGI::LogCarp::CUSTOM_STDERR_MSG;
        }
    }
    print STDOUT <<END;
<H1>Software Error:</h1>
<PRE>$msg</PRE>
<P>
$outer_message
END

}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 to_filehandle EXPR

Borrowed directly from CGI.pm by Lincoln Stein.
It converts EXPR to a filehandle.

=cut

sub to_filehandle
{
    my ($thingy) = shift;
    return undef unless $thingy;
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');
    if (!ref($thingy)) {
        my $caller = 1;
        while (my $package = caller($caller++)) {
            my ($tmp) = $thingy =~ m/[\':]/ ? $thingy : "$package\:\:$thingy";
            return $tmp if defined fileno($tmp);
        }
    }
    return undef;
}

=head2 is_STDOUT FILEHANDLE

This method compares FILEHANDLE with the STDOUT stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDOUT (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*STDOUT;
}

=head2 is_STDERR FILEHANDLE

This method compares FILEHANDLE with the STDERR stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDERR (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*STDERR;
}

=head2 is_STDBUG FILEHANDLE

This method compares FILEHANDLE with the STDBUG stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDBUG (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDBUG;
}

=head2 is_STDLOG FILEHANDLE

This method compares FILEHANDLE with the STDLOG stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_STDLOG (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::STDLOG;
}

=head2 is_realSTDERR FILEHANDLE

This method compares FILEHANDLE with the _STDERR stream
and returns the boolean result.

This method is not exported by default.

=cut

sub is_realSTDERR (*)
{
    my ($stream) = shift;
    streams_are_equal $stream, \*main::_STDERR;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head1 PRIVATE METHODS

=cut

# Locks are fine grained
# Do we need a higher level lock/unlock around a block of messages?
# e.g.: lock \*STDLOG; iterated_log_writes @lines; unlock \*STDLOG;

# These are the originals

=head2 realwarn @MESSAGE

This private method encapsulates Perl's underlying C<warn()> method,
actually producing the message on the STDERR stream.
Locking is performed to ensure exclusive access while appending.

This method is not exportable.

=cut

sub realwarn (@)
{
    my $msg = join("",@_);
    if ($CGI::LogCarp::CUSTOM_STDERR_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDERR_MSG) eq "CODE") {
            $msg = &{$CGI::LogCarp::CUSTOM_STDERR_MSG}($msg);
        }
    }
    lock    \*STDERR;
    print { \*STDERR } $msg;
    unlock  \*STDERR;
}

=head2 realdie @MESSAGE

This private method encapsulates Perl's underlying C<die()> method,
actually producing the message on the STDERR stream and then terminating
execution.
Locking is performed to ensure exclusive access while appending.

This method is not exportable.

=cut

sub realdie (@)
{
    my $msg = join("",@_);
    if ($CGI::LogCarp::CUSTOM_STDERR_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDERR_MSG) eq "CODE") {
            $msg = &{$CGI::LogCarp::CUSTOM_STDERR_MSG}($msg);
        }
    }
    lock    \*STDERR;
    print { \*STDERR } $msg;
    unlock  \*STDERR;
    CORE::die $msg; # This still goes to the original STDERR ... why?
    # my perl is 5.004_01 on BSD/OS 2.1 if that helps anyone
}

# The OS *should* unlock the stream as the process ends, but ...
END { unlock \*STDERR; }

=head2 reallog @MESSAGE

This private method synthesizes an underlying C<logmsg()> method,
actually producing the message on the STDLOG stream.
Locking is performed to ensure exclusive access while appending.
The message will only be sent when LOGLEVEL is greater than zero.

This method is not exportable.

=cut

sub reallog (@)
{
    return unless LOGLEVEL > 0;
    my $msg = join("",@_);
    if ($CGI::LogCarp::CUSTOM_STDLOG_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDLOG_MSG) eq "CODE") {
            $msg = &{$CGI::LogCarp::CUSTOM_STDLOG_MSG}($msg);
        }
    }
    lock    \*main::STDLOG;
    print { \*main::STDLOG } $msg;
    unlock  \*main::STDLOG;
}

=head2 realbug @message

This private method synthesizes an underlying C<debug()> method,
actually producing the message on the STDBUG stream.
Locking is performed to ensure exclusive access while appending.
The message will only be sent when DEBUGLEVEL is greater than zero.

This method is not exportable.

=cut

sub realbug (@)
{
    return unless DEBUGLEVEL > 0;
    my $msg = join("",@_);
    if ($CGI::LogCarp::CUSTOM_STDBUG_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDBUG_MSG) eq "CODE") {
            $msg = &{$CGI::LogCarp::CUSTOM_STDBUG_MSG}($msg);
        }
    }
    lock    \*main::STDBUG;
    print { \*main::STDBUG } $msg;
    unlock  \*main::STDBUG;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 realserverwarn @message

This private method synthesizes an underlying C<serverwarn()> method,
actually producing the message on the _STDERR stream.
Locking is performed to ensure exclusive access while appending.
This stream is typically directed to the webserver's error log
if used in a CGI program.

This method is not exportable.

=cut

sub realserverwarn (@)
{
    my $msg = join("",@_);
    if ($CGI::LogCarp::CUSTOM_STDERR_MSG) {
        if (ref($CGI::LogCarp::CUSTOM_STDERR_MSG) eq "CODE") {
            $msg = &{$CGI::LogCarp::CUSTOM_STDERR_MSG}($msg);
        }
    }
    lock    \*main::_STDERR;
    print { \*main::_STDERR } $msg;
    unlock  \*main::_STDERR;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 id $level

This private method returns the file, line, and basename
of the currently executing function.

This method is not exportable.

=cut

sub id ($)
{
    my ($level) = shift;
    my ($pack, $file,$line, $sub) = caller $level;
    return ($file,$line);
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 stamp $stream_id

A private method to construct a normalized timestamp prefix for a message.

This method is not exportable.

=cut

sub stamp ($)
{
    my ($stream_id) = shift;
    my $time = scalar localtime;
    my $process = sprintf("%6d",$$);
    my $frame = 0;
    my ($id,$pkg,$file);
    do {
        $id = $file;
        ($pkg,$file) = caller $frame++;
    } until !$file;
    ($id) = $id =~ m|([^/]+)$|;
    return "[$time] $process $id $stream_id: ";
}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

=head2 streams_are_equal FILEHANDLE, FILEHANDLE

This private method compares two FILEHANDLE streams to each other
and returns the boolean result.

This method is not exportable.

Note: This function is probably not portable to non-Unix-based
operating systems (i.e. NT, VMS, etc.).

=cut

sub streams_are_equal (**)
{
    my ($fh1,$fh2) = @_;
    $fh1 = to_filehandle($fh1) or realdie "Invalid filehandle $fh1\n";
    $fh2 = to_filehandle($fh2) or realdie "Invalid filehandle $fh2\n";
    my $fno1 = fileno($fh1);
    my $fno2 = fileno($fh2);
    return 1 unless (defined $fno1 or defined $fno2); # true if both undef
    return unless (defined $fno1 and defined $fno2);  # undef if one is undef
    my ($device1,$inode1) = stat $fh1;
    my ($device2,$inode2) = stat $fh2;
    ( $device1 == $device2 and $inode1 == $inode2 );
}

# --- END OF PAGE ---#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Some flock-related globals for lock/unlock
use Fcntl qw( /^LOCK_/ );
use POSIX qw( /^SEEK_/ );

=head2 lock FILEHANDLE

A private method that uses Perl's builtin C<flock()> and C<seek()>
to obtain an exclusive lock on the stream specified by FILEHANDLE.
A lock is only attempted on actual files that are writeable.

This method is not exportable.

=cut

sub lock (*)
{
    my ($fh) = shift;
    $fh = to_filehandle($fh) or realdie "Invalid filehandle $fh\n";
    my $no = fileno($fh) or return;
    return unless ( -f $fh and -w _ );
    flock $fh, LOCK_EX;
    # Just in case someone appended while we weren't looking...
    seek $fh, 0, SEEK_END;
}

=head2 unlock FILEHANDLE

A private method that uses Perl's builtin C<flock()>
to release any exclusive lock on the stream specified by FILEHANDLE.
An unlock is only attempted on actual files that are writeable.

This method is not exportable.

=cut

sub unlock (*)
{
    my ($fh) = shift;
    $fh = to_filehandle($fh) or realdie "Invalid filehandle $fh\n"; 
    my $no = fileno($fh) or return;
    return unless ( -f $fh and -w _ );
    flock $fh, LOCK_UN;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Right out of IO::Handle 5.005_01

# This is the only method we need from FileHandle
sub autoflush (*)
{
    my $old = SelectSaver->new(qualify($_[0],caller)) if ref($_[0]);
    my $prev = $|;
    $| = @_ > 1 ? $_[1] : 1;
    $prev;
}

# --- END OF PAGE ---^L#- - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End of CGI::LogCarp.pm
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
1;
