#include "EXTERN.h"
#include "perl.h"
#include "callparser1.h"
#include "XSUB.h"
#include "object_types.h"

#ifndef XS_INTERNAL
#define XS_INTERNAL(name) static XSPROTO(name)
#endif

static int has_attr(pTHX_ SV *attr_sv, const char *name) {
	const char *p, *end;
	STRLEN alen, nlen;
	if (!SvOK(attr_sv)) return 0;
	p = SvPV(attr_sv, alen);
	end = p + alen;
	nlen = strlen(name);
	while (p < end) {
		const char *comma = (const char *)memchr(p, ',', end - p);
		STRLEN seg = comma ? (STRLEN)(comma - p) : (STRLEN)(end - p);
		if (seg == nlen && memEQ(p, name, nlen)) return 1;
		p += seg + 1;
	}
	return 0;
}

/* ====== Enum type data for Object::Proto registration ====== */

typedef struct {
	HV *val2name;     /* value -> name lookup (for check) */
	HV *lc_name2val;  /* lc(name) -> value lookup (for coerce) */
	IV flags_mask;    /* combined bitmask for :Flags enums, -1 if not flags */
} EnumTypeData;

static bool enum_type_check(pTHX_ SV *val, void *data_ptr) {
	EnumTypeData *etd = (EnumTypeData *)data_ptr;
	const char *pv;
	STRLEN len;

	if (!SvOK(val)) return false;

	/* Flags: accept any valid combination */
	if (etd->flags_mask >= 0) {
		IV iv;
		if (!SvIOK(val) && !(SvPOK(val) && looks_like_number(val)))
			return false;
		iv = SvIV(val);
		return iv >= 0 && (iv & ~etd->flags_mask) == 0;
	}

	/* Int or Str enum: value must exist in val2name */
	pv = SvPV(val, len);
	return hv_exists(etd->val2name, pv, len);
}

static SV *enum_type_coerce(pTHX_ SV *val, void *data_ptr) {
	EnumTypeData *etd = (EnumTypeData *)data_ptr;
	const char *pv;
	STRLEN len;
	SV **found;
	char *lc;
	STRLEN i;
	SV *lc_sv;

	if (!SvOK(val)) return val;

	/* Already a valid value? Return as-is */
	pv = SvPV(val, len);
	if (hv_exists(etd->val2name, pv, len))
		return val;

	/* Try case-insensitive name -> value lookup */
	lc_sv = newSVpvn(pv, len);
	lc = SvPVX(lc_sv);
	for (i = 0; i < len; i++) lc[i] = toLOWER(lc[i]);
	found = hv_fetch(etd->lc_name2val, lc, len, 0);
	SvREFCNT_dec(lc_sv);
	if (found) return sv_mortalcopy(*found);

	return val;
}

static SV *lex_read_ident(pTHX) {
	SV *buf = newSVpvs("");
	I32 c;
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1) break;
		if (!isALNUM(c) && c != '_') break;
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	if (SvCUR(buf) == 0) {
		SvREFCNT_dec(buf);
		return NULL;
	}
	return buf;
}

static SV *lex_read_attrs(pTHX) {
	SV *attr_sv = &PL_sv_undef;
	I32 c = lex_peek_unichar(0);
	while (c == ':') {
		SV *a;
		lex_read_unichar(0);
		a = lex_read_ident(aTHX);
		if (!a) croak("Expected attribute name after ':'");
		if (attr_sv == &PL_sv_undef) {
			attr_sv = a;
		} else {
			sv_catpvs(attr_sv, ",");
			sv_catsv(attr_sv, a);
			SvREFCNT_dec(a);
		}
		lex_read_space(0);
		c = lex_peek_unichar(0);
	}
	return attr_sv;
}

static SV *lex_read_quoted_string(pTHX) {
	I32 quote = lex_peek_unichar(0);
	SV *sv;
	I32 c;
	lex_read_unichar(0);
	sv = newSVpvs("");
	while (1) {
		c = lex_read_unichar(0);
		if (c == -1) croak("Unterminated string in enum declaration");
		if (c == '\\' && quote == '"') {
			I32 next = lex_read_unichar(0);
			if (next == -1) croak("Unterminated string in enum declaration");
			sv_catpvf(sv, "%c", (int)next);
		} else if (c == quote) {
			break;
		} else {
			sv_catpvf(sv, "%c", (int)c);
		}
	}
	return sv;
}

