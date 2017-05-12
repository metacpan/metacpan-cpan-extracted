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

isa_ok(
	$Local::Fixtures::dbh,
	'DBI::db'
) or BAIL_OUT 'No db connection';


my $options = {
	populate => { 
		my_tinyint_u => 255, 
		my_set => 'two,three',
	},
	form_name => $Local::Fixtures::table_name,
#	information_schema_dbh => DBI->connect(
#		'DBI:mysql:database=information_schema;host=localhost',
#		'root', 
#		'password',
#	)
};

my $reflector = Form::Sensible::Reflector::MySQL->new();
my $form = $reflector->reflect_from($Local::Fixtures::dbh, $options);
isa_ok($form, 'Form::Sensible::Form');

&Local::Tests::positive_form_tests($form);

$reflector = Form::Sensible::Reflector::MySQL->new();
$options->{populate} = { my_tinyint_s => -128 };
$form = $reflector->reflect_from($Local::Fixtures::dbh, $options);
isa_ok($form, 'Form::Sensible::Form');

&Local::Tests::positive_form_tests($form);


done_testing( 185 );

