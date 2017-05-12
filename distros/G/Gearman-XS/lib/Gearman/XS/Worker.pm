# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

package Gearman::XS::Worker;

use strict;
use warnings;

our $VERSION= '0.15';

use Gearman::XS;

1;
__END__

=head1 NAME

Gearman::XS::Worker - Perl worker for gearman using libgearman

=head1 SYNOPSIS

  use Gearman::XS qw(:constants);
  use Gearman::XS::Worker;

  $worker = new Gearman::XS::Worker;

  $ret = $worker->add_server($host, $port);
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $worker->error());
    exit(1);
  }

  $ret = $worker->add_function("reverse", 0, \&reverse, $options);
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $worker->error());
  }

  while (1)
  {
    my $ret = $worker->work();
    if ($ret != GEARMAN_SUCCESS)
    {
      printf(STDERR "%s\n", $worker->error());
    }
  }

  sub reverse {
    $job = shift;

    $workload = $job->workload();
    $result   = reverse($workload);

    printf("Job=%s Function_Name=%s Workload=%s Result=%s\n",
            $job->handle(), $job->function_name(), $job->workload(), $result);

    return $result;
  }

=head1 DESCRIPTION

Gearman::XS::Worker is a worker class for the Gearman distributed job system
using libgearman.

=head1 CONSTRUCTOR

=head2 Gearman::XS::Worker->new()

Returns a Gearman::XS::Worker object.

=head1 METHODS

=head2 $worker->add_server($host, $port)

Add a job server to a worker. This goes into a list of servers than can be
used to run tasks. No socket I/O happens here, it is just added to a list.
Returns a standard gearman return value.

=head2 $worker->add_servers($servers)

Add a list of job servers to a worker. The format for the server list is:
SERVER[:PORT][,SERVER[:PORT]]... No socket I/O happens here, it is just added
to a list. Returns a standard gearman return value.

=head2 $worker->remove_servers()

Remove all servers currently associated with the worker.

=head2 $worker->echo($data)

Send data to all job servers to see if they echo it back. This is a test
function to see if job servers are responding properly.
Returns a standard gearman return value.

=head2 $worker->add_function($function_name, $timeout, $function, $function_args)

Register and add callback function for worker. Returns a standard gearman
return value.

=head2 $worker->work()

Wait for a job and call the appropriate callback function when it gets one.
Returns a standard gearman return value.

=head2 $worker->grab_job()

Get a job from one of the job servers. Returns a standard gearman return value.

=head2 $worker->error()

Return an error string for the last error encountered.

=head2 $worker->options()

Get options for a worker.

=head2 $worker->set_options($options)

Set options for a worker.

=head2 $worker->add_options($options)

Add options for a worker.

=head2 $worker->remove_options($options)

Remove options for a worker.

=head2 $worker->timeout()

Get current socket I/O activity timeout value. Returns Timeout in milliseconds
to wait for I/O activity.

=head2 $worker->set_timeout($timeout)

Set socket I/O activity timeout for connections in milliseconds.

=head2 $worker->register($function_name, $timeout)

Register function with job servers with an optional timeout. The timeout
specifies how many seconds the server will wait before marking a job as failed.
Returns a standard gearman return value.

=head2 $worker->unregister($function_name)

Unregister function with job servers. Returns a standard gearman return value.

=head2 $worker->unregister_all()

Unregister all functions with job servers. Returns a standard gearman return
value.

=head2 $worker->function_exist($function_name)

See if a function exists in the server. Returns 1 if the function exists,
empty string if not.

=head2 $worker->wait()

When in non-blocking I/O mode, wait for activity from one of the servers.

=head2 $worker->set_log_fn($function, $verbose)

Set logging function.

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
