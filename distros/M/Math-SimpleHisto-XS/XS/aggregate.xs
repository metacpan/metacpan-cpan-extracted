MODULE = Math::SimpleHisto::XS    PACKAGE = Math::SimpleHisto::XS


double
integral(self, from, to, type = 0)
    simple_histo_1d* self
    double from
    double to
    int type
  PREINIT:
    double* data;
    unsigned int i, n;
    double binsize;
    bool invert = 0;
  CODE:
    /* TODO nonconstant bins */
    if (from > to) {
      binsize = from; /* abuse as temp var */
      from = to;
      to = binsize;
      invert = 1;
    }

    data = self->data;
    binsize = self->binsize;

    /* FIXME handle both to/from being off limits on the same side*/
    if (to >= self->max)
      to = self->max;
    if (from < self->min)
      from = self->min;

    /*for (i = 1; i < self->nbins; ++i)
      printf("%u: %f ", i, data[i]);
    printf("\n");
    */

    switch(type) {
      case INTEGRAL_CONSTANT:
        if (self->bins == NULL) {
          /* first (fractional) bin */
          from = (from - self->min) / binsize;
          i = (int)from;
          from -= (double)i;

          /* last (fractional) bin */
          to = (to - self->min) / binsize;
          n = (int)to;
          to -= (double)n;
          if (i == n) {
            RETVAL = (to-from) * data[i];
          }
          else {
            RETVAL = data[i] * (1.-from)
                     + data[n] * to;
            ++i;
            for (; i < n; ++i)
              RETVAL += data[i];
          }
        }
        else { /* variable bin size */
          /* TODO optimize */
          double* bins = self->bins;
          unsigned int nbins = self->nbins;

          i = find_bin_nonconstant(from, nbins, bins);
          binsize = (bins[i+1]-bins[i]);
          RETVAL = (bins[i+1]-from)/binsize * data[i]; /* distance from 'from' to upper boundary of bin times data in bin */

          n = find_bin_nonconstant(to, nbins, bins);
          if (i == n) {
            RETVAL -= (bins[i+1]-to)/binsize * data[i];
          }
          else {
            ++i;
            for (; i < n; ++i) {
              RETVAL += data[i];
            }
            binsize = bins[n+1]-bins[n];
            RETVAL += data[n] * (to-bins[n])/binsize;
          }
        }
        break;
      default:
        croak("Invalid integration type");
    };
    if (invert)
      RETVAL *= -1.;
  OUTPUT: RETVAL


double
mean(self)
    simple_histo_1d* self
  CODE:
    RETVAL = histo_mean(aTHX_ self);
  OUTPUT: RETVAL

double
standard_deviation(self, ...)
    simple_histo_1d* self
  CODE:
    if (items > 1)
      RETVAL = histo_standard_deviation_with_mean(aTHX_ self, SvNV(ST(1)));
    else
      RETVAL = histo_standard_deviation(aTHX_ self);
  OUTPUT: RETVAL

double
median(self)
    simple_histo_1d* self
  PREINIT:
  CODE:
    RETVAL = histo_median(aTHX_ self);
  OUTPUT: RETVAL


double
median_absolute_deviation(self, ...)
    simple_histo_1d* self
  PREINIT:
    double median;
    double *x, *data;
    unsigned int i, n;
    simple_histo_1d* madhist;
  CODE:
    
    if (items == 2)
      median = SvNV(ST(1));
    else if (items == 1)
      median = histo_median(aTHX_ self);

    /* FIXME think hard about the optimal nbins here. Also wrt. variable bin size */
    madhist = histo_alloc_new_fixed_bins(aTHX_ self->nbins, 0., self->width);
    
    n = self->nbins;
    data = self->data;
    Newx(x, n, double);
    if (self->bins == 0) {
      double min = self->min;
      double binsize = self->binsize;
      for (i = 0; i < n; ++i) {
        /* abs(median-bin_center) */
        x[i] = fabs( median - (min + binsize * (i + 0.5)) );
      }
    }
    else { /* variable bin size */
      double* bins = self->bins;
      for (i = 0; i < n; ++i) {
        x[i] = fabs( median - 0.5*(bins[i]+bins[i+1]) );
      }
    }
    histo_fill(madhist, n, x, data);
    Safefree(x);

    RETVAL = histo_median(aTHX_ madhist);
    HS_DEALLOCATE(madhist);
  OUTPUT: RETVAL


