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
  project_id => $project_id
);

my $response;

# insert
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
is($response->{datasetReference}{datasetId}, $dataset_id, "insert");

# list
$response = $bigquery->request(
  method => 'list',
  resource => 'datasets',
);
ok(@{$response->{datasets}}, "list");

# get
$response = $bigquery->request(
  method => 'get',
  resource => 'datasets',
  dataset_id => $dataset_id
);
is($response->{datasetReference}{datasetId}, $dataset_id, "get");

# patch
$response = $bigquery->request(
  method => 'patch',
  resource => 'datasets',
  dataset_id => $dataset_id,
  content => {
    datasetReference => {
      projectId => $project_id,
      datasetId => $dataset_id
    }
  }
);
is($response->{description}, 'This is a sample dataset.', "patche: fields that are not specified are not replaced");

# update
$response = $bigquery->request(
  method => 'update',
  resource => 'datasets',
  dataset_id => $dataset_id,
  content => {
    datasetReference => {
      projectId => $project_id,
      datasetId => $dataset_id
    },
  }
);
is($response->{description}, undef, "update: fields that are not spcified are also replaced");

# delete
$response = $bigquery->request(
  method => 'delete',
  resource => 'datasets',
  dataset_id => $dataset_id,
);
ok(!%$response, "delete");

done_testing;
