MODULE = Math::SimpleHisto::XS    PACKAGE = Math::SimpleHisto::XS


void
bin_centers(self)
    simple_histo_1d* self
  PREINIT:
    AV* av;
    SV* rv;
    int i, n;
    double x;
  PPCODE:
    av = newAV();
    rv = (SV*)newRV((SV*)av);
    SvREFCNT_dec(av);
    n = self->nbins;
    av_fill(av, n-1);
    if (self->bins == NULL) {
      double binsize = self->binsize;
      x = self->min + 0.5*binsize;
      for (i = 0; i < n; ++i) {
        av_store(av, i, newSVnv(x));
        x += binsize;
      }
    }
    else {
      double* bins = self->bins;
      for (i = 0; i < n; ++i) {
        x = 0.5*(bins[i] + bins[i+1]);
        av_store(av, i, newSVnv(x));
      }
    }
    XPUSHs(sv_2mortal(rv));


double
bin_center(self, ibin)
    simple_histo_1d* self
    unsigned int ibin
  CODE:
    HS_ASSERT_BIN_RANGE(self, ibin);
    RETVAL = HS_BIN_CENTER(self, ibin);
  OUTPUT: RETVAL


double
bin_lower_boundary(self, ibin)
    simple_histo_1d* self
    unsigned int ibin
  CODE:
    HS_ASSERT_BIN_RANGE(self, ibin);
    RETVAL = HS_BIN_LOWER_BOUNDARY(self, ibin);
  OUTPUT: RETVAL


double
bin_upper_boundary(self, ibin)
    simple_histo_1d* self
    unsigned int ibin
  CODE:
    HS_ASSERT_BIN_RANGE(self, ibin);
    RETVAL = HS_BIN_UPPER_BOUNDARY(self, ibin);
  OUTPUT: RETVAL


void
bin_lower_boundaries(self)
    simple_histo_1d* self
  PREINIT:
    AV* av;
    SV* rv;
    int i, n;
  PPCODE:
    /* inlines HS_BIN_LOWER_BOUNDARY somewhat for unrolling */
    av = newAV();
    rv = (SV*)newRV((SV*)av);
    SvREFCNT_dec(av);
    n = self->nbins;
    av_fill(av, n-1);
    if (self->bins == NULL) {
      double binsize = self->binsize;
      double x = self->min;
      for (i = 0; i < n; ++i) {
        av_store(av, i, newSVnv(x));
        x += binsize;
      }
    }
    else {
      double* bins = self->bins;
      for (i = 0; i < n; ++i) {
        av_store(av, i, newSVnv(bins[i]));
      }
    }
    XPUSHs(sv_2mortal(rv));


void
bin_upper_boundaries(self)
    simple_histo_1d* self
  PREINIT:
    AV* av;
    SV* rv;
    int i, n;
    double x, binsize;
  PPCODE:
    /* inlines HS_BIN_UPPER_BOUNDARY somewhat for unrolling */
    av = newAV();
    rv = (SV*)newRV((SV*)av);
    SvREFCNT_dec(av);
    n = self->nbins;
    av_fill(av, n-1);
    if (self->bins == NULL) {
      binsize = self->binsize;
      x = self->min;
      for (i = 0; i < n; ++i) {
        x += binsize;
        av_store(av, i, newSVnv(x));
      }
    }
    else {
      double* bins = self->bins;
      for (i = 0; i < n; ++i) {
        av_store(av, i, newSVnv(bins[i+1]));
      }
    }
    XPUSHs(sv_2mortal(rv));


unsigned int
find_bin(self, x)
    simple_histo_1d* self
    double x
  CODE:
    if (x >= self->max || x < self->min) {
      XSRETURN_UNDEF;
    }
    RETVAL = histo_find_bin(self, x);
  OUTPUT: RETVAL


