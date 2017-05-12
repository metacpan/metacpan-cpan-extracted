#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <math.h>   /* exp(3), sqrt(3), ceil(3) */

/* From Module::Install::XSUtil. Thanks to gfx. */
#ifndef STATIC_INLINE /* from 5.13.4 */
# if defined(__GNUC__) || defined(__cplusplus) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#   define STATIC_INLINE static inline
# else
#   define STATIC_INLINE static
# endif
#endif /* STATIC_INLINE */


/* Ignore calculating pixel value if its value is less than this. */
const double EXP_IGNORE_THRESHOLD = -36.04365338911715; /* log(DBL_EPSILON) */

typedef unsigned int uint;

STATIC_INLINE SV*
valid_av_fetch(AV *array, int index)
{
    SV **item = av_fetch(array, index, 1);
    if (item == NULL) {
        croak("Fetched data from array was unexpectedly NULL");
    }

    return *item;
}

static int
fetch_pdata(AV *insert_datas, int *px, int *py, double *pweight)
{
    SV *pdata = av_shift(insert_datas);

    if (!SvOK(pdata)) return 0; /* End of data */

    if (!SvROK(pdata) || SvTYPE(SvRV(pdata)) != SVt_PVAV)
        goto invdata;

    I32 datalen = av_len((AV *)SvRV(pdata)) + 1;
    if (datalen < 2)
        goto invdata;

    AV *pdata_av = (AV *)SvRV(pdata);
    *px      = SvIV(valid_av_fetch(pdata_av, 0));
    *py      = SvIV(valid_av_fetch(pdata_av, 1));
    *pweight = (datalen > 2) ? SvNV(valid_av_fetch(pdata_av, 2)) : 1;

    return 1;

invdata:
    croak("insert_data should be an array reference "
          "which contains x, y, and optionally weight");
}

STATIC_INLINE max(int a, int b) { return (a > b) ? a : b; }
STATIC_INLINE min(int a, int b) { return (a < b) ? a : b; }

/* Calculate the probability density of each point insertion
 * for each pixels around it which to be get affected of insertion. */
static void
calc_probability_density(AV *matrix, AV *insert_datas,
                         uint xsize, uint ysize,
                         double xsigma, double ysigma, double correlation)
{
    const int w = xsize, h = ysize;

    /* Calculate things to not calculate these again. */
    const double xsig_sq   = xsigma * xsigma;
    const double ysig_sq   = ysigma * ysigma;
    const double xysig_mul = xsigma * ysigma;
    const double alpha     = 2 * correlation;
    const double beta      = 2 * (1 - correlation * correlation);

    /* (X|Y)-direction effective range of point insertion. */
    const uint x_affect_range = (uint)ceil(sqrt(-(EXP_IGNORE_THRESHOLD * beta) * xsig_sq));
    const uint y_affect_range = (uint)ceil(sqrt(-(EXP_IGNORE_THRESHOLD * beta) * ysig_sq));

    /*
     * The equation used to calculate 2-dimensional probability density
     * can be found at following URL:
     * Multivariate normal distribution - Wikipedia, the free encyclopedia
     *    http://en.wikipedia.org/wiki/Multivariate_normal_distribution#Bivariate_case
     */
    int    px, py;
    double pweight;
    while (fetch_pdata(insert_datas, &px, &py, &pweight)) {
        int x_beg = max(0, px - x_affect_range);
        int x_end = min(w, px + x_affect_range);
        int y_beg = max(0, py - y_affect_range);
        int y_end = min(h, py + y_affect_range);

        int x, y;
        for (x = x_beg; x < x_end; x++) {
            for (y = y_beg; y < y_end; y++) {
                int xd = x - px;
                int yd = y - py;

                SV *pixel_valsv = valid_av_fetch(matrix, x+w*y);

                double pixel_val = 0.0;
                if (SvOK(pixel_valsv)) {
                    pixel_val = SvNV(pixel_valsv);
                }

                pixel_val += exp(
                    -(xd*xd/xsig_sq + yd*yd/ysig_sq - alpha*xd*yd/xysig_mul) / beta
                ) * pweight;

                sv_setnv(pixel_valsv, pixel_val);
            }
        }
    }
}

MODULE = Imager::Heatmap		PACKAGE = Imager::Heatmap
PROTOTYPES: DISABLE

AV*
xs_build_matrix(matrix, insert_datas, xsize, ysize, xsigma, ysigma, correlation)
    AV          *matrix;
    AV          *insert_datas;
    unsigned int xsize;
    unsigned int ysize;
    double       xsigma;
    double       ysigma;
    double       correlation;

    CODE:

        calc_probability_density(
            matrix, insert_datas,
            xsize, ysize,
            xsigma, ysigma, correlation
        );

        RETVAL = matrix;
    OUTPUT:
        RETVAL
