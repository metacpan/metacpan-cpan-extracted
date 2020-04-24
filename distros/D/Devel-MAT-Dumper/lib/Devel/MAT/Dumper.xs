/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2013-2019 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#define FORMAT_VERSION_MAJOR 0
#define FORMAT_VERSION_MINOR 4

#ifndef SvOOK_offset
#  define SvOOK_offset(sv, len) STMT_START { len = SvIVX(sv); } STMT_END
#endif

#ifndef CxHASARGS
#  define CxHASARGS(cx) ((cx)->blk_sub.hasargs)
#endif

#ifndef OpSIBLING
#  define OpSIBLING(o) ((o)->op_sibling)
#endif

#ifndef HvNAMELEN
#  define HvNAMELEN(hv) (strlen(HvNAME(hv)))
#endif

/* This technically applies all the way back to 5.6 if we need it... */
#if (PERL_REVISION == 5) && (PERL_VERSION == 10) && (PERL_SUBVERSION == 0)
#  define CxOLD_OP_TYPE(cx) ((cx)->blk_eval.old_op_type)
#endif

static int max_string;

#if NVSIZE == 8
#  define PMAT_NVSIZE 8
#else
#  define PMAT_NVSIZE 10
#endif

#if (PERL_REVISION == 5) && (PERL_VERSION >= 26)
#  define SAVEt_ARG0_MAX  SAVEt_REGCONTEXT
#  define SAVEt_ARG1_MAX  SAVEt_FREEPADNAME
#  define SAVEt_ARG2_MAX  SAVEt_APTR
#  define SAVEt_MAX       SAVEt_DELETE
   /* older perls already defined SAVEt_ARG<n>_MAX */
#elif (PERL_REVISION == 5) && (PERL_VERSION >= 22)
#  define SAVEt_MAX       SAVEt_DELETE
#elif (PERL_REVISION == 5) && (PERL_VERSION >= 20)
#  define SAVEt_MAX       SAVEt_AELEM
#elif (PERL_REVISION == 5) && (PERL_VERSION >= 18)
#  define SAVEt_MAX       SAVEt_GVSLOT
#endif

static SV *tmpsv;  /* A temporary SV for internal purposes. Will not get dumped */

static SV *make_tmp_iv(IV iv)
{
  if(!tmpsv)
    tmpsv = newSV(0);
  sv_setiv(tmpsv, iv);
  return tmpsv;
}

static uint8_t sv_sizes[] = {
  /* Header                   PTRs,  STRs */
  4 + PTRSIZE + UVSIZE,       1,     0,     /* common SV */
  UVSIZE,                     8,     2,     /* GLOB */
  1 + 2*UVSIZE + PMAT_NVSIZE, 1,     1,     /* SCALAR */
  1,                          2,     0,     /* REF */
  1 + UVSIZE,                 0,     0,     /* ARRAY + has body */
  UVSIZE,                     1,     0,     /* HASH + has body */
  UVSIZE + 0,                 1 + 4, 0 + 1, /* STASH = extends HASH */
  5 + UVSIZE + PTRSIZE,       5,     2,     /* CODE + has body */
  2*UVSIZE,                   3,     0,     /* IO */
  1 + 2*UVSIZE,               1,     0,     /* LVALUE */
  0,                          0,     0,     /* REGEXP */
  0,                          0,     0,     /* FORMAT */
  0,                          0,     0,     /* INVLIST */
  0,                          0,     0,     /* UNDEF */
};

static uint8_t svx_sizes[] = {
  /* Header   PTRs   STRs */
  2,          2,     0,     /* magic */
  0,          1,     0,     /* saved SV */
  0,          1,     0,     /* saved AV */
  0,          1,     0,     /* saved HV */
  UVSIZE,     1,     0,     /* saved AELEM */
  0,          2,     0,     /* saved HELEM */
  0,          1,     0,     /* saved CV */
  0,          1,     1,     /* SV->SV annotation */
  2*UVSIZE,   0,     1,     /* SV leak report */
};

static uint8_t ctx_sizes[] = {
  /* Header   PTRs STRs */
  1 + UVSIZE, 0,   1, /* common CTX */
  4,          2,   0, /* SUB */
  0,          0,   0, /* TRY */
  0,          1,   0, /* EVAL */
};

// These do NOT agree with perl's SVt_* constants!
enum PMAT_SVt {
  PMAT_SVtGLOB = 1,
  PMAT_SVtSCALAR,
  PMAT_SVtREF,
  PMAT_SVtARRAY,
  PMAT_SVtHASH,
  PMAT_SVtSTASH,
  PMAT_SVtCODE,
  PMAT_SVtIO,
  PMAT_SVtLVALUE,
  PMAT_SVtREGEXP,
  PMAT_SVtFORMAT,
  PMAT_SVtINVLIST,
  PMAT_SVtUNDEF,

  /* TODO: emit these in DMD_helper.h */
  PMAT_SVxMAGIC = 0x80,
  PMAT_SVxSAVED_SV,
  PMAT_SVxSAVED_AV,
  PMAT_SVxSAVED_HV,
  PMAT_SVxSAVED_AELEM,
  PMAT_SVxSAVED_HELEM,
  PMAT_SVxSAVED_CV,
  PMAT_SVxSVSVnote,
  PMAT_SVxDEBUGREPORT,
};

enum PMAT_CODEx {
  PMAT_CODEx_CONSTSV = 1,
  PMAT_CODEx_CONSTIX,
  PMAT_CODEx_GVSV,
  PMAT_CODEx_GVIX,
  PMAT_CODEx_PADNAME,
  /* PMAT_CODEx_PADSV was 6 */
  PMAT_CODEx_PADNAMES = 7,
  PMAT_CODEx_PAD,
  PMAT_CODEx_PADNAME_FLAGS,
};

enum PMAT_CTXt {
  PMAT_CTXtSUB = 1,
  PMAT_CTXtTRY,
  PMAT_CTXtEVAL,
};

typedef int DMD_Helper(pTHX_ SV const *sv);
static HV *helper_per_package;

