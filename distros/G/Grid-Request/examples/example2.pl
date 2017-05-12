#!/usr/bin/perl

use strict;
use Grid::Request;
use Log::Log4perl ':easy';

my $logger = get_logger;

my $home = $ENV{HOME};

# Create a request object. The "project" is required.
my $request = Grid::Request->new ( project => "someproject" );

# Set up the executable and job attributes.
$request->set_command("/usr/bin/mysearch.pl");
$request->set_output("$home/clust.out");
$request->set_error("$home/clust.err");

# Add the command line parameters for the executable.
$request->add_param("-v");
$request->add_param('--inputfile=$(Name)', "$home/searchfiles", "FILE");
$request->add_param('--input2=$(Name)', "$home/otherfiles/", "DIR");

# Submit the job.
my @ids = $request->submit();

# Wait for the job to complete.
$request->wait_for_request();

# Job is now completed. Check the results.
my $state = $request->get_state();
my $message = $request->get_message();

print "Job finished with state: $state\n";
print "Message: $message\n";

exit;
