#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Form::Processor::Model::DBIC' );
}

diag( "Testing Form::Processor::Model::DBIC $Form::Processor::Model::DBIC::VERSION, Perl $], $^X" );
