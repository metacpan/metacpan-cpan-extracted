#!perl
use 5.008003;
use strict;
use warnings;

use Test::More;

use_ok('Log::Any::Adapter::Log4cplus') or BAIL_OUT("Couldn't load Log::Any::Adapter::Log4cplus");

diag("Testing Log::Any::Adapter::Log4cplus $Log::Any::Adapter::Log4cplus::VERSION, Perl $], $^X");

done_testing;
