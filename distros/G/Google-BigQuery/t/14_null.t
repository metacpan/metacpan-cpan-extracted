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
my $schema = [
  { name => 'id', type => 'INTEGER', mode => 'REQUIRED' },
  { name => 'name', type => 'STRING', mode => 'REQUIRED' },
];
my $ret;

my $bq = Google::BigQuery::create(
  client_email=>$client_email,
  private_key_file=>$private_key_file,
  project_id=>$project_id,
  dataset_id=>$dataset_id,
);

$bq->create_dataset;
$bq->create_table(table_id=>$table_id,schema=>$schema);

if (1) {
  my $data = "data.tsv";
  open my $out, ">", $data;
  print $out join("\t", 1, 'foo'), "\n";
  print $out join("\t", 2, ''), "\n";
  print $out join("\t", 3, 'baz'), "\n";
  close $out;
  is($bq->load(table_id=>$table_id,data=>$data), 0, 'load: null-string is null');
  unlink $data;
}

done_testing;
