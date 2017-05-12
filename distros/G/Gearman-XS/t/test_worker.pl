#!/usr/bin/env perl
#
# Gearman Perl front end
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
# 
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

use Storable;
use Data::Dumper;

use FindBin qw($Bin);
use lib ("$Bin/../blib/lib", "$Bin/../blib/arch");

use Gearman::XS qw(:constants);
use Gearman::XS::Worker;

my $worker = new Gearman::XS::Worker;
$worker->add_server('127.0.0.1', 4731);

$worker->add_function("reverse", 0, \&reverse, '');
$worker->add_function("fail", 0, \&fail, '');
$worker->add_function("status", 0, \&status, '');
$worker->add_function("storable", 0, \&storable, '');
$worker->add_function("add", 0, \&add, '');
$worker->add_function("quit", 0, \&quit, '');
$worker->add_function("complete", 0, \&complete, '');
$worker->add_function("warning", 0, \&warning, '');
$worker->add_function("undef_return", 0, \&undef_return, '');
$worker->add_function("wait_two_seconds", 0, \&wait_two_seconds, '');

while (1)
{
  my $ret= $worker->work();
  if ($ret != GEARMAN_SUCCESS)
  {
    printf(STDERR "%s\n", $worker->error());
  }
}

sub reverse {
  my ($job) = @_;

  my $workload= $job->workload();
  my $result= reverse($workload);

  return $result;
}

sub quit {
  my ($job) = @_;

  my $workload= $job->workload();

  die "I'm out.\n";
}

sub status {
  my ($job) = @_;

  $job->send_data('test data');

  sleep(1);
  $job->send_status(1, 4);

  sleep(1);
  $job->send_status(2, 4);

  sleep(1);
  $job->send_status(3, 4);

  sleep(1);
  $job->send_status(4, 4);

  sleep(1);
  return $job->workload();
}

sub warning {
  my ($job) = @_;

  $job->send_warning("argh");

  return $job->workload();
}

sub add {
  my ($job) = @_;

  my ($a, $b) = split(/\s+/, $job->workload());

  return ($a + $b);
}

sub storable {
  my ($job) = @_;

  my $storable= $job->workload();
  my $workload= Storable::thaw($storable);

  return Storable::nfreeze($workload);
}

sub fail {
  my ($job) = @_;

  my $workload= $job->workload();

  $job->send_fail();

  return;
}

sub complete {
  my ($job) = @_;

  $job->send_complete($job->workload());

  return;
}

sub undef_return {
  my ($job) = @_;
  return;
}

sub wait_two_seconds {
  my ($job) = @_;
  sleep(2);
  return 1;
}
