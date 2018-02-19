package Test::JSONAPI::Schema::Result::Author;

use base 'DBIx::Class::Core';

__PACKAGE__->table('author');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_nullable => 0,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
    },
    age => {
        data_type => 'int',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'posts' => 'Test::JSONAPI::Schema::Result::Post',
    'author_id'
);

1;
