#!/usr/bin/perl

package Mail::Log::Parse::Postfix;
{
=head1 NAME

Mail::Log::Parse::Postfix - Parse and return info in Postfix maillogs

=head1 SYNOPSIS

  use Mail::Log::Parse::Postfix;

(See L<Mail::Log::Parse> for more info.)

=head1 DESCRIPTION

This is a subclass of L<Mail::Log::Parse>, which handles parsing for
Postfix mail logs.

=head1 USAGE

=cut

use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Time::Local;
use Mail::Log::Parse 1.0400;
use Mail::Log::Exceptions;
use base qw(Mail::Log::Parse Exporter);

use Memoize;
memoize('timelocal');

BEGIN {
    use Exporter ();
    use vars qw($VERSION);
    $VERSION     = '1.0501';
}

# A constant, to convert month names to month numbers.
my %MONTH_NUMBER = (	Jan		=> 0
						,Feb	=> 1
						,Mar	=> 2
						,Apr	=> 3
						,May	=> 4
						,Jun	=> 5
						,Jul	=> 6
						,Aug	=> 7
						,Sep	=> 8
						,Oct	=> 9
						,Nov	=> 10
						,Dec	=> 11
					);

# We are going to assume we are only run once a day.  (Actually, since we only
# ever use the _year_...)
my @CURR_DATE = localtime;

#
# Define class variables.  Note that they are hashes...
#

my %log_info;

#
# DESTROY class variables.
#
### IF NOT DONE THERE IS A MEMORY LEAK.  ###

sub DESTROY {
	my ($self) = @_;
	
	delete $log_info{$$self};
	
	$self->SUPER::DESTROY();
	
	return;
}

sub new {
	my ($class, $parameters_ref) = @_;

	my $self = $class->SUPER::new($parameters_ref);

	if (defined($parameters_ref->{year})) {
		$self->set_year($parameters_ref->{year});
	}

	return $self
}

=head2 set_year

Sets the year, for the log timestamps.  If not set, the log is assumed to
be for the current year.  (Can also be passed in C<new>, with the key 'year'.)

=cut

sub set_year {
	my ($self, $year) = @_;
	$log_info{refaddr $self}->{year} = $year;
	$self->_clear_buffer();
	return
}

=head2 next

Returns a hash of the next line of postfix log data.

Hash keys are:

	delay_before_queue, delay_connect_setup, delay_in_queue, 
	delay_message_transmission, from, host, id, msgid, pid, program, 
	relay, size, status, text, timestamp, to, delay, connect,
	disconnect, previous_host, previous_host_name, previous_host_ip

All keys are guaranteed to be present.  'program', 'pid', 'host', 'timestamp',
'id' and 'text' are guaranteed to have a value.  'connect' and 'disconnect' are
boolean: true if the line is the relevant type of line, false otherwise.

The 'text' key will have all of the log text B<after> the standard Postfix
header.  (All of which is in the other keys that are required to have a value.)

=cut

sub _parse_next_line {
#	my ($self) = @_;	# Saves a couple of microseconds per call not to use $self.
						# Given the _extreme_ amounts this method is called,
						# I thought it worth the trade-off.  $_[0] == $self

	# The hash we will return.
	my %line_info = ( program => '' );

	# Some temp variables.
	my $line;
	my @line_data;

	# In a mixed-log enviornment, we can't count on any particular line being
	# something we can parse.  Keep going until we can.
	while ( $line_info{program} !~ m/postfix/ ) {
		# Read the line.
		$line = $_[0]->_get_data_line() or return undef;

		# Start parsing.
		@line_data = split ' ', $line, 7;

		no warnings qw(uninitialized);
		# Program name and pid.
		($line_info{program}, $line_info{pid}) = $line_data[4] =~ m/([^[]+)\[(\d+)\]/;
	}

	# First few fields are the date.  Convert back to Unix format...
	{	# We don't need all these temp variables hanging around.
		my ($log_hour, $log_minutes, $log_seconds) = split /:/, $line_data[2];
		if (!defined($log_info{${$_[0]}}->{year}) ) {
			$line_info{timestamp} = timelocal($log_seconds, $log_minutes, $log_hour, $line_data[1], $MONTH_NUMBER{$line_data[0]}, $CURR_DATE[5]);
		}
		else {
			$line_info{timestamp} = timelocal($log_seconds, $log_minutes, $log_hour, $line_data[1], $MONTH_NUMBER{$line_data[0]}, $log_info{${$_[0]}}->{year});
		}
	}

	# Machine Hostname
	$line_info{host} = $line_data[3];

	# Connection ID
	if ( $line_data[5] =~ m/([^:]+):/ ) {
		$line_info{id} = $1;
	}
	else {
		$line_info{id} = undef;
	}

	# The full rest is given as text.
	if (defined($line_info{id})) {
		$line_info{text} = $line_data[6];
	}
	else {
		$line_info{text} = join ' ', @line_data[5..$#line_data];
	}
	chomp $line_info{text};

	# Stage two of parsing.
	# (These may or may not return any info...)

	# To address
	@{$line_info{to}} = $line_info{text} =~ m/\bto=([^,]+),/g;

	if ( defined($line_info{to}[0]) ) {
		# Relay
		($line_info{relay}) = $line_info{text} =~ m/\brelay=([^,]+),/;

		# Delays
		($line_info{delay_before_queue}, $line_info{delay_in_queue}, $line_info{delay_connect_setup}, $line_info{delay_message_transmission} )
			= $line_info{text} =~ m{\bdelays=([^/]+)/([^/]+)/([^/]+)/([^,]+),};
		($line_info{delay}) = $line_info{text} =~ m/\bdelay=([\d.]+),/;

		# Status
		($line_info{status}) = $line_info{text} =~ m/\bstatus=(.+)\Z/;

		@line_info{'from', 'size', 'msgid', 'connect', 'disconnect', 'previous_host'
					, 'previous_host_name', 'previous_host_ip' } = undef;
	}
	else {
		# From address
		($line_info{from}) = $line_info{text} =~ m/\bfrom=([^,]+),/;

		# Size
		($line_info{size}) = $line_info{text} =~ m/\bsize=([^,]+),/;

		# Message ID
		($line_info{msgid}) = $line_info{text} =~ m/\bmessage-id=(.+)$/;

		# Connect (Boolean)
		$line_info{connect} = $line_info{text} =~ m/\bconnect from/;

		# Disconnect (Boolean)
		$line_info{disconnect} = $line_info{text} =~ m/\bdisconnect from/;

		# Remote host info.  (Only if above.)
		if ( $line_info{connect} || $line_info{disconnect} ) {
			($line_info{previous_host}) = $line_info{text} =~ m/connect from (\S+)/;
			($line_info{previous_host_name}, $line_info{previous_host_ip})
				= $line_info{previous_host} =~ m/([^[]+)\[([^\]]+)\]/;
		}
		else {
			@line_info{'previous_host', 'previous_host_name', 'previous_host_ip'} = undef;
		}

		@line_info{'relay', 'status', 'delay_before_queue', 'delay_in_queue'
					, 'delay_connect_setup', 'delay_message_transmission', 'delay'}
					= undef;
	}

	# Return the data.
	return \%line_info;
}

=head1 BUGS

None known at the moment.

=head1 REQUIRES

L<Scalar::Util>, L<Time::Local>, L<Mail::Log::Parse>, L<Mail::Log::Exceptions>,
L<Memoize>

=head1 AUTHOR

Daniel T. Staal

DStaal@usa.net

=head1 SEE ALSO

L<Mail::Log::Parse>, for the main documentation on this module set.

=head1 HISTORY

April 17, 2009 (1.5.1) - No longer uses C<_set_current_position_as_next_line>,
instead lets Mail::Log::Parse manage automatically.  (Requires 1.4.0.)

April 9, 2009 (1.5.0) - Now reads the connecting host from the 'connect' and
'disconnect' lines in the log.

Feb 27, 2009 (1.4.12) - Quieted an occasional error, if the log line doesn't 
have the standard Postfix format.

Dec 23, 2008 (1.4.11) - Further speedups.  Now requires Mail::Log::Parse of at
least version 1.3.0.

Dec 09, 2008 (1.4.10) - Profiled code, did some speedups.  Added dependency on
Memoize: For large logs this is a massive speedup.  For extremely sparse logs
it may not be, but sparse logs are likely to be small.

Nov 28, 2008 - Switched 'total_delay' to slightly more universal 'delay'.
Sped up some regexes.

Nov 11, 2008 - Switched to using the bufferable C<_parse_next_line> instead of
the unbuffered C<next>.

Nov 6, 2008 - Added C<set_year> and alternate year handling, in case we aren't
dealing with this year's logs.  (From the todo list.)

Oct 24, 2008 - Added 'connect' and 'disconnect' members to the return hash.

Oct 6, 2008 - Initial version.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2008 Daniel T. Staal. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

This copyright will expire in 30 years, or 5 years after the author's
death, whichever is longer.

=cut

# End module package.
}
1;
