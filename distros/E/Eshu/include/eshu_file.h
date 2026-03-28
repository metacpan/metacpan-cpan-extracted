/*
 * eshu_file.h — File and directory level indentation operations
 *
 * Pure C (POSIX), no Perl dependencies.
 * Requires: eshu.h, eshu_c.h, eshu_pl.h, eshu_xs.h, eshu_xml.h,
 *           eshu_css.h, eshu_diff.h
 */

#ifndef ESHU_FILE_H
#define ESHU_FILE_H

#include "eshu.h"
#include "eshu_diff.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>

#define ESHU_MAX_FILE_SIZE 1048576  /* 1MB */
#define ESHU_BINARY_SAMPLE  8192

/* ══════════════════════════════════════════════════════════════════
 *  Status codes for indent_file results
 * ══════════════════════════════════════════════════════════════════ */

enum eshu_file_status {
	ESHU_STATUS_UNCHANGED    = 0,
	ESHU_STATUS_CHANGED      = 1,
	ESHU_STATUS_NEEDS_FIXING = 2,
	ESHU_STATUS_SKIPPED      = 3,
	ESHU_STATUS_ERROR        = 4
};

/* ══════════════════════════════════════════════════════════════════
 *  File result
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	char  *file;         /* path (strdup'd, caller frees) */
	int    status;       /* eshu_file_status */
	char  *lang;         /* language string or NULL */
	char  *reason;       /* skip reason or NULL */
	char  *error;        /* error message or NULL */
	char  *diff;         /* diff string or NULL */
	size_t diff_len;
} eshu_file_result_t;

static void eshu_file_result_init(eshu_file_result_t *r) {
	memset(r, 0, sizeof(*r));
}

static void eshu_file_result_free(eshu_file_result_t *r) {
	if (r->file)   free(r->file);
	if (r->lang)   free(r->lang);
	if (r->reason) free(r->reason);
	if (r->error)  free(r->error);
	if (r->diff)   free(r->diff);
	memset(r, 0, sizeof(*r));
}

/* ══════════════════════════════════════════════════════════════════
 *  Directory report
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	int files_checked;
	int files_changed;
	int files_skipped;
	int files_errored;
	eshu_file_result_t *changes;
	size_t changes_count;
	size_t changes_cap;
} eshu_dir_report_t;

static void eshu_dir_report_init(eshu_dir_report_t *r) {
	memset(r, 0, sizeof(*r));
	r->changes_cap = 64;
	r->changes = (eshu_file_result_t *)malloc(r->changes_cap * sizeof(eshu_file_result_t));
}

static void eshu_dir_report_push(eshu_dir_report_t *r, eshu_file_result_t *res) {
	if (r->changes_count >= r->changes_cap) {
		r->changes_cap *= 2;
		r->changes = (eshu_file_result_t *)realloc(r->changes,
			r->changes_cap * sizeof(eshu_file_result_t));
	}
	r->changes[r->changes_count++] = *res;
	/* Transfer ownership — caller should not free res fields */
}

static void eshu_dir_report_free(eshu_dir_report_t *r) {
	size_t i;
	for (i = 0; i < r->changes_count; i++)
		eshu_file_result_free(&r->changes[i]);
	free(r->changes);
	memset(r, 0, sizeof(*r));
}

/* ══════════════════════════════════════════════════════════════════
 *  Language detection from extension (pure C)
 * ══════════════════════════════════════════════════════════════════ */

/* Case-insensitive single-char compare */
static int eshu_ci(char a, char b) {
	if (a >= 'A' && a <= 'Z') a += 32;
	if (b >= 'A' && b <= 'Z') b += 32;
	return a == b;
}

