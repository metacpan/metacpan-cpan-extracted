/* Copyright 2007, 2008, 2009, 2010, 2011, 2019 Kevin Ryde

   This file is part of Filter-gunzip.

   Filter-gunzip is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the
   Free Software Foundation; either version 3, or (at your option) any later
   version.

   Filter-gunzip is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with Filter-gunzip.  If not, see <http://www.gnu.org/licenses/>. */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_PL_parser
#define DPPP_PL_parser_NO_DUMMY    /* code below checks PL_parser != NULL */
#include "ppport.h"


/* set this to 1 for some debug prints to stderr */
#define MY_DEBUG  0


#if MY_DEBUG >= 1
#define MY_DEBUG1(code) do { code; } while (0)
#else
#define MY_DEBUG1(code)
#endif

#if MY_DEBUG >= 1
#define MY_SHOW_LAYERS(location)                                              \
  do {                                                                        \
    PerlIO *f = PL_rsfp;                                                      \
    AV *av = PerlIO_get_layers(aTHX_ f);                                      \
    if (!av) {                                                                \
      fprintf(stderr, "%s: get_layers NULL\n", location);                     \
    } else {                                                                  \
      int i, lastidx = av_len(av);                                            \
      fprintf(stderr, "%s: get_layers lastidx %d (ref count %d)\n",           \
              location, lastidx, SvREFCNT(av));                               \
      for (i = 0; i <= lastidx; i+=3) {                                       \
        SV **svp = av_fetch(av, i, FALSE);                                    \
        fprintf(stderr, "  i=%d  %s\n", i, SvPVX_const(*svp));                \
      }                                                                       \
      SvREFCNT_dec(av);                                                       \
    }                                                                         \
  } while (0)
#else
#define MY_SHOW_LAYERS(location)  do {} while (0)
#endif


MODULE = Filter::gunzip   PACKAGE = Filter::gunzip

int
_filter_by_layer ()
CODE:
    /* Return 1 if successful, or 0 if cannot use a layer (for any reason). */
    if (PL_parser == NULL) {
      MY_DEBUG1(fprintf(stderr, "PL_parser == NULL, no rsfp\n"));
      RETVAL = 0;

    } else {
      int other_filters = 0;
      {
        /* PL_rsfp_filters is NULL if never used.
           Believe can be an empty arrayref if used then the filter popped off.
        */
        AV *av = PL_rsfp_filters;
        if (av) {
          if (av_len(av) >= 0) {  /* $# style last index */
            MY_DEBUG1(fprintf(stderr, "rsfp_filters lastidx %d is other filters, so don't mangle rsfp\n",
                              av_len(av)));
            other_filters = 1;
          } else {
            MY_DEBUG1(fprintf(stderr, "rsfp_filters lastidx %d, good\n", av_len(av)));
          }
        } else {
          MY_DEBUG1(fprintf(stderr, "rsfp_filters NULL, good\n"));
        }
      }
      if (other_filters) {
        RETVAL = 0;

      } else {
        PerlIO *f = PL_rsfp;
        int crlf = 0;
        int gzip_apply;

        MY_SHOW_LAYERS("initial");
        {
          AV *av = PerlIO_get_layers(aTHX_ f);
          MY_DEBUG1(fprintf(stderr, "PL_rsfp get_layers length %d (ref count %d)\n",
                            av_len(av), SvREFCNT(av)));
          if (av_len(av)) {
            SV **svp = av_fetch(av, 0, FALSE);
            MY_DEBUG1(fprintf(stderr, "  top layer name: %s\n", SvPVX_const(*svp)));
            if (strEQ(SvPVX_const(*svp), "crlf")) {
              MY_DEBUG1(fprintf(stderr, "  set flag crlf = 1\n"));
              crlf = 1;
            }
          }
          SvREFCNT_dec(av);
        }

        if (crlf) {
          PerlIO_apply_layers(aTHX_ f, NULL, "pop");
          MY_SHOW_LAYERS("popped crlf");
        }

        gzip_apply = PerlIO_apply_layers(aTHX_ f, NULL, "gzip");
        MY_DEBUG1(fprintf(stderr, "gzip_apply result %d\n", gzip_apply));
        MY_SHOW_LAYERS("pushed gzip");

        /* PerlIO_apply_layers(aTHX_ f, NULL, "pop"); */
        /* MY_SHOW_LAYERS("popped gzip"); */

        if (crlf) {
          PerlIO_apply_layers(aTHX_ f, NULL, "crlf");
          MY_SHOW_LAYERS("pushed back crlf");
        }
        if (gzip_apply == 0) {
          /* success */
          RETVAL = 1;
        } else {
          /* cannot push ":gzip" for some reason */
          RETVAL = 0;
        }
        MY_DEBUG1(fprintf(stderr, "RETVAL %d\n", RETVAL));

        /*   for (;;) { */
        /*     int c = PerlIO_getc(f); */
        /*     fprintf(stderr, "c = %d\n", c); */
        /*     if (c == '\n') break; */
        /*   } */
      }
    }
OUTPUT:
    RETVAL
