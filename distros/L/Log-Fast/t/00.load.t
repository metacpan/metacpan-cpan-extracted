use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'Log::Fast' ) or BAIL_OUT('unable to load module') }

diag( "Testing Log::Fast $Log::Fast::VERSION, Perl $], $^X" );
