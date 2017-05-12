static int eca_mg_free(pTHX_ SV *sv, MAGIC *mg);
static int eca_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param);

static ECAslot *eca_dup(const ECAslot *src);
static void eca_destroy(ECAslot *slot);

static MGVTBL ECA_TBL = {0, 0, 0, 0, eca_mg_free, 0, eca_mg_dup, 0};

/*
 * ECAslot is a C structure
 * eca_new_sv creates an SV with a pointer to that structure. Magic need to
 * duplicate a structure(threads) and clear it. Don't forget:
 * mg->mg_flags |= MGf_DUP;
 *
 * slot->key contains a "shared" string.
 *
 * value, check, inject could be NULLs
 *
 * Don't try to move magic for CV, because one slot can be bound to both (new
 * and accessor)
 */

static int eca_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
  SV *sv = mg->mg_obj;
  ECAslot *dup = eca_dup(sv2slot(sv));
  sv_setuv(sv, PTR2UV(dup));
  PERL_UNUSED_VAR(param);
  return 0;
}

static int eca_mg_free(pTHX_ SV *sv, MAGIC *mg) {
  ECAslot *slot = sv2slot(mg->mg_obj);
  PERL_UNUSED_VAR(sv);
  eca_destroy(slot);
  return 0;
}

static ECAslot *eca_init(char *name, ECAtype type, SV *value, SV *check,
                         bool is_ro, SV *inject, bool is_method) {
  dTHX;

  ECAslot *slot = calloc(1, sizeof(ECAslot));
  if (!slot) croak("Can't allocate memory");

  switch (type) {

  case ECA_OPTIONAL:
    break;
  case ECA_LAZY: // no need to store undef
    if (SvTRUE(value)) slot->value = newSVsv(value);
    break;
  case ECA_DEFAULT:
  case ECA_DEFAULT_CODE:
  case ECA_REQUIRED:
    slot->value = newSVsv(value);
    break;
  default:
    croak("Bad type: %d", type);
    break;
  }

  if (SvTRUE(check)) slot->check = newSVsv(check);
  if (SvTRUE(inject)) slot->inject = newSVsv(inject);
  slot->is_ro = is_ro;
  slot->is_method = is_method;
  slot->type = type;
  slot->key = newSVpv_share(name, 0);
  return slot;
}

static SV *eca_new_sv(char *name, ECAtype type, SV *value, SV *check,
                      bool is_ro, SV *inject, bool is_method) {

  dTHX;
  ECAslot *slot = eca_init(name, type, value, check, is_ro, inject, is_method);
  SV *result_sv = newSVuv(PTR2UV(slot));
  MAGIC *mg =
      sv_magicext(result_sv, result_sv, PERL_MAGIC_ext, &ECA_TBL, NULL, 0);
  mg->mg_flags |= MGf_DUP; // to invoke attrs_dup
  return result_sv;
}

static void eca_destroy(ECAslot *slot) {
  dTHX;
  if (slot->value) SvREFCNT_dec(slot->value);
  if (slot->check) SvREFCNT_dec(slot->check);
  if (slot->inject) SvREFCNT_dec(slot->inject);
  SvREFCNT_dec(slot->key);

  free(slot);
}

static ECAslot *eca_dup(const ECAslot *src) {
  dTHX;
  ECAslot *dup = calloc(1, sizeof(*src));
  if (!dup) croak("can't locate memory");

  dup->key = newSVpv_share(SvPV_nolen(src->key), 0);
  if (src->value) dup->value = newSVsv(src->value);
  if (src->check) dup->check = newSVsv(src->check);
  if (src->inject) dup->inject = newSVsv(src->inject);
  return dup;
}
