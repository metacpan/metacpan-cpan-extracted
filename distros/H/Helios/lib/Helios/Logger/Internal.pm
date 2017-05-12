package Helios::Logger::Internal;

use 5.008;
use base qw(Helios::Logger);
use strict;
use warnings;

use Helios::LogEntry::Levels qw(:all);
use Helios::Error::LoggingError;

our $VERSION = '2.61';

# 2011-12-07:  The code of Helios::Service->logMsg() was moved here to 
# implement internal logging as a Helios::Logger subclass.
# 2012-01-02:  Re-added support for log_priority_threshold config parameter.

=head1 NAME

Helios::Logger::Internal - Helios::Logger subclass implementing Helios internal logging

=head1 SYNOPSIS

 #in helios.ini, enable internal Helios logging (this is default)
 internal_logger=on
 
 #in helios.ini, turn off internal logging 
 # make sure you've turned on another logger with the logger= directive
 # otherwise you will have NO logging system active
 internal_logger=off


=head1 DESCRIPTION

Helios::Logger::Internal is a refactor of the logging functionality found in 
the Helios 2.23 and earlier Helios::Service->logMsg().  This allows Helios 
services to retain logging functionality found in the previous Helios core 
system while also allowing Helios to be extended to support custom logging 
solutions by subclassing Helios::Logger.

=head1 IMPLEMENTED METHODS

=head2 init()

Helios::Logger::Internal->init() attempts to initialize the connection to the 
Helios collective database so it will be available for later calls to logMsg().

=cut

sub init { 
	my $self = shift;
	$self->getDriver();
}


=head2 logMsg($job, $priority_level, $message)

Implementation of the Helios::Service internal logging code refactored into a 
Helios::Logger class.  

=cut

sub logMsg {
	my $self = shift;
	my $job = shift;
	my $level = shift;
	my $msg = shift;

	my $params   = $self->getConfig();
	my $jobType  = $self->getJobType();
	my $hostname = $self->getHostname();

# 2012-01-02:  Re-added support for log_priority_threshold config parameter.
    # if this log message's priority is lower than log_priority_threshold,
    # don't bother logging the message
    if ( defined($params->{log_priority_threshold}) &&
        $level > $params->{log_priority_threshold} ) {
        return 1;
    }
# END 2012-01-02 modification.

	my $retries = 0;
	my $retry_limit = 3;
	RETRY: {
		eval {
			my $driver = $self->getDriver();
			my $log_entry;
			if ( defined($job) ) {
				$log_entry = Helios::LogEntry->new(
					log_time   => time(),
					host       => $self->getHostname(),
					process_id => $$,
					jobid      => $job->getJobid(),
					funcid     => $job->getFuncid(),
					job_class  => $jobType,
					priority   => $level,
					message    => $msg
				);
			} else {
				$log_entry = Helios::LogEntry->new(
					log_time   => time(),
					host       => $self->getHostname(),
					process_id => $$,
					jobid      => undef,
					funcid     => undef,
					job_class  => $jobType,
					priority   => $level,
					message    => $msg
				);
			}
			$driver->insert($log_entry);		
			1;
		} or do {
			my $E = $@;
			if ($retries > $retry_limit) {
				Helios::Error::LoggingError->throw("$E");
			} else {
				# we're going to give it another shot
				$retries++;
				sleep 5;
				next RETRY;
			}
		};
	}
	# retry block end
	return 1;
}


1;
__END__


=head1 SEE ALSO

L<Helios::Service>, L<Helios::Logger>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CEB Toolbox, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

