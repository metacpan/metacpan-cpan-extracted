/**
 * @file author.h
 * @author Tom Molesworth <tom@entitymodel.com>
 * @date 17/11/12 12:10:43
 *
 * $Id$
 */

#include <string>

namespace Model {

class Author {
public:
	Author() {
		name_ = "";
	}
virtual	~Author() { }

	Author &name(std::string name) { this->name_ = name; return *this; }
	std::string name(void) { return this->name_; }

private:
	std::string name_;
};

};

