#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <histo/histo.h>
#include <histo/histo2d.h>
#include <histo/fit.h>
#include <histo/sketch.h>
#include <histo/cli.h>
#include <histo/types.h>
#include <histo/version.h>


MODULE = Math::Histo    PACKAGE = Math::Histo    PREFIX = histo_xs_

PROTOTYPES: DISABLE

const char *
libhisto_version()
    CODE:
        RETVAL = HISTO_VERSION_STRING;
    OUTPUT:
        RETVAL

histo_t *
_create_uniform(CLASS, uint32_t nbins, double min, double max, uint32_t flags=0)
    char *CLASS
    CODE:
        (void)CLASS;
        RETVAL = histo_create_uniform(nbins, min, max, flags);
        if (!RETVAL) {
            croak("Math::Histo: failed to create uniform histogram (invalid parameters)");
        }
    OUTPUT:
        RETVAL

histo_t *
_create_variable(CLASS, SV *edges_ref, uint32_t flags=0)
    char *CLASS
    CODE:
        (void)CLASS;
        if (!SvROK(edges_ref) || SvTYPE(SvRV(edges_ref)) != SVt_PVAV) {
            croak("Math::Histo: edges must be an array reference of numbers");
        }
        AV *av = (AV*)SvRV(edges_ref);
        SSize_t n_edges = av_top_index(av) + 1;
        if (n_edges < 2) {
            croak("Math::Histo: variable binning requires at least 2 edges");
        }
        double *edges = (double*)malloc((size_t)n_edges * sizeof(double));
        if (!edges) {
            croak("Math::Histo: memory allocation failure");
        }
        for (SSize_t i = 0; i < n_edges; i++) {
            SV **item = av_fetch(av, i, 0);
            edges[i] = (item && SvOK(*item)) ? SvNV(*item) : 0.0;
        }
        RETVAL = histo_create_variable((uint32_t)(n_edges - 1), edges, flags);
        free(edges);
        if (!RETVAL) {
            croak("Math::Histo: failed to create variable histogram (edges must be strictly monotonically increasing)");
        }
    OUTPUT:
        RETVAL

histo_t *
_clone(histo_t *self)
    CODE:
        if (!self) croak("Math::Histo::clone: NULL histogram");
        RETVAL = histo_clone(self, false);
        if (!RETVAL) {
            croak("Math::Histo::clone: failed to clone histogram");
        }
    OUTPUT:
        RETVAL

