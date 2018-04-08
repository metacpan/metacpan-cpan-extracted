package Test::JSONAPI::Schema::Result::EmailTemplate;

use base 'DBIx::Class::Core';

__PACKAGE__->table('email_template');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    author_id => {
        data_type => 'integer',
        is_nullable => 0,
    },
    name => {
        data_type => 'varchar',
        is_nullable => 0,
    },
    body => {
        data_type => 'varchar',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'author' => 'Test::JSONAPI::Schema::Result::Author',
    'author_id'
);

1;
