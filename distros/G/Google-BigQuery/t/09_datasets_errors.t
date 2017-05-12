BEGIN {
  unless (defined $ENV{CLIENT_EMAIL} && defined $ENV{PRIVATE_KEY_FILE} && $ENV{PROJECT_ID}) {
    require Test::More;
    Test::More::plan(skip_all => 'This test needs $ENV{CLIENT_EMAIL}, $ENV{PRIVATE_KEY_FILE} and $ENV{PROJECT_ID}.');
  }
}

use strict;
use Test::More 0.98;
use Test::Exception;
use JSON qw(decode_json encode_json);
use Data::Dumper;
use FindBin '$Bin';

use Google::BigQuery;

my $client_email = $ENV{CLIENT_EMAIL};
my $private_key_file = $ENV{PRIVATE_KEY_FILE};
my $project_id = $ENV{PROJECT_ID};
my ${dataset_id} = 'sample_dataset_' . time;
my $table_id = 'sample_table_' . time;
my $ret;

my $bq = Google::BigQuery::create(client_email=>$client_email, private_key_file=>$private_key_file);

# create_dataset
is($bq->create_dataset(), 0, 'create_dataset: no project');
is($bq->create_dataset(project_id=>$project_id), 0, 'create_dataset: no dataset');
is($bq->create_dataset(project_id=>"${project_id}x",dataset_id=>$dataset_id), 0, 'create_dataset: not found project');
is($bq->create_dataset(project_id=>"${project_id}", dataset_id=>"${dataset_id}"), 1, 'create_datset: ok');
is($bq->create_dataset(project_id=>"${project_id}", dataset_id=>"${dataset_id}"), 0, 'create_dataset: already exists dataset');

# drop_dataset
is($bq->drop_dataset(), 0, 'create_dataset: no project');
is($bq->create_dataset(project_id=>$project_id), 0, 'create_dataset: no dataset');
is($bq->drop_dataset(project_id=>"${project_id}x", dataset_id=>"${dataset_id}"), 0, 'drop_dataset: not found project');
is($bq->drop_dataset(project_id=>"${project_id}", dataset_id=>"${dataset_id}x"), 0, 'drop_dataset: not found dataset');
is($bq->drop_dataset(project_id=>"${project_id}", dataset_id=>"${dataset_id}"), 1, 'drop_dataset: ok');

# show_datasets
is($bq->create_dataset(project_id=>"${project_id}",dataset_id=>"${dataset_id}"),1,'create_datset: ok');
is($bq->show_datasets(),undef,'show_datasets: no project');
is($bq->show_datasets(project_id=>"${project_id}x"),undef,'show_datasets: not found project');

done_testing;
