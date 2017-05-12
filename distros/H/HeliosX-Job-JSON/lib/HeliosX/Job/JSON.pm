package HeliosX::Job::JSON;

use 5.008;
use strict;
use warnings;
use base 'Helios::Job';

use JSON::Tiny qw(decode_json);
$JSON::Tiny::TRUE  = 1;
$JSON::Tiny::FALSE = 0;

use Helios::Config;
use HeliosX::Job::JSON::Error;

our $VERSION = '1.00';

=head1 NAME

HeliosX::Job::JSON - Helios::Job subclass using JSON to specify job arguments

=head1 SYNOPSIS

 # In your Helios::Service class:
 package MyService;
 use parent 'Helios::Service';
 use HeliosX::Job::JSON;
 
 sub JobClass { 'HeliosX::Job::JSON' }
 
 sub run {
 	... run code here ... 
 }
 
 1;
 
 # In your job submission code, use 
 # HeliosX::Job::JSON just like Helios::Job.
 my $config = Helios::Config->parseConfig();
 my $arg_json = qq/{ "args" : { "arg1": "value1", "arg2": "string2" } }/; 
 my $job = HeliosX::Job::JSON->new();
 $job->setConfig($config);
 $job->setJobType('MyService');
 $job->setArgString($arg_json);
 my $jobid = $job->submit();

 # You may also specify the config, jobtype, 
 # and argument string to the constructor.
 my $arg_json = qq/{ "args" : { "arg1": "value1", "arg2": "string2" } }/; 
 my $job = HeliosX::Job::JSON->new(
 	config    => $config,
 	jobtype   => 'MyService',
 	argstring => $arg_json
 );
 my $jobid = $job->submit();
 
 # Also, if you omit config, HeliosX::Job::JSON will 
 # use Helios::Config to get the config hash.
 # If you specify the jobtype in the JSON object string,
 # you do not have to specify a specific jobtype
 my $arg_json = qq/{ "jobtype" : "MyService", "args" : { "arg1": "value1", "arg2": "string2" } }/; 
 my $job = HeliosX::Job::JSON->new(
 	argstring => $arg_json
 );
 my $jobid = $job->submit();

 # Or use the included heliosx_job_json_submit command. 
 heliosx_job_json_submit --jobtype=MyService --args='{ "args" : { "arg1": "value1", "arg2": "string2" } }'


=head1 DESCRIPTION

HeliosX::Job::JSON is a Helios::Job subclass allowing you to specify Helios 
job arguments in JSON format instead of Helios's default XML format.  If parts 
of your application or system use the JSON data format, or your Helios job 
arguments are difficult to express in XML, you can change your Helios service 
to use HeliosX::Job::JSON to specify your job arguments in JSON.  

=head1 JSON JOB ARGUMENT FORMAT

Helios job argument JSON should describe a JSON object in the format:

 {
     "jobtype" : "<Helios jobtype name>",
     "args" : {
         "<arg1 name>" : "<arg1 value>",
         "<arg2 name>" : "<arg2 value>",
         ...etc...
     }
 }

Your JSON object string will define a "jobtype" string and an "args" object.  
The name and value pairs of the args object will become the job's argument 
hash.  For example:

 {
     "jobtype" : "MyService",
     "args": {
              "arg1"          : "value1",
              "arg2"          : "value2",
              "original_file" : "photo.jpg",
              "size"          : "125x125"
             }
 }

The jobtype value is optional if you specify a jobtype another way i.e. using 
the --jobtype option with heliosx_job_json_submit or using HeliosX::Job::JSON's 
setJobType() method.

=head1 NOTE ABOUT METAJOBS

HeliosX::Job::JSON does not yet support Helios metajobs.  Specifying metajob 
arguments in JSON may be supported in a future release.

=head1 METHODS

=head2 new()

The HeliosX::Job::JSON new() constructor overrides Helios::Job's constructor 
to allow you to specify the Helios config hash, jobtype, and argument string 
without making separate subsequent method calls to setConfig(), setJobType(),
or setArgString().  

=cut

sub new {
	my $cl = shift;
	my $self;
	if ( @_ && ref($_[0]) && ref($_[0]) eq 'Helios::TS::Job' ) {
		$self = $cl->SUPER::new(@_);
	} else {
		$self = $cl->SUPER::new();
	}
	bless($self, $cl);
	if (@_ > 1) {
		my %params = @_;
		if ( $params{config}    ) { $self->setConfig($params{config});       }
		if ( $params{jobtype}   ) { $self->setJobType($params{jobtype});     }
		if ( $params{argstring} ) { $self->setArgString($params{argstring}); }			
	}
	return $self;
}

=head2 parseArgs()

HeliosX::Job::JSON's parseArgs() method is much simpler than Helios::Job's 
parseArgs() method because JSON's object format is very close to Perl's concept
of a hash.      

=cut

sub parseArgs {
	my $self = shift;
	my $arg_string = $self->job()->arg()->[0];

	my $args_hash = $self->parseArgString($arg_string);

	unless ( defined($args_hash->{args}) ) {
		HeliosX::Job::JSON::Error->throw("HeliosX::Job::JSON->parseArgs(): args object is missing!");
	}

	my $args = $args_hash->{args};
	
	$self->setArgs( $args );
	return $args;
}


=head2 parseArgString($json_string)

The parseArgString() method does the actual parsing of the JSON object string 
into the Perl hash using JSON::Tiny.  If parsing fails, the method will throw 
a HeliosX::Job::JSON::Error exception.

=cut

sub parseArgString {
	my $self = shift;
	my $arg_string = shift;
	
	my $arg_hash;
	eval {
		$arg_hash = decode_json($arg_string);
		1;		
	} or do {
		my $E = $@;
		HeliosX::Job::JSON::Error->throw("HeliosX::Job::JSON->parseArgString(): $E");
	};
	return $arg_hash;		
}


=head2 submit() 

HeliosX::Job::JSON's submit() method overrides Helios::Job's submit() to allow 
specifying the jobtype via the JSON object instead of requiring a separate call
to setJobType().  If the jobtype wasn't explicitly specified and submit() 
cannot determine the jobtype from the JSON object, it will throw a 
HeliosX::Job::JSON::Error exception.

Also, if the config hash was not explicitly specified with either a config 
parameter to new() or the setConfig() method,  submit() will use 
Helios::Config->parseConfig() to get the collective database's dsn, user, and 
password values in the [global] section of the Helios configuration.

If job submission is successful, this method will return the new job's jobid 
to the calling routine.  

=cut

sub submit {
	my $self = shift;
	
	# if setJobType() wasn't used to specify the jobtype
	# try to get it from the JSON object
	# ugh: we're exposing some of Helios::Job's guts here :(
	unless ( $self->job()->{__funcname} ) {
		my $args = $self->parseArgString( $self->getArgString() );
		if ( defined($args->{jobtype}) ){
			$self->setJobType( $args->{jobtype} );
		} else {
			# uhoh, if the JSON object didn't have the jobtype,
			# and the user didn't use setJobType(),
			# we can't submit!!
			HeliosX::Job::JSON::Error->throw("HeliosX::Job::JSON::Error->throw(): No jobtype specified!");
		}
	}

	# if setConfig() wasn't used to pass the config,
	# attempt to use Helios::Config to parse the global config
	unless ( $self->getConfig() ) {
		my $conf = Helios::Config->parseConfig();
		$self->setConfig($conf);
	}
	
	return $self->SUPER::submit();
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

