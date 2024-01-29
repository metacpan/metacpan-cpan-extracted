/* vi: set ft=c : */

static void S_croaksv_from_caller(pTHX_ SV *msg_sv)
  __attribute__noreturn__;

static void S_croaksv_from_caller(pTHX_ SV *msg_sv)
{
  I32 count = 0;
  const PERL_CONTEXT *cx;
  while((cx = caller_cx(count, NULL))) {
    count++;

    /* TODO: Skip internal call frames? */
    /* warn("TODO: maybe croak from caller where caller stash is %s\n",
     *   HvNAME(CopSTASH(cx->blk_oldcop)));
     */
    PL_curcop = cx->blk_oldcop;
    break;
  }

  croak_sv(msg_sv);
}

#define croak_from_caller(fmt, ...)  S_croak_from_caller(aTHX_ fmt, __VA_ARGS__)
static void S_croak_from_caller(pTHX_ const char *fmt, ...)
  __attribute__noreturn__;

static void S_croak_from_caller(pTHX_ const char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  SV *msg_sv = sv_2mortal(vnewSVpvf(fmt, &args));
  va_end(args);

  S_croaksv_from_caller(aTHX_ msg_sv);
}
