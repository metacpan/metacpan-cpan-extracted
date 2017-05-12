package # hide from pause
  TestData;

use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw($CLIENT_PARAMS1 $CLIENT_PARAMS2 $CLIENT_PARAMS_1_9);

our $CLIENT_PARAMS1 = {
  'draw' => 1,
  'start' => 0,
  'length' => 10,
  'search[value]' => 'test_search',
  'search[regex]' => 'false',
  'order[0][column]' => 0,
  'order[0][dir]' => 'asc',
  'columns[0][name]' => 'col_name',
  'columns[0][data]' => 'col_name',
  'columns[0][orderable]' => 'true',
  'columns[0][searchable]' => 'true',
  'columns[0][search][value]' => '',
  'columns[0][search][regex]' => 'false',
};

# This should correspond with the CLIENT_PARAMS1
# data to make tests work
our $CLIENT_PARAMS_1_9 = {
  'sEcho' => 1,
  'iDisplayStart' => 0,
  'iDisplayLength' => 10,
  'sSearch' => 'test_search',
  'bRegex' => 'false', 
  'iColumns' => 1,
  'iSortingCols' => 1,
  'iSortCol_0' => 0,
  'sSortDir_0' => 'asc',
  'mDataProp_0' => 'col_name',
  'bSearchable_0' => 'true',
  'bSortable_0' => 'true',
  'sSearch_0' => '',
  'bRegex_0' => 'false',
};

our $CLIENT_PARAMS2 = {
  'draw' => 2,
  'start' => 1,
  'length' => 20,
  'search[value]' => 'test_search2',
  'search[regex]' => 'true',
  'order[1][column]' => 1,
  'order[1][dir]' => 'desc',
  'order[0][column]' => 0,
  'order[0][dir]' => 'asc',
  'columns[1][name]' => 'col_name1',
  'columns[1][data]' => 'col_data1',
  'columns[1][orderable]' => 'false',
  'columns[1][searchable]' => 'false',
  'columns[1][search][value]' => 'test value',
  'columns[1][search][regex]' => 'true',
  'columns[0][name]' => 'col_name',
  'columns[0][data]' => 'col_data',
  'columns[0][orderable]' => 'true',
  'columns[0][searchable]' => 'true',
  'columns[0][search][value]' => '',
  'columns[0][search][regex]' => 'false',
};


1;
