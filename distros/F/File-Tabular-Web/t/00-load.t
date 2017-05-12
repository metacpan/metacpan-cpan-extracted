#!perl -T

use Test::More tests => 3;

BEGIN {
  require_ok 'File::Tabular::Web'
    or BAIL_OUT;
  require_ok 'File::Tabular::Web::Attachments'
    or BAIL_OUT;
}

diag( "Testing File::Tabular::Web $File::Tabular::Web::VERSION, Perl $], $^X" );

SKIP: {
  eval {require Search::Indexer; 1}
    or skip "Search::Indexer does not seem to be installed", 1;

  require_ok 'File::Tabular::Web::Attachments::Indexed'
    or BAIL_OUT;
}
