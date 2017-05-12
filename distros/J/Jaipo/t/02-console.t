#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok( 'Jaipo' ) || print "Bail out!\n";
	use_ok( 'Jaipo::UI::Console' ) || print "Bail out!\n";
}

diag( "Testing Jaipo $Jaipo::VERSION, Perl $], $^X" );

my $jc = Jaipo::UI::Console->new;

ok( $jc );

$jc->init;

ok( $jc );
