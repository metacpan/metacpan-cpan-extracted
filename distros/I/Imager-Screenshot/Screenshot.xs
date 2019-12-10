#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "imext.h"
#include "imperl.h"
#include "imss.h"
#ifdef SS_WIN32
#include "svwin32.h"
#endif

DEFINE_IMAGER_CALLBACKS;

#define imss__x11_open imss_x11_open

MODULE = Imager::Screenshot  PACKAGE = Imager::Screenshot PREFIX = imss

PROTOTYPES: DISABLE

#ifdef SS_WIN32

Imager::ImgRaw
imss_win32(hwnd, include_decor = 0, left = 0, top = 0, right = 0, bottom = 0, monitor = 0)
	SSHWND hwnd
	int include_decor
	int left
	int top
	int right
	int bottom
	int monitor

#endif

#ifdef SS_X11

Imager::ImgRaw
imss_x11(display, window_id, left = 0, top = 0, right = 0, bottom = 0, direct = 0)
        unsigned long display
	int window_id
	int left
	int top
	int right
	int bottom
	int direct

unsigned long
imss_x11_open(display_name = NULL)
        const char *display_name

void
imss_x11_close(display)
        unsigned long display

#endif

#ifdef SS_DARWIN

Imager::ImgRaw
imss_darwin(left = 0, top = 0, right = 0, bottom = 0)
	int left
	int top
	int right
	int bottom

#endif

BOOT:
	PERL_INITIALIZE_IMAGER_CALLBACKS;
