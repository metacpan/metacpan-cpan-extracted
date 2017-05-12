#include "config.h"

#include <libgimp/gimp.h>
#include <libgimp/gimpui.h>

#include <locale.h>

/* dunno where this comes from */
#undef VOIDUSED

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#include "Gimp/gppport.h"

#include "Gimp/perl-intl.h"

/* FIXME */
/* dirty is used in gimp.h.  */
#ifdef dirty
# undef dirty
#endif

#ifndef HAVE_EXIT
/* expect iso-c here.  */
# include <signal.h>
#endif

#include "Gimp/gimp-perl.h"

MODULE = Gimp	PACKAGE = Gimp

PROTOTYPES: ENABLE

void
_exit()
	CODE:
#ifdef HAVE__EXIT
	_exit(0);
#elif defined(SIGKILL)
	raise(SIGKILL);
#else
	raise(9)
#endif
	abort();

BOOT:
#ifdef ENABLE_NLS
	setlocale (LC_MESSAGES, ""); /* calling twice doesn't hurt, no? */
        bindtextdomain (GETTEXT_PACKAGE "-perl", datadir "/locale");
        textdomain (GETTEXT_PACKAGE "-perl");
#endif

char *
bindtextdomain(d,dir)
	char * d
	char * dir

char *
textdomain(d)
	char *	d

utf8_str
gettext(s)
	utf8_str s
        PROTOTYPE: $

utf8_str
dgettext(d,s)
	char *	d
	utf8_str s

utf8_str
__(s)
	utf8_str s
        PROTOTYPE: $

void
xs_exit(status)
	int	status
	CODE:
	exit (status);

MODULE = Gimp	PACKAGE = Gimp::RAW

# some raw byte/bit-manipulation (e.g. for avi and miff), use PDL instead
# mostly undocumented as well...

void
reverse_v_inplace (datasv, bpl)
	SV *	datasv
        IV	bpl
        CODE:
        char *line, *data, *end;
        STRLEN h;

        data = SvPV (datasv, h); h /= bpl;
        end = data + (h-1) * bpl;

        New (0, line, bpl, char);

        while (data < end)
          {
            Move (data, line, bpl, char);
            Move (end, data, bpl, char);
            Move (line, end, bpl, char);

            data += bpl;
            end -= bpl;
          }

        Safefree (line);

	OUTPUT:
        datasv

void
convert_32_24_inplace (datasv)
	SV *	datasv
        CODE:
        STRLEN dc;
        char *data, *src, *dst, *end;

        data = SvPV (datasv, dc); end = data + dc;

        for (src = dst = data; src < end; )
          {
            *dst++ = *src++;
            *dst++ = *src++;
            *dst++ = *src++;
                     *src++;
          }

        SvCUR_set (datasv, dst - data);
	OUTPUT:
        datasv

void
convert_24_15_inplace (datasv)
	SV *	datasv
        CODE:
        STRLEN dc;
        char *data, *src, *dst, *end;

        U16 m31d255[256];

        for (dc = 256; dc--; )
          m31d255[dc] = (dc*31+127)/255;

        data = SvPV (datasv, dc); end = data + dc;

        for (src = dst = data; src < end; )
          {
            unsigned int r = *(U8 *)src++;
            unsigned int g = *(U8 *)src++;
            unsigned int b = *(U8 *)src++;

            U16 rgb = m31d255[r]<<10 | m31d255[g]<<5 | m31d255[b];
            *dst++ = rgb & 0xff;
            *dst++ = rgb >> 8;
          }

        SvCUR_set (datasv, dst - data);
	OUTPUT:
        datasv

void
convert_15_24_inplace (datasv)
	SV *	datasv
        CODE:
        STRLEN dc, de;
        char *data, *src, *dst;

        U8 m255d31[32];

        for (dc = 32; dc--; )
          m255d31[dc] = (dc*255+15)/31;

        data = SvPV (datasv, dc); dc &= ~1;
        de = dc + (dc >> 1);
        SvGROW (datasv, de);
        SvCUR_set (datasv, de);
        data = SvPV (datasv, de); src = data + dc;

        dst = data + de;

        while (src != dst)
          {
            U16 rgb = *(U8 *)--src << 8 | *(U8 *)--src;

            *(U8 *)--dst = m255d31[ rgb & 0x001f       ];
            *(U8 *)--dst = m255d31[(rgb & 0x03e0) >>  5];
            *(U8 *)--dst = m255d31[(rgb & 0x7c00) >> 10];
          }

	OUTPUT:
        datasv

void
convert_bgr_rgb_inplace (datasv)
	SV *	datasv
        CODE:
        char *data, *end;

        data = SvPV_nolen (datasv);
        end = SvEND (datasv);

        while (data < end)
          {
            char x = data[0];

            data[0] = data[2];
            data[2] = x;

            data += 3;
          }

	OUTPUT:
        datasv

