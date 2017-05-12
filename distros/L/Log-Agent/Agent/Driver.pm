###########################################################################
#
#   Driver.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;

########################################################################
package Log::Agent::Driver;

#
# Ancestor for all Log::Agent drivers.
#

#
# Common attribute acccess, initialized via _init().
#
# prefix    the common (static) string info to prepend to messages
# penalty   the skip Carp penalty to offset to the fixed one
#

sub prefix  { $_[0]->{'prefix'} }
sub penalty { $_[0]->{'penalty'} }

#
# is_deferred
#
# Report routine as being deferred
#
sub is_deferred {
    require Carp;
    Carp::confess("deferred");
}

#
# ->make -- deferred
#
# Creation routine.
#
sub make {
    &is_deferred;
}

#
# ->channel_eq
#
# Compare two channels and return true if they go to the same output.
#
sub channel_eq {
    &is_deferred;
}

#
# ->_init
#
# Common initilization routine
#
sub _init {
    my $self = shift;
    my ($prefix, $penalty) = @_;
    $self->{'prefix'} = $prefix;    # Prefix info to prepend
    $self->{'penalty'} = $penalty;  # Carp stack skip penalty
}

#
# ->add_penalty        -- "exported" only to Log::Agent::Driver::Datum
#
# Add offset to current driver penalty
#
sub add_penalty {
    my $self = shift;
    my ($offset) = @_;
    $self->{penalty} += $offset;
}

my %level = (
    'c' => 1,
    'e' => 2,
    'w' => 4,
    'n' => 6,
);

#
# ->priority        -- frozen
#
# Return proper priority for emit() based on one of the following strings:
# "critical", "error", "warning", "notice". Those correspond to the hardwired
# strings for logconfess()/logdie(), logerr(), logwarn() and logsay().
#
# This routine is intended to be "frozen", i.e. it MUST NOT be redefined.
# Redefine map_pri() if needed, or don't call it in the first place.
#
sub priority {
    my $self = shift;
    my ($prio) = @_;
    my $level = $level{lc(substr($prio, 0, 1))} || 8;
    return $self->map_pri($prio, $level);
}

#
# ->write            -- deferred
#
# Write log entry, physically.
# A trailing "\n" is to be added if needed.
#
# $channel is one of 'debug', 'output', 'error' and can be used to determine
# where the emission of the log message should be done.
#
sub write {
    my $self = shift;
    my ($channel, $priority, $logstring) = @_;
    &is_deferred;
}

#
# ->emit            -- may be redefined
#
# Routine to call to emit log, resolve priority and prefix logstring.
# Ulitimately calls ->write() to perform the physical write.
#
sub emit {
    my $self = shift;
    my ($channel, $prio, $msg) = @_;
    $self->write($channel, $self->priority($prio), $self->prefix_msg($msg));
    return;
}


#
# ->map_pri            -- may be redefined
#
# Convert a ("priority", level) tupple to a single priority token suitable
# for `emit'.
#
# This is driver-specific: drivers may ignore priority altogether thanks to
# the previous level-based filtering done (-trace and -debug switches in the
# Log::Agent configuration), choose to give precedence to levels over priority
# when "priority:level" was specified, or always ignore levels and only use
# "priority".
#
# The default is to ignore "priority" and "levels", which is suitable to basic
# drivers. Only those (ala syslog) which rely on post-filtering need to be
# concerned.
#
sub map_pri {
    my $self = shift;
    my ($priority, $level) = @_;
    return '';        # ignored for basic drivers
}

#
# ->prefix_msg        -- deferred
#
# Prefix message with driver-specific string, if necessary.
#
# This routine may or may not use common attributes like the fixed
# static prefix or the process's pid.
#
sub prefix_msg {
    my $self = shift;
    my ($str) = @_;
    &is_deferred;
}

