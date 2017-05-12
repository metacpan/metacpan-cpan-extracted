#!perl -T

use Test::More tests => 2;

BEGIN {
    my @modules = qw(
HPSG::Mason
HPSG::Mason::Interp
);

    foreach my $module ( @modules ){
	use_ok( $module );
    }
}

diag( "Testing HPSG::Mason $HPSG::Mason::VERSION, Perl $], $^X" );
