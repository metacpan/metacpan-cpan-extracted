use strict;
use warnings;

=pod

Verify that we can run the cache tests against the interface
class and any builtin cache classes we might have available.

=cut

use Test::More tests => 4;

use EntityModel::Test::Cache;

# Top-level
cache_ok('EntityModel::Cache');
cache_methods_ok('EntityModel::Cache');

# Built-in Perl cache layer
cache_ok('EntityModel::Cache::Perl');
cache_methods_ok('EntityModel::Cache::Perl');
#cache_implementation_ok('EntityModel::Cache');

