#! /usr/bin/env perl
use strict;
use warnings;
no warnings 'once';
use Test::More;
use Scalar::Util 'weaken';

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
		group1 => [ '$scalar', '@array', '%hash' ]
	);
	sub opt {
		no strict "refs";
		push @{ shift->{into}.'::opt_output' }, __PACKAGE__;
	}
	1;
}, 'declare Example' ) or diag $@;

Example->import({ into => 'CleanNamespace1', scope => \my $scope }, ':group1');
# use eval to prevent instantiating vars at compile time
is( eval '*CleanNamespace1::array{ARRAY}', *Example::array{ARRAY}, 'Exported to package' );

# the $scope holds a reference to the blessed importer.  This isn't part of the API,
# but reach in and grab it in order to test that the objects actually got cleaned up.
weaken( my $exporter_instance= $scope->[0] );

# $scope should be the only reference to that scope object, so weakening it should
# garbage collect it, and unimport the symbols.
weaken($scope);
is( $scope, undef, 'Weakened scope got garbage collected' );
is( $exporter_instance, undef, 'Exporter instance also got garbage collected' );
is( eval '*CleanNamespace1::array{ARRAY}', undef, 'Exported symbols were removed' );

done_testing;
