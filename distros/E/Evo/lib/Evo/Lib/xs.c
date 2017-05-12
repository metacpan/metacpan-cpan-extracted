#define ERRORED (SvTRUE(ERRSV) || !SvPOK(ERRSV))

/*
 * Instead of creating new stacks, we reuse a given one. So that's why no
 * ENTER/LEAVE
 *
 * We create 2 variable
 * a) if errored and catch exists, before catch and free it after invocation
 * b) if errored(settled by catch or catch doesn't exists), before fin. Make
 * immortal this time because we're going to die either in fin or by croak
 *
 * We set new SP in return it. Why not do it in XS? - Because XS syntax sucks
 */

static inline SV **evo_lib_try(int ax, int items, SV **SP) {
  dTHX;

  if (items < 2) croak("Bad usage: got %d args", items);
  SV *try_sv = ST(0);
  SV *catch = ST(1);
  SV *fin = items > 2 && SvTRUE(ST(2)) ? ST(2) : NULL;

  // try
  PUSHMARK(SP);
  int count = call_sv(try_sv, GIMME_V | G_EVAL);

  bool errored = ERRORED;

  // catch
  if (errored && SvTRUE(catch)) {
    PUSHMARK(SP);
    SV *tmp_err = newSVsv(ERRSV);
    PUSHs(tmp_err);
    PUTBACK;
    count = call_sv(catch, GIMME_V | G_EVAL);
    SvREFCNT_dec(tmp_err); // because we don't use ENTER..LEAVE

    errored = ERRORED;
  }
  // before fin because it can reset ERRSV
  SV *err_mcopy = errored ? sv_mortalcopy(ERRSV) : NULL;

  SPAGAIN; // don't call it until now
  if (fin) {
    PUSHMARK(SP);
    call_sv(fin, G_DISCARD | G_NOARGS);
  }
  if (err_mcopy) croak_sv(err_mcopy);

  int sp_index = count - 1;
  SP = &ST(sp_index);

  return SP;
}