typedef int DMD_MagicHelper(pTHX_ SV const *sv, MAGIC *mg);
static HV *helper_per_magic;

static void write_u8(FILE *fh, uint8_t v)
{
  fwrite(&v, 1, 1, fh);
}

/* We just write multi-byte integers in native endian, because we've declared
 * in the file flags what the platform byte direction is anyway
 */
static void write_u32(FILE *fh, uint32_t v)
{
  fwrite(&v, 4, 1, fh);
}

static void write_u64(FILE *fh, uint64_t v)
{
  fwrite(&v, 8, 1, fh);
}

static void write_uint(FILE *fh, UV v)
{
#if UVSIZE == 8
  write_u64(fh, v);
#elif UVSIZE == 4
  write_u32(fh, v);
#else
# error "Expected UVSIZE to be either 4 or 8"
#endif
}

static void write_ptr(FILE *fh, void *ptr)
{
  fwrite(&ptr, sizeof ptr, 1, fh);
}

static void write_svptr(FILE *fh, const SV *ptr)
{
  fwrite(&ptr, sizeof ptr, 1, fh);
}

static void write_nv(FILE *fh, NV v)
{
#if NVSIZE == 8
  fwrite(&v, sizeof(NV), 1, fh);
#else
  // long double is 10 bytes but sizeof() may be 16.
  fwrite(&v, 10, 1, fh);
#endif
}

static void write_strn(FILE *fh, const char *s, size_t len)
{
  write_uint(fh, len);
  fwrite(s, len, 1, fh);
}

static void write_str(FILE *fh, const char *s)
{
  if(s)
    write_strn(fh, s, strlen(s));
  else
    write_uint(fh, -1);
}

#define PMOP_pmreplroot(o)      o->op_pmreplrootu.op_pmreplroot

#if (PERL_REVISION == 5) && (PERL_VERSION < 14)
# define OP_CLASS(o)  (PL_opargs[o->op_type] & OA_CLASS_MASK)
#endif

static void dump_optree(FILE *fh, const CV *cv, OP *o);
static void dump_optree(FILE *fh, const CV *cv, OP *o)
{
  OP *kid;

  switch(o->op_type) {
    case OP_CONST:
    case OP_METHOD_NAMED:
#ifdef USE_ITHREADS
      if(o->op_targ) {
        write_u8(fh, PMAT_CODEx_CONSTIX);
        write_uint(fh, o->op_targ);
      }
#else
      write_u8(fh, PMAT_CODEx_CONSTSV);
      write_svptr(fh, cSVOPx(o)->op_sv);
#endif
      break;

    case OP_AELEMFAST:
    case OP_GVSV:
    case OP_GV:
#ifdef USE_ITHREADS
      write_u8(fh, PMAT_CODEx_GVIX);
      write_uint(fh, o->op_targ ? o->op_targ : cPADOPx(o)->op_padix);
#else
      write_u8(fh, PMAT_CODEx_GVSV);
      write_svptr(fh, cSVOPx(o)->op_sv);
#endif
      break;
  }

  if(o->op_flags & OPf_KIDS) {
    for (kid = ((UNOP*)o)->op_first; kid; kid = OpSIBLING(kid)) {
      dump_optree(fh, cv, kid);
    }
  }

  if(OP_CLASS(o) == OA_PMOP &&
#if (PERL_REVISION == 5) && ((PERL_VERSION > 25) || ((PERL_VERSION == 25) && (PERL_SUBVERSION >= 6)))
     /* The OP_PUSHRE behaviour was moved to OP_SPLIT in 5.25.6 */
     o->op_type != OP_SPLIT &&
#else
     o->op_type != OP_PUSHRE &&
#endif
     (kid = PMOP_pmreplroot(cPMOPx(o))))
    dump_optree(fh, cv, kid);
}

static void write_common_sv(FILE *fh, const SV *sv, size_t size)
{
  // Header
  write_svptr(fh, sv);
  write_u32(fh, SvREFCNT(sv));
  write_uint(fh, sizeof(SV) + size);

  // PTRs
  write_svptr(fh, SvOBJECT(sv) ? (SV*)SvSTASH(sv) : NULL);
}

static void write_private_gv(FILE *fh, const GV *gv)
{
  write_common_sv(fh, (const SV *)gv,
    sizeof(XPVGV) + (isGV_with_GP(gv) ? sizeof(struct gp) : 0));

  if(isGV_with_GP(gv)) {
    // Header
    write_uint(fh, GvLINE(gv));

    // PTRs
    write_svptr(fh, (SV*)GvSTASH(gv));
    write_svptr(fh,      GvSV(gv));
    write_svptr(fh, (SV*)GvAV(gv));
    write_svptr(fh, (SV*)GvHV(gv));
    write_svptr(fh, (SV*)GvCV(gv));
    write_svptr(fh, (SV*)GvEGV(gv));
    write_svptr(fh, (SV*)GvIO(gv));
    write_svptr(fh, (SV*)GvFORM(gv));

    // STRs
    write_str(fh, GvNAME(gv));
    write_str(fh, GvFILE(gv));
  }
  else {
    // Header
    write_uint(fh, 0);

    // PTRs
    write_svptr(fh, (SV*)GvSTASH(gv));
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);

    // STRs
    write_str(fh, NULL);
    write_str(fh, NULL);
  }
}