static SV *lex_read_integer(pTHX) {
	int is_neg = 0;
	SV *buf;
	IV ival;
	I32 c = lex_peek_unichar(0);
	if (c == '-') {
		is_neg = 1;
		lex_read_unichar(0);
		lex_read_space(0);
		c = lex_peek_unichar(0);
	}
	if (!isDIGIT(c))
	croak("Expected integer or string value after '=' in enum declaration");
	buf = newSVpvs("");
	while (1) {
		c = lex_peek_unichar(0);
		if (c == -1 || !isDIGIT(c)) break;
		sv_catpvf(buf, "%c", (int)c);
		lex_read_unichar(0);
	}
	ival = SvIV(buf);
	SvREFCNT_dec(buf);
	if (is_neg) ival = -ival;
	return newSViv(ival);
}

static AV *lex_read_variants(pTHX) {
	AV *av = newAV();
	I32 c;
	lex_read_space(0);
	c = lex_peek_unichar(0);
	if (c != '{') croak("Expected '{' after enum name");
	lex_read_unichar(0);
	while (1) {
		SV *vname;
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == '}') { lex_read_unichar(0); break; }
		if (c == -1) croak("Unexpected end of input in enum declaration");
		vname = lex_read_ident(aTHX);
		if (!vname) croak("Expected variant name in enum declaration");
		av_push(av, vname);
		/* optional = value */
		lex_read_space(0);
		c = lex_peek_unichar(0);
		if (c == '=') {
			lex_read_unichar(0);
			lex_read_space(0);
			c = lex_peek_unichar(0);
			if (c == '"' || c == '\'') {
				av_push(av, lex_read_quoted_string(aTHX));
			} else {
				av_push(av, lex_read_integer(aTHX));
			}
		} else {
			av_push(av, &PL_sv_undef);
		}
		lex_read_space(0);
		if (lex_peek_unichar(0) == ',') lex_read_unichar(0);
	}
	return av;
}

typedef struct {
	AV *names;
	AV *values;
	HV *name2val;
	HV *val2name;
} EnumData;

static EnumData build_enum_data(pTHX_ AV *variants, int is_str, int is_flags, const char *pkg, STRLEN pkg_len) {
	EnumData d;
	IV next_ival = is_flags ? 1 : 0;
	I32 pair_count = av_len(variants) + 1;
	I32 i;
	d.names    = newAV();
	d.values   = newAV();
	d.name2val = newHV();
	d.val2name = newHV();
	for (i = 0; i < pair_count; i += 2) {
		SV **name_p = av_fetch(variants, i, 0);
		SV **val_p  = av_fetch(variants, i + 1, 0);
		SV *vname   = name_p ? *name_p : &PL_sv_undef;
		SV *vval    = val_p  ? *val_p  : &PL_sv_undef;
		SV *resolved;
		const char *vname_pv;
		STRLEN vname_len;
		vname_pv = SvPV(vname, vname_len);
		if (SvOK(vval)) {
			if (is_str) {
				resolved = newSVsv(vval);
			} else {
				next_ival = SvIV(vval);
				resolved = newSViv(next_ival);
			}
		} else if (is_str) {
			char *lc;
			STRLEN j;
			resolved = newSVpvn(vname_pv, vname_len);
			lc = SvPVX(resolved);
			for (j = 0; j < vname_len; j++) lc[j] = toLOWER(lc[j]);
		} else {
			resolved = newSViv(next_ival);
		}
		av_push(d.names,  newSVpvn(vname_pv, vname_len));
		av_push(d.values, newSVsv(resolved));
		hv_store(d.name2val, vname_pv, vname_len, newSVsv(resolved), 0);
		{
			const char *val_pv;
			STRLEN val_len;
			SV *val_key = newSVsv(resolved);
			val_pv = SvPV(val_key, val_len);
			hv_store(d.val2name, val_pv, val_len,
				newSVpvn(vname_pv, vname_len), 0);
			SvREFCNT_dec(val_key);
		}
		{
			SV *val_copy = newSVsv(resolved);
			newCONSTSUB(gv_stashpvn(pkg, pkg_len, GV_ADD),
				vname_pv, val_copy);
		}
		if (!is_str)
		next_ival = is_flags ? next_ival << 1 : next_ival + 1;
		SvREFCNT_dec(resolved);
	}
	return d;
}

