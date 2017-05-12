use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;

# Tests floats

use Test::Most;

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

# FLOAT(n,m)
my $col = 'my_floatnm';
my $form  = $reflector->reflect_from($Local::Fixtures::dbh, 
	{
		%$options,
		only_columns => [$col]
	}
);

is( scalar $form->get_fields, 1, 'number of fields');

$form->field($col)->value( 'a test string' );

isnt( 
	scalar keys %{ $form->validate->error_fields }, 
	0, 
	$col.' NaN produces errors'
);

like( 
	$form->validate->error_fields->{$col}->[0],
	qr'not a valid', 'NaN'
); 


is(
	$form->field('my_floatnm')->{upper_bound},
	999.99,
	'upper bound of float'
);
is(
	$form->field('my_floatnm')->{lower_bound},
	-999.99,
	'lower bound of float'
);

$form->field('my_floatnm')->value( 9999 );
@rv = $form->field('my_floatnm')->validate;
#like( $rv[0], qr'higher', 'float too high'); 
like( $rv[0], qr'3', 'float too high'); 

$form->field('my_floatnm')->value( 99.999 );
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'3',
	'NaN error'
); 

$form->field('my_floatnm')->value( 999.99 );
is( 
	scalar (keys %{$form->validate->error_fields}),
	0,
	'no errors'
);

$form->field($col)->value( 18446744073709551615 );
TODO: {
	local $TODO = 'Error messages vary between versions of Form::Sensible';
	# http://www.cpantesters.org/cpan/report/3af9e5c6-520e-11e0-8a1e-03415704ce1c
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr'3'
	); 
}

is(
	$form->field($col)->{upper_bound},
	999.99,
	'upper bound of s float'
);
is(
	$form->field($col)->{lower_bound},
	-999.99,
	'lower bound of s float'
);

$form->field($col)->value( 10000 );
@rv = $form->field($col)->validate;
#like( $rv[0], qr'higher', 'float too high'); 
like( $rv[0], qr'3', 'float too high'); 



# FLOAT(n)
$col = 'my_floatn';
$form  = $reflector->reflect_from($Local::Fixtures::dbh, 
	{
		%$options,
		only_columns => [qw[ my_floatn ]]
	}
);

$form->field('my_floatn')->value( 'a test string' );

isnt( scalar keys %{ $form->validate->error_fields }, 0, 'has errors');

like( 
	$form->validate->error_fields->{'my_floatn'}->[0],
	qr'not a valid',
	'NaN'
); 

$form->field($col)->value( 18446744073709551615 );
isnt( 
	$form->validate->error_fields->{$col}->[0],
	'Invalid number format', 'NaN'
); 

done_testing(15);

