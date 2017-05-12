void **av_to_pp(pTHX_ AV* av, char *ctx, char *avname, char *typename)
{
  void **ptr;
  SSize_t idx, size = av_len(av) + 1;
  if (size == 0)
    return NULL;

  ptr = malloc(size * sizeof(void*));
  for (idx = 0; idx < size; idx++) {
    SV **val = av_fetch(av, idx, 0);
    if (!val)
      Perl_croak(aTHX_ "%s: %s[%d] is missing", ctx, avname, idx);
    if (SvROK(*val) && sv_derived_from(*val, typename)) {
      IV tmp = SvIV((SV*) SvRV(*val));
      ptr[idx] = INT2PTR(void*, tmp);
    } else {
      Perl_croak(aTHX_ "%s: %s[%d] is not %s", ctx, avname, idx, typename);
    }
  }
  return ptr;
}

#define AVPP_PREINIT(av, type)                  \
  type* ptr_##av;                               \
  int num_##av;

#define AVPP_CODE(av, ctx, type, typename) {                    \
    num_##av = av_len(av) + 1;                            \
    ptr_##av = (type*) av_to_pp(aTHX_ av, ctx, #av, typename);  \
  }

#define AVPP_CLEANUP(av)                        \
  if(ptr_##av) free(ptr_##av);
