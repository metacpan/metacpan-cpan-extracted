#include <iostream>
#include "Model.h"

using namespace std;
using namespace Model;

int
main(void)
{
/* Basic Test::More-ish behaviour */
	int test = 1;
	int expected_tests;
	auto note = [] (std::string m) {
		cout << u8"# " << m << endl;
	};
	auto ok = [&test] (bool check, std::string m) {
		cout << std::string(check ? u8"ok" : u8"not ok")
		  << u8" " << test++ << u8" - " << m << endl;
	};
	auto plan = [&expected_tests] (int count) {
		expected_tests = count;
		cout << u8"1.." << expected_tests << endl;
	};

	plan(5);

/*
 * Simple key=>value accessors on an object
 */
	note(u8"Creating author");
	Author author;
	author.name(std::string(u8"First author"));
	ok(
	  author.name() == u8"First author",
	  u8"name was set correctly"
	);
	note(u8"Author's name is: " + author.name());

/*
 * References to other objects
 */
	note(u8"Creating book");
	Book book;
	book.name(std::string(u8"First book")).author(&author);
	note(u8"Book name is " + book.name());
	note(u8"Author's name is " + book.author()->name());
	ok(book.name() == u8"First book", u8"book has correct name");
	ok(book.author() == &author, u8"book has correct author");
	ok(
	  book.author()->name() == u8"First author",
	  u8"linked author for book has correct name"
	);

/*
 * Collections
 */
	note(u8"Creating library");
	Library library;
	note(u8"Adding book to library");

	return 0;
}

