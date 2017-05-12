use strict;
use warnings;

=pod

Verify that we can run the standard EntityModel cache tests

=cut

use Test::More tests => 1;
use EntityModel::Test::Cache;
cache_ok('EntityModel::Cache::Memcached::Async');
