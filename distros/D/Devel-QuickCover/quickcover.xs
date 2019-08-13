#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define PERL_NO_GET_CONTEXT     /* we want efficiency */
#include <XSUB.h>

#include "glog.h"
#include "gmem.h"
#include "cover.h"
#include "util.h"

#define QC_PREFIX    "QC"
#define QC_EXTENSION ".txt"

#define QC_PACKAGE                 "Devel::QuickCover"
#define QC_CONFIG_VAR              QC_PACKAGE "::CONFIG"

#define QC_CONFIG_OUTPUTDIR        "output_directory"
#define QC_CONFIG_METADATA         "metadata"
#define QC_CONFIG_NOATEXIT         "noatexit"

#ifndef OpSIBLING
#define OpSIBLING(op) ((op)->op_sibling)
#endif

static Perl_ppaddr_t nextstate_orig = 0, dbstate_orig = 0;
static peep_t peepp_orig;
static CoverList* cover = 0;
static int enabled = 0;
static Buffer output_dir;
static Buffer metadata;

static void qc_init(int noatexit);
static void qc_fini(void);

static void qc_terminate(int nodump);
static void qc_install(pTHX);
static OP*  qc_nextstate(pTHX);
static void qc_peep(pTHX_ OP* o);
static void qc_dump(CoverList* cover);

static void save_stuff(pTHX);
static void save_output_directory(pTHX);
static void save_metadata(pTHX);

static void scan_optree(pTHX_ CoverList* cover, OP* op);

static void qc_init(int noatexit)
{
    if (!noatexit) {
        GLOG(("Registering atexit handler"));
        atexit(qc_fini);
    }

    gmem_init();
    buffer_init(&output_dir, 0);
    buffer_init(&metadata, 0);

    buffer_append(&output_dir, "/tmp", 0);
    buffer_terminate(&output_dir);

    buffer_terminate(&metadata);
}

static void qc_terminate(int nodump)
{
    if (cover) {
        if (nodump) {
            GLOG(("Skipping dumping cover data"));
        } else {
            qc_dump(cover);
        }
        cover_destroy(cover);
        cover = 0;
    }

    buffer_fini(&metadata);
    buffer_fini(&output_dir);
    gmem_fini();
}

static void qc_fini(void)
{
    qc_terminate(0);
}

static void qc_install(pTHX)
{
    if (PL_ppaddr[OP_NEXTSTATE] == qc_nextstate) {
        die("%s: internal error, exiting: qc_install called again", QC_PACKAGE);
    }

    nextstate_orig = PL_ppaddr[OP_NEXTSTATE];
    PL_ppaddr[OP_NEXTSTATE] = qc_nextstate;
    dbstate_orig = PL_ppaddr[OP_DBSTATE];
    PL_ppaddr[OP_DBSTATE] = qc_nextstate;
    peepp_orig = PL_peepp;
    PL_peepp = qc_peep;

    GLOG(("qc_install: nextstate_orig is [%p]", nextstate_orig));
    GLOG(("qc_install:   qc_nextstate is [%p]", qc_nextstate));
}

#if PERL_VERSION >= 18 && PERL_VERSION < 22

static void named_cv_name(pTHX_ SV* dest, CV* cv) {
    HV* stash = CvSTASH(cv);
    const char* name = stash ? HvNAME(stash) : NULL;

    if (name) {
        /* inspired by Perl_gv_fullname4 */
        const STRLEN len = HvNAMELEN(stash);

        sv_setpvn(dest, name, len);
        if (HvNAMEUTF8(stash))
            SvUTF8_on(dest);
        else
            SvUTF8_off(dest);
	sv_catpvs(dest, "::");
        sv_catsv(dest, sv_2mortal(newSVhek(CvNAME_HEK(cv))));
    }
}

#endif

static void add_sub_helper(pTHX_ CoverList* cover, const char* file, const char* name, U32 line) {
    U32 file_hash, name_hash;

    PERL_HASH(file_hash, file, strlen(file));
    PERL_HASH(name_hash, name, strlen(name));
    cover_sub_add_sub(cover, file, file_hash, name, name_hash, line);
}

static void add_covered_sub_helper(pTHX_ CoverList* cover, const char* file, const char* name, U32 line, int phase) {
    U32 file_hash, name_hash;

    PERL_HASH(file_hash, file, strlen(file));
    PERL_HASH(name_hash, name, strlen(name));
    cover_sub_add_covered_sub(cover, file, file_hash, name, name_hash, line, phase);
}

static void add_line_helper(pTHX_ CoverList* cover, const char* file, U32 line) {
    U32 file_hash;

    PERL_HASH(file_hash, file, strlen(file));
    cover_add_line(cover, file, file_hash, line);
}

static void add_covered_line_helper(pTHX_ CoverList* cover, const char* file, U32 line, int phase) {
    U32 file_hash;

    PERL_HASH(file_hash, file, strlen(file));
    cover_add_covered_line(cover, file, file_hash, line, phase);
}