static void write_private_sv(FILE *fh, const SV *sv)
{
  size_t size = 0;
  switch(SvTYPE(sv)) {
    case SVt_IV: break;
    case SVt_NV:   size += sizeof(NV); break;
    case SVt_PV:   size += sizeof(XPV) - STRUCT_OFFSET(XPV, xpv_cur); break;
    case SVt_PVIV: size += sizeof(XPVIV) - STRUCT_OFFSET(XPV, xpv_cur); break;
    case SVt_PVNV: size += sizeof(XPVNV) - STRUCT_OFFSET(XPV, xpv_cur); break;
    case SVt_PVMG: size += sizeof(XPVMG); break;
  }

  if(SvPOK(sv))
    size += SvLEN(sv);
  if(SvOOK(sv)) {
    STRLEN offset;
    SvOOK_offset(sv, offset);
    size += offset;
  }

  write_common_sv(fh, sv, size);

  // Header
  write_u8(fh, (SvIOK(sv) ? 0x01 : 0) |
               (SvUOK(sv) ? 0x02 : 0) |
               (SvNOK(sv) ? 0x04 : 0) |
               (SvPOK(sv) ? 0x08 : 0) |
               (SvUTF8(sv) ? 0x10 : 0));
  write_uint(fh, SvIOK(sv) ? SvUVX(sv) : 0);
  write_nv(fh, SvNOK(sv) ? SvNVX(sv) : 0.0);
  write_uint(fh, SvPOK(sv) ? SvCUR(sv) : 0);

  // PTRs
#if (PERL_REVISION == 5) && (PERL_VERSION <= 20)
  write_svptr(fh, (SV *)SvOURSTASH(sv));
#else
  write_svptr(fh, NULL);
#endif

  // STRs
  if(SvPOK(sv)) {
    STRLEN len = SvCUR(sv);
    if(max_string > -1 && len > max_string)
      len = max_string;
    write_strn(fh, SvPVX((SV *)sv), len);
  }
  else
    write_str(fh, NULL);
}

static void write_private_rv(FILE *fh, const SV *rv)
{
  write_common_sv(fh, rv, 0);

  // Header
  write_u8(fh, (SvWEAKREF(rv) ? 0x01 : 0));

  // PTRs
  write_svptr(fh, SvRV((SV *)rv));
#if (PERL_REVISION == 5) && (PERL_VERSION <= 20)
  write_svptr(fh, (SV *)SvOURSTASH(rv));
#else
  write_svptr(fh, NULL);
#endif
}

static void write_private_av(FILE *fh, const AV *av)
{
  /* Perl doesn't bother to keep AvFILL(PL_curstack) updated for efficiency
   * reasons, so if we're looking at PL_curstack we'll use a different method
   * to calculate this
   */
  int len = (av == PL_curstack) ? (PL_stack_sp - PL_stack_base + 1) :
    AvFILLp(av) + 1;

  write_common_sv(fh, (const SV *)av,
    sizeof(XPVAV) + sizeof(SV *) * (AvMAX(av) + 1));

  // Header
  write_uint(fh, len);
  write_u8(fh, (!AvREAL(av) ? 0x01 : 0));

  // Body
  int i;
  for(i = 0; i < len; i++)
    write_svptr(fh, AvARRAY(av)[i]);
}

static int write_hv_header(FILE *fh, const HV *hv, size_t size)
{
  size += sizeof(XPVHV);
  int nkeys = 0;

  if(HvARRAY(hv)) {
    int bucket;
    for(bucket = 0; bucket <= HvMAX(hv); bucket++) {
      HE *he;
      size += sizeof(HE *);

      for(he = HvARRAY(hv)[bucket]; he; he = he->hent_next) {
        size += sizeof(HE);
        nkeys++;

        if(!HvSHAREKEYS(hv))
          size += sizeof(HEK) + he->hent_hek->hek_len + 2;
      }
    }
  }

  write_common_sv(fh, (const SV *)hv, size);

  return nkeys;
}

static void write_hv_body_elems(FILE *fh, const HV *hv)
{
  // The shared string table (PL_strtab) has shared strings as keys but its
  // values are not SV pointers; they are refcounts. Pretend these values are
  // NULL.
  bool is_strtab = (hv == PL_strtab);

  int bucket;
  for(bucket = 0; bucket <= HvMAX(hv); bucket++) {
    HE *he;
    for(he = HvARRAY(hv)[bucket]; he; he = he->hent_next) {
      STRLEN len;
      char *key = HePV(he, len);
      write_strn(fh, key, len);
      write_svptr(fh, is_strtab ? NULL : HeVAL(he));
    }
  }
}

static void write_private_hv(FILE *fh, const HV *hv)
{
  int nkeys = write_hv_header(fh, hv, 0);

  // Header
  write_uint(fh, nkeys);

  // PTRs
  if(SvOOK(hv) && HvAUX(hv))
    write_svptr(fh, (SV*)HvAUX(hv)->xhv_backreferences);
  else
    write_svptr(fh, NULL);

  // Body
  if(HvARRAY(hv) && nkeys)
    write_hv_body_elems(fh, hv);
}

static void write_private_stash(FILE *fh, const HV *stash)
{
  struct mro_meta *mro_meta = HvAUX(stash)->xhv_mro_meta;

  int nkeys = write_hv_header(fh, stash,
    sizeof(struct xpvhv_aux) + (mro_meta ? sizeof(struct mro_meta) : 0));

  // Header
  // HASH
  write_uint(fh, nkeys);

  // PTRs
  if(SvOOK(stash) && HvAUX(stash))
    write_svptr(fh, (SV*)HvAUX(stash)->xhv_backreferences);
  else
    write_svptr(fh, NULL);
  if(mro_meta) {
#if (PERL_REVISION == 5) && (PERL_VERSION >= 12)
    write_svptr(fh, (SV*)mro_meta->mro_linear_all);
    write_svptr(fh,      mro_meta->mro_linear_current);
#else
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
#endif
    write_svptr(fh, (SV*)mro_meta->mro_nextmethod);
#if (PERL_REVISION == 5) && ((PERL_VERSION > 10) || (PERL_VERSION == 10 && PERL_SUBVERSION > 0))
    write_svptr(fh, (SV*)mro_meta->isa);
#else
    write_svptr(fh, NULL);
#endif
  }
  else {
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
    write_svptr(fh, NULL);
  }

  // STRs
  write_str(fh, HvNAME(stash));

  // Body
  if(HvARRAY(stash))
    write_hv_body_elems(fh, stash);
}