#
# ->carpmess
#
# Utility routine for logconfess and logcroak which builds the "die" message
# by calling the appropriate routine in Carp, and offseting the stack
# according to our call stack configuration, plus any offset.
#
sub carpmess {
    my $self = shift;
    my ($offset, $str, $fn) = @_;

    #
    # While confessing, we have basically tell $fn() to skip 2 stack frames:
    # this call, and our caller chain back to Log::Agent (calls within the
    # same hierarchy are automatically stripped by Carp).
    #
    # To that, we add any additional penalty level, as told us by the creation
    # routine of each driver, which accounts for extra levels used before
    # calling us.
    #

    require Carp;

    my $skip = $offset + 2 + $self->penalty;
    $Carp::CarpLevel += $skip;
    my $original = $str->str;        # Original user message
    my $msg = &$fn('__MESSAGE__');
    $Carp::CarpLevel -= $skip;

    #
    # If we have a newline in the message, we have a full stack trace.
    # Replace the original message string with the first line, and
    # append the remaining.
    #

    chomp($msg);                    # Remove final "\n" added

    if ($msg =~ s/^(.*?)\n//) {
        my $first = $1;

        #
        # Patch incorrect computation by Carp, which occurs when we request
        # a short message and we get a long one.  In that case, what we
        # want is the first line of the extra message.
        #
        # This bug manifests when the whole call chain above Log::Agent
        # lies in "main".  When objects are involved, it seems to work
        # correctly.
        #
        # The kludge here is valid for perl 5.005_03.  If some day Carp is
        # fixed, we will have to test for the Perl version.  The right fix,
        # I believe, would be to have Carp skip frame first, and not last
        # as it currently does.
        #        -- RAM, 30/09/2000
        #

        if ($fn == \&Carp::shortmess) {                # Kludge alert!!

            #
            # And things just got a little uglier with 5.8.0
            #
            # -- mrogaski, 1 Aug 2002
            #
            my $index = $] >= 5.008 ? 1 : 0;

            $first =~ s/(at (.+) line \d+)$//;
            my $bad = $1;
            my @stack = split(/\n/, $msg);
            my ($at) = $stack[$index] =~ /(at \S+ line \d+)$/
                    if defined $stack[$index];
            $at = "$bad (Log::Agent could not fix it)" unless $at;
            $first .= $at;
            $str->set_str($first);
        } else {
            $str->set_str($first);
            $str->append_last("\n");
            $str->append_last($msg);    # Stack at the very tail of message
        }
    } else {
        $str->set_str($msg);        # Change original message inplace
    }

    $msg = $str->str;

    # Another Carp workaround kludge.
    $msg =~ s/ at .*\d\.at / at /;

    $msg =~ s/__MESSAGE__/$original/;
    $str->set_str($msg);

    return $str;
}

#
# ->logconfess
#
# Confess fatal error
# Error is logged, and then we confess.
#
sub logconfess {
    my $self = shift;
    my ($str) = @_;
    my $msg = $self->carpmess(0, $str, \&Carp::longmess);
    $self->emit('error', 'critical', $msg);
    die "$msg\n";
}

#
# ->logxcroak
#
# Fatal error, from the perspective of the caller.
# Error is logged, and then we confess.
#
sub logxcroak {
    my $self = shift;
    my ($offset, $str) = @_;
    my $msg = $self->carpmess($offset, $str, \&Carp::shortmess);
    $self->emit('error', 'critical', $msg);
    die "$msg\n";
}

#
# ->logdie
#
# Fatal error
# Error is logged, and then we die.
#
sub logdie {
    my $self = shift;
    my ($str) = @_;
    $self->emit('error', 'critical', $str);
    die "$str\n";
}

#
# logerr
#
# Log error
#
sub logerr {
    my $self = shift;
    my ($str) = @_;
    $self->emit('error', 'error', $str);
}

