#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "fmmacar.h"
#include "tomacar.h"

#define PkgName "Lingua::AR::MacArabic"

/* Perl 5.6.1 ? */
#ifndef uvuni_to_utf8
#define uvuni_to_utf8   uv_to_utf8
#endif /* uvuni_to_utf8 */

/* Perl 5.6.1 ? */
#ifndef utf8n_to_uvuni
#define utf8n_to_uvuni  utf8_to_uv
#endif /* utf8n_to_uvuni */

#define SBCS_LEN	1

#define FromMacTbl	fm_macar_tbl
#define FromMacDir	fm_macar_dir
#define ToMacTbl 	to_macar_table
#define ToMacTblN	to_macar_N
#define ToMacTblL	to_macar_L
#define ToMacTblR	to_macar_R

static STDCHAR ** ToMacTbl [] = {
    ToMacTblN,
    ToMacTblL,
    ToMacTblR
};

static void
sv_cat_cvref (SV *dst, SV *cv, SV *sv)
{
    dSP;
    int count;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(sv));
    PUTBACK;
    count = call_sv(cv, (G_EVAL|G_SCALAR));
    SPAGAIN;
    if (SvTRUE(ERRSV) || count != 1) {
	croak("died in XS, " PkgName "\n");
    }
    sv_catsv(dst,POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;
}

MODULE = Lingua::AR::MacArabic	PACKAGE = Lingua::AR::MacArabic
PROTOTYPES: DISABLE

void
decode(...)
  ALIAS:
    decodeMacArabic = 1
  PREINIT:
    SV *src, *dst;
    STRLEN srclen;
    U8 *s, *e, *p, uni[UTF8_MAXLEN + 1];
    UV uv;
    STDCHAR curdir, predir;
  PPCODE:
    if (0 < items && SvROK(ST(0))) {
	croak(PkgName " 1st argument is REF, but handler for decode is NG.");
    }
    src = (0 < items) ? ST(0) : &PL_sv_undef;

    if (SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_downgrade(src, 0);
    }
    s = (U8*)SvPV(src,srclen);
    e = s + srclen;
    dst = sv_2mortal(newSV(1));
    (void)SvPOK_only(dst);
    SvUTF8_on(dst);

    predir = MACBIDI_DIR_NT;
    for (p = s; p < e; p++, predir = curdir) {
	curdir = FromMacDir[*p];

	if (predir != curdir) {
	    if (predir != MACBIDI_DIR_NT) {
		uv = MACBIDI_UV_PDF;
		(void)uvuni_to_utf8(uni, uv);
		sv_catpvn(dst, (char*)uni, (STRLEN)UNISKIP(uv));
	    }
	    if (curdir != MACBIDI_DIR_NT) {
		uv = (curdir == MACBIDI_DIR_LR) ? MACBIDI_UV_LRO :
		     (curdir == MACBIDI_DIR_RL) ? MACBIDI_UV_RLO :
		     0; /* Panic: undefined direction in decode" */;
		(void)uvuni_to_utf8(uni, uv);
		sv_catpvn(dst, (char*)uni, (STRLEN)UNISKIP(uv));
	    }
	}

	uv = FromMacTbl[*p];
	(void)uvuni_to_utf8(uni, uv);
	sv_catpvn(dst, (char*)uni, (STRLEN)UNISKIP(uv));
    }

    if (predir != MACBIDI_DIR_NT) {
	uv = MACBIDI_UV_PDF;
	(void)uvuni_to_utf8(uni, uv);
	sv_catpvn(dst, (char*)uni, (STRLEN)UNISKIP(uv));
    }
    XPUSHs(dst);



void
encode(...)
  ALIAS:
    encodeMacArabic = 1
  PREINIT:
    SV *src, *dst, *ref;
    STRLEN srclen, retlen;
    U8 *s, *e, *p;
    STDCHAR b, *t, **table;
    UV uv;
    STDCHAR dir;
    bool has_cv = FALSE;
    bool has_pv = FALSE;
  PPCODE:
    ref = NULL;
    if (0 < items && SvROK(ST(0))) {
	ref = SvRV(ST(0));
	if (SvTYPE(ref) == SVt_PVCV)
	    has_cv = TRUE;
	else if (SvPOK(ref))
	    has_pv = TRUE;
	else
	    croak(PkgName " 1st argument is not STRING nor CODEREF");
    }
    src = ref
	? (1 < items) ? ST(1) : &PL_sv_undef
	: (0 < items) ? ST(0) : &PL_sv_undef;

    if (!SvUTF8(src)) {
	src = sv_mortalcopy(src);
	sv_utf8_upgrade(src);
    }
    s = (U8*)SvPV(src,srclen);
    e = s + srclen;
    dst = sv_2mortal(newSV(1));
    (void)SvPOK_only(dst);
    SvUTF8_off(dst);

    dir = MACBIDI_DIR_NT;

    for (p = s; p < e;) {
	uv = utf8n_to_uvuni(p, e - p, &retlen, 0);
	p += retlen;

	switch (uv) {
	case MACBIDI_UV_PDF:
	    dir = MACBIDI_DIR_NT;
	    break;
	case MACBIDI_UV_LRO:
	    dir = MACBIDI_DIR_LR;
	    break;
	case MACBIDI_UV_RLO:
	    dir = MACBIDI_DIR_RL;
	    break;
	default:
	    table = ToMacTbl[dir];
	    t = uv < 0x10000 ? table[uv >> 8] : NULL;
	    b = t ? t[uv & 0xff] : 0;

	    if (b || uv == 0)
		sv_catpvn(dst, (char*)&b, SBCS_LEN);
	    else if (has_pv)
		sv_catsv(dst, ref);
	    else if (has_cv)
		sv_cat_cvref(dst, ref, newSVuv(uv));
	}
    }
    XPUSHs(dst);

