package Email::Archive::Storage::DBIC::Schema::Result::Messages;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('messages');

__PACKAGE__->add_columns(
  'message_id', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'from_addr', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'to_addr', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'cc', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'subject', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'date', {
    data_type => 'varchar',
    default_value => '',
    is_nullable => 0,
    size => 255,
  },
  'body', {
    data_type => 'text',
    default_value => '',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key('message_id');

1;

