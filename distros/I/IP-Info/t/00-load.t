#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok( 'IP::Info' )                       || print "Bail out!";
    use_ok( 'IP::Info::Response' )             || print "Bail out!";
    use_ok( 'IP::Info::Response::Network' )    || print "Bail out!";
    use_ok( 'IP::Info::Response::Location' )   || print "Bail out!";
    use_ok( 'IP::Info::UserAgent' )            || print "Bail out!";
    use_ok( 'IP::Info::UserAgent::Exception' ) || print "Bail out!";
}

diag( "Testing IP::Info $IP::Info::VERSION, Perl $], $^X" );
