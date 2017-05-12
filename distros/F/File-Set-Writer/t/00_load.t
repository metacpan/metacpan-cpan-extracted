#!/usr/bin/perl
use warnings;
use strict;
# Disable extra testing for deficient development environments
BEGIN { $ENV{PERL_STRICTURES_EXTRA} = 0; }
use Test::More;

use_ok( "File::Set::Writer" );

done_testing;
