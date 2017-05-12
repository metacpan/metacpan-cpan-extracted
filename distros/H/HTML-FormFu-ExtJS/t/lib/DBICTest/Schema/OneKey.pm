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
    DBICTest::Schema::OneKey;

use base 'DBIx::Class::Core';

__PACKAGE__->table('onekey');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artist' => {
    data_type => 'integer',
  },
  'cd' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key('id');


1;
