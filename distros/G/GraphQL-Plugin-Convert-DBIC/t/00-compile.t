use strict;
use Test::More 0.98;

use_ok $_ for qw(
  GraphQL::Plugin::Convert::DBIC
  SQL::Translator::Producer::GraphQL
);

done_testing;

