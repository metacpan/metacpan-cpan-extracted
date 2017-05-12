#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"


MODULE = Math::Derivative_XS		PACKAGE = Math::Derivative_XS		

void
Derivative2(x, y, yp1_sv = NULL, ypn_sv = NULL)
        AV * x
        AV * y
        SV * yp1_sv
        SV * ypn_sv
    PPCODE:
        {
            int i;
            int n = av_len(x);
            NV * y2 = calloc(n, sizeof(NV));
            NV * u = calloc(n, sizeof(NV));

            if (!yp1_sv || !SvOK(yp1_sv))
            {
                y2[0] = 0;
                u[0] = 0;
            }
            else
            {
                y2[0] = -0.5;
                NV x_0 = SvNV(*av_fetch(x, 0, 1));
                NV x_1 = SvNV(*av_fetch(x, 1, 1));
                NV y_0 = SvNV(*av_fetch(y, 0, 1));
                NV y_1 = SvNV(*av_fetch(y, 1, 1));

                u[0] = (3 / x_1 - x_0) * ((y_1 - y_0)/(x_1 - x_0) - SvNV(yp1_sv));
            }

            NV x_i_minus_1 = SvNV(*av_fetch(x, 0, 1));
            NV x_i = SvNV(*av_fetch(x, 1, 1));
            NV y_i_minus_1 = SvNV(*av_fetch(y, 0, 1));
            NV y_i = SvNV(*av_fetch(y, 1, 1));

            for (i=1; i < n; i++)
            {
                NV x_i_plus_1 = SvNV(*av_fetch(x, i+1, 1));
                NV y_i_plus_1 = SvNV(*av_fetch(y, i+1, 1));

                NV sig = (x_i - x_i_minus_1) / (x_i_plus_1 - x_i_minus_1);
                NV p = sig * y2[i-1] + 2.;
                y2[i] = (sig - 1.) / p;
                u[i] = (6.0 * ( (y_i_plus_1 - y_i) / (x_i_plus_1 - x_i) -
                                (y_i - y_i_minus_1) / (x_i - x_i_minus_1)
                            )/
                        (x_i_plus_1 - x_i_minus_1) -sig * u[i-1]) / p;

                x_i_minus_1 = x_i;
                x_i = x_i_plus_1;
                y_i_minus_1 = y_i;
                y_i = y_i_plus_1;
            }

            NV qn, un;
            if (!ypn_sv || !SvOK(ypn_sv))
            {
                qn = 0;
                un = 0;
            }
            else
            {
                NV x_n = SvNV(*av_fetch(x, n, 1));
                NV x_n_minus_1 = SvNV(*av_fetch(x, n-1, 1));
                NV y_n = SvNV(*av_fetch(y, n, 1));
                NV y_n_minus_1 = SvNV(*av_fetch(y, n-1, 1));
                NV ypn = SvNV(ypn_sv);

                qn = 0.5;
                un = (3. / (x_n - x_n_minus_1)) *
                     (ypn - (y_n - y_n_minus_1) / (x_n - x_n_minus_1));
            }

            y2[n] = (un - qn * u[n-1]) / (qn * y2[n-1] + 1.);

            for(i=n-1; i>=0; --i)
            {
                y2[i] = y2[i] * y2[i+1] + u[i];
            }

            EXTEND(SP, n);
            for (i=0; i <= n; i++)
                mPUSHn(y2[i]);

            free(y2);
            free(u);
        }
