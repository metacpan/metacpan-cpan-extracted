use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

# Tests the obtaining of default values from schema

package test;
use Local::Fixtures;
use Local::Tests;

use Test::Most;
die_on_fail;

if ( not $Local::Fixtures::dbh ){
	plan skip_all => 'No DBH - please set ENV{DBI_USER} and ENV{DBI_PASS}'; 
} 
	

use Form::Sensible;
use Form::Sensible::Reflector::MySQL;

isa_ok(
	$Local::Fixtures::dbh,
	'DBI::db'
) or BAIL_OUT 'No db connection';

my $reflector = Form::Sensible::Reflector::MySQL->new();

my $form  = $reflector->reflect_from( $Local::Fixtures::dbh, {
	use_db_defaults => 1,
	form_name => $Local::Fixtures::table_name,
});

isa_ok($form, 'Form::Sensible::Form');

is(
	$form->field('my_default_text')->value,
	$Local::Fixtures::default_text,
	'default text in empty record'
);

foreach my $f ( $form->get_fields ){
	next if $f->name eq 'my_default_text';
	is( $f->value, undef, $f->name .' is without value');	
}


$form  = $reflector->reflect_from( $Local::Fixtures::dbh, {
	no_db_defaults =>1,
	form_name => $Local::Fixtures::table_name,
});

isa_ok($form, 'Form::Sensible::Form');

isnt(
	$form->field('my_default_text')->value,
	$Local::Fixtures::default_text,
	'not default text in empty record'
);

done_testing( 49 );
