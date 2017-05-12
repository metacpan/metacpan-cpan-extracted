###########################################################################
#
#   Agent.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
###########################################################################

use strict;
require Exporter;

########################################################################
package Log::Agent;

use vars qw($Driver $Prefix $Trace $Debug $Confess
	$OS_Error $AUTOLOAD $Caller $Priorities $Tags $DATUM %prio_cache);

use AutoLoader;
use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA = qw(Exporter);
@EXPORT = qw(
	logconfig
	logconfess logcroak logcarp logxcroak logxcarp
	logsay logerr logwarn logdie logtrc logdbg
);
@EXPORT_OK = qw(
	logwrite logtags
);

use Log::Agent::Priorities qw(:LEVELS priority_level level_from_prio);
use Log::Agent::Formatting qw(tag_format_args);

our $VERSION = '1.001';
$VERSION = eval $VERSION;

$Trace = NOTICE;	# Default tracing
$OS_Error = '';         # Data stash for the $! value

sub AUTOLOAD {
    ${Log::Agent::OS_Error} = $!;       # for safe-keeping, the braces
                                        # prevent CVS substitution
    $AutoLoader::AUTOLOAD = $AUTOLOAD;
    goto &AutoLoader::AUTOLOAD;
}

1;
__END__

#
# logconfig
#
# Configure the logging system at the application level. By default, logging
# uses the Log::Agent::Driver::Default driver.
#
# Available options (case insensitive):
#
#   -PREFIX   => string           logging prefix/tag to use, for Default agent
#   -DRIVER   => object           object heir of Log::Agent::Driver
#   -TRACE    => level            trace level
#   -DEBUG    => level            debug level
#   -LEVEL    => level            specifies common trace/debug level
#   -CONFESS  => flag             whether to automatically confess on logdie
#   -CALLER   => listref          info from caller to add and where
#   -PRIORITY => listref          message priority information to add
#   -TAGS     => listref          list of user-defined tags to add
#
# Notes:
#   -CALLER   allowed keys documented in Log::Agent::Tag::Caller's make()
#   -PRIORITY allowed keys documented in Log::Agent::Tag::Priority's make()
#   -TAGS     supplies list of Log::Agent::Tag objects
#
sub logconfig {
	my (%args) = @_;
	my ($calldef, $priodef, $tags);

	my %set = (
		-prefix			=> \$Prefix,		# Only for Default init
		-driver			=> \$Driver,
		-trace			=> \$Trace,
		-debug			=> \$Debug,
		-level			=> [\$Trace, \$Debug],
		-confess		=> \$Confess,
		-caller			=> \$calldef,
		-priority		=> \$priodef,
		-tags			=> \$tags,
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		unless (ref $vset) {
			require Carp;
			Carp::croak("Unknown switch $arg");
		}
		if		(ref $vset eq 'SCALAR')		{ $$vset = $val }
		elsif	(ref $vset eq 'ARRAY')		{ map { $$_ = $val } @$vset }
		elsif	(ref $vset eq 'REF')		{ $$vset = $val }
		else								{ die "bug in logconfig" }
	}

	unless (defined $Driver) {
		require Log::Agent::Driver::Default;
		# Keep only basename for default prefix
		$Prefix =~ s|^.*/(.*)|$1| if defined $Prefix;
		$Driver = Log::Agent::Driver::Default->make($Prefix);
	}

	$Prefix = $Driver->prefix;
	$Trace = level_from_prio($Trace) if defined $Trace && $Trace =~ /^\D+/;
	$Debug = level_from_prio($Debug) if defined $Debug && $Debug =~ /^\D+/;

	#
	# Handle -caller => [ <options for Log::Agent::Tag::Caller's make> ]
	#

	if (defined $calldef) {
		unless (ref $calldef eq 'ARRAY') {
			require Carp;
			Carp::croak("Argument -caller must supply an array ref");
		}
		require Log::Agent::Tag::Caller;
		$Caller = Log::Agent::Tag::Caller->make(-offset => 3, @{$calldef});
	};

	#
	# Handle -priority => [ <options for Log::Agent::Tag::Priority's make> ]
	#

	if (defined $priodef) {
		unless (ref $priodef eq 'ARRAY') {
			require Carp;
			Carp::croak("Argument -priority must supply an array ref");
		}
		$Priorities = $priodef;		# Objects created via prio_tag()
	};

	#
	# Handle -tags => [ <list of Log::Agent::Tag objects> ]
	#

	if (defined $tags) {
		unless (ref $tags eq 'ARRAY') {
			require Carp;
			Carp::croak("Argument -tags must supply an array ref");
		}
		my $type = "Log::Agent::Tag";
		if (grep { !ref $_ || !$_->isa($type) } @$tags) {
			require Carp;
			Carp::croak("Argument -tags must supply list of $type objects");
		}
		if (@$tags) {
			require Log::Agent::Tag_List;
			$Tags = Log::Agent::Tag_List->make(@$tags);
		} else {
			undef $Tags;
		}
	}

	# Install interceptor if needed
	DATUM_is_here() if defined $DATUM && $DATUM;
}