# when move back to separate .xs, change MODULE
MODULE = Gimp	PACKAGE = Gimp::Constant

PROTOTYPES: ENABLE

#define ADD_GIMP_CONST(name, value) { \
  newCONSTSUB(stash, name, newSViv (value)); \
  av_push(inxs, newSVpv(name, 0)); \
}

BOOT:
{
   HV *stash = gv_stashpvn ("Gimp::Constant", strlen("Gimp::Constant"), TRUE);
   AV *inxs = get_av("Gimp::Constant::INXS", GV_ADD);

   ADD_GIMP_CONST("RUN_INTERACTIVE", GIMP_RUN_INTERACTIVE);
   ADD_GIMP_CONST("RUN_NONINTERACTIVE", GIMP_RUN_NONINTERACTIVE);
   ADD_GIMP_CONST("RUN_WITH_LAST_VALS", GIMP_RUN_WITH_LAST_VALS);

   ADD_GIMP_CONST("INTERNAL", GIMP_INTERNAL);
   ADD_GIMP_CONST("PLUGIN", GIMP_PLUGIN);
   ADD_GIMP_CONST("EXTENSION", GIMP_EXTENSION);
   ADD_GIMP_CONST("TEMPORARY", GIMP_TEMPORARY);

   ADD_GIMP_CONST("PARASITE_PERSISTENT", GIMP_PARASITE_PERSISTENT);
   ADD_GIMP_CONST("PARASITE_UNDOABLE", GIMP_PARASITE_UNDOABLE);
   ADD_GIMP_CONST("PARASITE_ATTACH_PARENT", GIMP_PARASITE_ATTACH_PARENT);
   ADD_GIMP_CONST("PARASITE_PARENT_PERSISTENT", GIMP_PARASITE_PARENT_PERSISTENT);
   ADD_GIMP_CONST("PARASITE_PARENT_UNDOABLE", GIMP_PARASITE_PARENT_UNDOABLE);
   ADD_GIMP_CONST("PARASITE_ATTACH_GRANDPARENT", GIMP_PARASITE_ATTACH_GRANDPARENT);
   ADD_GIMP_CONST("PARASITE_GRANDPARENT_PERSISTENT", GIMP_PARASITE_GRANDPARENT_PERSISTENT);
   ADD_GIMP_CONST("PARASITE_GRANDPARENT_UNDOABLE", GIMP_PARASITE_GRANDPARENT_UNDOABLE);

   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_RGB", GIMP_EXPORT_CAN_HANDLE_RGB);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_GRAY", GIMP_EXPORT_CAN_HANDLE_GRAY);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_INDEXED", GIMP_EXPORT_CAN_HANDLE_INDEXED);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_ALPHA", GIMP_EXPORT_CAN_HANDLE_ALPHA );
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_BITMAP", GIMP_EXPORT_CAN_HANDLE_BITMAP);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_LAYERS", GIMP_EXPORT_CAN_HANDLE_LAYERS);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_LAYERS_AS_ANIMATION", GIMP_EXPORT_CAN_HANDLE_LAYERS_AS_ANIMATION);
   ADD_GIMP_CONST("EXPORT_CAN_HANDLE_LAYER_MASKS", GIMP_EXPORT_CAN_HANDLE_LAYER_MASKS);
   ADD_GIMP_CONST("EXPORT_NEEDS_ALPHA", GIMP_EXPORT_NEEDS_ALPHA);
   ADD_GIMP_CONST("EXPORT_CANCEL", GIMP_EXPORT_CANCEL);
   ADD_GIMP_CONST("EXPORT_IGNORE", GIMP_EXPORT_IGNORE);
   ADD_GIMP_CONST("EXPORT_EXPORT", GIMP_EXPORT_EXPORT);

   ADD_GIMP_CONST("TRUE", TRUE);
   ADD_GIMP_CONST("FALSE", FALSE);

   ADD_GIMP_CONST("UNIT_PIXEL", GIMP_UNIT_PIXEL);
   ADD_GIMP_CONST("UNIT_INCH", GIMP_UNIT_INCH);
   ADD_GIMP_CONST("UNIT_MM", GIMP_UNIT_MM);
   ADD_GIMP_CONST("UNIT_POINT", GIMP_UNIT_POINT);
   ADD_GIMP_CONST("UNIT_PICA", GIMP_UNIT_PICA);
   ADD_GIMP_CONST("UNIT_END", GIMP_UNIT_END);
   ADD_GIMP_CONST("UNIT_PERCENT", GIMP_UNIT_PERCENT);
}
