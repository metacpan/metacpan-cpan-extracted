use strict;
use warnings;

=pod

Verify that we can run the storage tests against the interface
class and any builtin storage classes we might have available.

=cut

use Test::More tests => 4;

use EntityModel::Test::Storage;

# Top-level
storage_ok('EntityModel::Storage', []);
storage_methods_ok('EntityModel::Storage', []);

# Built-in Perl storage layer
storage_ok('EntityModel::Storage::Perl', []);
storage_methods_ok('EntityModel::Storage::Perl', []);
#storage_implementation_ok('EntityModel::Storage');

