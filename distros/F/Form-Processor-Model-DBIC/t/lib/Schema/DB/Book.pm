package Schema::DB::Book;

use base ('DBIx::Class', 'Class::Accessor::Fast');

__PACKAGE__->mk_accessors('comment');

Schema::DB::Book->load_components("Core");
Schema::DB::Book->table("book");
Schema::DB::Book->add_columns(
  "id",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "isbn",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "author",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "publisher",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "pages",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "year",
  { data_type => "INTEGER", is_nullable => 0, size => undef },
  "format",
  {
    data_type => "INTEGER",
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "borrower",
  {
    data_type => "INTEGER",
    is_foreign_key => 1,
    is_nullable => 0,
    size => undef,
  },
  "borrowed",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);
Schema::DB::Book->set_primary_key("id");
Schema::DB::Book->belongs_to(
  "format",
  "Schema::DB::Format",
  { id => "format" },
);
Schema::DB::Book->belongs_to(
  "borrower",
  "Schema::DB::Borrower",
  { id => "borrower" },
);
Schema::DB::Book->has_many(
  "books_genres",
  "Schema::DB::BooksGenres",
  { "foreign.book_id" => "self.id" },
);
Schema::DB::Book->many_to_many(
  genres => 'books_genres', 'genre'
);

1;
