package Helios::Service;

use 5.008;
use strict;
use warnings;
use base qw( TheSchwartz::Worker );
use File::Spec;
use Sys::Hostname;
use DBI;
use Helios::ObjectDriver::DBI;

use Helios::Error;
use Helios::Job;
use Helios::Config;
use Helios::ConfigParam;
use Helios::LogEntry;
use Helios::LogEntry::Levels qw(:all);
# [LH] [2013-10-04]: Using Helios::JobType instead of TheSchwartz::FuncMap now.
use Helios::JobType;
use Helios::Error::JobTypeError;

our $VERSION = '2.83';

# FILE CHANGE HISTORY:
# [2011-12-07]: Updated to support new Helios::Logger API.  Added 
# %INIT_LOG_CLASSES global.  Completely rewrote logMsg() method.  Updated 
# logMsg() documentation.
# [2011-12-07]: Updated copyright info.
# [2011-12-07]: Removed parseArgXML() method (redundant).
# [2011-12-28]: Removed unnecessary 'use XML::Parser' line.
# [2011-12-28]: Replaced metajob running code in work() with new runMetajob()
# method.
# [2011-12-28]: work(): changed so CACHED_CONFIG and 
# CACHED_CONFIG_RETRIEVAL_COUNT only print to STDOUT if debug() is set.
# [2011-12-28]: Updated copyright info.
# [2012-01-01]: Renamed runMetajob() method to metarun().
# [2012-01-01]: work(): replaced old code calling the service class's run() 
# method.  New code: 1) calls run() or metarun() as appropriate, 2) ignores 
# value returned by run() and metarun() unless DOWNSHIFT_ON_NONZERO_RUN 
# parameter is set, 3) is wrapped in an eval {} to catch uncaught exceptions
# a service class's run() might throw, forcing the job to failure.  Updated
# work() documenation for new functionality.
# [2012-01-01]: Updated copyright info for new year.
# [2012-01-04]: Fixed max_retries() and retry_delay() so they actually pay 
# attention to MaxRetries() and RetryInterval().  In the original code they 
# didn't, and MaxRetries() and RetryInterval() did not work as documented.
# [2012-01-08]: work(): explicitly return 0 to the calling routine. 
# [2012-03-27]: Reorganized use module lines.  Removed unnecessary TheSchwartz &
# TheSchwartz::Job lines.
# [2012-03-27]: work(): added debugging code for new driver and logger code.
# [2012-03-27]: work(): changed try {} to eval {}.
# [2012-03-27]: prep(): Replaced old prep() method with new version that 
# starts new logger and config initialization.
# [2012-03-27]: jobsWaiting(): changed quote operator for query from heredoc 
# to qq{}
# [2012-03-27]: added new setDriver() and initDriver() methods.  Replaced 
# getDriver() method with new one that uses setDriver() and initDriver().
# [2012-03-27]: added initLoggers() method to handle logger module 
# initialization.
# [2012-04-25]: added deferredJob() method.
# [2012-05-20]: work: removed driver and logger debugging code.  Removed 
# comment about removing a debug message before release (it is useful to leave 
# that debugging message in).
# [2012-05-20]: dbConnect(): removed old commented-out code.
# [LH] [2012-07-11]: Switched use line for Data::ObjectDriver::Driver::DBI to 
# load Helios::ObjectDriver::DBI to start integration of database connection 
# caching.
# [LH] [2012-07-15]: Changed prep() to use new Helios::Config class.  Removed 
# 'use Config::IniFiles' because with Helios::Config it's redundant.
# [LH] [2012-07-15]: replaced most of dbConnect() code to implement fork-safe 
# database connection creation and sharing.
# [LH] [2012-07-15]: replaced most of jobWaiting() code for simplicity and to 
# replace try{} with eval {}.
# [LH] [2012-07-15]: replaced most of getFuncidFromDb() code to change try{} 
# to eval{} and eliminate indirect object notation.
# [LH] [2012-07-16]: getFuncidFromDb(): fixed identation of new code.
# [LH] [2012-07-16]: updated copyright notices (added Logical Helion, LLC to 
# main COPYRIGHT section).
# [LH] [2012-08-04]: removed 'use Error' line as all of the try {} blocks have
# been replaced with eval {}.
# [LH] [2012-08-04]: replaced getConfigFromIni() and getConfigFromDb() with 
# versions that use the new Helios::Config API.  Changed POD for both to note
# the methods are deprecated.
# [LH] [2012-08-04]: added new initConfig() method to manage Helios::Config 
# module initialization.
# [LH] [2012-08-04]: added blank default ConfigClass() method.
# [LH] [2012-08-04]: dbConnect(): updated to better handle "options" directives
# and improve connection code.  Updated dbConnect() POD.
# [LH] [2012-08-04]: Reformatted copyright notices for clarity.
# [LH] [2012-08-07]: further changes to getConfigFromIni() and 
# getConfigFromDb() to work with Helios::Config API.
# [LH] [2012-09-05]: removed old commented out code from getConfigFromIni(), 
# getConfigFromDb(), getFuncidFromDb(), dbConnect().
# [LH] [2012-09-05]: Added to POD entry for getFuncidFromDb().
# [LH] [2012-11-06]: Added _require_module() method to safely load modules at 
# runtime.
# [LH] [2012-11-06]: removed old commented out 'use' lines for 
# Config::IniFiles, Data::ObjectDriver::Driver::DBI, Error.
# [LH] [2012-11-06]: corrected grammar in work() documentation.
# [LH] [2012-11-06]: removed old commented out code from prep().
# [LH] [2012-11-06]: removed old commented out code from getDriver().
# [LH] [2012-11-06]: Added ConfigClass() and initConfig() POD.
# [LH] [2013-08-11]: Added code to work() to catch and handle job 
# initialization errors.  [RT79690]
# [LH] [2013-08-19]: Removed old commented out code and clarified comments on 
# job initialization error handling.
# [LH] [2013-10-04]: Added code to start conversion to new Helios class 
# structure and support virtual jobtypes feature.  New new() constructor 
# initializes attribute hashref values and can only be called as a class 
# method.  Added set/get/addJobType(), set/getAltJobTypes(), 
# set/getAltJobtypeids(), addAltJobtypeid(), lookupJobtypeid(), 
# lookupAltJobtypeids().  Switched all code that used TheSchwartz::FuncMap to 
# use Helios::JobType.  Replaced set/getFuncid() with new version that mirrors 
# set/getJobType() (set/getFuncid() will be deprecated on final release).  
# Replaced jobsWaiting() with new version that uses Helios::JobType and scans 
# for all jobtypes (primary and alternates) if alternate jobtypes are set.
# [LH] [2013-10-04]: Removed 'require XML::Simple' line because Helios::Service 
# has not used that in a long time.
# [LH] [2013-10-18]: Added grab_for() and JobLockInterval() to implement new 
# retry API.  Added $CACHED_HOSTNAME and modified prep() to reduce calls to 
# Sys::Hostname::hostname(). 
# [LH] [2013-10-24]: Removed old, already commented out code.  Added POD for 
# new methods added in 2.7x development series.  Marked getFuncidFromDb() as
# deprecated; its function has been replaced by lookupJobtypeid().
# [LH] [2014-02-28]: Changed max_retries() and retry_delay() to default to zero
# rather than undef to eliminate some warnings.
# [LH] [2015-08-14]: Changed all CRLF endings to Unix-style LF endings.

