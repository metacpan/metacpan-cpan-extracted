BEGIN {
  unless (defined $ENV{CLIENT_EMAIL} && defined $ENV{PRIVATE_KEY_FILE} && $ENV{PROJECT_ID}) {
    require Test::More;
    Test::More::plan(skip_all => 'This test needs $ENV{CLIENT_EMAIL}, $ENV{PRIVATE_KEY_FILE} and $ENV{PROJECT_ID}.');
  }
}

use strict;
use Test::More 0.98;
use FindBin '$Bin';
use JSON qw(decode_json);
use Data::Dumper;

use Google::BigQuery;

my $client_email = $ENV{CLIENT_EMAIL};
my $private_key_file = $ENV{PRIVATE_KEY_FILE};
my $project_id = $ENV{PROJECT_ID};
my $dataset_id = 'sample_dataset_' . time;
my $table_id = 'sample_table_' . time;

my $bigquery = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file,
  project_id => $project_id,
  dataset_id => $dataset_id
);

my $response;

# create dataset
$response = $bigquery->request(
  method => 'insert',
  resource => 'datasets',
  dataset_id => $dataset_id,
  content => {
    datasetReference => {
      projectId => $project_id,
      datasetId => $dataset_id
    },
    description => 'This is a sample dataset.'
  }
);

# insert
$response = $bigquery->request(
  method => 'insert',
  resource => 'tables',
  table_id => $table_id,
  content => {
    tableReference => {
      projectId => $project_id,
      datasetId => $dataset_id,
      tableId => $table_id
    },
    schema => {
      fields => [
        { name => "column1", type => "STRING", mode => "REQUIRED" },
        { name => "column2", type => "INTEGER", mode => "NULLABLE" },
        { name => "column3", type => "RECORD", mode => "REPEATED", fields => [
          { name => "column3_1", type => "STRING", mode => "REQUIRED" },
          { name => "column3_2", type => "INTEGER", mode => "NULLABLE" }
        ]}
      ]
    },
    description => "This is a sample table."
  }
);
is(scalar @{$response->{schema}{fields}}, 3, "insert: number of parent fileds");

# list
$response = $bigquery->request(
  method => 'list',
  resource => 'tables',
);
ok(@{$response->{tables}}, "list");

# get
$response = $bigquery->request(
  method => 'get',
  resource => 'tables',
  table_id => $table_id,
);
is($response->{tableReference}{tableId}, $table_id, "get");

# patch
$response = $bigquery->request(
  method => 'patch',
  resource => 'tables',
  table_id => $table_id,
  content => {
    tableReference => {
      projectId => $project_id,
      datasetId => $dataset_id,
      tableId => $table_id
    },
    schema => {
      fields => [
        { name => "column1", type => "STRING", mode => "REQUIRED" },
        { name => "column2", type => "INTEGER", mode => "NULLABLE" },
        { name => "column3", type => "RECORD", mode => "REPEATED", fields => [
          { name => "column3_1", type => "STRING", mode => "REQUIRED" },
          { name => "column3_2", type => "INTEGER", mode => "NULLABLE" }
        ]},
        { name => "column4", type => "FLOAT", mode => "REPEATED" },
      ]
    },
  }
);
is(scalar @{$response->{schema}{fields}}, 4, "patch");
is($response->{description}, "This is a sample table.", "patch: fields that are not specified are not replaced");

# update
$response = $bigquery->request(
  method => 'update',
  resource => 'tables',
  table_id => $table_id,
  content => {
    tableReference => {
      projectId => $project_id,
      datasetId => $dataset_id,
      tableId => $table_id
    },
    schema => {
      fields => [
        { name => "column1", type => "STRING", mode => "REQUIRED" },
        { name => "column2", type => "INTEGER", mode => "NULLABLE" },
        { name => "column3", type => "RECORD", mode => "REPEATED", fields => [
          { name => "column3_1", type => "STRING", mode => "REQUIRED" },
          { name => "column3_2", type => "INTEGER", mode => "NULLABLE" }
        ]},
        { name => "column4", type => "FLOAT", mode => "REPEATED" },
        { name => "column5", type => "STRING", mode => "NULLABLE" },
      ]
    },
  }
);
is(scalar @{$response->{schema}{fields}}, 5, "update: number of parent fileds");
is($response->{description}, undef, "update: fields that are not spcified are also replaced");

# drop table
$response = $bigquery->request(
  method => 'delete',
  resource => 'tables',
  table_id => $table_id,
);
ok(!%$response, "delete");

# drop dataset
$bigquery->request(method => 'delete', resource => 'datasets');

done_testing;