/* Returns a static string: "c","xs","perl","xml","xhtml","html","css" or NULL */
static const char *eshu_detect_lang_ext(const char *path) {
	const char *dot = NULL;
	const char *p = path + strlen(path);
	size_t ext_len;

	while (p > path) {
		p--;
		if (*p == '.') { dot = p + 1; break; }
		if (*p == '/' || *p == '\\') break;
	}
	if (!dot) return NULL;
	ext_len = strlen(dot);

	/* c, h */
	if (ext_len == 1 && (eshu_ci(dot[0], 'c') || eshu_ci(dot[0], 'h')))
		return "c";
	/* xs */
	if (ext_len == 2 && eshu_ci(dot[0], 'x') && eshu_ci(dot[1], 's'))
		return "xs";
	/* pl, pm */
	if (ext_len == 2 && eshu_ci(dot[0], 'p')
	    && (eshu_ci(dot[1], 'l') || eshu_ci(dot[1], 'm')))
		return "perl";
	/* t */
	if (ext_len == 1 && eshu_ci(dot[0], 't'))
		return "perl";
	/* xml */
	if (ext_len == 3 && eshu_ci(dot[0], 'x') && eshu_ci(dot[1], 'm') && eshu_ci(dot[2], 'l'))
		return "xml";
	/* xsl */
	if (ext_len == 3 && eshu_ci(dot[0], 'x') && eshu_ci(dot[1], 's') && eshu_ci(dot[2], 'l'))
		return "xml";
	/* xslt */
	if (ext_len == 4 && eshu_ci(dot[0], 'x') && eshu_ci(dot[1], 's')
	    && eshu_ci(dot[2], 'l') && eshu_ci(dot[3], 't'))
		return "xml";
	/* svg */
	if (ext_len == 3 && eshu_ci(dot[0], 's') && eshu_ci(dot[1], 'v') && eshu_ci(dot[2], 'g'))
		return "xml";
	/* xhtml */
	if (ext_len == 5 && eshu_ci(dot[0], 'x') && eshu_ci(dot[1], 'h')
	    && eshu_ci(dot[2], 't') && eshu_ci(dot[3], 'm') && eshu_ci(dot[4], 'l'))
		return "xhtml";
	/* html */
	if (ext_len == 4 && eshu_ci(dot[0], 'h') && eshu_ci(dot[1], 't')
	    && eshu_ci(dot[2], 'm') && eshu_ci(dot[3], 'l'))
		return "html";
	/* htm */
	if (ext_len == 3 && eshu_ci(dot[0], 'h') && eshu_ci(dot[1], 't') && eshu_ci(dot[2], 'm'))
		return "html";
	/* tmpl */
	if (ext_len == 4 && eshu_ci(dot[0], 't') && eshu_ci(dot[1], 'm')
	    && eshu_ci(dot[2], 'p') && eshu_ci(dot[3], 'l'))
		return "html";
	/* tt */
	if (ext_len == 2 && eshu_ci(dot[0], 't') && eshu_ci(dot[1], 't'))
		return "html";
	/* ep */
	if (ext_len == 2 && eshu_ci(dot[0], 'e') && eshu_ci(dot[1], 'p'))
		return "html";
	/* css */
	if (ext_len == 3 && eshu_ci(dot[0], 'c') && eshu_ci(dot[1], 's') && eshu_ci(dot[2], 's'))
		return "css";
	/* scss */
	if (ext_len == 4 && eshu_ci(dot[0], 's') && eshu_ci(dot[1], 'c')
	    && eshu_ci(dot[2], 's') && eshu_ci(dot[3], 's'))
		return "css";
	/* less */
	if (ext_len == 4 && eshu_ci(dot[0], 'l') && eshu_ci(dot[1], 'e')
	    && eshu_ci(dot[2], 's') && eshu_ci(dot[3], 's'))
		return "css";

	/* js */
	if (ext_len == 2 && eshu_ci(dot[0], 'j') && eshu_ci(dot[1], 's'))
		return "js";
	/* jsx */
	if (ext_len == 3 && eshu_ci(dot[0], 'j') && eshu_ci(dot[1], 's') && eshu_ci(dot[2], 'x'))
		return "js";
	/* mjs */
	if (ext_len == 3 && eshu_ci(dot[0], 'm') && eshu_ci(dot[1], 'j') && eshu_ci(dot[2], 's'))
		return "js";
	/* cjs */
	if (ext_len == 3 && eshu_ci(dot[0], 'c') && eshu_ci(dot[1], 'j') && eshu_ci(dot[2], 's'))
		return "js";
	/* ts */
	if (ext_len == 2 && eshu_ci(dot[0], 't') && eshu_ci(dot[1], 's'))
		return "js";
	/* tsx */
	if (ext_len == 3 && eshu_ci(dot[0], 't') && eshu_ci(dot[1], 's') && eshu_ci(dot[2], 'x'))
		return "js";
	/* mts */
	if (ext_len == 3 && eshu_ci(dot[0], 'm') && eshu_ci(dot[1], 't') && eshu_ci(dot[2], 's'))
		return "js";

	/* pod */
	if (ext_len == 3 && eshu_ci(dot[0], 'p') && eshu_ci(dot[1], 'o') && eshu_ci(dot[2], 'd'))
		return "pod";

	return NULL;
}