static OP* qc_first_nextstate(pTHX) {
    const PERL_CONTEXT* cx = &cxstack[cxstack_ix];

    /* this should always be true, but just in case */
    if (CxTYPE(cx) == CXt_SUB) {
        CV* cv = cx->blk_sub.cv;
        SV* dest = sv_newmortal();
        GV* gv = CvGV(cv);

        /* Create data structure if necessary. */
        if (!cover) {
            cover = cover_create();
            GLOG(("qc_first_nextstate: created cover data [%p]", cover));
        }

        if (gv) { /* see the same condition in qc_peep */
            gv_efullname3(dest, gv, NULL);
            add_covered_sub_helper(aTHX_ cover, GvFILE(gv), SvPV_nolen(dest), CopLINE(cCOPx(PL_op)), PL_phase);
#if PERL_VERSION >= 18 && PERL_VERSION < 22
        } else if (CvNAMED(cv)) {
            named_cv_name(aTHX_ dest, cv);
            add_covered_sub_helper(aTHX_ cover, CvFILE(cv), SvPV_nolen(dest), CopLINE(cCOPx(PL_op)), PL_phase);
#endif
        }
    }

    return qc_nextstate(aTHX);
}

static OP* qc_nextstate(pTHX) {
    Perl_ppaddr_t orig_pp = PL_op->op_type == OP_NEXTSTATE ? nextstate_orig : dbstate_orig;
    OP* ret = orig_pp(aTHX);

    if (enabled) {
        /* Restore original nextstate op for this node. */
        if (PL_op->op_ppaddr == qc_nextstate)
            PL_op->op_ppaddr = orig_pp;

        /* Create data structure if necessary. */
        if (!cover) {
            cover = cover_create();
            GLOG(("qc_nextstate: created cover data [%p]", cover));
        }

        /* Now do our own nefarious tracking... */
        add_covered_line_helper(aTHX_ cover, CopFILE(PL_curcop), CopLINE(PL_curcop), PL_phase);
    }

    return ret;
}

static void qc_peep(pTHX_ OP *o)
{
    if (!o || o->op_opt)
        return;

    peepp_orig(aTHX_ o);

    if (enabled) {
        /* Create data structure if necessary. */
        if (!cover) {
            cover = cover_create();
            GLOG(("qc_peep: created cover data [%p]", cover));
        }

        /*
         * the peephole is called on the start op, and should proceed
         * in execution order, but we cheat because we don't need
         * execution order and it's much simpler to perform a
         * recursive scan of the tree
         *
         * This would be much simpler, and more natural, as a
         * PL_check[OP_NEXTSTATE] override, but guess what? Perl does
         * not call the check hook for OP_NEXTSTATE/DBSTATE
         */
        if (PL_compcv && o == CvSTART(PL_compcv) && CvROOT(PL_compcv)) {
            /* the first nextstate op marks the sub as covered */
            OP* f;
            for (f = o; f; f = f->op_next) {
                if (f->op_type == OP_NEXTSTATE || f->op_type == OP_DBSTATE) {
                    f->op_ppaddr = qc_first_nextstate;
                    break;
                }
            }
            if (f) {
                GV* gv = CvGV(PL_compcv);
                SV* dest = sv_newmortal();

                if (gv) { /* for example lexical subs don't have a GV on Perl < 5.22 */
                    gv_efullname3(dest, gv, NULL);
                    add_sub_helper(aTHX_ cover, GvFILE(gv), SvPV_nolen(dest), CopLINE(cCOPx(f)));
#if PERL_VERSION >= 18 && PERL_VERSION < 22
                } else if (CvNAMED(PL_compcv)) {
                    named_cv_name(aTHX_ dest, PL_compcv);
                    add_sub_helper(aTHX_ cover, CvFILE(PL_compcv), SvPV_nolen(dest), CopLINE(cCOPx(f)));
#endif
                }
            }
            scan_optree(aTHX_ cover, CvROOT(PL_compcv));
        } else if (o == PL_main_start && PL_main_root)
            scan_optree(aTHX_ cover, PL_main_root);
        else if (o == PL_eval_start && PL_eval_root)
            scan_optree(aTHX_ cover, PL_eval_root);
    }
}

