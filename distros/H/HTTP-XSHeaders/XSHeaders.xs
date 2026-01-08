#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "glog.h"
#include "gmem.h"
#include "util.h"
#include "header.h"

#if defined(USE_ITHREADS) && !defined(sv_dup_inc)
# define sv_dup_inc(sv, param) SvREFCNT_inc(sv_dup(sv, param))
#endif

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) ((void)x)
#endif

static MAGIC* THX_mg_find(pTHX_ SV* sv, const MGVTBL* const vtbl) {
    MAGIC* mg;

    if (SvTYPE(sv) < SVt_PVMG)
      return NULL;

    for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
      if(mg->mg_virtual == vtbl)
        return mg;
    }
    return NULL;
}

static int THX_mg_free(pTHX_ SV* const sv, MAGIC* const mg) {
  HList* const hl = (HList*)mg->mg_ptr;
  int j, k;

  GLOG(("=X= @@@ mg_free(%p|%d)", hl, hlist_size(hl)));

  for (j = 0; j < hl->ulen; ++j) {
    HNode* hn = &hl->data[j];
    PList* pl = hn->values;
    for (k = 0; k < pl->ulen; ++k) {
      PNode* pn = &pl->data[k];
      SvREFCNT_dec((SV*)pn->ptr);
    }
  }

  hlist_destroy(hl);
  return 0;
}

static int THX_mg_dup(pTHX_ MAGIC* const mg, CLONE_PARAMS* const param) {
#ifdef USE_ITHREADS
  HList* const hl = (HList*)mg->mg_ptr;
  HList* clone;
  int j, k;

  GLOG(("=X= @@@ mg_dup(%p|%d)", hl, hlist_size(hl)));

  if (!(clone = hlist_clone(hl)))
    croak("Could not clone HList object");

  for (j = 0; j < clone->ulen; ++j) {
    HNode* hnode = &clone->data[j];
    PList* plist = hnode->values;
    for (k = 0; k < plist->ulen; ++k) {
      PNode* pnode = &plist->data[k];
      pnode->ptr = sv_dup_inc((SV*)pnode->ptr, param);
    }
  }
  mg->mg_ptr = (char *)clone;
#else
  PERL_UNUSED_ARG(mg);
  PERL_UNUSED_ARG(param);
#endif
  return 0;
}

static MGVTBL const hlist_mgvtbl = {
    NULL,        /* get */
    NULL,        /* set */
    NULL,        /* len */
    NULL,        /* clear */
    THX_mg_free, /* free */
    NULL,        /* copy */
    THX_mg_dup,  /* dup */
#ifdef MGf_LOCAL
    NULL,        /* local */
#endif
};

static SV * THX_newSV_HList(pTHX_ HList* const hl, HV * const stash) {
  MAGIC *mg;
  HV *hv;
  SV *rv;

  GLOG(("=X= Will bless new object"));

  hv = newHV();
  rv = newRV_noinc((SV*)hv);
  mg = sv_magicext((SV*)hv, NULL, PERL_MAGIC_ext, &hlist_mgvtbl, (char *)hl, 0);
  mg->mg_flags |= MGf_DUP;
  sv_bless(rv, stash);
  sv_2mortal(rv);
  return rv;
}

static HList * THX_sv_2HList(pTHX_ SV* const sv, const char *name) {
  MAGIC* mg = NULL;

  SvGETMAGIC(sv);
  if (SvROK(sv))
    mg = THX_mg_find(aTHX_ SvRV(sv), &hlist_mgvtbl);

  if (!mg)
    croak("%s is not an instance of HTTP::XSHeaders", name);

  return (HList*)mg->mg_ptr;
}

#define newSV_HList(hl, stash) \
  THX_newSV_HList(aTHX_ hl, stash)

#define sv_2HList(sv, name) \
  THX_sv_2HList(aTHX_ sv,  name)

MODULE = HTTP::XSHeaders        PACKAGE = HTTP::XSHeaders
PROTOTYPES: DISABLE


#################################################################

int
_is_xsheaders(SV* sv)
  PREINIT:
    MAGIC* mg = NULL;
  CODE:
    SvGETMAGIC(sv);
    if (SvROK(sv)) {
      mg = THX_mg_find(aTHX_ SvRV(sv), &hlist_mgvtbl);
    }
    RETVAL = mg ? 1 : 0;
  OUTPUT: RETVAL


