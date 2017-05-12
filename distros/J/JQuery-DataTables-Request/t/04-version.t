use 5.012;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';

use Test::More;
use TestData qw($CLIENT_PARAMS1 $CLIENT_PARAMS_1_9);
use JQuery::DataTables::Request;

# 1.10
{ 
  my $req = JQuery::DataTables::Request->new( client_params => $CLIENT_PARAMS1 );
  ok( $req->version eq '1.10', 'version on 1.10 parameters returns 1.10' );
}

# 1.9
{ 
  my $req = JQuery::DataTables::Request->new( client_params => $CLIENT_PARAMS_1_9 );
  ok( $req->version eq '1.9', 'version on 1.9 parameters returns 1.9' );
}

# Test Class method call
ok( JQuery::DataTables::Request->version( $CLIENT_PARAMS1 ) == '1.10', 'Class method call works for 1.10' );
ok( JQuery::DataTables::Request->version( $CLIENT_PARAMS_1_9 ) == '1.9', 'Class method call works for 1.9' );
ok( ! JQuery::DataTables::Request->version( { something => 'else' } ), 'Class method returns undef for invalid client_params' );
ok( ! JQuery::DataTables::Request->version( {} ), 'Class method returns undef for empty client_params sent' );
ok( ! JQuery::DataTables::Request->version(), 'Class method returns undef for no client_params sent' );

done_testing;

