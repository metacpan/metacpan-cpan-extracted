#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(no_match_vars);
use Test::More;

use_ok qw(Log::Log4perl::Appender::AmazonSES);

done_testing;

1;