static void write_private_cv(FILE *fh, const CV *cv)
{
  bool is_xsub = CvISXSUB(cv);
  PADLIST *pl = (is_xsub ? NULL : CvPADLIST(cv));

  /* If the optree contains custom ops, the OP_CLASS() macro will allocate
   * a mortal SV. We'll need to FREETMPS it to ensure we don't dump it
   * accidentally
   */
  SAVETMPS;

  // TODO: accurate size information on CVs
  write_common_sv(fh, (const SV *)cv, sizeof(XPVCV));

  // Header
  int line = 0;
  OP *start;
  if(!CvISXSUB(cv) && !CvCONST(cv) && (start = CvSTART(cv))) {
    if(start->op_type == OP_NEXTSTATE)
      line = CopLINE((COP*)start);
  }
  write_uint(fh, line);
  write_u8(fh, (CvCLONE(cv)       ? 0x01 : 0) |
               (CvCLONED(cv)      ? 0x02 : 0) |
               (is_xsub           ? 0x04 : 0) |
               (CvWEAKOUTSIDE(cv) ? 0x08 : 0) |
#if (PERL_REVISION == 5) && (PERL_VERSION >= 14)
               (CvCVGV_RC(cv)     ? 0x10 : 0) |
#else
/* Prior to 5.14, CvANON() was used to indicate this */
               (CvANON(cv)        ? 0x10 : 0) |
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 22)
               (CvLEXICAL(cv)     ? 0x20 : 0) |
#endif
               0);
  if(!is_xsub && !CvCONST(cv))
    write_ptr(fh, CvROOT(cv));
  else
    write_ptr(fh, NULL);

  write_u32(fh, CvDEPTH(cv));

  // PTRs
  write_svptr(fh, (SV*)CvSTASH(cv));
#if (PERL_REVISION == 5) && (PERL_VERSION >= 18)
  if(CvNAMED(cv))
    write_svptr(fh, NULL);
  else
#endif
    write_svptr(fh, (SV*)CvGV(cv));
  write_svptr(fh, (SV*)CvOUTSIDE(cv));
#if (PERL_REVISION == 5) && (PERL_VERSION >= 20)
  /* Padlists are no longer heap-allocated on 5.20+ */
  write_svptr(fh, NULL);
#else
  write_svptr(fh, (SV*)(pl));
#endif
  if(CvCONST(cv))
    write_svptr(fh, (SV*)CvXSUBANY(cv).any_ptr);
  else
    write_svptr(fh, NULL);

  // STRs
  if(CvFILE(cv))
    write_str(fh, CvFILE(cv));
  else
    write_str(fh, "");

#if (PERL_REVISION == 5) && (PERL_VERSION >= 18)
  if(CvNAMED(cv))
    write_str(fh, HEK_KEY(CvNAME_HEK((CV*)cv)));
  else
#endif
    write_str(fh, NULL);

  // Body
  if(cv == PL_main_cv && PL_main_root)
    /* The PL_main_cv does not have a CvROOT(); instead that is found in
     * PL_main_root
     */
    dump_optree(fh, cv, PL_main_root);
  else if(!is_xsub && !CvCONST(cv) && CvROOT(cv))
    dump_optree(fh, cv, CvROOT(cv));

#if (PERL_REVISION == 5) && (PERL_VERSION >= 18)
  if(pl) {
    PADNAME **names = PadlistNAMESARRAY(pl);
    PAD **pads = PadlistARRAY(pl);
    int depth, i;

    write_u8(fh, PMAT_CODEx_PADNAMES);
#  if (PERL_VERSION > 20)
    write_svptr(fh, NULL);
    {
      PADNAME **padnames = PadnamelistARRAY(PadlistNAMES(pl));
      int padix_max = PadnamelistMAX(PadlistNAMES(pl));

      int padix;
      for(padix = 1; padix <= padix_max; padix++) {
        PADNAME *pn = padnames[padix];
        if(!pn)
          continue;

        write_u8(fh, PMAT_CODEx_PADNAME);
        write_uint(fh, padix);
        write_str(fh, PadnamePV(pn));
        write_svptr(fh, (SV*)PadnameOURSTASH(pn));

        if(PadnameFLAGS(pn)) {
          write_u8(fh, PMAT_CODEx_PADNAME_FLAGS);
          write_uint(fh, padix);
          write_u8(fh, (PadnameOUTER(pn)   ? 0x01 : 0) |
                       (PadnameIsSTATE(pn) ? 0x02 : 0) |
                       (PadnameLVALUE(pn)  ? 0x04 : 0) |
                       (PadnameFLAGS(pn) & PADNAMEt_TYPED ? 0x08 : 0) |
                       (PadnameFLAGS(pn) & PADNAMEt_OUR   ? 0x10 : 0));
        }
      }
    }
#  else
    write_svptr(fh, (SV*)PadlistNAMES(pl));
#  endif

    for(depth = 1; depth <= PadlistMAX(pl); depth++) {
      PAD *pad = pads[depth];

      write_u8(fh, PMAT_CODEx_PAD);
      write_uint(fh, depth);
      write_svptr(fh, (SV*)pad);
    }
  }
#endif

  write_u8(fh, 0);

  FREETMPS;
}

static void write_private_io(FILE *fh, const IO *io)
{
  write_common_sv(fh, (const SV *)io, sizeof(XPVIO));

  write_uint(fh, PerlIO_fileno(IoIFP(io)));
  write_uint(fh, PerlIO_fileno(IoOFP(io)));

  // PTRs
  write_svptr(fh, (SV*)IoTOP_GV(io));
  write_svptr(fh, (SV*)IoFMT_GV(io));
  write_svptr(fh, (SV*)IoBOTTOM_GV(io));
}

static void write_private_lv(FILE *fh, const SV *sv)
{
  write_common_sv(fh, sv, sizeof(XPVLV));

  // Header
  write_u8(fh, LvTYPE(sv));
  write_uint(fh, LvTARGOFF(sv));
  write_uint(fh, LvTARGLEN(sv));

  // PTRs
  write_svptr(fh, LvTARG(sv));
}

