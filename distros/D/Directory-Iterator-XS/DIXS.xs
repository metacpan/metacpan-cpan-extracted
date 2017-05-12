#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "DirectoryIterator.hh"

using std::string;

MODULE = Directory::Iterator::XS		PACKAGE = Directory::Iterator::XS		

PROTOTYPES: disable

DirectoryIterator *
DirectoryIterator::new (char * dir)

void
DirectoryIterator::show_dotfiles(arg)
	bool arg = sv_true($arg);

void
DirectoryIterator::show_directories(arg)
	bool arg = sv_true($arg);

void
DirectoryIterator::recursive(arg)
	bool arg = sv_true($arg);
      
bool
DirectoryIterator::is_directory()

string
DirectoryIterator::next()
CODE:
	if ( THIS->next() )
	   RETVAL = THIS->get();
	else
	   XSRETURN_UNDEF;
OUTPUT:
	RETVAL

string
DirectoryIterator::get()

void
DirectoryIterator::prune()

string
DirectoryIterator::prune_directory()

void
DirectoryIterator::DESTROY()
