BEGIN {
  unless (defined $ENV{CLIENT_EMAIL} && defined $ENV{PRIVATE_KEY_FILE} && $ENV{PROJECT_ID} && $ENV{GS_BUCKET}) {
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
my $schema = [
  { name => 'id', type => 'INTEGER', mode => 'REQUIRED' },
  { name => 'name', type => 'STRING', mode => 'REQUIRED' },
  { name => 'address', type => 'STRING', mode => 'NULLABLE' },
  { name => 'phone', type => 'INTEGER', mode => 'NULLABLE' },
];
my $bucket = $ENV{GS_BUCKET};
my $ret;

my $bq = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file,
  project_id => $project_id,
  dataset_id => $dataset_id,
);
$bq->create_dataset;
$bq->create_table(table_id=>$table_id,schema=>$schema);
$bq->load(
  table_id=>$table_id,
  data=>[("gs://$bucket/data-100000.json.gz", "gs://$bucket/data-10000.json.gz")],
);
my ($count) = $bq->selectrow_array(query => "SELECT COUNT(*) FROM $table_id");
is($count,110000,"load: gs");

done_testing;