=head1 NAME

Helios::Service - base class for services in the Helios job processing system

=head1 DESCRIPTION

Helios::Service is the base class for all services intended to be run by the 
Helios parallel job processing system.  It handles the underlying TheSchwartz job queue system and 
provides additional methods to handle configuration, job argument parsing, logging, and other 
functions.

A Helios::Service subclass must implement only one method:  the run() method.  The run() method 
will be passed a Helios::Job object representing the job to performed.  The run() method should 
mark the job as completed successfully, failed, or permanently failed (by calling completedJob(),
failedJob(), or failedJobPermanent(), respectively) before it ends.  

=head1 TheSchwartz HANDLING METHODS

The following 3 methods are used by the underlying TheSchwartz job queuing 
system to determine what work is to be performed and, if a job fails, how it 
should be retried.

YOU DO NOT NEED TO TOUCH THESE METHODS TO CREATE HELIOS SERVICES.  These 
methods manage interaction between Helios and TheSchwartz.  You only need to 
be concerned with these methods if you are attempting to extend core Helios
functionality.  

=head2 max_retries()

Controls how many times a job will be retried.  

=head2 retry_delay()

Controls how long (in secs) before a failed job will be retried.  

These two methods should return the number of times a job can be retried if it fails and the 
minimum interval between those retries, respectively.  If you don't define them in your subclass, 
they default to zero, and your job(s) will not be retried if they fail.

=head2 work()

The work() method is the method called by the underlying TheSchwartz::Worker (which in turn is 
called by the helios.pl service daemon) to perform the work of a job.  Effectively, work() sets 
up the worker process for the Helios job, and then calls the service subclass's run() method to 
run it.

The work() method is passed a job object from the underlying TheSchwartz job queue system.  The 
service class is instantiated, and the the job is recast into a Helios::Job object.  The service's 
configuration parameters are read from the system and made available as a hashref via the 
getConfig() method.  The job's arguments are parsed from XML into a Perl hashref, and made 
available via the job object's getArgs() method.  Then the service object's run() method is 
called, and is passed the Helios::Job object.

Once the run() method has completed the job and returned, work() determines 
whether the worker process should exit or stay running.  If OVERDRIVE mode is 
enabled and the service hasn't been HALTed or told to HOLD, the worker process 
will stay running, and work() will be called to setup and run another job.  If 
the service is not in OVERDRIVE mode, the worker process will exit.

=cut

our $CACHED_CONFIG;
our $CACHED_CONFIG_RETRIEVAL_COUNT = 0;
our $WORKER_START_TIME = 0;
# [LH] [2013-10-18]: Added $CACHED_HOSTNAME and modified prep() to reduce calls to 
# Sys::Hostname::hostname().  
our $CACHED_HOSTNAME = '';

our %INIT_LOG_CLASSES;	# for the logging system
our $INIT_CONFIG_CLASS; # for config system

our $DRIVER;	# for caching the Data::ObjectDriver

sub max_retries { $_[0]->MaxRetries() || 0; }
sub retry_delay { $_[0]->RetryInterval() || 0; }
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-18]: Added grab_for() and JobLockInterval() to implement new 
# retry API.  Like TheSchwartz's setup, the JobLockInterval() defaults to 
# 3600 sec (1 hr).
sub grab_for { $_[0]->JobLockInterval() || 3600 }
# END CODE Copyright (C) 2013 by Logical Helion, LLC.

