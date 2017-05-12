#!/usr/bin/perl -w
use Test::More;
use strict;

BEGIN {
	plan tests => 10;
	use_ok('Devel::FindGlobals');
}


SKIP: {
	ok(my $globals = find_globals(), 'Get globals');

	is(   $globals->{SCALAR}{'Devel::FindGlobals::VERSION'},  1, 'Check version' );
	isnt( $globals->{SCALAR}{'Devel::FindGlobals::VERSIONa'}, 1, 'Check versiona' );
}

SKIP: {
	ok(my $globals = find_globals_sizes(), 'Get globals sizes');

	cmp_ok( $globals->{SCALAR}{'Devel::FindGlobals::VERSION'},  '>=', 10, 'Check version'  );
	cmp_ok( $globals->{SCALAR}{'Devel::FindGlobals::VERSIONa'}, '<=', 10, 'Check versiona' );
}


SKIP: {
	ok(my $globals = print_globals_sizes(), 'Get globals sizes table');

	like(   $globals, qr/\$Devel::FindGlobals::VERSION/,  'Check version');
	unlike( $globals, qr/\$Devel::FindGlobals::VERSIONa/, 'Check versiona');
}

__END__
