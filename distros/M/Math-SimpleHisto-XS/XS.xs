#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "histogram.h"
#include "histo_perl_interf.h"

#include "mt.h"
#include "const-c.inc"

/* More HS_* macros to be found in histogram.h. Those here
 * are more chummy with perl than those in histogram.h, which only
 * currently use the memory allocation macros of perl. */

/* Ideally, HS_ASSERT_BIN_RANGE would be part of the histogram.h
 * API, but given that we know the unsigned data type here AND have
 * access to perl's croak conveniently, that seems premature cleanup. */
#define HS_ASSERT_BIN_RANGE(self, i) STMT_START {                                     \
  if (/* i < 0 || */ i >= self->nbins) {                                              \
    croak("Bin %u outside histogram range (highest bin index is %u", i, self->nbins); \
  } } STMT_END

#define HS_CLONE_GET_CLASS(classname, src, where) STMT_START {                        \
  if (!sv_isobject(src))                                                              \
    croak("Cannot call " #where "() on non-object");                                  \
  classname = sv_reftype(SvRV(src), TRUE);                                            \
  if ( !sv_isobject(src) || (SvTYPE(SvRV(src)) != SVt_PVMG) )                         \
    croak( "%s::" #where "() -- self is not a blessed SV reference", classname);      \
  } STMT_END


/* The following couple of lines are for the RNG, taken from Math::Random::MT */
typedef struct mt* Math__SimpleHisto__XS__RNG;

void*
U32ArrayPtr (pTHX_ int n)
{
  SV * sv = sv_2mortal( NEWSV( 0, n*sizeof(U32) ) );
  return SvPVX(sv);
}


MODULE = Math::SimpleHisto::XS    PACKAGE = Math::SimpleHisto::XS

REQUIRE: 2.2201

INCLUDE: const-xs.inc

INCLUDE: XS/rdgen.xs

INCLUDE: XS/construction.xs

INCLUDE: XS/bins.xs

INCLUDE: XS/aggregate.xs

void
DESTROY(self)
    simple_histo_1d* self
  CODE:
    HS_DEALLOCATE(self);

void
multiply_constant(self, factor = 1.)
    simple_histo_1d* self
    double factor
  CODE:
    if (factor < 0.)
      croak("Cannot multiply histogram with negative value %f", factor);
    histo_multiply_constant(self, factor);

void
add_histogram(self, operand)
    simple_histo_1d* self
    simple_histo_1d* operand
  ALIAS:
    subtract_histogram = 1
    multiply_histogram = 2
    divide_histogram = 3
  PREINIT:
    bool ok;
  CODE:
    if (ix == 0)
      ok = histo_add_histogram(self, operand);
    else if (ix == 1)
      ok = histo_subtract_histogram(self, operand);
    else if (ix == 2)
      ok = histo_multiply_histogram(self, operand);
    else
      ok = histo_divide_histogram(self, operand);

    if (!ok) {
      char *reason;
      if (ix == 0)
        reason = "add";
      else if (ix == 1)
        reason = "subtract";
      else if (ix == 2)
        reason = "multiply";
      else
        reason = "divide";
      croak("Failed to %s incompatible histogram. Binning not the same?", reason);
    }

void
normalize(self, normalization = 1.)
    simple_histo_1d* self
    double normalization
  CODE:
    if (normalization <= 0.)
      croak("Cannot normalize to %f", normalization);
    if (self->total == 0.)
      croak("Cannot normalize histogram without data");
    histo_multiply_constant(self, normalization / self->total);

void
fill(self, ...)
    simple_histo_1d* self
  CODE:
    if (items == 2) {
      SV* const x_tmp = ST(1);
      SvGETMAGIC(x_tmp);
      if (SvROK(x_tmp) && SvTYPE(SvRV(x_tmp)) == SVt_PVAV) {
        int i, n;
        SV** sv;
        double* x;
        AV* av = (AV*)SvRV(x_tmp);
        n = av_len(av);
        Newx(x, n+1, double);
        for (i = 0; i <= n; ++i) {
          sv = av_fetch(av, i, 0);
          if (UNLIKELY( sv == NULL )) {
            Safefree(x);
            croak("Shouldn't happen");
          }
          x[i] = SvNV(*sv);
        }
        histo_fill(self, n+1, x, NULL);
        Safefree(x);
      }
      else {
        double x = SvNV(ST(1));
        histo_fill(self, 1, &x, NULL);
      }
    }
    else if (items == 3) {
      SV* const x_tmp = ST(1);
      SV* const w_tmp = ST(2);
      SvGETMAGIC(x_tmp);
      SvGETMAGIC(w_tmp);
      if (SvROK(x_tmp) && SvTYPE(SvRV(x_tmp)) == SVt_PVAV) {
        int i, n;
        SV** sv;
        double *x, *w;
        AV *xav, *wav;
        if (UNLIKELY( !SvROK(w_tmp) || SvTYPE(SvRV(x_tmp)) != SVt_PVAV )) {
          croak("Need array of weights if using array of x values");
        }
        xav = (AV*)SvRV(x_tmp);
        wav = (AV*)SvRV(w_tmp);
        n = av_len(xav);
        if (UNLIKELY( av_len(wav) != n )) {
          croak("x and w array lengths differ");
        }

        Newx(x, n+1, double);
        Newx(w, n+1, double);
        for (i = 0; i <= n; ++i) {
          sv = av_fetch(xav, i, 0);
          if (UNLIKELY( sv == NULL )) {
            Safefree(x);
            Safefree(w);
            croak("Shouldn't happen");
          }
          x[i] = SvNV(*sv);

          sv = av_fetch(wav, i, 0);
          if (UNLIKELY( sv == NULL )) {
            Safefree(x);
            Safefree(w);
            croak("Shouldn't happen");
          }
          w[i] = SvNV(*sv);
        }
        histo_fill(self, n+1, x, w);
        Safefree(x);
        Safefree(w);
      }
      else {
        double x = SvNV(ST(1));
        double w = SvNV(ST(2));
        histo_fill(self, 1, &x, &w);
      }
    }
    else {
      croak("Invalid number of arguments to fill(self, ...)");
    }

void
fill_by_bin(self, ...)
    simple_histo_1d* self
  CODE:
    HS_INVALIDATE_CUMULATIVE(self);
    if (items == 2) {
      SV* const x_tmp = ST(1);
      SvGETMAGIC(x_tmp);
      if (SvROK(x_tmp) && SvTYPE(SvRV(x_tmp)) == SVt_PVAV) {
        int i, n;
        SV** sv;
        int* ibin;
        AV* av = (AV*)SvRV(x_tmp);
        n = av_len(av);
        Newx(ibin, n+1, int);
        for (i = 0; i <= n; ++i) {
          sv = av_fetch(av, i, 0);
          if (sv == NULL) {
            Safefree(ibin);
            croak("Shouldn't happen");
          }
          ibin[i] = SvIV(*sv);
        }
        histo_fill_by_bin(self, n+1, ibin, NULL);
        Safefree(ibin);
      }
      else {
        const int ibin = SvUV(ST(1));
        histo_fill_by_bin(self, 1, &ibin, NULL);
      }
    }
    else if (items == 3) {
      SV* const x_tmp = ST(1);
      SV* const w_tmp = ST(2);
      SvGETMAGIC(x_tmp);
      SvGETMAGIC(w_tmp);
      if (SvROK(x_tmp) && SvTYPE(SvRV(x_tmp)) == SVt_PVAV) {
        int i, n;
        SV** sv;
        int *ibin;
        double *w;
        AV *xav, *wav;
        if (!SvROK(w_tmp) || SvTYPE(SvRV(x_tmp)) != SVt_PVAV) {
          croak("Need array of weights if using array of bin numbers");
        }
        xav = (AV*)SvRV(x_tmp);
        wav = (AV*)SvRV(w_tmp);
        n = av_len(xav);
        if (av_len(wav) != n) {
          croak("ibin and w array lengths differ");
        }

        Newx(ibin, n+1, int);
        Newx(w, n+1, double);
        for (i = 0; i <= n; ++i) {
          sv = av_fetch(xav, i, 0);
          if (sv == NULL) {
            Safefree(ibin);
            Safefree(w);
            croak("Shouldn't happen");
          }
          ibin[i] = SvIV(*sv);

          sv = av_fetch(wav, i, 0);
          if (sv == NULL) {
            Safefree(ibin);
            Safefree(w);
            croak("Shouldn't happen");
          }
          w[i] = SvNV(*sv);
        }
        histo_fill_by_bin(self, n+1, ibin, w);
        Safefree(ibin);
        Safefree(w);
      }
      else {
        int ibin = SvIV(ST(1));
        double w = SvNV(ST(2));
        histo_fill_by_bin(self, 1, &ibin, &w);
      }
    }
    else {
      croak("Invalid number of arguments to fill(self, ...)");
    }


double
min(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->min;
  OUTPUT: RETVAL

double
max(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->max;
  OUTPUT: RETVAL

double
width(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->width;
  OUTPUT: RETVAL

double
overflow(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->overflow;
  OUTPUT: RETVAL

double
underflow(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->underflow;
  OUTPUT: RETVAL

double
total(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->total;
  OUTPUT: RETVAL

unsigned int
nbins(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->nbins;
  OUTPUT: RETVAL

unsigned int
highest_bin(self)
    simple_histo_1d* self
  CODE:
    /* I know. Trivial, but convienient! */
    RETVAL = self->nbins-1;
  OUTPUT: RETVAL

double
binsize(self, ibin = 0)
    simple_histo_1d* self
    unsigned int ibin
  CODE:
    HS_ASSERT_BIN_RANGE(self, ibin);
    if (self->bins == NULL)
      RETVAL = self->binsize;
    else
      RETVAL = self->bins[ibin+1] - self->bins[ibin];
  OUTPUT: RETVAL

unsigned int
nfills(self)
    simple_histo_1d* self
  CODE:
    RETVAL = self->nfills;
  OUTPUT: RETVAL


void
all_bin_contents(self)
    simple_histo_1d* self
  PREINIT:
    SV* rv;
  PPCODE:
    rv = histo_data_av(aTHX_ self);
    XPUSHs(sv_2mortal(rv));

void
set_all_bin_contents(self, new_data)
    simple_histo_1d* self
    AV* new_data
  PREINIT:
    unsigned int n, i;
    double* data;
    SV** elem;
  CODE:
    /* While this would be nicer in the histogram API, it will be much faster
     * to access the AV* on the fly instead of doing blanket conversion to remove
     * dependence on perl data structures, so this stays here for the time being. */
    HS_INVALIDATE_CUMULATIVE(self);
    n = self->nbins;
    if ((unsigned int)(av_len(new_data)+1) != n) {
      croak("Length of new data is %u, size of histogram is %u. That doesn't work.", (unsigned int)(av_len(new_data)+1), n);
    }
    data = self->data;
    for (i = 0; i < n; ++i) {
      elem = av_fetch(new_data, i, 0);
      if (elem == NULL) {
        croak("Shouldn't happen");
      }
      self->total -= data[i];
      data[i] = SvNV(*elem);
      self->total += data[i];
    }

double
bin_content(self, ibin)
    simple_histo_1d* self
    unsigned int ibin
  CODE:
    HS_ASSERT_BIN_RANGE(self, ibin);
    RETVAL = self->data[ibin];
  OUTPUT: RETVAL

void
set_bin_content(self, ibin, content)
    simple_histo_1d* self
    unsigned int ibin
    double content
  PPCODE:
    /* Would be nicer in the API, but again, this is faster. */
    HS_ASSERT_BIN_RANGE(self, ibin);
    HS_INVALIDATE_CUMULATIVE(self);
    self->total += content - self->data[ibin];
    self->data[ibin] = content;

void
set_underflow(self, content)
    simple_histo_1d* self
    double content
  PPCODE:
    /* This doesn't invalidate the INTERNAL cumulative histo */
    self->underflow = content;

void
set_overflow(self, content)
    simple_histo_1d* self
    double content
  PPCODE:
    /* This doesn't invalidate the INTERNAL cumulative histo */
    self->overflow = content;


void
set_nfills(self, nfills)
    simple_histo_1d* self
    unsigned int nfills
  PPCODE:
    /* This doesn't invalidate the INTERNAL cumulative histo */
    self->nfills = nfills;


#void
#binary_dump(self)
#    simple_histo_1d* self
#  PREINIT:
#    char* out;
#    SV* outSv;
#    double* tmp;
#    unsigned int size;
#  PPCODE:
#    size = sizeof(simple_histo_1d) + sizeof(double)*self->nbins;
#    outSv = newSVpvs("");
#    SvGROW(outSv, size+1);
#    printf("   %u\n", SvLEN(outSv));
#    out = SvPVX(outSv);
#    SvLEN_set(outSv, size);
#    printf("%u\n", SvLEN(outSv));
#    /*Newx(out, size+1, char);*/
#    tmp = self->data;
#    self->data = NULL;
#    Copy(self, out, sizeof(simple_histo_1d), char);
#    Copy(tmp, out+sizeof(simple_histo_1d), sizeof(double)*self->nbins, char);
#    out[size] = '\0';
#    printf("%u\n", SvLEN(outSv));
#    self->data = tmp;
#    XPUSHs(sv_2mortal(outSv));


void
rand(self, ...)
    simple_histo_1d* self
  PREINIT:
    double rndval;
    double retval;
    SV* rngsv;
    Math__SimpleHisto__XS__RNG rng;
    unsigned int ibin;
  PREINIT:
    simple_histo_1d* cum_hist;
  PPCODE:
    if (items > 1) {
      rngsv = ST(1);
    }
    else {
      rngsv = get_sv("Math::SimpleHisto::XS::RNG::Gen", 0);
      if (rngsv == 0) {
        croak("Cannot find default random number generator!");
      }
    }
    if (sv_derived_from(rngsv, "Math::SimpleHisto::XS::RNG")) {
      IV tmp = SvIV((SV*)SvRV(rngsv));
      rng = INT2PTR(Math__SimpleHisto__XS__RNG, tmp);
    }
    else
      Perl_croak(aTHX_ "%s: %s is not of type %s",
                  "Math::SimpleHisto::XS::rand",
                  "rng", "Math::SimpleHisto::XS::RNG");
    rndval = mt_genrand(rng);

    /* Get the properly normalized internal cumulative */
    HS_ASSERT_CUMULATIVE(self);
    cum_hist = self->cumulative_hist;

    /* This all operates on the cumulative histogram */
    ibin = rndval < cum_hist->data[0] ? 0 : find_bin_nonconstant(rndval, cum_hist->nbins, cum_hist->data);
    if (cum_hist->bins == 0) { /* constant bin size */
      retval = cum_hist->min + cum_hist->binsize * (double)(ibin+1);
      if (rndval > cum_hist->data[ibin]) {
        retval += cum_hist->binsize * (rndval - cum_hist->data[ibin])
                                      / (cum_hist->data[ibin+1] - cum_hist->data[ibin]);
      }
    }
    else { /* variable bin size */
      retval = cum_hist->bins[ibin+1];
      if (rndval > cum_hist->data[ibin]) {
        retval += (cum_hist->bins[ibin+1] - cum_hist->bins[ibin])
                  * (rndval - cum_hist->data[ibin])
                  / (cum_hist->data[ibin+1] - cum_hist->data[ibin]);
      }
    }
    XPUSHs(sv_2mortal(newSVnv(retval)));


void
_get_info(self)
    simple_histo_1d* self
  PREINIT:
    SV* data_ary;
    SV* bins_ary;
  PPCODE:
    /* min, max, nbins, nfills, overflow, underflow, dataref, binsref*/
    EXTEND(SP, 8);
    mPUSHn(self->min);
    mPUSHn(self->max);
    mPUSHu(self->nbins);
    mPUSHu(self->nfills);
    mPUSHn(self->overflow);
    mPUSHn(self->underflow);
    data_ary = histo_data_av(aTHX_ self);
    XPUSHs(sv_2mortal(data_ary));
    if (self->bins == NULL)
      bins_ary = &PL_sv_undef;
    else
      bins_ary = sv_2mortal(histo_bins_av(aTHX_ self));
    XPUSHs(bins_ary);

