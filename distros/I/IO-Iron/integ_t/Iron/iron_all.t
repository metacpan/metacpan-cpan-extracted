#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl';

plan tests => 3;

use IO::Iron ':all';

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
#use Data::Dumper; $Data::Dumper::Maxdepth = 1;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

my $iron_mq_client = ironmq( 'config' => 'iron_mq.json' );
my @iron_mq_queues = $iron_mq_client->get_queues();
ok(scalar @iron_mq_queues >= 0, 'iron_mq:get_queues() returned a list');

my $iron_cache_client = ironcache( 'config' => 'iron_cache.json' );
my @iron_caches = $iron_cache_client->get_caches();
ok(scalar @iron_caches >= 0, 'iron_cache:get_caches() returned a list');

my $iron_worker_client = ironworker( 'config' => 'iron_worker.json' );
my @iron_codes = $iron_worker_client->list_code_packages();
ok(scalar @iron_codes >= 0, 'ironworker:list_code_packages() returned a list');

