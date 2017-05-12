package Helios::Job;

use 5.008000;
use strict;
use warnings;

use DBI;
use Error qw(:try);
# [LH] [2013-10-18] Replaced Helios::TheSchwartz with Helios::TS
use Helios::TS;
use Helios::TS::Job;
use Helios::ObjectDriver::DBI;

require XML::Simple;

use Helios::Error;
use Helios::JobHistory;

our $VERSION = '2.83';

our $D_OD_RETRIES = 3;
our $D_OD_RETRY_INTERVAL = 5;

# 2011-12-15:  Removed setting $XML::Simple::PREFERRED_PARSER.
# 2012-01-01:  Changed failed() and failedNoRetry() methods to truncate error 
# string at 256 chars.  That's the max length of the matching field in the 
# ERROR table.  Updated copyright info.
# 2012-03-27:  Documented accessor methods and greatly expanded and updated 
# JOB SUBMISSION documentation.
# 2012-04-01:  Added setDriver() and initDriver() methods.  Refactored old 
# getDriver() into initDriver(), and changed getDriver() to call initDriver().
# 2012-04-25:  Added deferred() method.
# [LH] 2012-07-11: submit(): changed to use Helios::TheSchwartz instead of 
# base TheSchwartz to implement database connection caching.
# [LH] [2013-09-07] new(): changed to check to see if TheSchwartz::Job object 
# to new() has an array in arg(), and throw an exception if it doesn't.
# (It always should, but [RT79690] is preventing that in a tiny number of cases.) 
# [LH] [2013-10-18] Replaced calls to Helios::TheSchwartz and TheSchwartz::Job
# with Helios::TS and Helios::TS::Job.
# [LH] [2013-10-28] Added set/getArgString(), set/getJobType(), 
# set/getJobtypeid() methods; set/getArgXML(), set/getFuncname(), 
# set/getFuncid() will be deprecated in Helios 3.x.  Changed POD to document 
# the new functions.  
# [LH] [2014-08-10] Added get/setPriority() methods.
# [LH] [2015-08-14]: Changed all CRLF endings to Unix-style LF endings.

=head1 NAME

Helios::Job - base class for jobs in the Helios job processing system

=head1 DESCRIPTION

Helios::Job is the standard representation of jobs in the Helios framework.  It handles tasks 
related to the underlying TheSchwartz::Job objects, and provides its own methods for manipulating 
jobs in the Helios system.

=head1 ACCESSOR METHODS

These accessors allow access to information about an instantiated Helios::Job 
object:

 debug()             whether Debug Mode is enabled or not
 get/setConfig()     Helios configuration passed by the system to the job object
 get/setArgs()       hashref of the job's arguments (interpreted from the arg string)
 get/setArgString()  the raw XML of the job arguments

Several accessors are pass-through accessors to access values in the 
underlying TheSchwartz::Job object
 
 get/setJobid()         jobid of the job in the job queue
 get/setFailures()      number of previous failures of the job before current run
 get/setJobtypeid()     jobtypeid value of the job 
 get/setJobType()       jobtype name of the job
 get/setUniqkey()       uniqkey value of the job (see TheSchwartz documentation)
 get/setRunAfter()      current run_after value of the job
 get/setGrabbedUntil()  current grabbed_until value of the job
 get/setCoalesce()      coalesce value of the job (see TheSchwartz documentation)

When running a job, your service class need not access any of these values 
directly, though the information is available if you need it (for example, 
to log how many failures your job has encountered before the current run).  
When submitting a job, several of the set* accessors are needed to set up the
job before submission; see the section on the submit() method for more 
information.

=cut

sub setConfig { $_[0]->{config} = $_[1]; }
sub getConfig { return $_[0]->{config}; }

sub setArgs { $_[0]->{args} = $_[1]; }
sub getArgs { return $_[0]->{args}; }

sub setJobid { $_[0]->{args} = $_[1]; }
sub getJobid { return $_[0]->job()->jobid; }

sub setFuncid { return $_[0]->job()->funcid($_[1]); }
sub getFuncid { return $_[0]->job()->funcid; }

sub setFailures { return $_[0]->job()->failures($_[1]); }
sub getFailures { return $_[0]->job()->failures; }

sub setFuncname { return $_[0]->job()->funcname($_[1]); }
sub getFuncname { return $_[0]->job()->funcname; }

