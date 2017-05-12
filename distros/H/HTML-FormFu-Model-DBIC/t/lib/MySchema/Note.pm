package MySchema::Note;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table("note");

__PACKAGE__->add_columns(
    id     => { data_type => "INTEGER", is_nullable => 0 },
    master => { data_type => "INTEGER", is_nullable => 0 },
    note   => { data_type => "TEXT", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( master => 'MySchema::Master' );

1;

