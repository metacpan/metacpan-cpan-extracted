#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('LWP::UserAgent::Throttled') || print 'Bail out!';
}

require_ok('LWP::UserAgent::Throttled') || print 'Bail out!';

diag( "Testing LWP::UserAgent::Throttled $LWP::UserAgent::Throttled::VERSION, Perl $], $^X" );
