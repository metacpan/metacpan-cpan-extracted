#ifndef perl_type_tools_h_
#define perl_type_tools_h_

#include "mh_axis.h"

#define DEREF_RV_TO_AV(av, sv) \
        STMT_START { \
                SvGETMAGIC(sv); \
                if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) \
                    av = (AV*)SvRV(sv); \
                else \
                  av = NULL; \
        } STMT_END

#define HV_FETCHS_FATAL(svptr, hv, key) \
        STMT_START { \
                svptr = hv_fetchs(hv, key, 0); \
                if (svptr == NULL) \
                  croak("Failed to get key '%s' from hash", key); \
        } STMT_END

STATIC void
av_to_double_ary(pTHX_ AV *in, double *out)
{
  I32 thisN;
  SV** elem;
  I32 i;

  thisN = av_len(in)+1;
  if (thisN == 0)
    return;

  for (i = 0; i < thisN; ++i) {
    if (NULL == (elem = av_fetch(in, i, 0)))
      croak("Could not fetch element %i from array", i);
    else if (SvROK(*elem)) {
      croak("Element %i in array is a reference! (Expected number)", i);
    }
    else {
      out[i] = SvNV(*elem);
    }
  }
}


STATIC void
av_to_unsigned_int_ary(pTHX_ AV *in, unsigned int *out)
{
  I32 thisN;
  SV** elem;
  I32 i;

  thisN = av_len(in)+1;
  if (thisN == 0)
    return;

  for (i = 0; i < thisN; ++i) {
    if (NULL == (elem = av_fetch(in, i, 0)))
      croak("Could not fetch element from array");
    else
      out[i] = SvUV(*elem);
  }
}


STATIC void
unsigned_int_ary_to_av(pTHX_ unsigned int n, unsigned int *in, AV **out)
{
  unsigned int i;
  *out = newAV();
  av_fill(*out, n-1);
  for (i = 0; i < n; ++i) {
    av_store(*out, i, newSVuv(in[i]));
  }
}


STATIC void
double_ary_to_av(pTHX_ unsigned int n, double *in, AV **out)
{
  unsigned int i;
  *out = newAV();
  av_fill(*out, n-1);
  for (i = 0; i < n; ++i) {
    av_store(*out, i, newSVnv(in[i]));
  }
}


STATIC mh_axis_t **
av_to_axis_ary(pTHX_ AV *in, I32 n)
{
  SV **elem;
  SV *sv;
  I32 i;
  mh_axis_t **out;

  if (n == 0)
    return NULL;

  out = (mh_axis_t **)malloc(sizeof(mh_axis_t *) * n);

  for (i = 0; i < n; ++i) {
    if (NULL == (elem = av_fetch(in, i, 0)))
      croak("Could not fetch element from array");
    else {
      /* inlined typemap... */
      sv = *elem;
      if( sv_isobject(sv) && (SvTYPE(SvRV(sv)) == SVt_PVMG) )
        out[i] = (mh_axis_t *)SvIV((SV*)SvRV( sv ));
      else {
        free(out);
        croak("Element with index %u of input array reference is not a Math::Histogram::Axis object!", i);
      }
    }
  }

  return out;
}


#endif
