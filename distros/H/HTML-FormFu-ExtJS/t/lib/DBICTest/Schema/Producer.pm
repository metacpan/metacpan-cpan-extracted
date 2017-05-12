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
    DBICTest::Schema::Producer;

use base 'DBIx::Class::Core';

__PACKAGE__->table('producer');
__PACKAGE__->add_columns(
  'producerid' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('producerid');
__PACKAGE__->add_unique_constraint(prod_name => [ qw/name/ ]);

__PACKAGE__->has_many(
    cd_to_producer => 'DBICTest::Schema::CD_to_Producer' => 'producer'
);

__PACKAGE__->many_to_many( _cds => cd_to_producer => 'cd' );


sub cds {
	return shift->_cds->count;
}
1;
