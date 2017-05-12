/*
   Copyright 2009, 2010, 2011 Kevin Ryde

   This file is part of File-Locate-Iterator.

   File-Locate-Iterator is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.

   File-Locate-Iterator is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>. */

#include <fnmatch.h>
#include <stdlib.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#define DEBUG 0

#if DEBUG >= 1
#define DEBUG1(code) do { code; } while (0)
#else
#define DEBUG1(code)
#endif
#if DEBUG >= 2
#define DEBUG2(code) do { code; } while (0)
#else
#define DEBUG2(code)
#endif

#define GET_FIELD(var,name)                             \
  do {                                                  \
    SV **svptr;                                         \
    field = (name);                                     \
    svptr = hv_fetch (h, field, strlen(field), 0);      \
    if (! svptr) goto FIELD_MISSING;                    \
    (var) = *svptr;                                     \
  } while (0)

#define MATCH(target)                                                   \
  do {                                                                  \
    if (regexp) {                                                       \
      if (CALLREGEXEC (regexp,                                          \
                       entry_p, entry_p + entry_len,                    \
                       entry_p, 0, entry, NULL,                         \
                       REXEC_IGNOREPOS)) {                              \
        goto target;                                                    \
      }                                                                 \
      DEBUG1 (fprintf (stderr, "  no match regexp\n"));                 \
    } else {                                                            \
      if (! globs_ptr) {                                                \
        DEBUG1 (fprintf (stderr, "  no regexp or globs, so match\n"));  \
        goto target;                                                    \
      }                                                                 \
    }                                                                   \
    {                                                                   \
      SSize_t i;                                                        \
      for (i = 0; i <= globs_lastidx; i++) {                            \
        DEBUG2 (fprintf (stderr, "  fnmatch \"%s\" entry \"%s\"\n",     \
                         SvPV_nolen(globs_ptr[i]), entry_p));           \
        if (fnmatch (SvPV_nolen(globs_ptr[i]), entry_p, 0) == 0)        \
          goto target;                                                  \
      }                                                                 \
      DEBUG1 (fprintf (stderr, "  no match globs\n"));                  \
    }                                                                   \
    DEBUG1 (fprintf (stderr, "  no match\n"));                          \
  } while (0)

MODULE = File::Locate::Iterator   PACKAGE = File::Locate::Iterator

