package My::Schema::Result::Basic;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core/);
__PACKAGE__->table('Basic');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        size              => 10,
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    title => {
        data_type     => 'varchar',
        size          => 100,
        default_value => 'hello',
        is_nullable   => 0,
    },
    description => {
        data_type   => 'text',
        is_nullable => 1,
    },
    email => {
        data_type   => 'varchar',
        size        => 500,
        is_nullable => 1,
    },
    explicitnulldef => {
        data_type     => 'varchar',
        size          => 0,
        is_nullable   => 1,
        default_value => undef,
    },
    explicitemptystring => {
        data_type     => 'varchar',
        size          => 0,
        is_nullable   => 1,
        default_value => '',
    },
    emptytagdef => {
        data_type   => 'varchar',
        size        => 0,
        is_nullable => 1,
    },
    another_id => {
        data_type      => 'int',
        size           => 10,
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    timest => {
        data_type   => 'timestamp',
        is_nullable => 1,
    },
    boolfield => {
        data_type     => 'boolean',
        default_value => 1,
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( 'another_id', 'My::Schema::Result::Another' );

1;
