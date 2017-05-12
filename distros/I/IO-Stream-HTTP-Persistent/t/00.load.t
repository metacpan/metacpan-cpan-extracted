use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok( 'IO::Stream::HTTP::Persistent' ) or BAIL_OUT('unable to load module') }

diag( "Testing IO::Stream::HTTP::Persistent $IO::Stream::HTTP::Persistent::VERSION, Perl $], $^X" );
