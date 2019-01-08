/* vi: set ft=c inde=: */

#ifndef docatch

#define docatch(firstpp)  S_docatch(aTHX_ firstpp)

static OP *S_docatch(pTHX_ Perl_ppaddr_t firstpp)
{
    int ret;
    OP * const oldop = PL_op;
    dJMPENV;

    assert(CATCH_GET == TRUE);

    JMPENV_PUSH(ret);
    switch (ret) {
    case 0:
	PL_op = firstpp(aTHX);
 redo_body:
	CALLRUNOPS(aTHX);
	break;
    case 3:
	/* die caught by an inner eval - continue inner loop */
	if (PL_restartop && PL_restartjmpenv == PL_top_env) {
	    PL_restartjmpenv = NULL;
	    PL_op = PL_restartop;
	    PL_restartop = 0;
	    goto redo_body;
	}
	/* FALLTHROUGH */
    default:
	JMPENV_POP;
	PL_op = oldop;
	JMPENV_JUMP(ret);
	NOT_REACHED; /* NOTREACHED */
    }
    JMPENV_POP;
    PL_op = oldop;
    return NULL;
}

#endif
