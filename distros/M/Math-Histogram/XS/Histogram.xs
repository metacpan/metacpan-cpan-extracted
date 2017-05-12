
MODULE = Math::Histogram    PACKAGE = Math::Histogram

mh_histogram_t *
mh_histogram_t::new(AV *axises)
  PREINIT:
    mh_axis_t **axis_structs;
    mh_axis_t *tmp_axis;
    unsigned int i, n;
  CODE:
    n = av_len(axises)+1;
    if (n == 0)
      croak("Need array reference of axis objetcs");
    axis_structs = av_to_axis_ary(aTHX_ axises, n);
    if (axis_structs == NULL)
      croak("Need array reference of axis objetcs");

    for (i = 0; i < n; ++i) {
      tmp_axis = axis_structs[i];
      /* Clone axis if owned by histogram, otherwise set the "ownership" bit */
      if (PTR2UV(MH_AXIS_USERDATA(tmp_axis)) & F_AXIS_OWNED_BY_HIST)
        axis_structs[i] = mh_axis_clone(tmp_axis);
      else {
        UV flags = PTR2UV(MH_AXIS_USERDATA(tmp_axis));
        flags |= F_AXIS_OWNED_BY_HIST;
        MH_AXIS_USERDATA(tmp_axis) = INT2PTR(void *, flags);
      }
    }

    RETVAL = mh_hist_create(n, axis_structs);
  OUTPUT: RETVAL


void
mh_histogram_t::DESTROY()
  CODE:
    mh_hist_free(THIS);


mh_histogram_t *
mh_histogram_t::clone()
  PREINIT:
    const char *CLASS = "Math::Histogram";
  CODE:
    RETVAL = mh_hist_clone(THIS, 1); /* 1 => do clone data */
  OUTPUT: RETVAL


mh_histogram_t *
mh_histogram_t::new_alike()
  PREINIT:
    const char *CLASS = "Math::Histogram";
  CODE:
    RETVAL = mh_hist_clone(THIS, 0); /* 0 => do NOT clone data */
  OUTPUT: RETVAL


mh_axis_t *
mh_histogram_t::get_axis(unsigned int dimension)
  PREINIT:
    const char *CLASS = "Math::Histogram::Axis";
  CODE:
    if (dimension >= MH_HIST_NDIM(THIS))
      croak("Dimension number out of bounds: %u", dimension);
    RETVAL = MH_HIST_AXIS(THIS, dimension);
  OUTPUT: RETVAL


unsigned int
mh_histogram_t::ndim()
  CODE:
    RETVAL = MH_HIST_NDIM(THIS);
  OUTPUT: RETVAL


unsigned int
mh_histogram_t::nfills()
  CODE:
    RETVAL = MH_HIST_NFILLS(THIS);
  OUTPUT: RETVAL


double
mh_histogram_t::total()
  CODE:
    RETVAL = MH_HIST_TOTAL(THIS);
  OUTPUT: RETVAL


AV *
mh_histogram_t::find_bin_numbers(coords)
    AV *coords;
  CODE:
    av_to_double_ary(aTHX_ coords, MH_HIST_ARG_COORD_BUFFER(THIS));
    mh_hist_find_bin_numbers(THIS, MH_HIST_ARG_COORD_BUFFER(THIS), MH_HIST_ARG_BIN_BUFFER(THIS));
    unsigned_int_ary_to_av(aTHX_ MH_HIST_NDIM(THIS), MH_HIST_ARG_BIN_BUFFER(THIS), &RETVAL);
    sv_2mortal((SV*)RETVAL);
  OUTPUT: RETVAL


void
mh_histogram_t::fill(coords)
    AV *coords;
  CODE:
    av_to_double_ary(aTHX_ coords, MH_HIST_ARG_COORD_BUFFER(THIS));
    mh_hist_fill(THIS, MH_HIST_ARG_COORD_BUFFER(THIS));


void
mh_histogram_t::fill_w(coords, weight)
    AV *coords;
    double weight;
  CODE:
    av_to_double_ary(aTHX_ coords, MH_HIST_ARG_COORD_BUFFER(THIS));
    mh_hist_fill_w(THIS, MH_HIST_ARG_COORD_BUFFER(THIS), weight);


