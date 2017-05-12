#!perl -T

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok('Log::Dispatch::Email::Sendmail') || print 'Bail out!';
}

require_ok('Log::Dispatch::Email::Sendmail') || print 'Bail out!';

diag( "Log::Dispatch::Email::Sendmail $Log::Dispatch::Email::Sendmail::VERSION, Perl $], $^X" );
