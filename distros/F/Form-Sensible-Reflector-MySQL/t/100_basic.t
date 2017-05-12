use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;

use Test::Most;
die_on_fail;

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
#		information_schema_dbh => DBI->connect(
#			'DBI:mysql:database=information_schema',
#			$Local::Fixtures::test_user, 
#			$Local::Fixtures::test_password,
#		)
};

my $reflector = Form::Sensible::Reflector::MySQL->new();

my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);

isa_ok($form, 'Form::Sensible::Form');

foreach my $f ( $form->get_fields ){
	 is( $f->value, undef, $f->name .' is without value');	
}

$form->add_field(
	Form::Sensible::Field::Toggle->new( 
		name => 'Submit form',
	)
);

done_testing( 46 );

