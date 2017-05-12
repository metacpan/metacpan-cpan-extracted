/* Image::SubImageFind ($Id$)
 * Minor modifications by Dennis K. Paulsen
 *
 * Relies heavy on the algorithms and original code provided by
 * Dr. Werner Van Belle, as documented here:
 *     http://werner.yellowcouch.org/Papers/subimg/
 *     [A subimage finder (c) Werner Van Belle - 2007]
 *
 */
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <assert.h>
#include <math.h>
#include <fftw3.h>
#include <Magick++.h>
#include "DWVB.h"

/**
 * This function finds a subimage in a larger image. It expects two arguments.
 * The first is the image in which it must look. The second image is the
 * image that is to be found. The program relies on a number of different
 * steps to perform the calculation.
 *
 * It will first normalize the input images in order to improve the
 * crosscorrelation matching. Once the best crosscorrelation is found
 * a sad-matchers is applied in a grid over the larger image.
 *
 * The following two article explains the details:
 *
 *   Werner Van Belle; An Adaptive Filter for the Correct Localization
 *   of Subimages: FFT based Subimage Localization Requires Image
 *   Normalization to work properly; 11 pages; October 2007.
 *   http://werner.yellowcouch.org/Papers/subimg/
 *
 *   Werner Van Belle; Correlation between the inproduct and the sum
 *   of absolute differences is -0.8485 for uniform sampled signals on
 *   [-1:1]; November 2006
 *
 */

