#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <glib.h>


typedef struct {
    char *file;
    int line;
} when;

/* a few globals, never mind the mess for now */
GHashTable *used = NULL;
GHashTable *new_used = NULL;

/* cargo from Devel::Leak - wander the arena, see what SVs live */
typedef long used_proc _((void *,SV *,long));

static
long int
sv_apply_to_used(void *p, used_proc *proc, long n) {
    SV *sva;
    for (sva = PL_sv_arenaroot; sva; sva = (SV *) SvANY(sva)) {
        SV *sv = sva + 1;
        SV *svend = &sva[SvREFCNT(sva)];

        while (sv < svend) {
            if (SvTYPE(sv) != SVTYPEMASK) {
                n = (*proc) (p, sv, n);
            }
            ++sv;
        }
    }
    return n;
}
/* end Devel::Leak cargo */


static
long
note_used(void *p, SV* sv, long n) {
    when *old = NULL;

    if (used && (old = g_hash_table_lookup( used, sv ))) {
	g_hash_table_insert(new_used, sv, old);
	return n;
    }
    g_hash_table_insert(new_used, sv, p);
    return 1;
}

static
void
print_me(gpointer key, gpointer value, gpointer user_data) {
    when *w = value;
    char *type;

    switch SvTYPE((SV*)key) {
    case SVt_PVAV: type = "AV"; break;
    case SVt_PVHV: type = "HV"; break;
    case SVt_PVCV: type = "CV"; break;
    case SVt_RV:   type = "RV"; break;
    case SVt_PVGV: type = "GV"; break;
    default: type = "SV";
    }

    if (w->file) {
        fprintf(stderr, "leaked %s(0x%x) from %s line %d\n", 
		type, key, w->file, w->line);
    }
}

static
int
note_changes( char *file, int line ) {
    static when *w = NULL;
    int ret;

    if (!w) w = malloc(sizeof(when));
    w->line = line;
    w->file = file;
    new_used = g_hash_table_new( NULL, NULL );
    if (sv_apply_to_used( w, note_used, 0 )) w = NULL;
    if (used) g_hash_table_destroy( used );
    used = new_used;
    return ret;
}

/* Now this bit of cargo is a derived from Devel::Caller */

static
int
runops_leakcheck(pTHX) {
    char *lastfile = 0;
    int lastline = 0;
    IV last_count = 0;

    while ((PL_op = CALL_FPTR(PL_op->op_ppaddr)(aTHX))) {
        PERL_ASYNC_CHECK();

        if (PL_op->op_type == OP_NEXTSTATE) {
            if (PL_sv_count != last_count) {
                note_changes( lastfile, lastline );
                last_count = PL_sv_count;
            }
            lastfile = CopFILE(cCOP);
            lastline = CopLINE(cCOP);
        }
    }

    note_changes( lastfile, lastline );

    TAINT_NOT;
    return 0;
}

MODULE = Devel::LeakTrace PACKAGE = Devel::LeakTrace

PROTOTYPES: ENABLE

void
hook_runops()
  PPCODE:
{
    note_changes(NULL, 0);
    PL_runops = runops_leakcheck;
}

void
reset_counters()
  PPCODE:
{
    if (used) g_hash_table_destroy( used );
    used = NULL;
    note_changes(NULL, 0);
}

void
show_used()
CODE:
{
    if (used) g_hash_table_foreach( used, print_me, NULL );
}