histo_t *
_deserialize_binary(CLASS, SV *buf_sv)
    char *CLASS
    CODE:
        (void)CLASS;
        STRLEN len;
        const char *buf = SvPVbyte(buf_sv, len);
        histo_t *out = NULL;
        histo_status_t st = histo_deserialize_binary(buf, len, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::from_binary: deserialization failed (corrupt or invalid blob)");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
_deserialize_json(CLASS, SV *json_sv)
    char *CLASS
    CODE:
        (void)CLASS;
        STRLEN len;
        const char *str = SvPV(json_sv, len);
        histo_t *out = NULL;
        histo_status_t st = histo_deserialize_json(str, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::from_json: JSON deserialization failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL


void
DESTROY(histo_t *self)
    CODE:
        if (self) {
            histo_destroy(self);
        }

int
fill(histo_t *self, double x, double weight=1.0)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_status_t st;
        if (weight == 1.0) {
            st = histo_fill(self, x);
        } else {
            st = histo_fill_w(self, x, weight);
        }
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
fill_n(histo_t *self, SV *x_ref, SV *w_ref=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        if (!SvROK(x_ref) || SvTYPE(SvRV(x_ref)) != SVt_PVAV) {
            croak("Math::Histo::fill_n: x values must be an array reference");
        }
        AV *x_av = (AV*)SvRV(x_ref);
        SSize_t n = av_top_index(x_av) + 1;
        if (n == 0) XSRETURN_IV(0);

        AV *w_av = NULL;
        if (w_ref && SvOK(w_ref)) {
            if (!SvROK(w_ref) || SvTYPE(SvRV(w_ref)) != SVt_PVAV) {
                croak("Math::Histo::fill_n: weights must be an array reference");
            }
            w_av = (AV*)SvRV(w_ref);
            if (av_top_index(w_av) + 1 != n) {
                croak("Math::Histo::fill_n: x and weights array lengths must match");
            }
        }

        double *x_arr = (double*)malloc((size_t)n * sizeof(double));
        double *w_arr = w_av ? (double*)malloc((size_t)n * sizeof(double)) : NULL;
        if (!x_arr || (w_av && !w_arr)) {
            free(x_arr);
            free(w_arr);
            croak("Math::Histo::fill_n: memory allocation failure");
        }

        for (SSize_t i = 0; i < n; i++) {
            SV **xi = av_fetch(x_av, i, 0);
            x_arr[i] = (xi && SvOK(*xi)) ? SvNV(*xi) : 0.0;
            if (w_av) {
                SV **wi = av_fetch(w_av, i, 0);
                w_arr[i] = (wi && SvOK(*wi)) ? SvNV(*wi) : 1.0;
            }
        }

        histo_status_t st = histo_fill_n(self, (size_t)n, x_arr, w_arr);
        free(x_arr);
        free(w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
fill_packed_f64(histo_t *self, SV *packed_x, SV *packed_w=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        STRLEN x_len;
        const char *x_bytes = SvPVbyte(packed_x, x_len);
        if (x_len % sizeof(double) != 0) {
            croak("Math::Histo::fill_packed_f64: packed x byte length must be multiple of 8 (double)");
        }
        size_t n = x_len / sizeof(double);
        if (n == 0) XSRETURN_IV(0);

        const double *x_arr = (const double *)x_bytes;
        const double *w_arr = NULL;

        if (packed_w && SvOK(packed_w)) {
            STRLEN w_len;
            const char *w_bytes = SvPVbyte(packed_w, w_len);
            if (w_len != x_len) {
                croak("Math::Histo::fill_packed_f64: weights length must match x length");
            }
            w_arr = (const double *)w_bytes;
        }

        histo_status_t st = histo_fill_n(self, n, x_arr, w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

uint64_t
num_entries(histo_t *self)
    CODE:
        RETVAL = histo_num_entries(self);
    OUTPUT:
        RETVAL

double
total_weight(histo_t *self)
    CODE:
        RETVAL = histo_total_weight(self);
    OUTPUT:
        RETVAL

double
underflow_weight(histo_t *self)
    CODE:
        RETVAL = histo_underflow(self);
    OUTPUT:
        RETVAL

double
overflow_weight(histo_t *self)
    CODE:
        RETVAL = histo_overflow(self);
    OUTPUT:
        RETVAL

uint64_t
nan_count(histo_t *self)
    CODE:
        RETVAL = histo_nan_count(self);
    OUTPUT:
        RETVAL

uint32_t
nbins(histo_t *self)
    CODE:
        RETVAL = histo_nbins(self);
    OUTPUT:
        RETVAL

double
min(histo_t *self)
    CODE:
        double min_val = 0.0, max_val = 0.0;
        histo_range(self, &min_val, &max_val);
        RETVAL = min_val;
    OUTPUT:
        RETVAL

double
max(histo_t *self)
    CODE:
        double min_val = 0.0, max_val = 0.0;
        histo_range(self, &min_val, &max_val);
        RETVAL = max_val;
    OUTPUT:
        RETVAL

int
is_uniform(histo_t *self)
    CODE:
        RETVAL = (histo_bin_type(self) == HISTO_BIN_UNIFORM) ? 1 : 0;
    OUTPUT:
        RETVAL


double
mean(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_mean(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
variance(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_variance(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
std_dev(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_std_dev(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
skewness(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_skewness(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
kurtosis(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_kurtosis(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
excess_kurtosis(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_excess_kurtosis(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
central_moment(histo_t *self, uint32_t order)
    CODE:
        double out = 0.0;
        if (histo_central_moment(self, order, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
median(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_median(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
quantile(histo_t *self, double q)
    CODE:
        double out = 0.0;
        if (histo_quantile(self, q, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
iqr(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_iqr(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
mad(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_mad(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
mode(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_mode_continuous(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
fwhm(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_fwhm(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
rms(histo_t *self)
    CODE:
        double out = 0.0;
        if (histo_rms(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
trimmed_mean(histo_t *self, double fraction)
    CODE:
        double out = 0.0;
        if (histo_trimmed_mean(self, fraction, 1.0 - fraction, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
winsorized_mean(histo_t *self, double fraction)
    CODE:
        double out = 0.0;
        if (histo_winsorized_mean(self, fraction, 1.0 - fraction, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
integral(histo_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        uint32_t n = histo_nbins(self);
        double out = 0.0;
        if (n == 0 || histo_integral(self, 0, n - 1, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
cdf(histo_t *self, double prenormalization=1.0)
    CODE:
        if (!self) XSRETURN_UNDEF;
        RETVAL = histo_cdf(self, prenormalization);
        if (!RETVAL) {
            croak("Math::Histo::cdf failed");
        }
    OUTPUT:
        RETVAL

int64_t
find_bin(histo_t *self, double x)
    CODE:
        if (!self) XSRETURN_UNDEF;
        int64_t bin_idx = -1;
        if (histo_find_bin(self, x, &bin_idx) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = bin_idx;
    OUTPUT:
        RETVAL

double
bin_content(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double out = 0.0;
        if (histo_bin_content(self, (uint32_t)bin_idx, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_error(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double out = 0.0;
        if (histo_bin_error(self, (uint32_t)bin_idx, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_sum_w2(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double out = 0.0;
        if (histo_bin_sum_w2(self, (uint32_t)bin_idx, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_low_edge(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double low = 0.0, high = 0.0;
        if (histo_bin_bounds(self, (uint32_t)bin_idx, &low, &high) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = low;
    OUTPUT:
        RETVAL

double
bin_high_edge(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double low = 0.0, high = 0.0;
        if (histo_bin_bounds(self, (uint32_t)bin_idx, &low, &high) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = high;
    OUTPUT:
        RETVAL

double
bin_center(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double out = 0.0;
        if (histo_bin_center(self, (uint32_t)bin_idx, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_width(histo_t *self, int bin_idx)
    CODE:
        if (!self) XSRETURN_UNDEF;
        double low = 0.0, high = 0.0;
        if (histo_bin_bounds(self, (uint32_t)bin_idx, &low, &high) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = high - low;
    OUTPUT:
        RETVAL

SV *
bin_contents(histo_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        uint32_t n = histo_nbins(self);
        AV *av = newAV();
        av_extend(av, (SSize_t)n - 1);
        for (uint32_t i = 0; i < n; i++) {
            double c = 0.0;
            histo_bin_content(self, i, &c);
            av_push(av, newSVnv(c));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

SV *
bin_edges(histo_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        uint32_t n = histo_nbins(self);
        AV *av = newAV();
        av_extend(av, (SSize_t)n);
        double low = 0.0, high = 0.0;
        for (uint32_t i = 0; i < n; i++) {
            histo_bin_bounds(self, i, &low, &high);
            av_push(av, newSVnv(low));
        }
        av_push(av, newSVnv(high));
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL


SV *
stats(histo_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_stats_t st;
        histo_status_t err = histo_get_stats(self, &st);
        if (err != HISTO_OK) XSRETURN_UNDEF;
        HV *hv = newHV();
        hv_stores(hv, "entries", newSVuv(st.n_entries));
        hv_stores(hv, "total_weight", newSVnv(st.total_weight));
        hv_stores(hv, "mean", newSVnv(st.mean));
        hv_stores(hv, "variance", newSVnv(st.variance));
        hv_stores(hv, "std_dev", newSVnv(st.std_dev));
        hv_stores(hv, "min", newSVnv(st.min));
        hv_stores(hv, "max", newSVnv(st.max));
        hv_stores(hv, "median", newSVnv(st.median));
        RETVAL = newRV_noinc((SV*)hv);
    OUTPUT:
        RETVAL

int
reset(histo_t *self)
    CODE:
        RETVAL = (histo_reset(self) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
scale(histo_t *self, double factor)
    CODE:
        RETVAL = (histo_scale(self, factor) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
normalize(histo_t *self, double target_integral=1.0)
    CODE:
        RETVAL = (histo_normalize(self, target_integral) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

histo_t *
rebin(histo_t *self, uint32_t group_factor)
    CODE:
        if (!self) XSRETURN_UNDEF;
        RETVAL = histo_rebin(self, group_factor);
        if (!RETVAL) {
            croak("Math::Histo::rebin: failed to rebin (invalid group factor)");
        }
    OUTPUT:
        RETVAL

int
add(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        RETVAL = (histo_add(self, other) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
subtract(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        RETVAL = (histo_subtract(self, other) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
multiply(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        RETVAL = (histo_multiply(self, other) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
divide(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        RETVAL = (histo_divide(self, other) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

void
chi2_test(histo_t *self, histo_t *other)
    PPCODE:
        if (!self || !other) XSRETURN_UNDEF;
        double chi2 = 0.0;
        uint32_t ndf = 0;
        histo_status_t st = histo_cmp_chi2(self, other, &chi2, &ndf);
        if (st != HISTO_OK) {
            croak("Math::Histo::chi2_test failed (incompatible binning)");
        }
        if (GIMME_V == G_ARRAY) {
            EXTEND(SP, 2);
            mPUSHn(chi2);
            mPUSHi((IV)ndf);
        } else {
            mPUSHn(chi2);
        }

double
kolmogorov_smirnov(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        double ks_stat = 0.0;
        histo_status_t st = histo_cmp_ks(self, other, &ks_stat);
        if (st != HISTO_OK) {
            croak("Math::Histo::kolmogorov_smirnov failed");
        }
        RETVAL = ks_stat;
    OUTPUT:
        RETVAL

double
wasserstein_distance(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        double w1 = 0.0;
        histo_status_t st = histo_cmp_wasserstein_1d(self, other, &w1);
        if (st != HISTO_OK) {
            croak("Math::Histo::wasserstein_distance failed");
        }
        RETVAL = w1;
    OUTPUT:
        RETVAL

double
kl_divergence(histo_t *self, histo_t *other, double eps=1e-12)
    CODE:
        (void)eps;
        if (!self || !other) XSRETURN_UNDEF;
        double kl = 0.0;
        histo_status_t st = histo_cmp_kl_divergence(self, other, &kl);
        if (st != HISTO_OK) {
            croak("Math::Histo::kl_divergence failed");
        }
        RETVAL = kl;
    OUTPUT:
        RETVAL

double
bhattacharyya_distance(histo_t *self, histo_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        double bhat = 0.0;
        histo_status_t st = histo_cmp_bhattacharyya(self, other, &bhat);
        if (st != HISTO_OK) {
            croak("Math::Histo::bhattacharyya_distance failed");
        }
        RETVAL = bhat;
    OUTPUT:
        RETVAL

SV *
serialize_binary(histo_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        void *out_buf = NULL;
        size_t out_size = 0;
        histo_status_t st = histo_serialize_binary(self, &out_buf, &out_size);
        if (st != HISTO_OK || !out_buf) {
            croak("Math::Histo::serialize_binary: serialization failed");
        }
        RETVAL = newSVpvn((const char*)out_buf, out_size);
        histo_free_buffer(out_buf);
    OUTPUT:
        RETVAL

SV *
serialize_json(histo_t *self, int pretty=0)
    CODE:
        (void)pretty;
        if (!self) XSRETURN_UNDEF;
        char *json = NULL;
        histo_status_t st = histo_serialize_json(self, &json);
        if (st != HISTO_OK || !json) {
            croak("Math::Histo::serialize_json: JSON serialization failed");
        }
        RETVAL = newSVpv(json, 0);
        histo_free_buffer(json);
    OUTPUT:
        RETVAL


MODULE = Math::Histo    PACKAGE = Math::Histo::2D    PREFIX = histo2d_xs_

histo2d_t *
_create_uniform(CLASS, uint32_t nx, double xmin, double xmax, uint32_t ny, double ymin, double ymax, uint32_t flags=0)
    char *CLASS
    CODE:
        (void)CLASS;
        RETVAL = histo2d_create_uniform(nx, xmin, xmax, ny, ymin, ymax, flags);
        if (!RETVAL) {
            croak("Math::Histo::2D: failed to create uniform 2D histogram");
        }
    OUTPUT:
        RETVAL

histo2d_t *
_create_variable(CLASS, SV *xedges_ref, SV *yedges_ref, uint32_t flags=0)
    char *CLASS
    CODE:
        (void)CLASS;
        if (!SvROK(xedges_ref) || SvTYPE(SvRV(xedges_ref)) != SVt_PVAV ||
            !SvROK(yedges_ref) || SvTYPE(SvRV(yedges_ref)) != SVt_PVAV) {
            croak("Math::Histo::2D: xedges and yedges must be array references");
        }
        AV *x_av = (AV*)SvRV(xedges_ref);
        AV *y_av = (AV*)SvRV(yedges_ref);
        SSize_t nx_edges = av_top_index(x_av) + 1;
        SSize_t ny_edges = av_top_index(y_av) + 1;
        if (nx_edges < 2 || ny_edges < 2) {
            croak("Math::Histo::2D: variable binning requires >= 2 edges per axis");
        }
        double *xedges = (double*)malloc((size_t)nx_edges * sizeof(double));
        double *yedges = (double*)malloc((size_t)ny_edges * sizeof(double));
        if (!xedges || !yedges) {
            free(xedges); free(yedges);
            croak("Math::Histo::2D: memory allocation failure");
        }
        for (SSize_t i = 0; i < nx_edges; i++) {
            SV **it = av_fetch(x_av, i, 0);
            xedges[i] = (it && SvOK(*it)) ? SvNV(*it) : 0.0;
        }
        for (SSize_t i = 0; i < ny_edges; i++) {
            SV **it = av_fetch(y_av, i, 0);
            yedges[i] = (it && SvOK(*it)) ? SvNV(*it) : 0.0;
        }
        RETVAL = histo2d_create_variable((uint32_t)(nx_edges - 1), xedges, (uint32_t)(ny_edges - 1), yedges, flags);
        free(xedges);
        free(yedges);
        if (!RETVAL) {
            croak("Math::Histo::2D: failed to create variable 2D histogram");
        }
    OUTPUT:
        RETVAL

histo2d_t *
_clone(histo2d_t *self)
    CODE:
        if (!self) croak("Math::Histo::2D::clone: NULL histogram");
        RETVAL = histo2d_clone(self, false);
        if (!RETVAL) {
            croak("Math::Histo::2D::clone: failed to clone");
        }
    OUTPUT:
        RETVAL


histo2d_t *
_deserialize_binary(CLASS, SV *buf_sv)
    char *CLASS
    CODE:
        (void)CLASS;
        STRLEN len;
        const char *buf = SvPVbyte(buf_sv, len);
        histo2d_t *out = NULL;
        histo_status_t st = histo2d_deserialize_binary(buf, len, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::from_binary: deserialization failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo2d_t *
_deserialize_json(CLASS, SV *json_sv)
    char *CLASS
    CODE:
        (void)CLASS;
        STRLEN len;
        const char *str = SvPV(json_sv, len);
        histo2d_t *out = NULL;
        histo_status_t st = histo2d_deserialize_json(str, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::from_json: JSON deserialization failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

void
DESTROY(histo2d_t *self)
    CODE:
        if (self) {
            histo2d_destroy(self);
        }

int
fill(histo2d_t *self, double x, double y, double weight=1.0)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_status_t st;
        if (weight == 1.0) {
            st = histo2d_fill(self, x, y);
        } else {
            st = histo2d_fill_w(self, x, y, weight);
        }
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
fill_n(histo2d_t *self, SV *x_ref, SV *y_ref, SV *w_ref=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        if (!SvROK(x_ref) || SvTYPE(SvRV(x_ref)) != SVt_PVAV ||
            !SvROK(y_ref) || SvTYPE(SvRV(y_ref)) != SVt_PVAV) {
            croak("Math::Histo::2D::fill_n: x and y must be array references");
        }
        AV *x_av = (AV*)SvRV(x_ref);
        AV *y_av = (AV*)SvRV(y_ref);
        SSize_t n = av_top_index(x_av) + 1;
        if (av_top_index(y_av) + 1 != n) {
            croak("Math::Histo::2D::fill_n: x and y array lengths must match");
        }
        if (n == 0) XSRETURN_IV(0);

        AV *w_av = NULL;
        if (w_ref && SvOK(w_ref)) {
            if (!SvROK(w_ref) || SvTYPE(SvRV(w_ref)) != SVt_PVAV) {
                croak("Math::Histo::2D::fill_n: weights must be an array reference");
            }
            w_av = (AV*)SvRV(w_ref);
            if (av_top_index(w_av) + 1 != n) {
                croak("Math::Histo::2D::fill_n: weights length must match x length");
            }
        }

        double *x_arr = (double*)malloc((size_t)n * sizeof(double));
        double *y_arr = (double*)malloc((size_t)n * sizeof(double));
        double *w_arr = w_av ? (double*)malloc((size_t)n * sizeof(double)) : NULL;
        if (!x_arr || !y_arr || (w_av && !w_arr)) {
            free(x_arr); free(y_arr); free(w_arr);
            croak("Math::Histo::2D::fill_n: memory allocation failure");
        }

        for (SSize_t i = 0; i < n; i++) {
            SV **xi = av_fetch(x_av, i, 0);
            SV **yi = av_fetch(y_av, i, 0);
            x_arr[i] = (xi && SvOK(*xi)) ? SvNV(*xi) : 0.0;
            y_arr[i] = (yi && SvOK(*yi)) ? SvNV(*yi) : 0.0;
            if (w_av) {
                SV **wi = av_fetch(w_av, i, 0);
                w_arr[i] = (wi && SvOK(*wi)) ? SvNV(*wi) : 1.0;
            }
        }

        histo_status_t st = histo2d_fill_n(self, (size_t)n, x_arr, y_arr, w_arr);
        free(x_arr); free(y_arr); free(w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
fill_packed_f64(histo2d_t *self, SV *packed_x, SV *packed_y, SV *packed_w=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        STRLEN x_len = 0, y_len = 0;
        const char *x_raw = SvPVbyte(packed_x, x_len);
        const char *y_raw = SvPVbyte(packed_y, y_len);
        if ((x_len % sizeof(double)) != 0 || (y_len % sizeof(double)) != 0 || x_len != y_len) {
            croak("Math::Histo::2D::fill_packed_f64: packed x and y byte lengths must match and be multiple of 8 (double)");
        }
        size_t n = x_len / sizeof(double);
        if (n == 0) XSRETURN_IV(0);

        const double *x_arr = (const double *)(const void *)x_raw;
        const double *y_arr = (const double *)(const void *)y_raw;
        const double *w_arr = NULL;
        if (packed_w && SvOK(packed_w)) {
            STRLEN w_len = 0;
            const char *w_raw = SvPVbyte(packed_w, w_len);
            if (w_len != x_len) {
                croak("Math::Histo::2D::fill_packed_f64: weights length must match x length");
            }
            w_arr = (const double *)(const void *)w_raw;
        }
        histo_status_t st = histo2d_fill_n(self, n, x_arr, y_arr, w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

uint64_t
num_entries(histo2d_t *self)

    CODE:
        RETVAL = histo2d_num_entries(self);
    OUTPUT:
        RETVAL

double
total_weight(histo2d_t *self)
    CODE:
        RETVAL = histo2d_total_weight(self);
    OUTPUT:
        RETVAL

double
bin_sum_w2(histo2d_t *self, int ix, int iy)
    CODE:
        double out = 0.0;
        if (histo2d_bin_sum_w2(self, (uint32_t)ix, (uint32_t)iy, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL


uint32_t
nx(histo2d_t *self)
    CODE:
        RETVAL = histo2d_nbins_x(self);
    OUTPUT:
        RETVAL

uint32_t
ny(histo2d_t *self)
    CODE:
        RETVAL = histo2d_nbins_y(self);
    OUTPUT:
        RETVAL

double
xmin(histo2d_t *self)
    CODE:
        histo2d_axis_t axis_x_def;
        if (histo2d_axis_x(self, &axis_x_def) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = axis_x_def.min;
    OUTPUT:
        RETVAL

double
xmax(histo2d_t *self)
    CODE:
        histo2d_axis_t axis_x_def;
        if (histo2d_axis_x(self, &axis_x_def) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = axis_x_def.max;
    OUTPUT:
        RETVAL

double
ymin(histo2d_t *self)
    CODE:
        histo2d_axis_t axis_y_def;
        if (histo2d_axis_y(self, &axis_y_def) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = axis_y_def.min;
    OUTPUT:
        RETVAL

double
ymax(histo2d_t *self)
    CODE:
        histo2d_axis_t axis_y_def;
        if (histo2d_axis_y(self, &axis_y_def) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = axis_y_def.max;
    OUTPUT:
        RETVAL


double
mean_x(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_mean_x(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
mean_y(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_mean_y(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
variance_x(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_variance_x(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
variance_y(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_variance_y(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
covariance(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_covariance(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
correlation(histo2d_t *self)
    CODE:
        double out = 0.0;
        if (histo2d_correlation(self, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_content(histo2d_t *self, int ix, int iy)
    CODE:
        double out = 0.0;
        if (histo2d_bin_content(self, (uint32_t)ix, (uint32_t)iy, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

double
bin_error(histo2d_t *self, int ix, int iy)
    CODE:
        double out = 0.0;
        if (histo2d_bin_error(self, (uint32_t)ix, (uint32_t)iy, &out) != HISTO_OK) XSRETURN_UNDEF;
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
project_x(histo2d_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_project_x(self, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::project_x failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
project_y(histo2d_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_project_y(self, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::project_y failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
slice_x(histo2d_t *self, int iy_min, int iy_max)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_slice_x(self, iy_min, iy_max, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::slice_x failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
slice_y(histo2d_t *self, int ix_min, int ix_max)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_slice_y(self, ix_min, ix_max, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::slice_y failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
profile_x(histo2d_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_profile_x(self, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::profile_x failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

histo_t *
profile_y(histo2d_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_t *out = NULL;
        histo_status_t st = histo2d_profile_y(self, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::2D::profile_y failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

SV *
serialize_binary(histo2d_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        void *out_buf = NULL;
        size_t out_size = 0;
        histo_status_t st = histo2d_serialize_binary_alloc(self, &out_buf, &out_size);
        if (st != HISTO_OK || !out_buf) {
            croak("Math::Histo::2D::serialize_binary failed");
        }
        RETVAL = newSVpvn((const char*)out_buf, out_size);
        free(out_buf);
    OUTPUT:
        RETVAL

SV *
serialize_json(histo2d_t *self, int pretty=0)
    CODE:
        (void)pretty;
        if (!self) XSRETURN_UNDEF;
        char *json = NULL;
        size_t size = 0;
        histo_status_t st = histo2d_serialize_json_alloc(self, &json, &size);
        if (st != HISTO_OK || !json) {
            croak("Math::Histo::2D::serialize_json failed");
        }
        RETVAL = newSVpv(json, size);
        free(json);
    OUTPUT:
        RETVAL


MODULE = Math::Histo    PACKAGE = Math::Histo::Fit    PREFIX = histo_fit_xs_

histo_fit_result_t *
_fit_builtin(CLASS, histo_t *h, int model_type, SV *init_ref, SV *lower_ref=NULL, SV *upper_ref=NULL, SV *fixed_ref=NULL, int max_iter=200, double tol=1e-8, int loss_fn=0)
    char *CLASS
    CODE:
        (void)CLASS;
        if (!h) XSRETURN_UNDEF;

        histo_fit_options_t opts;
        histo_fit_options_init(&opts);
        opts.max_iterations = max_iter;
        opts.ftol = tol;
        opts.gtol = tol;
        opts.xtol = tol;
        opts.loss_type = (histo_fit_loss_t)loss_fn;

        size_t n_p = histo_fit_model_num_params((histo_fit_model_t)model_type, opts.poly_degree);
        double *init_p = NULL;

        /* Unpack initial parameters if provided */
        if (init_ref && SvOK(init_ref) && SvROK(init_ref) && SvTYPE(SvRV(init_ref)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(init_ref);
            SSize_t n = av_top_index(av) + 1;
            if (n > 0) {
                init_p = (double*)malloc((size_t)n * sizeof(double));
                if (!init_p) croak("Math::Histo::Fit: memory allocation failure");
                for (SSize_t i = 0; i < n; i++) {
                    SV **v = av_fetch(av, i, 0);
                    init_p[i] = (v && SvOK(*v)) ? SvNV(*v) : 0.0;
                }
            }
        }

        double *lower_bounds = NULL;
        double *upper_bounds = NULL;
        bool *fixed_params = NULL;

        if (lower_ref && SvOK(lower_ref) && SvROK(lower_ref) && SvTYPE(SvRV(lower_ref)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(lower_ref);
            lower_bounds = (double*)calloc(n_p, sizeof(double));
            for (SSize_t i = 0; i <= av_top_index(av) && (size_t)i < n_p; i++) {
                SV **v = av_fetch(av, i, 0);
                if (v && SvOK(*v)) lower_bounds[i] = SvNV(*v);
            }
            opts.lower_bounds = lower_bounds;
        }

        if (upper_ref && SvOK(upper_ref) && SvROK(upper_ref) && SvTYPE(SvRV(upper_ref)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(upper_ref);
            upper_bounds = (double*)calloc(n_p, sizeof(double));
            for (SSize_t i = 0; i <= av_top_index(av) && (size_t)i < n_p; i++) {
                SV **v = av_fetch(av, i, 0);
                if (v && SvOK(*v)) upper_bounds[i] = SvNV(*v);
            }
            opts.upper_bounds = upper_bounds;
        }

        if (fixed_ref && SvOK(fixed_ref) && SvROK(fixed_ref) && SvTYPE(SvRV(fixed_ref)) == SVt_PVAV) {
            AV *av = (AV*)SvRV(fixed_ref);
            fixed_params = (bool*)calloc(n_p, sizeof(bool));
            for (SSize_t i = 0; i <= av_top_index(av) && (size_t)i < n_p; i++) {
                SV **v = av_fetch(av, i, 0);
                if (v && SvOK(*v) && SvTRUE(*v)) fixed_params[i] = true;
            }
            opts.fixed_params = fixed_params;
        }

        histo_fit_result_t *res = NULL;
        histo_status_t st = histo_fit_model(h, (histo_fit_model_t)model_type, init_p, &opts, &res);

        free(init_p);
        free(lower_bounds);
        free(upper_bounds);
        free(fixed_params);

        if (st < 0 || !res) {
            croak("Math::Histo::Fit::fit failed (numerical error or optimization diverged)");
        }
        RETVAL = res;
    OUTPUT:
        RETVAL


MODULE = Math::Histo    PACKAGE = Math::Histo::Fit::Result    PREFIX = histo_fit_res_xs_

void
DESTROY(histo_fit_result_t *self)
    CODE:
        if (self) {
            histo_fit_result_destroy(self);
        }

int
status(histo_fit_result_t *self)
    CODE:
        RETVAL = (int)self->status;
    OUTPUT:
        RETVAL

uint32_t
iterations(histo_fit_result_t *self)
    CODE:
        RETVAL = self->iterations;
    OUTPUT:
        RETVAL

uint32_t
n_params(histo_fit_result_t *self)
    CODE:
        RETVAL = (uint32_t)self->num_params;
    OUTPUT:
        RETVAL

double
chi2(histo_fit_result_t *self)
    CODE:
        RETVAL = self->chi2;
    OUTPUT:
        RETVAL

int32_t
ndf(histo_fit_result_t *self)
    CODE:
        RETVAL = self->ndf;
    OUTPUT:
        RETVAL

double
reduced_chi2(histo_fit_result_t *self)
    CODE:
        RETVAL = self->reduced_chi2;
    OUTPUT:
        RETVAL

double
p_value(histo_fit_result_t *self)
    CODE:
        RETVAL = self->p_value;
    OUTPUT:
        RETVAL

double
log_likelihood(histo_fit_result_t *self)
    CODE:
        RETVAL = self->log_likelihood;
    OUTPUT:
        RETVAL

double
aic(histo_fit_result_t *self)
    CODE:
        RETVAL = self->aic;
    OUTPUT:
        RETVAL

double
bic(histo_fit_result_t *self)
    CODE:
        RETVAL = self->bic;
    OUTPUT:
        RETVAL

SV *
params(histo_fit_result_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        AV *av = newAV();
        av_extend(av, (SSize_t)self->num_params - 1);
        for (size_t i = 0; i < self->num_params; i++) {
            av_push(av, newSVnv(self->params[i]));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

SV *
errors(histo_fit_result_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        AV *av = newAV();
        av_extend(av, (SSize_t)self->num_params - 1);
        for (size_t i = 0; i < self->num_params; i++) {
            av_push(av, newSVnv(self->param_errors ? self->param_errors[i] : 0.0));
        }
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

SV *
cov_matrix(histo_fit_result_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        AV *rows = newAV();
        av_extend(rows, (SSize_t)self->num_params - 1);
        for (size_t i = 0; i < self->num_params; i++) {
            AV *row = newAV();
            av_extend(row, (SSize_t)self->num_params - 1);
            for (size_t j = 0; j < self->num_params; j++) {
                double val = self->cov_matrix ? self->cov_matrix[i * self->num_params + j] : 0.0;
                av_push(row, newSVnv(val));
            }
            av_push(rows, newRV_noinc((SV*)row));
        }
        RETVAL = newRV_noinc((SV*)rows);
    OUTPUT:
        RETVAL


MODULE = Math::Histo    PACKAGE = Math::Histo::Sketch    PREFIX = histo_sketch_xs_

histo_sketch_t *
_create(CLASS, double alpha=0.01, uint32_t max_bins=2048)
    char *CLASS
    CODE:
        (void)CLASS;
        RETVAL = histo_sketch_create(alpha, max_bins);
        if (!RETVAL) {
            croak("Math::Histo::Sketch: failed to create sketch");
        }
    OUTPUT:
        RETVAL

histo_sketch_t *
_deserialize_binary(CLASS, SV *buf_sv)
    char *CLASS
    CODE:
        (void)CLASS;
        STRLEN len;
        const char *buf = SvPVbyte(buf_sv, len);
        histo_sketch_t *out = NULL;
        histo_status_t st = histo_sketch_deserialize_binary(buf, len, &out);
        if (st != HISTO_OK || !out) {
            croak("Math::Histo::Sketch::from_binary: deserialization failed");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

void
DESTROY(histo_sketch_t *self)
    CODE:
        if (self) {
            histo_sketch_destroy(self);
        }

int
insert(histo_sketch_t *self, double value, double weight=1.0)
    CODE:
        if (!self) XSRETURN_UNDEF;
        histo_status_t st;
        if (weight == 1.0) {
            st = histo_sketch_insert(self, value);
        } else {
            st = histo_sketch_insert_w(self, value, weight);
        }
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
insert_n(histo_sketch_t *self, SV *values_ref, SV *weights_ref=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        if (!SvROK(values_ref) || SvTYPE(SvRV(values_ref)) != SVt_PVAV) {
            croak("Math::Histo::Sketch::insert_n: values must be an array reference");
        }
        AV *v_av = (AV*)SvRV(values_ref);
        SSize_t n = av_top_index(v_av) + 1;
        if (n == 0) XSRETURN_IV(0);

        AV *w_av = NULL;
        if (weights_ref && SvOK(weights_ref)) {
            if (!SvROK(weights_ref) || SvTYPE(SvRV(weights_ref)) != SVt_PVAV) {
                croak("Math::Histo::Sketch::insert_n: weights must be an array reference");
            }
            w_av = (AV*)SvRV(weights_ref);
            if (av_top_index(w_av) + 1 != n) {
                croak("Math::Histo::Sketch::insert_n: values and weights length mismatch");
            }
        }

        double *v_arr = (double*)malloc((size_t)n * sizeof(double));
        double *w_arr = w_av ? (double*)malloc((size_t)n * sizeof(double)) : NULL;
        if (!v_arr || (w_av && !w_arr)) {
            free(v_arr); free(w_arr);
            croak("Math::Histo::Sketch::insert_n: memory allocation failure");
        }

        for (SSize_t i = 0; i < n; i++) {
            SV **vi = av_fetch(v_av, i, 0);
            v_arr[i] = (vi && SvOK(*vi)) ? SvNV(*vi) : 0.0;
            if (w_av) {
                SV **wi = av_fetch(w_av, i, 0);
                w_arr[i] = (wi && SvOK(*wi)) ? SvNV(*wi) : 1.0;
            }
        }

        histo_status_t st = histo_sketch_insert_n(self, (size_t)n, v_arr, w_arr);
        free(v_arr); free(w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

int
insert_packed_f64(histo_sketch_t *self, SV *packed_v, SV *packed_w=NULL)
    CODE:
        if (!self) XSRETURN_UNDEF;
        STRLEN v_len = 0;
        const char *v_raw = SvPVbyte(packed_v, v_len);
        if ((v_len % sizeof(double)) != 0) {
            croak("Math::Histo::Sketch::insert_packed_f64: packed values byte length must be multiple of 8 (double)");
        }
        size_t n = v_len / sizeof(double);
        if (n == 0) XSRETURN_IV(0);

        const double *v_arr = (const double *)(const void *)v_raw;
        const double *w_arr = NULL;
        if (packed_w && SvOK(packed_w)) {
            STRLEN w_len = 0;
            const char *w_raw = SvPVbyte(packed_w, w_len);
            if (w_len != v_len) {
                croak("Math::Histo::Sketch::insert_packed_f64: weights length must match values length");
            }
            w_arr = (const double *)(const void *)w_raw;
        }
        histo_status_t st = histo_sketch_insert_n(self, n, v_arr, w_arr);
        RETVAL = (st == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

double
quantile(histo_sketch_t *self, double q)

    CODE:
        if (!self) XSRETURN_UNDEF;
        double out = 0.0;
        histo_status_t st = histo_sketch_quantile(self, q, &out);
        if (st != HISTO_OK) {
            croak("Math::Histo::Sketch::quantile failed (empty sketch or invalid q in [0,1])");
        }
        RETVAL = out;
    OUTPUT:
        RETVAL

int
merge(histo_sketch_t *self, histo_sketch_t *other)
    CODE:
        if (!self || !other) XSRETURN_UNDEF;
        RETVAL = (histo_sketch_merge(self, other) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

double
min(histo_sketch_t *self)
    CODE:
        RETVAL = histo_sketch_min(self);
    OUTPUT:
        RETVAL

double
max(histo_sketch_t *self)
    CODE:
        RETVAL = histo_sketch_max(self);
    OUTPUT:
        RETVAL

double
total_weight(histo_sketch_t *self)
    CODE:
        RETVAL = histo_sketch_total_weight(self);
    OUTPUT:
        RETVAL

uint64_t
num_entries(histo_sketch_t *self)
    CODE:
        RETVAL = histo_sketch_num_entries(self);
    OUTPUT:
        RETVAL

int
reset(histo_sketch_t *self)
    CODE:
        RETVAL = (histo_sketch_reset(self) == HISTO_OK) ? 1 : 0;
    OUTPUT:
        RETVAL

SV *
serialize_binary(histo_sketch_t *self)
    CODE:
        if (!self) XSRETURN_UNDEF;
        void *out_buf = NULL;
        size_t out_size = 0;
        histo_status_t st = histo_sketch_serialize_binary(self, &out_buf, &out_size);
        if (st != HISTO_OK || !out_buf) {
            croak("Math::Histo::Sketch::serialize_binary failed");
        }
        RETVAL = newSVpvn((const char*)out_buf, out_size);
        free(out_buf);
    OUTPUT:
        RETVAL

MODULE = Math::Histo    PACKAGE = Math::Histo::CLI    PREFIX = histo_cli_xs_

int
run(...)
    PROTOTYPE: @
    CODE:
        int start = 0;
        if (items > 0 && SvPOK(ST(0)) && strcmp(SvPV_nolen(ST(0)), "Math::Histo::CLI") == 0) {
            start = 1;
        }
        int argc = items - start;
        if (argc == 0) {
            char *default_argv[] = { "phisto", NULL };
            RETVAL = histo_cli_main(1, default_argv, stdout, stderr);
        } else {
            char **argv = (char **)malloc(((size_t)argc + 2) * sizeof(char *));
            if (!argv) {
                croak("Math::Histo::CLI::run: out of memory allocating argv");
            }
            argv[0] = (char *)"phisto";
            for (int i = 0; i < argc; ++i) {
                argv[i + 1] = SvPV_nolen(ST(start + i));
            }
            argv[argc + 1] = NULL;
            RETVAL = histo_cli_main(argc + 1, argv, stdout, stderr);
            free(argv);
        }
    OUTPUT:
        RETVAL


int
histo_cli_xs_run_raw(...)
    PROTOTYPE: @
    CODE:
        /* Run with explicit argv[0] */
        int argc = items;
        if (argc == 0) {
            char *default_argv[] = { "phisto", NULL };
            RETVAL = histo_cli_main(1, default_argv, stdout, stderr);
        } else {
            char **argv = (char **)malloc(((size_t)argc + 1) * sizeof(char *));
            if (!argv) {
                croak("Math::Histo::CLI::run_raw: out of memory allocating argv");
            }
            for (int i = 0; i < argc; ++i) {
                argv[i] = SvPV_nolen(ST(i));
            }
            argv[argc] = NULL;
            RETVAL = histo_cli_main(argc, argv, stdout, stderr);
            free(argv);
        }
    OUTPUT:
        RETVAL

