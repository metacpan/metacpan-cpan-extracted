#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "xs_jit.h"

static HV *jit_compiled = NULL;
static int jit_available = -1;
static int callback_counter = 0;

static int _jit_available(pTHX) {
	if (jit_available >= 0) return jit_available;
	HV *env = get_hv("ENV", 0);
	if (env) {
		SV **no_jit_svp = hv_fetch(env, "MEOW_NO_JIT", 11, 0);
		if (no_jit_svp && SvTRUE(*no_jit_svp)) {
			jit_available = 0;
			return 0;
		}
	}
	/* XS::JIT is always available since we're linked against it */
	jit_available = 1;
	return jit_available;
}

static SV *_extract_type_name(pTHX_ SV *isa) {
	if (!isa || !SvOK(isa) || !SvROK(isa)) {
		return newSVpvn("", 0);
	}
	SV *rv = SvRV(isa);
	if (SvOBJECT(rv) && SvTYPE(rv) == SVt_PVHV) {
		HV *stash = SvSTASH(rv);
		if (stash && strEQ(HvNAME(stash), "Basic::Types::XS")) {
			SV **name_svp = hv_fetch((HV*)rv, "name", 4, 0);
			if (name_svp && SvOK(*name_svp)) {
				return newSVsv(*name_svp);
			}
		}
	}
	if (SvOBJECT(rv)) {
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(isa);
		PUTBACK;
		int count = call_method("name", G_SCALAR | G_EVAL);
		SPAGAIN;
		if (count == 1 && !SvTRUE(ERRSV)) {
			SV *result = POPs;
			if (SvOK(result)) {
				SV *ret = newSVsv(result);
				PUTBACK;
				FREETMPS;
				LEAVE;
				return ret;
			}
		}
		PUTBACK;
		FREETMPS;
		LEAVE;
	}
	return newSVpvn("", 0);
}

static HV *compiler_compiled = NULL;
static int func_counter = 0;

static void _safe_name(const char *name, char *out, size_t outlen) {
	size_t i, j = 0;
	for (i = 0; name[i] && j < outlen - 1; i++) {
		char c = name[i];
		if (c == ':') {
			out[j++] = '_';
			if (name[i+1] == ':') i++;
		} else if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
		           (c >= '0' && c <= '9') || c == '_') {
			out[j++] = c;
		} else {
			out[j++] = '_';
		}
	}
	out[j] = '\0';
}

static const char *_get_type_check(const char *type_name, const char *var_name) {
	static char buf[512];
	if (!type_name || !*type_name) return NULL;
	if (strcmp(type_name, "Str") == 0) {
		snprintf(buf, sizeof(buf), "!SvROK(%s)", var_name);
	} else if (strcmp(type_name, "Num") == 0) {
		snprintf(buf, sizeof(buf), "looks_like_number(%s)", var_name);
	} else if (strcmp(type_name, "Int") == 0) {
		snprintf(buf, sizeof(buf), "(SvIOK(%s) || (SvPOK(%s) && _is_int_string(SvPV_nolen(%s))))", var_name, var_name, var_name);
	} else if (strcmp(type_name, "Bool") == 0) {
		snprintf(buf, sizeof(buf), "!SvROK(%s)", var_name);
	} else if (strcmp(type_name, "ArrayRef") == 0) {
		snprintf(buf, sizeof(buf), "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVAV)", var_name, var_name);
	} else if (strcmp(type_name, "HashRef") == 0) {
		snprintf(buf, sizeof(buf), "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVHV)", var_name, var_name);
	} else if (strcmp(type_name, "CodeRef") == 0) {
		snprintf(buf, sizeof(buf), "(SvROK(%s) && SvTYPE(SvRV(%s)) == SVt_PVCV)", var_name, var_name);
	} else if (strcmp(type_name, "Object") == 0) {
		snprintf(buf, sizeof(buf), "(SvROK(%s) && SvOBJECT(SvRV(%s)))", var_name, var_name);
	} else if (strcmp(type_name, "Defined") == 0) {
		snprintf(buf, sizeof(buf), "SvOK(%s)", var_name);
	} else if (strcmp(type_name, "Any") == 0) {
		return "1";
	} else {
		return NULL;
	}
	return buf;
}

static char *_store_callback(pTHX_ SV *callback) {
	HV *perl_callbacks = get_hv("Meow::JIT::CALLBACKS", GV_ADD);
	char buf[64];
	snprintf(buf, sizeof(buf), "cb_%d", callback_counter++);
	SvREFCNT_inc(callback);
	hv_store(perl_callbacks, buf, strlen(buf), callback, 0);
	return strdup(buf);
}

static int _generate_default_code(pTHX_ SV *default_val, char *out, size_t outlen, char **callback_key_out) {
	*callback_key_out = NULL;
	if (!default_val || !SvOK(default_val)) {
		strncpy(out, "&PL_sv_undef", outlen);
		return 0;
	}
	if (!SvROK(default_val)) {
		if (SvIOK(default_val)) {
			snprintf(out, outlen, "sv_2mortal(newSViv(%ld))", (long)SvIV(default_val));
		} else if (SvNOK(default_val)) {
			snprintf(out, outlen, "sv_2mortal(newSVnv(%g))", SvNV(default_val));
		} else if (SvPOK(default_val)) {
			STRLEN len;
			const char *pv = SvPV(default_val, len);
			int is_int = 1, is_num = 1;
			size_t i;
			for (i = 0; i < len; i++) {
				if (pv[i] == '-' && i == 0) continue;
				if (pv[i] == '.' && is_int) { is_int = 0; continue; }
				if (pv[i] < '0' || pv[i] > '9') { is_int = 0; is_num = 0; break; }
			}
			if (is_int && len > 0) {
				snprintf(out, outlen, "sv_2mortal(newSViv(%s))", pv);
			} else if (is_num && len > 0) {
				snprintf(out, outlen, "sv_2mortal(newSVnv(%s))", pv);
			} else {
				snprintf(out, outlen, "sv_2mortal(newSVpvn(\"%s\", %lu))", pv, (unsigned long)len);
			}
		} else {
			strncpy(out, "&PL_sv_undef", outlen);
		}
		return 0;
	} else {
		SV *rv = SvRV(default_val);
		if (SvTYPE(rv) == SVt_PVAV && av_len((AV*)rv) < 0) {
			strncpy(out, "newRV_noinc((SV*)newAV())", outlen);
			return 0;
		} else if (SvTYPE(rv) == SVt_PVHV && HvKEYS((HV*)rv) == 0) {
			strncpy(out, "newRV_noinc((SV*)newHV())", outlen);
			return 0;
		} else {
			*callback_key_out = _store_callback(aTHX_ default_val);
			strncpy(out, "&PL_sv_undef", outlen);
			return 1;
		}
	}
}

