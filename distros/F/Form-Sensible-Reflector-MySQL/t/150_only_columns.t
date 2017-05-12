use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

package test;
# 150_only_columns.t - test the 'only_columns' option

use Test::Most;
die_on_fail;

use Local::Fixtures;
use Local::Tests;


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
isa_ok($form, 'Form::Sensible::Form');


my @all_fields = map {$_->name} $form->get_fields;

$form  = $reflector->reflect_from(
	$Local::Fixtures::dbh, 
	{
		%$options,
		only_columns => [
			@all_fields[0..2]
		],
	}
);
isa_ok($form, 'Form::Sensible::Form');

my @three_fields = $form->get_fields;
isnt(scalar(@three_fields), scalar(@all_fields), 'limited fields');


$form  = $reflector->reflect_from(
	$Local::Fixtures::dbh, 
	{
		%$options,
		populate => {
			my_tinyint_s => -128,
		},
		only_columns => [
			@all_fields[0..2]
		],
	}
);
isa_ok($form, 'Form::Sensible::Form');

@three_fields = $form->get_fields;
isnt(scalar(@three_fields), scalar(@all_fields), 'limited fields');

done_testing(5);


