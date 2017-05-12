#!perl -T

use Test::More tests => 1;
# required by appenders to work correctly
use Log::Log4perl;

BEGIN {
  BAIL_OUT("can't import Log::Log4perl::Appender::Fluent")
    if not use_ok('Log::Log4perl::Appender::Fluent');
}

diag("Testing Log::Log4perl::Appender::Fluent $Log::Log4perl::Appender::Fluent::VERSION, Perl $], $^X");

# vim:ft=perl
