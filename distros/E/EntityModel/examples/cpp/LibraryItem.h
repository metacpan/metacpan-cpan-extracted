/**
 * @file LibraryItem.h
 * @author Tom Molesworth <tom@entitymodel.com>
 * @date 17/11/12 12:25:18
 *
 * $Id$
 */

#include <string>
#include <list>

namespace Model {

class Book;

class LibraryItem {
public:
	LibraryItem(Library &library):
		library_(library)
	{
	}

virtual	~LibraryItem() { }

private:
	Library &library_;
};

};


