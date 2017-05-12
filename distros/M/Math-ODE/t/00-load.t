use File::Spec;
use lib File::Spec->catfile("..","lib");
use Test::More tests => 1;

BEGIN {
	use_ok( 'Math::ODE' );
}

#diag( "Testing Math::ODE " . $Math::ODE::VERSION . ", Perl $], $^X" );