void
new( SV* klass, ... )
  PREINIT:
    int    argc = 0;
    HList* hl = 0;
    int    j;
    SV*    pkey;
    SV*    pval;
    char*  ckey;

  CODE:
    if (!SvOK(klass) || !SvPOK(klass)) {
      XSRETURN_EMPTY;
    }

    argc = items - 1;
    if ( argc % 2 ) {
      croak("Expecting a hash as input to constructor");
    }

    GLOG(("=X= @@@ new()"));
    if (!(hl = hlist_create()))
      croak("Could not create new HList object");

    ST(0) = newSV_HList(hl, gv_stashpv(SvPV_nolen(klass), 0));

    /* create the initial list */
    for (j = 1; j <= argc; ) {
      pkey = ST(j++);

      /* did we reach the end by any chance? */
      if (j > argc) {
        break;
      }

      pval = ST(j++);
      ckey = SvPV_nolen(pkey);
      GLOG(("=X= Will set [%s] to [%s]", ckey, SvPV_nolen(pval)));
      set_value(aTHX_ hl, ckey, pval);
    }
    XSRETURN(1);


void
clone(HList* hl)
  PREINIT:
    HList* clone;
    int    j;
    int    k;
  CODE:
    GLOG(("=X= @@@ clone(%p|%d)", hl, hlist_size(hl)));

    if (!(clone = hlist_clone(hl)))
      croak("Could not clone HList object");

    ST(0) = newSV_HList(clone, SvSTASH(SvRV(ST(0))));

    /* Clone the SVs into new ones */
    for (j = 0; j < clone->ulen; ++j) {
      HNode* hnode = &clone->data[j];
      PList* plist = hnode->values;
      for (k = 0; k < plist->ulen; ++k) {
        PNode* pnode = &plist->data[k];
        pnode->ptr = newSVsv( (SV*)pnode->ptr );
      }
    }

    XSRETURN(1);


#
# Clear object, leaving it as freshly created.
#
void
clear(HList* hl, ...)
  CODE:
    GLOG(("=X= @@@ clear(%p|%d)", hl, hlist_size(hl)));
    hlist_clear(hl);


#
# Get all the keys in an existing HList.
#
void
header_field_names(HList* hl)
  PPCODE:
    GLOG(("=X= @@@ header_field_names(%p|%d), want %d",
          hl, hlist_size(hl), GIMME_V));
    hlist_sort(hl);
    PUTBACK;
    return_hlist(aTHX_ hl, "header_field_names", GIMME_V);
    SPAGAIN;


#
# init_header
#
void
init_header(HList* hl, ...)
  PREINIT:
    int    argc = 0;
    SV*    pkey;
    SV*    pval;
    STRLEN len;
    char*  ckey;

  CODE:
    GLOG(("=X= @@@ init_header(%p|%d), %d params, want %d",
          hl, hlist_size(hl), argc, GIMME_V));
    argc = items - 1;
    if (argc != 2) {
      croak("init_header needs two arguments");
    }

    /* TODO: apply this check everywhere! */
    pkey = ST(1);
    if (!SvOK(pkey) || !SvPOK(pkey)) {
      croak("init_header not called with a first string argument");
    }
    ckey = SvPV(pkey, len);
    pval = ST(2);

    if (!hlist_get(hl, ckey)) {
      set_value(aTHX_ hl, ckey, pval);
    }

#
# push_header
#
void
push_header(HList* hl, ...)
  PREINIT:
    int    argc = 0;
    int    j;
    SV*    pkey;
    SV*    pval;
    STRLEN len;
    char*  ckey;

  CODE:
    GLOG(("=X= @@@ push_header(%p|%d), %d params, want %d",
          hl, hlist_size(hl), argc, GIMME_V));

    argc = items - 1;
    if (argc % 2 != 0) {
      croak("push_header needs an even number of arguments");
    }

    for (j = 1; j <= argc; ) {
        if (j > argc) {
          break;
        }
        pkey = ST(j++);

        if (j > argc) {
          break;
        }
        pval = ST(j++);

        ckey = SvPV(pkey, len);
        set_value(aTHX_ hl, ckey, pval);
    }


