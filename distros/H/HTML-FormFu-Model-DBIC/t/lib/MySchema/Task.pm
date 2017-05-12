package MySchema::Task;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table("task");

__PACKAGE__->add_columns(
    id       => { data_type => "INTEGER", is_nullable => 0 },
    schedule => { data_type => "INTEGER", is_nullable => 0 },
    deadline => { data_type => "DATETIME", is_nullable => 1 },
    detail   => { data_type => "TEXT", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( schedule => 'MySchema::Schedule' );

1;