/* ══════════════════════════════════════════════════════════════════
 *  Config from lang string
 * ══════════════════════════════════════════════════════════════════ */

/* Forward declarations for engine functions — headers must already be included */

static int eshu_lang_from_string(const char *lang) {
	if (!lang) return -1;
	if (strcmp(lang, "c") == 0)     return ESHU_LANG_C;
	if (strcmp(lang, "perl") == 0)  return ESHU_LANG_PERL;
	if (strcmp(lang, "pl") == 0)    return ESHU_LANG_PERL;
	if (strcmp(lang, "xs") == 0)    return ESHU_LANG_XS;
	if (strcmp(lang, "xml") == 0)   return ESHU_LANG_XML;
	if (strcmp(lang, "xsl") == 0)   return ESHU_LANG_XML;
	if (strcmp(lang, "xslt") == 0)  return ESHU_LANG_XML;
	if (strcmp(lang, "svg") == 0)   return ESHU_LANG_XML;
	if (strcmp(lang, "xhtml") == 0) return ESHU_LANG_XML;
	if (strcmp(lang, "html") == 0)  return ESHU_LANG_HTML;
	if (strcmp(lang, "htm") == 0)   return ESHU_LANG_HTML;
	if (strcmp(lang, "tmpl") == 0)  return ESHU_LANG_HTML;
	if (strcmp(lang, "tt") == 0)    return ESHU_LANG_HTML;
	if (strcmp(lang, "ep") == 0)    return ESHU_LANG_HTML;
	if (strcmp(lang, "css") == 0)   return ESHU_LANG_CSS;
	if (strcmp(lang, "scss") == 0)  return ESHU_LANG_CSS;
	if (strcmp(lang, "less") == 0)  return ESHU_LANG_CSS;
	if (strcmp(lang, "js") == 0)        return ESHU_LANG_JS;
	if (strcmp(lang, "javascript") == 0) return ESHU_LANG_JS;
	if (strcmp(lang, "jsx") == 0)       return ESHU_LANG_JS;
	if (strcmp(lang, "mjs") == 0)       return ESHU_LANG_JS;
	if (strcmp(lang, "cjs") == 0)       return ESHU_LANG_JS;
	if (strcmp(lang, "ts") == 0)        return ESHU_LANG_JS;
	if (strcmp(lang, "typescript") == 0) return ESHU_LANG_JS;
	if (strcmp(lang, "tsx") == 0)       return ESHU_LANG_JS;
	if (strcmp(lang, "mts") == 0)       return ESHU_LANG_JS;
	if (strcmp(lang, "pod") == 0)       return ESHU_LANG_POD;
	return -1;
}

/* Dispatch to the correct indentation engine.
 * Returns malloc'd result; caller must free. */
