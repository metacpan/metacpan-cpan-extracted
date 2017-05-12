/**
 * @file book.h
 * @author Tom Molesworth <tom@entitymodel.com>
 * @date 17/11/12 12:03:58
 *
 * $Id$
 */

#include <string>

namespace Model {

class Author;

class Book {
public:
	Book() {
		name_ = "";
		author_ = nullptr;
	}
virtual	~Book() { }

	Book &name(std::string name) { this->name_ = name; return *this; }
	std::string name(void) { return this->name_; }

	Book &author(Author *author) { this->author_ = author; return *this; }
	Author *author(void) { return this->author_; }

private:
	std::string name_;
	Author *author_;
};

};