#
# header
#
void
header(HList* hl, ...)
  PREINIT:
    int    argc = 0;
    int    j;
    SV*    pkey = 0;
    SV*    pval = 0;
    STRLEN len;
    char*  ckey = 0;
    HNode* n = 0;
    HList* seen = 0; /* TODO: make this more efficient; use Perl hash? */

  PPCODE:
    GLOG(("=X= @@@ header(%p|%d), %d params, want %d",
          hl, hlist_size(hl), argc, GIMME_V));

    argc = items - 1;
    do {
      if (argc == 0) {
        croak("header called with no arguments");
      }

      if (argc == 1) {
        pkey = ST(1);
        ckey = SvPV(pkey, len);
        n = hlist_get(hl, ckey);
        if (n && plist_size(n->values) > 0) {
          PUTBACK;
          return_plist(aTHX_ n->values, "header1", GIMME_V);
          SPAGAIN;
        }
        break;
      }

      if (argc % 2 != 0) {
        croak("init_header needs one or an even number of arguments");
      }

      seen = hlist_create();
      for (j = 1; j <= argc; ) {
          if (j > argc) {
            break;
          }
          pkey = ST(j++);

          if (j > argc) {
            break;
          }
          pval = ST(j++);

          ckey = SvPV(pkey, len);
          int clear = 0;
          if (! hlist_get(seen, ckey)) {
            clear = 1;
            hlist_add(seen, ckey, 0);
          }

          n = hlist_get(hl, ckey);
          if (n) {
            if (j > argc && plist_size(n->values) > 0) {
              /* Last value, return its current contents */
              PUTBACK;
              return_plist(aTHX_ n->values, "header2", GIMME_V);
              SPAGAIN;
            }
            if (clear) {
              plist_clear(n->values);
            }
          }

          set_value(aTHX_ hl, ckey, pval);
      }
      hlist_destroy(seen);
      break;
    } while (0);


#
# _header
#
# Yes, this is an internal function, but it is used by some modules!
# So far, I am aware of HTTP::Cookies as one of the culprits.
# Luckily, they only use it with a single arg, which will be the
# ONLY usecase supported, at least for now.
#
void
_header(HList* hl, ...)
  PREINIT:
    int    argc = 0;
    SV*    pkey = 0;
    STRLEN len;
    char*  ckey = 0;
    HNode* n = 0;

  PPCODE:
    GLOG(("=X= @@@ header(%p|%d), %d params, want %d",
          hl, hlist_size(hl), argc, GIMME_V));

    argc = items - 1;
    if (argc != 1) {
      croak("_header not called with one argument");
    }

    pkey = ST(1);
    if (!SvOK(pkey) || !SvPOK(pkey)) {
      croak("_header not called with one string argument");
    }
    ckey = SvPV(pkey, len);
    n = hlist_get(hl, ckey);
    if (n && plist_size(n->values) > 0) {
      PUTBACK;
      return_plist(aTHX_ n->values, "_header", GIMME_V);
      SPAGAIN;
    }


#
# remove_header
#
void
remove_header(HList* hl, ...)
  PREINIT:
    int    argc = 0;
    int    j;
    SV*    pkey;
    STRLEN len;
    char*  ckey;
    int    size = 0;
    int    total = 0;

  PPCODE:
    GLOG(("=X= @@@ remove_header(%p|%d), %d params, want %d",
          hl, hlist_size(hl), argc, GIMME_V));

    argc = items - 1;
    for (j = 1; j <= argc; ++j) {
      pkey = ST(j);
      ckey = SvPV(pkey, len);

      HNode* n = hlist_get(hl, ckey);
      if (!n) {
        continue;
      }

      size = plist_size(n->values);
      if (size > 0) {
        total += size;
        if (GIMME_V == G_ARRAY) {
          PUTBACK;
          return_plist(aTHX_ n->values, "remove_header", G_ARRAY);
          SPAGAIN;
        }
      }

      hlist_del(hl, ckey);
      GLOG(("=X= remove_header: deleted key [%s]", ckey));
    }

    if (GIMME_V == G_SCALAR) {
      GLOG(("=X= remove_header: returning count %d", total));
      EXTEND(SP, 1);
      PUSHs(sv_2mortal(newSViv(total)));
    }


