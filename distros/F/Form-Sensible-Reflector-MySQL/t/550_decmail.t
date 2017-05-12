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

foreach my $col ('my_decimal', 'my_numeric'){

	my $form  = $reflector->reflect_from($Local::Fixtures::dbh, 
		{
			%$options,
			only_columns => [$col]
		}
	);
	
	$form->field($col)->value( 'a test string' );
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr'not a valid', 
		'String is NaN'
	); 
	
	# TODO Bounds and out of bounds tests
	$form->field($col)->value( '9' x 66 );
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr'too many digits', 
		'Exceeds default'
	); 
	
}


foreach my $col ('my_decimalmd', 'my_numericmd'){
	my $form  = $reflector->reflect_from($Local::Fixtures::dbh, 
		{
			%$options,
			only_columns => [$col]
		}
	);
	$form->field($col)->value( 'a test string' );
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr'not a valid', 
		'String is NaN'
	); 

	my $max = $Local::Fixtures::dbh->selectrow_array(
		"SELECT `$col` FROM $Local::Fixtures::table_name LIMIT 1"
	);

	$form->field($col)->value( $max );
	is( 
		scalar keys %{$form->validate->error_fields},
		0, 
		'Max OK'
	) or explain $form->validate->error_fields; 

	$form->field($col)->value( $max+1 );
	
	ok( exists( $form->validate->error_fields->{$col} ), 'max+1 produced error');
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr/ has too many digits in total: the maximum is \d+/, 
		'Max +1 err msg'
	);

}
	
done_testing(12);

