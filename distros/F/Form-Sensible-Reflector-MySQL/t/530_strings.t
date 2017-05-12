use strict;
use warnings;
use utf8;
use lib qw( ../lib lib ../t/lib t/lib);

# Test date times
package test;

use Test::Most ;

BEGIN {
	use Local::Fixtures;
	use Local::Tests;
}

if ( not $Local::Fixtures::dbh ){
	plan skip_all => 'No DBH - please set ENV{DBI_USER} and ENV{DBI_PASS}'; 
}

use Form::Sensible;
use Form::Sensible::Reflector::MySQL;

my $reflector = Form::Sensible::Reflector::MySQL->new();

# Do both text and blob columns:
our %col2len = (
	my_char => 23,
	my_varchar => 23,
	my_tinytext => 255,
	my_text => 65535,
	my_mediumtext => 16777215,
# TOO SLOW	my_longtext => 4294967295,
);


while (my ($colbase, $max) = each %col2len){

	for my $i (1..2){
	
		my $col = $colbase;
		if ($i == 2){
			$col =~ s/char/binary/;
			$col =~ s/text/blob/;
		}
		
		my $options = { 
			form_name => $Local::Fixtures::table_name,
			no_db_defaults => 1,
			only_columns => [$col],
		};
		my $form  = $reflector->reflect_from($Local::Fixtures::dbh, $options);
		isa_ok($form, 'Form::Sensible::Form');
		
		$form->field($col)->value( 'x' x $max );
		is(
			scalar (keys %{$form->validate->error_fields } ),
			0,
			"No error in $max length $col"
		) or explain $form->validate->error_fields;
			
		$form->field($col)->value( 'x' x ($max + 1) );
		like(
			$form->validate->error_fields->{$col}->[0],
			qr/(no more|long)/,
			'too long in '.$col
		);
	}
}

done_testing(30);


