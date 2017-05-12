#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <wordcut/wcwordcut.h>
#include <string.h>

typedef WcWordcut* Lingua__TH__Segmentation__wc;
typedef WcWordVector* Lingua__TH__Segmentation__vector;

MODULE = Lingua::TH::Segmentation		PACKAGE = Lingua::TH::Segmentation
PROTOTYPES: ENABLE

Lingua::TH::Segmentation::wc get_wc(package)
	char *package;
	CODE:
		RETVAL = wc_wordcut_new();
	OUTPUT:
		RETVAL

Lingua::TH::Segmentation::wc get_custom_wc(package,dictionary_file,wordunit_file);
	char *package;
	guchar* dictionary_file;
	guchar* wordunit_file;
	CODE:
		RETVAL = wc_wordcut_new_custom(dictionary_file,wordunit_file);
	OUTPUT:
		RETVAL

void destroy_wc(package,wc)
	char *package;
	Lingua::TH::Segmentation::wc wc;	
	CODE:
		wc_wordcut_delete(wc);

gchar* wordcut(package,wc,str);
	char* package;
	Lingua::TH::Segmentation::wc wc;
	gchar* str;
	PREINIT:
		char* delimiter;
		gchar* xyz;
	CODE:
		delimiter = "#K_=";
		strcpy(wc->print.delimiter,delimiter);
		xyz =(gchar*) wc_wordcut_cutline(wc,str,strlen(str));
		RETVAL = xyz;
	OUTPUT:
		RETVAL

gchar* string_separate(package,wc,str,separator);
	char* package;
	Lingua::TH::Segmentation::wc wc;
	gchar* str;
	char* separator
	PREINIT:
		gchar* xyz;
	CODE:
		strcpy(wc->print.delimiter,separator);
		xyz =(gchar*) wc_wordcut_cutline(wc,str,strlen(str));
		RETVAL = xyz;
	OUTPUT:
		RETVAL
