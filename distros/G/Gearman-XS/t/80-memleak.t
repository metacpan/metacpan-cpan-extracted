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

if ( not $ENV{LINUX_MEMLEAK_CHECK} ) {
  my $msg = 'Hacky linux memory leak test. Set $ENV{LINUX_MEMLEAK_CHECK} to a true value to run.';
  plan( skip_all => $msg );
}

plan tests => 5;

my $testlib = new TestLib;
$testlib->run_gearmand();
$testlib->run_test_worker();
sleep(2);

my $client;
my $vsize;

# check do()
$client= new Gearman::XS::Client;
$client->add_server('127.0.0.1', 4731);

$vsize= vsize();
for (1..10000) {
  $client->do('reverse', 'normal');
}
is(vsize(), $vsize);

# check add_task()/run_tasks()
$client= new Gearman::XS::Client;
$client->add_server('127.0.0.1', 4731);

$vsize= vsize();
for (1..10000) {
  $client->add_task("reverse", 'normal');
  $client->run_tasks();
}
is(vsize(), $vsize);

# check add_task()/run_tasks() with callbacks outside the loop
$client= new Gearman::XS::Client;
$client->add_server('127.0.0.1', 4731);

$client->set_complete_fn(sub {
  my ($task) = @_;
  return GEARMAN_SUCCESS;
});

$vsize= vsize();
for (1..10000) {
  $client->add_task("reverse", 'normal');
  $client->run_tasks();
}
is(vsize(), $vsize);

# check add_task()/run_tasks() with client creation in the loop
$vsize= vsize();
for (1..10000) {
  $client= new Gearman::XS::Client;
  $client->add_server('127.0.0.1', 4731);
  $client->add_task("reverse", 'normal');
  $client->run_tasks();
}
is(vsize(), $vsize);

# check add_task()/run_tasks() with callbacks/client creation inside the loop
my $subref= sub {
  my ($task) = @_;
  return GEARMAN_SUCCESS;
};

$vsize= vsize();
for (1..10000) {
  $client= new Gearman::XS::Client;
  $client->add_server('127.0.0.1', 4731);
  $client->set_complete_fn($subref);
  $client->add_task("reverse", 'normal');
  $client->run_tasks();
  $client->clear_fn();
}
is(vsize(), $vsize);

sub vsize {
  my $vsize = 0;
  if (open(FILE, "/proc/$$/stat")) {
    $vsize = int((split(/ /, <FILE>))[22]);
    close FILE;
  }
  return $vsize;
}
