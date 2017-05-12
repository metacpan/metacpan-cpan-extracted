package Schema::DB::Genre;

use strict;
use warnings;

use base 'DBIx::Class';

Schema::DB::Genre->load_components("Core");
Schema::DB::Genre->table("genre");
Schema::DB::Genre->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
Schema::DB::Genre->set_primary_key("id");
Schema::DB::Genre->has_many(
  "books_genres",
  "Schema::DB::BooksGenres",
  { "foreign.genre_id" => "self.id" },
);
Schema::DB::Genre->many_to_many(
  books => 'books_genres', 'book'
);


1;
