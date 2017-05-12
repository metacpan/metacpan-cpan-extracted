#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include "EXTERN.h"
#include "perl.h"

#include "glog.h"
#include "gmem.h"
#include "header.h"
#include "util.h"

/* Append string str at pos in buf. */
static int string_append(char* buf, int pos, const char* str);

/* Cleanup string str (as used in as_string), leaving cleaned up result in */
/* buf, with maximum length len; use newl as new line terminator. */
static int string_cleanup(const char* str, char* buf, int len, const char* newl);

void set_value(pTHX_ HList* h, const char* ckey, SV* pval) {
  SV *deref;
  AV *array;

  if ( ! SvOK(pval) ) {
    GLOG(("=X= deleting [%s]", ckey));
    hlist_del( h, ckey );
    return;
  }

  if ( ! SvROK(pval) ) {
    set_scalar(aTHX_ h, ckey, pval);
    return;
  }

  deref = SvRV(pval);
  if (SvTYPE(deref) != SVt_PVAV) {
    set_scalar(aTHX_ h, ckey, pval);
    return;
  }

  array = (AV*) deref;
  set_array(aTHX_ h, ckey, array);
}

void set_scalar(pTHX_ HList* h, const char* ckey, SV* pval) {
  hlist_add(h, ckey, newSVsv(pval));
  GLOG(("=X= set scalar [%s] => [%s]", ckey, SvPV_nolen(pval)));
}

void set_array(pTHX_ HList* h, const char* ckey, AV* pval) {
  int count = av_len(pval) + 1;
  int j;
  for (j = 0; j < count; ++j) {
    SV** svp = av_fetch(pval, j, 0);
    GLOG(("=X= set array %2d [%s]", j, ckey));
    set_value(aTHX_ h, ckey, *svp);
  }
}

void return_hlist(pTHX_ HList* list, const char* func, int want) {
  dSP;
  int count;

  if (want == G_VOID) {
    GLOG(("=X= %s: no return expected, nothing will be returned", func));
    return;
  }

  count = hlist_size(list);

  if (want == G_SCALAR) {
    GLOG(("=X= %s: returning number of elements", func));
    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSViv(count)));
    PUTBACK;
  }

  if (count <= 0) {
    GLOG(("=X= %s: hlist is empty, returning nothing", func));
    return;
  }

  if (want == G_ARRAY) {
    int num = 0;
    int j;

    GLOG(("=X= %s: returning as %d elements", func, count));
    EXTEND(SP, count);

    for (j = 0; j < list->ulen; ++j) {
      HNode* node = &list->data[j];
      const char* s = node->header->name;
      ++num;

      GLOG(("=X= %s: returning %2d - str [%s]", func, num, s));
      PUSHs(sv_2mortal(newSVpv(s, 0)));
    }
    PUTBACK;
  }
}

void return_plist(pTHX_ PList* list, const char* func, int want) {
  int count;
  dSP;

  if (want == G_VOID) {
    GLOG(("=X= %s: no return expected, nothing will be returned", func));
    return;
  }

  count = plist_size(list);

  if (count <= 0) {
    if (want == G_ARRAY) {
      GLOG(("=X= %s: plist is empty, wantarray => 0", func));
      EXTEND(SP, 1);
      PUSHs(sv_2mortal(newSViv(0)));
      PUTBACK;
    } else {
      GLOG(("=X= %s: plist is empty, returning nothing", func));
    }
    return;
  }

  GLOG(("=X= %s: returning %d values", func, count));

  if (want == G_SCALAR) {
    GLOG(("=X= %s: returning as single string", func));
    EXTEND( SP, 1 );

    if ( count == 1 ) {
      /*
       * handle returning one value, useful when storing an object
       */
      PNode* node = &list->data[0];
      PUSHs( (SV*)node->ptr );

    } else {

      /*
       * concatenate values, useful for full header strings
       */

      int size = 16;
      int j;
      for (j = 0; j < list->ulen; ++j) {
        PNode* node = &list->data[j];
        STRLEN len;
        SvPV( (SV*)node->ptr, len );  /* We just need the length */
        size += len + 2;
      }

      {
        char* rstr;
        int rpos = 0;
        int num = 0;
        int j;
        GMEM_NEW(rstr, char*, size);
        for (j = 0; j < list->ulen; ++j) {
          PNode* node = &list->data[j];
          ++num;

          STRLEN len;
          char* str = SvPV( (SV*)node->ptr, len );
          GLOG(("=X= %s: returning %2d - str [%s]", func, num, str));
          if (rpos > 0) {
            rstr[rpos++] = ',';
            rstr[rpos++] = ' ';
          }

          memcpy(rstr + rpos, str, len);
          rpos += len;
        }

        rstr[rpos] = '\0';
        PUSHs(sv_2mortal(newSVpv(rstr, rpos)));
        GMEM_DEL(rstr, char*, size);
      }
    }

    PUTBACK;
  }

  if (want == G_ARRAY) {
    int num = 0;
    int j;
    GLOG(("=X= %s: returning as %d elements", func, count));
    EXTEND(SP, count);
    for (j = 0; j < list->ulen; ++j) {
      PNode* node = &list->data[j];
      ++num;

      PUSHs( (SV*)node->ptr );
    }

    PUTBACK;
  }
}

