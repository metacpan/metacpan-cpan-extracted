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
# Example Client Using Callbacks

use strict;
use warnings;

use Getopt::Std;

use FindBin qw($Bin);
use lib ("$Bin/../blib/lib", "$Bin/../blib/arch");

use Gearman::XS qw(:constants);
use Gearman::XS::Client;

use constant REVERSE_TASKS => 10;

my %opts;
if (!getopts('h:p:', \%opts))
{
  usage();
  exit(1);
}

my $host= $opts{h} || '';
my $port= $opts{p} || 0;

if (scalar @ARGV < 1)
{
  usage();
  exit(1);
}

my $client= new Gearman::XS::Client;

my $ret= $client->add_server($host, $port);
if ($ret != GEARMAN_SUCCESS)
{
  printf(STDERR "%s\n", $client->error());
  exit(1);
}

for (1..REVERSE_TASKS)
{
  my ($ret, $task) = $client->add_task('reverse', $ARGV[0]);
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $client->error());
    exit(1);
  }
  printf("Added: %s\n", $task->unique());
}

$client->set_created_fn(\&created_cb);
$client->set_data_fn(\&data_cb);
$client->set_complete_fn(\&completed_cb);
$client->set_fail_fn(\&fail_cb);
$client->set_status_fn(\&status_cb);

$ret= $client->run_tasks();
if ($ret != GEARMAN_SUCCESS)
{
  printf(STDERR "%s\n", $client->error());
  exit(1);
}

exit;

sub created_cb {
  my ($task) = @_;
  printf("Created: %s\n", $task->job_handle());
  return GEARMAN_SUCCESS;
}

sub data_cb {
  my ($task) = @_;
  printf("Data: %s %s\n", $task->job_handle(), $task->data());
  return GEARMAN_SUCCESS;
}

sub status_cb {
  my ($task) = @_;
  printf("Status: %s (%d/%d)\n", $task->job_handle(), $task->numerator(),
                                $task->denominator());
  return GEARMAN_SUCCESS;
}

sub completed_cb {
  my ($task) = @_;
  printf("Completed: %s %s\n", $task->job_handle(), ($task->data() || ''));
  return GEARMAN_SUCCESS;
}

sub fail_cb {
  my ($task) = @_;
  printf("Failed: %s\n", $task->job_handle());
  return GEARMAN_SUCCESS;
}

sub usage {
  printf("\nusage: $0 [-h <host>] [-p <port>] <string>\n");
  printf("\t-h <host> - job server host\n");
  printf("\t-p <port> - job server port\n");
}
