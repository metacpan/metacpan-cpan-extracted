use 5.012;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';

use Test::More;

use TestData qw($CLIENT_PARAMS1 $CLIENT_PARAMS_1_9 $CLIENT_PARAMS2);
use JQuery::DataTables::Request;

{
  foreach my $client_params ( ($CLIENT_PARAMS_1_9) ) {
    my $req = JQuery::DataTables::Request->new( client_params => $client_params );
    isa_ok( $req, 'JQuery::DataTables::Request' );

    # top level 
    ok($req->start == 0, 'constructor set start properly');
    ok($req->length == 10, 'constructor set length properly');
    ok($req->draw  == 1, 'constructor set draw properly');

    # order
    ok(defined($req->order(0)), 'constructor created order entry');
    ok($req->order(0)->{column} == 0, 'constructor set proper column order column');
    ok($req->order(0)->{dir} eq 'asc', 'constructor set proper column order direction');

    # column
    ok($req->column(0)->{name} eq 'col_name', 'column name accessor works');
    ok($req->column(0)->{data} eq 'col_name', 'column data accessor works');

    # columns
    ok(defined($req->columns->[0]), 'constructor created column entry');
    ok($req->columns->[0]{name} eq 'col_name', 'constructor set column name entry');
    ok($req->columns->[0]{data} eq 'col_name', 'constructor set column data entry');
    ok(!$req->columns->[0]{search}{regex}, 'constructor converted to perl boolean'); 

    # search
    ok(defined($req->search), 'constructor set search entry');
    ok(!$req->search->{regex},  'constructor set search regex entry');
    ok($req->search->{value} eq 'test_search', 'constructor set search value entry');
  }
}

# Make sure order is preserved on our arrays
{
  my $req = JQuery::DataTables::Request->new( client_params => $CLIENT_PARAMS2 );

  # order
  ok( $req->order(0)->{column} ==  0, 'order returns proper order at index 0');
  ok( $req->order(1)->{column} ==  1, 'order returns proper order at index 0');

  #orders
  ok( $req->orders->[0]->{column} ==  0, 'orders returns proper order at index 0');
  ok( $req->orders->[1]->{column} ==  1, 'orders returns proper order at index 0');

  #column
  ok($req->column(0)->{name} eq 'col_name', 'column returns proper column at index 0');
  ok($req->column(1)->{name} eq 'col_name1', 'column returns proper column at index 1');

  #columns
  ok($req->columns->[0]{name} eq 'col_name', 'columns returns proper column at index 0');
  ok($req->columns->[1]{name} eq 'col_name1', 'columns returns proper column at index 1');
}

# croaks?
{
  my $req;
  eval {
    my $non_dt = {
      'draw' => 'camels',
      'reading' => 'rainbow',
      'Geordi' => 'La Forge'
    };
    $req = JQuery::DataTables::Request->new( client_params => $non_dt );
  };
  ok( $@, 'constructor croaked with invalid parameters passed' );
}


done_testing;
