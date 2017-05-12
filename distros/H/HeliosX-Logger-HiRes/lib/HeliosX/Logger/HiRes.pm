package HeliosX::Logger::HiRes;

use 5.008;
use strict;
use warnings;
use parent 'Helios::Logger';
use constant MAX_RETRIES    => 3;
use constant RETRY_INTERVAL => 5;
use Time::HiRes 'time';

use Helios::LogEntry::Levels ':all';
use Helios::Error::LoggingError;
use HeliosX::Logger::HiRes::LogEntry;

our $VERSION = '1.00';

=head1 NAME

HeliosX::Logger::HiRes - enhanced, high-resolution logging for Helios applications

=head1 SYNOPSIS

 # in a helios.ini file:
 [MyService]
 loggers=HeliosX::Logger::HiRes
 internal_logger=off

 --OR--
 
 # using helios_config_set
 helios_config_set -s MyService -H="*" -p loggers -v HeliosX::Logger::HiRes
 helios_config_set -s MyService -H="*" -p internal_logger -v off 

 # then, use heliosx_logger_hires_search to search the log
 heliosx_logger_hires_search --service=MyService


=head1 DESCRIPTION

HeliosX::Logger::HiRes is a Helios::Logger logging class that provides logging
with high-resolution timestamp precision with a more normalized database
structure.  It also provides L<heliosx_logger_hires_search>, a command to
view and search for log messages at the command line.

=head1 CONFIGURATION

HeliosX::Logger::HiRes must be added to your service using the B<loggers>
directive either using the B<helios_config_set> command or in B<helios.ini>.

Additionally, as HeliosX::Logger::HiRes is largely intended to replace the
Helios internal logger, once you are sure it is working properly in your
installation you should turn off the Helios default logger using the
B<internal_logger=off> option.

See the L<Helios::Configuration> page for complete information about the
B<loggers> and B<internal_logger> directives.

HeliosX::Logger::HiRes itself can be configured using the options below:

=over 4

=item * log_priority_threshold

Unlike L<HeliosX::Logger::Syslog> and L<HeliosX::Logger::Log4perl>,
HeliosX::Logger::HiRes supports the Helios internal logger's
B<log_priority_threshold> option to limit the messages actually being logged
to a certain level.  Unlike the others, HeliosX::Logger::HiRes is intended to
replace rather than augment the Helios internal logger, so most users running
HeliosX::Logger::HiRes will most likely turn off the Helios internal
logger.  Rather than create confusion with a separate threshold option,
HeliosX::Logger::HiRes honors the internal logger's built-in
B<log_priority_threshold> option.

The B<log_priority_threshold> value should be an integer matching one of the
Helios logging priorities in L<Helios::LogEntry::Levels>:

 Priority Name    Integer Value
 LOG_EMERG        0
 LOG_ALERT        1
 LOG_CRIT         2
 LOG_ERR          3
 LOG_WARNING      4
 LOG_NOTICE       5
 LOG_INFO         6
 LOG_DEBUG        7

Examples:

 # in helios.ini
 # for all services on this host, log everything but debug messages
 [global]
 log_priority_threshold=6

 # at the command line, set all instances of MyService
 # to only log warnings and worse
 helios_config_set -s MyService -H="*" -p log_priority_threshold -v 4
 
=back

=head1 IMPLEMENTED METHODS

=head2 init()

HeliosX::Logger::HiRes->init() is empty.

=cut

sub init { }

=head2 logMsg($job, $priority, $message)

The logMsg() method takes a job, priority, and log message and savesthe message
to the high-resolution log table in the Helios collective database.

The job parameter should be a Helios::Job object.  If the job value is
undefined, no jobid is saved with the message.

If the priority parameter is undefined, logMsg() defaults the message's
priority to 6 (LOG_INFO).

=cut

sub logMsg {
    my $self = shift;
    unless (scalar @_ == 3) { Helios::Error::LoggingError->throw(__PACKAGE__."->logMsg() ERROR:  logMsg() requires 3 arguments:  \$job, \$priority, \$message."); }    
    my ($job, $priority, $message) = @_;

    # deal with the log priority & threshold (if set)
    $priority = defined($priority) ? $priority : LOG_INFO;
    my $threshold = defined($self->getConfig()->{log_priority_threshold}) ? $self->getConfig()->{log_priority_threshold} : LOG_DEBUG;
    if ($priority > $threshold) {
        return 1;
    }
    
    my $success = 0;
    my $retries = 0;
    my $err;

    # deal with jobid & jobtypeid
    my $jobid = defined($job) ? $job->getJobid() : undef;
    my $jobtypeid = defined($job) ? $job->getJobtypeid() : undef;
    
    do {
        eval {

            my $drvr = $self->getDriver();
            my $obj = HeliosX::Logger::HiRes::LogEntry->new(
                log_time  => sprintf("%.6f", time()),
                host      => $self->getHostname(),
                pid       => $$,
                jobid     => $jobid,
                jobtypeid => $jobtypeid,
                service   => $self->getService(),
                priority  => $priority,
                message   => $message,
            );
            $drvr->insert($obj);
            1;
        };
        if ($@) {
            $err = $@;
            $retries++;
            sleep RETRY_INTERVAL;
        } else {
            # no exception? then declare success and move on
            $success = 1;
        }
    } until ($success || ($retries > MAX_RETRIES));
    
    unless ($success) {
        Helios::Error::LoggingError->throw(__PACKAGE__."->logMsg() ERROR: $err");
    }
    
    return 1;    
}

1;
__END__


=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify it under 
the terms of the Artistic License 2.0.  See the included LICENSE file for 
details.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut


