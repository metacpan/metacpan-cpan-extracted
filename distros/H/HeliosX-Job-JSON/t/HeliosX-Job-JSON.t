# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HeliosX-Job-JSON.t'

use 5.008;
use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('HeliosX::Job::JSON') };

my $arg_string = '{ "args": { "arg1":"value1","arg2":"value2"} }';
my $job = HeliosX::Job::JSON->new();
isa_ok($job, 'Helios::Job');
isa_ok($job, 'HeliosX::Job::JSON');

my $job_args = $job->parseArgString($arg_string);
is($job_args->{args}->{arg1}, 'value1', 'The value of arg1 is correct');
is($job_args->{args}->{arg2}, 'value2', 'The value of arg2 is correct');

my $job2 = HeliosX::Job::JSON->new(
	jobtype => 'HeliosX::Job::JSON::TestService',
	argstring => $arg_string
);
isa_ok($job2, 'Helios::Job');
isa_ok($job2, 'HeliosX::Job::JSON');

my $jt2 = $job2->getJobType();
my $job_args2 = $job2->parseArgString( $job2->getArgString());
is($jt2, 'HeliosX::Job::JSON::TestService', 'The jobtype is HeliosX::Job::JSON::TestService');
is($job_args2->{args}->{arg1}, 'value1', 'The value of arg1 is correct');
is($job_args2->{args}->{arg2}, 'value2', 'The value of arg2 is correct');

