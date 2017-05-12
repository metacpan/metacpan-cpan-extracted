#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'EnsEMBL::Web::Record' );
	use_ok( 'EnsEMBL::Web::Record::User' );
	use_ok( 'EnsEMBL::Web::Record::Group' );
}

diag( "Testing EnsEMBL::Web::Record $EnsEMBL::Web::Record::VERSION, Perl $], $^X" );
diag( "Testing EnsEMBL::Web::Record::User $EnsEMBL::Web::Record::User::VERSION, Perl $], $^X" );
diag( "Testing EnsEMBL::Web::Record::Group $EnsEMBL::Web::Record::Group::VERSION, Perl $], $^X" );
