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

use Google::BigQuery;

my $bigquery = Google::BigQuery::create(
  client_email => $ENV{CLIENT_EMAIL},
  private_key_file => $ENV{PRIVATE_KEY_FILE}
);
isnt($bigquery, undef, 'constructor');
isnt($bigquery->{access_token}, undef, 'access_token');

done_testing;