sub setUniqkey { return $_[0]->job()->uniqkey($_[1]); }
sub getUniqkey { return $_[0]->job()->uniqkey; }

sub setRunAfter { return $_[0]->job()->run_after($_[1]); }
sub getRunAfter { return $_[0]->job()->run_after; }

sub setGrabbedUntil { return $_[0]->job()->grabbed_until($_[1]); }
sub getGrabbedUntil { return $_[0]->job()->grabbed_until; }

sub setCoalesce { return $_[0]->job()->coalesce($_[1]); }
sub getCoalesce { return $_[0]->job()->coalesce; }

# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.
sub setDriver { $_[0]->{driver} = $_[1]; }
sub getDriver { 
	if ( defined($_[0]->{driver}) ) {
		return $_[0]->{driver};
	} else {
		return $_[0]->initDriver();
	}
}
# END CODE Copyright (C) 2012 by Andrew Johnson.

sub debug { my $self = shift; @_ ? $self->{debug} = shift : $self->{debug}; }

# these are for direct access to the underlying TheSchwartz::Job object
sub job { my $self = shift; @_ ? $self->{job} = shift : $self->{job}; }

sub setArgXML { $_[0]->{argxml} = $_[1]; }
sub getArgXML { return $_[0]->{argxml}; }

# BEGIN CODE Copyright (C) 2013 by Logical Helion, LLC.
sub setArgString { setArgXML(@_) }
sub getArgString { getArgXML(@_) }

sub setJobType { setFuncname(@_) }
sub getJobType { getFuncname(@_) }

sub setJobtypeid { setFuncid(@_) }
sub getJobtypeid { getFuncid(@_) }
# END CODE Copyright (C) 2013 by Logical Helion, LLC.

# BEGIN CODE Copyright (C) 2014 by Logical Helion, LLC.
sub setPriority {
	my $self = shift;
	my $p = shift;
	$self->job()->priority($p);
}
sub getPriority {
	my $self = shift;
	$self->job()->priority();
}
# END CODE Copyright (C) 2014 by Logical Helion, LLC.

=head1 METHODS

=head2 new($job)

=cut

sub new {
	my $caller = shift;
	my $class = ref($caller) || $caller;
#	my $self = $class->SUPER::new(@_);
	my $self = {};
	bless $self, $class;

	# init fields
	# [LH] [2013-10-18] Replaced Helios::TheSchwartz with Helios::TS
	if ( defined($_[0]) && ref($_[0]) && $_[0]->isa('Helios::TS::Job') ) {
		$self->job($_[0]);
# BEGIN CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
# [LH] [2013-09-07] new(): changed to check to see if TheSchwartz::Job object 
# to new() has an array in arg(), and throw an exception if it doesn't.
# (It always should, but [RT79690] is preventing that in a tiny number of cases.) 
		if ( ref($_[0]->arg()) eq 'ARRAY' ) {
			my $arg_str = $_[0]->arg()->[0];
			$self->setArgXML($arg_str);		
		} else {
			Helios::Error::DatabaseError->throw("Received job without actual job arguments, probably due to transient database problem [RT79690].");				
		}
# END CODE COPYRIGHT (C) 2013 LOGICAL HELION, LLC.
	} else {
		# [LH] [2013-10-18] Replaced Helios::TheSchwartz with Helios::TS
		my $schwartz_job = Helios::TS::Job->new(@_);
		$self->job($schwartz_job);
	}

	return $self;
}


=head1 ARGUMENT PROCESSING METHODS

=head2 parseArgXML($xml) 

Given a string of XML, parse it into a mixed hash/arrayref structure.  This uses XML::Simple.

=cut

sub parseArgXML {
	my $self = shift;
	my $xml = shift;
	my $xs = XML::Simple->new(SuppressEmpty => undef, KeepRoot => 1, ForceArray => ['job']);
	my $args;
	try {
		$args = $xs->XMLin($xml);
	} otherwise {
		throw Helios::Error::InvalidArg($!);
	};
	return $args;
}



=head2 parseArgs()

Call parseArgs() to pick the Helios job arguments (the first element of the job->args() array) 
from the Schwartz job object, parse the XML into a Perl data structure (via XML::Simple) and 
return the structure to the calling routine.  

This is really a convenience method created because 

 $args = $self->parseArgXML( $job->arg()->[0] );

looks nastier than it really needs to be.

=cut

