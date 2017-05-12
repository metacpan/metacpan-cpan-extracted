# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

package Gearman::XS::Client;

use strict;
use warnings;

our $VERSION= '0.15';

use Gearman::XS;

1;
__END__

=head1 NAME

Gearman::XS::Client - Perl client for gearman using libgearman

=head1 SYNOPSIS

  use Gearman::XS qw(:constants);
  use Gearman::XS::Client;

  $client = new Gearman::XS::Client;

  $ret = $client->add_server($host, $port);
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $client->error());
    exit(1);
  }

  # single client interface
  ($ret, $result) = $client->do("reverse", 'teststring');
  if ($ret == GEARMAN_SUCCESS)
  {
    printf("Result=%s\n", $result);
  }

  # background client interface
  ($ret, $job_handle) = $client->do_background('reverse', 'teststring);
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $client->error());
    exit(1);
  }

  # concurrent client interface
  ($ret, $task) = $client->add_task('reverse', 'test1');
  ($ret, $task) = $client->add_task('reverse', 'test2');

  $ret = $client->run_tasks();

=head1 DESCRIPTION

Gearman::XS::Client is a client class for the Gearman distributed job system
using libgearman.

=head1 CONSTRUCTOR

=head2 Gearman::XS::Client->new()

Returns a Gearman::XS::Client object.

=head1 METHODS

=head2 $client->add_server($host, $port)

Add a job server to a client. This goes into a list of servers than can be
used to run tasks. No socket I/O happens here, it is just added to a list.
Returns a standard gearman return value.

=head2 $client->add_servers($servers)

Add a list of job servers to a client. The format for the server list is:
SERVER[:PORT][,SERVER[:PORT]]... No socket I/O happens here, it is just added
to a list. Returns a standard gearman return value.

=head2 $client->remove_servers()

Remove all servers currently associated with the client.

=head2 $client->options()

Get options for a client.

=head2 $client->set_options($options)

Set options for a client.

=head2 $client->add_options($options)

Add options for a client.

=head2 $client->remove_options($options)

Remove options for a client.

=head2 $client->timeout()

Get current socket I/O activity timeout value. Returns Timeout in milliseconds
to wait for I/O activity.

=head2 $client->set_timeout($timeout)

Set socket I/O activity timeout for connections in milliseconds.

=head2 $client->echo($data)

Send data to all job servers to see if they echo it back. This is a test
function to see if job servers are responding properly.
Returns a standard gearman return value.

=head2 $client->do($function_name, $workload)

Run a single task and return a list with two entries: the first is a standard
gearman return value, the second is the result.

=head2 $client->do_high($function_name, $workload)

Run a high priority task and return a list with two entries: the first is a
standard gearman return value, the second is the result.

=head2 $client->do_low($function_name, $workload)

Run a low priority task and return a list with two entries: the first is a
standard gearman return value, the second is the result.

=head2 $client->do_background($function_name, $workload)

Run a task in the background and return a list with two entries: the first is a
standard gearman return value, the second is the job handle.

=head2 $client->do_high_background($function_name, $workload)

Run a high priority task in the background and return a list with two entries:
the first is a standard gearman return value, the second is the job handle.

=head2 $client->do_low_background($function_name, $workload)

Run a low priority task in the background and return a list with two entries:
the first is a standard gearman return value, the second is the job handle.

=head2 $client->add_task($function_name, $workload)

Add a task to be run in parallel and return a list with two entries:
the first is a standard gearman return value, the second is a Gearman::XS::Task
object.

=head2 $client->add_task_high($function_name, $workload)

Add a high priority task to be run in parallel and return a list with two
entries: the first is a standard gearman return value, the second is a
Gearman::XS::Task object.

=head2 $client->add_task_low($function_name, $workload)

Add a low priority task to be run in parallel and return a list with two
entries: the first is a standard gearman return value, the second is a
Gearman::XS::Task object.

=head2 $client->add_task_background($function_name, $workload)

Add a background task to be run in parallel and return a list with two entries:
the first is a standard gearman return value, the second is a Gearman::XS::Task
object.

=head2 $client->add_task_high_background($function_name, $workload)

Add a high priority background task to be run in parallel and return a list
with two entries: the first is a standard gearman return value, the second is a
Gearman::XS::Task object.

=head2 $client->add_task_low_background($function_name, $workload)

Add a low priority background task to be run in parallel and return a list
with two entries: the first is a standard gearman return value, the second is a
Gearman::XS::Task object.

=head2 $client->add_task_status($job_handle)

Add task to get the status for a background task in parallel and return a list
with two entries: the first is a standard gearman return value, the second is a
Gearman::XS::Task object.

=head2 $client->run_tasks()

Run tasks that have been added in parallel. Returns a standard gearman return
value.

=head2 $client->set_created_fn($subref)

Set callback function when a job has been created for a task. No return value.

=head2 $client->set_data_fn($subref)

Set callback function when there is a data packet for a task. No return value.

=head2 $client->set_complete_fn($subref)

Set callback function when a task is complete. No return value.

=head2 $client->set_fail_fn($subref)

Set callback function when a task has failed. No return value.

=head2 $client->set_status_fn($subref)

Set callback function when there is a status packet for a task. No return value.

=head2 $client->set_warning_fn($subref)

Set callback function when there is a warning packet for a task.
No return value.

=head2 $client->error()

Return an error string for the last error encountered.

=head2 $client->do_status()

Get the status for the running task. Returns a list with the percent complete
numerator and denominator.

=head2 $client->job_status($job_handle)

Get the status for a background job. Returns a list with 5 entries: standard
gearman return value, boolean indicating the know status, boolean indicating
the running status, and the precent complete numerator and denominator.

=head2 $client->wait()

When in non-blocking I/O mode, wait for activity from one of the servers.

=head2 $client->clear_fn()

Clear all task callback functions.

=head1 CALLBACKS

Please make sure that callback functions always explicitly return a valid
gearman_return_t value. An implicitly returned value, for example from a print
statement can cause the client connection to abort.

=head1 BUGS

Any in libgearman plus many others of my own.

=head1 COPYRIGHT

Copyright (C) 2013 Data Differential, ala Brian Aker, http://datadifferential.com/
Copyright (C) 2009-2010 Dennis Schoen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Brian Aker <brian@tangent.org>

=cut
