#!/run/bin/perl 

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Test::More tests => 1;

BEGIN {
	$SIG{__DIE__}	= sub {
		warn @_;
		BAIL_OUT( q[Couldn't use module; can't continue.] );	
		
	};
}	

BEGIN {
	use Devel::Comments;
}

pass( 'Load module.' );
diag( "Testing Devel::Comments $Devel::Comments::VERSION" );



