#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Test::More;

use_ok( 'Exporter::Extensible' ) or BAIL_OUT;

ok( eval q{
	package Example;
	$INC{'Example.pm'}=1;

	use Exporter::Extensible -exporter_setup => 0;
	our ($scalar, @array, %hash);
	sub code { 1 }
	our %EXPORT= (
		code => \&code,
		'$scalar' => \$scalar,
		'@array' => \@array,
		'%hash' => \%hash,
		-opt => [ "opt", 0 ],
	);
	our %EXPORT_TAGS= (
		group1 => [ '$scalar', '@array', '%hash' ],
		default => [ '@array' ],
	);
	sub opt {
		no strict "refs";
		push @{ shift->{into}.'::opt_output' }, __PACKAGE__;
	}
	1;
}, 'declare Example' ) or diag $@;

Example->import({ into => 'CleanNamespace1' }, ':group1');
# use eval to prevent instantiating vars at compile time
is( eval '*CleanNamespace1::array{ARRAY}', eval '*Example::array{ARRAY}', 'Exported to package' );

my %symbols;
Example->import({ into => \%symbols }, ':group1', 'code');
is_deeply( \%symbols, {
		code => Example->can('code'),
		'$scalar' => eval '*Example::scalar{SCALAR}',
		'@array'  => eval '*Example::array{ARRAY}',
		'%hash'   => eval '*Example::hash{HASH}',
	}, 'Exported to hashref' );

%symbols= ();
Example->import({ into => \%symbols });
is_deeply( \%symbols, {
		'@array'  => eval '*Example::array{ARRAY}',
	}, 'Exported to hashref' );

Example->unimport({ into => 'CleanNamespace1' }, '@array' );
is( eval '*CleanNamespace1::array{ARRAY}', undef, 'Un-exported @array from package' );

Example->unimport({ into => \%symbols }, '$scalar' );
ok( !exists $symbols{'$scalar'}, 'Un-exported $scalar from hashref' );

done_testing;