sub work {
	my $class = shift;
	my $schwartz_job = shift;
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
	# 2013-08-11: Rewritten job initialization code to catch job init errors, including [RT79690].
	my $job;
	my $job_init_error;
	eval {
		# turn the schwartz job we were given into: 
		# a custom job object defined by the app class,
		# or a basic Helios::Job object if the app didn't specify anything special
		if ( $class->JobClass() ) {
			# instantiate a custom job object
			$job = $class->JobClass()->new($schwartz_job);
		} else {
			# nothing fancy, just a normal Helios::Job object
			$job = Helios::Job->new($schwartz_job);
		}
		1;
	} or do {
		# uhoh, there was a problem turning the schwartz job into a Helios job
		# note that, and when the worker is fully prepped, 
		# we'll take care of the problem
		$job_init_error = "$@";
	};
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
	$WORKER_START_TIME = $WORKER_START_TIME ? $WORKER_START_TIME : time();     # for WORKER_MAX_TTL 
	my $return_code;
	my $args;

	# instantiate the service class into a worker
	my $self = new $class;
	eval {
	    # if we've previously retrieved a config
        # AND OVERDRIVE is enabled (1) 
        # AND LAZY_CONFIG_UPDATE is enabled (1),
        # AND we're not servicing the 10th job (or technically a multiple of ten)
        # THEN just retrieve the pre-existing config        
        if ($self->debug) {
	        print "CACHED_CONFIG=",$CACHED_CONFIG,"\n";
	        print "CACHED_CONFIG_RETRIEVAL_COUNT=",$CACHED_CONFIG_RETRIEVAL_COUNT,"\n";
        }
        if ( defined($CACHED_CONFIG) && 
                $CACHED_CONFIG->{LAZY_CONFIG_UPDATE} == 1 &&
                $CACHED_CONFIG->{OVERDRIVE} == 1 &&
                $CACHED_CONFIG_RETRIEVAL_COUNT % 10 != 0 
            ) {
            $self->prep(CACHED_CONFIG => $CACHED_CONFIG);
            $CACHED_CONFIG_RETRIEVAL_COUNT++;
            if ($self->debug) { $self->logMsg(LOG_DEBUG,"Retrieved config params from in-memory cache"); } 
        } else {
			$self->prep();

			# prep() just parsed the config for us
			# let's grab the db driver and loggers for use by the next job
			# (if we're in OVERDRIVE; if we're not, there won't be much effect
            if ( defined($self->getConfig()->{LAZY_CONFIG_UPDATE}) && 
                    $self->getConfig()->{LAZY_CONFIG_UPDATE} == 1 ) {
                $CACHED_CONFIG = $self->getConfig();
                $CACHED_CONFIG_RETRIEVAL_COUNT = 1;     # "prime the pump"
            }	    
        }

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
		# 2013-08-11: Rewritten job initialization code to catch job init errors, including [RT79690].
		# if a job initialization error occurred above,
		# we want to log the error and then exit the worker process
		# trying to further job setup and/or run the job is ill-advised,
		# and if we have to exit the process so TheSchwartz doesn't force the job to failure.
		# (but we have to wait and do it here so we can properly log the error)
		if ( defined($job_init_error) ) {
			if ($self->debug) { print "JOB INITIALIZATION ERROR: ".$job_init_error."\n"; }
			$self->logMsg(LOG_CRIT, "JOB INITIALIZATION ERROR: $job_init_error");
			exit(1);
		}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.
	    	    
		$job->debug( $self->debug );
		$job->setConfig($self->getConfig());
# BEGIN CODE Copyright (C) 2011-2012 by Andrew Johnson.
		$job->setDriver($self->getDriver());
		$args = $job->parseArgs();
		1;
	} or do {
		my $E = $@;
		if ( $E->isa('Helios::Error::InvalidArg') ) {
			$self->logMsg($job, LOG_ERR, "Invalid arguments: $E");
			$job->failedNoRetry("$E");			
			exit(1);
		} elsif ( $E->isa('Helios::Error::DatabaseError') ) {
			$self->logMsg($job, LOG_ERR, "Database error: $E");
			$job->failed("$E");
			exit(1);
		} else {
			$self->logMsg($job, LOG_ERR, "Unexpected error: $E");
			$job->failed("$E");
			exit(1);
		}
	};

	# run the job, whether it's a metajob or simple job
	$self->setJob($job);
	eval {
		if ( $job->isaMetaJob() ) {
			# metajob
			if ($self->debug) { print 'CALLING METARUN() for metajob '.$job->getJobid()."...\n"; }
			$return_code = $self->metarun($job);
			if ($self->debug) { print 'METARUN() RETURN CODE: '.$return_code."\n"; }
		} else {
			# must be a simple job then
			if ($self->debug) { print 'CALLING RUN() for job '. $job->getJobid()."...\n"; }
			$return_code = $self->run($job);
			if ($self->debug) { print 'RUN() RETURN CODE: '. $return_code."\n"; }
		}
		1;
	} or do {
		my $E = $@;
		$self->logMsg($job, LOG_CRIT,"Uncaught exception thrown by run() in process ".$$.': '.$E);
		$self->logMsg($job, LOG_CRIT,'Forcing failure of job '.$job->getJobid().' and exit of process '.$$);
		$self->failedJob($job, $E, 1);
		exit(1);
	};

	# DOWNSHIFT_ON_NONZERO_RUN
	# previously a nonzero return from run() was taken to mean a failed job, 
	# and would cause a downshift in OVERDRIVE mode.  This was considered a 
	# safety feature as it was unknown what caused the job to fail.
	# But this feature was underdocumented and misunderstood and has been 
	# removed.  
	# The new default behavior doesn't pay attention to the value returned
	# from run() or metarun().  You should mark your job as completed or 
	# failed in run() or metarun() and not worry about returning anything.
	# Anyone requiring the old behavior can use the new DOWNSHIFT_ON_NONZERO_RUN
	# parameter to enable it.
	if ( defined($self->getConfig()->{DOWNSHIFT_ON_NONZERO_RUN}) &&
			$self->getConfig()->{DOWNSHIFT_ON_NONZERO_RUN} == 1 && 
			$return_code != 0
		) { 
		exit(1); 
	}
# END CODE Copyright (C) 2011-2012 by Andrew Johnson.

	# if we're not in OVERDRIVE, the worker process will exit as soon as work() returns anyway 
	#    (calling shouldExitOverdrive will be a noop)
	# if we're in OVERDRIVE, work() will exit and the worker process will call it again with another job
	# if we were in OVERDRIVE, but now we're NOT, we should explicitly exit() to accomplish the downshift
	if ( $self->shouldExitOverdrive() ) {
		$self->logMsg(LOG_NOTICE,"Class $class exited (downshift)");
		exit(0);
	}

	# we'll assume if we got here, things went reasonably well
	# (run() or metarun() succeeded, or it failed and the errors were caught
	# we're going to return 0 to the calling routine
	# in normal mode, this will immediately return to launch_worker() in helios.pl
	#     (which will exit with this return code)
	# in OVERDRIVE, this will return to TheSchwartz->work_until_done(), which 
	# will call this work() with another TheSchwartz::Job, over and over again
	# until it runs out of jobs.  When the jobs are exhausted, then it returns
	# to launch_worker() in helios.pl (which then exits with this return code)
	return 0;
}

# BEGIN CODE Copyright (C) 2011-2012 by Andrew Johnson.

=head2 metarun($job)

Given a metajob, the metarun() method runs the job, returning 0 if the 
metajob was successful and nonzero otherwise.

This is the default metarun() for Helios.  In the default Helios system, 
metajobs consist of multiple simple jobs.  These jobs are defined in the 
metajob's argument XML at job submission time.  The metarun() method will 
burst the metajob apart into its constituent jobs, which are then run by 
another service.  

Metajobs' primary use in the base Helios system is to speed the job submission 
process of large job batches.  One metajob containing a batch of thousands of 
jobs can be submitted and burst apart by the system much faster than thousands 
of individual jobs can be submitted.  In addition, the faster jobs enter the 
job queue, the faster Helios workers can be launched to handle them.  If you 
have thousands (or tens of thousands, or more) of jobs to run, especially if 
you are running your service in OVERDRIVE mode, you should use metajobs to 
greatly increase system throughput.

=cut

sub metarun {
	my $self = shift;
	my $metajob = shift;
	my $config = $self->getConfig();
	my $args = $metajob->getArgs();
	my $r;
	
	eval {
		$self->logMsg($metajob, LOG_NOTICE, 'Bursting metajob '.$metajob->getJobid);
		my $jobCount = $self->burstJob($metajob);
		$self->logMsg($metajob, LOG_NOTICE, 'Metajob '.$metajob->getJobid().' burst into '.$jobCount.' jobs.');
		1;
	} or do {
		my $E = $@;
		if ( $E->isa('Helios::Error::BaseError') ) {
			$self->logMsg($metajob, 
					LOG_ERR, 
					'Metajob burst failure for metajob '
					.$metajob->getJobid().': '
					.$E->text()
			);
		} else {
			$self->logMsg($metajob, 
					LOG_ERR, 
					'Metajob burst failure for metajob '
					.$metajob->getJobid().': '
					.$E
			);
		}
	};
}
# END CODE Copyright (C) 2011-2012 by Andrew Johnson.


=head1 ACCESSOR METHODS

These accessors will be needed by subclasses of Helios::Service.

 get/setConfig()
 get/setHostname()
 get/setIniFile()
 get/setJob()
 get/setJobType()
 get/setAltJobTypes(), addAltJobType()
 get/setJobTypeid()
 get/setAltJobtypeids(), addAltJobtypeid()
 errstr()
 debug()

Most of these are handled behind the scenes simply by calling the prep() method.

After calling prep(), calling getConfig() will return a hashref of all the configuration parameters
relevant to this service class on this host.

If debug mode is enabled (the HELIOS_DEBUG env var is set to 1), debug() will return a true value, 
otherwise, it will be false.  Some of the Helios::Service methods will honor this value and log 
extra debugging messages either to the console or the Helios log (helios_log_tb table).  You can 
also use it within your own service classes to enable/disable debugging messages or behaviors.

=cut

sub setJob { $_[0]->{job} = $_[1]; }
sub getJob { return $_[0]->{job}; }

# need for helios.pl logging	
sub setJobType { $_[0]->{jobType} = $_[1]; }
sub getJobType { return $_[0]->{jobType}; }

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04] Virtual jobtype code.
sub setAltJobTypes {
	my $self = shift;
	$self->{altJobTypes} = [@_];
}
sub getAltJobTypes {
	if ( defined $_[0]->{altJobTypes} ) {
		return @{ $_[0]->{altJobTypes} };
	} else {
		return undef;
	}
}
sub addAltJobType {
	push(@{ $_[0]->{altJobTypes} }, $_[1]);
}