static void write_annotations_from_stack(FILE *fh, int n)
{
  dSP;
  SV **p = SP - n + 1;

  while(p <= SP) {
    unsigned char type = SvIV(p[0]);
    switch(type) {
      case PMAT_SVxSVSVnote:
        write_u8(fh, type);
        write_svptr(fh, p[1]); /* target */
        write_svptr(fh, p[2]); /* value */
        write_strn(fh, SvPV_nolen(p[3]), SvCUR(p[3])); /* annotation */
        p += 4;
        break;
      default:
        fprintf(stderr, "ARG: Unsure how to handle PMAT_SVn annotation type %02x\n", type);
        p = SP + 1;
    }
  }
}

static void write_sv(FILE *fh, const SV *sv)
{
  unsigned char type = -1;
  switch(SvTYPE(sv)) {
    case SVt_NULL:
      type = PMAT_SVtUNDEF; break;
    case SVt_IV:
    case SVt_NV:
    case SVt_PV:
    case SVt_PVIV:
    case SVt_PVNV:
    case SVt_PVMG:
      type = SvROK(sv) ? PMAT_SVtREF : PMAT_SVtSCALAR; break;
#if (PERL_REVISION == 5) && (PERL_VERSION < 12)
    case SVt_RV: type = PMAT_SVtREF; break;
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 19)
    case SVt_INVLIST: type = PMAT_SVtINVLIST; break;
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 12)
    case SVt_REGEXP: type = PMAT_SVtREGEXP; break;
#endif
    case SVt_PVGV: type = PMAT_SVtGLOB; break;
    case SVt_PVLV: type = PMAT_SVtLVALUE; break;
    case SVt_PVAV: type = PMAT_SVtARRAY; break;
    // HVs with names we call STASHes
    case SVt_PVHV: type = HvNAME(sv) ? PMAT_SVtSTASH : PMAT_SVtHASH; break;
    case SVt_PVCV: type = PMAT_SVtCODE; break;
    case SVt_PVFM: type = PMAT_SVtFORMAT; break;
    case SVt_PVIO: type = PMAT_SVtIO; break;
    default:
      fprintf(stderr, "dumpsv %p has unknown SvTYPE %d\n", sv, SvTYPE(sv));
      break;
  }

  if(type == PMAT_SVtSCALAR && !SvOK(sv))
    type = PMAT_SVtUNDEF;

  write_u8(fh, type);

  switch(type) {
    case PMAT_SVtGLOB:   write_private_gv   (fh, (GV*)sv); break;
    case PMAT_SVtSCALAR: write_private_sv   (fh,      sv); break;
    case PMAT_SVtREF:    write_private_rv   (fh,      sv); break;
    case PMAT_SVtARRAY:  write_private_av   (fh, (AV*)sv); break;
    case PMAT_SVtHASH:   write_private_hv   (fh, (HV*)sv); break;
    case PMAT_SVtSTASH:  write_private_stash(fh, (HV*)sv); break;
    case PMAT_SVtCODE:   write_private_cv   (fh, (CV*)sv); break;
    case PMAT_SVtIO:     write_private_io   (fh, (IO*)sv); break;
    case PMAT_SVtLVALUE: write_private_lv   (fh,      sv); break;

#if (PERL_REVISION == 5) && (PERL_VERSION >= 12)
    case PMAT_SVtREGEXP: write_common_sv(fh, sv, sizeof(regexp)); break;
#endif
    case PMAT_SVtFORMAT: write_common_sv(fh, sv, sizeof(XPVFM)); break;
    case PMAT_SVtINVLIST: write_common_sv(fh, sv, sizeof(XPV) + SvLEN(sv)); break;
    case PMAT_SVtUNDEF:  write_common_sv(fh, sv, 0); break;
  }

  if(SvMAGICAL(sv)) {
    MAGIC *mg;
    for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
      write_u8(fh, PMAT_SVxMAGIC);
      write_svptr(fh, sv);
      write_u8(fh, mg->mg_type);
      write_u8(fh, (mg->mg_flags & MGf_REFCOUNTED ? 0x01 : 0));
      write_svptr(fh, mg->mg_obj);
      if(mg->mg_len == HEf_SVKEY)
        write_svptr(fh, (SV*)mg->mg_ptr);
      else
        write_svptr(fh, NULL);

      if(mg->mg_type == PERL_MAGIC_ext &&
         mg->mg_ptr && mg->mg_len != HEf_SVKEY) {
        HE *he;

        he = hv_fetch_ent(helper_per_magic, make_tmp_iv((IV)mg->mg_virtual), 0, 0);
        if(he) {
          DMD_MagicHelper *helperfunc = (DMD_MagicHelper *)SvUV(HeVAL(he));

          ENTER;
          SAVETMPS;

          int ret = (*helperfunc)(aTHX_ sv, mg);
          if(ret > 0)
            write_annotations_from_stack(fh, ret);

          FREETMPS;
          LEAVE;
        }
      }
    }
  }

  if(SvOBJECT(sv)) {
    HV *stash = SvSTASH(sv);
    SV **helpersv = hv_fetch(helper_per_package, HvNAME(stash), HvNAMELEN(stash), 0);

    if(helpersv) {
      DMD_Helper *helperfunc = (DMD_Helper *)SvUV(*helpersv);

      ENTER;
      SAVETMPS;

      int ret = (*helperfunc)(aTHX_ sv);
      if(ret > 0)
        write_annotations_from_stack(fh, ret);

      FREETMPS;
      LEAVE;
    }
  }

#ifdef DEBUG_LEAKING_SCALARS
  {
    write_u8(fh, PMAT_SVxDEBUGREPORT);
    write_svptr(fh, sv);
    write_uint(fh, sv->sv_debug_serial);
    write_uint(fh, sv->sv_debug_line);
    /* TODO: this is going to make the file a lot larger, due to nonshared
     * strings. Consider if there's a way we can share these somehow
     */
    write_str(fh, sv->sv_debug_file);
  }
#endif
}

#if (PERL_REVISION == 5) && (PERL_VERSION < 14)
/*
 * This won't be very good, but good enough for our needs
 */
