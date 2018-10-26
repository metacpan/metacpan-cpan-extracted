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
	our %EXPORT= ( alpha => \&alpha, beta => \&beta, gamma => \&gamma, delta => \&delta );
	sub alpha { 'a' }
	sub beta  { 'b' }
	sub gamma { 'g' }
	sub delta { 'd' }
	1;
}, 'declare Example' ) or diag $@;

subtest replace_die => \&test_replace_die;
sub test_replace_die {
	Example->import_into('NsReplaceDie', ':all');
	ok( eval 'Example->import_into("NsReplaceDie", {replace => "die"}, "alpha");1',
		'Re-export same symbol' )
		or diag $@;
	ok( !eval 'Example->import_into("NsReplaceDie", {replace => "die"}, "alpha", { -as => "beta" });1',
		'Can\t replace with different symbol' );
	eval 'sub NsReplaceDie::foo { 0 };1' or die $@;
	ok( !eval 'Example->import_into("NsReplaceDie", {replace => "die"}, "alpha", { -as => "foo" });1',
		'Prevents overwriting existing subs' )
		or diag $@;
	eval 'push @NsReplaceDie::Array, 1' or die $@;
	ok( eval 'Example->import_into("NsReplaceDie", {replace => "die"}, "alpha", { -as => "Array" });1',
		'Allow adding sub when glob existed alredy' )
		or diag $@;
	done_testing;
}

subtest replace_warn => \&test_replace_warn;
sub test_replace_warn {
	my @warned;
	local *Carp::carp= sub { push @warned, @_ };
	ok( Example->import_into('NsReplaceWarn', { replace => 'warn' }, ':all'), 'imported :all' );
	is_deeply( \@warned, [], 'no warnings' )
		or diag @warned;
	ok( Example->import_into('NsReplaceWarn', { replace => 'warn' }, ':all'), 'imported :all again' );
	is_deeply( \@warned, [], 'no warnings (because same refs imported)' )
		or diag @warned;
	ok( Example->import_into('NsReplaceWarn', 'beta', { -as => 'alpha', replace => 'warn' }), 'imported beta as alpha' );
	is( scalar @warned, 1, 'generated one warning' );
	note @warned;
	is( NsReplaceWarn->alpha, 'b', 'but did import it' );
	done_testing;
}

subtest replace_skip => \&test_replace_skip;
sub test_replace_skip {
	my @warned;
	local *Carp::carp= sub { push @warned, @_ };
	*NsReplaceSkip::delta= sub { 'ours' };
	ok( Example->import_into('NsReplaceSkip', { replace => 'skip' }, ':all'), 'imported :all' );
	is_deeply( \@warned, [], 'no warnings' )
		or diag @warned;
	is( NsReplaceSkip->gamma, 'g', 'installed gamma' );
	is( NsReplaceSkip->delta, 'ours', 'preserved existing delta' );
	done_testing;
}

subtest replace_1 => \&test_replace_1;
sub test_replace_1 {
	my @warned;
	local *Carp::carp= sub { push @warned, @_ };
	*NsReplace1::delta= sub { 'ours' };
	ok( Example->import_into('NsReplace1', { replace => 1 }, ':all'), 'imported :all' );
	is_deeply( \@warned, [], 'no warnings' )
		or diag @warned;
	is( NsReplace1->gamma, 'g', 'installed gamma' );
	is( NsReplace1->delta, 'd', 'installed (overwrote) delta' );
	done_testing;
}

is_deeply( [ Example->alpha, Example->beta, Example->gamma, Example->delta ], [qw( a b g d )], 'sanity check' );

done_testing;
