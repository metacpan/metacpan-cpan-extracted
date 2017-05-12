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
    DBICTest::Schema::Owners;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('owners');
__PACKAGE__->add_columns(
  'ownerid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => '100',
  },
);
__PACKAGE__->set_primary_key('ownerid');

__PACKAGE__->has_many(books => "DBICTest::Schema::BooksInLibrary", "owner");

1;