static I32 dopoptosub_at(const PERL_CONTEXT *cxstk, I32 startingblock)
{
  dVAR;
  I32 i;

  for(i = startingblock; i >= 0; i--) {
    const PERL_CONTEXT * const cx = &cxstk[i];
    switch (CxTYPE(cx)) {
      case CXt_EVAL:
      case CXt_SUB:
      case CXt_FORMAT:
        return i;
      default:
        continue;
    }
  }
  return i;
}

static const PERL_CONTEXT *caller_cx(int count, void *ignore)
{
  I32 cxix = dopoptosub_at(cxstack, cxstack_ix);
  const PERL_CONTEXT *ccstack = cxstack;
  const PERL_SI *top_si = PL_curstackinfo;

  while(1) {
    while(cxix < 0 && top_si->si_type != PERLSI_MAIN) {
      top_si = top_si->si_prev;

      ccstack = top_si->si_cxstack;
      cxix = dopoptosub_at(ccstack, top_si->si_cxix);
    }

    if(cxix < 0)
      return NULL;

    if (PL_DBsub && GvCV(PL_DBsub) && cxix >= 0 && ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
      count++;

    if(!count--)
      break;

    cxix = dopoptosub_at(ccstack, cxix - 1);
  }

  const PERL_CONTEXT *cx = &ccstack[cxix];

  if(CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
    const I32 dbcxix = dopoptosub_at(ccstack, cxix - 1);
    if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
      cx = &ccstack[dbcxix];
  }

  return cx;
}
#endif

static void dumpfh(FILE *fh)
{
  max_string = SvIV(get_sv("Devel::MAT::Dumper::MAX_STRING", GV_ADD));

  // Header
  fwrite("PMAT", 4, 1, fh);

  int flags = 0;
#if (BYTEORDER == 0x1234) || (BYTEORDER == 0x12345678)
  // little-endian
#elif (BYTEORDER == 0x4321) || (BYTEORDER == 0x87654321)
  flags |= 0x01; // big-endian
#else
# error "Expected BYTEORDER to be big- or little-endian"
#endif

#if UVSIZE == 8
  flags |= 0x02; // 64-bit integers
#elif UVSIZE == 4
#else
# error "Expected UVSIZE to be either 4 or 8"
#endif

#if PTRSIZE == 8
  flags |= 0x04; // 64-bit pointers
#elif PTRSIZE == 4
#else
# error "Expected PTRSIZE to be either 4 or 8"
#endif

#if NVSIZE > 8
  flags |= 0x08; // long-double
#endif

#ifdef USE_ITHREADS
  flags |= 0x10; // ithreads
#endif

  write_u8(fh, flags);
  write_u8(fh, 0);
  write_u8(fh, FORMAT_VERSION_MAJOR);
  write_u8(fh, FORMAT_VERSION_MINOR);

  write_u32(fh, PERL_REVISION<<24 | PERL_VERSION<<16 | PERL_SUBVERSION);

  write_u8(fh, sizeof(sv_sizes)/3);
  fwrite(sv_sizes, sizeof(sv_sizes), 1, fh);

  write_u8(fh, sizeof(svx_sizes)/3);
  fwrite(svx_sizes, sizeof(svx_sizes), 1, fh);

  write_u8(fh, sizeof(ctx_sizes)/3);
  fwrite(ctx_sizes, sizeof(ctx_sizes), 1, fh);

  // Roots
  write_svptr(fh, &PL_sv_undef);
  write_svptr(fh, &PL_sv_yes);
  write_svptr(fh, &PL_sv_no);

  struct root { char *name; SV *ptr; } roots[] = {
    { "main_cv",         (SV*)PL_main_cv },
    { "defstash",        (SV*)PL_defstash },
    { "mainstack",       (SV*)PL_mainstack },
    { "beginav",         (SV*)PL_beginav },
    { "checkav",         (SV*)PL_checkav },
    { "unitcheckav",     (SV*)PL_unitcheckav },
    { "initav",          (SV*)PL_initav },
    { "endav",           (SV*)PL_endav },
    { "strtab",          (SV*)PL_strtab },
    { "envgv",           (SV*)PL_envgv },
    { "incgv",           (SV*)PL_incgv },
    { "statgv",          (SV*)PL_statgv },
    { "statname",        (SV*)PL_statname },
    { "tmpsv",           (SV*)PL_Sv }, // renamed
    { "defgv",           (SV*)PL_defgv },
    { "argvgv",          (SV*)PL_argvgv },
    { "argvoutgv",       (SV*)PL_argvoutgv },
    { "argvout_stack",   (SV*)PL_argvout_stack },
    { "errgv",           (SV*)PL_errgv },
    { "fdpid",           (SV*)PL_fdpid },
    { "preambleav",      (SV*)PL_preambleav },
    { "modglobalhv",     (SV*)PL_modglobal },
#ifdef USE_ITHREADS
    { "regex_padav",     (SV*)PL_regex_padav },
#endif
    { "sortstash",       (SV*)PL_sortstash },
    { "firstgv",         (SV*)PL_firstgv },
    { "secondgv",        (SV*)PL_secondgv },
    { "debstash",        (SV*)PL_debstash },
    { "stashcache",      (SV*)PL_stashcache },
    { "isarev",          (SV*)PL_isarev },
#if (PERL_REVISION == 5) && ((PERL_VERSION > 10) || (PERL_VERSION == 10 && PERL_SUBVERSION > 0))
    { "registered_mros", (SV*)PL_registered_mros },
#endif
    { "rs",              (SV*)PL_rs },
    { "last_in_gv",      (SV*)PL_last_in_gv },
    { "defoutgv",        (SV*)PL_defoutgv },
    { "hintgv",          (SV*)PL_hintgv },
    { "patchlevel",      (SV*)PL_patchlevel },
    { "e_script",        (SV*)PL_e_script },
    { "mess_sv",         (SV*)PL_mess_sv },
    { "ors_sv",          (SV*)PL_ors_sv },
    { "encoding",        (SV*)PL_encoding },
#if (PERL_REVISION == 5) && (PERL_VERSION >= 12)
    { "ofsgv",           (SV*)PL_ofsgv },
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 14) && (PERL_VERSION <= 20)
    { "apiversion",      (SV*)PL_apiversion },
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 14)
    { "blockhooks",      (SV*)PL_blockhooks },
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 16)
    { "custom_ops",      (SV*)PL_custom_ops },
    { "custom_op_names", (SV*)PL_custom_op_names },
    { "custom_op_descs", (SV*)PL_custom_op_descs },
