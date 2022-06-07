package My::Schema::Result::Foo;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('foo');
__PACKAGE__->add_columns(
    id => {
        data_type => 'INTEGER',
        is_nullable => 0,
    },
    name => {
        data_type => 'VARCHAR',
        is_nullable => 0,
    },
    delete_fg => {
        data_type => 'INTEGER',
        default_value => 0,
    },
);
__PACKAGE__->set_primary_key('id');

1;
