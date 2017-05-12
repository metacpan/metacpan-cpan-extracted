###########################################################################
#
#   Channel.pm
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
package Log::Agent::Channel;

#
# Ancestor for all Log::Agent logging channels.
#

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
# ->make			-- deferred
#
# Creation routine.
#
sub make {
	&is_deferred;
}

#
# ->write_fn		-- frozen
#
# Message is a CODE ref, call routine to generate it, then perform write.
# Extra arguments after CODE ref are passed back to the routine.
#
sub write_fn {
	my $self = shift;
	my ($priority, $fn) = splice(@_, 0, 2);
	my $msg = &$fn(@_);
	$self->write($priority, $msg);
}

#
# ->write			-- deferred
#
# Physical writing of the message with the said priority.
#
sub write {
	my $self = shift;
	my ($priority, $msg) = @_;
	&is_deferred;
}

#
# ->close			-- deferred
#
sub close {
	my $self = shift;
	&is_deferred;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Channel - ancestor class for all Log::Agent channels

=head1 SYNOPSIS

 @Log::Agent::Channel::XXX::ISA = qw(Log::Agent::Channel);

=head1 DESCRIPTION

The C<Log::Agent::Channel> class is the root class from which all
C<Log::Agent> channels inherit. It is a I<deferred> class, meaning that
it cannot be instantiated directly. All the deferred routines need to
be implemented by its heirs to form a valid driver.

Internally, the various C<Log::Agent::Driver> objects create
C<Log::Agent::Channel> instances for each logging channel defined at
driver creation time.  The channels are therefore architecturally hidden
within C<Log::Agent>, since this module only provides redefined mappings
for the various logxxx() routines (logerr(), logwarn(), logdie(), etc...).

However, this does not mean that channel classes cannot be used externally:
the C<Log::Agent::Logger> extension makes C<Log::Agent::Channel> objects
architecturally visible, thereby offering an application-level logging API
that can be redirected to various places transparently for the application.

=head1 CHANNEL LIST

The following channels are currently made available by C<Log::Agent>.  More
channels can be defined by the C<Log::Agent::Logger> extension:

=over 4

=item Log::Agent::Channel::File

This channel writes logs to files, defined by their path or via a magical
opening sequence such as "|cmd".  See L<Log::Agent::Channel::File>.

=item Log::Agent::Channel::Handle

This channel writes logs to an already opened descriptor, as specified by its
file handle: an IO::Handle object, or a GLOB reference such as \*FILE.
See L<Log::Agent::Channel::Handle>.

=item Log::Agent::Channel::Syslog

This channel redirects logs to the syslogd(8) daemon, which will then handle
the dispatching to various logfiles, based on its own configuration.
See L<Log::Agent::Channel::Syslog>.

=back

=head1 INTERFACE

You need not read this section if you're only B<using> C<Log::Agent>.
However, if you wish to B<implement> another channel, then this section
might be of interest.

The following routines are B<deferred> and therefore need to be defined
by the heir:

=over 4

=item write($priority, $logstring)

Emit the log entry held in $logstring, at priority $priority.
A trailing "\n" is added to the $logstring, if needed (i.e. if the physical
entity does not do it already, like syslog does).

The $priority argument must be a valid syslog priority, i.e. one of the
following strings: "emerg", "alert", "crit", "err", "warning", "notice",
"info", "debug".

The $logstring may not really be a plain string. It can actually be a
Log::Agent::Message object with an overloaded stringification routine, so
the illusion should be complete.

=item close

Close the channel.

=item make

This is the creation routine. Its signature varies for each channel, naturally.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Channel::File(3), Log::Agent::Channel::Handle(3),
Log::Agent::Channel::Syslog(3), Log::Agent::Logger(3).

=cut
