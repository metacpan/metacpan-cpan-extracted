#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "assert.h"
#include "ppport.h"

#include "perl_type_tools.h"

#include "mh_histogram.h"

#define ASSERT_BIN_RANGE(axis, ibin) \
    STMT_START { \
      if (ibin < 1 || ibin > MH_AXIS_NBINS(axis)) \
        croak("Bin %u outside axis bin range (min: 1, max: %u)", MH_AXIS_NBINS(axis)); \
    } STMT_END

#define ASSERT_BIN_RANGE_WITH_OVERFLOW(axis, ibin) \
    STMT_START { \
      if (ibin < 0 || ibin > MH_AXIS_NBINS(axis)+1) \
        croak("Bin %u outside axis bin range (incl. under- and overflow: min: 0, max: %u)", MH_AXIS_NBINS(axis)+1); \
    } STMT_END


/* The following are flags that we use on the userdata slot of an axis.
 * Right now, that's just using the first bit (take care not to use more than 32...)
 * indicating that if set, the axis is owned by a histogram. If that's the case,
 * using that axis in another histogram will create a clone of the axis.
 * At the same time, any explicit Perl-level reference to the axis will not free
 * the underlying C object if that bit is set as the Perl-level reference goes out of
 * scope. */
#define F_AXIS_OWNED_BY_HIST 1

static SV *
axis_to_hashref(pTHX_ mh_axis_t *axis)
{
  SV *rv;
  HV *hash;
  hash = newHV();

  if (MH_AXIS_ISFIXBIN(axis)) {
    if ( ! hv_stores(hash, "nbins", newSVuv(MH_AXIS_NBINS(axis))) )
      croak("hv_stores nbins failed");
    if ( ! hv_stores(hash, "min", newSVnv(MH_AXIS_MIN(axis))) )
      croak("hv_stores min failed");
    if ( ! hv_stores(hash, "max", newSVnv(MH_AXIS_MAX(axis))) )
      croak("hv_stores max failed");
  }
  else {
    unsigned int i, n;
    AV *bin_av;
    double *bins = axis->bins;
    n = MH_AXIS_NBINS(axis);
    bin_av = newAV();
    if ( ! hv_stores(hash, "bins", newRV_noinc((SV *)bin_av)) )
      croak("hv_stores bins failed");
    av_extend(bin_av, n);
    for (i = 0; i <= n; ++i)
      av_store(bin_av, i, newSVnv(bins[i]));
  }
  rv = newRV_noinc((SV *)hash);

  return rv;
}

static mh_axis_t *
hash_to_axis(pTHX_ HV *hash)
{
  unsigned int nbins;
  SV *tmp;
  SV **svptr;
  mh_axis_t *rv;

  if (hv_exists(hash, "bins", 4)) { /* varbins */
    AV *bin_av;
    tmp = *hv_fetchs(hash, "bins", 0);
    DEREF_RV_TO_AV(bin_av, tmp);
    if (bin_av == NULL)
      croak("'bins' entry is not an array reference");
    nbins = av_len(bin_av);
    rv = mh_axis_create( nbins, MH_AXIS_OPT_VARBINS );
    if (rv == NULL)
      croak("Cannot create Math::Histogram::Axis! Invalid number of bins or out of memory.");
    av_to_double_ary(aTHX_ bin_av, rv->bins);
    /* FIXME include same bin order sanity check as for the normal constructor? */
    mh_axis_init( rv, rv->bins[0], rv->bins[nbins] );
  }
  else { /* fixed width bins */
    double min, max;
    svptr = hv_fetchs(hash, "nbins", 0);
    if (svptr == NULL)
      croak("Missing 'bins' and 'nbins' hash entries");
    nbins = SvUV(*svptr);
    svptr = hv_fetchs(hash, "min", 0);
    if (svptr == NULL)
      croak("Missing 'min' hash entry");
    min = SvNV(*svptr);
    svptr = hv_fetchs(hash, "max", 0);
    if (svptr == NULL)
      croak("Missing 'max' hash entry");
    max = SvNV(*svptr);
    if (min > max) {
      double tmp = min;
      min = max;
      max = tmp;
    }
    rv = mh_axis_create( nbins, MH_AXIS_OPT_FIXEDBINS );
    if (rv == NULL)
      croak("Cannot create Math::Histogram::Axis! Invalid bin number or out of memory.");
    mh_axis_init( rv, min, max );
  }

  return rv;
}

/*
 * FIXME This file has a bunch of hardcoded class names for non-constructor methods
 *       that return objects. That needs to be fixed!
 */

MODULE = Math::Histogram    PACKAGE = Math::Histogram

PROTOTYPES: DISABLE

REQUIRE: 2.21

INCLUDE: XS/Axis.xs

INCLUDE: XS/Histogram.xs
