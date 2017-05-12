#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <fftw3.h>

MODULE = Math::FFTW	PACKAGE = Math::FFTW	

SV *
fftw_dft_real2complex_1d(in_sv)
        SV * in_sv
    INIT:
        AV *results;
        double *in;
        fftw_complex *out;
        int N, Nc;

        fftw_plan p;
        int i;

        if ((!SvROK(in_sv))
            || (SvTYPE(SvRV(in_sv)) != SVt_PVAV)
            || ((N = av_len((AV *)SvRV(in_sv))) < 0))
        {
            XSRETURN_UNDEF;
        }
        results = (AV *)sv_2mortal((SV *)newAV());
        N++;
        Nc = (N / 2) + 1;
    CODE:
        in = (double*) fftw_malloc(sizeof(double) * N);
        out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * Nc);
        for (i=0; i < N; i++) {
            in[i] = SvNV(*av_fetch((AV *)SvRV(in_sv), i, 0));
        }
        p = fftw_plan_dft_r2c_1d(N, in, out, FFTW_ESTIMATE);

        fftw_execute(p);

        fftw_destroy_plan(p);

        fftw_free(in);

        for (i=0; i < Nc; i++) {
            av_push(results, newSVnv(out[i][0]));
            av_push(results, newSVnv(out[i][1]));
        }

        fftw_free(out);

        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL


SV *
fftw_idft_complex2real_1d(in_sv)
        SV * in_sv
    INIT:
        AV *results;
        fftw_complex *in;
        double *out;
        int Ncoeff, N, Nc;

        fftw_plan p;
        int i;

        if ((!SvROK(in_sv))
            || (SvTYPE(SvRV(in_sv)) != SVt_PVAV)
            || ((Ncoeff = av_len((AV *)SvRV(in_sv))) < 0))
        {
            XSRETURN_UNDEF;
        }
        results = (AV *)sv_2mortal((SV *)newAV());
        Ncoeff++;
        N = ((Ncoeff / 2) - 1) * 2;
        Nc = Ncoeff / 2;
    CODE:
        out = (double*) fftw_malloc(sizeof(double) * N);
        in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * Nc);

        for (i=0; i < Nc; i++) {
            in[i][0] = SvNV(*av_fetch((AV *)SvRV(in_sv), i*2, 0));
            in[i][1] = SvNV(*av_fetch((AV *)SvRV(in_sv), i*2+1, 0));
        }
        p = fftw_plan_dft_c2r_1d(N, in, out, FFTW_ESTIMATE);

        fftw_execute(p);

        fftw_destroy_plan(p);

        fftw_free(in);

        for (i=0; i < N; i++) {
/*            av_push(results, newSVnv( out[i] ));
 */
            av_push(results, newSVnv( out[i] / (double) N ));
 
        }

        fftw_free(out);

        RETVAL = newRV((SV *)results);
    OUTPUT:
        RETVAL