sub parseArgs {
	my $self = shift;
	my $job = $self->job();
	my $args;
	my $parsedxml = $self->parseArgXML($job->arg()->[0]);
	# is this a metajob?
	if ( defined($parsedxml->{metajob}) ) {
		# this is a metajob, with full xml syntax (required for metajobs)
		$args = $parsedxml->{metajob};
		$args->{metajob} = 1;
	} elsif ( defined($parsedxml->{job}) ) {
		# this isn't a metajob, but is a job with full <job> xml syntax
		# unfortunately, forcing <job> into an array for metajobs adds complexity here
		$args = $parsedxml->{job}->[0]->{params};
	} else {
		# we'll assume this is the old-style <params> w/o the enclosing <job> section
		# we'll probably still support this for awhile
		$args = $parsedxml->{params};
	}
	
	$self->setArgs( $args );
	return $args;
}


=head2 isaMetaJob()

Returns a true value if the job is a metajob and a false value otherwise.

=cut

sub isaMetaJob {
	my $self = shift;
	my $args = $self->getArgs() ? $self->getArgs() : $self->parseArgs();
	if ( defined($args->{metajob}) && $args->{metajob} == 1) { return 1; }
	return 0;
}


=head1 JOB SUCCESS/FAILURE METHODS

Use these methods to mark jobs as either successful or failed.  

Helios follows the *nix concept of exitstatus:  0 is successful, nonzero is failure.  If you don't 
specify an exitstatus when you call failed() or failedNoRetry(), 1 will be recorded as the 
exitstatus.

