#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Log::WarnDie') || print 'Bail out!';
}

require_ok('Log::WarnDie') || print 'Bail out!';

diag("Testing Log::WarnDie $Log::WarnDie::VERSION, Perl $], $^X");
