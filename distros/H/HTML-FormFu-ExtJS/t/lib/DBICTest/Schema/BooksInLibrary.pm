#
# This file is part of HTML-FormFu-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package # hide from PAUSE 
    DBICTest::Schema::BooksInLibrary;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('books');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'source' => {
    data_type => 'varchar',
    size      => '100',
  },
  'owner' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size      => '100',
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->resultset_attributes({where => { source => "Library" } });

1;
