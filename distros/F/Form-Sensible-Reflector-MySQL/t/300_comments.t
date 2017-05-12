use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;

BEGIN {
	use Local::Fixtures;
	use Local::Tests;
	use Test::Most;
	die_on_fail;
	
	if ( not $Local::Fixtures::dbh ){
		plan skip_all => 'No DBH - please set ENV{DBI_USER} and ENV{DBI_PASS}'; 
	} 
}

use Form::Sensible;
use Form::Sensible::Reflector::MySQL;

isa_ok( $Local::Fixtures::dbh, 'DBI::db' );

# Test with comments

my $is_dbh = eval {
	DBI->connect(
		'DBI:mysql:database=information_schema;host=localhost',
		$Local::Fixtures::test_user,
		$Local::Fixtures::test_password,
	)
};

SKIP:{
	isa_ok( $is_dbh, 'DBI::db' ) or skip 'No CX to information_schema',9;
	
	my $options = { 
		form_name => $Local::Fixtures::table_name,
		information_schema_dbh => $is_dbh
	};
	
	my $reflector = Form::Sensible::Reflector::MySQL->new();
	
	my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);
	
	isa_ok($form, 'Form::Sensible::Form');
	
	# Test field comments as field names
	ok(
		$form->field( 'my_tinyint_s'),
		'Got field by name'
	);
	is(
		$form->field('my_tinyint_s')->display_name,
		$Local::Fixtures::col_comment,
		'Set display-name from comment'
	);
	is(
		$reflector->{form_display_name},
		$Local::Fixtures::table_comment,
		'Set form-name field from comment'
	);
	
	
	# Test without comments
	
	$options = { 
		form_name => $Local::Fixtures::table_name,
	};
	
	$reflector = Form::Sensible::Reflector::MySQL->new();
	
	$form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);
	
	isa_ok($form, 'Form::Sensible::Form');
	
	# Test field comments as field names
	ok(
		$form->field( 'my_tinyint_s'),
		'Got field by name'
	);
	
	isnt(
		$form->field('my_tinyint_s')->display_name,
		$Local::Fixtures::col_comment,
		'Not set display-name from comment'
	);
	
	is(
		$form->field('my_tinyint_s')->display_name,
		'My tinyint_s',
		'Display-name not from comment'
	);
	
	isnt(
		$reflector->{form_display_name},
		$Local::Fixtures::table_comment,
		'Set form-name field from comment'
	);
	is(
		$reflector->{form_display_name},
		undef,
		'No form-name field from comment'
	);
}

done_testing(12);