# [LH] [2013-10-04] Virtual jobtype code.
sub setJobtypeid { $_[0]->{jobtypeid} = $_[1]; }
sub getJobtypeid { return $_[0]->{jobtypeid}; }

sub setAltJobtypeids {
	my $self = shift;
	$self->{altJobtypeids} = [@_];
}
sub getAltJobtypeids {
	if ( defined $_[0]->{altJobtypeids} ) {
		return @{ $_[0]->{altJobtypeids} };
	} else {
		return undef;
	}
}
sub addAltJobtypeid {
	push(@{ $_[0]->{altJobtypeids} }, $_[1]);
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.


sub setConfig { $_[0]->{config} = $_[1]; }
sub getConfig { return $_[0]->{config}; }

# [LH] [2013-10-04]: Virtual jobtypes.  Changed set/getFuncid() for 
# compatibility with set/getJobtypeid().  Set/getFuncid() is DEPRECATED;
# retained for now for backward compatibility with Helios 2.6x and earlier.
sub setFuncid { $_[0]->{jobtypeid} = $_[1]; }
sub getFuncid { return $_[0]->{jobtypeid}; }

sub setIniFile { $_[0]->{inifile} = $_[1]; }
sub getIniFile { return $_[0]->{inifile}; }

sub setHostname { $_[0]->{hostname} = $_[1]; }
sub getHostname { return $_[0]->{hostname}; }

# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.
# these are class methods!
sub setDriver { 
	$DRIVER = $_[1];
}
sub getDriver {
	initDriver(@_);
}
# END CODE Copyright Andrew Johnson.

sub errstr { my $self = shift; @_ ? $self->{errstr} = shift : $self->{errstr}; }
sub debug { my $self = shift; @_ ? $self->{debug} = shift : $self->{debug}; }

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04] New constructor initializes attributes in the underlying
# object structure and can only be called as a class method.  

=head1 CONSTRUCTOR

=head2 new()

The new() method creates a new service class instance.  It initializes all of 
the underlying attribute values and sets the instance's jobType to the name of 
the class.

=cut