#
# remove_content_headers
#
void
remove_content_headers(HList* hl, ...)
  PREINIT:
    HList* to = 0;
    HNode* n = 0;
    int    j;

  CODE:
    GLOG(("=X= @@@ remove_content_headers(%p|%d)",
          hl, hlist_size(hl)));

    if (!(to = hlist_create()))
      croak("Could not create new HList object");

    ST(0) = newSV_HList(to, SvSTASH(SvRV(ST(0))));

    for (j = 0; j < hl->ulen; ) {
      n = &hl->data[j];
      if (! header_is_entity(n->header)) {
        ++j;
        continue;
      }
      hlist_transfer_header(hl, j, to);
    }

    XSRETURN(1);


const char*
as_string(HList* hl, ...)
  PREINIT:
    char* str = 0;
    int size = 0;

  CODE:
    GLOG(("=X= @@@ as_string(%p|%d) %d", hl, hlist_size(hl), items));

    const char* cendl = "\n";
    if ( items > 1 ) {
      SV* pendl = ST(1);
      cendl = SvPV_nolen(pendl);
    }

    str = format_all(aTHX_ hl, 1, cendl, &size);
    RETVAL = str;

  OUTPUT: RETVAL

  CLEANUP:
    GMEM_DEL(str, char*, size);


const char*
as_string_without_sort(HList* hl, ...)
  PREINIT:
    char* str = 0;
    int size = 0;

  CODE:
    GLOG(("=X= @@@ as_string_without_sort(%p|%d) %d", hl, hlist_size(hl), items));

    const char* cendl = "\n";
    if ( items > 1 ) {
      SV* pendl = ST(1);
      cendl = SvPV_nolen(pendl);
    }

    str = format_all(aTHX_ hl, 0, cendl, &size);
    RETVAL = str;

  OUTPUT: RETVAL

  CLEANUP:
    GMEM_DEL(str, char*, size);


SV*
psgi_flatten(HList* hl)
  PREINIT:
    AV* av = 0;
    int j;
    int k;
  CODE:
    GLOG(("=X= @@@ psgi_flatten(%p|%d)", hl, hlist_size(hl)));
    hlist_sort(hl);
    av = newAV();
    for (j = 0; j < hl->ulen; ++j) {
      HNode* hn = &hl->data[j];
      const char* header = hn->header->name;
      PList* pl = hn->values;
      for (k = 0; k < pl->ulen; ++k) {
        PNode* pn = &pl->data[k];
        SV* value = (SV*) pn->ptr;
        av_push(av, newSVpv(header, 0));
        av_push(av, newSVsv(value));
      }
    }
    RETVAL = newRV_noinc((SV*) av);
  OUTPUT: RETVAL


SV*
psgi_flatten_without_sort(HList* hl)
  PREINIT:
    AV* av = 0;
    int j;
    int k;
  CODE:
    GLOG(("=X= @@@ psgi_flatten_without_sort(%p|%d)", hl, hlist_size(hl)));
    av = newAV();
    for (j = 0; j < hl->ulen; ++j) {
      HNode* hn = &hl->data[j];
      const char* header = hn->header->name;
      PList* pl = hn->values;
      for (k = 0; k < pl->ulen; ++k) {
        PNode* pn = &pl->data[k];
        SV* value = (SV*) pn->ptr;
        av_push(av, newSVpv(header, 0));
        av_push(av, newSVsv(value));
      }
    }
    RETVAL = newRV_noinc((SV*) av);
  OUTPUT: RETVAL


void
scan(HList* hl, SV* sub)
  PREINIT:
    int j;
    int k;

  CODE:
    GLOG(("=X= @@@ scan(%p|%d)", hl, hlist_size(hl)));

    if (!SvOK(sub) || !SvRV(sub) || SvTYPE( SvRV(sub) ) != SVt_PVCV ) {
      croak("Second argument must be a CODE reference");
    }

    hlist_sort(hl);
    for (j = 0; j < hl->ulen; ++j) {
      HNode* hn = &hl->data[j];
      const char* header = hn->header->name;
      SV* pheader = sv_2mortal(newSVpv(header, 0));
      PList* pl = hn->values;
      for (k = 0; k < pl->ulen; ++k) {
        PNode* pn = &pl->data[k];
        SV* value = (SV*) pn->ptr;

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        PUSHs( pheader );
        PUSHs( value );
        PUTBACK;
        call_sv( (SV *)SvRV(sub), G_DISCARD );

        FREETMPS;
        LEAVE;
      }
    }
