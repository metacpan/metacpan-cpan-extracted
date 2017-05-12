/*
 *  Finance::InteractiveBrokers::SWIG - Perl/C embedding XS dispatcher
 *
 *  Copyright (c) 2010-2014 Jason McManus
 *
 *  This is #include'd from the SWIG .i interface file
 *  (Borrowed from Advanced Perl Programming, 1st Ed.)
 */

#include <string.h>

/* Our header */
#include "ezembed.h"

#ifndef IB_API_VERSION
# error IB_API_VERSION must be defined.
#endif

#ifndef IB_API_INTVER
# error IB_API_INTVER must be defined.
#endif

/* Main function: perl_call_va() - call this from other code, with the
   fully-qualified package::name of the Perl function you wish to call,
   and pass in the parameters in pairs of "type", "arg", ending all of
   them with a trailing NULL.
      e.g.   retval = perl_call_va( "Foo::bar",
                                    "s", "My bologna has a first name",
                                    "i", 42,
                                    NULL );
*/
int
perl_call_va (const char *subname, ...)
{
    char *p;
    char *str = NULL; int ii = 0; double d = 0;
    int  nret = 0; /* number of return params expected*/
    int i = 0;
    Out_Param op[32];
    va_list vl;
    int out = 0;
    int result = 0;
    SV *obj;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    va_start (vl, subname);

#ifdef DEBUG
    printf ("Entering perl_call %s\n", subname);
#endif
    while (p = va_arg(vl, char *)) {
#ifdef DEBUG
        printf ("Type: %s\n", p);
#endif
        switch (*p)     /* Used: [ s i f c o r d x u O ] */
        {
        // string
        case 's' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, char *);
                op[nret++].type = 's';
            } else {
                str = va_arg(vl, char *);
#ifdef DEBUG
                printf ("IN: String %s\n", str);
#endif
                ii = strlen(str);
                XPUSHs(sv_2mortal(newSVpv(str,ii)));
            }
            break;
        // integer
        case 'i' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, int *);
                op[nret++].type = 'i';
            } else {
                ii = va_arg(vl, int);
#ifdef DEBUG
                printf ("IN: Int %d\n", ii);
#endif
                XPUSHs(sv_2mortal(newSViv(ii)));
            }
            break;
        // floating point
        case 'f' :
            if (out) {
                op[nret].pdata = (void*) va_arg(vl, double *);
                op[nret++].type = 'f';
            } else {
                d = va_arg(vl, double);
#ifdef DEBUG
                printf ("IN: Double %f\n", d);
#endif
                XPUSHs(sv_2mortal(newSVnv(d)));
            }
            break;
        /*********************************************************/
        // our C++ objects, turned into perl objects, using SWIG.
        // These cannot be "out" parameters.
        /*********************************************************/
        // Contract
        case 'c' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, Contract * )
                          ),
                          SWIGTYPE_p_Contract,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
        // Order
        case 'o' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, Order * )
                          ),
                          SWIGTYPE_p_Order,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
        // OrderState
        case 'r' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, OrderState * )
                          ),
                          SWIGTYPE_p_OrderState,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
        // ContractDetails
        case 'd' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, ContractDetails * )
                          ),
                          SWIGTYPE_p_ContractDetails,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
        // Execution
        case 'x' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, Execution * )
                          ),
                          SWIGTYPE_p_Execution,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
        // UnderComp
        case 'u' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, UnderComp * )
                          ),
                          SWIGTYPE_p_UnderComp,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
#if IB_API_INTVER >= 967
        // CommissionReport
        case 'm' :
            obj = newSV( 0 );
            SWIG_MakePtr( obj,
                          SWIG_as_voidptr(
                              (void*) va_arg( vl, CommissionReport * )
                          ),
                          SWIGTYPE_p_CommissionReport,
                          SWIG_OWNER | SWIG_SHADOW );
            XPUSHs( obj );
            break;
#endif
        // out parameter(s)
        case 'O' :
            out = 1;  /* Out parameters starting */
            break;
        default :
            fprintf (stderr, "perl_call_va: Unknown option \'%c\'.\n"
                             "Did you forget a trailing NULL ?\n", *p);
            return 0;
        }
    }

    va_end(vl);

    PUTBACK;
    result = perl_call_pv(subname, (nret == 0) ? G_DISCARD :
                                   (nret == 1) ? G_SCALAR  :
                                                 G_ARRAY  );

    SPAGAIN;
#ifdef DEBUG
    printf ("nret: %d, result: %d\n", nret, result);
#endif
    if (nret > result)
        nret = result;

    for (i = --nret; i >= 0; i--) {
        switch (op[i].type) {
        case 's':
            str = POPp;
#ifdef DEBUG
            printf ("String: %s\n", str);
#endif
            strcpy((char *)op[i].pdata, str);
            break;
        case 'i':
            ii = POPi;
#ifdef DEBUG
            printf ("Int: %d\n", ii);
#endif
            *((int *)(op[i].pdata)) = ii;
            break;
        case 'd':
            d = POPn;
#ifdef DEBUG
            printf ("Double: %f\n", d);
#endif
            *((double *) (op[i].pdata)) = d;
            break;
        }
    }

    FREETMPS ;
    LEAVE ;
    return result;
}

/* END */

