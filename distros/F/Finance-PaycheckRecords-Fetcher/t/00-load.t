#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Finance::PaycheckRecords::Fetcher');
}

diag("Testing Finance::PaycheckRecords::Fetcher $Finance::PaycheckRecords::Fetcher::VERSION");
