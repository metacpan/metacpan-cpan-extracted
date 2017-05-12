/*
 * You may want to know that:
 * * I use perl's magic feature to bind an ::Attrs instance to xs_new, ECAslot
 * slot to xs_attr (MGVTBL ATTRS_TBL);
 *
 * * I use magic mg_dup and mg_free to clear and duplicate(for threads) ECAslot
 * instance (MGVTBL ECA_TBL)
 *
 * * For performance reason, CvXSUBANY(cv).any_ptr is used to fetch bound data
 * unless perl was build without usemultiplicity. This will improve performance
 * by 2-4%. This technique was borrowed from Mouse. MAGIC is still used to mark
 * variable for GC.
 *
 * * I use a perl's array as an object for this instance because using pure C
 * structure will make code more complex without real benefits
 *
 */

/* xs_new
 * 0) args_to_uniq behaves like %opts = @_; (delete duplicates). And we can
 * avoid creating hash
 *
 * I) Iterate through slots
 * 1) Iterate through array of args in inner loop, skip consumed(NULL).
 * a) compare slot->key with arg's name. If matched, mark as consumed (NULL).
 * Continue parent's loop(simulate by goto, could be rewritten by function)
 * b) Check, if slot->type is on of REQ/DEF/ type, do action
 *
 * II) If there are not consumed args, croak "unknown attribute"
 */

static MGVTBL ATTRS_TBL = {0, 0, 0, 0, 0, 0, 0, 0};

static void xs_new(pTHX_ SV *cv) {
  PERL_UNUSED_VAR(cv);
  dXSARGS;
  if (items < 1) croak("Usage: class, ref");

  SV *class;
  if (sv_isobject(ST(0))) {
    HV *stash = SvSTASH(SvRV(ST(0)));
    char *class_name = HvNAME(stash);
    class = newSVpv(class_name, 0);
    sv_2mortal(class);
  } else {
    class = ST(0);
  }

  // $class::EVO_CLASS_ATTRS
  const char *SUFFIX = "::EVO_CLASS_ATTRS";
  STRLEN need_len = SvCUR(class) + strlen(SUFFIX) + 1;
  char attrs_name[need_len];
  strcpy(attrs_name, SvPV_nolen(class));
  strncat(attrs_name, SUFFIX, need_len);
  AV *slots = sv2av(get_sv(attrs_name, 0));

  HV *hash = newHV();
  SV *obj = sv_2mortal(newRV_noinc((SV *)hash)); // don't move to the end(leaks)

  SV **args;                                               // uniq args
  int args_count = args_to_uniq(&ST(1), items - 1, &args); // skip 1(class)

  int slots_count = av_top_index(slots) + 1;
  for (int i = 0; i < slots_count; i++) { // NEXT_SLOT:
    ECAslot *slot = sv2slot(av_fetch_or_croak(slots, i));

    // iterage args, null if matched
    for (int j = 0; j < args_count; j += 2) {
      SV *tmp = args[j];
      if (!tmp) continue; // already matched

      if (!sv_cmp(tmp, slot->key)) {
        if (slot->check) do_check(slot->check, args[j + 1], slot->key);
        hv_he_store_or_croak(hash, slot->key, args[j + 1]);
        args[j] = NULL;
        goto NEXT_SLOT;
        args[j] = NULL; // mark as consumed
      }
    }

    // slot not found in passed args, decide what to do
    switch (slot->type) {
    case ECA_REQUIRED:
      croak("Attribute \"%s\" is required", SvPV_nolen(slot->key));
      break;
    case ECA_DEFAULT:
      hv_he_store_or_croak(hash, slot->key, slot->value);
      break;
    case ECA_DEFAULT_CODE:
      invoke_and_store(class, slot->value, hash, slot->key);
      break;
    case ECA_LAZY:
    case ECA_OPTIONAL:
      break;
    }

  NEXT_SLOT:; // simulate continue label
  }

  // todo: croak all superfluous
  for (int j = 0; j < args_count; j += 2) {
    if (args[j]) croak("Unknown attribute %s", SvPV_nolen(args[j]));
  }

  sv_bless(obj, gv_stashsv(class, GV_ADD));
  ST(0) = obj;
  XSRETURN(1);
}

static void xs_attr(pTHX_ SV *cv) {
  dXSARGS;
  // checks
  if (items < 1) croak("Bad usage");
  SV *self = ST(0);
  if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)) croak("Not a HASH");
  HV *hash = (HV *)SvRV(self);

  SV *result = &PL_sv_undef;

#ifndef MULTIPLICITY
  ECAslot *slot = CvXSUBANY(cv).any_ptr;
#else
  MAGIC *mg = mg_findext(cv, PERL_MAGIC_ext, &ATTRS_TBL);
  ECAslot *slot = sv2slot(mg->mg_obj);
#endif

  if (items == 1) { // get
    HE *he = hv_fetch_ent(hash, slot->key, 0, 0);
    if (he) {
      result = HeVAL(he);
    } else {
      if (slot->type == ECA_LAZY) {
        result = invoke_and_store(self, slot->value, hash, slot->key);
      } else {
        result = &PL_sv_undef;
      }
    }
  } else { // set
    if (slot->is_ro)
      croak("Attribute \"%s\" is readonly", SvPV_nolen(slot->key));
    if (slot->check) do_check(slot->check, ST(1), slot->key);
    hv_he_store_or_croak(hash, slot->key, ST(1));
    result = self;
  }

  ST(0) = result;
  XSRETURN(1);
};

/* XS FUNCTIONS */
static SV *attrs__gen_attr(SV *self, char *name, int type, SV *value, SV *check,
                           bool is_ro, SV *inject, bool method) {
  dTHX;
  AV *av = sv2av(self);
  SV *slot_sv = eca_new_sv(name, type, value, check, is_ro, inject, method);
  ECAslot *slot = sv2slot(slot_sv);

  // register... i will be either last + 1 or matched element
  int i, last = av_top_index(av);
  for (i = 0; i <= last; i++) {
    SV *tmp_sv = av_fetch_or_croak(av, i);
    ECAslot *cur = sv2slot(tmp_sv);
    if (!sv_cmp(cur->key, slot->key)) break;
  }
  if (!av_store(av, i, slot_sv)) croak("Can't store");

  // generate cv
  CV *xsub = newXS(NULL, (XSUBADDR_t)xs_attr, __FILE__);
  sv_magicext((SV *)xsub, slot_sv, PERL_MAGIC_ext, &ATTRS_TBL, NULL, 0);
#ifndef MULTIPLICITY
  CvXSUBANY(xsub).any_ptr = sv2slot(slot_sv);
#endif
  return newRV_noinc((SV *)xsub);
}

static SV *attrs_gen_new(SV *self) {
  dTHX;
  PERL_UNUSED_VAR(self);
  CV *xsub = newXS(NULL, (XSUBADDR_t)xs_new, __FILE__);
  return newRV_noinc((SV *)xsub);
}

static bool attrs_exists(SV *self, SV *name) {
  dTHX;

  AV *av = sv2av(self);
  int i, size = av_top_index(av) + 1;

  for (i = 0; i < size; i++) {
    SV *tmp_sv = av_fetch_or_croak(av, i);
    ECAslot *slot = sv2slot(tmp_sv);
    if (!sv_cmp(name, slot->key)) return 1;
  }
  return false;
}
