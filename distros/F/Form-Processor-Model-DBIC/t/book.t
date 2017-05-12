use strict;
use warnings;
use Test::More;
use lib 't/lib';


use_ok( 'Form::Processor::Model::DBIC' );

use_ok( 'BookForm');

use_ok( 'Schema::DB');

my $schema = Schema::DB->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $form = BookForm->new(item_id => undef, schema => $schema);

ok( !$form->validate, 'Empty data' );

$form->clear;

# This is munging up the equivalent of param data from a form
my $good = {
    'title' => 'How to Test Perl Form Processors',
    'author' => 'I.M. Author',
    'genres' => [2, 4],
    'format'       => 2,
    'isbn'   => '123-02345-0502-2' ,
    'publisher' => 'EreWhon Publishing',
    'comment' => 'Some comment',
};

ok( $form->validate( $good ), 'good data validates');

ok( $form->update_from_form( $good ), 'Good data' );

my $book = $form->item;
END { $book->delete };
is( $book->comment, 'Some comment', 'non-db accessor works' );

ok ($book, 'get book object from form');

my $num_genres = $book->genres->count;
is( $num_genres, 2, 'multiple select list updated ok');

is( $form->value('format'), 2, 'get value for format' );

my $id = $book->id;

my $bad_1 = {
    title => '',
    notitle => 'not req',
    silly_field   => 4,
};

$form->clear;
ok( !$form->validate( $bad_1 ), 'bad 1' );

$form = BookForm->new(item => $book, schema => $schema);
ok( $form, 'create form from db object');

my $genres_field = $form->field('genres');
is_deeply( sort $genres_field->value, [2, 4], 'value of multiple field is correct');
is( $form->field('test')->value, 'testing', 'init_value works' );

my $bad_2 = {
    'title' => "Another Silly Test Book",
    'author' => "C. Foolish",
    'year' => '1590',
    'pages' => 'too few',
    'format' => '22',
};

ok( !$form->validate( $bad_2 ), 'bad 2');
ok( $form->field('year')->has_error, 'year has error' );
ok( $form->field('pages')->has_error, 'pages has error' );
ok( !$form->field('author')->has_error, 'author has no error' );
ok( $form->field('format')->has_error, 'format has error' );



done_testing;
