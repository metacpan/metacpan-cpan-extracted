#ifndef histo_perl_interf_h_
#define histo_perl_interf_h_

/* This file is purely for inclusion in the XS and defines
 * (STATIC) functions for C-histogram <=> Perl interfacing
 */

STATIC
SV*
histo_ary_to_AV_internal(pTHX_ unsigned int n, double* ary) {
  AV* av;
  unsigned int i;
  SV* rv;

  av = newAV();
  rv = (SV*)newRV((SV*)av);
  SvREFCNT_dec(av);

  av_fill(av, n-1);
  for (i = 0; i < n; ++i) {
    av_store(av, (int)i, newSVnv(ary[i]));
  }

  return rv;
}

STATIC
SV*
histo_data_av(pTHX_ simple_histo_1d* self) {
  return histo_ary_to_AV_internal(aTHX_ self->nbins, self->data);
}

STATIC
SV*
histo_bins_av(pTHX_ simple_histo_1d* self) {
  return histo_ary_to_AV_internal(aTHX_ self->nbins+1, self->bins);
}


#endif
