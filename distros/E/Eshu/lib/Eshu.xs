#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*
 * On Windows threaded Perl (MULTIPLICITY), perl.h redefines standard C
 * functions (malloc, free, stat, opendir, etc.) as macros that require
 * the interpreter context (my_perl).  Our engine headers are pure C and
 * must call the real libc functions, so undo those overrides here.
 * This is safe: the XS code below uses Perl API directly and never
 * relies on these macros.
 */
#ifdef WIN32
#  undef malloc
#  undef realloc
#  undef calloc
#  undef free
#  undef stat
#  undef lstat
#  undef fstat
#  undef opendir
#  undef readdir
#  undef closedir
#  undef rename
#  undef open
#  undef close
#  undef read
#  undef write
#endif

#include "eshu.h"
#include "eshu_c.h"
#include "eshu_pod.h"
#include "eshu_pl.h"
#include "eshu_xs.h"
#include "eshu_js.h"
#include "eshu_xml.h"
#include "eshu_css.h"
#include "eshu_diff.h"
#include "eshu_file.h"

MODULE = Eshu  PACKAGE = Eshu

PROTOTYPES: DISABLE

SV *
detect_lang(class, filename_sv)
	SV * class
	SV * filename_sv
	CODE:
	{
		const char *filename;
		const char *dot;
		STRLEN len;

		PERL_UNUSED_VAR(class);
		RETVAL = &PL_sv_undef;

		if (SvOK(filename_sv)) {
			filename = SvPV(filename_sv, len);
			dot = NULL;
			/* find last dot */
			{
				const char *p = filename + len;
				while (p > filename) {
					p--;
					if (*p == '.') { dot = p + 1; break; }
				}
			}
			if (dot) {
				STRLEN ext_len = (filename + len) - dot;
				if ((ext_len == 1 && (dot[0] == 'c' || dot[0] == 'C'))
				    || (ext_len == 1 && (dot[0] == 'h' || dot[0] == 'H'))) {
					RETVAL = newSVpvs("c");
				} else if (ext_len == 2
				           && (dot[0] == 'x' || dot[0] == 'X')
				           && (dot[1] == 's' || dot[1] == 'S')) {
					RETVAL = newSVpvs("xs");
				} else if ((ext_len == 2
				            && (dot[0] == 'p' || dot[0] == 'P')
				            && (dot[1] == 'l' || dot[1] == 'L'))
				           || (ext_len == 2
				               && (dot[0] == 'p' || dot[0] == 'P')
				               && (dot[1] == 'm' || dot[1] == 'M'))
				           || (ext_len == 1
				               && (dot[0] == 't' || dot[0] == 'T'))) {
					RETVAL = newSVpvs("perl");
				} else if ((ext_len == 3
				            && (dot[0] == 'x' || dot[0] == 'X')
				            && (dot[1] == 'm' || dot[1] == 'M')
				            && (dot[2] == 'l' || dot[2] == 'L'))
				           || (ext_len == 3
				               && (dot[0] == 'x' || dot[0] == 'X')
				               && (dot[1] == 's' || dot[1] == 'S')
				               && (dot[2] == 'l' || dot[2] == 'L'))
				           || (ext_len == 4
				               && (dot[0] == 'x' || dot[0] == 'X')
				               && (dot[1] == 's' || dot[1] == 'S')
				               && (dot[2] == 'l' || dot[2] == 'L')
				               && (dot[3] == 't' || dot[3] == 'T'))
				           || (ext_len == 3
				               && (dot[0] == 's' || dot[0] == 'S')
				               && (dot[1] == 'v' || dot[1] == 'V')
				               && (dot[2] == 'g' || dot[2] == 'G'))
				           || (ext_len == 5
				               && (dot[0] == 'x' || dot[0] == 'X')
				               && (dot[1] == 'h' || dot[1] == 'H')
				               && (dot[2] == 't' || dot[2] == 'T')
				               && (dot[3] == 'm' || dot[3] == 'M')
				               && (dot[4] == 'l' || dot[4] == 'L'))) {
					RETVAL = newSVpvs("xml");
				} else if ((ext_len == 4
				            && (dot[0] == 'h' || dot[0] == 'H')
				            && (dot[1] == 't' || dot[1] == 'T')
				            && (dot[2] == 'm' || dot[2] == 'M')
				            && (dot[3] == 'l' || dot[3] == 'L'))
				           || (ext_len == 3
				               && (dot[0] == 'h' || dot[0] == 'H')
				               && (dot[1] == 't' || dot[1] == 'T')
				               && (dot[2] == 'm' || dot[2] == 'M'))
				           || (ext_len == 4
				               && (dot[0] == 't' || dot[0] == 'T')
				               && (dot[1] == 'm' || dot[1] == 'M')
				               && (dot[2] == 'p' || dot[2] == 'P')
				               && (dot[3] == 'l' || dot[3] == 'L'))
				           || (ext_len == 2
				               && (dot[0] == 't' || dot[0] == 'T')
				               && (dot[1] == 't' || dot[1] == 'T'))
				           || (ext_len == 2
				               && (dot[0] == 'e' || dot[0] == 'E')
				               && (dot[1] == 'p' || dot[1] == 'P'))) {
					RETVAL = newSVpvs("html");
				} else if ((ext_len == 3
				            && (dot[0] == 'c' || dot[0] == 'C')
				            && (dot[1] == 's' || dot[1] == 'S')
				            && (dot[2] == 's' || dot[2] == 'S'))
				           || (ext_len == 4
				               && (dot[0] == 's' || dot[0] == 'S')
				               && (dot[1] == 'c' || dot[1] == 'C')
				               && (dot[2] == 's' || dot[2] == 'S')
				               && (dot[3] == 's' || dot[3] == 'S'))
				           || (ext_len == 4
				               && (dot[0] == 'l' || dot[0] == 'L')
				               && (dot[1] == 'e' || dot[1] == 'E')
				               && (dot[2] == 's' || dot[2] == 'S')
				               && (dot[3] == 's' || dot[3] == 'S'))) {
					RETVAL = newSVpvs("css");
				} else if ((ext_len == 2
				            && (dot[0] == 'j' || dot[0] == 'J')
				            && (dot[1] == 's' || dot[1] == 'S'))
				           || (ext_len == 3
				               && (dot[0] == 'j' || dot[0] == 'J')
				               && (dot[1] == 's' || dot[1] == 'S')
				               && (dot[2] == 'x' || dot[2] == 'X'))
				           || (ext_len == 3
				               && (dot[0] == 'm' || dot[0] == 'M')
				               && (dot[1] == 'j' || dot[1] == 'J')
				               && (dot[2] == 's' || dot[2] == 'S'))
				           || (ext_len == 3
				               && (dot[0] == 'c' || dot[0] == 'C')
				               && (dot[1] == 'j' || dot[1] == 'J')
				               && (dot[2] == 's' || dot[2] == 'S'))
				           || (ext_len == 2
				               && (dot[0] == 't' || dot[0] == 'T')
				               && (dot[1] == 's' || dot[1] == 'S'))
				           || (ext_len == 3
				               && (dot[0] == 't' || dot[0] == 'T')
				               && (dot[1] == 's' || dot[1] == 'S')
				               && (dot[2] == 'x' || dot[2] == 'X'))
				           || (ext_len == 3
				               && (dot[0] == 'm' || dot[0] == 'M')
				               && (dot[1] == 't' || dot[1] == 'T')
				               && (dot[2] == 's' || dot[2] == 'S'))) {
					RETVAL = newSVpvs("js");
				} else if (ext_len == 3
				           && (dot[0] == 'p' || dot[0] == 'P')
				           && (dot[1] == 'o' || dot[1] == 'O')
				           && (dot[2] == 'd' || dot[2] == 'D')) {
					RETVAL = newSVpvs("pod");
				}
			}
		}
	}
	OUTPUT:
		RETVAL