static void merge_enum_exports(pTHX_ const char *pkg) {
	SV *buf = sv_newmortal();
	AV *pending, *exp, *exp_ok;
	I32 j;

	sv_setpvf(buf, "%s::_ENUM_EXPORTS", pkg);
	pending = get_av(SvPV_nolen(buf), 0);
	if (!pending || av_len(pending) < 0) return;

	sv_setpvf(buf, "%s::EXPORT", pkg);
	exp = get_av(SvPV_nolen(buf), GV_ADD);

	sv_setpvf(buf, "%s::EXPORT_OK", pkg);
	exp_ok = get_av(SvPV_nolen(buf), GV_ADD);

	for (j = 0; j <= av_len(pending); j++) {
		SV **n = av_fetch(pending, j, 0);
		if (n) {
			av_push(exp,    newSVsv(*n));
			av_push(exp_ok, newSVsv(*n));
		}
	}
	av_clear(pending);
}

XS_INTERNAL(xs_enum_pkg_import) {
	dXSARGS;
	const char *pkg;
	CV *exp_import;
	I32 j;

	if (items < 1) croak("Usage: PKG->import(...)");
	pkg = SvPV_nolen(ST(0));

	merge_enum_exports(aTHX_ pkg);

	exp_import = get_cv("Exporter::import", 0);
	if (!exp_import) {
		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Exporter"), NULL);
		exp_import = get_cv("Exporter::import", 0);
	}
	if (!exp_import) croak("Cannot find Exporter::import");

	{
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		for (j = 0; j < items; j++) {
			XPUSHs(ST(j));
		}
		PUTBACK;
		call_sv((SV*)exp_import, G_VOID | G_DISCARD);
		FREETMPS;
		LEAVE;
	}

	XSRETURN_EMPTY;
}

static void setup_exports(pTHX_ const char *pkg, STRLEN pkg_len, AV *names, SV *enum_name) {
	SV *buf = sv_newmortal();
	AV *pending;
	AV *tag_list;
	HV *export_tags;
	I32 j;

	/* Store exports for deferred merge at import() time */
	sv_setpvf(buf, "%s::_ENUM_EXPORTS", pkg);
	pending = get_av(SvPV_nolen(buf), GV_ADD);

	for (j = 0; j <= av_len(names); j++) {
		SV **n = av_fetch(names, j, 0);
		if (n) av_push(pending, newSVsv(*n));
	}
	if (enum_name) av_push(pending, newSVsv(enum_name));

	/* Populate %EXPORT_TAGS with enum-name tag */
	if (enum_name) {
		sv_setpvf(buf, "%s::EXPORT_TAGS", pkg);
		export_tags = get_hv(SvPV_nolen(buf), GV_ADD);

		tag_list = newAV();
		for (j = 0; j <= av_len(names); j++) {
			SV **n = av_fetch(names, j, 0);
			if (n) av_push(tag_list, newSVsv(*n));
		}
		av_push(tag_list, newSVsv(enum_name));
		(void)hv_store_ent(export_tags, enum_name, newRV_noinc((SV*)tag_list), 0);
	}

	/* Install custom import if not already present */
	sv_setpvf(buf, "%s::import", pkg);
	if (!get_cv(SvPV_nolen(buf), 0)) {
		newXS(SvPV_nolen(buf), xs_enum_pkg_import, __FILE__);
	}
}

