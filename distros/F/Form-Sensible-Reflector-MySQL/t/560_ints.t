use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;

# Test ints

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

die_on_fail;

my (@rv);
	
my $options = { 
	form_name => $Local::Fixtures::table_name,
	no_db_defaults => 1,
};

my $reflector = Form::Sensible::Reflector::MySQL->new();

my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);

goto TEST;

# TINYINT S

is( $form->field('my_tinyint_s')->field_type, 'number', 'class');

$form->field('my_tinyint_s')->value( 'a test string' );
@rv = $form->field('my_tinyint_s')->validate;
like( $rv[0], qr'is not a number', 'NaN');

$form->clear_state;

$form->field('my_tinyint_s')->value( -129 );
like(  $form->validate->error_fields->{'my_tinyint_s'}->[0], qr'lower', 'lower'); 

TEST:
$form->field('my_tinyint_s')->value( -128 );
is( $form->field('my_tinyint_s')->value, -128, 'Set negative value' );

is(
	$form->field('my_tinyint_s')->validate,
	0,
	"No error for tinyint signed"
) or explain $form->field('my_tinyint_s')->validate->error_fields;


$form->set_values({ my_tinyint_s => 128 });
like(  $form->validate->error_fields->{'my_tinyint_s'}->[0], qr'higher', '128 higher for tinyint s'); 

$form->set_values({ my_tinyint_s => 128 });
ok( not($form->validate->is_valid), 'tinyint s 128 ok');

# TINYINT U	

is( $form->field('my_tinyint_u')->field_type, 'number', 'class');

$form->field('my_tinyint_u')->value( 'a test string' );
@rv = $form->field('my_tinyint_u')->validate;
like( $rv[0], qr'is not a number', 'NaN');

$form->field('my_tinyint_u')->value( 256 );
like( 
	$form->validate->error_fields->{'my_tinyint_u'}->[0],
	qr'higher',
	'higher'
); 

$form->field('my_tinyint_u')->value( 255 );

is(
	$form->field('my_tinyint_u')->validate,
	0,
	"No error for tinyint unsigned"
) or explain $form->field('my_tinyint_u')->validate->error_fields;



$form->field('my_tinyint_u')->value( -1 );
@rv = $form->field('my_tinyint_u')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_tinyint_u')->value( 0 );
is(
	$form->field('my_tinyint_u')->validate,
	0,
	"No error for tinyint unsigned"
) or explain $form->field('my_tinyint_u')->validate->error_fields;



# SMALLINT S

is( $form->field('my_smallint_s')->field_type, 'number', 'class');

$form->field('my_smallint_s')->value( 'a test string' );
@rv = $form->field('my_smallint_s')->validate;
like( $rv[0], qr'is not a number', 'NaN');

$form->field('my_smallint_s')->value( -32769 );
@rv = $form->field('my_smallint_s')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_smallint_s')->value( -32768 );
is( $form->field('my_smallint_s')->validate, 0, 'smallint s -32768 ok');

$form->set_values({ my_smallint_s => 32768 });
@rv = $form->field('my_smallint_s')->validate;
like( $rv[0], qr'higher', 'higher');

$form->set_values({ my_smallint_s => 32767 });
ok( not($form->validate->is_valid), 'smallint s 32767 ok');

$form->set_values({ my_smallint_s => 0 });
ok( not($form->validate->is_valid), 'smallint s 0 ok');

# SMALLINT U	

is( $form->field('my_smallint_u')->field_type, 'number', 'class');

$form->field('my_smallint_u')->value( 'a test string' );
@rv = $form->field('my_smallint_u')->validate;
like( $rv[0], qr'not a number', 'NaN');

$form->field('my_smallint_u')->value( 65536 );
@rv = $form->field('my_smallint_u')->validate;
like( $rv[0], qr'higher', 'higher'); 

$form->field('my_smallint_u')->value( 65535 );
is( $form->field('my_smallint_u')->validate, 0, 'smallint u 255 ok' );

$form->field('my_smallint_u')->value( -1 );
@rv = $form->field('my_smallint_u')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_smallint_u')->value( 0 );
is( $form->field('my_smallint_u')->validate, 0, 'smallint u 0 ok' );


# MEDIUMINT S

is( $form->field('my_mediumint_s')->field_type, 'number', 'class');

$form->field('my_mediumint_s')->value( 'a test string' );
@rv = $form->field('my_mediumint_s')->validate;
like( $rv[0], qr'not a number', 'NaN');

$form->field('my_mediumint_s')->value( -8388609 );
@rv = $form->field('my_mediumint_s')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_mediumint_s')->value( -8388608 );
is( $form->field('my_mediumint_s')->validate, 0, 'mediumint s -8388608 ok');

$form->set_values({ my_mediumint_s => 8388608 });
@rv = $form->field('my_mediumint_s')->validate;
like( $rv[0], qr'higher', 'higher');

$form->set_values({ my_mediumint_s => 8388607 });
ok( not($form->validate->is_valid), 'mediumint s 8388607 ok');

$form->set_values({ my_mediumint_s => 0 });
ok( not($form->validate->is_valid), 'mediumint s 0 ok');

# MEDIUMINT U	

