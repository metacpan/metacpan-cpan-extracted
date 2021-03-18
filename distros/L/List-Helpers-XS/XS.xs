#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
//#include <unistd.h>
//#include <stdlib.h>

inline static void croak_sv_is_not_an_arrayref (short int pos) {
    static char* pattern = "The argument at position %i isn't an array reference";
    SV* msg = sv_2mortal( newSVpvf(pattern, pos) );
    Perl_croak(pTHX_ (char *) SvPV_nolen( msg ));
}

inline static void shuffle_tied_av_last_num_elements (AV *av, SSize_t len, SSize_t num) {

    static SSize_t rand_index = 0;
    SSize_t cur_index  = len;
    SV* a;
    SV* b;
    SV** ap;
    SV** bp;

    while (cur_index > 1) {
        rand_index = (cur_index + 1) * Drand01(); // rand() % cur_index;
        ap = av_fetch(av,  cur_index, 0);
        bp = av_fetch(av, rand_index, 0);
        a = (ap ? sv_2mortal( newSVsv(*ap) ) : &PL_sv_undef);
        b = (bp ? sv_2mortal( newSVsv(*bp) ) : &PL_sv_undef);
        SvREFCNT_inc_simple_void(a);
        SvREFCNT_inc_simple_void(b);

        // if "av_store" returns NULL, the caller will have to decrement the reference count to avoid a memory leak
        if (av_store(av,  cur_index, b) == NULL)
            SvREFCNT_dec(b);
        mg_set(b);

        if (av_store(av, rand_index, a) == NULL)
            SvREFCNT_dec(a);

        mg_set(a);
        cur_index--;
    }
}

inline static void shuffle_av_last_num_elements (AV *av, SSize_t len, SSize_t num) {

    if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
        shuffle_tied_av_last_num_elements(av, len, num);
    } else {
        static SSize_t rand_index = 0;
        SSize_t cur_index  = len;
        SV **pav = AvARRAY(av);
        SV* a;

        while (cur_index > 1) {
            rand_index = (cur_index + 1) * Drand01(); // rand() % cur_index;
            //warn("cur_index = %i\trnd = %i\n", cur_index, rand_index);
            a = (SV*) pav[rand_index];
            pav[rand_index] = pav[cur_index];
            pav[cur_index] = a;
            cur_index--;
        }
    }
}

inline static void shuffle_av_first_num_elements (AV *av, SSize_t len, SSize_t num) {

    /*
    static short int is_rand_initialized = 0;

    if (is_rand_initialized == 0) {
        srand( (unsigned int) getpid() );
        is_rand_initialized = 1;
    }
    */

    static SSize_t rand_index = 0;
    static SSize_t cur_index  = 0;
    SV* a;

    len++;

    if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
        SV* b;
        SV** ap;
        SV** bp;

        while (cur_index <= num) {
            rand_index = cur_index + (len - cur_index) * Drand01(); // rand() % cur_index;
            // perlguts: Note the value so returned does not need to be deallocated, as it is already mortal.
            // SO, let's bump REFCNT then
            ap = av_fetch(av,  cur_index, 0);
            bp = av_fetch(av, rand_index, 0);
            a = (ap ? sv_2mortal( newSVsv(*ap) ) : &PL_sv_undef);
            b = (bp ? sv_2mortal( newSVsv(*bp) ) : &PL_sv_undef);
            SvREFCNT_inc_simple_void(b);
            SvREFCNT_inc_simple_void(a);
            //warn("cur_index = %i\trnd = %i\n", cur_index, rand_index);

            // [MAYCHANGE] After a call to "av_store" on a tied array, the caller will usually
            // need to call "mg_set(val)" to actually invoke the perl level "STORE" method on the TIEARRAY object.
            if (av_store(av,  cur_index, b) == NULL)
                SvREFCNT_dec(b);
            mg_set(b);

            if (av_store(av, rand_index, a) == NULL)
                SvREFCNT_dec(a);
            mg_set(a);

            cur_index++;
        }
    } else {
        SV **pav = AvARRAY(av);

        while (cur_index <= num) {
            rand_index = cur_index + (len - cur_index) * Drand01(); // rand() % (len - cur_index);
            //warn("cur_index = %i\trnd = %i\n", cur_index, rand_index);
            a = (SV*) pav[rand_index];
            pav[rand_index] = pav[cur_index];
            pav[cur_index] = a;
            cur_index++;
        }
    }
}