#
# ->logxcarp
#
# Log warning, from the perspective of the caller.
#
sub logxcarp {
    my $self = shift;
    my ($offset, $str) = @_;
    my $msg = $self->carpmess($offset, $str, \&Carp::shortmess);
    $self->emit('error', 'warning', $msg);
}

#
# logwarn
#
# Log warning
#
sub logwarn {
    my $self = shift;
    my ($str) = @_;
    $self->emit('error', 'warning', $str);
}

#
# logsay
#
# Log message at the "notice" level.
#
sub logsay {
    my $self = shift;
    my ($str) = @_;
    $self->emit('output', 'notice', $str);
}

#
# logwrite
#
# Emit the message to the specified channel
#
sub logwrite {
    my $self = shift;
    my ($chan, $prio, $level, $str) = @_;
    $self->write($chan, $self->map_pri($prio, $level),
        $self->prefix_msg($str));
}

1;    # for require
__END__

=head1 NAME

Log::Agent::Driver - ancestor class for all Log::Agent drivers

=head1 SYNOPSIS

 @Log::Agent::Driver::XXX::ISA = qw(Log::Agent::Driver);

=head1 DESCRIPTION

The Log::Agent::Driver class is the root class from which all Log::Agent
drivers inherit. It is a I<deferred> class, meaning that it cannot
be instantiated directly. All the deferred routines need to be implemented
by its heirs to form a valid driver.

A I<deferred> routine is a routine whose signature and semantics (pre and
post conditions, formally) are specified, but not implemented. It allows
specification of high-level processings in terms of them, thereby factorizing
common code in the ancestors without loosing specialization benefits.

=head1 DRIVER LIST

The following drivers are currently fully implemented:

=over 4

=item Log::Agent::Driver::Default

This is the default driver which remaps to simple print(), warn() and die()
Perl calls.

=item Log::Agent::Driver::File

This driver redirects logs to files. Each logging channel may go to a dedicated
file.

=item Log::Agent::Driver::Silent

Silence all the logxxx() routines.

=item Log::Agent::Driver::Syslog

This driver redirects logs to the syslogd(8) daemon, which will then handle
the dispatching to various logfiles, based on its own configuration.

=back

=head1 INTERFACE

You need not read this section if you're only B<using> Log::Agent.  However,
if you wish to B<implement> another driver, then you should probably read it
a few times.

The following routines are B<deferred> and therefore need to be defined
by the heir:

=over 4

=item channel_eq($chan1, $chan2)

Returns true when both channels $chan1 and $chan2 send their output to
the same place.  The purpose is not to have a 100% accurate comparison,
which is almost impossible for the Log::Agent::Driver::File driver,
but to reasonably detect similarities to avoid duplicating messages to
the same output when Carp::Datum is installed and activated.

=item write($channel, $priority, $logstring)

Emit the log entry held in $logstring, at priority $priority and through
the specfied $channel name. A trailing "\n" is to be added if needed, but the
$logstring should not already have one.

The $channel name is just a string, and it is up to the driver to map that
name to an output device using its own configuration information. The generic
logxxx() routines use only C<error>, C<output> or C<debug> for channel names.

The $priority entry is assumed to have passed through the map_pri() routine,
which by default returns an empty string (only the Log::Agent::Driver::Syslog
driver needs a priority, for now). Ignore if you don't need that, or redefine
map_pri().

The $logstring may not really be a plain string. It can actually be a
Log::Agent::Message object with an overloaded stringification routine, so
the illusion should be complete.

=item make

This is the creation routine. Its signature varies for each driver, naturally.

=item prefix_msg($str)

Prefix the log message string (a Log::Agent::Message object) with
driver-specific information (like the configured prefix, the PID of the
process, etc...).

Must return the prefixed string, either as a Log::Agent::Message object
or as a plain string. This means you may use normal string operations on the
$str variable and let the overloaded stringification perform its magic. Or
you may return the $str parameter without modification.