SV *
indent_c(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "indent_pp")) {
				cfg.indent_pp = SvTRUE(val) ? 1 : 0;
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_c(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_pl(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_PERL;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_pl(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_xs(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_XS;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "indent_pp")) {
				cfg.indent_pp = SvTRUE(val) ? 1 : 0;
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_xs(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_xml(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_XML;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "lang")) {
				const char *l = SvPV_nolen(val);
				if (strEQ(l, "html") || strEQ(l, "htm")) {
					cfg.lang = ESHU_LANG_HTML;
				}
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_xml(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_html(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_HTML;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_xml(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_css(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_CSS;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_css(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_js(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_JS;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_js(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_pod(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();
		cfg.lang = ESHU_LANG_POD;

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		result = eshu_indent_pod(src, (size_t)src_len, &cfg, &out_len);
		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_string(class, src_sv, ...)
	SV * class
	SV * src_sv
	CODE:
	{
		const char *src;
		STRLEN src_len;
		eshu_config_t cfg;
		char *result;
		size_t out_len;
		const char *lang = "c";
		int i;

		PERL_UNUSED_VAR(class);
		src = SvPV(src_sv, src_len);
		cfg = eshu_default_config();

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "lang")) {
				lang = SvPV_nolen(val);
			} else if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "indent_pp")) {
				cfg.indent_pp = SvTRUE(val) ? 1 : 0;
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		if (strEQ(lang, "c")) {
			result = eshu_indent_c(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "perl") || strEQ(lang, "pl")) {
			cfg.lang = ESHU_LANG_PERL;
			result = eshu_indent_pl(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "xs")) {
			cfg.lang = ESHU_LANG_XS;
			result = eshu_indent_xs(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "xml") || strEQ(lang, "svg")) {
			cfg.lang = ESHU_LANG_XML;
			result = eshu_indent_xml(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "html") || strEQ(lang, "htm")) {
			cfg.lang = ESHU_LANG_HTML;
			result = eshu_indent_xml(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "css") || strEQ(lang, "scss") || strEQ(lang, "less")) {
			cfg.lang = ESHU_LANG_CSS;
			result = eshu_indent_css(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "js") || strEQ(lang, "javascript") ||
		           strEQ(lang, "jsx") || strEQ(lang, "ts") ||
		           strEQ(lang, "typescript") || strEQ(lang, "tsx") ||
		           strEQ(lang, "mjs") || strEQ(lang, "cjs") ||
		           strEQ(lang, "mts")) {
			cfg.lang = ESHU_LANG_JS;
			result = eshu_indent_js(src, (size_t)src_len, &cfg, &out_len);
		} else if (strEQ(lang, "pod")) {
			cfg.lang = ESHU_LANG_POD;
			result = eshu_indent_pod(src, (size_t)src_len, &cfg, &out_len);
		} else {
			croak("Eshu: unsupported language '%s'", lang);
			result = NULL; /* not reached */
			out_len = 0;
		}

		RETVAL = newSVpvn(result, out_len);
		free(result);
	}
	OUTPUT:
		RETVAL

SV *
indent_file(class, path_sv, ...)
	SV * class
	SV * path_sv
	CODE:
	{
		const char *path;
		STRLEN path_len;
		eshu_config_t cfg;
		const char *force_lang = NULL;
		int opts = 0;
		int i;
		eshu_file_result_t res;
		HV *hv;

		PERL_UNUSED_VAR(class);
		path = SvPV(path_sv, path_len);
		cfg = eshu_default_config();

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "fix")) {
				if (SvTRUE(val)) opts |= ESHU_OPT_FIX;
			} else if (strEQ(key, "diff")) {
				if (SvTRUE(val)) opts |= ESHU_OPT_DIFF;
			} else if (strEQ(key, "lang")) {
				force_lang = SvPV_nolen(val);
			} else if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "indent_pp")) {
				cfg.indent_pp = SvTRUE(val) ? 1 : 0;
			} else if (strEQ(key, "range_start")) {
				cfg.range_start = SvIV(val);
			} else if (strEQ(key, "range_end")) {
				cfg.range_end = SvIV(val);
			}
		}

		eshu_indent_file(path, &cfg, force_lang, opts, &res);

		hv = newHV();
		hv_store(hv, "file", 4, newSVpv(res.file, 0), 0);
		switch (res.status) {
		case ESHU_STATUS_UNCHANGED:
			hv_store(hv, "status", 6, newSVpvs("unchanged"), 0); break;
		case ESHU_STATUS_CHANGED:
			hv_store(hv, "status", 6, newSVpvs("changed"), 0); break;
		case ESHU_STATUS_NEEDS_FIXING:
			hv_store(hv, "status", 6, newSVpvs("needs_fixing"), 0); break;
		case ESHU_STATUS_SKIPPED:
			hv_store(hv, "status", 6, newSVpvs("skipped"), 0); break;
		case ESHU_STATUS_ERROR:
			hv_store(hv, "status", 6, newSVpvs("error"), 0); break;
		}
		if (res.lang)
			hv_store(hv, "lang", 4, newSVpv(res.lang, 0), 0);
		if (res.reason)
			hv_store(hv, "reason", 6, newSVpv(res.reason, 0), 0);
		if (res.error)
			hv_store(hv, "error", 5, newSVpv(res.error, 0), 0);
		if (res.diff)
			hv_store(hv, "diff", 4, newSVpvn(res.diff, res.diff_len), 0);

		eshu_file_result_free(&res);
		RETVAL = newRV_noinc((SV *)hv);
	}
	OUTPUT:
		RETVAL

SV *
indent_dir(class, path_sv, ...)
	SV * class
	SV * path_sv
	CODE:
	{
		const char *path;
		STRLEN path_len;
		eshu_config_t cfg;
		const char *force_lang = NULL;
		int file_opts = 0;
		int recursive = 1;
		int i;
		eshu_strlist_t files;
		eshu_dir_report_t report;
		HV *report_hv;
		AV *changes_av;
		size_t fi;
		AV *exclude_av = NULL;
		AV *include_av = NULL;

		PERL_UNUSED_VAR(class);
		path = SvPV(path_sv, path_len);
		cfg = eshu_default_config();

		for (i = 2; i + 1 < items; i += 2) {
			const char *key = SvPV_nolen(ST(i));
			SV *val = ST(i + 1);
			if (strEQ(key, "fix")) {
				if (SvTRUE(val)) file_opts |= ESHU_OPT_FIX;
			} else if (strEQ(key, "diff")) {
				if (SvTRUE(val)) file_opts |= ESHU_OPT_DIFF;
			} else if (strEQ(key, "lang")) {
				force_lang = SvPV_nolen(val);
			} else if (strEQ(key, "recursive")) {
				recursive = SvTRUE(val) ? 1 : 0;
			} else if (strEQ(key, "exclude")) {
				if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
					exclude_av = (AV *)SvRV(val);
				} else {
					exclude_av = newAV();
					av_push(exclude_av, SvREFCNT_inc(val));
					sv_2mortal((SV *)exclude_av);
				}
			} else if (strEQ(key, "include")) {
				if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
					include_av = (AV *)SvRV(val);
				} else {
					include_av = newAV();
					av_push(include_av, SvREFCNT_inc(val));
					sv_2mortal((SV *)include_av);
				}
			} else if (strEQ(key, "indent_char")) {
				const char *ic = SvPV_nolen(val);
				cfg.indent_char = (*ic == ' ') ? ' ' : '\t';
			} else if (strEQ(key, "indent_width")) {
				cfg.indent_width = SvIV(val);
			} else if (strEQ(key, "indent_pp")) {
				cfg.indent_pp = SvTRUE(val) ? 1 : 0;
			}
		}

		/* Collect files */
		eshu_strlist_init(&files);
		{
			struct stat st;
			if (stat(path, &st) == 0 && S_ISREG(st.st_mode)) {
				eshu_strlist_push(&files, path);
			} else if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
				eshu_walk_dir(path, &files, recursive);
			} else {
				eshu_strlist_free(&files);
				croak("Eshu: '%s' is not a file or directory", path);
			}
		}
		eshu_strlist_sort(&files);

		/* Process files */
		eshu_dir_report_init(&report);
		changes_av = newAV();

		for (fi = 0; fi < files.count; fi++) {
			const char *fpath = files.items[fi];
			int skip = 0;

			/* Exclude filter */
			if (exclude_av) {
				SSize_t j, alen = av_len(exclude_av) + 1;
				for (j = 0; j < alen; j++) {
					SV **elem = av_fetch(exclude_av, j, 0);
					if (elem && SvOK(*elem)) {
						REGEXP *rx = SvRX(*elem);
						if (rx) {
							SV *file_sv = sv_2mortal(newSVpv(fpath, 0));
							if (pregexec(rx, SvPV_nolen(file_sv), SvPV_nolen(file_sv) + strlen(fpath), SvPV_nolen(file_sv), 0, file_sv, 0)) {
								skip = 1; break;
							}
						}
					}
				}
			}
			if (skip) {
				HV *hv = newHV();
				hv_store(hv, "file", 4, newSVpv(fpath, 0), 0);
				hv_store(hv, "status", 6, newSVpvs("skipped"), 0);
				hv_store(hv, "reason", 6, newSVpvs("excluded"), 0);
				av_push(changes_av, newRV_noinc((SV *)hv));
				report.files_skipped++;
				continue;
			}

			/* Include filter */
			if (include_av) {
				SSize_t j, alen = av_len(include_av) + 1;
				int matched = 0;
				for (j = 0; j < alen; j++) {
					SV **elem = av_fetch(include_av, j, 0);
					if (elem && SvOK(*elem)) {
						REGEXP *rx = SvRX(*elem);
						if (rx) {
							SV *file_sv = sv_2mortal(newSVpv(fpath, 0));
							if (pregexec(rx, SvPV_nolen(file_sv), SvPV_nolen(file_sv) + strlen(fpath), SvPV_nolen(file_sv), 0, file_sv, 0)) {
								matched = 1; break;
							}
						}
					}
				}
				if (!matched) {
					HV *hv = newHV();
					hv_store(hv, "file", 4, newSVpv(fpath, 0), 0);
					hv_store(hv, "status", 6, newSVpvs("skipped"), 0);
					hv_store(hv, "reason", 6, newSVpvs("not included"), 0);
					av_push(changes_av, newRV_noinc((SV *)hv));
					report.files_skipped++;
					continue;
				}
			}

			/* Process file */
			{
				eshu_file_result_t res;
				HV *hv = newHV();

				eshu_indent_file(fpath, &cfg, force_lang, file_opts, &res);

				hv_store(hv, "file", 4, newSVpv(res.file, 0), 0);
				switch (res.status) {
				case ESHU_STATUS_UNCHANGED:
					hv_store(hv, "status", 6, newSVpvs("unchanged"), 0); break;
				case ESHU_STATUS_CHANGED:
					hv_store(hv, "status", 6, newSVpvs("changed"), 0); break;
				case ESHU_STATUS_NEEDS_FIXING:
					hv_store(hv, "status", 6, newSVpvs("needs_fixing"), 0); break;
				case ESHU_STATUS_SKIPPED:
					hv_store(hv, "status", 6, newSVpvs("skipped"), 0); break;
				case ESHU_STATUS_ERROR:
					hv_store(hv, "status", 6, newSVpvs("error"), 0); break;
				}
				if (res.lang)
					hv_store(hv, "lang", 4, newSVpv(res.lang, 0), 0);
				if (res.reason)
					hv_store(hv, "reason", 6, newSVpv(res.reason, 0), 0);
				if (res.error)
					hv_store(hv, "error", 5, newSVpv(res.error, 0), 0);
				if (res.diff)
					hv_store(hv, "diff", 4, newSVpvn(res.diff, res.diff_len), 0);

				if (res.status == ESHU_STATUS_CHANGED || res.status == ESHU_STATUS_NEEDS_FIXING) {
					report.files_changed++;
					report.files_checked++;
				} else if (res.status == ESHU_STATUS_UNCHANGED) {
					report.files_checked++;
				} else if (res.status == ESHU_STATUS_SKIPPED) {
					report.files_skipped++;
				} else if (res.status == ESHU_STATUS_ERROR) {
					report.files_errored++;
				}

				eshu_file_result_free(&res);
				av_push(changes_av, newRV_noinc((SV *)hv));
			}
		}

		eshu_strlist_free(&files);

		report_hv = newHV();
		hv_store(report_hv, "files_checked", 13, newSViv(report.files_checked), 0);
		hv_store(report_hv, "files_changed", 13, newSViv(report.files_changed), 0);
		hv_store(report_hv, "files_skipped", 13, newSViv(report.files_skipped), 0);
		hv_store(report_hv, "files_errored", 13, newSViv(report.files_errored), 0);
		hv_store(report_hv, "changes", 7, newRV_noinc((SV *)changes_av), 0);

		free(report.changes);

		RETVAL = newRV_noinc((SV *)report_hv);
	}
	OUTPUT:
		RETVAL
