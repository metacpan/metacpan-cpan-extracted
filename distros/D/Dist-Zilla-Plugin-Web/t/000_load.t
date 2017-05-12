use strict;
use warnings;
use Test::More 0.88;

BEGIN {
	use_ok( 'Dist::Zilla::Plugin::Web' );
	use_ok( 'Dist::Zilla::Plugin::Web::Bundle' );
	use_ok( 'Dist::Zilla::Plugin::Web::NPM::Package' );
}

done_testing;