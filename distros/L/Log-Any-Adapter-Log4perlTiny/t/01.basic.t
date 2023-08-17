#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Output;

use Log::Any '$log';
use Log::Any::Adapter 'Log4perlTiny';
use Log::Log4perl::Tiny ();

my $real_logger = Log::Log4perl::Tiny->get_logger;
$real_logger->format('%M %m%n');
$real_logger->level('INFO');

stderr_is(\&here,  "main::here whatever\n", 'test %M for correct level');
stderr_is(\&there, '', 'test no DEBUG output in INFO level');

done_testing();

sub here  { $log->info('whatever') }
sub there { $log->debug('sorry!') }