There is no default implementation here because this is too driver-specific
to choose one good default. And I like making things explicit sometimes.

=back

The following routines are implemented in terms of write(), map_pri()
and prefix_msg(). The default implementation may need to be redefined for
performance or tuning reasons, but simply defining the deferred routines
above should bring a reasonable behaviour.

As an example, here is the default logsay() implementation, which uses
the emit() wrapper (see below):

    sub logsay {
        my $self = shift;
        my ($str) = @_;
        $self->emit('output', 'notice', $str);
    }

Yes, we do show the gory details in a manpage, but inheriting from a class
is not for the faint of heart, and requires getting acquainted with the
implementation, most of the time.

The order is not alphabetical here but by increased level of severity
(as expected, anyway):

=over 4

=item logwrite($channel, $priority, $level, $str)

Log message to the given channel, at the specified priority/level,
obtained through a call to map_pri().

=item logsay($str)

Log message to the C<output> channel, at the C<notice> priority.

=item logwarn($str)

Log warning to the C<error> channel at the C<warning> priority.

=item logxcarp($offset, $str)

Log warning to the C<error> channel at the C<warning> priority, from
the perspective of the caller.  An additional $offset stack frames
are skipped to find the caller (added to the hardwired fixed offset imposed
by the overall Log::Agent architecture).

=item logerr($str)

Log error to the C<error> channel at the C<error> priority.

=item logdie($str)

Log fatal error to the C<error> channel at the C<critical> priority
and then call die() with "$str\n" as argument.

=item logxcroak($offset, $str)

Log a fatal error, from the perspective of the caller. The error is logged
to the C<error> channel at the C<critical> priority and then Carp::croak()
is called with "$str\n" as argument.  An additional $offset stack frames
are skipped to find the caller (added to the hardwired fixed offset imposed
by the overall Log::Agent architecture).

=item logconfess($str)

Confess a fatal error. The error is logged to the C<error> channel at
the C<critical> priority and then Carp::confess() is called with "$str\n"
as argument.

=back

The following routines have a default implementation but may be redefined
for specific drivers:

=over 4

=item emit($channel, $prio, $str)

This is a convenient wrapper that calls:

 write($channel, $self->priority($prio), $self->prefix_msg($str))

using dynamic binding.

=item map_pri($priority, $level)

Converts a ("priority", level) tupple to a single priority token suitable
for emit(). By default, returns an empty string, which is OK only when
emit() does not care!

=back

The following routine is B<frozen>. There is no way in Perl to freeze a routine,
i.e. to explicitly forbid any redefinition, so this is an informal
notification:

=over 4

=item priority($priority)

This routine returns the proper priority for emit() for each of the
following strings: "critical", "error", "warning" and "notice", which are
the hardwired priority strings, as documented above.

It derives a logging level from the $priority given and then returns the
result of:

    map_pri($priority, $level);

Therefore, only map_pri() should be redefined.

=back

Finally, the following initialization routine is provided: to record the

=over 4

=item _init($prefix, $penalty)

Records the C<prefix> attribute, as well as the Carp C<penalty> (amount
of extra stack frames to skip). Should be called in the constructor of
all the drivers.

=back

=head1 AUTHORS

Originally written by Raphael Manfredi E<lt>Raphael_Manfredi@pobox.comE<gt>,
currently maintained by Mark Rogaski E<lt>mrogaski@cpan.orgE<gt>.

=head1 LICENSE

  Copyright (C) 1999 Raphael Manfredi.
  Copyright (C) 2002 Mark Rogaski; all rights reserved.

See L<Log::Agent(3)> or the README file included with the distribution for
license information.

=head1 SEE ALSO

Log::Agent(3), Log::Agent::Driver::Default(3), Log::Agent::Driver::File(3),
Log::Agent::Driver::Fork(3), Log::Agent::Driver::Silent(3),
Log::Agent::Driver::Syslog(3), Carp::Datum(3).

=cut