MODULE = List::Helpers::XS      PACKAGE = List::Helpers::XS

PROTOTYPES: DISABLE

BOOT:
#if (PERL_VERSION >= 14)
    sv_setpv((SV*)GvCV(gv_fetchpvs("List::Helpers::XS::shuffle", 0, SVt_PVCV)), "+");
#else
    sv_setpv((SV*)GvCV(gv_fetchpvs("List::Helpers::XS::shuffle", 0, SVt_PVCV)), "\\@");
#endif


AV* random_slice (av, num)
    AV* av
    IV num
PPCODE:

    if (num < 0)
        Perl_croak(pTHX_ "The slice's size can't be less than 0");

    if (num != 0) {

        SSize_t last_index = av_top_index(av);

        num -= 1;

        if (num < last_index) {

            SSize_t cur_index;
            AV *slice;
            SV **svp;
            SV *sv;

            shuffle_av_first_num_elements(av, last_index, num);

            if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
                SSize_t k = 0;
                slice = newAV();
                for (k = 0; k <= num; k++) {
                    svp = av_fetch(av,  k, 0);
                    sv = (svp ? newSVsv(*svp) : &PL_sv_undef);
                    av_push(slice, sv);
                    mg_set(sv);
                }
            }
            else
                slice = av_make(num + 1, av_fetch(av, 0, 0));

            ST(0) = sv_2mortal(newRV_noinc( (SV *) slice )); // mXPUSHs(newRV_noinc( (SV *) slice ));
        }
    }

    XSRETURN(1);


void random_slice_void (av, num)
    AV* av
    IV num
PPCODE:

    if (num < 0)
        Perl_croak(pTHX_ "The slice's size can't be less than 0");

    if (num == 0) {
        av_fill(av, 0);
    }
    else {

        SSize_t last_index = av_top_index(av);

        num -= 1;

        if (num < last_index) {
            shuffle_av_first_num_elements(av, last_index, num);
            av_fill(av, num);
        }

        // If "flags" equals "G_DISCARD", the element is freed and NULL is returned.
        // But it's more slower than "av_fill"
        // for (cur_index = last_index; cur_index > num; cur_index--)
            // av_delete(av, cur_index, G_DISCARD); // a = av_delete(av, cur_index); SvREFCNT_dec(a)
            // SvREFCNT_dec( av_pop(av) );
    }

    XSRETURN_EMPTY;


void shuffle (av)
    AV *av
PPCODE:
    SSize_t len = av_len(av);
    /* it's faster than "shuffle_av_first_num_elements" */
    shuffle_av_last_num_elements(av, len, len);
    XSRETURN_EMPTY;


void shuffle_multi(av, ...)
    AV* av;
PPCODE:
    static SSize_t i;
    static SSize_t len;
    SV* sv;
    SV *ref;

    if (items == 0)
        Perl_croak(pTHX_ "Wrong amoung of arguments");

    for (i = 0; i < items; i++) {
        sv = ST(i);
        if (!SvOK(sv)) // skip undefs
            continue;
        if (!SvROK(sv)) // isn't a ref type
            croak_sv_is_not_an_arrayref(i);
        ref = SvRV(sv);
        if (SvTYPE(ref) == SVt_PVAV) { // $ref eq "ARRAY"
            av = (AV *) ref;
            len = av_len(av);
            shuffle_av_last_num_elements(av, len, len);
        }
        else // $ref ne "ARRAY"
            croak_sv_is_not_an_arrayref(i);
    }
    // if (items < X) EXTEND(SP, X);
    XSRETURN_EMPTY;
