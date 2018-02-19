package Test::JSONAPI::Schema::Result::Post;

use base 'DBIx::Class::Core';

__PACKAGE__->table('post');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    author_id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    title => {
        data_type => 'varchar',
        is_nullable => 0,
    },
    description => {
        data_type => 'varchar',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'comments' => 'Test::JSONAPI::Schema::Result::Comment',
    'post_id'
);

__PACKAGE__->belongs_to(
    'author' => 'Test::JSONAPI::Schema::Result::Author',
    'author_id'
);

1;
