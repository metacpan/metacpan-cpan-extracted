use 5.012;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';

use Test::More;
use TestData qw($CLIENT_PARAMS1);
use JQuery::DataTables::Request;

my $req = JQuery::DataTables::Request->new( client_params => $CLIENT_PARAMS1 );
isa_ok( $req, 'JQuery::DataTables::Request' );

ok( $req->find_columns( by_name => 'col_name' ), 'find_columns by_name works' );
ok( $req->find_columns( by_name => 'col_name', 'name_field' => 'data' ), 'find_columns name_field works' );
ok( $req->find_columns( by_idx => 0 ), 'find_columns by_idx works' );
ok( $req->column(0), 'column method index lookup works' );
ok( $req->column(0)->{orderable}, 'column method index lookup works 2' );
ok( @{ $req->columns([0,1]) } == 2, 'columns index by arrayref works' );
ok( !defined ($req->columns([0,1])->[1]), 'non-existent column requested returns undef' );

ok( $req->columns_hashref->{0}->{name} eq 'col_name', 'columns_hashref returns hashref' );

done_testing;