void
mh_histogram_t::fill_n(coords)
    AV *coords;
  PREINIT:
    SV **elem;
    SV *sv;
    unsigned int i, n;
  CODE:
    n = av_len(coords)+1;
    /* Fill each individually since we have
     * to do lots of Perl => C conversion anyway */
    for (i = 0; i < n; ++i) {
      elem = av_fetch(coords, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");

      /* Inner array deref */
      sv = *elem;
      SvGETMAGIC(sv);
      if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av_to_double_ary(aTHX_ (AV*)SvRV(sv), MH_HIST_ARG_COORD_BUFFER(THIS));
        mh_hist_fill(THIS, MH_HIST_ARG_COORD_BUFFER(THIS));
      }
      else
        croak("Element with index %u of input array reference is "
              "not an array reference, stopping histogram filling "
              "at that point!", i);
    }


void
mh_histogram_t::fill_nw(coords, weights)
    AV *coords;
    AV *weights;
  PREINIT:
    SV **elem;
    SV *sv;
    unsigned int i, n;
    double weight;
  CODE:
    n = av_len(coords)+1;
    if ((unsigned int)(av_len(weights)+1) != n)
      croak("Coordinates and weights arrays need to be of same size!");

    /* Fill each individually since we have
     * to do lots of Perl => C conversion anyway */
    for (i = 0; i < n; ++i) {
      elem = av_fetch(weights, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");
      weight = SvNV(*elem);

      elem = av_fetch(coords, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");

      /* Inner array deref */
      sv = *elem;
      SvGETMAGIC(sv);
      if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av_to_double_ary(aTHX_ (AV*)SvRV(sv), MH_HIST_ARG_COORD_BUFFER(THIS));
        mh_hist_fill_w(THIS, MH_HIST_ARG_COORD_BUFFER(THIS), weight);
      }
      else
        croak("Element with index %u of input array reference is "
              "not an array reference, stopping histogram filling "
              "at that point!", i);
    }


void
mh_histogram_t::fill_bin(dim_bin_nums)
    AV *dim_bin_nums;
  CODE:
    av_to_unsigned_int_ary(aTHX_ dim_bin_nums, MH_HIST_ARG_BIN_BUFFER(THIS));
    mh_hist_fill_bin(THIS, MH_HIST_ARG_BIN_BUFFER(THIS));


void
mh_histogram_t::fill_bin_w(dim_bin_nums, weight)
    AV *dim_bin_nums;
    double weight;
  CODE:
    av_to_unsigned_int_ary(aTHX_ dim_bin_nums, MH_HIST_ARG_BIN_BUFFER(THIS));
    mh_hist_fill_bin_w(THIS, MH_HIST_ARG_BIN_BUFFER(THIS), weight);


void
mh_histogram_t::fill_bin_n(dim_bin_nums)
    AV *dim_bin_nums;
  PREINIT:
    SV **elem;
    SV *sv;
    unsigned int i, n;
  CODE:
    n = av_len(dim_bin_nums)+1;
    /* Fill each individually since we have
     * to do lots of Perl => C conversion anyway */
    for (i = 0; i < n; ++i) {
      elem = av_fetch(dim_bin_nums, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");

      /* Inner array deref */
      sv = *elem;
      SvGETMAGIC(sv);
      if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av_to_unsigned_int_ary(aTHX_ (AV*)SvRV(sv), MH_HIST_ARG_BIN_BUFFER(THIS));
        mh_hist_fill_bin(THIS, MH_HIST_ARG_BIN_BUFFER(THIS));
      }
      else
        croak("Element with index %u of input array reference is "
              "not an array reference, stopping histogram filling "
              "at that point!", i);
    }


void
mh_histogram_t::fill_bin_nw(dim_bin_nums, weights)
    AV *dim_bin_nums;
    AV *weights;
  PREINIT:
    SV **elem;
    SV *sv;
    unsigned int i, n;
    double weight;
  CODE:
    n = av_len(dim_bin_nums)+1;
    if ((unsigned int)(av_len(weights)+1) != n)
      croak("Bin-numbers and weights arrays need to be of same size!");

    /* Fill each individually since we have
     * to do lots of Perl => C conversion anyway */
    for (i = 0; i < n; ++i) {
      elem = av_fetch(weights, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");
      weight = SvNV(*elem);

      elem = av_fetch(dim_bin_nums, i, 0);
      if (elem == NULL)
        croak("Woah, this should never happen!");

      /* Inner array deref */
      sv = *elem;
      SvGETMAGIC(sv);
      if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
        av_to_unsigned_int_ary(aTHX_ (AV*)SvRV(sv), MH_HIST_ARG_BIN_BUFFER(THIS));
        mh_hist_fill_bin_w(THIS, MH_HIST_ARG_BIN_BUFFER(THIS), weight);
      }
      else
        croak("Element with index %u of input array reference is "
              "not an array reference, stopping histogram filling "
              "at that point!", i);
    }


double
mh_histogram_t::get_bin_content(dim_bin_nums)
    AV *dim_bin_nums;
  PREINIT:
    int rc;
  CODE:
    av_to_unsigned_int_ary(aTHX_ dim_bin_nums, MH_HIST_ARG_BIN_BUFFER(THIS));
    rc = mh_hist_get_bin_content(THIS, MH_HIST_ARG_BIN_BUFFER(THIS), &RETVAL);
    if (rc != 0)
      croak("Bin numbers out of range!");
  OUTPUT: RETVAL


void
mh_histogram_t::set_bin_content(dim_bin_nums, content)
    AV *dim_bin_nums;
    double content;
  PREINIT:
    int rc;
  CODE:
    av_to_unsigned_int_ary(aTHX_ dim_bin_nums, MH_HIST_ARG_BIN_BUFFER(THIS));
    rc = mh_hist_set_bin_content(THIS, MH_HIST_ARG_BIN_BUFFER(THIS), content);
    if (rc != 0)
      croak("Bin numbers out of range!");


mh_histogram_t *
mh_histogram_t::contract_dimension(contracted_dimension)
    unsigned int contracted_dimension;
  PREINIT:
    const char *CLASS = "Math::Histogram"; /* FIXME */
  CODE:
    RETVAL = mh_hist_contract_dimension(THIS, contracted_dimension);
    if (RETVAL == NULL)
      croak("Contracted dimension appears to be out of range!");
  OUTPUT: RETVAL


void
mh_histogram_t::cumulate(cumulation_dimension)
    unsigned int cumulation_dimension;
  PREINIT:
    int rc;
  CODE:
    rc = mh_hist_cumulate(THIS, cumulation_dimension);
    if (rc != 0)
      croak("Cumulated dimension appears to be out of range!");

int
mh_histogram_t::data_equal_to(other)
    mh_histogram_t *other;
  CODE:
    RETVAL = mh_hist_data_equal(THIS, other);
  OUTPUT: RETVAL


int
mh_histogram_t::is_overflow_bin(dim_bin_nums)
    AV *dim_bin_nums;
  CODE:
    av_to_unsigned_int_ary(aTHX_ dim_bin_nums, MH_HIST_ARG_BIN_BUFFER(THIS));
    RETVAL = !!mh_hist_is_overflow_bin(THIS, MH_HIST_ARG_BIN_BUFFER(THIS));
  OUTPUT: RETVAL

int
mh_histogram_t::is_overflow_bin_linear(linear_bin_num)
    unsigned int linear_bin_num;
  CODE:
    RETVAL = !!mh_hist_is_overflow_bin_linear(THIS, linear_bin_num);
  OUTPUT: RETVAL

void
mh_histogram_t::_debug_bin_iter_print()
  CODE:
    mh_hist_debug_bin_iter_print(THIS);

void
mh_histogram_t::_debug_dump_data()
  CODE:
    mh_hist_debug_dump_data(THIS);

void
mh_histogram_t::_as_hash()
  PREINIT:
    SV *rv;
    SV *tmp;
    HV *hash;
    AV *axis_av;
    AV *data_av;
    unsigned int ndim, i, nbins_total;
    double *data;
    mh_axis_t *tmp_axis;
  PPCODE:
    hash = newHV();
    rv = sv_2mortal(newRV_noinc((SV *)hash));

    ndim = MH_HIST_NDIM(THIS);
    if ( ! hv_stores(hash, "ndim", newSVuv(ndim)) )
      croak("hv_stores ndim failed");

    /* store axises */
    axis_av = newAV();
    if ( ! hv_stores(hash, "axises", newRV_noinc((SV *)axis_av)) )
      croak("hv_stores ndim failed");
    av_extend(axis_av, ndim-1);
    for (i = 0; i < ndim; ++i) {
      tmp_axis = MH_HIST_AXIS(THIS, i);
      tmp = axis_to_hashref(aTHX_ MH_HIST_AXIS(THIS, i));
      av_store(axis_av, i, tmp);
    }

    if ( ! hv_stores(hash, "nfills", newSVuv(MH_HIST_NFILLS(THIS))) )
      croak("hv_stores nfills failed");
    if ( !hv_stores(hash, "total", newSVnv(MH_HIST_TOTAL(THIS))) )
      croak("hv_stores total failed");

    /* store data */
    /* FIXME: strictly speaking, this violates encapsulation */
    nbins_total = THIS->nbins_total;
    data_av = newAV();
    if ( ! hv_stores(hash, "data", newRV_noinc((SV *)data_av)) )
      croak("hv_stores data failed");

    av_extend(data_av, nbins_total-1);
    data = THIS->data;
    for (i = 0; i < nbins_total; ++i)
      av_store(data_av, i, newSVnv(data[i]));

    XPUSHs(rv);
    XSRETURN(1);


mh_histogram_t *
_from_hash_internal(CLASS, hash, axises)
    char *CLASS;
    HV *hash;
    AV *axises;
  PREINIT:
    mh_axis_t **axis_structs;
    unsigned int i, n, ndim, nfill;
    double total_content;
    double *data;
    SV **svptr;
    AV *axis_av;
    AV *data_av;
  CODE:
    /* dimensionality */
    HV_FETCHS_FATAL(svptr, hash, "ndim");
    ndim = SvUV( *svptr );
    if (ndim < 1)
      croak("Need at least a dimension of 1");

    /* nfills and total */
    HV_FETCHS_FATAL(svptr, hash, "nfills");
    nfill = SvUV( *svptr );
    HV_FETCHS_FATAL(svptr, hash, "total");
    total_content = SvNV( *svptr );

    /* data array */
    HV_FETCHS_FATAL(svptr, hash, "data");
    DEREF_RV_TO_AV(data_av, *svptr);
    if (data_av == NULL)
      croak("'data' entry is not an array reference");

    /* axises */
    n = av_len(axises)+1;
    if (n != ndim)
      croak("Number of axises needs to be same as number of dimensions");

    axis_structs = av_to_axis_ary(aTHX_ axises, n);
    if (axis_structs == NULL)
      croak("Need array reference of axis objetcs");
    /* Mark the fresh axises as owned by the histogram */
    for (i = 0; i < n; ++i) {
      UV flags = PTR2UV(MH_AXIS_USERDATA(axis_structs[i]));
      flags |= F_AXIS_OWNED_BY_HIST;
      MH_AXIS_USERDATA(axis_structs[i]) = INT2PTR(void *, flags);
    }

    /* make output struct */
    RETVAL = mh_hist_create(ndim, axis_structs);
    RETVAL->nfills = nfill;
    RETVAL->total = total_content;

    /* fill data */
    n = RETVAL->nbins_total;
    if ((unsigned int)(av_len(data_av)+1) != n) {
      free(RETVAL);
      croak("Input data array length (%u) is not the same as the total number of bins in the histogram (%u)", av_len(data_av)+1, n);
    }
    data = RETVAL->data;
    for (i = 0; i < n; ++i) {
      svptr = av_fetch(data_av, i, 0);
      if (svptr == NULL) {
        free(RETVAL);
        croak("Failed to fetch scalar from array!?");
      }
      data[i] = SvNV(*svptr);
    }
  OUTPUT: RETVAL

