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
    DBICTest::Schema::Tag;

use base qw/DBIx::Class::Core/;

__PACKAGE__->table('tags');
__PACKAGE__->add_columns(
  'tagid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'cd' => {
    data_type => 'integer',
  },
  'tag' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('tagid');

__PACKAGE__->belongs_to( cd => 'DBICTest::Schema::CD' );

1;