bool DWVB::getCoordinates(size_t &x, size_t &y)
{
    /**
     * The larger image will be called A. The smaller image will be called B.
     *
     * The code below relies heavily upon fftw. The indices necessary for the
     * fast r2c and c2r transforms are at best confusing. Especially regarding
     * the number of rows and colums (watch our for Asx vs Asx2 !).
     *
     * After obtaining all the crosscorrelations we will scan through the image
     * to find the best sad match. As such we make a backup of the original data
     * in advance
     *
     */
    size_t Asx, Asy;
    size_t Bsx, Bsy;
    signed2 *A = ImageProcessor::readImageGrayscale(this->hayImage, Asx, Asy);
    signed2 *B = ImageProcessor::readImageGrayscale(this->needleImage, Bsx, Bsy);
	if ((Asx*Asy) < (Bsx*Bsy)) {
		fprintf(stderr, "Haystack is smaller than needle!\n");
		return false;
	}
	//printf("%d x %d\n", (Asx*Asy), (Bsx*Bsy));

    size_t Asx2 = Asx / 2 + 1;
    unsigned1 *Asad = (unsigned1 *)malloc(sizeof(unsigned1) * Asx * Asy);
    unsigned1 *Bsad = (unsigned1 *)malloc(sizeof(unsigned1) * Bsx * Bsy);
    size_t i = 0;
    for (i = 0; i < Bsx * Bsy; i++)
    {
        Bsad[i] = B[i];
        Asad[i] = A[i];
    }
    for (i = Bsx * Bsy; i < Asx * Asy; i++)
	{
        Asad[i] = A[i];
    }

    /**
     * Normalization and windowing of the images.
     *
     * The window size (wx,wy) is half the size of the smaller subimage. This
     * is useful to have as much good information from the subimg.
     */
    size_t wx = Bsx / 2;
    size_t wy = Bsy / 2;
    normalize(B, Bsx, Bsy, wx, wy);
    normalize(A, Asx, Asy, wx, wy);

    /**
     * Preparation of the fourier transforms.
     * Aa is the amplitude of image A. Af is the frequence of image A
     * Similar for B. crosscors will hold the crosscorrelations.
     */
    double *Aa = (double *)fftw_malloc(sizeof(double) * Asx * Asy);
    fftw_complex *Af = (fftw_complex *)fftw_malloc (sizeof(fftw_complex) * Asx2 * Asy);
    double *Ba = (double *)fftw_malloc(sizeof( double) * Asx * Asy);
    fftw_complex *Bf = (fftw_complex *) fftw_malloc(sizeof(fftw_complex) * Asx2 * Asy);
    if (Af == NULL || Bf == NULL)
    {
		fprintf(stderr, "Unable to allocate memory for one or more plans!\n");
		return false;
    }

    /**
     * The forward transform of A goes from Aa to Af
     * The forward tansform of B goes from Ba to Bf
     * In Bf we will also calculate the inproduct of Af and Bf
     * The backward transform then goes from Bf to Aa again. That
     * variable is aliased as crosscors;
     */
    fftw_plan forwardA = fftw_plan_dft_r2c_2d ( Asy, Asx, Aa, Af, FFTW_ESTIMATE );
    fftw_plan forwardB = fftw_plan_dft_r2c_2d ( Asy, Asx, Ba, Bf, FFTW_ESTIMATE );
    double *crosscorrs = Aa;
    fftw_plan backward = fftw_plan_dft_c2r_2d ( Asy, Asx, Bf, crosscorrs,
                         FFTW_BACKWARD | FFTW_ESTIMATE );
    if (forwardA == NULL || forwardB == NULL || backward == NULL)
	{
		fprintf(stderr, "Unable to create one or more plans!\n");
		return false;
	}

    /**
     * The two forward transforms of A and B. Before we do so we copy the normalized
     * data into the double array. For B we also pad the data with 0
     */
    size_t row = 0;
    size_t col = 0;
    for ( row = 0; row < Asy; row++ )
    {
        for ( col = 0; col < Asx; col++ )
        {
            Aa[col + Asx * row] = A[col + Asx * row];
        }
    }
    fftw_execute(forwardA);

    size_t j = 0;
    for (j = 0; j < Asx * Asy; j++)
        Ba[j] = 0;
    for (row = 0; row < Bsy; row++)
        for (col = 0; col < Bsx; col++)
            Ba[col + Asx * row] = B[col + Bsx * row];
    fftw_execute(forwardB);

    /**
     * The inproduct of the two frequency domains and calculation
     * of the crosscorrelations
     */
    double norm = Asx * Asy;
    for ( j = 0; j < Asx2 * Asy; j++ )
    {
        double a = Af[j][0];
        double b = Af[j][1];
        double c = Bf[j][0];
        double d = -Bf[j][1];
        double e = a * c - b * d;
        double f = a * d + b * c;
        Bf[j][0] = e / norm;
        Bf[j][1] = f / norm;
    }
    fftw_execute (backward);

    /**
     * We now have a correlation map. We can spent one more pass
     * over the entire image to actually find the best matching images
     * as defined by the SAD.
     * We calculate this by gridding the entire image according to the
     * size of the subimage. In each cel we want to know what the best
     * match is.
     */
    int sa = 1 + Asx / Bsx;
    int sb = 1 + Asy / Bsy;
    int sadx = 0;
    int sady = 0;
    signed8 minsad = Bsx * Bsy * 256L;
    int a = 0;
    int b = 0;

    for (a = 0; a < sa; a++)
    {
    	size_t xl = a * Bsx;
        size_t xr = xl + Bsx;
        if ( xr > Asx )
            continue;
        for (b = 0; b < sb; b++)
        {
        	size_t yl = b * Bsy;
        	size_t yr = yl + Bsy;
            if ( yr > Asy )
                continue;

            // find the maximum correlation in this cell
            int cormxat = xl + yl * Asx;
            double cormx = crosscorrs[cormxat];
            size_t cx = 0;
            size_t cy = 0;
            for ( cx = xl; cx < xr; cx++ )
                for ( cy = yl; cy < yr; cy++ )
                {
                	size_t j = cx + cy * Asx;
                    if ( crosscorrs[j] > cormx )
                        cormx = crosscorrs[cormxat = j];
                }
            int corx = cormxat % Asx;
            int cory = cormxat / Asx;

            // We dont want subimages that fall of the larger image
            if ( corx + Bsx > Asx )
                continue;
            if ( cory + Bsy > Asy )
                continue;

            signed8 sad = 0;
            for (size_t sx = 0; sad < minsad && sx < Bsx; sx++ )
                for (size_t sy = 0; sy < Bsy; sy++ )
                {
                    int j = ( sx + corx ) + ( sy + cory ) * Asx;
                    int i = sx + sy * Bsx;
                    sad += llabs ( ( int ) Bsad[i] - ( int ) Asad[j] );
                }

            if ( sad < minsad )
            {
                minsad = sad;
                sadx = corx;
                sady = cory;
                //printf("* ");
            }
            //printf("Grid (%d,%d) (%d,%d) Sip=%g Sad=%lld\n",a,b,corx,cory,cormx,sad);
        }
    }

    // Set coordinates..
    //printf("%d\t%d\n",sadx,sady);
    x = sadx;
    y = sady;

    /**
     * Aa, Ba, Af and Bf were allocated in this function
     * crosscorrs was an alias for Aa and does not require deletion.
     */
    fftw_free(Aa);
    fftw_free(Ba);
    fftw_free(Af);
    fftw_free(Bf);
	free(A);
	free(B);


	return true;
}

void DWVB::normalize(signed2 *img, int sx, int sy, int wx, int wy)
{
    /**
      * Calculate the mean background. We will subtract this
      * from img to make sure that it has a mean of zero
      * over a window size of wx x wy. Afterwards we calculate
      * the square of the difference, which will then be used
      * to normalize the local variance of img.
      */
    signed2 *mean = boxaverage (img, sx, sy, wx, wy);
    signed2 *sqr = ( signed2 * ) malloc ( sizeof ( signed2 ) * sx * sy );
    int j = 0;
    for (j = 0; j < sx * sy; j++)
    {
        img[j] -= mean[j];
        signed2 v = img[j];
        sqr[j] = v * v;
    }
    signed2 *var = boxaverage ( sqr, sx, sy, wx, wy );

    /**
     * The normalization process. Currenlty still
     * calculated as doubles. Could probably be fixed
     * to integers too. The only problem is the sqrt
     */
    for ( j = 0; j < sx * sy; j++ )
    {
        double v = sqrt ( fabs ( var[j] ) );
        assert ( isfinite ( v ) && v >= 0 );
        if ( v < 0.0001 )
            v = 0.0001;
        img[j] *= 32 / v;
        if ( img[j] > 127 )
            img[j] = 127;
        if ( img[j] < -127 )
            img[j] = -127;
    }

    /**
     * Mean was allocated in the boxaverage function
     * Sqr was allocated in this function
     * Var was allocated through boxaveragering
     */
    free (mean);
    free (sqr);
    free (var);

    /**
     * As a last step in the normalization we
     * window the sub image around the borders
     * to become 0
     */
    window ( img, sx, sy, wx, wy );

}


