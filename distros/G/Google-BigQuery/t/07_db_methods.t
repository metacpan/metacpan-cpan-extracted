BEGIN {
  unless (defined $ENV{CLIENT_EMAIL} && defined $ENV{PRIVATE_KEY_FILE} && $ENV{PROJECT_ID}) {
    require Test::More;
    Test::More::plan(skip_all => 'This test needs $ENV{CLIENT_EMAIL}, $ENV{PRIVATE_KEY_FILE} and $ENV{PROJECT_ID}.');
  }
}

use strict;
use Test::More 0.98;
use FindBin '$Bin';
use JSON qw(decode_json encode_json);
use Data::Dumper;

use Google::BigQuery;

my $client_email = $ENV{CLIENT_EMAIL};
my $private_key_file = $ENV{PRIVATE_KEY_FILE};
my $project_id = $ENV{PROJECT_ID};
my $dataset_id = 'sample_dataset_' . time;
my $table_id = 'sample_table_' . time;
my $ret;

my $bigquery = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file
);

# set default project
$bigquery->use_project($project_id);
is($bigquery->{project_id}, $project_id, "use_project");

# set default dataset
$bigquery->use_dataset($dataset_id);
is($bigquery->{dataset_id}, $dataset_id, "use_dataset");

# create dataset
$ret = $bigquery->create_dataset();
is($ret, 1, "create_dataset");

# is_exists_dataset
$ret = $bigquery->is_exists_dataset(dataset_id => $dataset_id);
is($ret, 1, "is_exists_dataset (exists)");

# create table
$bigquery->create_table(
  table_id => $table_id,
  schema => [
    { name => "id", type => "INTEGER", mode => "REQUIRED" },
    { name => "name", type => "STRING", mode => "NULLABLE" }
  ]
);
is($ret, 1, "create_table");

# is_exists_table
$ret = $bigquery->is_exists_table(table_id => $table_id);
is($ret, 1, "is_exists_table (exists)");

# insert
$ret = $bigquery->insert(
  table_id => $table_id,
  values => [
    { id => 101, name => 'name101' },
    { id => 102 },
    { id => 103, name => 'name103' }
  ]
);
is($ret, 1, "insert");

# load
my $load_file;
my @types = qw(csv tsv json);
for (my $i = 0; $i < @types; $i++) {
  $load_file = "load_file." . $types[$i];

  open my $out, ">", $load_file;
  for (my $j = 0; $j < 10; $j++) {
    my $id = ($i * 10) + $j;
    if ($types[$i] =~ /csv/i) {
      print $out join(",", $id, "name${id}"), "\n"; 
    } elsif ($types[$i] =~ /tsv/i) {
      print $out join("\t", $id, "name${id}"), "\n"; 
    } else {
      print $out encode_json({ id => $id, name => "name${id}" }), "\n";
    }
  }
  close $out;

  $ret = $bigquery->load(
    table_id => $table_id,
    data => $load_file
  );
  is($ret, 1, "load ($load_file)");
}

# load gzip
`gzip $load_file`;
$load_file .= ".gz";

$ret = $bigquery->load(
  table_id => $table_id,
  data => $load_file
);
is($ret, 1, "load ($load_file)");

unlink $load_file;

# selectrow_array
my ($count) = $bigquery->selectrow_array(query => "SELECT COUNT(*) FROM $table_id");
is($count, 43, "SELECT COUNT(*) FROM $table_id");

# selectall_arrayref
my $aref = $bigquery->selectall_arrayref(query => "SELECT * FROM $table_id");
is(scalar @{$aref}, 43, "SELECT * FROM $table_id (number of rows)");
is(scalar @{$aref->[0]}, 2, "SELECT * FROM $table_id (number of fields)");

# drop table
$ret = $bigquery->drop_table(table_id => $table_id);
is($ret, 1, "drop table");

# is_exists_table
$ret = $bigquery->is_exists_table(table_id => $table_id);
is($ret, 0, "is_exists_table (no exists)");

# drop dataset
$ret = $bigquery->drop_dataset(dataset_id => $dataset_id);
is($ret, 1, "drop dataset");

# is_exists_dataset
$ret = $bigquery->is_exists_dataset(dataset_id => $dataset_id);
is($ret, 0, "is_exists_dataset (no exists)");

done_testing;
