package Email::Archive::Storage::DBIC::Schema::Result::Metadata;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('metadata');

__PACKAGE__->add_columns(
  'schema_version', {
    data_type => 'integer',
    extra => { unsigned => 1 },
    default_value => 0,
  },
);

__PACKAGE__->set_primary_key('schema_version');

1;

