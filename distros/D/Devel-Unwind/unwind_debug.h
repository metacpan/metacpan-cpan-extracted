#ifndef _UNWIND_DEBUG_H_
#define _UNWIND_DEBUG_H_

static void _deb_stack(pTHX);
static void _deb_env(pTHX);
static void _deb_cx(pTHX);

#define deb_cx() _deb_cx(aTHX)
#define deb_stack() _deb_stack(aTHX)
#define deb_env() _deb_env(aTHX)

static void DEBUG_printf(char *fmt, ...) {
#ifdef DEBUGGING
    dTHX;
    va_list ap;
    va_start(ap, fmt);
    PerlIO_vprintf(PerlIO_stderr(), fmt, ap);
    va_end(ap);
#else
    PERL_UNUSED_ARG(fmt);
#endif
}

static const char * const si_names[] =
{
    "UNKNOWN","UNDEF","MAIN","MAGIC",
    "SORT","SIGNAL","OVERLOAD","DESTROY",
    "WARNHOOK","DIEHOOK","REQUIRE"
};

static void _deb_env(pTHX) {
#ifdef DEBUGGING
    const JMPENV *env = PL_top_env;
    const JMPENV *eit;
    I32 eix;
    I32 eix_max;

    for (eix_max= -1, eit=env; eit; eit=eit->je_prev, eix_max++);
    warn("env: eix_max=%d\n",eix_max);
    for (eix=0, eit=env; eit; eit=eit->je_prev,eix++) {
        warn("\tlevel=%d je_ret=%d je_mustcatch=%d\n",
             eix_max - eix,
             eit->je_ret,
             eit->je_mustcatch
            );
    }
#else
    PERL_UNUSED_CONTEXT;
#endif
}

static void _deb_stack(pTHX) {
#ifdef DEBUGGING
  const PERL_SI *si = PL_curstackinfo;
  I32 siix;
  while (si->si_prev) {
    si = si->si_prev;
  }
  for (siix = 0; si; si = si->si_next, siix++) {
    I32 cxix;
    warn("stack %d type %s(%d) %p\n",
         siix, si_names[si->si_type + 1], si->si_type, si);
    for (cxix = 0; cxix <= si->si_cxix; cxix++) {
      const PERL_CONTEXT* const cx = &(si->si_cxstack[cxix]);
      warn("\tcxix %d type %s(%d)\n",
           cxix, PL_block_type[CxTYPE(cx)], CxTYPE(cx));
    }
    if (si == PL_curstackinfo) {
      break;
    }
  }
#else
  PERL_UNUSED_CONTEXT;
#endif
}

static void mycx_dump(pTHX_ PERL_CONTEXT *cx);

static void _deb_cx(pTHX)
{
#ifdef DEBUGGING
    dVAR;
    I32 i;
    for (i = PL_curstackinfo->si_cxix; i >= 0; i--) {
        mycx_dump(aTHX_ &PL_curstackinfo->si_cxstack[i]);
    }
#endif
}

