
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"

MODULE = Gnome::About		PACKAGE = Gnome::About		PREFIX = gnome_about_

#ifdef GNOME_ABOUT

Gnome::About_Sink
new(Class, title=0, version=0, copyright=0, authors=0, comments=0, logo=0)
	char *	title
	char *	version
	char *	copyright
	SV *	authors
	char *	comments
	char *	logo
	CODE:
	{
		char ** a = 0;
		if (authors && SvOK(authors)) {
			if (SvRV(authors) && (SvTYPE(SvRV(authors)) == SVt_PVAV)) {
				AV * av = (AV*)SvRV(authors);
				int i;
				a = (char**)malloc(sizeof(char*) * (av_len(av)+2));
				for(i=0;i<=av_len(av);i++) {
					a[i] = SvPV(*av_fetch(av, i, 0), PL_na);
				}
				a[i] = 0;
			} else {
				a = (char**)malloc(sizeof(char*) * 2);
				a[0] = SvPV(authors, PL_na);
				a[1] = 0;
			}
		}
		RETVAL = (GnomeAbout*)(gnome_about_new(title, version, copyright, a, comments, logo));
		if (a)
			free(a);
	}
	OUTPUT:
	RETVAL

#endif

