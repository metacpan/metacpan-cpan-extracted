#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <libgnome/gnome-sound.h>

static int
not_here(char *s)
{
	croak("%s not implemented on this architecture", s);
	return -1;
}

static double
constant(char *name, int len, int arg)
{
	errno = EINVAL;
	return 0;
}

MODULE = Gnome::Sound		PACKAGE = Gnome::Sound		

double
constant(sv,arg)
	PREINIT:
		STRLEN len;
	INPUT:
		SV   * sv
		char * s = SvPV(sv, len);
		int    arg
	CODE:
		RETVAL = constant(s, len, arg);
	OUTPUT:
		RETVAL

void
init(hostname)
		const char * hostname
	CODE:
		gnome_sound_init(hostname);

void
shutdown()
	CODE:
		gnome_sound_shutdown();

int
sample_load(sample_name, filename)
		const char * sample_name
		const char * filename
	CODE:
		RETVAL = gnome_sound_sample_load(sample_name, filename);
	OUTPUT:
		RETVAL

void
play(filename)
		const char * filename
	CODE:
		gnome_sound_play(filename);


