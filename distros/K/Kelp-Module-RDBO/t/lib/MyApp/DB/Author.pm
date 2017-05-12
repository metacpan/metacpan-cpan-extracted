package MyApp::DB::Author;
use Kelp::Base 'Rose::DB::Object';
use Rose::DB::Object::Helpers 'as_tree';

__PACKAGE__->meta->setup(
    table => 'authors',

    columns => [
        rowid => { type => 'serial',  primary_key => 1 },
        name  => { type => 'varchar', length      => 255 }
    ],

    unique_key => 'name',

    relationships => [
        books => {
            type       => 'one to many',
            class      => 'MyApp::DB::Book',
            column_map => { rowid => 'author_id' }
        }
    ]
);

__PACKAGE__->meta->make_manager_class('authors');


1;
