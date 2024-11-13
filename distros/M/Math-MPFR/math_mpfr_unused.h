
#ifndef MATH_MPFR_UNUSED_H
#define MATH_MPFR_UNUSED_H 1

#define PERL_UNUSED_ARG2(a,b) PERL_UNUSED_ARG(a);PERL_UNUSED_ARG(b);

#define PERL_UNUSED_ARG3(a,b,c) PERL_UNUSED_ARG(a);PERL_UNUSED_ARG(b);\
                                PERL_UNUSED_ARG(c);

#define PERL_UNUSED_ARG4(a,b,c,d) PERL_UNUSED_ARG(a);PERL_UNUSED_ARG(b);\
                                  PERL_UNUSED_ARG(c);PERL_UNUSED_ARG(d);

#define PERL_UNUSED_ARG5(a,b,c,d,e) PERL_UNUSED_ARG(a);PERL_UNUSED_ARG(b);\
                                    PERL_UNUSED_ARG(c);PERL_UNUSED_ARG(d);\
                                    PERL_UNUSED_ARG(e);

#define PERL_UNUSED_ARG6(a,b,c,d,e,f) PERL_UNUSED_ARG(a);PERL_UNUSED_ARG(b);\
                                      PERL_UNUSED_ARG(c);PERL_UNUSED_ARG(d);\
                                      PERL_UNUSED_ARG(e);PERL_UNUSED_ARG(f);

#endif

