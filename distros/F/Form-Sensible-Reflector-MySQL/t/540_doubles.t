use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;
# Tests doubles:
# my_double = 123.456
# my_double_precision = 123.456


use Test::Most ;
die_on_fail;
use Data::Dumper;

BEGIN {
	use Local::Fixtures;
	use Local::Tests;
}

if ( not $Local::Fixtures::dbh ){
	plan skip_all => 'No DBH - please set ENV{DBI_USER} and ENV{DBI_PASS}'; 
} 
	
use Form::Sensible;
use Form::Sensible::Reflector::MySQL;

my (@rv);
	
my $options = { 
	form_name => $Local::Fixtures::table_name,
	no_db_defaults => 1,
};

my $reflector = Form::Sensible::Reflector::MySQL->new();

foreach my $col ('my_double', 'my_real'){

	my $form  = $reflector->reflect_from($Local::Fixtures::dbh, 
		{
			%$options,
			only_columns => [$col]
		}
	);
	
	$form->field($col)->value( 'a test string' );
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr'is not a valid', 
		'String is NaN'
	); 

	TODO: {
		local $TODO = "TODO Math::BigInt->new( -1.7976931348623157E+309 )";
		$form->field($col)->value( Math::BigInt->new( -1.7976931348623157E+309 ));
		# TODO Bounds and out of bounds tests
		is( 
			$form->validate->error_fields->{$col}->[0],
			undef,
			'expon'
		);
	}	
}
	
	
done_testing( 4 );

