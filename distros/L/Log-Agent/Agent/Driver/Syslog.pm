###########################################################################
#
#   Syslog.pm
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
package Log::Agent::Driver::Syslog;

require Log::Agent::Driver;
use vars qw(@ISA);
@ISA = qw(Log::Agent::Driver);

require Log::Agent::Channel::Syslog;

#
# ->make			-- defined
#
# Creation routine.
#
# All switches are passed to Log::Agent::Channel::Syslog.
#
# prefix		the application name
# facility		the syslog facility name to use ("auth", "daemon", etc...)
# showpid		whether to show pid
# socktype		socket type ('unix' or 'inet')
# logopt		list of openlog() options: 'ndelay', 'cons' or 'nowait'
#
sub make {
	my $self = bless {}, shift;
	my (%args) = @_;
	my $prefix;

	my %set = (
		-prefix		=> \$prefix,				# Handled by parent via _init
	);

	while (my ($arg, $val) = each %args) {
		my $vset = $set{lc($arg)};
		next unless ref $vset;
		$$vset = $val;
	}

	$self->{channel} = Log::Agent::Channel::Syslog->make(@_);
	$self->_init($prefix, 0);					# 0 is the skip Carp penalty
	return $self;
}

sub channel		{ $_[0]->{channel} }

#
# ->prefix_msg		-- defined
#
# NOP -- syslog will handle this
#
sub prefix_msg {
	my $self = shift;
	return $_[0];
}

#
# ->channel_eq		-- defined
#
# Always true.
#
sub channel_eq {
	return 1;
}

my %syslog_pri = (
	'em' => 'emerg',
	'al' => 'alert',
	'cr' => 'crit',
	'er' => 'err',
	'wa' => 'warning',
	'no' => 'notice',
	'in' => 'info',
	'de' => 'debug'
);

#
# ->map_pri			-- redefined
#
# Levels ignored, only priorities matter.
#
sub map_pri {
	my $self = shift;
	my ($priority, $level) = @_;
	return $syslog_pri{lc(substr($priority, 0, 2))} || 'debug';
}

#
# ->write			-- defined
#
# $channel is ignored
#
sub write {
	my $self = shift;
	my ($channel, $priority, $logstring) = @_;
	$self->channel->write($priority, $logstring);
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Driver::Syslog - syslog logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::Syslog;

 my $driver = Log::Agent::Driver::Syslog->make(
     -prefix     => prefix,
     -facility   => "user",
     -showpid    => 1,
     -socktype   => "unix",
     -logopt     => "ndelay",
 );
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The syslog logging driver delegates logxxx() operations to syslog() via
the Sys::Syslog(3) interface.

The creation routine make() takes the following switches:

=over 4

=item C<-facility> => I<facility>

Tell syslog() which facility to use (e.g. "user", "auth", "daemon").
Unlike the Sys::Syslog(3) interface, the facility is set once and for all:
every logging message will use the same facility.

If you wish to log something to "auth" for instance, then do so via
Sys::Syslog directly: there is no guarantee that the application will configure
its Log::Agent to use syslog anyway!

=item C<-logopt> => I<syslog options>

Specifies logging options, under the form of a string containing zero or
more of the words I<ndelay>, I<cons> or I<nowait>.

=item C<-prefix> => I<prefix>

The I<prefix> here is syslog's identification string.

=item C<-showpid> => I<flag>

Set to true to have the PID of the process logged. It is false by default.

=item C<-socktype> => (I<unix> | I<inet>)

Specifies the logging socket type to use. The default behaviour is to
use Sys:Syslog's default.

=back

=head1 CHANNELS

All the channels go to syslog(), of course.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent::Channel::Syslog(3).

=cut