static char *eshu_indent_dispatch(const char *src, size_t src_len,
                                  eshu_config_t *cfg, size_t *out_len)
{
	switch (cfg->lang) {
	case ESHU_LANG_PERL:
		return eshu_indent_pl(src, src_len, cfg, out_len);
	case ESHU_LANG_XS:
		return eshu_indent_xs(src, src_len, cfg, out_len);
	case ESHU_LANG_XML:
	case ESHU_LANG_HTML:
		return eshu_indent_xml(src, src_len, cfg, out_len);
	case ESHU_LANG_CSS:
		return eshu_indent_css(src, src_len, cfg, out_len);
	case ESHU_LANG_JS:
		return eshu_indent_js(src, src_len, cfg, out_len);
	case ESHU_LANG_POD:
		return eshu_indent_pod(src, src_len, cfg, out_len);
	default:
		return eshu_indent_c(src, src_len, cfg, out_len);
	}
}

/* ══════════════════════════════════════════════════════════════════
 *  indent_file — process a single file
 * ══════════════════════════════════════════════════════════════════ */

/* opts bitflags */
#define ESHU_OPT_FIX    1
#define ESHU_OPT_DIFF   2

static void eshu_indent_file(const char *path, const eshu_config_t *cfg,
                             const char *force_lang, int opts,
                             eshu_file_result_t *result)
{
	struct stat st;
	FILE *fp;
	char *src;
	size_t src_len, out_len;
	char *fixed;
	const char *lang_str;
	int lang_id;
	eshu_config_t file_cfg;

	eshu_file_result_init(result);
	result->file = strdup(path);

	/* Check file exists and is regular */
	if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) {
		result->status = ESHU_STATUS_ERROR;
		result->error  = strdup("not a readable file");
		return;
	}

	/* Size limit */
	if (st.st_size > ESHU_MAX_FILE_SIZE) {
		result->status = ESHU_STATUS_SKIPPED;
		result->reason = strdup("file too large");
		return;
	}

	/* Read file */
	fp = fopen(path, "rb");
	if (!fp) {
		result->status = ESHU_STATUS_ERROR;
		result->error  = strdup("cannot open file");
		return;
	}
	src_len = (size_t)st.st_size;
	src = (char *)malloc(src_len + 1);
	if (fread(src, 1, src_len, fp) != src_len) {
		fclose(fp);
		free(src);
		result->status = ESHU_STATUS_ERROR;
		result->error  = strdup("read error");
		return;
	}
	fclose(fp);
	src[src_len] = '\0';

	/* Binary detection: NUL in first 8KB */
	if (src_len > 0) {
		size_t check = src_len < ESHU_BINARY_SAMPLE ? src_len : ESHU_BINARY_SAMPLE;
		if (memchr(src, '\0', check) != NULL) {
			free(src);
			result->status = ESHU_STATUS_SKIPPED;
			result->reason = strdup("binary file");
			return;
		}
	}

	/* Detect language */
	lang_str = force_lang ? force_lang : eshu_detect_lang_ext(path);
	if (!lang_str) {
		free(src);
		result->status = ESHU_STATUS_SKIPPED;
		result->reason = strdup("unrecognised extension");
		return;
	}
	lang_id = eshu_lang_from_string(lang_str);
	if (lang_id < 0) {
		free(src);
		result->status = ESHU_STATUS_SKIPPED;
		result->reason = strdup("unrecognised extension");
		return;
	}
	result->lang = strdup(lang_str);

	/* Build config */
	file_cfg = *cfg;
	file_cfg.lang = lang_id;

	/* Indent */
	fixed = eshu_indent_dispatch(src, src_len, &file_cfg, &out_len);

	if (out_len == src_len && memcmp(fixed, src, src_len) == 0) {
		result->status = ESHU_STATUS_UNCHANGED;
	} else {
		result->status = (opts & ESHU_OPT_FIX)
			? ESHU_STATUS_CHANGED : ESHU_STATUS_NEEDS_FIXING;

		if (opts & ESHU_OPT_FIX) {
			fp = fopen(path, "wb");
			if (!fp) {
				result->status = ESHU_STATUS_ERROR;
				result->error  = strdup("cannot write file");
				free(src);
				free(fixed);
				return;
			}
			fwrite(fixed, 1, out_len, fp);
			fclose(fp);
		}
		if (opts & ESHU_OPT_DIFF) {
			result->diff = eshu_simple_diff(path, src, src_len,
			                                fixed, out_len, &result->diff_len);
		}
	}

	free(src);
	free(fixed);
}

