package HeliosX::Logger::Log4perl;

use 5.008;
use base qw(Helios::Logger);
use strict;
use warnings;

use Log::Log4perl;

use Helios::LogEntry::Levels qw(:all);
use Helios::Error::LoggingError;

our $VERSION = '1.00';

=head1 NAME

HeliosX::Logger::Log4perl - Helios::Logger subclass implementing logging to Log4perl for Helios

=head1 SYNOPSIS

 # in your helios.ini
 loggers=HeliosX::Logger::Log4perl
 log4perl_conf=/path/to/log4perl.conf
 log4perl_category=logging.category
 log4perl_watch_interval=10
 log4perl_priority_threshold=6
 
 # log4perl supports lots of options, so you can get creative
 # e.g. log everything to log4perl, 
 # but specify which services go to which categories
 [global]
 internal_logging=off
 loggers=HeliosX::Logger::Log4perl
 log4perl_conf=/etc/helios_log4perl.conf
 
 # log all the MyApp::* services to the same log4perl category 
 [MyApp::MetajobBurstService]
 log4perl_category=MyApp
 [MyApp::IndexerService]
 log4perl_category=MyApp
 [MyApp::ReportingService]
 log4perl_category=MyApp
 
 [YourApp]
 # we won't specify a category here, so Helios will default to category 'YourApp'

=head1 DESCRIPTION

This class implements a Helios::Logger class to provide Helios applications  
the logging capabilities of Log4perl.

For information about configuring Log4perl, see the L<Log::Log4perl> documentation.

=head1 HELIOS.INI CONFIGURATION

=head2 log4perl_conf [REQUIRED]

The location of the Log4perl configuration file.  If specified in your 
helios.ini [global] section, the conf file will apply to all of your 
Helios services.  You may also configure different conf files for specific 
services by placing the log4perl_conf line in an individual service's 
helios.ini section.

See the Log4perl documentation for details about configuring Log4perl itself.

=head2 log4perl_category 

The Log4perl "category" to log messages for this service.  If declared in your 
helios.ini [global] section, all Helios services will send log messages to the 
specified category.  If specified in a single service's section, only that 
service will send log messages to the specified category.  You may also declare
a default category in the [global] section, and specific categories for 
particular Helios services, allowing certain services to log to their own 
category but others to default to the global one.  

If log4perl_category is not specified, the Log4perl category will default to 
the name of your service class.

=head2 log4perl_watch_interval

If specified, Log4perl will reread the log4perl_conf file after the given 
number of seconds and update its configuration accordingly.  If this isn't 
specified, any changes to your conf file will require you to restart your 
service daemon to pick up the new configuration.

=head2 log4perl_priority_threshold

Just like log_priority_threshold, but for syslogd.  If you just want to log 
messages of a certain priority or higher, you can set a numeric value for 
log4perl_priority_threshold and any log messages of a higher value (lower 
priority) will be discarded.  The priority levels are defined in 
Helios::LogEntry::Levels.

=head3 Priority Translation

Helios was originally developed using Sys::Syslog as its primary logging 
system.  It eventually developed its own internal logging subsystem, and 
Helios 2.30 added the Helios::Logger interface to further modularize Helios's 
logging capabilities and make it useful in more environments.  Due to this 
history, however, Helios defines 8 logging priorities versus Log4perl's 5.  
HeliosX::Logger::Log4perl translates on-the-fly several of the priority levels 
defined in Helios::LogEntry::Levels to Log4perl's levels:

 numeric value  Helios::LogEntry::Levels   Log::Log4perl::Level
 0              LOG_EMERG                  $FATAL
 1              LOG_ALERT                  $FATAL
 2              LOG_CRIT                   $FATAL
 3              LOG_ERR                    $ERROR
 4              LOG_WARNING                $WARN
 5              LOG_NOTICE                 $INFO
 6              LOG_INFO                   $INFO
 7              LOG_DEBUG                  $DEBUG

