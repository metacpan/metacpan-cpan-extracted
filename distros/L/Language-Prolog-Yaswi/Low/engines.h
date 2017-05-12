
void check_prolog(pTHX_ pMY_CXT);

void release_prolog(pTHX_ pMY_CXT);

#ifdef MULTIPLICITY

void *my_Perl_get_context(void);

#  define MY_dTHX PerlInterpreter *my_perl=(PerlInterpreter *)my_Perl_get_context()

#else

#  define MY_dTHX extern PerlInterpreter *my_perl

#endif


