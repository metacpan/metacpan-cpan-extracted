package Helios::TestService;

use 5.008;
use strict;
use warnings;
use base qw( Helios::Service );

use Helios::Error;			
use Helios::LogEntry::Levels qw(:all);

# 2012-01-01:  Completely rewrote this to be more clear, concise, and to use
# more up-to-date Perl.

our $VERSION = '2.40';	

=head1 NAME

Helios::TestService - Helios::Service subclass useful for testing

=head1 DESCRIPTION

You can use Helios::TestService to test the functionality of your Helios 
collective:  

=over 4

=item 1.

Start a helios.pl daemon to service Helios::TestService jobs by issuing:

 helios.pl Helios::TestService

at a command prompt.

=item 2.

Use the helios_job_submit.pl program to submit a Helios::TestService job to the
Helios collective:

 helios_job_submit.pl Helios::TestService "<job><params><arg1>value1</arg1></params></job>"

=item 3.

Helios should run the test job.  Helios::TestService will log a "Hello World" 
message, then any job arguments will be parsed and logged as entries in the 
Helios log.  If you are running the service in debug mode, the service's 
config parameters and job arguments will be printed to the terminal as well.

=back

=head1 METHODS

=head2 run()

The run() method prints a "Hello World!" message to the Helios log and then 
logs the job arguments.

=cut

sub run {
	my $self = shift;
	my $job = shift;
	my $config = $self->getConfig();
	my $args = $self->getJobArgs($job);

	eval {

		# this is just for debugging purposes, you wouldn't print 
		# to the terminal in a normal Helios service
		if ($self->debug) { 
			$self->printConfigParams();
			$self->printJobArgs(); 
		}

		# Hello World!
		$self->logMsg($job, 'Helios::TestService says, "Hello World!"');

		# just for fun (and to prove we received the job correctly)
		# log the job arguments
		foreach my $arg (sort keys %$args) {
			$self->logMsg($job,"JOBARG=$arg VALUE=".$args->{$arg});
		}

		# if your job completes successfully, you need to mark it was completed
		$self->completedJob($job);
		1; 
	} or do {
		my $E = $@;
		if ($E->isa('Helios::Error::Warning')) {
			# you can throw this in your run() method to indicate  
			# there was a problem, but it wasn't bad enough for the job to fail
			$self->logMsg($job, LOG_WARNING, "WARNING: ".$E);	
			$self->completedJob($job);
		} elsif ($E->isa('Helios::Error::Fatal')) {
			# you can throw this in your run() method to indicate a job failed
			# calling failedJob() will tell Helios to mark it as failed
			# but allow it to be retried if your service supports that
			$self->logMsg($job, LOG_ERR, "FAILED: ".$E);
			$self->failedJob($job, $E, 1);			
		} else {
			# this will catch all the other exceptions that happen
			# if you don't really care what kind of error was thrown,
			# this (and the $E declaration above) is all you really need
			# in your 'or do' block.
			$self->logMsg($job, LOG_ERR, "FAILED with unexpected error: ".$E);
			$self->failedJob($job, $E);
		}
	};

}


=head2 printConfigParams()

This method prints the service's config params to the terminal.  It's only 
called when Helios::TestService is run in debug mode.

=cut

sub printConfigParams {
	my $self = shift;
	my $c = $self->getConfig();

	print "<--CONFIG PARAMS-->\n";
	foreach (sort keys %$c) {
		print $_.' => '.$c->{$_}."\n";
	}
	return 1;
}


=head2 printJobArgs()

This method prints the job arguments passed to the service to the terminal.  
It's only called when Helios::TestService is run in debug mode.

=cut

sub printJobArgs {
	my $self = shift;
	my $j = $self->getJob();
	my $a = $self->getJobArgs($j);
	
	print "<--JOB ARGUMENTS-->\n"; 
	foreach (sort keys %$a) {
		print $_.' => '.$a->{$_}."\n";
	}
	return 1;
}


1;
__END__


=head1 SEE ALSO

L<Helios::Service>

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dotorgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Andrew Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

