package Test::JSONAPI::Schema::Result::Comment;

use base 'DBIx::Class::Core';

__PACKAGE__->table('comment');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_nullable => 0,
    },
    post_id => {
        data_type => 'int',
        is_nullable => 0,
    },
    author_id => {
        data_type => 'int',
        is_nullable => 0,
    },
    description => {
        data_type => 'varchar',
        is_nullable => 0,
    },
    likes => {
        data_type => 'int',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'post' => 'Test::JSONAPI::Schema::Result::Post',
    'post_id'
);

__PACKAGE__->belongs_to(
    'author' => 'Test::JSONAPI::Schema::Result::Author',
    'author_id'
);

1;
