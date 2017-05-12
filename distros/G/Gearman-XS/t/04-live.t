# Gearman Perl front end
# Copyright (C) 2013 Data Differential, http://datadifferential.com/
# Copyright (C) 2009-2010 Dennis Schoen
# All rights reserved.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.9 or,
# at your option, any later version of Perl 5 you may have available.

use strict;
use warnings;
use Test::More;
use Storable;
use Gearman::XS qw(:constants);
use FindBin qw( $Bin );
use lib ("$Bin/lib", "$Bin/../lib");
use TestLib;

if ( not $ENV{GEARMAN_LIVE_TEST} ) {
  plan( skip_all => 'Set $ENV{GEARMAN_LIVE_TEST} to run this test' );
}

plan tests => 156;

my ($ret, $result, $job_handle, $task);

my $created   = 0;
my $completed = 0;
my $failed    = 0;
my $warnings  = 0;
my $numerator = 0;
my $data      = 0;
my $tasks     = 0;

# client
my $client= new Gearman::XS::Client;
isa_ok($client, 'Gearman::XS::Client');

is($client->error(), undef);
is($client->add_server('127.0.0.1', 4731), GEARMAN_SUCCESS);

# worker
my $worker= new Gearman::XS::Worker;
isa_ok($worker, 'Gearman::XS::Worker');

is($worker->error(), undef);
is($worker->add_server('127.0.0.1', 4731), GEARMAN_SUCCESS);

my $testlib = new TestLib;
$testlib->run_gearmand();
$testlib->run_test_worker();
sleep(2);

# gearman server running?
is($client->echo("blubbtest"), GEARMAN_SUCCESS);
is($worker->echo("blahfasel"), GEARMAN_SUCCESS);

# single task interface
($ret, $result) = $client->do("reverse", 'do');
is($ret, GEARMAN_SUCCESS);
is($result, reverse('do'));

# this tests perls INT return type
($ret, $result) = $client->do("add", '3 4');
is($ret, GEARMAN_SUCCESS);
is($result, 7);

# this tests perls DOUBLE return type
($ret, $result) = $client->do("add", '3.7 4.3');
is($ret, GEARMAN_SUCCESS);
is($result, 8);

# test binary data
my %hash= (key => 'value');
my $storable= Storable::nfreeze(\%hash);
($ret, $result) = $client->do("storable", $storable);
is($ret, GEARMAN_SUCCESS);
is_deeply(Storable::thaw($result), \%hash);

($ret, $result) = $client->do("reverse", 'do unique', 'unique');
is($ret, GEARMAN_SUCCESS);
is($result, reverse('do unique'));

# integer input
($ret, $result) = $client->do("reverse", 12345, 'unique');
is($ret, GEARMAN_SUCCESS);
is($result, reverse(12345));

($ret, $result) = $client->do_high("reverse", 'do high');
is($ret, GEARMAN_SUCCESS);
is($result, reverse('do high'));

($ret, $result) = $client->do_low("reverse", 'do low');
is($ret, GEARMAN_SUCCESS);
is($result, reverse('do low'));

# TODO: this is currently broken, I still have to think of a fix.
# working with empty strings
# ($ret, $result) = $client->do("reverse", '');
# is($ret, GEARMAN_SUCCESS);
# is($result, '');

# single async task interface
($ret, $job_handle) = $client->do_background("reverse", 'do background', 'unique');
is($ret, GEARMAN_SUCCESS);
like($job_handle, qr/H:.+:.+/);

($ret, $job_handle) = $client->do_high_background("reverse", 'do high background');
is($ret, GEARMAN_SUCCESS);
like($job_handle, qr/H:.+:.+/);

($ret, $job_handle) = $client->do_low_background("reverse", 'do low background');
is($ret, GEARMAN_SUCCESS);
like($job_handle, qr/H:.+:.+/);

# callback functions
$client->set_created_fn(\&created_cb);
$client->set_data_fn(\&data_cb);
$client->set_complete_fn(\&completed_cb);
$client->set_fail_fn(\&fail_cb);
$client->set_status_fn(\&status_cb);
$client->set_warning_fn(\&warning_cb);

# concurrent interface
($ret, $task) = $client->add_task("reverse", 'normal');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

($ret, $task) = $client->add_task_high("reverse", 'high');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

($ret, $task) = $client->add_task_low("reverse", 'low');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

# concurrent async interface
($ret, $task) = $client->add_task_background("reverse", 'background normal');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

($ret, $task) = $client->add_task_high_background("reverse", 'background high');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

($ret, $task) = $client->add_task_low_background("reverse", 'background low');
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

