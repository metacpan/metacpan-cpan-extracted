#!/usr/bin/env perl
#
use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok( 'HTML::ExtractMeta' );
}

diag( 'Testing HTML::ExtractMeta ' . $HTML::ExtractMeta::VERSION . ', Perl' . $] );

done_testing;