void
next (SV *self)
CODE:
  {
    HV *h;
    SV **mref_svptr, *entry, *sharelen_sv;
    SV **globs_ptr = NULL;
    SSize_t globs_lastidx = -1;
    REGEXP *regexp = NULL;
    const char *field;
    char *entry_p;
    STRLEN entry_len;
    IV sharelen, adj;
    int at_eof = 0;

    DEBUG2 (fprintf (stderr, "FLI XS next()\n"));

    goto START;
    {
    FIELD_MISSING:
      croak ("oops, missing '%s'", field);
    }
  START:
    h = (HV*) SvRV(self);

    GET_FIELD (entry, "entry");

    GET_FIELD (sharelen_sv, "sharelen");
    sharelen = SvIV (sharelen_sv);

    {
      SV **regexp_svptr = hv_fetch (h, "regexp", 6, 0);
      if (regexp_svptr) {
        SV *regexp_sv = *regexp_svptr;
        DEBUG2(fprintf (stderr, "regexp sv="); sv_dump (regexp_sv));
        regexp = SvRX(regexp_sv);
        /* regexp=>undef is no regexp to match.  Normally the regexp field
           is omitted if undef (ie regexp_svptr==NULL), but the Moose stuff
           insists on filling-in named attributes. :-( */
        if (SvOK(regexp_sv)) {
          if (! regexp) croak ("'regexp' not a regexp");
        }
      }
      DEBUG1 (fprintf (stderr, "REGEXP obj %"UVxf"\n", PTR2UV(regexp)));
    }

    {
      SV **globs_svptr = hv_fetch (h, "globs", 5, 0);
      if (globs_svptr) {
        SV *globs_sv = *globs_svptr;
        /* globs=>undef is no globs to match.  Normally the globs field is
           omitted if undef (ie globs_svptr==NULL), but the Moose stuff
           insists on filling-in named attributes. :-(
           globs has been crunched by new(), so it's a plain array, no need
           to worry about SvGetMagic() or whatnot.  */
        if (SvOK (globs_sv)) {
          if (! SvROK (globs_sv))
            croak ("oops, 'globs' not a reference");
          AV *globs_av = (AV*) SvRV(globs_sv);

          if (SvTYPE(globs_av) != SVt_PVAV)
            croak ("oops, 'globs' not an arrayref");
          globs_ptr = AvARRAY (globs_av);
          globs_lastidx = av_len (globs_av);
        }
      }
      DEBUG1 (fprintf
              (stderr, "globs_svptr %"UVxf" globs_ptr %"UVxf" globs_lastidx %d\n",
               PTR2UV(globs_svptr), PTR2UV(globs_ptr), globs_lastidx));
    }

    mref_svptr = hv_fetch (h, "mref", 4, 0);
    if (mref_svptr) {
      SV *mref, *mmap, *pos_sv;
      mref = *mref_svptr;
      char *mp, *gets_beg, *gets_end;
      STRLEN mlen;
      UV pos;

      mmap = (SV*) SvRV(mref);
      mp = SvPV (mmap, mlen);

      GET_FIELD (pos_sv, "pos");
      pos = SvUV(pos_sv);
      DEBUG2 (fprintf (stderr, "mmap %"UVxf" mlen %u, pos %"UVuf"\n",
                      PTR2UV(mp), mlen, pos));

      for (;;) {
        DEBUG2 (fprintf (stderr, "MREF_LOOP\n"));
        if (pos >= mlen) {
          /* EOF */
          at_eof = 1;
          break;
        }
        adj = ((I8*)mp)[pos++];

        if (adj == -128) {
          DEBUG1 (fprintf (stderr, "two-byte adj at pos=%"UVuf"\n", pos));
          if (pos >= mlen-1) goto UNEXPECTED_EOF;
          adj = (I16) ((((U16) ((U8*)mp)[pos]) << 8)
                       + ((U8*)mp)[pos+1]);
          pos += 2;
        }
        DEBUG1 (fprintf (stderr, "adj %"IVdf" at pos=%"UVuf"\n", adj, pos));
        
        sharelen += adj;
        if (sharelen < 0 || sharelen > SvCUR(entry)) {
          sv_setpv (entry, NULL);
          croak ("Invalid database contents (bad share length %"IVdf")",
                 sharelen);
        }
        DEBUG1 (fprintf (stderr, "sharelen %"IVdf"\n", sharelen));
        
        if (pos >= mlen) goto UNEXPECTED_EOF;
        gets_beg = mp + pos;
        gets_end = memchr (gets_beg, '\0', mlen-pos);
        if (! gets_end) {
          DEBUG1 (fprintf (stderr, "NUL not found gets_beg=%"UVxf" len=%lu\n",
                          PTR2UV(gets_beg), mlen-pos));
          goto UNEXPECTED_EOF;
        }
        
        SvCUR_set (entry, sharelen);
        sv_catpvn (entry, gets_beg, gets_end - gets_beg);
        pos = gets_end + 1 - mp;
        
        entry_p = SvPV(entry, entry_len);

        MATCH(MREF_LOOP_END);
      }
    MREF_LOOP_END:
      SvUV_set (pos_sv, pos);

    } else {
      SV *fh;
      PerlIO *fp;
      int got;
      union {
        char buf[2];
        U16 u16;
      } adj_u;
      char *gets_ret;

      GET_FIELD (fh, "fh");
      fp = IoIFP(sv_2io(fh));
      DEBUG2 (fprintf (stderr, "fp=%"UVxf" fh=\n", PTR2UV(fp));
              sv_dump (fh));

      /*  local $/ = "\0"  */
      save_item (PL_rs);
      sv_setpvn (PL_rs, "\0", 1);

      for (;;) {
        DEBUG2 (fprintf (stderr, "IO_LOOP\n"));
        got = PerlIO_read (fp, adj_u.buf, 1);
        if (got == 0) {
          /* EOF */
          at_eof = 1;
          break;
        }
        if (got != 1) {
        READ_ERROR:
          DEBUG1 (fprintf (stderr, "read fp=%"UVxf" got=%d\n",
                           PTR2UV(fp), got));
          if (got < 0) {
            croak ("Error reading database");
          } else {
          UNEXPECTED_EOF:
            croak ("Invalid database contents (unexpected EOF)");
          }
        }

        adj = (I8) adj_u.buf[0];
        if (adj == -128) {
          DEBUG1 (fprintf (stderr, "two-byte adj\n"));
          got = PerlIO_read (fp, adj_u.buf, 2);
          if (got != 2) goto READ_ERROR;
          DEBUG1 (fprintf (stderr, "raw %X,%X %X ntohs %X\n",
                  (int) (U8) adj_u.buf[0], (int) (U8) adj_u.buf[1],
                          adj_u.u16, ntohs(adj_u.u16)));
          adj = (int) (I16) ntohs(adj_u.u16);
        }
        DEBUG1 (fprintf (stderr, "adj %"IVdf" %#"UVxf"\n", adj, adj));

        sharelen += adj;
        DEBUG1 (fprintf (stderr, "sharelen %"IVdf" %#"UVxf"  SvCUR %d utf8 %d\n",
                        sharelen, sharelen,
                        SvCUR(entry), SvUTF8(entry)));

        if (sharelen < 0 || sharelen > SvCUR(entry)) {
          sv_setpv (entry, NULL);
          croak ("Invalid database contents (bad share length %"IVdf")",
                 sharelen);
        }

        /* sv_gets() in perl 5.10.1 and earlier must have "append" equal to
           SvCUR(sv).  The "fast" direct buffer access takes it as a byte
           position to store to, but the plain read code takes it as a flag
           to do sv_catpvn() instead of sv_setpvn().  This appears to be so
           right back to 5.002 ("fast" access directly into a FILE*).  So
           SvCUR_set() here to work in either case.  */
        SvCUR_set (entry, sharelen);

        gets_ret = sv_gets (entry, fp, sharelen);
        if (gets_ret == NULL) goto UNEXPECTED_EOF;
        DEBUG2 (fprintf (stderr,
                         "entry gets to %u, chomp to %u, fpos now %lu(%#lx)\n",
                         SvCUR(entry), SvCUR(entry) - 1,
                         (unsigned long) PerlIO_tell(fp),
                         (unsigned long) PerlIO_tell(fp));
                fprintf (stderr, "entry gets to %u, chomp to %u\n",
                         SvCUR(entry), SvCUR(entry) - 1));

        entry_p = SvPV(entry, entry_len);
        if (entry_len < 1 || entry_p[entry_len-1] != '\0') {
          DEBUG1 (fprintf (stderr, "no NUL from sv_gets\n"));
          goto UNEXPECTED_EOF;
        }
        entry_len--;
        SvCUR_set (entry, entry_len); /* chomp \0 terminator */

        MATCH(IO_LOOP_END);
      }
    IO_LOOP_END:
      /* taint the same as other reads from a file, and in particular the
         same as from the pure-perl reads */
      SvTAINTED_on(entry);
    }
    if (at_eof) {
      sv_setpv (entry, NULL);
      DEBUG2 (fprintf (stderr, "eof\n  entry=\n");
              sv_dump (entry);
              fprintf (stderr, "\n"));
      XSRETURN(0);

    } else {
      SvUV_set (sharelen_sv, sharelen);
      DEBUG2 (fprintf (stderr, "return entry=\n");
              sv_dump (entry);
              fprintf (stderr, "\n"));

      SvREFCNT_inc_simple_void (entry);
      ST(0) = sv_2mortal(entry);
      XSRETURN(1);
    }
  }
