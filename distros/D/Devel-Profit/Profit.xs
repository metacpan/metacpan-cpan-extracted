#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <time.h>

static FILE *fp;        /* pointer to profile.out file */
SV *file;
int line;
double start;
double now;
double diff;
HV* seen_file;
int file_number;
SV* seen_file_number;
    
static double get_clock()
{
    struct timespec ts;
    clock_gettime (CLOCK_MONOTONIC, &ts);
//    clock_gettime (CLOCK_REALTIME, &ts);
//    clock_gettime (CLOCK_PROCESS_CPUTIME_ID, &ts);
//    clock_gettime (CLOCK_THREAD_CPUTIME_ID, &ts);
    return 1e9 * ts.tv_sec + ts.tv_nsec;
}

int runops_devel_profit(pTHX)
{
    while (PL_op) {
        if (PL_op->op_type == OP_NEXTSTATE) {
            now = get_clock();
            diff = now - start;
            //printf("%s:%ld start=%.0f now=%.0f diff=%.0f\n", file, line, start, now, diff);
            if (line) {
                if (hv_exists_ent(seen_file, file, 0)) {
                    seen_file_number = HeVAL(hv_fetch_ent(seen_file, file, 0, 0));
                    //printf("have seen file %s before: %d\n", SvPV_nolen(file), SvIV(seen_file_number));
                } else {
                    seen_file_number = newSViv(file_number);
                    hv_store_ent(seen_file, file, seen_file_number, 0);
                    file_number++;
                    fprintf(fp, "%d=%s\n", SvIV(seen_file_number), SvPV_nolen(file));
                    //printf("have not seen file %s before: %d\n", SvPV_nolen(file), SvIV(seen_file_number));
                }
                fprintf(fp, "%d:%ld %.0f\n", SvIV(seen_file_number), line, diff);
                //fprintf(fp, "%s:%ld %.0f\n", SvPV_nolen(file), line, diff);
            }
            file = CopFILESV(cCOP);
            line = CopLINE(cCOP);
            start = now;
        }

        PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX);

        PERL_ASYNC_CHECK(); /* FIXME is it OK that PERL_ASYNC_CHECK happens even after PL_op might be false? */
    }

    TAINT_NOT;

    return 0;
}

MODULE = Devel::Profit PACKAGE = Devel::Profit

BOOT:
        if( (fp = fopen( "profit.out", "w" )) == NULL )
                     croak("Devel::Profit: unable to write profit.out, errno = %d\n", errno );
        fprintf(fp, "file:line microseconds\n");
        seen_file = newHV();
        file_number = 1;
        start = get_clock();
        PL_runops = runops_devel_profit;
