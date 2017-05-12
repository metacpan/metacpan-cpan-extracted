package Schema::DB::BooksGenres;

use strict;
use warnings;

use base 'DBIx::Class';

Schema::DB::BooksGenres->load_components("Core");
Schema::DB::BooksGenres->table("books_genres");
Schema::DB::BooksGenres->add_columns(
  "book_id",
  {
    data_type => "INTEGER",
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "genre_id",
  {
    data_type => "INTEGER",
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
);
Schema::DB::BooksGenres->set_primary_key(('book_id', 'genre_id'));
   
Schema::DB::BooksGenres->belongs_to(
  "book",
  "Schema::DB::Book",
  { id => "book_id" },
);
Schema::DB::BooksGenres->belongs_to(
  "genre",
  "Schema::DB::Genre",
  { id => "genre_id" },
);


1;