is( $form->field('my_mediumint_u')->field_type, 'number', 'class');

$form->field('my_mediumint_u')->value( 'a test string' );
@rv = $form->field('my_mediumint_u')->validate;
like( $rv[0], qr'not a number', 'NaN');

$form->field('my_mediumint_u')->value( 16777216 );
@rv = $form->field('my_mediumint_u')->validate;
like( $rv[0], qr'higher'); 

$form->field('my_mediumint_u')->value( 16777215 );
is( $form->field('my_mediumint_u')->validate, 0, 'mediumint u 255 ok' );

$form->field('my_mediumint_u')->value( -1 );
@rv = $form->field('my_mediumint_u')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_mediumint_u')->value( 0 );
is( $form->field('my_mediumint_u')->validate, 0,  'mediumint u 0 ok' );


# INT S

is( $form->field('my_int_s')->field_type, 'number', 'class');

$form->field('my_int_s')->value( 'a test string' );
@rv = $form->field('my_int_s')->validate;
like( $rv[0], qr'not a number', 'NaN');

$form->field('my_int_s')->value( -2147483649 );
@rv = $form->field('my_int_s')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_int_s')->value( -2147483648 );
is( $form->field('my_int_s')->validate, 0, 'int s -8388608 ok');

$form->set_values({ my_int_s => 2147483648 });
@rv = $form->field('my_int_s')->validate;
like( $rv[0], qr'higher', 'higher');

$form->set_values({ my_int_s => 2147483647 });
ok( not($form->validate->is_valid), 'int s 8388607 ok');

$form->set_values({ my_int_s => 0 });
ok( not($form->validate->is_valid), 'int s 0 ok');

# INT U	

is( $form->field('my_int_u')->field_type, 'number', 'class');

$form->field('my_int_u')->value( 'a test string' );
@rv = $form->field('my_int_u')->validate;
like( $rv[0], qr'not a number', 'NaN');

$form->field('my_int_u')->value( 4294967296 );
@rv = $form->field('my_int_u')->validate;
like( $rv[0], qr'higher'); 

$form->field('my_int_u')->value( 4294967295 );
is( $form->field('my_int_u')->validate, 0, 'int u 255 ok' );

$form->field('my_int_u')->value( -1 );
@rv = $form->field('my_int_u')->validate;
like( $rv[0], qr'lower', 'lower'); 

$form->field('my_int_u')->value( 0 );
is( $form->field('my_int_u')->validate,  0, 'int u 0 ok' );


# BIGINT S

is( $form->field('my_bigint_s')->field_type, 'Text', 'class');

$form->field('my_bigint_s')->value( 'a test string' );
like( 
	$form->validate->error_fields->{'my_bigint_s'}->[0], 
	qr'invalid',
	'NaN'
) or explain $form->validate->error_fields->{'my_bigint_s'};

$form->field('my_bigint_s')->value( -9223372036854775809 );

is( $form->field('my_bigint_s')->value, -9223372036854775809, 'big int signed');
TODO: {
	local $TODO = 'Error messages vary between versions of Form::Sensible';
	# http://www.cpantesters.org/cpan/report/3af9e5c6-520e-11e0-8a1e-03415704ce1c
	like(  
		$form->validate->error_fields->{'my_bigint_s'}->[0], 
		qr'lower', 
		'big int s lower'
	); 
}

$form->field('my_bigint_s')->value( -9223372036854775808 );
is( $form->field('my_bigint_s')->validate, 0, 'bigint s -9223372036854775808 ok');

$form->set_values({ my_bigint_s => 9223372036854775808 });
like( 
	$form->validate->error_fields->{'my_bigint_s'}->[0], 
	qr'higher',
	'Higher'
) or explain $form->validate->error_fields->{'my_bigint_s'};

$form->set_values({ my_bigint_s => 9223372036854775807 });
ok( not($form->validate->is_valid), 'bigint s 9223372036854775807 ok');

$form->set_values({ my_bigint_s => 0 });
ok( not($form->validate->is_valid), 'bigint s 0 ok');

# BIGINT U	

is( $form->field('my_bigint_u')->field_type, 'Text', 'class');

$form->field('my_bigint_u')->value( 'a test string' );
like(
	$form->validate->error_fields->{'my_bigint_u'}->[0],
	qr'invalid',
	'a test string is NaN'
);

$form->field('my_bigint_u')->value( 18446744073709551616 );
like( 
	$form->validate->error_fields->{'my_bigint_u'}->[0],
	qr'higher',
	'exceeds big int u upper bounds'
);

$form->field('my_bigint_u')->value( 255 );
is( 
	scalar keys %{$form->validate->error_fields->{my_bigint_u}},
	0,
	'bigint u 255 ok' 
);

$form->field('my_bigint_u')->value( -1 );
like(
	$form->validate->error_fields->{my_bigint_u}->[0],  , 
	qr'lower', 
	'lower'
); 


$form->field('my_bigint_u')->value( 1 );
is( $form->field('my_bigint_u')->validate, 0,  'bigint u 1 ok' );


$form->field('my_bigint_u')->value( 0 );
is( $form->field('my_bigint_u')->validate, 0, 'bigint u 0 ok' );


done_testing( 64 );

