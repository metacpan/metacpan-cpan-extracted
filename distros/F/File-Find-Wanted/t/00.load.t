#!perl -Tw

use Test::More tests => 1;

use File::Find::Wanted;

diag( "Testing File::Find::Wanted $File::Find::Wanted::VERSION, Perl $], $^X" );

pass( 'All modules loaded' );

done_testing();