The completed(), failed(), and failedNoRetry() methods actually return the exitstatus of the job, 
so completed() always returns 0 and the failed methods return the exitstatus you specified (or 1 
if you didn't specify one).  This is to facilitate ending of service class run() methods; the 
caller of a run() method will cause the worker process to exit if a nonzero value is returned.  If 
you make sure your completed() or failed()/failedNoRetry() call is the last thing you do in your 
run() method, everything should work fine.

=head2 completed()

Marks the job as completed successfully.  

Successful jobs are marked with exitstatus of zero in Helios job history.

=cut

sub completed {
	my $self = shift;
	my $job = $self->job();

	my $retries = 0;
	RETRY: {
        try {
            my $driver = $self->getDriver();
            my $jobhistory = Helios::JobHistory->new(
                jobid         => $job->jobid,
                funcid        => $job->funcid,
                arg           => $job->arg()->[0],
                uniqkey       => $job->uniqkey,
                insert_time   => $job->insert_time,
                run_after     => $job->run_after,
                grabbed_until => $job->grabbed_until,
                priority      => $job->priority,
                coalesce      => $job->coalesce,
                complete_time => time(),
                exitstatus    => 0
            );
            $driver->insert($jobhistory);
        } otherwise {
            my $e = shift;
            if ($retries > $D_OD_RETRIES) {
                throw Helios::Error::DatabaseError($e->text);		
            } else {
                $retries++;
                sleep $D_OD_RETRY_INTERVAL;
                next RETRY;
            }
        };
	}
	$job->completed();
	return 0;
}


=head2 failed([$error][, $exitstatus])

Marks the job as failed.  Allows job to be retried if the job's service class supports it.  
Returns the exitstatus recorded for the job (if it wasn't given, it defaults to 1).

=cut

sub failed {
	my $self = shift;
	my $error = shift;
	my $exitstatus = shift;
	my $job = $self->job();
	
	# this job failed; that means a nonzero exitstatus
	# if exitstatus wasn't specified (or is zero?), set it to 1
	if ( !defined($exitstatus) || $exitstatus == 0 ) {
		$exitstatus = 1;
	}
	
	my $retries = 0;
	my $retry_limit = 3;
	RETRY: {
        try {
            my $driver = $self->getDriver();
            my $jobhistory = Helios::JobHistory->new(
                jobid         => $job->jobid,
                funcid        => $job->funcid,
                arg           => $job->arg()->[0],
                uniqkey       => $job->uniqkey,
                insert_time   => $job->insert_time,
                run_after     => $job->run_after,
                grabbed_until => $job->grabbed_until,
                priority      => $job->priority,
                coalesce      => $job->coalesce,
                complete_time => time(),
                exitstatus    => $exitstatus
            );
            $driver->insert($jobhistory);
        } otherwise {
            my $e = shift;
            if ($retries > $retry_limit) {
                $job->failed($error, $exitstatus);
                throw Helios::Error::DatabaseError($e->text);		
            } else {
                $retries++;
                sleep 10;
                next RETRY;
            }
        };
	}	
	$job->failed(substr($error,0,254), $exitstatus);
	return $exitstatus;
}


=head2 failedNoRetry([$error][, $exitstatus])

Marks the job as permanently failed (no more retries allowed).

If not specified, exitstatus defaults to 1.  

=cut

sub failedNoRetry {
	my $self = shift;
	my $error = shift;
	my $exitstatus = shift;
	my $job = $self->job();

	# this job failed; that means a nonzero exitstatus
	# if exitstatus wasn't specified (or is zero?), set it to 1
	if ( !defined($exitstatus) || $exitstatus == 0 ) {
		$exitstatus = 1;
	}

	my $retries = 0;
	my $retry_limit = 3;
	RETRY: {
        try {
            my $driver = $self->getDriver();
            my $jobhistory = Helios::JobHistory->new(
                jobid         => $job->jobid,
                funcid        => $job->funcid,
                arg           => $job->arg()->[0],
                uniqkey       => $job->uniqkey,
                insert_time   => $job->insert_time,
                run_after     => $job->run_after,
                grabbed_until => $job->grabbed_until,
                priority      => $job->priority,
                coalesce      => $job->coalesce,
                complete_time => time(),
                exitstatus    => $exitstatus
            );
            $driver->insert($jobhistory);
        } otherwise {
            my $e = shift;
            if ($retries > $retry_limit) {
                $job->permanent_failure($error, $exitstatus);
                throw Helios::Error::DatabaseError($e->text);		
            } else {
                $retries++;
                sleep 10;
                next RETRY;
            }
        };
	}

	$job->permanent_failure(substr($error,0,254), $exitstatus);
	return $exitstatus;
}

=head2 deferred()

Defers processing of a job even though it was available for processing in the 
queue.  The job will be seen as available for processing again when the 
grabbed_until time has expired (the default is 60 minutes).  If your service 
employs the job retry API, a declined job run does not count against the job's 
retry count.

Unlike the completed() and failed*() methods above, deferred() is actually 
only a wrapper around TheSchwartz 1.10's TheSchwartz::Job->declined() method 
for now.  No job history is recorded in the HELIOS_JOB_HISTORY_TB in the 
collective database.  This may change in the future.

=cut

sub deferred {
	my $self = shift;
	my $job = $self->job();

	$job->declined();
	return 0;
}


=head1 JOB SUBMISSION

=head2 submit()

Submits a job to the Helios collective for processing.  Returns the jobid if successful, throws an 
error if it fails.

Before a job can be successfully submitted, the following must be set first:

 $job->setConfig($configHash);
 $job->setArgString($xmlstring);
 $job->setJobType($servicename);

So, for example, to submit a Helios::TestService to the Helios system, you need 
to do the following:

 # you need Helios::Service and Helios::Job
 use Helios::Service;
 use Helios::Job;

 # these are the job arguments we want to pass to Helios::TestService
 my $jobxml = "<job><params><string1>This is a test</string1/params>/job>";

 # first, use Helios::Service to get the Helios configuration
 my $srv = Helios::Service->new();
 $srv->prep();
 my $config = $srv->getConfig();
 
 # once you have the config, you can set up the Helios::Job
 my $job = Helios::Job->new();
 $job->setConfig($config);
 $job->setJobType('Helios::TestService');
 $job->setArgString($jobxml);
 
 # then submit the job (this will throw an exception if something goes wrong)
 my $jobid = $job->submit();
 print "Submitted job $jobid to Helios\n";
 
Both Helios::Service->prep() and Helios::Job->submit() will throw exceptions 
if they encounter errors, so a safer example would catch them:

 use Helios::Service;
 use Helios::Job;

 my $jobxml = "<job><params><string1>This is a test</string1/params>/job>";

 my $srv = Helios::Service->new();
 eval {
 	$srv->prep();
 	1;
 } or do {
 	my $E = $@;
 	print "Error encountered prepping Helios service: $E\n";
 	exit(1);
 };
 my $config = $srv->getConfig();
 
 # once you have the config, you can set up the Helios::Job
 my $job = Helios::Job->new();
 $job->setConfig($config);
 $job->setJobType('Helios::TestService');
 $job->setArgString($jobxml);
 
 # then submit the job (this will throw an exception if something goes wrong)
 my $jobid;
 eval {
	$jobid = $job->submit();
 	1;
 } or do {
	my $E = $@;
	print "Error encountered attempting job submission: $E\n"; 	
 };
 print "Submitted job $jobid to Helios\n";

Of course, the Try::Tiny (available on CPAN) would work just as well as an
eval{} block, and have much prettier syntax.

=cut

sub submit {
	my $self = shift;
	my $config = $self->getConfig();
	my $params = $self->getArgXML();
	my $job_class = $self->getFuncname;
	
	my $databases = [
		{   dsn => $config->{dsn},
			user => $config->{user},
			pass => $config->{password}
		}
	];

	my $args = [ $params ];

	# [LH] [2013-10-18] Replaced Helios::TheSchwartz with Helios::TS
	my Helios::TS $client = Helios::TS->new( databases => $databases, verbose => 1 );
	my $sjh = $client->insert($job_class, $args);
	$self->setJobid($sjh->jobid);
	return $sjh->jobid;
}


=head1 JOB BURSTING

Metajobs are jobs that specify multiple jobs.  These metajobs will be burst apart by Helios into 
the constituent jobs, which will be available for processing by any of the workers of the 
appropriate class in the Helios collective.  Metajobs provide a faster means to submit jobs in 
bulk to Helios; rather than submit a thousand jobs, your application can submit 1 metajob that 
will be burst apart by Helios into the thousand constituent jobs, which other workers will process 
as if they were submitted individually.

Normally, the Helios::Service base class determines whether a job is a metajob or not and can 
handle the bursting process without intervention from your service subclass.  If you need metajobs 
to be burst in a way different than from the default, you may need to override 
Helios::Service->burstJob() in your service class (and possibly create a Helios::Job subclass with 
an overridden burst() method as well).

=head2 burst()

Bursts a metajob into smaller jobs.  Returns the number of jobs burst if successful.

=cut

sub burst {
	my $self = shift;
	my $job = $self->job();
	my $args = $self->getArgs();
	my $xs = XML::Simple->new(SuppressEmpty => undef, ForceArray => [ 'job' ]);
	my @newjobs;
	my $classname;
	
	# determine the class of the burst jobs
	# if it wasn't specified, it's the same class as this job
	if ( defined($args->{class}) ) {
		$classname = $args->{class};
	} else {
		$classname = $job->funcname;
	}

	try {

		foreach my $job_arg (@{$args->{jobs}->{job}}) {
			my $newxml = $xs->XMLout($job_arg, NoAttr => 1, NoIndent => 1, RootName => undef);
			my $newjob = TheSchwartz::Job->new(
				funcname => $classname,
				arg      => [ $newxml ]
			);
			push(@newjobs, $newjob);
		}	

		$job->replace_with(@newjobs);

	} otherwise {
		my $e = shift;
		$self->failed($e->text);
		throw Helios::Error::Fatal($e->text);
	};
	$self->completed;
	
	# return the number of jobs burst from the meta job here
	if ($self->debug) {
		foreach (@newjobs) {
			print "JOBID: ",$_->jobid,"\n";
		}
	}
	return scalar(@newjobs);
}


=head1 OTHER METHODS

=head2 initDriver()

Returns a Data::ObjectDriver object for use with Helios layer database updates.

=cut

# BEGIN CODE Copyright (C) 2012 by Andrew Johnson.

sub initDriver {
	my $self = shift;
	my $config = $self->getConfig();
	if ($self->debug) { print $config->{dsn},$config->{user},$config->{password},"\n"; }
	my $driver = Helios::ObjectDriver::DBI->new(
	    dsn      => $config->{dsn},
	    username => $config->{user},
	    password => $config->{password}
	);	
	if ($self->debug) { print 'Job->initDriver() DRIVER: ',$driver,"\n"; }
	$self->setDriver($driver);
	return $driver;	
}
# END CODE Copyright (C) 2012 by Andrew Johnson.


1;
__END__


=head1 SEE ALSO

L<Helios::Service>, L<Helios::TS>, L<Helios::TS::Job>, L<XML::Simple>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by CEB Toolbox, Inc.

Portions of this software, where noted, are
Copyright (C) 2012 by Andrew Johnson.

Portions of this software, where noted, are
Copyright (C) 2013-4 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

