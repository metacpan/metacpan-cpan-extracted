###########################################################################
#
#   Datum.pm
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
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::Datum;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

#
# ->make			-- defined
#
# Creation routine.
#
# Attributes:
#   driver     the underlying driver originally configured
#
sub make {
	my $self = bless {}, shift;
	my ($driver) = @_;
	$self->_init('', 0);				# 0 is the skip Carp penalty
	$self->{driver} = $driver;
	$driver->add_penalty(2);			# We're intercepting the calls
	return $self;
}

#
# Attribute access
#

sub prefix		{ $_[0]->{driver}->prefix }
sub driver		{ $_[0]->{driver} }

#
# Cannot-be-called routines.
#

sub prefix_msg	{ require Carp; Carp::confess("prefix_msg") }
sub emit		{ require Carp; Carp::confess("emit") }

#
# ->channel_eq		-- defined
#
# Redirect comparison to driver.
#
sub channel_eq {
	my $self = shift;
	my ($chan1, $chan2) = @_;
	return $self->driver->channel_eq($chan1, $chan2);
}

#
# ->datum_trace
#
# Emit a Carp::Datum trace, which will be a logwrite() on the 'debug' channel.
#
sub datum_trace {
	my $self = shift;
	my ($str, $tag) = @_;
	require Carp::Datum;
	Carp::Datum::trace($str, $tag);
}

#
# intercept
#
# Intercept call to driver by calling ->datum_trace() first, then resume
# regular operation on the driver, if the channel where message would go
# is not the same as the debug channel.
#
sub intercept {
	my ($aref, $tag, $op, $chan, $prepend) = @_;
	my $self = shift @$aref;

	#
	# $aref can be [$str] or [$offset, $str]
	#

	my $pstr = $aref->[$#$aref];		# String is last argument
	if (defined $prepend) {
		$pstr = $pstr->clone;			# We're prepending tag on a copy
		$pstr->prepend("$prepend: ");
	}
	$self->datum_trace($pstr, $tag);
	my $driver = $self->driver;
	if ($driver->channel_eq('debug', $chan)) {
		die "$pstr\n" if $prepend eq 'FATAL';
	} else {
		$driver->$op(@$aref);
	}
}

#
# Interface interception.
#
# The string will be tagged with ">>" to make it clear it comes from Log::Agent,
# unless it's a fatal string from logconfess/logcarp/logdie, in wich case
# it is tagged with "**".
#

sub logconfess	{ intercept(\@_, '**', 'logconfess', 'error',	'FATAL') }
sub logxcroak	{ intercept(\@_, '**', 'logxcroak',	 'error',	'FATAL') }
sub logdie		{ intercept(\@_, '**', 'logdie',	 'error',	'FATAL') }
sub logerr		{ intercept(\@_, '>>', 'logerr',	 'error',	'ERROR') }
sub logwarn		{ intercept(\@_, '>>', 'logwarn',	 'error',	'WARNING') }
sub logxcarp	{ intercept(\@_, '>>', 'logxcarp',	 'error',	'WARNING') }
sub logsay		{ intercept(\@_, '>>', 'logsay',	 'output') }

#
# logwrite		-- redefined
#
# Emit the message to the specified channel
#
sub logwrite {
	my $self = shift;
	my ($chan, $prio, $level, $str) = @_;

	#
	# Have to be careful not to recurse through ->datum_trace().
	# Look at who is calling us (immediate caller is Log::Agent).
	#

	my $pkg = caller(1);
	if ($pkg =~ /^Carp::Datum\b/) {
		my $drv = $self->driver;
		return unless defined $drv;	# Can happen during global destruct
		$drv->logwrite($chan, $prio, $level, $str);
		return;
	}

	#
	# The following will recurse back to us, but the above check will
	# cut the recursion.
	#

	intercept([$self, $str], '>>', 'logwrite', $chan);
}

__END__

=head1 NAME

Log::Agent::Driver::Datum - interceptor driver to cooperate with Carp::Datum

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

The purpose of the interceptor is to cooperate with Carp::Datum by emitting
traces to the debug channel via Carp::Datum's traces facilities.

This driver is automatically installed by Log::Agent when Carp::Datum is
in use and debug was activated through it.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Carp::Datum(3).

=cut
