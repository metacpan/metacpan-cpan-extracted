#!/usr/bin/perl -w
use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Lingua::EN::NameCase') || print 'Bail out!';
}

require_ok('Lingua::EN::NameCase') || print 'Bail out!';

diag("Testing Lingua::EN::NameCase $Lingua::EN::NameCase::VERSION, Perl $], $^X");
