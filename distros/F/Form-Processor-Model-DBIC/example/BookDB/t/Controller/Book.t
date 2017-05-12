
use Test::More tests => 3;
use_ok( Catalyst::Test, 'BookDB' );
use_ok('BookDB::Controller::Book');

ok( request('book')->is_success );

