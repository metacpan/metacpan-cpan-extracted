package Helios::App::Stub;

use 5.008;
use strict;
use warnings;
use base 'Helios::Service';
use Helios::LogEntry::Levels ':all';
use Helios::Error;			# pulls in all Helios::Error::* exception types

our $VERSION = '0.04';		# for packaging purposes


# FILE CHANGE HISTORY:
# 2012-01-08:  Updated code for clarity.
# 2012-01-09:  Refactored from Stub::StubService to just StubService.
# [2014-10-10] [LH]:  Renamed to Helios::App::Stub to prevent PAUSE indexer
# from letting an example app grab a CPAN top-level namespace.

=head1 NAME

Helios::App::Stub - Helios::Service subclass to handle [job type here] jobs

=head1 DESCRIPTION

This is a stub class to use as a guide to create new services for the Helios 
system.

=head1 RETRY METHODS

Define MaxRetries() and RetryInterval() methods to determine how many times a 
job should be retried if it fails and what the interval between the retries 
should be.  If you don't define these methods, jobs for your service will not 
be retried if they fail.

The commented lines below set a job to be retried twice at 1 hour intervals.  
RetryInterval() values are in seconds.

=cut

#sub MaxRetries { 2 }
#sub RetryInterval { 3600 }


=head2 run($job)

The run() method is the method called to actually run a job.  It is called as 
an object method, and will be passed a Helios::Job object representing the job 
arguments and other information associated with the job to be run.

Once the work for a particular job is done, you should mark the job as either 
completed or failed.  You can do this by calling the completedJob() or 
failedJob() methods.  These methods will call the appropriate Helios::Job 
methods to mark the job as completed.  

Most Helios classes and methods will throw exceptions if there are problems, 
as will the code in many other CPAN distributions.  To catch these errors 
before they blow up your worker process altogether, use the eval {} or do {};
construct to catch these errors and deal with them appropriately.  For cleaner 
exception syntax, look for the L<Try::Tiny> module on CPAN.

=cut

sub run {
	my $self = shift;
	my $job = shift;
	my $config = $self->getConfig();
	my $args = $self->getJobArgs($job);

	eval {
		#### DO YOUR WORK HERE ####

		# example debug log message
		if ($self->debug) { $self->logMsg($job, LOG_DEBUG, "Debugging message"); }

		# example normal log message (defaults to LOG_INFO) 
		$self->logMsg($job, "This is a normal log message");

		# if your job completes successfully, you need to mark it was completed
		$self->completedJob($job);
		1;
	} or do {
		my $E = $@;
		# you can check the type of exception that was thrown
		# or if you don't care what type of error was thrown, 
		# you can just use failedJob() to mark it as failed.
		if ( $E->isa('Helios::Error::Warning') ) {
			# this is just a warning, so we log it and mark the job completed
			$self->logMsg($job, LOG_WARNING, "Warning: ".$E);
			$self->completedJob($job);			
		} else {
			# this will handle any error regardless of type
			$self->logMsg($job, LOG_ERR, "JOB FAILURE: ".$E);
			$self->failedJob($job, $E);
		}
	};

}


1;
__END__