static void _generate_attr_init(pTHX_ SV *code_sv, const char *name, HV *spec) {
	STRLEN name_len = strlen(name);
	SV **default_svp = hv_fetch(spec, "default", 7, 0);
	SV **type_name_svp = hv_fetch(spec, "type_name", 9, 0);
	SV **coerce_svp = hv_fetch(spec, "coerce", 6, 0);
	SV **trigger_svp = hv_fetch(spec, "trigger", 7, 0);
	SV **builder_svp = hv_fetch(spec, "builder", 7, 0);
	SV **isa_svp = hv_fetch(spec, "isa", 3, 0);
	int has_default = default_svp != NULL;
	int has_coderef_default = has_default && SvROK(*default_svp) && SvTYPE(SvRV(*default_svp)) == SVt_PVCV;
	int has_coerce = coerce_svp && SvROK(*coerce_svp);
	int has_trigger = trigger_svp && SvROK(*trigger_svp);
	int has_builder = builder_svp && SvROK(*builder_svp);
	int has_isa = isa_svp && SvOK(*isa_svp) && SvROK(*isa_svp);
	const char *type_name = (type_name_svp && SvOK(*type_name_svp)) ? SvPV_nolen(*type_name_svp) : "";
	char *coerce_key = has_coerce ? _store_callback(aTHX_ *coerce_svp) : NULL;
	char *trigger_key = has_trigger ? _store_callback(aTHX_ *trigger_svp) : NULL;
	char *isa_key = has_isa ? _store_callback(aTHX_ *isa_svp) : NULL;
	sv_catpvf(code_sv, "    {\n");
	sv_catpvf(code_sv, "        SV** %s_valp = args ? hv_fetch(args, \"%s\", %lu, 0) : NULL;\n", name, name, (unsigned long)name_len);
	sv_catpvf(code_sv, "        SV* %s_val;\n", name);
	sv_catpvf(code_sv, "        if (%s_valp && SvOK(*%s_valp)) {\n", name, name);
	sv_catpvf(code_sv, "            %s_val = *%s_valp;\n", name, name);
	sv_catpvf(code_sv, "        }\n");
	if (has_default) {
		sv_catpvf(code_sv, "        else {\n");
		if (has_coderef_default) {
			char *default_key = _store_callback(aTHX_ *default_svp);
			sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
			sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", default_key, (unsigned long)strlen(default_key));
			sv_catpvf(code_sv, "            if (cb_svp) {\n");
			sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(class_sv); PUTBACK;\n");
			sv_catpvf(code_sv, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
			sv_catpvf(code_sv, "                %s_val = POPs; PUTBACK;\n", name);
			sv_catpvf(code_sv, "            } else { %s_val = &PL_sv_undef; }\n", name);
			free(default_key);
		} else {
			char default_code[256];
			char *complex_default_key = NULL;
			int is_complex = _generate_default_code(aTHX_ *default_svp, default_code, sizeof(default_code), &complex_default_key);
			if (is_complex && complex_default_key) {
				sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
				sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", complex_default_key, (unsigned long)strlen(complex_default_key));
				sv_catpvf(code_sv, "            if (cb_svp) {\n");
				sv_catpvf(code_sv, "                %s_val = newSVsv(*cb_svp);\n", name);
				sv_catpvf(code_sv, "            } else { %s_val = &PL_sv_undef; }\n", name);
				free(complex_default_key);
			} else {
				sv_catpvf(code_sv, "            %s_val = %s;\n", name, default_code);
			}
		}
		sv_catpvf(code_sv, "        }\n");
	} else {
		sv_catpvf(code_sv, "        else {\n");
		sv_catpvf(code_sv, "            %s_val = &PL_sv_undef;\n", name);
		sv_catpvf(code_sv, "        }\n");
	}
	if (has_coerce) {
		sv_catpvf(code_sv, "        if (SvOK(%s_val)) {\n", name);
		sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", coerce_key, (unsigned long)strlen(coerce_key));
		sv_catpvf(code_sv, "            if (cb_svp) {\n");
		sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(%s_val); PUTBACK;\n", name);
		sv_catpvf(code_sv, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
		sv_catpvf(code_sv, "                %s_val = POPs; PUTBACK;\n", name);
		sv_catpvf(code_sv, "            }\n");
		sv_catpvf(code_sv, "        }\n");
	}
	if (type_name && *type_name) {
		char var_full[256];
		snprintf(var_full, sizeof(var_full), "%s_val", name);
		const char *type_check = _get_type_check(type_name, var_full);
		if (type_check) {
			sv_catpvf(code_sv, "        if (SvOK(%s_val) && !(%s)) {\n", name, type_check);
			sv_catpvf(code_sv, "            croak(\"value did not pass type constraint \\\"%s\\\"\");\n", type_name);
			sv_catpvf(code_sv, "        }\n");
		} else if (has_isa) {
			sv_catpvf(code_sv, "        if (SvOK(%s_val)) {\n", name);
			sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
			sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", isa_key, (unsigned long)strlen(isa_key));
			sv_catpvf(code_sv, "            if (cb_svp) {\n");
			sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(%s_val); PUTBACK;\n", name);
			sv_catpvf(code_sv, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
			sv_catpvf(code_sv, "                %s_val = POPs; PUTBACK;\n", name);
			sv_catpvf(code_sv, "            }\n");
			sv_catpvf(code_sv, "        }\n");
		}
	} else if (has_isa) {
		sv_catpvf(code_sv, "        if (SvOK(%s_val)) {\n", name);
		sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", isa_key, (unsigned long)strlen(isa_key));
		sv_catpvf(code_sv, "            if (cb_svp) {\n");
		sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(%s_val); PUTBACK;\n", name);
		sv_catpvf(code_sv, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
		sv_catpvf(code_sv, "                %s_val = POPs; PUTBACK;\n", name);
		sv_catpvf(code_sv, "            }\n");
		sv_catpvf(code_sv, "        }\n");
	}
	sv_catpvf(code_sv, "        if (SvOK(%s_val)) {\n", name);
	sv_catpvf(code_sv, "            SvREFCNT_inc(%s_val);\n", name);
	sv_catpvf(code_sv, "            hv_store(self_hv, \"%s\", %lu, %s_val, 0);\n", name, (unsigned long)name_len, name);
	sv_catpvf(code_sv, "        }\n");
	if (has_trigger) {
		sv_catpvf(code_sv, "        if (SvOK(%s_val)) {\n", name);
		sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", trigger_key, (unsigned long)strlen(trigger_key));
		sv_catpvf(code_sv, "            if (cb_svp) {\n");
		sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(self); XPUSHs(%s_val); PUTBACK;\n", name);
		sv_catpvf(code_sv, "                call_sv(*cb_svp, G_DISCARD); SPAGAIN; PUTBACK;\n");
		sv_catpvf(code_sv, "            }\n");
		sv_catpvf(code_sv, "        }\n");
	}
	sv_catpvf(code_sv, "    }\n\n");
}

static void _generate_builder_pass(pTHX_ SV *code_sv, const char *name, HV *spec) {
	STRLEN name_len = strlen(name);
	SV **builder_svp = hv_fetch(spec, "builder", 7, 0);
	SV **coerce_svp = hv_fetch(spec, "coerce", 6, 0);
	SV **trigger_svp = hv_fetch(spec, "trigger", 7, 0);
	SV **isa_svp = hv_fetch(spec, "isa", 3, 0);
	SV **type_name_svp = hv_fetch(spec, "type_name", 9, 0);
	int has_builder = builder_svp && SvROK(*builder_svp);
	if (!has_builder) return;
	int has_coerce = coerce_svp && SvROK(*coerce_svp);
	int has_trigger = trigger_svp && SvROK(*trigger_svp);
	int has_isa = isa_svp && SvOK(*isa_svp) && SvROK(*isa_svp);
	const char *type_name = (type_name_svp && SvOK(*type_name_svp)) ? SvPV_nolen(*type_name_svp) : "";
	char *builder_key = _store_callback(aTHX_ *builder_svp);
	char *coerce_key = has_coerce ? _store_callback(aTHX_ *coerce_svp) : NULL;
	char *trigger_key = has_trigger ? _store_callback(aTHX_ *trigger_svp) : NULL;
	char *isa_key = has_isa ? _store_callback(aTHX_ *isa_svp) : NULL;
	sv_catpvf(code_sv, "    {\n");
	sv_catpvf(code_sv, "        SV** %s_valp = hv_fetch(self_hv, \"%s\", %lu, 0);\n", name, name, (unsigned long)name_len);
	sv_catpvf(code_sv, "        if (!%s_valp || !SvOK(*%s_valp)) {\n", name, name);
	sv_catpvf(code_sv, "            SV* %s_val;\n", name);
	sv_catpvf(code_sv, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
	sv_catpvf(code_sv, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", builder_key, (unsigned long)strlen(builder_key));
	sv_catpvf(code_sv, "            if (cb_svp) {\n");
	sv_catpvf(code_sv, "                dSP; PUSHMARK(SP); XPUSHs(self); PUTBACK;\n");
	sv_catpvf(code_sv, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
	sv_catpvf(code_sv, "                %s_val = POPs; PUTBACK;\n", name);
	sv_catpvf(code_sv, "            } else { %s_val = &PL_sv_undef; }\n", name);
	if (has_coerce) {
		sv_catpvf(code_sv, "            if (SvOK(%s_val)) {\n", name);
		sv_catpvf(code_sv, "                cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", coerce_key, (unsigned long)strlen(coerce_key));
		sv_catpvf(code_sv, "                if (cb_svp) {\n");
		sv_catpvf(code_sv, "                    dSP; PUSHMARK(SP); XPUSHs(%s_val); PUTBACK;\n", name);
		sv_catpvf(code_sv, "                    call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
		sv_catpvf(code_sv, "                    %s_val = POPs; PUTBACK;\n", name);
		sv_catpvf(code_sv, "                }\n");
		sv_catpvf(code_sv, "            }\n");
	}
	if (type_name && *type_name) {
		char var_full[256];
		snprintf(var_full, sizeof(var_full), "%s_val", name);
		const char *type_check = _get_type_check(type_name, var_full);
		if (type_check) {
			sv_catpvf(code_sv, "            if (SvOK(%s_val) && !(%s)) {\n", name, type_check);
			sv_catpvf(code_sv, "                croak(\"value did not pass type constraint \\\"%s\\\"\");\n", type_name);
			sv_catpvf(code_sv, "            }\n");
		} else if (has_isa) {
			sv_catpvf(code_sv, "            if (SvOK(%s_val)) {\n", name);
			sv_catpvf(code_sv, "                cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", isa_key, (unsigned long)strlen(isa_key));
			sv_catpvf(code_sv, "                if (cb_svp) {\n");
			sv_catpvf(code_sv, "                    dSP; PUSHMARK(SP); XPUSHs(%s_val); PUTBACK;\n", name);
			sv_catpvf(code_sv, "                    call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
			sv_catpvf(code_sv, "                    %s_val = POPs; PUTBACK;\n", name);
			sv_catpvf(code_sv, "                }\n");
			sv_catpvf(code_sv, "            }\n");
		}
	}
	sv_catpvf(code_sv, "            if (SvOK(%s_val)) {\n", name);
	sv_catpvf(code_sv, "                SvREFCNT_inc(%s_val);\n", name);
	sv_catpvf(code_sv, "                hv_store(self_hv, \"%s\", %lu, %s_val, 0);\n", name, (unsigned long)name_len, name);
	sv_catpvf(code_sv, "            }\n");
	if (has_trigger) {
		sv_catpvf(code_sv, "            if (SvOK(%s_val)) {\n", name);
		sv_catpvf(code_sv, "                cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", trigger_key, (unsigned long)strlen(trigger_key));
		sv_catpvf(code_sv, "                if (cb_svp) {\n");
		sv_catpvf(code_sv, "                    dSP; PUSHMARK(SP); XPUSHs(self); XPUSHs(%s_val); PUTBACK;\n", name);
		sv_catpvf(code_sv, "                    call_sv(*cb_svp, G_DISCARD); SPAGAIN; PUTBACK;\n");
		sv_catpvf(code_sv, "                }\n");
		sv_catpvf(code_sv, "            }\n");
	}
	sv_catpvf(code_sv, "        }\n");
	sv_catpvf(code_sv, "    }\n\n");
}

static SV *_generate_constructor(pTHX_ const char *package, const char *prefix, HV *attrs) {
	SV *code = newSVpvn("", 0);
	char func_name[256];
	snprintf(func_name, sizeof(func_name), "%s_new", prefix);
	sv_catpvf(code, "XS_EUPXS(%s) {\n", func_name);
	sv_catpvf(code, "    dVAR; dXSARGS;\n");
	sv_catpvf(code, "    PERL_UNUSED_VAR(cv);\n");
	sv_catpvf(code, "    SV* class_sv = ST(0);\n");
	sv_catpvf(code, "    const char* classname = SvPV_nolen(class_sv);\n");
	sv_catpvf(code, "    HV* self_hv = newHV();\n");
	sv_catpvf(code, "    SV* self = sv_bless(newRV_noinc((SV*)self_hv), gv_stashpv(classname, GV_ADD));\n");
	sv_catpvf(code, "    HV* args = NULL;\n");
	sv_catpvf(code, "    int free_args = 0;\n");
	sv_catpvf(code, "    if (items > 1) {\n");
	sv_catpvf(code, "        if (items == 2 && SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVHV) {\n");
	sv_catpvf(code, "            args = (HV*)SvRV(ST(1));\n");
	sv_catpvf(code, "        } else {\n");
	sv_catpvf(code, "            args = newHV();\n");
	sv_catpvf(code, "            free_args = 1;\n");
	sv_catpvf(code, "            int i;\n");
	sv_catpvf(code, "            for (i = 1; i < items; i += 2) {\n");
	sv_catpvf(code, "                SV* val = ST(i + 1);\n");
	sv_catpvf(code, "                SvREFCNT_inc(val);\n");
	sv_catpvf(code, "                hv_store_ent(args, ST(i), val, 0);\n");
	sv_catpvf(code, "            }\n");
	sv_catpvf(code, "        }\n");
	sv_catpvf(code, "    }\n");
	HE *entry;
	hv_iterinit(attrs);
	while ((entry = hv_iternext(attrs))) {
		STRLEN klen;
		char *attr_name = HePV(entry, klen);
		SV *attr_spec_sv = hv_iterval(attrs, entry);
		if (SvROK(attr_spec_sv) && SvTYPE(SvRV(attr_spec_sv)) == SVt_PVHV) {
			_generate_attr_init(aTHX_ code, attr_name, (HV*)SvRV(attr_spec_sv));
		}
	}
	hv_iterinit(attrs);
	while ((entry = hv_iternext(attrs))) {
		STRLEN klen;
		char *attr_name = HePV(entry, klen);
		SV *attr_spec_sv = hv_iterval(attrs, entry);
		if (SvROK(attr_spec_sv) && SvTYPE(SvRV(attr_spec_sv)) == SVt_PVHV) {
			_generate_builder_pass(aTHX_ code, attr_name, (HV*)SvRV(attr_spec_sv));
		}
	}
	sv_catpvf(code, "    if (free_args) {\n");
	sv_catpvf(code, "        SvREFCNT_dec((SV*)args);\n");
	sv_catpvf(code, "    }\n");
	sv_catpvf(code, "    ST(0) = sv_2mortal(self);\n");
	sv_catpvf(code, "    XSRETURN(1);\n");
	sv_catpvf(code, "}\n");
	return code;
}

static SV *_generate_ro_accessor(pTHX_ const char *prefix, const char *name) {
	SV *code = newSVpvn("", 0);
	STRLEN name_len = strlen(name);
	char func_name[256];
	snprintf(func_name, sizeof(func_name), "%s_%s", prefix, name);
	sv_catpvf(code, "XS_EUPXS(%s) {\n", func_name);
	sv_catpvf(code, "    dVAR; dXSARGS;\n");
	sv_catpvf(code, "    PERL_UNUSED_VAR(cv);\n");
	sv_catpvf(code, "    if (items > 1) {\n");
	sv_catpvf(code, "        croak(\"Read only attributes cannot be set\");\n");
	sv_catpvf(code, "    }\n");
	sv_catpvf(code, "    SV* self = ST(0);\n");
	sv_catpvf(code, "    HV* hv = (HV*)SvRV(self);\n");
	sv_catpvf(code, "    SV** valp = hv_fetch(hv, \"%s\", %lu, 0);\n", name, (unsigned long)name_len);
	sv_catpvf(code, "    ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;\n");
	sv_catpvf(code, "    XSRETURN(1);\n");
	sv_catpvf(code, "}\n");
	return code;
}

static SV *_generate_rw_accessor(pTHX_ const char *prefix, const char *name, HV *spec) {
	SV *code = newSVpvn("", 0);
	STRLEN name_len = strlen(name);
	char func_name[256];
	snprintf(func_name, sizeof(func_name), "%s_%s", prefix, name);
	SV **type_name_svp = hv_fetch(spec, "type_name", 9, 0);
	SV **coerce_svp = hv_fetch(spec, "coerce", 6, 0);
	SV **trigger_svp = hv_fetch(spec, "trigger", 7, 0);
	SV **isa_svp = hv_fetch(spec, "isa", 3, 0);
	const char *type_name = (type_name_svp && SvOK(*type_name_svp)) ? SvPV_nolen(*type_name_svp) : "";
	int has_coerce = coerce_svp && SvROK(*coerce_svp);
	int has_trigger = trigger_svp && SvROK(*trigger_svp);
	int has_isa = isa_svp && SvOK(*isa_svp) && SvROK(*isa_svp);
	char *coerce_key = has_coerce ? _store_callback(aTHX_ *coerce_svp) : NULL;
	char *trigger_key = has_trigger ? _store_callback(aTHX_ *trigger_svp) : NULL;
	char *isa_key = has_isa ? _store_callback(aTHX_ *isa_svp) : NULL;
	sv_catpvf(code, "XS_EUPXS(%s) {\n", func_name);
	sv_catpvf(code, "    dVAR; dXSARGS;\n");
	sv_catpvf(code, "    PERL_UNUSED_VAR(cv);\n");
	sv_catpvf(code, "    SV* self = ST(0);\n");
	sv_catpvf(code, "    HV* hv = (HV*)SvRV(self);\n");
	sv_catpvf(code, "    if (items > 1) {\n");
	sv_catpvf(code, "        SV* val = ST(1);\n");
	if (has_coerce) {
		sv_catpvf(code, "        {\n");
		sv_catpvf(code, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", coerce_key, (unsigned long)strlen(coerce_key));
		sv_catpvf(code, "            if (cb_svp) {\n");
		sv_catpvf(code, "                dSP; PUSHMARK(SP); XPUSHs(val); PUTBACK;\n");
		sv_catpvf(code, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
		sv_catpvf(code, "                val = POPs; PUTBACK;\n");
		sv_catpvf(code, "            }\n");
		sv_catpvf(code, "        }\n");
	}
	if (type_name && *type_name) {
		const char *type_check = _get_type_check(type_name, "val");
		if (type_check) {
			sv_catpvf(code, "        if (SvOK(val) && !(%s)) {\n", type_check);
			sv_catpvf(code, "            croak(\"value did not pass type constraint \\\"%s\\\"\");\n", type_name);
			sv_catpvf(code, "        }\n");
		} else if (has_isa) {
			sv_catpvf(code, "        if (SvOK(val)) {\n");
			sv_catpvf(code, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
			sv_catpvf(code, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", isa_key, (unsigned long)strlen(isa_key));
			sv_catpvf(code, "            if (cb_svp) {\n");
			sv_catpvf(code, "                dSP; PUSHMARK(SP); XPUSHs(val); PUTBACK;\n");
			sv_catpvf(code, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
			sv_catpvf(code, "                val = POPs; PUTBACK;\n");
			sv_catpvf(code, "            }\n");
			sv_catpvf(code, "        }\n");
		}
	} else if (has_isa) {
		sv_catpvf(code, "        if (SvOK(val)) {\n");
		sv_catpvf(code, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", isa_key, (unsigned long)strlen(isa_key));
		sv_catpvf(code, "            if (cb_svp) {\n");
		sv_catpvf(code, "                dSP; PUSHMARK(SP); XPUSHs(val); PUTBACK;\n");
		sv_catpvf(code, "                call_sv(*cb_svp, G_SCALAR); SPAGAIN;\n");
		sv_catpvf(code, "                val = POPs; PUTBACK;\n");
		sv_catpvf(code, "            }\n");
		sv_catpvf(code, "        }\n");
	}
	sv_catpvf(code, "        SvREFCNT_inc(val);\n");
	sv_catpvf(code, "        hv_store(hv, \"%s\", %lu, val, 0);\n", name, (unsigned long)name_len);
	if (has_trigger) {
		sv_catpvf(code, "        {\n");
		sv_catpvf(code, "            HV* cbs = get_hv(\"Meow::JIT::CALLBACKS\", 0);\n");
		sv_catpvf(code, "            SV** cb_svp = hv_fetch(cbs, \"%s\", %lu, 0);\n", trigger_key, (unsigned long)strlen(trigger_key));
		sv_catpvf(code, "            if (cb_svp) {\n");
		sv_catpvf(code, "                dSP; PUSHMARK(SP); XPUSHs(self); XPUSHs(val); PUTBACK;\n");
		sv_catpvf(code, "                call_sv(*cb_svp, G_DISCARD); SPAGAIN; PUTBACK;\n");
		sv_catpvf(code, "            }\n");
		sv_catpvf(code, "        }\n");
	}
	sv_catpvf(code, "    }\n");
	sv_catpvf(code, "    SV** valp = hv_fetch(hv, \"%s\", %lu, 0);\n", name, (unsigned long)name_len);
	sv_catpvf(code, "    ST(0) = (valp && *valp) ? *valp : &PL_sv_undef;\n");
	sv_catpvf(code, "    XSRETURN(1);\n");
	sv_catpvf(code, "}\n");
	return code;
}

static SV *_generate_accessors(pTHX_ const char *prefix, HV *attrs) {
	SV *code = newSVpvn("", 0);
	HE *entry;
	hv_iterinit(attrs);
	while ((entry = hv_iternext(attrs))) {
		STRLEN klen;
		char *name = HePV(entry, klen);
		SV *spec_sv = hv_iterval(attrs, entry);
		if (!SvROK(spec_sv) || SvTYPE(SvRV(spec_sv)) != SVt_PVHV) continue;
		HV *spec = (HV*)SvRV(spec_sv);
		SV **is_ro_svp = hv_fetch(spec, "is_ro", 5, 0);
		int is_ro = is_ro_svp && SvTRUE(*is_ro_svp);
		SV *accessor;
		if (is_ro) {
			accessor = _generate_ro_accessor(aTHX_ prefix, name);
		} else {
			accessor = _generate_rw_accessor(aTHX_ prefix, name, spec);
		}
		sv_catsv(code, accessor);
		sv_catpvf(code, "\n");
		SvREFCNT_dec(accessor);
	}
	return code;
}

static SV *_generate_c_code(pTHX_ const char *package, const char *prefix, HV *attrs) {
	SV *code = newSVpvn("", 0);
	sv_catpv(code, "#include \"EXTERN.h\"\n");
	sv_catpv(code, "#include \"perl.h\"\n");
	sv_catpv(code, "#include \"XSUB.h\"\n\n");
	sv_catpv(code, "static int _is_int_string(const char *s) {\n");
	sv_catpv(code, "    if (!s || !*s) return 0;\n");
	sv_catpv(code, "    if (*s == '-') s++;\n");
	sv_catpv(code, "    if (!*s) return 0;\n");
	sv_catpv(code, "    while (*s) {\n");
	sv_catpv(code, "        if (*s < '0' || *s > '9') return 0;\n");
	sv_catpv(code, "        s++;\n");
	sv_catpv(code, "    }\n");
	sv_catpv(code, "    return 1;\n");
	sv_catpv(code, "}\n\n");
	SV *constructor = _generate_constructor(aTHX_ package, prefix, attrs);
	sv_catsv(code, constructor);
	sv_catpv(code, "\n");
	SvREFCNT_dec(constructor);
	SV *accessors = _generate_accessors(aTHX_ prefix, attrs);
	sv_catsv(code, accessors);
	SvREFCNT_dec(accessors);
	return code;
}

static void _install_compiled_functions(pTHX_ const char *package, const char *prefix, HV *attrs) {
	char source_func[512];
	char target_func[512];
	snprintf(source_func, sizeof(source_func), "%s::%s_new", package, prefix);
	snprintf(target_func, sizeof(target_func), "%s::new", package);
	CV *src_cv = get_cv(source_func, 0);
	if (src_cv) {
		GV *gv = gv_fetchpv(target_func, GV_ADD, SVt_PVCV);
		GvCV_set(gv, src_cv);
		SvREFCNT_inc((SV*)src_cv);
	}
	HE *entry;
	hv_iterinit(attrs);
	while ((entry = hv_iternext(attrs))) {
		STRLEN klen;
		char *name = HePV(entry, klen);
		snprintf(source_func, sizeof(source_func), "%s::%s_%s", package, prefix, name);
		snprintf(target_func, sizeof(target_func), "%s::%s", package, name);
		src_cv = get_cv(source_func, 0);
		if (src_cv) {
			GV *gv = gv_fetchpv(target_func, GV_ADD, SVt_PVCV);
			GvCV_set(gv, src_cv);
			SvREFCNT_inc((SV*)src_cv);
		}
	}
}

static int _compile_jit(pTHX_ const char *package) {
	if (!jit_compiled) {
		jit_compiled = newHV();
	}
	if (hv_exists(jit_compiled, package, strlen(package))) {
		return 1;
	}
	if (!_jit_available(aTHX)) {
		return 0;
	}
	char cv_name[256];
	snprintf(cv_name, sizeof(cv_name), "%s::new", package);
	CV *newcv = get_cv(cv_name, 0);
	if (!newcv) {
		return 0;
	}
	SV *spec = (SV *)CvXSUBANY(newcv).any_ptr;
	if (!spec || !SvROK(spec) || SvTYPE(SvRV(spec)) != SVt_PVHV) {
		return 0;
	}
	HV *spec_hv = (HV*)SvRV(spec);
	if (HvKEYS(spec_hv) == 0) {
		return 0;
	}
	HV *specs_hv = get_hv("Meow::SPECS", GV_ADD);
	hv_store(specs_hv, package, strlen(package), newSVsv(spec), 0);
	HV *attrs = newHV();
	HE *entry;
	hv_iterinit(spec_hv);
	while ((entry = hv_iternext(spec_hv))) {
		STRLEN klen;
		char *key = HePV(entry, klen);
		if (key[0] == '_') continue;
		SV *attr_spec_sv = hv_iterval(spec_hv, entry);
		if (!SvROK(attr_spec_sv) || SvTYPE(SvRV(attr_spec_sv)) != SVt_PVHV) continue;
		HV *attr_spec = (HV*)SvRV(attr_spec_sv);
		HV *compiler_attr = newHV();
		SV **is_ro_svp = hv_fetch(attr_spec, "is_ro", 5, 0);
		int is_ro = (is_ro_svp && SvTRUE(*is_ro_svp)) ? 1 : 0;
		hv_store(compiler_attr, "is_ro", 5, newSViv(is_ro), 0);
		SV **isa_svp = hv_fetch(attr_spec, "isa", 3, 0);
		SV *type_name = isa_svp ? _extract_type_name(aTHX_ *isa_svp) : newSVpvn("", 0);
		hv_store(compiler_attr, "type_name", 9, type_name, 0);
		if (isa_svp && SvOK(*isa_svp)) {
			hv_store(compiler_attr, "isa", 3, newSVsv(*isa_svp), 0);
		}
		int has_default = hv_exists(attr_spec, "default", 7);
		int has_builder = hv_exists(attr_spec, "builder", 7);
		hv_store(compiler_attr, "required", 8, newSViv(!has_default && !has_builder), 0);
		SV **default_svp = hv_fetch(attr_spec, "default", 7, 0);
		if (default_svp) hv_store(compiler_attr, "default", 7, newSVsv(*default_svp), 0);
		SV **coerce_svp = hv_fetch(attr_spec, "coerce", 6, 0);
		if (coerce_svp) hv_store(compiler_attr, "coerce", 6, newSVsv(*coerce_svp), 0);
		SV **trigger_svp = hv_fetch(attr_spec, "trigger", 7, 0);
		if (trigger_svp) hv_store(compiler_attr, "trigger", 7, newSVsv(*trigger_svp), 0);
		SV **builder_svp = hv_fetch(attr_spec, "builder", 7, 0);
		if (builder_svp) hv_store(compiler_attr, "builder", 7, newSVsv(*builder_svp), 0);
		hv_store(attrs, key, klen, newRV_noinc((SV*)compiler_attr), 0);
	}
	if (HvKEYS(attrs) == 0) {
		SvREFCNT_dec((SV*)attrs);
		return 0;
	}
	char safe_pkg[256];
	char prefix[300];
	_safe_name(package, safe_pkg, sizeof(safe_pkg));
	snprintf(prefix, sizeof(prefix), "%s_%d", safe_pkg, func_counter++);
	SV *c_code = _generate_c_code(aTHX_ package, prefix, attrs);
	{
		char jit_name[300];
		snprintf(jit_name, sizeof(jit_name), "Meow::JIT::%s", prefix);

		/* Build function mapping array for XS::JIT */
		int num_attrs = HvKEYS(attrs);
		XS_JIT_Func *funcs = (XS_JIT_Func*)malloc(sizeof(XS_JIT_Func) * (num_attrs + 2));
		int func_idx = 0;

		/* Add constructor */
		char *new_target = (char*)malloc(strlen(package) + 6);
		char *new_source = (char*)malloc(strlen(prefix) + 5);
		sprintf(new_target, "%s::new", package);
		sprintf(new_source, "%s_new", prefix);
		funcs[func_idx].target = new_target;
		funcs[func_idx].source = new_source;
		funcs[func_idx].has_varargs = 0;
		funcs[func_idx].is_xs_native = 1;  /* XS-native function */
		func_idx++;

		/* Add accessors */
		HE *entry;
		hv_iterinit(attrs);
		while ((entry = hv_iternext(attrs))) {
			STRLEN klen;
			char *name = HePV(entry, klen);
			char *target = (char*)malloc(strlen(package) + klen + 3);
			char *source = (char*)malloc(strlen(prefix) + klen + 2);
			sprintf(target, "%s::%s", package, name);
			sprintf(source, "%s_%s", prefix, name);
			funcs[func_idx].target = target;
			funcs[func_idx].source = source;
			funcs[func_idx].has_varargs = 0;
			funcs[func_idx].is_xs_native = 1;  /* XS-native function */
			func_idx++;
		}

		int ok = xs_jit_compile(aTHX_
			SvPV_nolen(c_code),
			jit_name,
			funcs,
			func_idx,
			NULL,  /* default cache dir */
			0      /* don't force */
		);

		/* Free allocated strings */
		int i;
		for (i = 0; i < func_idx; i++) {
			free((void*)funcs[i].target);
			free((void*)funcs[i].source);
		}
		free(funcs);
		SvREFCNT_dec(c_code);

		if (!ok) {
			SvREFCNT_dec((SV*)attrs);
			return 0;
		}
	}
	/* Note: XS::JIT already installs functions via the function mapping */
	SvREFCNT_dec((SV*)attrs);
	hv_store(jit_compiled, package, strlen(package), newSViv(1), 0);
	return 1;
}

static SV * _new(SV *class, HV *hash) {
	dTHX;
	if (SvTYPE(class) != SVt_PV) {
		char *name = HvNAME(SvSTASH(SvRV(class)));
		class = newSVpv(name, strlen(name));
	}
	return sv_bless(newRV_noinc((SV*)hash), gv_stashsv(class, 0));
}

char *substr(const char *input, size_t start, size_t len) {
	dTHX;
	char *ret = (char *)malloc(len - start + 1);
	memcpy(ret, input + start, len - start);
	ret[len - start] = '\0';
	return ret;
}

int find_last(const char *str, const char word) {
	dTHX;
	int lastIndex = -1, i = 0;
	for (i = 0; str[i] != '\0'; i++) {
		if (str[i] == word) {
			lastIndex = i;
		}
	}
	return lastIndex;
}

char *get_ex_method(const char *name) {
	dTHX;
	char *callr = HvNAME((HV*)CopSTASH(PL_curcop));
	STRLEN retlen = strlen(callr);
	size_t ex_len = strlen(name) + 2 + retlen + 1;
	char *ex_out = (char *)malloc(ex_len);
	if (!ex_out) croak("Out of memory in get_ex_method");
	snprintf(ex_out, ex_len, "%s::%s", callr, name);
	return ex_out;
}

char *get_caller(void) {
	dTHX;
	char *callr = HvNAME((HV*)CopSTASH(PL_curcop));
	return callr;
}

void get_class_and_method(SV *cv_name_sv, char **class_out, char **method_out) {
	dTHX;
	STRLEN len;
	char *full = SvPV(cv_name_sv, len);
	int idx = find_last(full, ':');
	if (idx == -1 || idx < 1) {
		*class_out = strdup("");
		*method_out = strdup(full);
		return;
	}
	int sep = idx;
	if (sep > 0 && full[sep-1] == ':') sep--;
	*class_out = substr(full, 0, sep);
	*method_out = substr(full, idx+1, len);
}

void register_attribute(CV *cv, char *name, SV *attr, XSUBADDR_t xsub_addr, int is_ro) {
	dTHX;
	SV *newcv = (SV *)CvXSUBANY(cv).any_ptr;
	SV *spec = (SV *)CvXSUBANY(newcv).any_ptr;
	if (!SvOK(attr) || !SvROK(attr)) {
		HV *n = newHV();
		hv_store(n, "name", 4, newSVpv(name, strlen(name)), 0);
		attr = newRV_noinc((SV*)n);
	} else {
		SV *rv = SvRV(attr);
		if (SvTYPE(rv) != SVt_PVHV || !hv_exists((HV*)rv, "isa", 3)) {
			HV *n = newHV();
			hv_store(n, "name", 4, newSVpv(name, strlen(name)), 0);
			hv_store(n, "isa", 3, newSVsv(attr), 0);
			attr = newRV_noinc((SV*)n);
		} else {
			hv_store((HV*)rv, "name", 4, newSVpv(name, strlen(name)), 0);
		}
	}
	HV *attr_hv = (HV*)SvRV(attr);
	hv_store(attr_hv, "is_ro", 5, newSViv(is_ro), 0);
	HV *spec_hv = (HV*)SvRV(spec);
	hv_store(spec_hv, name, strlen(name), newSVsv(attr), 0);
	if (hv_exists(attr_hv, "builder", 7) || hv_exists(attr_hv, "trigger", 7)) {
		if (!hv_exists(spec_hv, "_needs_second_pass", 18)) {
			hv_store(spec_hv, "_needs_second_pass", 18, newSViv(1), 0);
		}
	}
	char *ex = get_ex_method(name);
	CV *new_attr_cv = newXS(ex, xsub_addr, __FILE__);
	SvREFCNT_inc(attr);
	CvXSUBANY(new_attr_cv).any_ptr = (void *)attr;
	free(ex);
}

static AV *get_avf(const char *fmt, ...) {
	dTHX;
	va_list ap;
	char buf[256];
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	return get_av(buf, GV_ADD);
}

static CV *get_cvf(const char *fmt, ...) {
	dTHX;
	va_list ap;
	char buf[256];
	va_start(ap, fmt);
	vsnprintf(buf, sizeof(buf), fmt, ap);
	va_end(ap);
	return get_cv(buf, GV_ADD);
}

static SV *normalise_attr(SV *attr) {
	dTHX;
	if (!SvOK(attr) || !SvROK(attr)) {
		HV *n = newHV();
		hv_store(n, "isa", 3, &PL_sv_undef, 0);
		attr = newRV_noinc((SV*)n);
	} else {
		SV *rv = SvRV(attr);
		if (SvTYPE(rv) != SVt_PVHV || !hv_exists((HV*)rv, "isa", 3)) {
			HV *n = newHV();
			hv_store(n, "isa", 3, newSVsv(attr), 0);
			attr = newRV_noinc((SV*)n);
		}
	}
	return attr;
}

MODULE = Meow  PACKAGE = Meow
PROTOTYPES: ENABLE

SV *
new(pkg, ...)
	SV *pkg
	CODE:
		SV *spec = (SV *)CvXSUBANY(cv).any_ptr;
		HV *args;
		int i;
		if (items > 2) {
			if ((items - 1) % 2 != 0) {
				croak("Odd number of elements in hash assignment");
			}
			args = newHV();
			for (i = 1; i < items; i += 2) {
				STRLEN retlen;
				char *key = SvPV(ST(i), retlen);
				SV *value = newSVsv(ST(i + 1));
				hv_store(args, key, retlen, value, 0);
			}
		} else {
			if (!SvOK(ST(1))) {
				args = newHV();
			} else if (!SvROK(ST(1)) || SvTYPE(SvRV(ST(1))) != SVt_PVHV) {
				croak("Not a hash assignment");
			} else {
				args = (HV*)SvRV(newSVsv(ST(1)));
			}
		}
		RETVAL = _new(newSVsv(ST(0)), args);
		HV *right = (HV*)SvRV(spec);
		HE *entry;
		(void)hv_iterinit(right);
		while ((entry = hv_iternext(right))) {
			STRLEN retlen;
			char *key = SvPV(hv_iterkeysv(entry), retlen);
			if (retlen == 18 && memcmp(key, "_needs_second_pass", 18) == 0) continue;
			SV **valp = hv_fetch(args, key, retlen, 0);
			SV *value = valp ? *valp : &PL_sv_undef;
			SV *spec_sv = hv_iterval(right, entry);
			if (SvROK(spec_sv) && SvTYPE(SvRV(spec_sv)) == SVt_PVHV) {
				HV *spec_hv = (HV*)SvRV(spec_sv);
				SV **default_svp, **coerce_svp, **isa_svp;
				if (!SvOK(value)) {
					default_svp = hv_fetch(spec_hv, "default", 7, 0);
					if (default_svp) {
						if (SvROK(*default_svp) && SvTYPE(SvRV(*default_svp)) == SVt_PVCV) {
							dSP;
							PUSHMARK(SP);
							XPUSHs(pkg);
							PUTBACK;
							call_sv(*default_svp, G_SCALAR);
							SPAGAIN;
							value = POPs;
							PUTBACK;
						} else {
							value = *default_svp;
							SvREFCNT_inc(value);
						}
					}
				}
				if (SvOK(value)) {
					coerce_svp = hv_fetch(spec_hv, "coerce", 6, 0);
					if (coerce_svp) {
						dSP;
						PUSHMARK(SP);
						XPUSHs(value);
						PUTBACK;
						call_sv(*coerce_svp, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
					}
				}
				if (SvOK(value)) {
					isa_svp = hv_fetch(spec_hv, "isa", 3, 0);
					if (isa_svp && SvOK(*isa_svp)) {
						dSP;
						PUSHMARK(SP);
						XPUSHs(value);
						PUTBACK;
						call_sv(*isa_svp, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
					}
				}
				SvREFCNT_inc(value);
			}
			hv_store(args, key, retlen, value, 0);
		}
		if (hv_exists(right, "_needs_second_pass", 18)) {
			(void)hv_iterinit(right);
			while ((entry = hv_iternext(right))) {
				STRLEN retlen;
				char *key = SvPV(hv_iterkeysv(entry), retlen);
				if (retlen == 18 && memcmp(key, "_needs_second_pass", 18) == 0) continue;
				SV **valp = hv_fetch(args, key, retlen, 0);
				SV *value = valp ? *valp : &PL_sv_undef;
				SV *spec_sv = hv_iterval(right, entry);
				HV *spec_hv = (HV*)SvRV(spec_sv);
				SV **builder_svp, **isa_svp, **trigger_svp;
				if (!SvOK(value)) {
					builder_svp = hv_fetch(spec_hv, "builder", 7, 0);
					if (builder_svp) {
						dSP;
						PUSHMARK(SP);
						XPUSHs(RETVAL);
						PUTBACK;
						call_sv(*builder_svp, G_SCALAR);
						SPAGAIN;
						value = POPs;
						PUTBACK;
						if (SvOK(value)) {
							isa_svp = hv_fetch(spec_hv, "isa", 3, 0);
							if (isa_svp && SvOK(*isa_svp)) {
								dSP;
								PUSHMARK(SP);
								XPUSHs(value);
								PUTBACK;
								call_sv(*isa_svp, G_SCALAR);
								SPAGAIN;
								value = POPs;
								PUTBACK;
							}
						}
						hv_store(args, key, retlen, newSVsv(value), 0);
					}
				}
				if (SvOK(value)) {
					trigger_svp = hv_fetch(spec_hv, "trigger", 7, 0);
					if (trigger_svp) {
						dSP;
						PUSHMARK(SP);
						XPUSHs(RETVAL);
						XPUSHs(value);
						PUTBACK;
						call_sv(*trigger_svp, G_SCALAR);
						SPAGAIN;
						POPs;
						PUTBACK;
					}
				}
			}
		}
	OUTPUT:
		RETVAL

SV *
rw_attribute(...)
	CODE:
		SV *spe = (SV *)CvXSUBANY(cv).any_ptr;
		HV *spec = (HV*)SvRV(spe);
		STRLEN retlen;
		SV **name_sv = hv_fetch(spec, "name", 4, 0);
		if (!name_sv) croak("No 'name' in spec");
		char *method = SvPV(*name_sv, retlen);
		STRLEN method_len = strlen(method);
		HV *self = (HV*)SvRV(ST(0));
		SV *val;

		if (items > 1) {
			SV **coerce_svp, **isa_svp, **trigger_svp;
			val = newSVsv(ST(1));

			coerce_svp = hv_fetch(spec, "coerce", 6, 0);
			if (coerce_svp) {
				dSP;
				PUSHMARK(SP);
				XPUSHs(val);
				PUTBACK;
				call_sv(*coerce_svp, G_SCALAR);
				SPAGAIN;
				SvREFCNT_dec(val);
				val = newSVsv(POPs);
				PUTBACK;
			}

			isa_svp = hv_fetch(spec, "isa", 3, 0);
			if (isa_svp && SvOK(*isa_svp)) {
				dSP;
				PUSHMARK(SP);
				XPUSHs(val);
				PUTBACK;
				call_sv(*isa_svp, G_SCALAR);
				SPAGAIN;
				SvREFCNT_dec(val);
				val = newSVsv(POPs);
				PUTBACK;
			}

			trigger_svp = hv_fetch(spec, "trigger", 7, 0);
			if (trigger_svp) {
				dSP;
				PUSHMARK(SP);
				XPUSHs(ST(0));
				XPUSHs(val);
				PUTBACK;
				call_sv(*trigger_svp, G_SCALAR);
				SPAGAIN;
				POPs;
				PUTBACK;
			}

			hv_store(self, method, method_len, newSVsv(val), 0);
			RETVAL = val;
		} else {
			SV **valp = hv_fetch(self, method, method_len, 0);
			if (valp) {
				RETVAL = *valp;
				SvREFCNT_inc(RETVAL);
			} else {
				RETVAL = &PL_sv_undef;
			}
		}
	OUTPUT:
		RETVAL

SV *
rw(name, attr)
	char *name
	SV *attr
	CODE:
		register_attribute(cv, name, attr, XS_Meow_rw_attribute, 0);

		RETVAL = newSViv(1);
	OUTPUT:
		RETVAL

SV *
ro_attribute(...)
	CODE:
		if (items > 1) {
			croak("Read only attributes cannot be set");
		}
		SV *spe = (SV *)CvXSUBANY(cv).any_ptr;
		HV *spec = (HV*)SvRV(spe);
		SV **name_sv = hv_fetch(spec, "name", 4, 0);
		if (!name_sv) croak("No 'name' in spec");
		STRLEN method_len;
		char *method = SvPV(*name_sv, method_len);
		HV *self = (HV*)SvRV(ST(0));
		SV **valp = hv_fetch(self, method, method_len, 0);
		if (valp) {
			RETVAL = *valp;
			SvREFCNT_inc(RETVAL);
		} else {
			RETVAL = &PL_sv_undef;
		}
	OUTPUT:
		RETVAL

SV *
ro(name, ...)
	char *name
	CODE:
		SV *attr;
		if (items > 1) {
			attr = ST(1);
			SvREFCNT_inc(attr);
		} else {
			attr = &PL_sv_undef;
		}

		register_attribute(cv, name, attr, XS_Meow_ro_attribute, 1);

		RETVAL = newSViv(1);
	OUTPUT:
		RETVAL

SV *
Default(...)
	CODE:
		SV *attr, *val;
		if (items > 1) {
			attr = ST(0);
			SvREFCNT_inc(attr);
			val = ST(1);
			SvREFCNT_inc(val);
		} else {
			attr = &PL_sv_undef;
			val = ST(0);
			SvREFCNT_inc(val);
		}
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "default", 7, val, 0);
		RETVAL = attr;
	OUTPUT:
		RETVAL

SV *
Coerce(...)
	CODE:
		SV *attr, *val;
		if (items > 1) {
			attr = ST(0);
			SvREFCNT_inc(attr);
			val = ST(1);
			SvREFCNT_inc(val);
		} else {
			attr = &PL_sv_undef;
			val = ST(0);
			SvREFCNT_inc(val);
		}
		if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVCV) {
			croak("Coerce requires a code reference as the second argument");
		}
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "coerce", 6, val, 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

SV *
Trigger(...)
	CODE:
		SV *attr, *val;
		if (items > 1) {
			attr = ST(0);
			SvREFCNT_inc(attr);
			val = ST(1);
			SvREFCNT_inc(val);
		} else {
			attr = &PL_sv_undef;
			val = ST(0);
			SvREFCNT_inc(val);
		}
		if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVCV) {
			croak("Trigger requires a code reference as the second argument");
		}
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "trigger", 7, val, 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

SV *
Builder(...)
	CODE:
		SV *attr, *val;
		if (items > 1) {
			attr = ST(0);
			SvREFCNT_inc(attr);
			val = ST(1);
			SvREFCNT_inc(val);
		} else {
			attr = &PL_sv_undef;
			val = ST(0);
			SvREFCNT_inc(val);
		}
		if (!SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVCV) {
			croak("Builder requires a code reference as the second argument");
		}
		attr = normalise_attr(attr);
		HV *spec = (HV*)SvRV(attr);
		hv_store(spec, "builder", 7, val, 0);
		SvREFCNT_inc(attr);
		RETVAL = attr;
	OUTPUT:
		RETVAL

void
extends(...)
	CODE:
		dTHX;
		HV *stash = (HV*)CopSTASH(PL_curcop);
		const char *child = HvNAME(stash);
		int i;
		for (i = 0; i < items; i++) {
			char *parent = SvPV_nolen(ST(i));
			AV *isa = get_avf("%s::ISA", child);
			int found = 0;
			SV **svp;
			SSize_t j, len = isa ? av_len(isa) + 1 : 0;
			for (j = 0; j < len; j++) {
				svp = av_fetch(isa, j, 0);
				if (svp && SvPOK(*svp) && strcmp(SvPV_nolen(*svp), parent) == 0) {
					found = 1;
					break;
				}
			}
			if (!found) {
				av_push(isa, newSVpv(parent, 0));
			}

			CV *child_cv = get_cvf("%s::new", child);
			CV *parent_cv = get_cvf("%s::new", parent);

			if (!child_cv || !parent_cv)
				croak("Could not find new() for child or parent class");

			SV *child_spec = (SV *)CvXSUBANY(child_cv).any_ptr;
			if (!child_spec || !SvROK(child_spec)) {
				HV *specs = get_hv("Meow::SPECS", 0);
				if (specs) {
					SV **svp = hv_fetch(specs, child, strlen(child), 0);
					if (svp && SvROK(*svp)) child_spec = *svp;
				}
			}
			SV *parent_spec = (SV *)CvXSUBANY(parent_cv).any_ptr;
			if (!parent_spec || !SvROK(parent_spec)) {
				HV *specs = get_hv("Meow::SPECS", 0);
				if (specs) {
					SV **svp = hv_fetch(specs, parent, strlen(parent), 0);
					if (svp && SvROK(*svp)) parent_spec = *svp;
				}
			}

			if (!child_spec || !parent_spec || !SvROK(child_spec) || !SvROK(parent_spec))
				croak("Missing spec in child or parent");
			HV *child_hv = (HV*)SvRV(child_spec);
			HV *parent_hv = (HV*)SvRV(parent_spec);
			HE *entry;
			hv_iterinit(parent_hv);
			while ((entry = hv_iternext(parent_hv))) {
				SV *keysv = hv_iterkeysv(entry);
				STRLEN klen;
				const char *key = SvPV(keysv, klen);
				if (!hv_exists(child_hv, key, klen)) {
					SV *val = newSVsv(hv_iterval(parent_hv, entry));
					hv_store(child_hv, key, klen, val, 0);
				}
			}
		}

void
import(pkg, ...)
	char *pkg
	CODE:
		char *callr = get_caller();
		const char *export[] = { "new", "rw", "ro", "extends", "Default", "Coerce", "Trigger", "Builder", "make_immutable" };
		int i;
		CV *newcv = NULL;
		for (i = 0; i < 9; i++) {
			const char *ex = export[i];
			size_t name_len = strlen(callr) + 2 + strlen(ex) + 1;
			char *name = (char *)malloc(name_len);
			if (!name) croak("Out of memory in import");
			snprintf(name, name_len, "%s::%s", callr, ex);
			if (strcmp(ex, "new") == 0) {
				newcv = newXS(name, XS_Meow_new, __FILE__);
				SV *spec = newRV_noinc((SV*)newHV());
				CvXSUBANY(newcv).any_ptr = (void *)spec;
			} else if (strcmp(ex, "rw") == 0) {
				CV *rwcv = newXS(name, XS_Meow_rw, __FILE__);
				CvXSUBANY(rwcv).any_ptr = (void *)newcv;
			} else if (strcmp(ex, "ro") == 0) {
				CV *rwcv = newXS(name, XS_Meow_ro, __FILE__);
				CvXSUBANY(rwcv).any_ptr = (void *)newcv;
			} else if (strcmp(ex, "extends") == 0) {
				CV *extends_cv = newXS(name, XS_Meow_extends, __FILE__);
			} else if (strcmp(ex, "Default") == 0) {
				CV *default_cv = newXS(name, XS_Meow_Default, __FILE__);
			} else if (strcmp(ex, "Coerce") == 0){
				CV *coerce_cv = newXS(name, XS_Meow_Coerce, __FILE__);
			} else if (strcmp(ex, "Trigger") == 0) {
				CV *trigger_cv = newXS(name, XS_Meow_Trigger, __FILE__);
			} else if (strcmp(ex, "Builder") == 0) {
				CV *builder_cv = newXS(name, XS_Meow_Builder, __FILE__);
			} else if (strcmp(ex, "make_immutable") == 0) {
				CV *mi_cv = get_cv("Meow::make_immutable", 0);
				if (mi_cv) {
					GV *gv = gv_fetchpv(name, GV_ADD, SVt_PVCV);
					GvCV_set(gv, mi_cv);
					SvREFCNT_inc((SV*)mi_cv);
					GvIMPORTED_CV_on(gv);
					GvMULTI_on(gv);
				}
			}
			free(name);
		}

void
DESTROY(...)
	CODE:
		Safefree(ST(0));

SV *
_get_spec_from_cv(package)
	char *package
	CODE:
		/* Get the spec hash from a package's new() function */
		char name[256];
		snprintf(name, sizeof(name), "%s::new", package);
		CV *newcv = get_cv(name, 0);
		if (!newcv) {
			RETVAL = &PL_sv_undef;
		} else {
			SV *spec = (SV *)CvXSUBANY(newcv).any_ptr;
			if (spec && SvROK(spec)) {
				RETVAL = newSVsv(spec);
			} else {
				RETVAL = &PL_sv_undef;
			}
		}
	OUTPUT:
		RETVAL

SV *
_get_attr_spec_from_cv(package, attr_name)
	char *package
	char *attr_name
	CODE:
		/* Get the spec hash from an attribute accessor */
		char name[256];
		snprintf(name, sizeof(name), "%s::%s", package, attr_name);
		CV *attrcv = get_cv(name, 0);
		if (!attrcv) {
			RETVAL = &PL_sv_undef;
		} else {
			SV *spec = (SV *)CvXSUBANY(attrcv).any_ptr;
			if (spec && SvROK(spec)) {
				RETVAL = newSVsv(spec);
			} else {
				RETVAL = &PL_sv_undef;
			}
		}
	OUTPUT:
		RETVAL

void
make_immutable(...)
	CODE:
		/* Get the caller's package name */
		const char *package = HvNAME((HV*)CopSTASH(PL_curcop));
		_compile_jit(aTHX_ package);

int
compile_jit(package)
	char *package
	CODE:
		RETVAL = _compile_jit(aTHX_ package);
	OUTPUT:
		RETVAL

int
_jit_available_xs()
	CODE:
		RETVAL = _jit_available(aTHX);
	OUTPUT:
		RETVAL