signed2* DWVB::boxaverage(signed2 * input, int sx, int sy, int wx, int wy )
{
    signed2 *horizontalmean = ( signed2 * ) malloc ( sizeof ( signed2 ) * sx * sy );
    assert ( horizontalmean );
    int wx2 = wx / 2;
    int wy2 = wy / 2;
    signed2 *from = input + ( sy - 1 ) * sx;
    signed2 *to = horizontalmean + ( sy - 1 ) * sx;
    int initcount = wx - wx2;
    if ( sx < initcount )
        initcount = sx;
    int xli = -wx2;
    int xri = wx - wx2;
    for ( ; from >= input; from -= sx, to -= sx )
    {
        signed8 sum = 0;
        int count = initcount;
        int c = 0;
        for ( c = 0; c < count; c++ )
            sum += ( signed8 ) from[c];
        to[0] = sum / count;
        int xl = xli, x = 1, xr = xri;
        /**
         * The area where the window is slightly outside the
         * left boundary. Beware: the right bnoundary could be
         * outside on the other side already
         */
        for ( ; x < sx; x++, xl++, xr++ )
        {
            if ( xl >= 0 )
                break;
            if ( xr < sx )
            {
                sum += ( signed8 ) from[xr];
                count++;
            }
            to[x] = sum / count;
        }
        /**
         * both bounds of the sliding window
         * are fully inside the images
         */
        for ( ; xr < sx; x++, xl++, xr++ )
        {
            sum -= ( signed8 ) from[xl];
            sum += ( signed8 ) from[xr];
            to[x] = sum / count;
        }
        /**
         * the right bound is falling of the page
         */
        for ( ; x < sx; x++, xl++ )
        {
            sum -= ( signed8 ) from[xl];
            count--;
            to[x] = sum / count;
        }
    }

    /**
     * The same process as aboe but for the vertical dimension now
     */
    int ssy = ( sy - 1 ) * sx + 1;
    from = horizontalmean + sx - 1;
    signed2 *verticalmean = ( signed2 * ) malloc ( sizeof ( signed2 ) * sx * sy );
    assert ( verticalmean );
    to = verticalmean + sx - 1;
    initcount = wy - wy2;
    if ( sy < initcount )
        initcount = sy;
    int initstopat = initcount * sx;
    int yli = -wy2 * sx;
    int yri = ( wy - wy2 ) * sx;
    for ( ; from >= horizontalmean; from--, to-- )
    {
        signed8 sum = 0;
        int count = initcount;
        int d = 0;
        for ( d = 0; d < initstopat; d += sx )
            sum += ( signed8 ) from[d];
        to[0] = sum / count;
        int yl = yli, y = 1, yr = yri;
        for ( ; y < ssy; y += sx, yl += sx, yr += sx )
        {
            if ( yl >= 0 )
                break;
            if ( yr < ssy )
            {
                sum += ( signed8 ) from[yr];
                count++;
            }
            to[y] = sum / count;
        }
        for ( ; yr < ssy; y += sx, yl += sx, yr += sx )
        {
            sum -= ( signed8 ) from[yl];
            sum += ( signed8 ) from[yr];
            to[y] = sum / count;
        }
        for ( ; y < ssy; y += sx, yl += sx )
        {
            sum -= ( signed8 ) from[yl];
            count--;
            to[y] = sum / count;
        }
    }
    free ( horizontalmean );
    return verticalmean;
}

void DWVB::window(signed2 * img, int sx, int sy, int wx, int wy )
{
    int wx2 = wx / 2;
    int sxsy = sx * sy;
    int sx1 = sx - 1;
    int x = 0;
    int y = 0;
    for ( x = 0; x < wx2; x++ )
        for ( y = 0; y < sxsy; y += sx )
        {
            img[x + y] = img[x + y] * x / wx2;
            img[sx1 - x + y] = img[sx1 - x + y] * x / wx2;
        }

    int wy2 = wy / 2;
    int syb = ( sy - 1 ) * sx;
    int syt = 0;
    for ( y = 0; y < wy2; y++ )
    {
        for ( x = 0; x < sx; x++ )
        {
            /**
              * here we need to recalculate the stuff (*y/wy2)
              * to preserve the discrete nature of integers.
              */
            img[x + syt] = img[x + syt] * y / wy2;
            img[x + syb] = img[x + syb] * y / wy2;
        }
        /**
         * The next row for the top rows
         * The previous row for the bottom rows
         */
        syt += sx;
        syb -= sx;
    }
}