/* ══════════════════════════════════════════════════════════════════
 *  Sorted string list (for collecting file paths)
 * ══════════════════════════════════════════════════════════════════ */

typedef struct {
	char  **items;
	size_t  count;
	size_t  cap;
} eshu_strlist_t;

static void eshu_strlist_init(eshu_strlist_t *l) {
	l->cap   = 256;
	l->count = 0;
	l->items = (char **)malloc(l->cap * sizeof(char *));
}

static void eshu_strlist_push(eshu_strlist_t *l, const char *s) {
	if (l->count >= l->cap) {
		l->cap *= 2;
		l->items = (char **)realloc(l->items, l->cap * sizeof(char *));
	}
	l->items[l->count++] = strdup(s);
}

static int eshu_strcmp_ptr(const void *a, const void *b) {
	return strcmp(*(const char **)a, *(const char **)b);
}

static void eshu_strlist_sort(eshu_strlist_t *l) {
	qsort(l->items, l->count, sizeof(char *), eshu_strcmp_ptr);
}

static void eshu_strlist_free(eshu_strlist_t *l) {
	size_t i;
	for (i = 0; i < l->count; i++) free(l->items[i]);
	free(l->items);
	l->items = NULL;
	l->count = l->cap = 0;
}

/* ══════════════════════════════════════════════════════════════════
 *  Recursive directory walk
 * ══════════════════════════════════════════════════════════════════ */

static void eshu_walk_dir(const char *dir_path, eshu_strlist_t *files,
                          int recursive)
{
	DIR *d;
	struct dirent *ent;
	struct stat st;
	char pathbuf[4096];

	d = opendir(dir_path);
	if (!d) return;

	while ((ent = readdir(d)) != NULL) {
		if (ent->d_name[0] == '.') continue;

		snprintf(pathbuf, sizeof(pathbuf), "%s/%s", dir_path, ent->d_name);

		if (lstat(pathbuf, &st) != 0) continue;

		if (S_ISLNK(st.st_mode)) {
			/* Symlink: follow to files only, never to directories */
			struct stat tgt;
			if (stat(pathbuf, &tgt) == 0 && S_ISREG(tgt.st_mode)) {
				eshu_strlist_push(files, pathbuf);
			}
		} else if (S_ISREG(st.st_mode)) {
			eshu_strlist_push(files, pathbuf);
		} else if (recursive && S_ISDIR(st.st_mode)) {
			eshu_walk_dir(pathbuf, files, recursive);
		}
	}
	closedir(d);
}

/* Check if symlinked dir — lstat shows symlink, stat shows dir */
static int eshu_is_symlinked_dir(const char *path) {
	struct stat lst, st;
	if (lstat(path, &lst) != 0) return 0;
	if (!S_ISLNK(lst.st_mode)) return 0;
	if (stat(path, &st) != 0) return 0;
	return S_ISDIR(st.st_mode);
}

/* ══════════════════════════════════════════════════════════════════
 *  indent_dir — process a directory tree
 * ══════════════════════════════════════════════════════════════════ */

/* Note: exclude/include regex filtering is handled at the XSUB level
 * since PCRE/regex matching is more natural from Perl. This C function
 * collects all files and processes them; the XSUB wrapper handles
 * filtering before calling eshu_indent_file for each file. */

#endif /* ESHU_FILE_H */