static void
mycx_dump(pTHX_ PERL_CONTEXT *cx)
{
    PERL_ARGS_ASSERT_CX_DUMP;

#ifdef DEBUGGING
    PerlIO_printf(Perl_debug_log, "CX %ld = %s\n", (long)(cx - cxstack), PL_block_type[CxTYPE(cx)]);
    if (CxTYPE(cx) != CXt_SUBST) {
	const char *gimme_text;
	PerlIO_printf(Perl_debug_log, "BLK_OLDSP = %ld\n", (long)cx->blk_oldsp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDCOP = 0x%"UVxf"\n",
		      PTR2UV(cx->blk_oldcop));
	PerlIO_printf(Perl_debug_log, "BLK_OLDMARKSP = %ld\n", (long)cx->blk_oldmarksp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDSCOPESP = %ld\n", (long)cx->blk_oldscopesp);
	PerlIO_printf(Perl_debug_log, "BLK_OLDPM = 0x%"UVxf"\n",
		      PTR2UV(cx->blk_oldpm));
	switch (cx->blk_gimme) {
	    case G_VOID:
		gimme_text = "VOID";
		break;
	    case G_SCALAR:
		gimme_text = "SCALAR";
		break;
	    case G_ARRAY:
		gimme_text = "LIST";
		break;
	    default:
		gimme_text = "UNKNOWN";
		break;
	}
	PerlIO_printf(Perl_debug_log, "BLK_GIMME = %s\n", gimme_text);
    }
    switch (CxTYPE(cx)) {
    case CXt_NULL:
    case CXt_BLOCK:
	break;
    case CXt_FORMAT:
	PerlIO_printf(Perl_debug_log, "BLK_FORMAT.CV = 0x%"UVxf"\n",
		PTR2UV(cx->blk_format.cv));
	PerlIO_printf(Perl_debug_log, "BLK_FORMAT.GV = 0x%"UVxf"\n",
		PTR2UV(cx->blk_format.gv));
	PerlIO_printf(Perl_debug_log, "BLK_FORMAT.DFOUTGV = 0x%"UVxf"\n",
		PTR2UV(cx->blk_format.dfoutgv));
	PerlIO_printf(Perl_debug_log, "BLK_FORMAT.HASARGS = %d\n",
		      (int)CxHASARGS(cx));
	PerlIO_printf(Perl_debug_log, "BLK_FORMAT.RETOP = 0x%"UVxf"\n",
		PTR2UV(cx->blk_format.retop));
	break;
    case CXt_SUB:
	PerlIO_printf(Perl_debug_log, "BLK_SUB.CV = 0x%"UVxf"\n",
		PTR2UV(cx->blk_sub.cv));
	PerlIO_printf(Perl_debug_log, "BLK_SUB.OLDDEPTH = %ld\n",
		(long)cx->blk_sub.olddepth);
	PerlIO_printf(Perl_debug_log, "BLK_SUB.HASARGS = %d\n",
		(int)CxHASARGS(cx));
	PerlIO_printf(Perl_debug_log, "BLK_SUB.LVAL = %d\n", (int)CxLVAL(cx));
	PerlIO_printf(Perl_debug_log, "BLK_SUB.RETOP = 0x%"UVxf"\n",
		PTR2UV(cx->blk_sub.retop));
	break;
    case CXt_EVAL:
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_IN_EVAL = %ld\n",
		(long)CxOLD_IN_EVAL(cx));
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_OP_TYPE = %s (%s)\n",
		PL_op_name[CxOLD_OP_TYPE(cx)],
		PL_op_desc[CxOLD_OP_TYPE(cx)]);
	if (cx->blk_eval.old_namesv)
	    PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_NAME = %s\n",
			  SvPVX_const(cx->blk_eval.old_namesv));
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.OLD_EVAL_ROOT = 0x%"UVxf"\n",
		PTR2UV(cx->blk_eval.old_eval_root));
	PerlIO_printf(Perl_debug_log, "BLK_EVAL.RETOP = 0x%"UVxf"\n",
		PTR2UV(cx->blk_eval.retop));
	break;

    case CXt_LOOP_LAZYIV:
    case CXt_LOOP_LAZYSV:
    case CXt_LOOP_FOR:
    case CXt_LOOP_PLAIN:
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.LABEL = %s\n", CxLABEL(cx));
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.RESETSP = %ld\n",
		(long)cx->blk_loop.resetsp);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.MY_OP = 0x%"UVxf"\n",
		PTR2UV(cx->blk_loop.my_op));
	/* XXX: not accurate for LAZYSV/IV */
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERARY = 0x%"UVxf"\n",
		PTR2UV(cx->blk_loop.state_u.ary.ary));
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERIX = %ld\n",
		(long)cx->blk_loop.state_u.ary.ix);
	PerlIO_printf(Perl_debug_log, "BLK_LOOP.ITERVAR = 0x%"UVxf"\n",
		PTR2UV(CxITERVAR(cx)));
	break;

    case CXt_SUBST:
	PerlIO_printf(Perl_debug_log, "SB_ITERS = %ld\n",
		(long)cx->sb_iters);
	PerlIO_printf(Perl_debug_log, "SB_MAXITERS = %ld\n",
		(long)cx->sb_maxiters);
	PerlIO_printf(Perl_debug_log, "SB_RFLAGS = %ld\n",
		(long)cx->sb_rflags);
	PerlIO_printf(Perl_debug_log, "SB_ONCE = %ld\n",
		(long)CxONCE(cx));
	PerlIO_printf(Perl_debug_log, "SB_ORIG = %s\n",
		cx->sb_orig);
	PerlIO_printf(Perl_debug_log, "SB_DSTR = 0x%"UVxf"\n",
		PTR2UV(cx->sb_dstr));
	PerlIO_printf(Perl_debug_log, "SB_TARG = 0x%"UVxf"\n",
		PTR2UV(cx->sb_targ));
	PerlIO_printf(Perl_debug_log, "SB_S = 0x%"UVxf"\n",
		PTR2UV(cx->sb_s));
	PerlIO_printf(Perl_debug_log, "SB_M = 0x%"UVxf"\n",
		PTR2UV(cx->sb_m));
	PerlIO_printf(Perl_debug_log, "SB_STREND = 0x%"UVxf"\n",
		PTR2UV(cx->sb_strend));
	PerlIO_printf(Perl_debug_log, "SB_RXRES = 0x%"UVxf"\n",
		PTR2UV(cx->sb_rxres));
	break;
    }
#else
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(cx);
#endif	/* DEBUGGING */
}

#endif /* _UNWIND_DEBUG_H_ */
