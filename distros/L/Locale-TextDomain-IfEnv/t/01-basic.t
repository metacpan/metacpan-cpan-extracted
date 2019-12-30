#!perl

use strict;
use warnings;
use Test::More 0.98;

use Locale::TextDomain::IfEnv 'Locale-TextDomain-IfEnv';

local $ENV{LANGUAGE} = 'id';

is(__("book"), "book");

is(__x("There is/are {count} book(s). {mark}", count=>1), "There is/are 1 book(s). {mark}");

is(__n("book", "books", 1), "book");
is(__n("book", "books", 2), "books");

is(__nx("There is {count} book. {mark}", "There are {count} books. {mark}", 1, count=>1), "There is 1 book. {mark}");
is(__nx("There is {count} book. {mark}", "There are {count} books. {mark}", 2, count=>2), "There are 2 books. {mark}");

is(__xn("There is {count} book. {mark}", "There are {count} books. {mark}", 1, count=>1), "There is 1 book. {mark}");
is(__xn("There is {count} book. {mark}", "There are {count} books. {mark}", 2, count=>2), "There are 2 books. {mark}");

is(__p("Noun, a book", "book"), "book");

is(__px("Context", "There is/are {count} book(s). {mark}", count=>1), "There is/are 1 book(s). {mark}");

is(__np("Context", "book", "books", 1), "book");
is(__np("Context", "book", "books", 2), "books");

is(__npx("Context", "There is {count} book. {mark}", "There are {count} books. {mark}", 1, count=>1), "There is 1 book. {mark}");
is(__npx("Context", "There is {count} book. {mark}", "There are {count} books. {mark}", 2, count=>2), "There are 2 books. {mark}");

is_deeply([N__("book")], ["book"]);
is_deeply([N__n("book", "books", 1)], ["book", "books", 1]);
is_deeply([N__p("Noun, a book", "book")], ["Noun, a book", "book"]);
is_deeply([N__np("Context", "book", "books", 1)], ["Context", "book", "books", 1]);

done_testing;
