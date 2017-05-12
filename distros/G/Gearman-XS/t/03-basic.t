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

use Test::More tests => 34;

# import constants
use Gearman::XS qw(:constants);

my ($ret, $job, $job_handle);

# test some constants
is(GEARMAN_SUCCESS, 0);
is(GEARMAN_WORK_FAIL, 24);

# client
my $client = new Gearman::XS::Client;
isa_ok($client, 'Gearman::XS::Client');

$client->add_options(GEARMAN_CLIENT_NON_BLOCKING);
ok($client->options() & GEARMAN_CLIENT_NON_BLOCKING);

$client->remove_options(GEARMAN_CLIENT_NON_BLOCKING);
ok(!($client->options() & GEARMAN_CLIENT_NON_BLOCKING));

$client->set_options(GEARMAN_CLIENT_UNBUFFERED_RESULT);
ok($client->options() & GEARMAN_CLIENT_UNBUFFERED_RESULT);

$client->remove_options(GEARMAN_CLIENT_UNBUFFERED_RESULT);
ok(!($client->options() & GEARMAN_CLIENT_UNBUFFERED_RESULT));

is($client->timeout(), -1);
$client->set_timeout(10000);
is($client->timeout(), 10000);

is($client->error(), undef);

is($client->add_server(), GEARMAN_SUCCESS);
is($client->add_server('localhost'), GEARMAN_SUCCESS);
is($client->add_server('127.0.0.1', 4730), GEARMAN_SUCCESS);
is($client->add_servers('127.0.0.1:4730,127.0.0.1'), GEARMAN_SUCCESS);

$client->remove_servers();

# worker
my $worker = new Gearman::XS::Worker;
isa_ok($worker, 'Gearman::XS::Worker');

$worker->add_options(GEARMAN_WORKER_NON_BLOCKING);
ok($worker->options() & GEARMAN_WORKER_NON_BLOCKING);

$worker->remove_options(GEARMAN_WORKER_NON_BLOCKING);
ok(!($worker->options() & GEARMAN_WORKER_NON_BLOCKING));

$worker->set_options(GEARMAN_WORKER_NON_BLOCKING);
ok($worker->options() & GEARMAN_WORKER_NON_BLOCKING);

$worker->remove_options(GEARMAN_WORKER_NON_BLOCKING);
ok(!($worker->options() & GEARMAN_WORKER_NON_BLOCKING));

is($worker->timeout(), GEARMAN_WORKER_WAIT_TIMEOUT);
$worker->set_timeout(1000);
is($worker->timeout(), 1000);

is($worker->error(), undef);

is($worker->add_server(), GEARMAN_SUCCESS);
is($worker->add_server('127.0.0.1'), GEARMAN_SUCCESS);
is($worker->add_server('localhost', 4730), GEARMAN_SUCCESS);
is($client->add_servers('localhost:4730,127.0.0.1'), GEARMAN_SUCCESS);

$worker->remove_servers();

$client = new Gearman::XS::Client;
$client->add_server('127.0.0.1', 61333);

$worker = new Gearman::XS::Worker;
$worker->add_server('213.3.4.5', 61333);

# no functions
is($worker->work(), GEARMAN_NO_REGISTERED_FUNCTIONS);
($ret, $job) = $worker->grab_job();
is($ret, GEARMAN_NO_REGISTERED_FUNCTIONS);
is(Gearman::XS::strerror($ret), 'GEARMAN_NO_REGISTERED_FUNCTIONS');
is($job, undef);

# no connection
($ret, $job_handle) = $client->do_background("reverse", 'do background', 'unique');
is($ret, GEARMAN_COULD_NOT_CONNECT);
is(Gearman::XS::strerror($ret), 'GEARMAN_COULD_NOT_CONNECT');
is($job_handle, undef);
ok($client->error());
