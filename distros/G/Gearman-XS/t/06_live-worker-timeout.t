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

plan tests => 7;

my ($ret, $job_handle);
my @handles = ();

my $timeout = 0;

# client
my $client= new Gearman::XS::Client;
isa_ok($client, 'Gearman::XS::Client');
is($client->add_server('localhost', 4731), GEARMAN_SUCCESS);

# worker
my $worker= new Gearman::XS::Worker;
isa_ok($worker, 'Gearman::XS::Worker');
is($worker->add_server('localhost', 4731), GEARMAN_SUCCESS);
is($worker->add_function("dummy", 0, sub {}, ''), GEARMAN_SUCCESS);
$worker->set_log_fn(\&log_callback, GEARMAN_VERBOSE_ERROR);

my $testlib = new TestLib;
$testlib->run_gearmand();
sleep(2);

$worker->set_timeout(1000); # 1 second
$ret = $worker->work();
is($ret, GEARMAN_TIMEOUT);
is($timeout, 1);

sub log_callback {
  my ($line, $verbose) = @_;
    $timeout++;
}