#endif

    // Unicode etc...
    { "utf8_mark",              (SV*)PL_utf8_mark },
    { "utf8_toupper",           (SV*)PL_utf8_toupper },
    { "utf8_totitle",           (SV*)PL_utf8_totitle },
    { "utf8_tolower",           (SV*)PL_utf8_tolower },
    { "utf8_tofold",            (SV*)PL_utf8_tofold },
    { "utf8_idstart",           (SV*)PL_utf8_idstart },
    { "utf8_idcont",            (SV*)PL_utf8_idcont },
#if (PERL_REVISION == 5) && (PERL_VERSION >= 12) && (PERL_VERSION <= 20)
    { "utf8_X_extend",          (SV*)PL_utf8_X_extend },
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 14)
    { "utf8_xidstart",          (SV*)PL_utf8_xidstart },
    { "utf8_xidcont",           (SV*)PL_utf8_xidcont },
    { "utf8_foldclosures",      (SV*)PL_utf8_foldclosures },
#if (PERL_REVISION == 5) && ((PERL_VERSION < 29) || (PERL_VERSION == 29 && PERL_SUBVERSION < 7))
    { "utf8_foldable",          (SV*)PL_utf8_foldable },
#endif
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 16)
    { "Latin1",                 (SV*)PL_Latin1 },
    { "AboveLatin1",            (SV*)PL_AboveLatin1 },
    { "utf8_perl_idstart",      (SV*)PL_utf8_perl_idstart },
#endif
#if (PERL_REVISION == 5) && (PERL_VERSION >= 18)
#if (PERL_REVISION == 5) && ((PERL_VERSION < 29) || (PERL_VERSION == 29 && PERL_SUBVERSION < 7))
    { "NonL1NonFinalFold",      (SV*)PL_NonL1NonFinalFold },
#endif
    { "HasMultiCharFold",       (SV*)PL_HasMultiCharFold },
#  if (PERL_VERSION <= 20)
    { "utf8_X_regular_begin",   (SV*)PL_utf8_X_regular_begin },
#  endif
    { "utf8_charname_begin",    (SV*)PL_utf8_charname_begin },
    { "utf8_charname_continue", (SV*)PL_utf8_charname_continue },
    { "utf8_perl_idcont",       (SV*)PL_utf8_perl_idcont },
#endif
#if (PERL_REVISION == 5) && ((PERL_VERSION > 19) || (PERL_VERSION == 19 && PERL_SUBVERSION >= 4))
    { "UpperLatin1",            (SV*)PL_UpperLatin1 },
#endif
  };

  write_u32(fh, sizeof(roots) / sizeof(roots[0]));

  int i;
  for(i = 0; i < sizeof(roots) / sizeof(roots[0]); i++) {
    write_str(fh, roots[i].name);
    write_svptr(fh, roots[i].ptr);
  }

  // Stack
  write_uint(fh, PL_stack_sp - PL_stack_base + 1);
  SV **sp;
  for(sp = PL_stack_base; sp <= PL_stack_sp; sp++)
    write_svptr(fh, *sp);

  bool seen_defstash = false;

  // Heap
  SV *arena;
  for(arena = PL_sv_arenaroot; arena; arena = (SV *)SvANY(arena)) {
    const SV *arenaend = &arena[SvREFCNT(arena)];

    SV *sv;
    for(sv = arena + 1; sv < arenaend; sv++) {
      if(sv == tmpsv)
        continue;

      switch(SvTYPE(sv)) {
        case 0xff:
          continue;
      }

      write_sv(fh, sv);

      if(sv == (const SV *)PL_defstash)
        seen_defstash = true;
    }
  }

  // and a few other things that don't actually appear in the arena
  if(!seen_defstash)
    write_sv(fh, (const SV *)PL_defstash);

  // Savestack
