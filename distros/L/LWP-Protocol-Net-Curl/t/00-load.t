#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More tests => 1;

BEGIN {
    use_ok(q(LWP::Protocol::Net::Curl));
}

diag(qq(LWP::Protocol::Net::Curl v$LWP::Protocol::Net::Curl::VERSION, Perl $], $^X));
