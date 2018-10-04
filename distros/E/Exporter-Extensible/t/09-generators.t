#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once', 'redefine';
use Test::More;
use Scalar::Util 'weaken';

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q{
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 1;
	our %EXPORT= ( alpha => \\\\"alpha", beta => \\\\&beta, '@gamma' => \\\\&gamma, '*zeta' => \\\\'_generateGlob_zeta' );
	our %EXPORT_TAGS= ( delta => \"delta" );
	sub alpha { sub { 'a' } }
	sub beta  { sub { 'b' } }
	sub gamma { ['g'] }
	sub delta { ['alpha', 'beta'] }
	sub _generateGlob_zeta { open my $fh, '<', \"test"; $fh; }
	1;
}, 'declare Example' ) or diag $@;

ok( Example->import_into("Test::_Namespace1", 'alpha'), 'import "alpha"' );
is( eval 'Test::_Namespace1::alpha()', 'a', 'run alpha' );

ok( Example->import_into('Test::_Namespace1', 'beta'), 'import "beta"' );
is( eval 'Test::_Namespace1::beta()', 'b', 'run beta' );

ok( Example->import_into('Test::_Namespace1', '@gamma'), 'import "@gamma"' );
is_deeply( eval '\\@Test::_Namespace1::gamma', ['g'], '@gamma correct value' );

ok( Example->import_into('Test::_Namespace1', '*zeta'), 'import "*zeta"' );
is_deeply( eval 'scalar <Test::_Namespace1::zeta>', 'test', '*zeta correct value' );

ok( Example->import_into("Test::_Namespace2", ':delta'), 'import ":delta"' );
is_deeply( eval 'no strict; [sort keys %{"Test::_Namespace2::"}]', ['alpha','beta'], 'imported alpha, beta' );

done_testing;
