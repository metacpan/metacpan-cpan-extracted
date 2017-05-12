use Test::More tests => 3;
use URI;

BEGIN {
	use_ok( 'URI::virtual' );
};
BEGIN {
	use_ok( 'LWP::Protocol::virtual' );
}

diag(qq(Testing LWP::Protocol::virtual $LWP::Protocol::virtual::VERSION));

ok(ref URI->new("virtual://CPAN/") eq "URI::virtual", q(URI found me));