sub new {
	my $cl = shift;
	my $self = {
		'jobType'       => undef,
		'altJobTypes'   => undef,
		'jobtypeid'     => undef,
		'altJobtypeids' => undef,
		'hostname'      => undef,
		'inifile'       => undef,
		'job'           => undef,
		
		'config' => undef,
		'debug'  => undef,
		'errstr' => undef,
	};
	bless $self, $cl;

	# init fields
	my $jobtype = $cl;
	$self->setJobType($jobtype);

	return $self;
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.


=head1 INTERNAL SERVICE CLASS METHODS

When writing normal Helios services, the methods listed in this section will 
have already been dealt with before your run() method is called.  If you are 
extending Helios itself or instantiating a Helios service outside of Helios 
(for example, to retrieve a service's config params), you may be interested in 
some of these, primarily the prep() method. 

=head2 prep()

The prep() method is designed to call all the various setup routines needed to 
get the service ready to do useful work.  It:

=over 4

=item * 

Pulls in the contents of the HELIOS_DEBUG and HELIOS_INI env vars, and sets the appropriate 
instance variables if necessary.

=item *

Calls the getConfigFromIni() method to read the appropriate configuration parameters from the 
INI file.

=item *

Calls the getConfigFromDb() method to read the appropriate configuration parameters from the 
Helios database.

=back

Normally it returns a true value if successful, but if one of the getConfigFrom*() methods throws 
an exception, that exception will be raised to your calling routine.

=cut

# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.

sub prep {
	my $self = shift;
	my %params = @_;
	my $cached_config;
	my $driver;
	my $loggers;
	my $inifile;

	# if we were explicitly given setup information, use that 
	# instead of setting up new ones
	if ( defined($params{CACHED_CONFIG}) ) {
		$cached_config = $params{CACHED_CONFIG};
	}
	if ( defined($params{DRIVER}) ) {
		$driver = $params{DRIVER};
	}
	if ( defined($params{LOGGERS}) && keys(%{$params{LOGGERS}}) ) {
		$loggers = $params{LOGGERS};
	}
	if ( defined($params{INIFILE}) ) {
		$inifile = $params{INIFILE};
	}

	# pull other parameters from environment

# END CODE Copyright (C) 2012 by Andrew Johnson.
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
	# If hostname value is not set,
	# 1) use the cached value if we have one, or 
	# 2) go ahead and call hostname() (and cache it for later)
	if ( !defined($self->getHostname()) ) {
	# [LH] [2013-10-18] Changed hostname handling to reduce hostname lookups.
		if ( $CACHED_HOSTNAME ) {
			$self->setHostname($CACHED_HOSTNAME);
		} else {
			$CACHED_HOSTNAME = hostname();
			$self->setHostname($CACHED_HOSTNAME);
		}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.		
# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.
	}
	
	if ( defined($ENV{HELIOS_DEBUG}) ) {
		$self->debug($ENV{HELIOS_DEBUG});
	}
	SWITCH: {
		# explicitly giving an inifile to prep() overrides everything
		if ( defined($inifile) ) { $self->setIniFile($inifile); last SWITCH; }
		# if inifile is already set, we'll leave it alone
		if ( defined($self->getIniFile()) ) { last SWITCH; }
		# we'll pull in the HELIOS_INI environment variable
		if ( defined($ENV{HELIOS_INI}) ) { $self->setIniFile($ENV{HELIOS_INI}); }
	}
	
	if ( defined($cached_config) ) {
		$self->setConfig($cached_config);
		return 1;        
    } else {
		# initialize config module if it isn't already initialized
		unless ($INIT_CONFIG_CLASS) {
			$INIT_CONFIG_CLASS = $self->initConfig();
		}
		my $conf = $INIT_CONFIG_CLASS->parseConfig();

		$self->setConfig($conf);
	}

	# use the given D::OD driver if we were given one
	# otherwise call getDriver() to make sure we have one
	if ( defined($driver) ) {
		$self->setDriver($driver);
	} else {
		$self->getDriver();
	}
	
	# make sure loggers are init()ed
	unless ( defined($loggers) ) {	
		$self->initLoggers();
	}

	return 1;
}
# END Code Copyright Andrew Johnson.

=head2 getConfigFromIni([$inifile]) DEPRECATED

The getConfigFromIni() method opens the helios.ini file, grabs global params and config params relevant to
the current service class, and returns them in a hash to the calling routine.  It also sets the class's 
internal {config} hashref, so the config parameters are available via the getConfig() method.

Typically service classes will call this once near the start of processing to pick up any relevant 
parameters from the helios.ini file.  However, calling the prep() method takes care of this for 
you, and is the preferred method.

=cut

sub getConfigFromIni {
	my $self = shift;
	my $inifile = shift;

# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
# getConfigFromIni() is no longer necessary.
	
	unless ($INIT_CONFIG_CLASS) {
		if ( defined($inifile) ) { $self->setIniFile($inifile); }
		$INIT_CONFIG_CLASS = $self->initConfig();
	}
	my $conf = $INIT_CONFIG_CLASS->parseConfFile();
	$self->setConfig($conf);
	return %{$conf};
# END CODE Copyright (C) 2012 by Logical Helion, LLC.

}


=head2 getConfigFromDb() DEPRECATED

The getConfigFromDb() method connects to the Helios database, retrieves config params relevant to the 
current service class, and returns them in a hash to the calling routine.  It also sets the class's 
internal {config} hashref, so the config parameters are available via the getConfig() method.

Typically service classes will call this once near the start of processing to pick up any relevant 
parameters from the helios.ini file.  However, calling the prep() method takes care of this for 
you.

There's an important subtle difference between getConfigFromIni() and getConfigFromDb():  
getConfigFromIni() erases any previously set parameters from the class's internal {config} hash, 
while getConfigFromDb() merely updates it.  This is due to the way helios.pl uses the methods:  
the INI file is only read once, while the database is repeatedly checked for configuration 
updates.  For individual service classes, the best thing to do is just call the prep() method; it 
will take care of things for the most part.

=cut

sub getConfigFromDb {
	my $self = shift;
	my $params = $self->getConfig();

# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.
# getConfigFromDb() method is no longer necessary.

	unless ($INIT_CONFIG_CLASS) {
		$INIT_CONFIG_CLASS = $self->initConfig();
	}
	my $dbconf = $INIT_CONFIG_CLASS->parseConfDb();
	while (my ($key, $value) = each %$dbconf ) {
		$params->{$key} = $value;
	}
	$self->setConfig($params);
	return %{$params};
# END CODE Copyright (C) 2012 by Logical Helion, LLC.

}


=head2 getFuncidFromDb() [DEPRECATED]

Queries the collective database for the funcid of the service class and 
returns it to the calling routine.  The service name used in the query is the 
value returned from the getJobType() accessor method.  

This method is most commonly used by helios.pl to get the funcid associated 
with a particular service class, so it can scan the job table for waiting jobs.
If their are jobs for the service waiting, helios.pl may launch new worker 
processes to perform these jobs.

As of Helios 2.80, getFuncidFromDb() has been replaced by lookupJobtypeid().  
This method is thus deprecated.

=cut

sub getFuncidFromDb {
    my $self = shift;
    my $params = $self->getConfig();
    my $jobtype = $self->getJobType();
    my @funcids;

    if ($self->debug) { print "Retrieving funcid for ".$self->getJobType()."\n"; }

	eval {
		my $driver = $self->getDriver();
		# also get the funcid 
		my @funcids = $driver->search('TheSchwartz::FuncMap' => { funcname => $jobtype });
		if ( scalar(@funcids) > 0 ) {
			$self->setFuncid( $funcids[0]->funcid() );
		}
		1;
	} or do {
		my $E = $@;
		Helios::Error::DatabaseError->throw("$E");
	};

	return $self->getFuncid();	
}


# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04] Virtual jobtype code.
=head2 lookupAltJobtypeids(@jobtypenames)

The lookupAltJobtypeids() method uses the lookupJobtypeid() method to determine 
the jobtypeids of all of the service instance's alternate jobtypes.  If given 
a list of jobtype names, these will override any jobtypes previously set with
the setAltJobTypes() or addAltJobType() methods.

Usually, "alternate" jobtypes and jobtypes specified on the helios.pl 
command line using the --jobtypes option.  The "primary" jobtype is the jobtype
matching the service class's name.

=cut

sub lookupAltJobtypeids {
	my $self = shift;
	my @jobtypes = @_ || $self->getAltJobTypes();
	my $config = $self->getConfig();
	my @ids;
	
	for (@jobtypes) {
		my $jtid = $self->lookupJobtypeid($_);
		unless ($jtid) { Helios::Error::JobTypeError->throw("lookupAltJobtypeids(): $_ cannot be found in collective database."); }
		push(@ids, $jtid);
		$self->addAltJobtypeid($jtid);
	}
	return @ids;
}


=head2 lookupJobtypeid($jobtypename)

Given the name of a jobtype, lookupJobtypeid() uses the Helios::JobType class 
to find the jobtypeid of the jobtype and returns it to the calling routine.  
If the jobtype does not exist, the method returns undef.

=cut

sub lookupJobtypeid {
	my $self = shift;
	my $jt = shift;

	my $jobtype = Helios::JobType->lookup(name => $jt, config => $self->getConfig());
	if ($jobtype) {
		return $jobtype->getJobtypeid();
	} else {
		return undef;
	}
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.


=head2 jobsWaiting() 

Scans the job queue for jobs that are ready to run.  Returns the number of jobs 
waiting.  Only meant for use with the helios.pl service daemon.

=cut

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
# [LH] [2013-10-04] jobsWaiting() replaced with new version for virtual 
# jobtypes.    
sub jobsWaiting {
	my $self = shift;
	my $num_of_jobs = 0;
	my $primary_jobtypeid = $self->getJobtypeid();
	my @alt_jobtypeids;
	my $sth;
	eval {
		my $dbh = $self->dbConnect();
		unless ( defined($primary_jobtypeid) ) {
			$primary_jobtypeid = $self->lookupJobtypeid($self->getJobType);
			$self->setJobtypeid($primary_jobtypeid);
		}
		if ( $self->getAltJobTypes() ) {
			if ( $self->getAltJobtypeids() ) {
				@alt_jobtypeids = $self->getAltJobtypeids();
			} else {
				@alt_jobtypeids = $self->lookupAltJobtypeids();
			}
		}
		
		if (@alt_jobtypeids) {
			my @plhrs = ('?');	# one for the primary
			for (@alt_jobtypeids) { push(@plhrs,'?'); }
			my $plhrs_str = join(',' => @plhrs);

			$sth = $dbh->prepare_cached("SELECT COUNT(*) FROM job WHERE funcid IN($plhrs_str) AND (run_after < ?) AND (grabbed_until < ?)");
			$sth->execute($primary_jobtypeid, @alt_jobtypeids, time(), time());
		} else {
			$sth = $dbh->prepare_cached('SELECT COUNT(*) FROM job WHERE funcid = ? AND (run_after < ?) AND (grabbed_until < ?)');
			$sth->execute($primary_jobtypeid, time(), time());
		}
		my $r = $sth->fetchrow_arrayref();
		$sth->finish();
		$num_of_jobs = $r->[0];
		
		1;
	} or do {
		my $E = $@;
		Helios::Error::DatabaseError->throw("$E");
	};
	
	return $num_of_jobs;
}
# END CODE Copyright (C) 2013 by Logical Helion, LLC.


# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.

=head2 initDriver()

Creates a Data::ObjectDriver object connected to the Helios database and 
returns it to the calling routine.  Normally called by getDriver() if an 
D::OD object has not already been initialized.

The initDriver() method calls setDriver() to cache the D::OD 
object for use by other methods.  This will greatly reduce the number of open 
connections to the Helios database.

=cut

sub initDriver {
	my $self = shift;
	my $config = $self->getConfig();
	if ($self->debug) { print $config->{dsn},$config->{user},$config->{password},"\n"; }
	my $driver = Helios::ObjectDriver::DBI->new(
	    dsn      => $config->{dsn},
	    username => $config->{user},
	    password => $config->{password}
	);	
	if ($self->debug) { print "initDriver() DRIVER: ",$driver,"\n"; }
	$self->setDriver($driver);
	return $driver;	
}
# END CODE Copyright (C) 2012 by Andrew Johnson.

=head2 shouldExitOverdrive()

Determine whether or not to exit if OVERDRIVE mode is enabled.  The config 
params will be checked for HOLD, HALT, or OVERDRIVE values.  If HALT is defined 
or HOLD == 1 this method will return a true value, indicating the worker 
process should exit().

This method is used by helios.pl and Helios::Service->work().  Normal Helios
services do not need to use this method directly.

=cut

sub shouldExitOverdrive {
	my $self = shift;
	my $params = $self->getConfig();
	if ( defined($params->{HALT}) ) { return 1; }
	if ( defined($params->{HOLD}) && $params->{HOLD} == 1) { return 1; }
	if ( defined($params->{WORKER_MAX_TTL}) && $params->{WORKER_MAX_TTL} > 0 && 
	       time() > $WORKER_START_TIME + $params->{WORKER_MAX_TTL} ) {
        return 1;
    }
	return 0;
}



=head1 METHODS AVAILABLE TO SERVICE SUBCLASSES

The methods in this section are available for use by Helios services.  They 
allow your service to interact with the Helios environment.

=cut

# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.

=head2 dbConnect($dsn, $user, $password, $options)

Method to connect to a database in a "safe" way.  If the connection parameters 
are not specified, a connection to the Helios collective database will be 
returned.  If a connection to the given database already exists, dbConnect() 
will return a database handle to the existing connection rather than create a 
new connection.

The dbConnect() method uses the DBI->connect_cached() method to reuse database 
connections and thus reduce open connections to your database (often important
when you potentially have hundreds of active worker processes working in a 
Helios collective).  It "tags" the connections it creates with the current PID 
to prevent reusing a connection that was established by a parent process.  
That, combined with helios.pl clearing connections after the fork() to create 
a worker process, should allow for safe database connection/disconnection in 
a forking environment.

=cut

sub dbConnect {
	my $self = shift;
	my $dsn = shift;
	my $user = shift;
	my $password = shift;
	my $options = shift;
	my $params = $self->getConfig();
	my $connect_to_heliosdb = 0;

	# if we weren't given params, 
	# we'll default to the Helios collective database
	unless ( defined($dsn) ) {
		$dsn = $params->{dsn};
		$user = $params->{user};
		$password = $params->{password};
		$options = $params->{options};
		$connect_to_heliosdb = 1;
	}

	my $dbh;
	my $o;

	eval {

		# if we were given options, parse them into a hashref
		# throw a config error if this fails
		if ($options) {
			$o = eval "{$options}";
			Helios::Error::ConfigError->throw($@) if $@;
		}
		
		# if we're connecting to the collective db, 
		# we _must_ force certain options to make sure the "new" connection
		# doesn't disrupt Helios operations
		# (Previous dbConnect() code didn't properly handle connection creation
		#  because it effectively ignored the "options" config param
		if ( $connect_to_heliosdb ) {
			$o->{RaiseError} = 1;
			$o->{AutoCommit} = 1;
		}
		# ALL db connections created by dbConnect() get a "tag" 
		# this is to generally make sure if a fork has happened, 
		# we don't allow DBI to reuse a connection the parent made
		# (helios.pl should be clearing those now, though)
		$o->{'private_heliconn_dbconnect_'.$$} = $$;
		
		# debug
		if ($self->debug) { 
			print "dbConnect():\n\tdsn=$dsn\n";
			if ( defined($user)   ) { print "\tuser=$user\n"; }
			if ( defined($options)) { print "\toptions=$options\n"; } 
		}	

		# make the connection!
		$dbh = DBI->connect_cached($dsn, $user, $password, $o);	

		# if we *didn't* get a database connection, we have to throw an error
		unless ( defined($dbh) ) {
			Helios::Error::DatabaseError->throw($DBI::errstr);
		}

		1;
	} or do {
		# whatever exception was thrown, 
		# we're going to cast it into a DatabaseError
		my $E = $@;
		Helios::Error::DatabaseError->throw("$E");
	};
	
	return $dbh;
}
# END CODE Copyright (C) 2012 by Logical Helion, LLC.


=head2 logMsg([$job,] [$priority_level,] $message)

Given a message to log, an optional priority level, and an optional Helios::Job
object, logMsg() will record the message in the logging systems that have been 
configured.  The internal Helios logging system is the only system enabled by 
default.

In addition to the log message, there are two optional parameters:

=over 4

=item $job

The current Helios::Job object being processed.  If specified, the jobid will 
be logged in the database along with the message.

=item $priority

The priority level of the message as defined by Helios::LogEntry::Levels.  
These are really integers, but if you import Helios::LogEntry::Levels (with the 
:all tag) into your namespace, your logMsg() calls will be much more readable.  
There are 8 log priority levels, corresponding (for historical reasons) to 
the log priorities defined by Sys::Syslog:

    name         priority
    LOG_EMERG    0
    LOG_ALERT    1
    LOG_CRIT     2
    LOG_ERR      3
    LOG_WARNING  4
    LOG_NOTICE   5
    LOG_INFO     6
    LOG_DEBUG    7
   
LOG_DEBUG, LOG_INFO, LOG_NOTICE, LOG_WARNING, and LOG_ERR are the most common 
used by Helios itself; LOG_INFO is the default.

=back

The host, process id, and service class are automatically recorded with your log 
message.  If you supplied either a Helios::Job object or a priority level, these
will also be recorded with your log message.

This method returns a true value if successful and throws a 
Helios::Error::LoggingError if errors occur.   

=head3 LOGGING SYSTEM CONFIGURATION

Several parameters are available to configure Helios logging.  Though these 
options can be set either in helios.ini or in the Ctrl Panel, it is B<strongly>
recommended these options only be set in helios.ini.  Changing logging 
configurations on-the-fly could potentially cause a Helios service (and 
possibly your whole collective) to become unstable!

The following options can be set in either a [global] section or in an 
application section of your helios.ini file.

=head4 loggers

 loggers=HeliosX::Logger::Syslog,HeliosX::Logger::Log4perl

A comma delimited list of interface classes to external logging systems.  Each 
of these classes should implement (or otherwise extend) the Helios::Logger 
class.  Each class will have its own configuration parameters to 
set; consult the documentation for the interface class you're trying to 
configure.

=head4 internal_logger 

 internal_logger=on|off 

Whether to enable the internal Helios logging system as well as the loggers 
specified with the 'loggers=' line above.  The default is on.  If set to off, 
the only logging your service will do will be to the external logging systems.

=head4 log_priority_threshold

 log_priority_threshold=1|2|3|4|5|6   

You can specify a logging threshold to better control the 
logging of your service on-the-fly.  Unlike the above parameters, 
log_priority_threshold can be safely specified in your Helios Ctrl Panel.  
Specifying a 'log_priority_threshold' config parameter in your helios.ini or 
Ctrl Panel will cause log messages of a lower priority (higher numeric value) 
to be discarded.  For example, a line in your helios.ini like:

 log_priority_threshold=6

will cause any log messages of priority 7 (LOG_DEBUG) to be discarded.

This configuration option is supported by the internal Helios logger 
(Helios::Logger::Internal).  Other Helios::Logger systems may or may not 
support it; check the documentation of the logging module you plan to use.

If anything goes wrong with calling the configured loggers' logMsg() methods,
this method will attempt to catch the error and log it to the 
Helios::Logger::Internal internal logger.  It will then rethrow the error 
as a Helios::Error::LoggingError exception.

=cut

# BEGIN CODE Copyright (C) 2009-12 by Andrew Johnson.
sub logMsg {
	my $self = shift;
	my @args = @_;
	my $job;
	my $level;
	my $msg;
	my @loggers;


	# were we called with 3 params?  ($job, $level, $msg)
	# 2 params?                      ($level, $msg) or ($job, $msg)
	# or just 1?                     ($msg)

	# is the first arg is a Helios::Job object?
	if ( ref($args[0]) && $args[0]->isa('Helios::Job') ) {
		$job = shift @args;
	}

	# if there are 2 params remaining, the first is level, second msg
	# if only one, it's just the message 
	if ( defined($args[0]) && defined($args[1]) ) {
		$level = $args[0];
		$msg = $args[1];
	} else {
		$level = LOG_INFO;	# default the level to LOG_INFO
		$msg = $args[0];
	}

	# the loggers should already know these, 
	# but in case of emergency we'll need them	
	my $config = $self->getConfig();
	my $jobType = $self->getJobType();
	my $hostname = $self->getHostname();
	my $driver = $self->getDriver();

	foreach my $logger (keys %INIT_LOG_CLASSES) {
		eval {
			$logger->logMsg($job, $level, $msg);
			1;
		} or do {
            my $E = $@;
            print "$E\n"; 
            Helios::Logger::Internal->setConfig($config);
            Helios::Logger::Internal->setJobType($jobType);
            Helios::Logger::Internal->setHostname($hostname);
			Helios::Logger::Internal->setDriver($driver);
            Helios::Logger::Internal->init();
            Helios::Logger::Internal->logMsg(undef, LOG_EMERG, $logger.' LOGGING FAILURE: '.$E);
		};			
	}
	
	return 1;	
}
# END CODE Copyright (C) 2009-12 by Andrew Johnson.


# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.

=head2 initConfig()

The initConfig() method is called to initialize the configuration parsing 
class.  This method is normally called by the prep() method before a service's 
run() method is called; most Helios application developers do not need to 
worry about this method.

The normal Helios config parsing class is Helios::Config.  This can be 
changed by specifying another config class with the ConfigClass() method in 
your service.

This method will throw a Helios::Error::ConfigError if anything goes wrong 
with config class initialization.

=cut

sub initConfig {
	my $self = shift;
	my $config_class = $self->ConfigClass() ? $self->ConfigClass() : 'Helios::Config';
	
	# only initialize the config system once
	unless( defined($INIT_CONFIG_CLASS) ) {

#		if ( $config_class !~ /^[A-Za-z]([A-Za-z0-9_\-]|:{2})*[A-Za-z0-9_\-]$/ ) {
#			Helios::Error::ConfigError->throw("Requested Config class name is invalid: ".$config_class);
#		}
#
#		# attempt class load if it hasn't been already
#		unless ( $config_class->can('init') ) {
#			eval "require $config_class";
#		    Helios::Error::ConfigError->throw($@) if $@;
#		}

		$self->_require_module($config_class, 'Helios::Config');
		
		$config_class->init(
			CONF_FILE => $self->getIniFile(),
			SERVICE   => $self->getJobType(),
			HOSTNAME  => $self->getHostname(),
			DEBUG     => $self->debug()
		);
		$INIT_CONFIG_CLASS = $config_class;
	}
	return $config_class;
}

# END CODE Copyright (C) 2012 by Logical Helion, LLC.


=head2 initLoggers()

The initLoggers() method is called to initialize all of the configured 
Helios::Logger classes.  This method is normally called by the prep() method
before a service's run() method is called.

This method sets up the Helios::Logger subclass's configuration by calling 
setConfig(), setHostname(), setJobType(), and setDriver().  It then calls the
logger's init() method to finish the initialization phase of the logging class.

This method will throw a Helios::Error::Logging error if anything goes wrong 
with the initialization of a logger class.  It will also attempt to fall back 
to the Helios::Logger::Internal logger to attempt to log the initialization 
error.

=cut

# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.

sub initLoggers {
	my $self = shift;
	my $config = $self->getConfig();
	my $jobType = $self->getJobType();
	my $hostname = $self->getHostname();
	my $driver = $self->getDriver();
	my $debug = $self->debug();
	my @loggers;

    # grab the names of all the configured loggers to try
    if ( defined($config->{loggers}) ) {
	    @loggers = split(/,/, $config->{loggers});
    }
    
    # inject the internal logger automatically
    # UNLESS it has been specifically turned off
    unless ( defined($config->{internal_logger}) && 
        ( $config->{internal_logger} eq 'off' || $config->{internal_logger} eq '0') ) {
    	unshift(@loggers, 'Helios::Logger::Internal');
    }


	foreach my $logger (@loggers) {
		# init the logger if it hasn't been initialized yet
		unless ( defined($INIT_LOG_CLASSES{$logger}) ) {
#			if ( $logger !~ /^[A-Za-z]([A-Za-z0-9_\-]|:{2})*[A-Za-z0-9_\-]$/ ) {
#				Helios::Error::LoggingError->throw("Sorry, requested Logger name is invalid: ".$logger);
#			}
#			# attempt to init the class
#			unless ( $logger->can('init') ) {
#		        eval "require $logger";
#		        throw Helios::Error::LoggingError($@) if $@;
#			}
			$self->_require_module($logger,'Helios::Logger');
			$logger->setConfig($config);
			$logger->setJobType($jobType);
			$logger->setHostname($hostname);
			$logger->setDriver($driver);
#			$logger->debug($debug);
            eval {
    			$logger->init();
				1;
            } or do {
            	# our only resort is to use the internal logger
            	my $E = $@;
            	print "$E\n";
                Helios::Logger::Internal->setConfig($config);
                Helios::Logger::Internal->setJobType($jobType);
                Helios::Logger::Internal->setHostname($hostname);
				Helios::Logger::Internal->setDriver($driver);
                Helios::Logger::Internal->init();
            	Helios::Logger::Internal->logMsg(undef, LOG_EMERG, $logger.' CONFIGURATION ERROR: '.$E);
				# we need to go ahead and rethrow the error to stop the init process
				Helios::Error::LoggingError->throw($E);
            };
			$INIT_LOG_CLASSES{$logger} = $logger;
			if ($self->debug) { print "Initialized Logger: $logger\n"; }
		}
	}
}
# END CODE Copyright (C) 2012 by Andrew Johnson.


=head2 getJobArgs($job)

Given a Helios::Job object, getJobArgs() returns a hashref representing the 
parsed job argument XML.  It actually calls the Helios::Job object's parseArgs()
method and returns its value.

=cut

sub getJobArgs {
	my $self = shift;
	my $job = shift;
	return $job->getArgs() ? $job->getArgs() : $job->parseArgs();
}


=head1 JOB COMPLETION METHODS

These methods should be called in your Helios service class's run() method to 
mark a job as successfully completed, failed, or failed permanently.  They 
actually call the appropriate methods of the given Helios::Job object.

=head2 completedJob($job)

Marks $job as completed successfully.

=cut

sub completedJob {
	my $self = shift;
	my $job = shift;
	return $job->completed();
}


=head2 failedJob($job [, $error][, $exitstatus])

Marks $job as failed.  Allows job to be retried if your subclass supports that 
(see max_retries()).

=cut

sub failedJob {
	my $self = shift;
	my $job = shift;
	my $error = shift;
	my $exitstatus = shift;
	return $job->failed($error, $exitstatus);
}


=head2 failedJobPermanent($job [, $error][, $exitstatus])

Marks $job as permanently failed (no more retries allowed).

=cut

sub failedJobPermanent {
	my $self = shift;
	my $job = shift;
	my $error = shift;
	my $exitstatus = shift;
	return $job->failedNoRetry($error, $exitstatus);
}


=head2 deferredJob($job)

Defers processing of a job until its grabbed_until interval expires (default 
is 60 minutes).  This feature requires TheSchwartz 1.10.

=cut

sub deferredJob {
	my $self = shift;
	my $job = shift;
	return $job->deferred();
}

=head2 burstJob($metajob)

Given a metajob, burstJob bursts it into its constituent jobs for other Helios workers to process. 
Normally Helios::Service's internal methods will take care of bursting jobs, but the method can be 
overridden if a job service needs special bursting capabilities.

=cut

sub burstJob {
	my $self = shift;
	my $job = shift;
	my $jobnumber = $job->burst();	
	return $jobnumber;
}


=head1 SERVICE CLASS DEFINITION

These are the basic methods that define your Helios service.  The run() method 
is the only one required. 

=head2 run($job)

This is a default run method for class completeness.  You have to override it 
in your own Helios service class. 

=cut

sub run {
    throw Helios::Error::FatalNoRetry($_[0]->getJobType.': run() method not implemented!'); 
}

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.

=head2 MaxRetries(), RetryInterval(), and JobLockInterval()

The MaxRetries(), RetryInterval(), and JobLockInterval() methods specify to 
Helios the number of reattempts it should make at running a job and the 
frequency of those attempts.  If you don't define these, jobs will not be 
retried if they fail.

MaxRetries() is straightforward; set it to the number of times you want a job 
to be retried if it fails.

RetryInterval() is the amount of time (in seconds) to wait after a job fails 
before a job is available to try again.

JobLockInterval() is the amount of time (in seconds) a job is locked for 
processing.  This amount of time should be enough time to make sure a job can 
be completed or at marked as failed.  The default is 3600 sec (1 hour).  

RetryInterval() and JobLockInterval() can interact in an odd way:  for example,
if you want to retry a job every 60 secs, you can add:

 sub RetryInterval { 60 }

to your service class.  However, your jobs will still be locked for an hour, 
because 3600 is the JobLockInterval() default.  If you want to retry jobs 
more frequently than a hour, you need to add a JobLockInterval() method to 
your service class as well as a RetryInterval() method.  So, to retry jobs 
every 60 secs, add both of the following methods to your service class:

 sub RetryInterval { 60 }
 sub JobLockInterval { 60 }

Keep in mind this will reduce the amount of time available for your service to 
mark a job as completed or failed.  If it has not done so by the time the 
JobLockInterval() value has expired, the job will be seen by the Helios system 
as available for processing again, and another worker process will pick up and 
attempt to run the job.  So always make sure your JobLockInterval() allows 
enough time to actually complete a job.  Another rule of thumb is to set 
RetryInterval() and JobLockInterval() to the same value if RetryInterval() is 
less than 3600.

=cut

# END CODE Copyright (C) 2013 by Logical Helion, LLC.

sub MaxRetries { return undef; }
sub RetryInterval { return undef; }
# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
sub JobLockInterval { undef }
# END CODE Copyright (C) 2013 by Logical Helion, LLC.

=head2 JobClass()

Defines which job class to instantiate the job as.  The default is Helios::Job, 
which should be fine for most purposes.  If necessary, however, you can create 
a subclass of Helios::Job and set your JobClass() method to return that 
subclass's name.  The service's work() method will instantiate the job as an 
instance of the class you specified rather than the base Helios::Job.

NOTE:  Please remember that "jobs" in Helios are most often only used to convey 
arguments to services, and usually only contain enough logic to properly parse 
those arguments and mark jobs as completed.  It should be rare to need to 
extend the Helios::Job object.  OTOH, if you are attempting to extend Helios 
itself to provide new abilities and not just writing a normal Helios 
application, you can use JobClass() to use your extended job class rather than 
the default.  

=cut

sub JobClass { return undef; }


# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.

=head2 ConfigClass()

Defines which configuration class to use to parse your service's 
configuration.  The default is Helios::Config, which should work fine for most 
applications.  If necessary, you can create a subclass of Helios::Config and 
set your ConfigClass() method to return that subclass's name.  The service's 
prep() method will initialize your custom config class and use it to parse your 
service's configuration information.

See the L<Helios::Config> documentation for more information about creating 
custom config classes.

=cut

sub ConfigClass { return undef; }

# END CODE Copyright (C) 2012 by Logical Helion, LLC.


# BEGIN CODE Copyright (C) 2012 by Logical Helion, LLC.

sub _require_module {
	my $self = shift;
	my $class = shift;
	my $requested_superclass = shift;
	
	if ( $class !~ /^[A-Za-z]([A-Za-z0-9_\-]|:{2})*[A-Za-z0-9_\-]$/ ) {
		Helios::Error::ConfigError->throw("Requested module name is invalid: $class");
	}
	unless ( $class->can('init') ) {
        eval {
        	my $class_file = $class;
        	$class_file .= '.pm';
        	$class_file =~ s/::/\//g;
			require $class_file;
			1;
		} or do {
			my $E = $@;
			Helios::Error::ConfigError->throw("Requested module $class could not be loaded: $E");
		};
	}
	if ($requested_superclass && !$class->isa($requested_superclass)) {
		Helios::Error::ConfigError->throw("$class is not a subclass of $requested_superclass.");
	}
	return 1;
}

# END CODE Copyright (C) 2012 by Logical Helion, LLC.


1;
__END__


=head1 SEE ALSO

L<Helios>, L<helios.pl>, L<Helios::Job>, L<Helios::Error>, L<Helios::Config>, 
L<Helios::JobType>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-9 by CEB Toolbox, Inc., except as noted.

Portions of this software, where noted, are 
Copyright (C) 2009 by Andrew Johnson.

Portions of this software, where noted, are
Copyright (C) 2011-2012 by Andrew Johnson.

Portions of this software, where noted, are
Copyright (C) 2012-3 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

