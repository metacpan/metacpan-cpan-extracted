#!perl -T

use strict;

use Test::Most tests => 2;

BEGIN {
    use_ok('Geo::Coder::Abbreviations') || print 'Bail out!';
}

require_ok('Geo::Coder::Abbreviations') || print 'Bail out!';

diag("Testing Geo::Coder::Abbreviations $Geo::Coder::Abbreviations::VERSION, Perl $], $^X");
