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
  { name => 'phone', type => 'INTEGER', mode => 'NULLABLE' },
];
my $ret;

my $bq = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file,
  project_id => $project_id,
  dataset_id => $dataset_id,
  scope => [qw(https://www.googleapis.com/auth/bigquery https://www.googleapis.com/auth/devstorage.full_control)],
  version => 'v2',
);
isnt($bq, undef, 'create');

# create_dataset
if (1) {
  my $access = [];
  my $description = 'This is a sample dataset.';
  my $friendlyName = 'This is a sample friendlyName of sample dataset.';

  $bq->create_dataset(
    project_id => $project_id,
    dataset_id => $dataset_id,
    access => $access,
    description => $description,
    friendlyName => $friendlyName,
  );

  my $res = $bq->desc_dataset(
    project_id => $project_id,
    dataset_id => $dataset_id,
  );
  is($res->{description}, $description, 'create_dataset: description');
  is($res->{friendlyName}, $friendlyName, 'create_dataset: friendlyName');
}

# show_datasets
if (0) {
  my $all = 1;
  my $maxResults = 1;
  my $pageToken = undef;

  my @datasets = $bq->show_datasets(
    project_id => $project_id,
    dataset_id => $dataset_id,
    all => $all,
    maxResults => $maxResults,
    pageToken => $pageToken,
  );
  is(scalar @datasets, 1, 'show_datasets: 1st');
  #print join("\n", @datasets), "\n";

  @datasets = $bq->show_datasets(
    project_id => $project_id,
    dataset_id => $dataset_id,
    all => $all,
    maxResults => $maxResults + 1,
    pageToken => $bq->{response}{nextPageToken},
  );
  is(scalar @datasets, 2, 'show_datasets: 2nd');
  #print join("\n", @datasets), "\n";
}

# create table
if (0) {
  my $description = 'This is a sample table.';
  my $expirationTime = (time + 86400) * 1000;
  my $friendlyName = 'This is a friendlyName of a sample table.';
  $bq->create_table(
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
    schema => $schema,
    description => $description,
    expirationTime => $expirationTime,
    friendlyName => $friendlyName,
  );

  my $res = $bq->desc_table(
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
  );
  is($res->{description}, $description, 'create_table: description');
  is($res->{expirationTime}, $expirationTime, 'create_table: expirationTime');
  is($res->{friendlyName}, $friendlyName, 'create_table: friendlyName');
}

# show_tables
if (0) {
  my $maxResults = 1;

  my @tables = $bq->show_tables(
    project_id => $project_id,
    dataset_id => $dataset_id,
    maxResults => $maxResults,
  );
  is(scalar @tables, 1, 'show_tables: 1st');

  my @tables = $bq->show_tables(
    project_id => $project_id,
    dataset_id => $dataset_id,
    maxResults => $maxResults,
    pageToken => $bq->{response}{nextPageToken},
  );
  is(scalar @tables, 0, 'show_tables: 2nd');
}

# load
if (1) {
  my $data = "data";
  open my $out, ">", $data or die;
  print $out join("\t", qw(ID NAME ADDRESS PHONE)), "\n";
  print $out join("\t", 1, 'foo', "TOKYO"), "\n";
  print $out join("\t", 2, 'bar', '', 1234567890), "\n";
  print $out join("\t", 3, 'baz'), "\n";
  close $out;

  my $allowJaggedRows = 1;
  my $allowQuoatedNewLines = 1;

  $bq->load(
    project_id => $project_id,
    dataset_id => $dataset_id,
    table_id => $table_id,
    data => $data,
    schema => $schema,
    allowJaggedRows => 1,
    allowQuoatedNewLines => 1,
    encoding => 'UTF-8',
    fieldDelimiter => "\t",
    createDisposition => 'CREATE_IF_NEEDED',
    ignoreUnknownValues => 1,
    maxBadRecords => 1,
    skipLeadingRows => 1,
    sourceFormat => 'CSV',
    writeDisposition => 'WRITE_EMPTY',
  ) || die;
}

# selectall_arrayref
if (1) {
  my $aref = $bq->selectall_arrayref(
    project_id => $project_id,
    dataset_id => $dataset_id,
    query => "SELECT * FROM $table_id",
    maxResults => 1,
    timeoutMs => 1,
    dryRun => 1,
    useQueryCache => 0,
  );
  print Dumper $bq->{response};
  foreach my $ref (@$aref) {
    print join("\t", @$ref), "\n";
  }
}

done_testing;
