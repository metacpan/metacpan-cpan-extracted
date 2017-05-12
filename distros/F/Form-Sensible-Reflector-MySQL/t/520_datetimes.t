use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

# Test date times
package test;

use Test::Most ;
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
};

my $reflector = Form::Sensible::Reflector::MySQL->new();
my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);

isa_ok($form, 'Form::Sensible::Form');

$form->field('my_datetime')->value( '2010-11-12 13:14:15' );
is(  $form->validate->error_fields->{'my_datetime'}->[0], undef, '4-digit year good datetime'); 

$form->field('my_datetime')->value( '10-11-12 12:34:56' );
isnt(  $form->validate->error_fields->{'my_datetime'}->[0], undef, '2-digit year bad datetime'); 
like( $form->validate->error_fields->{'my_datetime'}->[0], qr'four-digit', 'custom error message');

$form->field('my_datetime')->value( '2010-11-12 99:99:99' );
isnt(  $form->validate->error_fields->{'my_datetime'}->[0], undef, 'bad datetime'); 

$form->field('my_datetime')->value( '2010-11-12 2:34:56' );
isnt(  $form->validate->error_fields->{'my_datetime'}->[0], undef, 'bad datetime'); 




$form->field('my_timestamp')->value( '2010-11-12 13:14:15' );
is(  $form->validate->error_fields->{'my_timestamp'}->[0], undef, '4-digit year good timestamp'); 

$form->field('my_timestamp')->value( '10-11-12 12:34:56' );
isnt(  $form->validate->error_fields->{'my_timestamp'}->[0], undef, '2-digit year bad timestamp'); 
like( $form->validate->error_fields->{'my_timestamp'}->[0], qr'four-digit', 'custom error message');

$form->field('my_timestamp')->value( '2010-11-12 99:99:99' );
isnt(  $form->validate->error_fields->{'my_timestamp'}->[0], undef, 'bad timestamp'); 

$form->field('my_timestamp')->value( '2010-11-12 2:34:56' );
isnt(  $form->validate->error_fields->{'my_timestamp'}->[0], undef, 'bad timestamp'); 





foreach my $d (qw( . ' " + : ; / * _ -), ','){
	$form->field('my_date')->value( '2010-11-12' );
	is(  $form->validate->error_fields->{'my_date'}->[0], undef, '4-digit year good date, delimited by '.$d); 
}

$form->field('my_date')->value( '10-11-12' );
isnt(  $form->validate->error_fields->{'my_date'}->[0], undef, '2-digit year bad date'); 
like( $form->validate->error_fields->{'my_date'}->[0], qr'four-digit', 'custom error message');

$form->field('my_date')->value( '1010-11-12' );
is(  $form->validate->error_fields->{'my_date'}->[0], undef, 'bad date'); 

$form->field('my_date')->value( '2010£11£12' );
isnt(  $form->validate->error_fields->{'my_date'}->[0], undef, 'bad delimiter £'); 

$form->field('my_date')->value( '1000-01-01' );
isnt(  $form->validate->error_fields->{'my_date'}->[0], undef, 'date too low'); 
like(  $form->validate->error_fields->{'my_date'}->[0], qr'must have a year from', 'date too low custom err msg'); 



$form->field('my_time')->value( '13:14:15' );
is(  $form->validate->error_fields->{'my_time'}->[0], undef, '4-digit year good time'); 

$form->field('my_time')->value( '99:01:01' );
isnt(  $form->validate->error_fields->{'my_time'}->[0], undef, 'bad hours'); 
like(  $form->validate->error_fields->{'my_time'}->[0], qr'Hour', 'bad hours msg'); 

$form->field('my_time')->value( '01:60:01' );
isnt(  $form->validate->error_fields->{'my_time'}->[0], undef, 'bad minutes'); 
like(  $form->validate->error_fields->{'my_time'}->[0], qr'Minute', 'bad min msg'); 

$form->field('my_time')->value( '01:01:60' );
isnt(  $form->validate->error_fields->{'my_time'}->[0], undef, 'bad seconds'); 
like(  $form->validate->error_fields->{'my_time'}->[0], qr'Second', 'bad seconds msg'); 

$form->field('my_time')->value( '00:00:00' );
is(  $form->validate->error_fields->{'my_time'}->[0], undef, 'ok zero time'); 

$form->field('my_time')->value( '2:34:56' );
isnt(  $form->validate->error_fields->{'my_time'}->[0], undef, 'bad time'); 



for my $i (1901, 2155){
	$form->field('my_year')->value( $i );
	is(  $form->validate->error_fields->{'my_year'}->[0], undef, 'good default-digit year '.$i); 
}

for my $i (1900, 2156){
	$form->field('my_year')->value( $i );
	like( $form->validate->error_fields->{'my_year'}->[0], qr'between', 'bad default-digit year '.$i.' custom error message');
}


for my $i (1901, 2155){
	$form->field('my_year4')->value( $i );
	is(  $form->validate->error_fields->{'my_year4'}->[0], undef, 'good default-digit year '.$i); 
}

for my $i (1900, 2156){
	$form->field('my_year4')->value( $i );
	like( $form->validate->error_fields->{'my_year4'}->[0], qr'between', 'bad default-digit year '.$i.' custom error message');
}


for my $i ( '00', 99){
	$form->field('my_year2')->value( $i );
	is(  $form->validate->error_fields->{'my_year2'}->[0], undef, 'good default-digit year '.$i); 
}

for my $i (0, -1, 100, 1900, 2156){
	$form->field('my_year2')->value( $i );
	like( $form->validate->error_fields->{'my_year2'}->[0], qr'between', 'bad default-digit year '.$i.' custom error message');
}

done_testing(52);