char* format_all(pTHX_ HList* h, int sort, const char* endl, int* size) {
  int le = strlen(endl);
  int j;
  *size = 64;

  if (sort) {
    hlist_sort(h);
  }

  for (j = 0; j < h->ulen; ++j) {
    HNode* hn = &h->data[j];
    const char* header = hn->header->name;
    int lh = strlen(header);
    PList* pl = hn->values;
    int k;
    for (k = 0; k < pl->ulen; ++k) {
      PNode* pn = &pl->data[k];
      const char* value = SvPV_nolen( (SV*) pn->ptr );
      int lv = strlen(value);
      *size += lh + 2 + lv + lv * le;
    }
  }

  {
    char* rstr;
    int rpos = 0;
    GMEM_NEW(rstr, char*, *size);
    for (j = 0; j < h->ulen; ++j) {
      HNode* hn = &h->data[j];
      const char* header = hn->header->name;
      int lh = strlen(header);
      PList* pl = hn->values;
      int k;
      PNode *pn;
      const char *value;
      for (k = 0; k < pl->ulen; ++k) {
        memcpy(rstr + rpos, header, lh);
        rpos += lh;
        rstr[rpos++] = ':';
        rstr[rpos++] = ' ';

        pn = &pl->data[k];
        value = SvPV_nolen( (SV*) pn->ptr );
        rpos += string_cleanup(value, rstr + rpos, *size - rpos, endl);
      }
    }

    rstr[rpos] = '\0';
    GLOG(("=X= format_all (%d/%d) [%s]", rpos, *size, rstr));
    return rstr;
  }
}

static int string_append(char* buf, int pos, const char* str) {
  int k;
  for (k = 0; str[k] != '\0'; ++k) {
    buf[pos++] = str[k];
  }
  return pos;
}

static int string_cleanup(const char* str, char* buf, int len, const char* newl) {
  int pos = 0;
  int last_nonblank = -1;
  int saw_newline = 0;
  int j;
  for (j = 0; str[j] != '\0'; ++j) {
    if (pos >= len) {
      break;
    }
    if (isspace(str[j])) {
      if (saw_newline) {
        /* ignore */
      } else {
        if (str[j] == '\n') {
          pos = string_append(buf, pos, newl);
          saw_newline = 1;
          last_nonblank = pos-1;
        } else {
          buf[pos++] = str[j];
        }
      }
    } else {
      if (saw_newline) {
        buf[pos++] = ' ';
      }
      buf[pos++] = str[j];
      last_nonblank = pos-1;
      saw_newline = 0;
    }
  }

  if (! saw_newline) {
    pos = string_append(buf, last_nonblank+1, newl);
    last_nonblank = pos-1;
  }
  buf[++last_nonblank] = '\0';
  return last_nonblank;

  /*
   * This is the original code in Perl, for reference.

sub _process_newline {
    local $_ = shift;
    my $endl = shift;
    # must handle header values with embedded newlines with care
    s/\s+$//;        # trailing newlines and space must go
    s/\n(\x0d?\n)+/\n/g;     # no empty lines
    s/\n([^\040\t])/\n $1/g; # intial space for continuation
    s/\n/$endl/g;    # substitute with requested line ending
    $_;

  */
}
