
MODULE = Math::Histogram    PACKAGE = Math::Histogram::Axis

mh_axis_t *
mh_axis_t::new(...)
  PREINIT:
    SV *tmp;
    AV *bins;
    I32 n, i;
    double prev;
    double *dbl_ary;
  CODE:
    /* varbins => just a single arrayref */
    if (items == 2) {
      tmp = ST(1);
      DEREF_RV_TO_AV(bins, tmp);
      if (bins == NULL)
        croak("Need either array reference as first parameter or a number of bins followed by min/max");
      n = av_len(bins) + 1;
      if (n <= 1)
        croak("Bins array must have at least a lower and upper boundary for a single bin");

      RETVAL = mh_axis_create( n-1, MH_AXIS_OPT_VARBINS );
      if (RETVAL == NULL)
        croak("Cannot create Math::Histogram::Axis! Invalid number of bins or out of memory.");

      av_to_double_ary(aTHX_ bins, RETVAL->bins);

      /* Check whether the numbers make some basic sense */
      dbl_ary = RETVAL->bins;
      prev = dbl_ary[0];
      for (i = 1; i < n; ++i) {
        if (dbl_ary[i] <= prev) {
          mh_axis_free(RETVAL);
          croak("Bin boundaries for histogram axis are not strictly monotonic!");
        }
        prev = dbl_ary[i];
      }
      mh_axis_init( RETVAL, RETVAL->bins[0], RETVAL->bins[n-1] );
    }
    /* fixbins => n, min, max */
    else if (items == 4) {
      RETVAL = mh_axis_create( SvUV(ST(1)), MH_AXIS_OPT_FIXEDBINS );
      if (RETVAL == NULL)
        croak("Cannot create Math::Histogram::Axis! Invalid number of bins or out of memory.");
      prev = SvNV(ST(2));
      if (prev >= SvNV(ST(3))) {
        mh_axis_free(RETVAL);
        croak("Lower axis boundary (%f) cannot be larger than or equal to upper boundary (%f)!", prev, SvNV(ST(3)));
      }
      mh_axis_init( RETVAL, prev, SvNV(ST(3)) );
    }
  OUTPUT: RETVAL


void
mh_axis_t::DESTROY()
  CODE:
    /* free only if not owned by some histogram */
    if (!( PTR2UV(MH_AXIS_USERDATA(THIS)) & F_AXIS_OWNED_BY_HIST ))
      mh_axis_free(THIS);


void
mh_axis_t::_as_hash()
  PREINIT:
    SV *rv;
  PPCODE:
    rv = sv_2mortal(axis_to_hashref(aTHX_ THIS));
    XPUSHs(rv);
    XSRETURN(1);


mh_axis_t *
_from_hash(CLASS, hash)
    char *CLASS;
    HV *hash;
  CODE:
    RETVAL = hash_to_axis(aTHX_ hash);
  OUTPUT: RETVAL


mh_axis_t *
mh_axis_t::clone()
  PREINIT:
    const char *CLASS = "Math::Histogram::Axis"; /* hack around deficient typemap */
  CODE:
    RETVAL = mh_axis_clone(THIS);
  OUTPUT: RETVAL


unsigned int
mh_axis_t::nbins()
  CODE:
    RETVAL = MH_AXIS_NBINS(THIS);
  OUTPUT: RETVAL


double
mh_axis_t::min()
  CODE:
    RETVAL = MH_AXIS_MIN(THIS);
  OUTPUT: RETVAL


double
mh_axis_t::max()
  CODE:
    RETVAL = MH_AXIS_MAX(THIS);
  OUTPUT: RETVAL


double
mh_axis_t::width()
  CODE:
    RETVAL = MH_AXIS_WIDTH(THIS);
  OUTPUT: RETVAL



double
mh_axis_t::binsize(unsigned int ibin = 1)
  CODE:
    ASSERT_BIN_RANGE(THIS, ibin);
    RETVAL = MH_AXIS_BINSIZE(THIS, ibin);
  OUTPUT: RETVAL


double
mh_axis_t::lower_boundary(unsigned int ibin = 1)
  CODE:
    ASSERT_BIN_RANGE(THIS, ibin);
    RETVAL = MH_AXIS_BIN_LOWER(THIS, ibin);
  OUTPUT: RETVAL


double
mh_axis_t::upper_boundary(unsigned int ibin = 1)
  CODE:
    ASSERT_BIN_RANGE(THIS, ibin);
    RETVAL = MH_AXIS_BIN_UPPER(THIS, ibin);
  OUTPUT: RETVAL


double
mh_axis_t::bin_center(unsigned int ibin = 1)
  CODE:
    ASSERT_BIN_RANGE(THIS, ibin);
    RETVAL = MH_AXIS_BIN_CENTER(THIS, ibin);
  OUTPUT: RETVAL


unsigned int
mh_axis_t::find_bin(double x)
  CODE:
    RETVAL = mh_axis_find_bin(THIS, x);
  OUTPUT: RETVAL