static void install_meta(pTHX_ SV *name_sv, const char *pkg, STRLEN pkg_len, EnumData *d, int is_flags, int is_type) {
	dSP;
	SV *meta;
	const char *ename = SvPV_nolen(name_sv);
	EnumTypeData *etd = NULL;

	/* Build type data BEFORE passing HVs to meta (newRV_noinc steals refcounts) */
	if (is_type) {
		HE *he;
		I32 j;

		Newxz(etd, 1, EnumTypeData);
		etd->val2name = newHV();
		etd->lc_name2val = newHV();

		/* Copy val2name from the EnumData */
		hv_iterinit(d->val2name);
		while ((he = hv_iternext(d->val2name))) {
			STRLEN klen;
			const char *key = HePV(he, klen);
			SV *val = HeVAL(he);
			hv_store(etd->val2name, key, klen, newSVsv(val), 0);
		}

		/* Build lc(name) -> value for case-insensitive coercion */
		hv_iterinit(d->name2val);
		while ((he = hv_iternext(d->name2val))) {
			STRLEN klen;
			const char *key = HePV(he, klen);
			SV *val = HeVAL(he);
			char *lc_key;
			STRLEN k;
			Newx(lc_key, klen + 1, char);
			for (k = 0; k < klen; k++) lc_key[k] = toLOWER(key[k]);
			lc_key[klen] = '\0';
			hv_store(etd->lc_name2val, lc_key, klen, newSVsv(val), 0);
			Safefree(lc_key);
		}

		/* Compute flags mask or -1 */
		if (is_flags) {
			IV mask = 0;
			for (j = 0; j <= av_len(d->values); j++) {
				SV **svp = av_fetch(d->values, j, 0);
				if (svp) mask |= SvIV(*svp);
			}
			etd->flags_mask = mask;
		} else {
			etd->flags_mask = -1;
		}
	}

	/* Build meta object (consumes d->names, d->values, d->name2val, d->val2name) */
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	mXPUSHs(newSVpvs("Enum::Declare::Meta"));
	mXPUSHs(newSVpvs("enum_name"));   mXPUSHs(newSVsv(name_sv));
	mXPUSHs(newSVpvs("package"));     mXPUSHs(newSVpvn(pkg, pkg_len));
	mXPUSHs(newSVpvs("names"));       mXPUSHs(newRV_noinc((SV*)d->names));
	mXPUSHs(newSVpvs("values"));      mXPUSHs(newRV_noinc((SV*)d->values));
	mXPUSHs(newSVpvs("name2val"));    mXPUSHs(newRV_noinc((SV*)d->name2val));
	mXPUSHs(newSVpvs("val2name"));    mXPUSHs(newRV_noinc((SV*)d->val2name));
	PUTBACK;
	call_method("new", G_SCALAR);
	SPAGAIN;
	meta = SvREFCNT_inc(POPs);
	PUTBACK;
	FREETMPS;
	LEAVE;
	{
		HV *registry = get_hv("Enum::Declare::_registry", GV_ADD);
		SV *key = newSVpvf("%s::%s", pkg, ename);
		hv_store_ent(registry, key, newSVsv(meta), 0);
		SvREFCNT_dec(key);
	}
	newCONSTSUB(gv_stashpvn(pkg, pkg_len, GV_ADD), ename, meta);

	/* Register as Object::Proto type via C-level API (only with :Type) */
	if (is_type && etd) {
		object_register_type_xs_ex(aTHX_ ename,
			enum_type_check, enum_type_coerce, (void*)etd);
	}
}

XS_INTERNAL(xs_enum_stub) {
	dXSARGS;
	PERL_UNUSED_VAR(items);
	XSRETURN_EMPTY;
}

static OP *enum_parser_callback(pTHX_ GV *namegv, SV *psobj, U32 *flagsp) {
	SV *name_sv;
	SV *attr_sv;
	AV *variants;
	const char *pkg;
	STRLEN pkg_len;
	EnumData data;
	int is_flags;
	PERL_UNUSED_ARG(namegv);
	PERL_UNUSED_ARG(psobj);
	lex_read_space(0);
	name_sv = lex_read_ident(aTHX);
	if (!name_sv) croak("Expected enum name");
	lex_read_space(0);
	attr_sv = lex_read_attrs(aTHX);
	variants = lex_read_variants(aTHX);
	pkg     = HvNAME(PL_curstash);
	pkg_len = strlen(pkg);
	is_flags = has_attr(aTHX_ attr_sv, "Flags");
	data = build_enum_data(aTHX_ variants,
		has_attr(aTHX_ attr_sv, "Str"),
		is_flags,
		pkg, pkg_len
	);
	if (has_attr(aTHX_ attr_sv, "Export"))
	setup_exports(aTHX_ pkg, pkg_len, data.names, name_sv);
	install_meta(aTHX_ name_sv, pkg, pkg_len, &data, is_flags,
		has_attr(aTHX_ attr_sv, "Type"));
	if (attr_sv != &PL_sv_undef) SvREFCNT_dec(attr_sv);
	SvREFCNT_dec(name_sv);
	SvREFCNT_dec((SV*)variants);
	*flagsp |= CALLPARSER_STATEMENT;
	return newNULLLIST();
}

MODULE = Enum::Declare  PACKAGE = Enum::Declare
PROTOTYPES: DISABLE

void import(...)
	CODE: 
	{
		const char *caller = CopSTASHPV(PL_curcop);
		SV *fqn = newSVpvf("%s::enum", caller);
		CV *cv = newXS(SvPV_nolen(fqn), xs_enum_stub, __FILE__);
		cv_set_call_parser(cv, enum_parser_callback, &PL_sv_undef);
		SvREFCNT_dec(fqn);
	}
