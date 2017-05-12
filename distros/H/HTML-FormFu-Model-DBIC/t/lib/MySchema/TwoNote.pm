package MySchema::TwoNote;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table("two_note");

__PACKAGE__->add_columns(
    id     => { data_type => "INTEGER", is_nullable => 0 },
    two_note_id => { data_type => "INTEGER", is_nullable => 0 },
    note   => { data_type => "TEXT", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("two_note_id");

__PACKAGE__->belongs_to( id => 'MySchema::Master', { id => 'id' } );

1;

