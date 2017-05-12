/*
	Copyright (c) 2000 Paul T. Miller
  License: LGPL ( http://www.gnu.org/copyleft/lgpl.html )
  Modified from original sample/testread.cpp in xmlio distribution
    to be suitable for use in the benchmarking system included with
    XML::Bare.
*/

#include "sample.h"
#include "xmlinput.h"
#include "xmlfile.h"
#include <iostream>

static void sDocHandler(XML::Element &elem, void *userData)
{
	// found a Document - make a new one 
	Document *doc = new Document(elem.GetAttribute("name"));

	doc->Read(elem);

	Document::ObjectList::const_iterator it;
	for (it = doc->begin(); it != doc->end(); ++it)
	{
		const Object *obj = (*it);
	}
	delete doc;
}

int main(int argc, char **argv)
{
	XML::FileInputStream file(argv[1]);
	XML::Input input(file);

	// set up initial handler for Document
	XML::Handler handlers[] = {
		XML::Handler("Document", sDocHandler),
		XML::Handler::END
	};

	try {
		input.Process(handlers, NULL);
	}
	catch (const XML::ParseException &e)
	{
		fprintf(stderr, "ERROR: %s (line %d, column %d)\n", e.What(), e.GetLine(), e.GetColumn());
	}
	return 0;
}


