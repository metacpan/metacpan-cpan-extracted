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

Example->import({ into => 'CleanNamespace1', prefix => 'x_' }, ':group1');
# use eval to prevent instantiating vars at compile time
is( eval '*CleanNamespace1::x_array{ARRAY}', *Example::array{ARRAY}, 'Exported @x_array' );
is( eval '*CleanNamespace1::array{ARRAY}', undef, 'Didn\'t export @array' );

Example->import({ into => 'CleanNamespace2', suffix => '_x' }, 'code');
is( CleanNamespace2->can('code_x'), \&Example::code, 'Exported code_x' );
is( CleanNamespace2->can('code'), undef, 'Didn\'t export code' );

Example->import({ into => 'CleanNamespace3' }, code => { -prefix => 'x', -suffix => 'x' });
is( CleanNamespace3->can('xcodex'), Example->can('code'), 'inline prefix and suffix' );

Example->import({ into => 'CleanNamespace3' }, code => { -as => 'foo' });
is( CleanNamespace3->can('foo'), Example->can('code'), '-as foo' );
is( CleanNamespace3->can('code'), undef, 'code not exported' );

Example->import({ into => 'CleanNamespace4', prefix => 'x_' },
	code => { -as => 'foo' },
	code => { -prefix => 'y_' },
	code => { -suffix => '_y' }
);
no strict 'refs';
my $stash= \%{'CleanNamespace4::'};
is_deeply( [ sort keys %$stash ], [qw( foo x_code_y y_code )], 'mix of prefix and suffix and inline' );

done_testing;