# test fail callback
($ret, $task) = $client->add_task("quit", "I'll be dead");
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

($ret, $task) = $client->add_task("fail", "I will fail.");
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

# test status callback
($ret, $task) = $client->add_task("status", "I'll phone back 4 times");
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');
is($task->numerator(), 0);
is($task->denominator(), 0);
like($task->unique(), qr/\w+-\w+-\w+-\w+-\w+/);

# test warning callback
($ret, $task) = $client->add_task("warning", "warning test");
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

# run concurrent tasks
is($client->run_tasks(), GEARMAN_SUCCESS);

# check callback results
is($created, 10);
is($completed, 5);
is($failed, 2);
is($warnings, 1);
is($data, 1);
is($numerator, 4);

# test clear_fn() really clears callback
$client->clear_fn();
($ret, $task) = $client->add_task("reverse", 'normal');
is($client->run_tasks(), GEARMAN_SUCCESS);
is($created, 10);
is($completed, 5);
is($failed, 2);
is($warnings, 1);
is($data, 1);
is($numerator, 4);

($ret, $result) = $client->do("undef_return", 'blah');
is($ret, GEARMAN_SUCCESS);
is($result, undef);

($ret, $result) = $client->do("complete", 'blubb');
is($ret, GEARMAN_SUCCESS);
is($result, 'blubb');

($ret, $result) = $client->do('warning', 'blubb');
is($ret, GEARMAN_SUCCESS);
is($result, 'blubb');

($ret, $result) = $client->do('fail', 'blubb');
is($ret, GEARMAN_WORK_FAIL);
is($result, undef);

$client= new Gearman::XS::Client;
$client->add_server('127.0.0.1', 4731);

# You can turn off auto task destruction by unsetting this flag on a gearman client.
$client->remove_options(GEARMAN_CLIENT_FREE_TASKS);

($ret, $job_handle) = $client->do_background("status", "blubb");
is($ret, GEARMAN_SUCCESS);

($ret, $task) = $client->add_task_status($job_handle);
is($ret, GEARMAN_SUCCESS);
isa_ok($task, 'Gearman::XS::Task');

is($task->is_known(), '');
sleep(1);     # give the worker some time to start.
is($task->is_running(), '');

is($client->run_tasks(), GEARMAN_SUCCESS);

is($task->is_known(),1 );
is($task->is_running(), 1);

# test timeout
$client->set_timeout(1000); # 1 second
($ret, $result) = $client->do("wait_two_seconds", 'blubb');
is($ret, GEARMAN_TIMEOUT);
is($result, undef);
$client->set_timeout(-1); # infinite

$client= new Gearman::XS::Client;
$client->add_server('127.0.0.1', 4731);
$client->add_options(GEARMAN_CLIENT_NON_BLOCKING);

$tasks= 2;

$client->set_created_fn(\&created_cb);
$client->set_complete_fn(\&completed_cb);

$client->add_task("reverse", 'hello');
$client->add_task("reverse", 'world');

# This while loop should be replaced with $client->send_tasks();
while (1)
{
  my $ret = $client->run_tasks();
  if ($ret == GEARMAN_SUCCESS || $tasks <= 0)
  {
    last;
  }
  is($client->wait(), GEARMAN_SUCCESS);
}
is($created, 12);
is($completed, 5);

# jobs have been sent, do something else here...
sleep(2);

# now block for results
$client->remove_options(GEARMAN_CLIENT_NON_BLOCKING);
is($client->run_tasks(), GEARMAN_SUCCESS);

is($created, 12);
is($completed, 7);

sub created_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);

  $created++;
  $tasks--;

  return GEARMAN_SUCCESS;
}

sub data_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);
  is($task->data(), 'test data');

  $data++;

  return GEARMAN_SUCCESS;
}

sub completed_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);
  like($task->data(), qr/\w+/);
  like($task->data_size(), qr/\d+/);
  like($task->function_name(), qr/\w+/);

  $completed++;

  return GEARMAN_SUCCESS;
}

sub fail_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);
  like($task->function_name(), qr/(fail|quit)/);

  $failed++;

  return GEARMAN_SUCCESS;
}

sub status_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);
  is($task->function_name(), "status");
  is($task->denominator(), 4);
  is($task->numerator(), ++$numerator);

  return GEARMAN_SUCCESS;
}

sub warning_cb {
  my ($task) = @_;

  like($task->job_handle(), qr/H:.+:.+/);
  is($task->function_name(), "warning");

  $warnings++;

  return GEARMAN_SUCCESS;
}
