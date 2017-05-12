package MySchema::Schedule;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ InflateColumn::DateTime Core /);

__PACKAGE__->table("schedule");

__PACKAGE__->add_columns(
    id     => { data_type => "INTEGER", is_nullable => 0 },
    master => { data_type => "INTEGER", is_nullable => 0 },
    date   => { data_type => "DATETIME", is_nullable => 0 },
    note   => { data_type => "TEXT", is_nullable => 0 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( master => 'MySchema::Master' );

__PACKAGE__->has_many( tasks => 'MySchema::Task', 'schedule' );

1;

