//#define PERL_NO_GET_CONTEXT

// PERL_NO_GET_CONTEXT is not used here, so it's OK to define it after inculding these files
#include "EXTERN.h"
#include "perl.h"

// There are a lot of macro about threads: USE_ITHREADS, USE_5005THREADS, I_PTHREAD, I_MACH_CTHREADS, OLD_PTHREADS_API
// This symbol, if defined, indicates that Perl should be built to use the interpreter-based threading implementation.
#ifndef USE_ITHREADS
#	define PERL_NO_GET_CONTEXT
#endif

//#ifdef USE_ITHREADS
//#	warning USE_ITHREADS: THREADS ARE ON
//#endif
//#ifdef USE_5005THREADS
//#	warning USE_5005THREADS: THREADS ARE ON
//#endif
//#ifdef I_PTHREAD
//#	warning I_PTHREAD: THREADS ARE ON
//#endif
//#ifdef I_MACH_CTHREADS
//#	warning I_MACH_CTHREADS: THREADS ARE ON
//#endif
//#ifdef OLD_PTHREADS_API
//# warning OLD_PTHREADS_API: THREADS ARE ON
//#endif

#include "XSUB.h"

#include <sys/types.h>

#ifdef I_PTHREAD
#	include "pthread.h"
#endif

#ifdef I_MACH_CTHREADS
#	include "mach/cthreads.h"
#endif

#include <utility>

/*
inline static void call_srand_if_required (void) {
    //#if (PERL_VERSION >= 9)
    if(!PL_srand_called) {
        (void)seedDrand01((Rand_seed_t)Perl_seed(aTHX));
        PL_srand_called = TRUE;
    }
}
*/

inline static void croak_sv_is_not_an_arrayref (short int pos) {
    static const char* pattern = "The argument at position %i isn't an array reference";
    croak(pattern, pos);
}

inline static void shuffle_tied_av_last_num_elements (AV *av, SSize_t len, SSize_t num) {

    static SSize_t rand_index, cur_index;
    SV *a, *b;
    SV **ap, **bp;

    cur_index = std::move(len);

    while (cur_index >= 1) {
		rand_index = rand() % cur_index; // (cur_index + 1) * Drand01();

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

inline static void shuffle_tied_av_first_num_elements (AV *av, SSize_t len, SSize_t num) {

    static SSize_t rand_index, cur_index;
    SV *a, *b;
    SV **ap, **bp;

    cur_index = 0;

    while (cur_index <= num) {
        rand_index = cur_index + (len - cur_index) * Drand01(); // cur_index + rand() % (len - cur_index)

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
}

inline static void shuffle_av_last_num_elements (AV *av, SSize_t len, SSize_t num) {

    //call_srand_if_required();

    if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
        shuffle_tied_av_last_num_elements(av, len, num);
    } else {
        static SSize_t rand_index, cur_index;
        SV **pav = AvARRAY(av);
        SV* a;

        cur_index = std::move(len);

        while (cur_index >= 0) {
            rand_index = (cur_index + 1) * Drand01(); // rand() % (cur_index + 1);
            //warn("cur_index = %i\trnd = %i\n", (int)cur_index, (int)rand_index);
            a = std::move((SV*) pav[rand_index]);
            pav[rand_index] = std::move(pav[cur_index]);
            pav[cur_index] = std::move(a);
            cur_index--;
        }
    }
}

inline static void shuffle_av_first_num_elements (AV *av, SSize_t len, SSize_t num) {

    len++;

    //call_srand_if_required();

    if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
        shuffle_tied_av_first_num_elements(av, len, num);
    } else {
        static SSize_t rand_index, cur_index;
        SV* a;
        SV **pav = AvARRAY(av);

        cur_index = 0;

        while (cur_index <= num) {
            rand_index = cur_index + (len - cur_index) * Drand01(); // cur_index + rand() % (len - cur_index);
            //warn("cur_index = %i\trnd = %i\n", (int)cur_index, (int)rand_index);

            a = std::move((SV*) pav[rand_index]);
            pav[rand_index] = std::move(pav[cur_index]);
            pav[cur_index] = std::move(a);
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
        croak("The slice's size can't be less than 0");

    if (num != 0) {

        static SSize_t last_index;

        last_index = std::move(av_top_index(av));
        num -= 1;

        if (num < last_index) {

            AV *slice;

            // shuffling for usual and tied arrays
            shuffle_av_first_num_elements(av, last_index, num);

            if (SvTIED_mg((SV *)av, PERL_MAGIC_tied)) {
                static SSize_t k;
                SV *sv, **svp;
                slice = newAV();
                for (k = 0; k <= num; k++) {
                    svp = av_fetch(av,  k, 0);
                    sv = (svp ? newSVsv(*svp) : &PL_sv_undef);
                    av_push(slice, sv);
                    mg_set(sv);
                }
            }
            else if (GIMME_V == G_VOID) {
                av_fill(av, num);
                XSRETURN_EMPTY;
            }
            else
                slice = av_make(num + 1, av_fetch(av, 0, 0));

            ST(0) = sv_2mortal(newRV_noinc( (SV *) slice )); // mXPUSHs(newRV_noinc( (SV *) slice ));
        }
    }

    XSRETURN(1);


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
        croak("Wrong amount of arguments");

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
