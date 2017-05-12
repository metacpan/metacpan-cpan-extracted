package MyApp::DB::Book;
use Kelp::Base 'Rose::DB::Object';

__PACKAGE__->meta->setup(
    table => 'books',

    columns => [
        rowid     => { type => 'serial',  primary_key => 1 },
        title     => { type => 'varchar', length      => 255 },
        author_id => { type => 'text' },
    ],

    foreign_keys => [
        author => {
            class       => 'MyApp::DB::Author',
            key_columns => { author_id => 'id' }
        }
    ]
);

__PACKAGE__->meta->make_manager_class('books');

1;
