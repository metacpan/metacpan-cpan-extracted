
use Test::More tests => 3;
use_ok( Catalyst::Test, 'BookDB' );
use_ok('BookDB::Controller::Borrower');

ok( request('borrower')->is_success );

