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
  { name => 'address', type => 'STRING', mode => 'NULLABLE' },
  { name => 'skills', type => 'STRING', mode => 'REPEATED' },
  { name => 'jobs', type => 'RECORD', mode => 'REPEATED', fields => [
    { name => 'year', type => 'INTEGER', mode => 'REQUIRED' },
    { name => 'company', type => 'STRING', mode => 'REQUIRED' },
    { name => 'role', type => 'STRING', mode => 'NULLABLE' },
  ]}
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

# no requried field error
if (1) {
  my $data = "data.json";
  open my $out, ">", $data;
  print $out encode_json({id=>1, name=>'foo'}), "\n";
  print $out encode_json({id=>2}), "\n";
  print $out encode_json({id=>3, name=>'bar'}), "\n";
  close $out;
  is($bq->load(table_id=>$table_id,data=>$data),0,'load: no required field');
  unlink $data;
}

# invalid type
if (1) {
  my $data = "data.json";
  open my $out, ">", $data;
  print $out encode_json({id=>'foo',name=>'bar'}), "\n";
  close $out;
  is($bq->load(table_id=>$table_id,data=>$data),0,'load: invalid type');
  unlink $data;
}

# no suche field
if (1) {
  my $jobs = [
    { year => 2012, company => 'Facebook' },
    { year => 2013, company => 'Twitter', role => 'developer' },
    { year => 2014, company => 'Google', xxx => 'yyy' },
  ];

  my $data = "data.json";
  open my $out, ">", $data;
  print $out encode_json({id=>1, name=>'foo', skills=>['perl'], jobs=>$jobs}), "\n";
  close $out;
  is($bq->load(table_id=>$table_id,data=>$data),0,'load: no such field');
  unlink $data;
}

done_testing;
