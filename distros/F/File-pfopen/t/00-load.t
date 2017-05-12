#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('File::pfopen') || print 'Bail out!';
}

require_ok('File::pfopen') || print 'Bail out!';

diag( "Testing File::pfopen $File::pfopen::VERSION, Perl $], $^X" );
