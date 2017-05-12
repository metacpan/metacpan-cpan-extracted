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

# insert from tsv
my $load_file = "load_file.tsv";
open my $out, '>', $load_file or die;
for (my $i = 1; $i <= 100; $i++) {
  my $name = $i % 10 == 0 ? undef : "name$i";
  print $out join("\t", $i, $name), "\n";
}
close $out;

$response = $bigquery->request(
  method => 'insert',
  resource => 'jobs',
  table_id => $table_id,
  content => {
    configuration => {
      load => {
        destinationTable => {
          projectId => $ENV{PROJECT_ID},
          datasetId => $dataset_id,
          tableId => $table_id,
        },
        sourceFormat => 'CSV',
        fieldDelimiter => "\t",
      },
    },
  },
  data => $load_file
);
is($response->{status}{state}, 'DONE', 'insert');
unlink $load_file;

# select count
$response = $bigquery->request(
  method => 'query',
  resource => 'jobs',
  content => {
    query => "SELECT COUNT(*) FROM $table_id",
    defaultDataset => {
      datasetId => $dataset_id,
      projectId => $project_id
    }
  },
);
#print Dumper $response;
is($response->{rows}[0]{f}[0]{v}, 100, "query: select count(*) from $table_id");

# select rows
$response = $bigquery->request(
  method => 'query',
  resource => 'jobs',
  content => {
    query => "SELECT * FROM $table_id",
    defaultDataset => {
      projectId => $project_id,
      datasetId => $dataset_id
    }
  }
);
#print Dumper $response;
is($response->{rows}[0]{f}[0]{v}, 1, "query: select * from $table_id: rows[0]{id}");
is($response->{rows}[0]{f}[1]{v}, "name1", "query: select * from $table_id: rows[0]{name}"); 
is($response->{rows}[99]{f}[0]{v}, 100, "query: select * from $table_id: rows[99]{id}");
is($response->{rows}[99]{f}[1]{v}, undef, "query: select * from $table_id: rows[99]{name}");

# list
$response = $bigquery->request(
  method => 'list',
  resource => 'jobs',
  project_id => $project_id,
  query_string => {
    projection => 'full',
    stateFilter => 'done',
  }
);
ok(@{$response->{jobs}}, "list");

# getQueryResults
my $job_id = $response->{jobs}[0]{jobReference}{jobId};
$response = $bigquery->request(
  method => 'getQueryResults',
  resource => 'jobs',
  job_id => $job_id
);
is($response->{rows}[0]{f}[0]{v}, 1, "getQueryResults: select * from $table_id: rows[0]{id}");
is($response->{rows}[0]{f}[1]{v}, "name1", "getQueryResults: select * from $table_id: rows[0]{name}"); 
is($response->{rows}[99]{f}[0]{v}, 100, "getQueryResults: select * from $table_id: rows[99]{id}");
is($response->{rows}[99]{f}[1]{v}, undef, "getQueryResults: select * from $table_id: rows[99]{name}");

# drop table
$bigquery->request(method => 'delete', resource => 'tables', table_id => $table_id);

# drop dataset
$bigquery->request(method => 'delete', resource => 'datasets');

done_testing;
