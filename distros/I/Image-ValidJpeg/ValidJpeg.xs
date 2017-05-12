#include "valid_jpeg.h"

MODULE = Image::ValidJpeg		PACKAGE = Image::ValidJpeg		

PROTOTYPES: ENABLE

int
check_tail(PerlIO * fh);

int
valid_jpeg(PerlIO * fh, int skip=0);

int 
check_all(PerlIO * fh);

int
check_jpeg(PerlIO *fh);

int
GOOD()
CODE:
	RETVAL = GOOD_;
OUTPUT:
	RETVAL

int
BAD()
CODE:
	RETVAL = BAD_;
OUTPUT:
	RETVAL

int
EXTRA()
CODE:
	RETVAL = EXTRA_;
OUTPUT:
	RETVAL

int
SHORT()
CODE:
	RETVAL = SHORT_;
OUTPUT:
	RETVAL

int
max_seek(int n)

void
set_valid_jpeg_debug(int x)