static void qc_dump(CoverList* cover)
{
    static int count = 0;
    static time_t last = 0;

    time_t t = 0;
    FILE* fp = 0;
    char base[1024];
    char tmp[1024];
    char txt[1024];
    struct tm now;

    /*
     * If current time is different from last time (seconds
     * resolution), reset file suffix counter to zero.
     */
    t = time(0);
    if (last != t) {
        last = t;
        count = 0;
    }

    /*
     * Get detailed current time:
     */
    localtime_r(&t, &now);

    /*
     * We generate the information on a file with the following structure:
     *
     *   output_dir/prefix_YYYYMMDD_hhmmss_pid_NNNNN.txt
     *
     * where NNNNN is a suffix counter to allow for more than one file in a
     * single second interval.
     */
    sprintf(base, "%s_%04d%02d%02d_%02d%02d%02d_%ld_%05d",
            QC_PREFIX,
            now.tm_year + 1900, now.tm_mon + 1, now.tm_mday,
            now.tm_hour, now.tm_min, now.tm_sec,
            (long) getpid(),
            count++);

    /*
     * We generate the information on a file with a prepended dot.  Once we are
     * done, we atomically rename it and get rid of the dot.  This way, any job
     * polling for new files will not find any half-done work.
     */
    sprintf(tmp, "%s/.%s%s", output_dir.data, base, QC_EXTENSION);
    sprintf(txt, "%s/%s%s" , output_dir.data, base, QC_EXTENSION);

    GLOG(("qc_dump: dumping cover data [%p] to file [%s]", cover, txt));
    fp = fopen(tmp, "w");
    if (!fp) {
        GLOG(("qc_dump: could not create dump file [%s]", tmp));
    } else {
        fprintf(fp, "{");

        fprintf(fp, "\"date\":\"%04d-%02d-%02d\",",
                now.tm_year + 1900, now.tm_mon + 1, now.tm_mday);
        fprintf(fp, "\"time\":\"%02d:%02d:%02d\",",
                now.tm_hour, now.tm_min, now.tm_sec);

        fprintf(fp, "\"metadata\":%s,", metadata.data);
        cover_dump(cover, fp);

        fprintf(fp, "}\n");
        fclose(fp);
        rename(tmp, txt);
    }
}

static void save_stuff(pTHX)
{
    save_output_directory(aTHX);
    save_metadata(aTHX);
}

static void save_output_directory(pTHX)
{
    HV* qc_config = 0;
    SV** val = 0;
    STRLEN len = 0;
    const char* str;

    qc_config = get_hv(QC_CONFIG_VAR, 0);
    if (!qc_config) {
        die("%s: Internal error, exiting: %s must exist",
            QC_PACKAGE, QC_CONFIG_VAR);
    }
    val = hv_fetch(qc_config, QC_CONFIG_OUTPUTDIR,
                   sizeof(QC_CONFIG_OUTPUTDIR) - 1, 0);
    if (!SvUTF8(*val)) {
        sv_utf8_upgrade(*val);
    }
    str = SvPV_const(*val, len);

    buffer_reset(&output_dir);
    buffer_append(&output_dir, str, len);
    buffer_terminate(&output_dir);
}

static void save_metadata(pTHX)
{
    HV* qc_config = 0;
    SV** val = 0;
    HV* hv;

    qc_config = get_hv(QC_CONFIG_VAR, 0);
    if (!qc_config) {
        die("%s: Internal error, exiting: %s must exist",
            QC_PACKAGE, QC_CONFIG_VAR);
    }
    val = hv_fetch(qc_config, QC_CONFIG_METADATA,
                   sizeof(QC_CONFIG_METADATA) - 1, 0);
    if (!SvROK(*val) || SvTYPE(SvRV(*val)) != SVt_PVHV) {
        die("%s: Internal error, exiting: %s must be a hashref",
            QC_PACKAGE, QC_CONFIG_METADATA);
    }

    hv = (HV*) SvRV(*val);
    buffer_reset(&metadata);
    dump_hash(aTHX_ hv, &metadata);
    buffer_terminate(&metadata);
    GLOG(("Saved metadata [%s]", metadata.data));
}

static void scan_optree(pTHX_ CoverList* cover, OP* op)
{
  if (op->op_flags & OPf_KIDS) {
    OP* curr;

    for (curr = cUNOPx(op)->op_first; curr; curr = OpSIBLING(curr))
      scan_optree(aTHX_ cover, curr);
  }

  if (op->op_type == OP_NEXTSTATE || op->op_type == OP_DBSTATE)
    add_line_helper(aTHX_ cover, CopFILE(cCOPx(op)), CopLINE(cCOPx(op)));
}


MODULE = Devel::QuickCover        PACKAGE = Devel::QuickCover
PROTOTYPES: DISABLE

#################################################################

BOOT:
    GLOG(("@@@ BOOT"));
    qc_install(aTHX);

void
start()
PREINIT:
    HV* qc_config = 0;
    SV** val = 0;
    int noatexit = 0;
CODE:
    if (enabled) {
        GLOG(("@@@ start(): ignoring multiple calls"));
    } else {
        GLOG(("@@@ start(): enabling Devel::QuickCover"));

        qc_config = get_hv(QC_CONFIG_VAR, 0);
        if (!qc_config) {
            die("%s: Internal error, exiting: %s must exist",
                QC_PACKAGE, QC_CONFIG_VAR);
        }
        val = hv_fetch(qc_config, QC_CONFIG_NOATEXIT,
                       sizeof(QC_CONFIG_NOATEXIT) - 1, 0);
        noatexit = val && SvTRUE(*val);

        enabled = 1;
        qc_init(noatexit);
        save_stuff(aTHX);
    }

void
end(...)
PREINIT:
    int nodump = 0;
CODE:
    if (!enabled) {
        GLOG(("@@@ end(): ignoring multiple calls"));
    } else {
        if (items >= 1) {
            SV* pnodump = ST(0);
            nodump = SvTRUE(pnodump);
        }
        GLOG(("@@@ end(%d): dumping data and disabling Devel::QuickCover", nodump));
        save_stuff(aTHX);
        qc_terminate(nodump);
        enabled = 0;
    }
