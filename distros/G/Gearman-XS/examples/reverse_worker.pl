#!/usr/bin/env perl

# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.
#
# Example Worker

use strict;
use warnings;

use Getopt::Std;

use FindBin qw($Bin);
use lib ("$Bin/../blib/lib", "$Bin/../blib/arch");

use constant REVERSE_WORKER_OPTIONS_NONE    => 0;
use constant REVERSE_WORKER_OPTIONS_DATA    => (1 << 0);
use constant REVERSE_WORKER_OPTIONS_STATUS  => (1 << 1);
use constant REVERSE_WORKER_OPTIONS_UNIQUE  => (1 << 2);

use Gearman::XS qw(:constants);
use Gearman::XS::Worker;

my %opts;
if (!getopts('h:p:c:t:dsu', \%opts))
{
  usage();
  exit(1);
}

my $host= $opts{h} || '';
my $port= $opts{p} || 0;
my $count= $opts{c} || 0;
my $timeout= $opts{t} || -1;

my $options= REVERSE_WORKER_OPTIONS_NONE;

if ($opts{d})
{
  $options |= REVERSE_WORKER_OPTIONS_DATA
}
if ($opts{s})
{
  $options |= REVERSE_WORKER_OPTIONS_STATUS
}
if ($opts{u})
{
  $options |= REVERSE_WORKER_OPTIONS_UNIQUE
}

my $worker= new Gearman::XS::Worker;

if ($options & REVERSE_WORKER_OPTIONS_UNIQUE)
{
  $worker->add_options(GEARMAN_WORKER_GRAB_UNIQ);
}

if ($timeout >= 0)
{
  $worker->set_timeout($timeout);
}

my $ret= $worker->add_server($host, $port);
if ($ret != GEARMAN_SUCCESS)
{
  printf(STDERR "%s\n", $worker->error());
  exit(1);
}

$ret= $worker->add_function("reverse", 0, \&reverse, $options);
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

  if ($count > 0)
  {
    $count--;
    if ($count == 0)
    {
      last;
    }
  }
}

sub reverse {
  my ($job, $options) = @_;

  my $workload= $job->workload();
  my $workload_size= length($workload);

  my $result= '';

  for (my $i= $workload_size; $i > 0; $i--)
  {
    my $letter= substr($workload, ($i - 1), 1);
    $result .= $letter;

    if ($options & REVERSE_WORKER_OPTIONS_DATA)
    {
      my $ret= $job->send_data($letter);
      if ($ret != GEARMAN_SUCCESS)
      {
        return '';
      }
    }

    if ($options & REVERSE_WORKER_OPTIONS_STATUS)
    {
      my $ret= $job->send_status($workload_size - $i, $workload_size);
      if ($ret != GEARMAN_SUCCESS)
      {
        return '';
      }
      sleep(1);
    }
  }

  printf("Job=%s%s%s Workload=%s Result=%s\n",
          $job->handle(),
          $options & REVERSE_WORKER_OPTIONS_UNIQUE ? " Unique=" : "",
          $options & REVERSE_WORKER_OPTIONS_UNIQUE ? $job->unique() : "",
          $job->workload(), $result);

  if ($options & REVERSE_WORKER_OPTIONS_DATA)
  {
    return '';
  }

  return $result;
}

sub usage {
  printf("\nusage: %s [-h <host>] [-p <port>]\n", $0);
  printf("\t-c <count>   - number of jobs to run before exiting\n");
  printf("\t-d           - send result back in data chunks\n");
  printf("\t-h <host>    - job server host\n");
  printf("\t-p <port>    - job server port\n");
  printf("\t-s           - send status updates and sleep while running job\n");
  printf("\t-u           - when grabbing jobs, grab the unique id\n");
  printf("\t-t <timeout> - timeout in milliseconds\n");
}

exit;
