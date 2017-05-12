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

my $bigquery = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file,
  project_id => $project_id,
  dataset_id => $dataset_id,
);

my $response;
my $table_id = 'sample_table_' . time;

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

# create table
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
        { name => "id", type => "INTEGER", mode => "REQUIRED" },
        { name => "name", type => "STRING", mode => "NULLABLE" },
      ]
    },
    description => "This is a sample table."
  }
);

# insertAll
$response = $bigquery->request(
  method => 'insertAll',
  resource => 'tabledata',
  table_id => $table_id,
  content => {
    rows => [
      {
        insertId => 'insert_id_1',
        json => {
          id => 1,
          name => 'name1'
        }
      },
      {
        insertId => 'insert_id_2',
        json => {
          id => 2
        }
      },
      {
        insertId => 'insert_id_3',
        json => {
          id => 3,
          name => 'name3'
        }
      }
    ]
  }
);
ok(!defined $response->{errors}, "insertAll");

print "wait for warm up for about 2 minutes at first\n";
my $warmup = time + 120;
while (time < $warmup) {
  print ".";
  sleep(1);
}
print "DONE!\n";

# list
$response = $bigquery->request(
  method => 'list',
  resource => 'tabledata',
  table_id => $table_id
);
is(scalar @{$response->{rows}}, 3, "list");

# insertAll (2nd)
$response = $bigquery->request(
  method => 'insertAll',
  resource => 'tabledata',
  table_id => $table_id,
  content => {
    rows => [
      {
        insertId => 'insert_id_4',
        json => {
          id => 4,
          name => 'name4'
        }
      },
      {
        insertId => 'insert_id_5',
        json => {
          id => 5
        }
      },
      {
        insertId => 'insert_id_6',
        json => {
          id => 6,
          name => 'name6'
        }
      }
    ]
  }
);
ok(!defined $response->{errors}, "insertAll (2nd)");

print "no wait for warm up\n";

# list
$response = $bigquery->request(
  method => 'list',
  resource => 'tabledata',
  table_id => $table_id
);
is(scalar @{$response->{rows}}, 6, "list");

# drop table
$bigquery->request(method => 'delete', resource => 'tables', table_id => $table_id);

# drop dataset
$bigquery->request(method => 'delete', resource => 'datasets');

done_testing;
