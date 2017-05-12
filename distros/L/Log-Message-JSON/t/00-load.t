#!perl -T

use Test::More tests => 1;

BEGIN {
  BAIL_OUT("can't import Log::Message::JSON")
    if not use_ok('Log::Message::JSON');
}

diag("Testing Log::Message::JSON $Log::Message::JSON::VERSION, Perl $], $^X");

# vim:ft=perl
