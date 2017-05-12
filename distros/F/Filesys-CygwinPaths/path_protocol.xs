#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "path_protocol.h"


MODULE = Filesys::CygwinPaths		PACKAGE = Filesys::CygwinPaths		


char*
cygwin_conv_to_full_posix_path(input_string)
	const char *	input_string;

  CODE:
	char      output_string[MAX_PATH]="";
    cygwin_conv_to_full_posix_path(input_string, output_string);
	RETVAL = output_string;

  OUTPUT:
	RETVAL



char*
cygwin_conv_to_full_win32_path(input_string)
	const char *	input_string;

  CODE:
	char      output_string[MAX_PATH]="";
    cygwin_conv_to_full_win32_path(input_string, output_string);
	RETVAL = output_string;

  OUTPUT:
	RETVAL



char*
cygwin_conv_to_posix_path(input_string)
	const char *	input_string;

  CODE:
	char      output_string[MAX_PATH]="";
    cygwin_conv_to_posix_path(input_string, output_string);
	RETVAL = output_string;

  OUTPUT:
	RETVAL



char*
cygwin_conv_to_win32_path(input_string)
	const char *	input_string;

  CODE:
	char      output_string[MAX_PATH]="";
    cygwin_conv_to_win32_path(input_string, output_string);
	RETVAL = output_string;

  OUTPUT:
	RETVAL


