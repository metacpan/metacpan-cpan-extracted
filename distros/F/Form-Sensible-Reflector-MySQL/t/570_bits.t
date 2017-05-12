use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;
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

my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);

isa_ok($form, 'Form::Sensible::Form');

# BIT
is( $form->field('my_bit')->field_type, 'text', 'class');
is( $form->field('my_bit1')->field_type, 'toggle', 'class');

is( $form->field('my_bit1')->{on_value}, 1, 'toggle on true');
is( $form->field('my_bit1')->{off_value}, 0, 'toggle off false');

$form->field('my_bit')->value( 'a test string' );
like( 
	$form->validate->error_fields->{my_bit}->[0], 
	qr'4$',
	'too long'
);

$form->field('my_bit1')->value( 'a test string' );
isnt(  $form->validate->error_fields->{'my_bit1'}->[0], undef, 'bit(1) bad string' ); 
like(
	$form->validate->error_fields->{my_bit1}->[0], 
	qr'must be ',
	'Our custom error message'
);

$form->field('my_bit1')->value( 1 );
is(  $form->validate->error_fields->{'my_bit1'}->[0], undef, 'bit(1) 1' ); 

$form->field('my_bit1')->value( 0 );
is(  $form->validate->error_fields->{'my_bit1'}->[0], undef, 'bit(1) 0' ); 

$form->field('my_bit1')->value( 11 );
isnt(  $form->validate->error_fields->{'my_bit1'}->[0], undef, 'bit(1) 11' ); 

is( $form->field('my_bit')->{maximum_length}, 4, 'field length' );
foreach my $good (qw( 0000 1111 1001 11 01 1 )){
	$form->field('my_bit')->value( $good );
	is( length( $form->field('my_bit')->value), length($good), 'length of value is as expected');
	is(  $form->validate->error_fields->{'my_bit'}->[0], undef, 'Accepts '.$good); 
}

foreach my $bad (qw( 
	99 -1 foo 
)){
	$form->field('my_bit')->value( $bad );
	is( length( $form->field('my_bit')->value), length($bad), 'length of value is as expected');
	isnt(  $form->validate->error_fields->{'my_bit'}->[0], undef, 'Error on '.$bad); 
}


# Toggle field
is( 
	$form->field('my_true_boolean')->{on_value},
	1,
	'boolean true'
);

is( 
	$form->field('my_true_boolean')->{off_value},
	0,
	'boolean false'
);


done_testing( 32 );

