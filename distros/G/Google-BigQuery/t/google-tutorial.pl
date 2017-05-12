#!/usr/bin/env perl
use strict;
use warnings;

use Google::BigQuery;

use Data::Dumper;

my $client_email = $ENV{CLIENT_EMAIL};
my $private_key_file = $ENV{PRIVATE_KEY_FILE};
my $project_id = $ENV{PROJECT_ID};

my $bq = Google::BigQuery::create(
  client_email => $client_email,
  private_key_file => $private_key_file,
  project_id => $project_id,
);

{
  print "[Heaviest 10 children]\n";
  my $aref = $bq->selectall_arrayref(
    query => "SELECT TOP(title, 10) as title, COUNT(*) as revision_count FROM [publicdata:samples.wikipedia] WHERE wp_namespace = 0"
  );
  foreach my $ref (@$aref) {
    print join("\t", @$ref), "\n";
  }
}

{
  print "[A popular myth debunked!]\n";
  my $aref = $bq->selectall_arrayref(
    query => 'SELECT word FROM publicdata:samples.shakespeare WHERE word="huzzah"'
  );
  foreach my $ref (@$aref) {
    print join("\t", @$ref), "\n";
  }
}

{
  print "[How many works of Shakespeare are there?]\n";
  my $aref = $bq->selectall_arrayref(
    query => "SELECT corpus FROM publicdata:samples.shakespeare GROUP BY corpus"
  );
  foreach my $ref (@$aref) {
    print join("\t", @$ref), "\n";
  }
}

{
  print "[How many works of Shakespeare are there?]\n";
  my $aref = $bq->selectall_arrayref(
    query => "SELECT corpus, sum(word_count) AS wordcount FROM publicdata:samples.shakespeare GROUP BY corpus ORDER BY wordcount DESC"
  );
  foreach my $ref (@$aref) {
    print join("\t", @$ref), "\n";
  }
}
