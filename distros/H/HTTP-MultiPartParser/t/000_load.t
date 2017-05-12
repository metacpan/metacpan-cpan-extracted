#!perl

use strict;
use warnings;

use Test::More tests => 1;

require_ok('HTTP::MultiPartParser');
diag("HTTP::MultiPartParser $HTTP::MultiPartParser::VERSION, Perl $], $^X");

