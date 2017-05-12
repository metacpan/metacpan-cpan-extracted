package HeliosX::Logger::Syslog;

use 5.008;
use strict;
use warnings;
use base qw(Helios::Logger);

use Sys::Syslog;

use Helios::LogEntry::Levels qw(:all);
use Helios::Error::LoggingError;

our $VERSION = '1.00';

=head1 NAME

HeliosX::Logger::Syslog - Helios::Logger subclass implementing logging to syslogd for Helios

=head1 SYNOPSIS

 # in helios.ini
 loggers=HeliosX::Logger::Syslog
 
 # (optional) specific a syslog facility (defaults to 'user')
 syslog_facility=local1

 # (optional) you can set other syslog options as necessary
 syslog_options=nofatal,pid 

 # (optional) you can set the logmask by using mask values
 # 127 will filter out LOG_DEBUG msgs but log everything else
 syslog_logmask=127

 # (optional) you can also set a threshold (doesn't pass the message to syslog)
 # 3 will log errors and worse, but filter out warnings, notices, etc
 syslog_priority_threshold=3

=head1 DESCRIPTION

This class implments a Helios::Logger subclass to provide Helios applications 
the ability to log messages to syslogd. 

=head1 CONFIGURATION

Config options:

=over 4

=item syslog_facility

The syslogd facility to which to log messages.  If not specified, it will 
default to 'user'.

=item syslog_options

A comma-delimited list of syslog options.  This will be passed as the second 
parameter of openlog().  These options include (from the Sys::Syslog manpage):

=over 4

=item nofatal

When set to true, "openlog()" and "syslog()" will only emit warnings
instead of dying if the connection to the syslog can't be established.

=item nowait

Don't wait for child processes that may have been created while logging
the message.  (The GNU C library does not create a child process, so this option
has no effect on Linux.)

=item perror

Write the message to standard error output as well to the system log.

=item pid  

Include PID with each message.

=back

See the L<Sys::Syslog> manpage for more details.

=item syslog_logmask

Allows you choose which log priorities you want to syslogd to actually log.  
This is like the Helios internal log_priority_threshold, but more capable as 
you can pick and choose which priorities you want, rather than just a range.

Syslogd defines the mask values for priorities as:

 1   = LOG_EMERG
 2   = LOG_ALERT
 4   = LOG_CRIT
 8   = LOG_ERR
 16  = LOG_WARNING
 32  = LOG_NOTICE
 64  = LOG_INFO
 128 = LOG_DEBUG

So, for example, if you wanted to log everything except LOG_DEBUG messages, 
putting:

syslog_logmask=127

in your helios.ini or Ctrl Panel will cause syslogd to filter out messages of 
LOG_DEBUG priority.  In addition, to only log LOG_ERR and LOG_WARNING messages:

syslog_logmask=24

will filter out any messages not of LOG_ERR or LOG_WARNING priority 
(8 + 16 = 24).

=item syslog_priority_threshold

Just like log_priority_threshold, but for syslogd.  If you just want to log 
messages of a certain priority or higher, you can set a numeric value for 
syslog_priority_threshold and any log messages of a higher value (lower 
priority) will be discarded.  The priority levels are defined in 
Helios::LogEntry::Levels (which happen to match syslogd's):

 Helios::LogEntry::Levels   numeric values
 LOG_EMERG                  0
 LOG_ALERT                  1
 LOG_CRIT                   2
 LOG_ERR                    3
 LOG_WARNING                4
 LOG_NOTICE                 5
 LOG_INFO                   6
 LOG_DEBUG                  7

So if you want to discard LOG_DEBUG-level messages but log everything else, 
adding a line like

 syslog_priority_threshold=6

to your helios.ini or Ctrl Panel will discard LOG_DEBUG-level messages but log 
everything else.

The syslog_priority_threshold configuration option is implemented at the Perl 
level, so if your syslogd-based system is experiencing high load, you can use 
it instead of syslog_logmask to reduce demand on your logging system.

It should be noted that although log_priority_threshold and 
B<sys>log_priority_threshold work in exactly the same way, they are in fact 
completely independent.  The log_priority_threshold config option only 
affects the internal Helios logging system (Helios::Logger::Internal), while 
syslog_priority_threshold only affects HeliosX::Logger::Syslog.


=back

=head1 IMPLEMENTED METHODS

=head2 init()

The init() method is empty.

=cut

sub init { }


=head2 logMsg($job, $priority_level, $message)

The logMsg() method logs the given message to the configured syslog_facility with the configured 
syslog_options and the given $priority_level.

=cut

sub logMsg {
    my $self = shift;
    my $job = shift;
    my $priority = shift;
    my $msg = shift;
	my $config = $self->getConfig();
	my $facility;
	my $options;

	# if syslog_priority_threshold is set & this priority 
	# isn't as bad as that, don't bother doing any syslog stuff
	if ( defined($config->{syslog_priority_threshold}) &&
		$priority > $config->{syslog_priority_threshold} )
	{
		return;
	}

	# default to facility 'user'
	if ( !defined($config->{syslog_facility}) ) {
		$facility = 'user';
	} else {
		$facility = $config->{syslog_facility};
	}
	# use options if specified
	if ( defined($config->{syslog_options}) ) {
		$options = $config->{syslog_options};
	}

    openlog($self->getJobType(), $options, $facility);
	if ( defined($config->{syslog_logmask}) ) {
		setlogmask($config->{syslog_logmask});
	}
	syslog($priority, $self->assembleMsg($job, $priority, $msg));
	closelog();
}


=head2 assembleMsg($job, $priority_level, $msg)

Given the information passed to logMsg(), assembleMsg() returns the actual text 
string to be logged to syslogd.  Separating this step into its own method 
allows you to easily override the default message format if you so 
choose.  Simply subclass HeliosX::Logger::Syslog and override assembleMsg() 
with your own message formatting method.

=cut

sub assembleMsg {
	my ($self, $job, $priority, $msg) = @_;
    if ( defined($job) ) { 
    	return 'Job '.$job->getJobid().': '.$msg;
    } else {
    	return $msg;
    }
}


1;
__END__


=head1 SEE ALSO

L<Helios::Service>, L<Helios::Logger>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

COPYRIGHT AND LICENSE

Copyright (C) 2009-12 by Andrew Johnson.

This library is free software; you can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
