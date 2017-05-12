use Test::More;
use Test::UseAllModules;

BEGIN {
	use strict;
	$^W = 1;
	$| = 1;

	plan tests => Test::UseAllModules::_get_module_list() + 1;

	ok(($] > 5.008000), 'Perl version acceptable') or BAIL_OUT ('Perl version unacceptably old.');
	all_uses_ok();
	diag( "Testing Dist::Zilla::BeLike::CSJEWELL $Dist::Zilla::BeLike::CSJEWELL::VERSION" );
}