#if (PERL_REVISION == 5) && (PERL_VERSION >= 18)
  /* The savestack only had a vaguely nicely predicable layout from perl 5.18 onwards
   * On earlier perls we'll just not bother. Sorry
   * No `local` detection for you
   */

  int saveix = PL_savestack_ix;
  while(saveix) {
    UV uv = PL_savestack[saveix-1].any_uv;
    U8 type = (U8)uv & SAVE_MASK;

    /* TODO: this seems fragile - does core perl not export a nice way to
     * do it?
     */
    char count;
    if(type <= SAVEt_ARG0_MAX)
      count = 0;
    else if(type <= SAVEt_ARG1_MAX)
      count = 1;
    else if(type <= SAVEt_ARG2_MAX)
      count = 2;
    else if(type <= SAVEt_MAX)
      count = 3;
    else
      /* Unrecognised type; just abort here */
      break;

    saveix -= (count + 1);
    ANY *a0 = count > 0 ? &PL_savestack[saveix  ] : NULL,
        *a1 = count > 1 ? &PL_savestack[saveix+1] : NULL,
        *a2 = count > 2 ? &PL_savestack[saveix+2] : NULL;

    switch(type) {
      /* Most savestack entries aren't very interesting to Devel::MAT, but
       * there's a few we find useful. A lot of them don't add any linkages
       * between SVs, so we can ignore the majority of them
       */
      case SAVEt_CLEARSV:
      case SAVEt_CLEARPADRANGE:

#if (PERL_REVISION == 5) && (PERL_VERSION >= 24)
      case SAVEt_TMPSFLOOR:
#endif
      case SAVEt_BOOL:
      case SAVEt_COMPPAD:
      case SAVEt_FREEOP:
      case SAVEt_FREESV:
      case SAVEt_I16:
      case SAVEt_I32_SMALL:
      case SAVEt_I8:
      case SAVEt_INT_SMALL:
      case SAVEt_MORTALIZESV:
      case SAVEt_OP:
      case SAVEt_PARSER:
      case SAVEt_SHARED_PVREF:
      case SAVEt_SPTR:

      case SAVEt_DESTRUCTOR:
      case SAVEt_DESTRUCTOR_X:
      case SAVEt_GP:
      case SAVEt_I32:
      case SAVEt_INT:
      case SAVEt_IV:
      case SAVEt_LONG:
#if (PERL_REVISION == 5) && (PERL_VERSION >= 20)
      case SAVEt_STRLEN:
#endif
      case SAVEt_VPTR:
      case SAVEt_ADELETE:

      case SAVEt_DELETE:
        /* ignore */
        break;

      case SAVEt_AV:
        /* a local'ised @var */
        write_u8(fh, PMAT_SVxSAVED_AV);
        write_svptr(fh, a0->any_ptr); // GV
        write_svptr(fh, a1->any_ptr); // AV
        break;

      case SAVEt_HV:
        /* a local'ised %var */
        write_u8(fh, PMAT_SVxSAVED_HV);
        write_svptr(fh, a0->any_ptr); // GV
        write_svptr(fh, a1->any_ptr); // HV
        break;

      case SAVEt_SV:
        /* a local'ised $var */
        write_u8(fh, PMAT_SVxSAVED_SV);
        write_svptr(fh, a0->any_ptr); // GV
        write_svptr(fh, a1->any_ptr); // SV
        break;

      case SAVEt_HELEM:
        /* a local'ised $hash{key} */
        write_u8(fh, PMAT_SVxSAVED_HELEM);
        write_svptr(fh, a0->any_ptr); // HV
        write_svptr(fh, a1->any_ptr); // key SV
        write_svptr(fh, a2->any_ptr); // value SV
        break;

      case SAVEt_AELEM:
        /* a local'ised $array[idx] */
        write_u8(fh, PMAT_SVxSAVED_AELEM);
        write_svptr(fh, a0->any_ptr); // AV
        write_uint(fh, a1->any_iv);   // index
        write_svptr(fh, a2->any_ptr); // value SV
        break;

      case SAVEt_GVSLOT:
        /* a local'ised glob slot
         * a0 points at the GV itself, a1 points at one of the slots within
         * the GP part
         * In practice this would only ever be the CODE slot, because other
         * slots have other localisation mechanisms
         */
        if(a1->any_ptr != (SV **) &(GvGP((GV *)a0->any_ptr)->gp_cv)) {
          fprintf(stderr, "TODO: SAVEt_GVSLOT of slot other than ->gp_cv\n");
          break;
        }

        write_u8(fh, PMAT_SVxSAVED_CV);
        write_svptr(fh, a0->any_ptr);
        write_svptr(fh, a2->any_ptr);
        break;

      case SAVEt_GENERIC_SVREF:
        /* Core perl uses this in a number of places, a few of which we can
         * identify
         */
        if(a0->any_ptr == &GvSV(PL_defgv)) {
          /* local $_ = ... */
          write_u8(fh, PMAT_SVxSAVED_SV);
          write_svptr(fh, (SV *)PL_defgv);
          write_svptr(fh, a1->any_ptr);
        }
        else
          fprintf(stderr, "TODO: SAVEt_GENERIC_SVREF *a0=%p a1=%p\n",
            *((void **)a0->any_ptr), a1->any_ptr);
        break;

      default:
        fprintf(stderr, "TODO: savestack type=%d\n", type);
        break;
    }
  }
#endif

  write_u8(fh, 0);

  // Caller context
  int cxix;
  for(cxix = 0; ; cxix++) {
    const PERL_CONTEXT *cx = caller_cx(cxix, NULL);
    if(!cx)
      break;

    switch(CxTYPE(cx)) {
      case CXt_SUB: {
        COP *oldcop = cx->blk_oldcop;

        write_u8(fh, PMAT_CTXtSUB);
        write_u8(fh, cx->blk_gimme);
        write_uint(fh, CopLINE(oldcop));
        write_str(fh, CopFILE(oldcop));

        write_u32(fh, cx->blk_sub.olddepth);
        write_svptr(fh, (SV*)cx->blk_sub.cv);
#if (PERL_REVISION == 5) && ((PERL_VERSION > 23) || (PERL_VERSION == 23 && PERL_SUBVERSION >= 8))
        write_svptr(fh, NULL);
#else
        write_svptr(fh, CxHASARGS(cx) ? (SV*)cx->blk_sub.argarray : NULL);
#endif

        break;
      }
      case CXt_EVAL: {
        COP *oldcop = cx->blk_oldcop;


        if(CxOLD_OP_TYPE(cx) == OP_ENTEREVAL) {
          /* eval() */
          write_u8(fh, PMAT_CTXtEVAL);
          write_u8(fh, cx->blk_gimme);
          write_uint(fh, CopLINE(oldcop));
          write_str(fh, CopFILE(oldcop));
          write_svptr(fh, cx->blk_eval.cur_text);
        }
        else if(cx->blk_eval.old_namesv)
          // require
          ;
        else {
          /* eval BLOCK == TRY */
          write_u8(fh, PMAT_CTXtTRY);
          write_u8(fh, cx->blk_gimme);
          write_uint(fh, CopLINE(oldcop));
          write_str(fh, CopFILE(oldcop));
        }

        break;
      }
    }
  }

  write_u8(fh, 0);
}

MODULE = Devel::MAT::Dumper        PACKAGE = Devel::MAT::Dumper

void
dump(char *file)
CODE:
{
  FILE *fh = fopen(file, "wb+");
  if(!fh)
    croak("Cannot open %s for writing - %s", file, strerror(errno));

  dumpfh(fh);
  fclose(fh);
}

void
dumpfh(FILE *fh)

BOOT:
  helper_per_package = get_hv("Devel::MAT::Dumper::HELPER_PER_PACKAGE", GV_ADD);
  helper_per_magic   = get_hv("Devel::MAT::Dumper::HELPER_PER_MAGIC", GV_ADD);
