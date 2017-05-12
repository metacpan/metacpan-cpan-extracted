use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 18;

BEGIN {
	use_ok('Debug::Client');
	use_ok('t::lib::Debugger');

	use_ok( 'Carp',           '1.20' );
	use_ok( 'IO::Socket::IP', '0.21' );
	use_ok( 'PadWalker',      '1.96' );
	use_ok( 'Term::ReadLine', '1.1' );
	use_ok( 'constant',       '1.21' );

	use_ok( 'Exporter',        '5.64' );
	use_ok( 'File::HomeDir',   '1' );
	use_ok( 'File::Spec',      '3.4' );
	use_ok( 'File::Temp',      '0.2301' );
	use_ok( 'Test::CheckDeps', '0.006' );
	use_ok( 'Test::Class',     '0.39' );
	use_ok( 'Test::Deep',      '0.11' );
	use_ok( 'Test::More',      '0.98' );
	use_ok( 'Test::Requires',  '0.07' );
	use_ok( 'parent',          '0.225' );
	use_ok( 'version',         '0.9902' );
}

diag("Info: Testing Debug::Client $Debug::Client::VERSION");
diag("Info: Perl $PERL_VERSION");

done_testing();

__END__
