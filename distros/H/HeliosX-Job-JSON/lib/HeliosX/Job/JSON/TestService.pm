package HeliosX::Job::JSON::TestService;

use 5.008;
use strict;
use warnings;
use base 'Helios::Service';

use Helios::Config;
use Helios::LogEntry::Levels qw(:all);
use HeliosX::Job::JSON;

our $VERSION = '1.00';

=head1 NAME

HeliosX::Job::JSON::TestService - service for testing HeliosX::Job::JSON jobs

=head1 SYNOPSIS

 # create a Helios job using HeliosX::Job::JSON
 use HeliosX::Job::JSON;
 my $json = qq/
     {
      "jobtype" : "HeliosX::Job::JSON::TestService", 
      "args"    : { 
                   "arg1" : "value1", 
                   "arg2" : "value2"
                  }
     }
 /;
 my $job = HeliosX::Job::JSON->new(argstring => $json);
 my $jobid = $job->submit();
 
 --OR--
 
 # create a Helios job using the heliosx_job_json_submit command
 heliosx_job_json_submit --jobtype=HeliosX::Job::JSON::TestService --args='{"args":{"arg1":"value1","arg2":"value2"}}'
 
 # then start a HeliosX::Job::JSON::TestService daemon 
 # the service will log a hello message 
 # and the individual job args to the configured log(s)
 helios.pl HeliosX::Job::JSON::TestService

=head1 DESCRIPTION

HeliosX::Job::JSON::TestService is a Helios service that can be used for 
testing HeliosX::Job::JSON jobs.

=head1 HELIOS METHODS

=head2 JobClass()

The JobClass method tells the Helios system to use HeliosX::Job::JSON instead 
of the default Helios::Job when working with HeliosX::Job::JSON::TestService. 

=cut

sub JobClass { 'HeliosX::Job::JSON' }


=head2 run()

The run() method of HeliosX::Job::JSON::TestService is a bare-bones method.  
It logs a "Hello World" message to the Helios logging system, and then logs 
all of the job arguments in the job it was given.

The remarkable thing about this run() method is that it is wholly unmarkable; 
even though the job argument format and parser has changed, the run() method 
is no different than one using the default job class and XML-format arguments.

=cut

sub run {
	my $self = shift;
	my $job = shift;
	my $config = $self->getConfig();
	my $args = $self->getJobArgs($job);
	
	eval {
		$self->logMsg($job, LOG_INFO, __PACKAGE__." says 'Hello World!'");
		foreach ( keys %{$args} ) {
			$self->logMsg($job, LOG_INFO, 'ARG: '.$_.' VALUE: '.$args->{$_});
		}
		
		$self->completedJob($job);
		1;
	} or do {
		my $E = $@;
		$self->logMsg($job, LOG_ERR, "ERROR: $E");
		$self->failedJob($job, $E);
	};
	
}



1;
__END__

=head1 AUTHOR

Andrew Johnson, E<lt>lajandy at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Logical Helion, LLC.

This library is free software; you can redistribute it and/or modify it under 
the terms of the Artistic License 2.0.  See the included LICENSE file for 
details.

=head1 WARRANTY

This software comes with no warranty of any kind.

=cut

