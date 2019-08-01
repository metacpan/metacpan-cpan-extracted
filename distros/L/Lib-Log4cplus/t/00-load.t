#!perl
use 5.008001;
use strict;
use warnings;

use Test::More;

use_ok('Lib::Log4cplus') or BAIL_OUT("Couldn't load Lib::Log4cplus");
use_ok('Log::Log4cplus') or BAIL_OUT("Couldn't load Log::Log4cplus");

diag("Testing Lib::Log4cplus $Lib::Log4cplus::VERSION, Perl $], $^X");

done_testing();