#
# inited
#
# Returns whether Log::Agent was inited.
# NOT exported, must be called as Log::Agent::inited().
#
sub inited {
	return 0 unless defined $Driver;
	return ref $Driver ? 1 : 0;
}

#
# DATUM_is_here		-- undocumented, but for Carp::Datum
#
# Tell Log::Agent that the Carp::Datum package was loaded and configured
# for debug.
#
# If there is a driver configured already, install the interceptor.
# Otherwise, record that DATUM is here and the interceptor will be installed
# by logconfig().
#
# NOT exported, must be called as Log::Agent::DATUM_is_here().
#
sub DATUM_is_here {
	$DATUM = 1;
	return unless defined $Driver;
	return if ref $Driver eq 'Log::Agent::Driver::Datum';

	#
	# Install the interceptor.
	#

	require Log::Agent::Driver::Datum;
	$Driver = Log::Agent::Driver::Datum->make($Driver);
}

#
# log_default
#
# Initialize a default logging driver.
#
sub log_default {
	return if defined $Driver;
	logconfig();
}

#
# logconfess
#
# Die with a full stack trace
#
sub logconfess {
	my $ptag = prio_tag(priority_level(CRIT)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logconfess($str);
	bug("back from logconfess in driver $Driver\n");
}

#
# logcroak
#
# Fatal error, from the perspective of our caller
# Error is logged, and then we die.
#
sub logcroak {
	goto &logconfess if $Confess;		# Redirected when -confess
	my $ptag = prio_tag(priority_level(CRIT)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logxcroak(0, $str);
	bug("back from logxcroak in driver $Driver\n");
}

#
# logxcroak
#
# Same a logcroak, but with a specific additional offset.
#
sub logxcroak {
	my $offset = shift;
	goto &logconfess if $Confess;		# Redirected when -confess
	my $ptag = prio_tag(priority_level(CRIT)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logxcroak($offset, $str);
	bug("back from logxcroak in driver $Driver\n");
}

#
# logdie
#
# Fatal error
# Error is logged, and then we die.
#
sub logdie {
	goto &logconfess if $Confess;		# Redirected when -confess
	my $ptag = prio_tag(priority_level(CRIT)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logdie($str);
	bug("back from logdie in driver $Driver\n");
}

#
# logerr
#
# Log error, at the "error" level.
#
sub logerr {
	return if $Trace < ERROR;
	my $ptag = prio_tag(priority_level(ERROR)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logerr($str);
}

#
# logcarp
#
# Warning, from the perspective of our caller (at the "warning" level)
#
sub logcarp {
	return if $Trace < WARN;
	my $ptag = prio_tag(priority_level(WARN)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logxcarp(0, $str);
}

#
# logxcarp
#
# Same a logcarp, but with a specific additional offset.
#
sub logxcarp {
	return if $Trace < WARN;
	my $offset = shift;
	my $ptag = prio_tag(priority_level(WARN)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logxcarp($offset, $str);
}

#
# logwarn
#
# Log warning at the "warning" level.
#
sub logwarn {
	return if $Trace < WARN;
	my $ptag = prio_tag(priority_level(WARN)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logwarn($str);
}

#
# logsay
#
# Log message at the "notice" level.
#
sub logsay {
	return if $Trace < NOTICE;
	my $ptag = prio_tag(priority_level(NOTICE)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logsay($str);
}

#
# logtrc		-- frozen
#
# Trace the message if trace level is set high enough.
# Trace level must either be a single digit or "priority" or "priority:digit".
#
sub logtrc {
	my $id = shift;
	my ($prio, $level) = priority_level($id);
	return if $level > $Trace;
	my $ptag = prio_tag($prio, $level) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logwrite('output', $prio, $level, $str);
}

#
# logdbg		-- frozen
#
# Emit debug message if debug level is set high enough.
# Debug level must either be a single digit or "priority" or "priority:digit".
#
sub logdbg {
	my $id = shift;
	my ($prio, $level) = priority_level($id);
	return if !defined($Debug) || $level > $Debug;
	my $ptag = prio_tag($prio, $level) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logwrite('debug', $prio, $level, $str);
}

#
# logtags
#
# Returns info on user-defined logging tags.
# Asking for this creates the underlying taglist object if not already present.
#
sub logtags {
	return $Tags if defined $Tags;
	require Log::Agent::Tag_List;
	return $Tags = Log::Agent::Tag_List->make();
}

###
### Utilities
###

#
# logwrite		-- not exported by default
#
# Write message to the specified channel, at the given priority.
#
sub logwrite {
	my ($channel, $id) = splice(@_, 0, 2);
	my ($prio, $level) = priority_level($id);
	my $ptag = prio_tag($prio, $level) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	&log_default unless defined $Driver;
	$Driver->logwrite($channel, $prio, $level, $str);
}

#
# bug
#
# Log bug, and die.
#
sub bug {
	my $ptag = prio_tag(priority_level(EMERG)) if defined $Priorities;
	my $str = tag_format_args($Caller, $ptag, $Tags, \@_);
	logerr("BUG: $str");
	die "${Prefix}: $str\n";
}

#
# prio_tag
#
# Returns Log::Agent::Tag::Priority message that is suitable for tagging
# at this priority/level, if configured to log priorities.
#
# Objects are cached into %prio_cache.
#
sub prio_tag {
	my ($prio, $level) = @_;
	my $ptag = $prio_cache{$prio, $level};
	return $ptag if defined $ptag;

	require Log::Agent::Tag::Priority;

	#
	# Common attributes (formatting, postfixing, etc...) are held in
	# the $Priorities global variable.  We add the priority/level here.
	#

	$ptag = Log::Agent::Tag::Priority->make(
		-priority	=> $prio,
		-level		=> $level,
		@$Priorities
	);

	return $prio_cache{$prio, $level} = $ptag;
}

=head1 NAME

Log::Agent - logging agent

=head1 SYNOPSIS

 use Log::Agent;            # in all reusable components
 logerr "error";
 logtrc "notice:12", "notice that" if ...;
 logdie "log and die";

 use Log::Agent;            # in application's main
 logconfig(-prefix => $0);  # simplest, uses default driver

 use Log::Agent;                    # another more complex example
 require Log::Agent::Driver::File;  # logging made to file
 logconfig(-driver =>
     Log::Agent::Driver::File->make(
         -prefix      => $0,
         -showpid     => 1,
         -channels    => {
             'error'  => "$0.err",
             'output' => "$0.out",
             'debug'  => "$0.dbg",
         },
     )
 );

=head1 DESCRIPTION

The C<Log::Agent> module provides an abstract layer for logging and
tracing, which is independent from the actual method used to physically
perform those activities. It acts as an agent (hence the name) that
collects the requests and delegates processing to a sublayer: the
logging driver.

The C<Log::Agent> module is meant to be used in all reusable components,
since they cannot know in advance how the application which ends up using
them will perform its logging activities: either by emitting messages
on stdout and errors on stderr, or by directing messages to logfiles,
or by using syslog(3).

The logging interface is common for all the logging drivers, and is
therefore the result of a compromise between many logging schemes: any
information given at this level must be either handled by all drivers,
or may be ignored depending on the application's final choice.

=head1 PRIORITIES AND LEVEL

The C<Log::Agent> module can use both priorities (as defined by
syslog(3)) or logging levels, or either, in which case there is
an implicit computation of the missing item (i.e. the level 4, for
instance, corresponds to the "warning" priority, and vice-versa).
See L<Log::Agent::Priorities> for more details.

A logging level is defined as being a threshold: any level lesser than
or equal to that threshold will be logged.

At the C<Log::Agent> level, it is possible to define a trace level and
a debug level. Only the messages below those levels (inclusive) will be
handed out to the underlying driver for logging. They are used by the
logtrc() and logdbg() routines, respectively.

=head1 CHANNELS

The C<Log::Agent> class defines three logging channels, which are
C<error>, C<output> and C<debug>. Depending on the driver used for
logging, those channels are ignored (typically with syslog()) or may
be implicitely defined (default logging, i.e. the one achieved by the
C<Log::Agent::Driver::Default> driver, remaps C<error> and C<debug>
to stderr, C<output> to stdout).

=head1 INTERFACE

Anywhere a I<message> is expected, it can be a single string, or a
printf()-like format string followed by the required arguments. The
special macro C<%m> is handled directly by C<Log::Agent> and is replaced
by the string version of $!, which is the last error message returned
by the last failing system call.

B<NOTE>: There should not be any trailing "\n" in the I<message> strings,
nor any embededed one, although this is not enforced. Remember that
the main purpose of C<Log::Agent> is to specify logging messages in a
standard way!  Therefore, most of the time, a "should" should be read as
"must" and "should not" as "must not", which is the strongest interdiction
form available in English, as far as I know.

Here are valid I<message> examples:

    "started since $time"
    "started since %s", $time
    "fork: %m"

The follwing logging interface is made available to modules:

=over 4

=item logdbg I<priority>, I<message>

Debug logging of I<message> to the C<debug> channel.

You may specify any priority you want, i.e.  a C<debug> priority is
not enforced here. You may even specify C<"notice:4"> if you wish,
to have the message logged if the debug level is set to 4 or less.
If handed over to syslog(3), the message will nonetheless be logged at
the C<notice> priority.

=item logtrc I<priority>, I<message>

Trace logging of I<message> to the C<output> channel.

Like logdbg() above, you are not restricted to the C<info> priority. This
routine checks the logging level (either explicit as in C<"info:14">
or implicit as in C<"notice">) against the trace level.

=item logsay I<message>

Log the message at the C<notice> priority to the C<output> channel.
The logging always takes place under the default C<-trace> settings, but
only if the routine is called, naturally.  This means you can still say:

    logsay "some trace message" if $verbose;

and control whether the message is emitted by using some external
configuration for your module (e.g. by adding a -verbose flag to the
creation routine of your class).

=item logwarn I<message>

Log a warning message at the C<warning> priority to the C<error> channel.

=item logcarp I<message>

Same as logwarn(), but issues a Carp::carp(3) call instead, which will
warn from the perspective of the routine's caller.

=item logerr I<message>

Log an error message at the C<error> priority to the C<error> channel.

=item logdie I<message>

Log a fatal message at the C<critical> priority to the C<error> channel,
and then dies.

=item logconfess I<message>

Same as logdie(), but issues a Carp::confess(3) call instead.  It is
possible to configure the C<Log::Agent> module via the C<-confess>
switch to automatically redirect a logdie() to logconfess(), which is
invaluable during unit testing.

=item logcroak I<message>

Same as logdie(), but issues a Carp::croak(3) call instead.  It is
possible to configure the C<Log::Agent> module via the C<-confess>
switch to automatically redirect a logcroak() to logconfess(), which is
invaluable during unit testing.

=item Log::Agent::inited

Returns true when C<Log::Agent> was initialized, either explicitly via
a logconfig() or implicitely via any logxxx() call.

=back

Modules sometimes wish to report errors from the perspective of their
caller's caller, not really their caller.  The following interface is
therefore provided:

=over 4

=item logxcarp I<offset>, I<message>

Same a logcarp(), but with an additional offset to be applied on the
stack.  To warn one level above your caller, set it to 1.

=item logxcroak I<offset>, I<message>

Same a logcroak(), but with an additional offset to be applied on the
stack.  To report an error one level above your caller, set it to 1.

=back

For applications that wish to implement a debug layer on top of
C<Log::Agent>, the following routine is provided.  Note that it is not
imported by default, i.e. it needs to be explicitly mentionned at C<use>
time, since it is not meant to be used directly under regular usage.

=over 4

=item logwrite I<channel>, I<priority>, I<message>

Unconditionally write the I<message> at the given I<priority> on I<channel>.
The channel can be one of C<debug>, C<error> or C<output>.

=back

At the application level, one needs to commit once and for all about the
logging scheme to be used. This is done thanks to the logconfig() routine
which takes the following switches, in alphabetical order:

=over 4

=item C<-caller> => [ I<parameters> ]

Request that caller information (relative to the logxxx() call) be part
of the log message. The given I<parameters> are handed off to the
creation routine of C<Log::Agent::Tag::Caller> and are documented there.

I usually say something like:

 -caller => [ -display => '($sub/$line)', -postfix => 1 ]

which I find informative enough. On occasion, I found myself using more
complex sequences.  See L<Log::Agent::Tag::Caller>.

=item C<-confess> => I<flag>

When true, all logdie() calls will be automatically masqueraded as
logconfess().

=item C<-debug> => I<priority or level>

Sets the priority threshold (can be expressed as a string or a number, the
string being mapped to a logging level as described above in
B<PRIORITIES AND LEVEL>) for logdbg() calls.

Calls tagged with a level less than or equal to the given threshold will
pass through, others will return prematurely without logging anything.

=item C<-driver> => I<driver_object>

This switch defines the driver object to be used, which must be an heir of
the C<Log::Agent::Driver> class. See L<Log::Agent::Driver(3)> for a list
of the available drivers.

=item C<-level> => I<priority or level>

Specifies both C<-debug> and C<-trace> levels at the same time, to a
common value.

=item C<-prefix> => I<name>

Defines the application name which will be pre-pended to all messages,
followed by C<": "> (a colon and a space). Using this switch alone will
configure the default driver to use that prefix (stripped down to its
basename component).

When a driver object is used, the C<-prefix> switch is kept at the
C<Log::Agent> level only and is not passed to the driver: it is up to
the driver's creation routine to request the C<-prefix>. Having this
information in Log::Agent enables the module to die on critical errors
with that error prefix, since it cannot rely on the logging driver for
that, obviously.

=item C<-priority> => [ I<parameters> ]

Request that message priority information be part of the log message.
The given I<parameters> are handed off to the
creation routine of C<Log::Agent::Tag::Priority> and are documented there.

I usually say something like:

	-priority => [ -display => '[$priority]' ]

which will display the whole priority name at the beginning of the messages,
e.g. "[warning]" for a logwarn() or "[error]" for logerr().
See L<Log::Agent::Tag::Priority> and L<Log::Agent::Priorities>.

B<NOTE>: Using C<-priority> does not prevent the C<-duperr> flag of
the file driver to also add its own hardwired prefixing in front of
duplicated error messages.  The two options act at a different level.

=item C<-tags> => [ I<list of C<Log::Agent::Tag> objects> ]

Specifies user-defined tags to be added to each message.  The objects
given here must inherit from C<Log::Agent::Tag> and conform to its
interface.  See L<Log::Agent::Tag> for details.

At runtime, well after logconfig() was issued, it may be desirable to
add (or remove) a user tag.  Use the C<logtags()> routine for this purpose,
and iteract directly with the tag list object.

For instance, a web module might wish to tag all the messages with a
session ID, information that might not have been available by the time
logconfig() was issued.

=item C<-trace> => I<priority or level>

Same a C<-debug> but applies to logsay(), logwarn(), logerr() and logtrc().

When unspecified, C<Log::Agent> runs at the "notice" level.

=back

Additional routines, not exported by default, are:

=over 4

=item logtags

Returns a C<Log::Agent::Tag_List> object, which holds all user-defined
tags that are to be added to each log message.

The initial list of tags is normally supplied by the application at
logconfig() time, via the C<-tags> argument.  To add or remove tags after
configuration time, one needs direct access to the tag list, obtained via
this routine.  See L<Log::Agent::Tag_List> for the operations that can be
performed.

=back

=head1 KNOWN LIMITATIONS

The following limitations exist in this early version. They might be
addressed in future versions if they are perceived as annoying limitatons
instead of being just documented ones. :-)

=over 4

=item *

A module which calls logdie() may have its die trapped if called from
within an eval(), but unfortunately, the value of $@ is unpredictable:
it may be prefixed or not depending on the driver used. This is harder to
fix as one might think of at first glance.

=item *

Some drivers lack customization and hardwire a few things that come
from my personal taste, like the prefixing done when I<duperr> is set
in Log::Agent::Driver::File, or the fact that the C<debug> and C<stderr>
channels are merged as one in the Log::Agent::Driver::Default driver.

=item *

When using logcroak() or logconfess(), the place where the call was
made can still be visible when -caller is used, since the addition
of the caller information to the message is done before calling the
logging driver.  Is this a problem?

=back

=head1 AUTHOR

Log::Agent was originally authored by Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>> and is currently maintained by Mark Rogaski F<E<lt>mrogaski@cpan.orgE<gt>>.

=head1 LICENSE

Copyright (c) 1999-2000 Raphael Manfredi.

Copyright (c) 2002-2003, 2005, 2013 Mark Rogaski; all rights reserved.

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 SEE ALSO

Log::Agent::Driver(3), Carp(3).

=cut
