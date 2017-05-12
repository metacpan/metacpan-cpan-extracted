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
my $dataset_id = 'sample_dataset_' . time;
my $table_id = 'sample_table_' . time;
my $ret;
my $bq;

# auth
throws_ok
  { Google::BigQuery::create() }
  '/undefined client_eamil/',
  'undefined client_email';

throws_ok
  { Google::BigQuery::create(client_email=>$client_email) }
  '/undefined private_key_file/',
  'undefined private_key_file';

throws_ok
  { Google::BigQuery::create(client_email=>"${client_email}x", private_key_file=>$private_key_file); }
  '/invalid_grant/',
  'invalid_grant';

throws_ok
  { Google::BigQuery::create(client_email=>"${client_email}", private_key_file=>"x${private_key_file}") }
  '/not found private_key_file/',
  'not found private_key_file';

my $invalid_private_key_file="$Bin/invalid_private_key_file.txt";
throws_ok
  { Google::BigQuery::create(client_email=>"${client_email}", private_key_file=>"$invalid_private_key_file") }
  '/invalid private_key_file format/',
  'invalid private_key_file format';

my $bq = Google::BigQuery::create(client_email=>$client_email, private_key_file=>$private_key_file);

done_testing;
