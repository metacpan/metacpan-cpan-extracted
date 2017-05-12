use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;

# Test enums and sets
#		my_enum ENUM('one', 'two', 'three', 'comma,', 'apostrophe''') NOT NULL,
#		my_set SET('one', 'two', 'three') NOT NULL,

use Test::Most;
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
	
my $options = { 
	form_name => $Local::Fixtures::table_name,
	no_db_defaults => 1,
};

my $reflector = Form::Sensible::Reflector::MySQL->new();

my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);


my $col = 'my_set';

is( $form->field($col)->field_type, 'select', 'class');
is( $form->field($col)->accepts_multiple, 1, 'accepts_multiple');


$form->field($col)->value( 'one' );
ok( 
	scalar keys %{ $form->validate->error_fields },
	'No errors on enum, single'
); 

$form->field($col)->value( 'asdf' );
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'invalid',
	'invalid'
); 

$form->field($col)->value( 'one,asdf' );
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'invalid',
	'invalid'
); 










$col = 'my_enum';

is( $form->field($col)->field_type, 'select', 'class');
isnt( $form->field($col)->accepts_multiple, 1, 'not accepts_multiple');

$form->field($col)->value( 'one' );
ok( 
	scalar keys %{ $form->validate->error_fields },
	'No errors on enum, single'
); 

$form->field($col)->value( 'one,two' );
ok( 
	scalar keys %{ $form->validate->error_fields },
	'Errors on enum, double'
); 
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'invalid',
	'invalid double selection on enum'
); 

$form->field($col)->value( 'asdf' );
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'invalid',
	'invalid'
); 

$form->field($col)->value( 'one,asdf' );
like( 
	$form->validate->error_fields->{$col}->[0],
	qr'invalid',
	'invalid'
); 


TODO: {
	local $TODO = 'Unexpected return from Select->value: https://rt.cpan.org/Ticket/Display.html?id=64544';
	$form->field($col)->value( 'one', 'two' );
	isa_ok( 
		$form->field($col)->value( ['one', 'two'] ),
		'ARRAY',
		'Select value'
	);

	ok( 
		not scalar keys %{ $form->validate->error_fields },
		'Errors on enum, double'
	); 
	ok(	$form->validate->error_fields->{$col}->[0], 'error field');
	like( 
		$form->validate->error_fields->{$col}->[0],
		qr/invalid/,
		'invalid double selection on enum'
	); 


}	



done_testing( 16 );