=head1 IMPLEMENTED METHODS

=head2 init($config, $jobType)

The init() method verifies log4perl_conf is set in helios.ini and can be read.  It then calls 
Log::Log4perl::init() or (if log4perl_watch_interval is set) Log::Log4perl::init_and_watch() to 
set up the Log4perl system for logging.

=cut

sub init {
    my $self = shift;
    my $config = $self->getConfig();

    unless ( defined($config->{log4perl_conf}) && (-r $config->{log4perl_conf}) ) {
        throw Helios::Error::LoggingError('CONFIGURATION ERROR: log4perl_conf not defined or cannot be read');
    }
    
    if ( defined($config->{log4perl_watch_interval}) ) {
        Log::Log4perl::init_and_watch($config->{log4perl_conf}, $config->{log4perl_watch_interval});
    } else {
        Log::Log4perl::init($config->{log4perl_conf});
    }
    return 1;
}


=head2 logMsg($job, $priority_level, $message)

The logMsg() method logs the given message to the configured log4perl_category with the given 
$priority_level.


=cut

sub logMsg {
    my $self = shift;
    my $job = shift;
    my $level = shift;
    my $msg = shift;
    my $config = $self->getConfig();
    my $logger;

    # has log4perl been initialized yet?
    unless ( Log::Log4perl->initialized() ) {
        $self->init();
    }

	# if syslog_priority_threshold is set & this priority 
	# isn't as bad as that, don't bother doing any syslog stuff
	if ( defined($config->{log4perl_priority_threshold}) &&
		$level > $config->{log4perl_priority_threshold} )
	{
		return;
	}

    # if a l4p category was specified, get a logger for it
    # otherwise, get a logger for the jobtype
    if ( defined($config->{log4perl_category}) ) {
        $logger = Log::Log4perl->get_logger($config->{log4perl_category});
    } else {
        $logger = Log::Log4perl->get_logger($self->getJobType());
    }   

    # assemble message from the parts we have
    $msg = $self->assembleMsg($job, $level, $msg);

    # we shouldn't have to do a level check, since 
    # Helios::Service->logMsg() will default the level to LOG_INFO
    # still, it can't hurt
    if ( defined($level) ) {
        SWITCH: {
            if ($level eq LOG_DEBUG)      { $logger->debug($msg); last SWITCH; }
            if ($level eq LOG_INFO 
                || $level eq LOG_NOTICE)  { $logger->info($msg); last SWITCH; }
            if ($level eq LOG_WARNING)    { $logger->warn($msg); last SWITCH; }
            if ($level eq LOG_ERR)        { $logger->error($msg); last SWITCH; }
            if ($level eq LOG_CRIT 
                || $level eq LOG_ALERT 
                || $level eq LOG_EMERG)   { $logger->fatal($msg); last SWITCH; }
            throw Helios::Error::LoggingError('Invalid log level '.$level);           
        }
    } else {
        # $level wasn't defined, so we'll default to INFO
        $logger->info($msg);
    }
    return 1;
}


=head2 assembleMsg($job, $priority_level, $msg)

Given the information passed to logMsg(), assembleMsg() returns the text 
string to be logged to the Log4perl category.  Separating this step into its 
own method allows you to easily override the default message format if you so 
choose.  Simply subclass HeliosX::Logger::Log4perl and override assembleMsg() 
with your own message formatting method.

=cut

sub assembleMsg {
	my ($self, $job, $level, $msg) = @_;
    if ( defined($job) ) { 
    	return 'Job:'.$job->getJobid().' '.$self->getJobType().' ('.$self->getHostname.') '.$msg;
    } else {
    	return $self->getJobType().' ('.$self->getHostname.') '.$msg;
    }
}



1;
__END__


=head1 SEE ALSO

L<Helios::Service>, L<HeliosX::Logger>, L<Log::Log4perl>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-12 by Andrew Johnson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut
