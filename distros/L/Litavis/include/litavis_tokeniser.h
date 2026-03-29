#ifndef LITAVIS_TOKENISER_H
#define LITAVIS_TOKENISER_H

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* ── Token types ──────────────────────────────────────────── */

typedef enum {
    LITAVIS_T_SELECTOR,        /* .class, #id, element, *, [attr] */
    LITAVIS_T_LBRACE,          /* { */
    LITAVIS_T_RBRACE,          /* } */
    LITAVIS_T_PROPERTY,        /* property-name (before :) */
    LITAVIS_T_COLON,           /* : */
    LITAVIS_T_VALUE,           /* property value (up to ;) */
    LITAVIS_T_SEMICOLON,       /* ; */
    LITAVIS_T_COMMA,           /* , */
    LITAVIS_T_AT_KEYWORD,      /* @media, @keyframes, @layer, @supports, etc. */
    LITAVIS_T_AT_PRELUDE,      /* text between @keyword and { or ; */
    LITAVIS_T_COMMENT,         /* block comment */
    LITAVIS_T_LINE_COMMENT,    /* // single-line comment */
    LITAVIS_T_PREPROC_VAR_DEF, /* $varname: value; */
    LITAVIS_T_PREPROC_VAR_REF, /* $varname in a value context */
    LITAVIS_T_CSS_VAR_DEF,     /* --custom-property (as property name) */
    LITAVIS_T_FUNCTION,        /* identifier( ... ) including nested parens */
    LITAVIS_T_MIXIN_DEF,       /* %name: ( ... ); */
    LITAVIS_T_MIXIN_REF,       /* %name; */
    LITAVIS_T_AMPERSAND,       /* & parent selector reference */
    LITAVIS_T_STRING,          /* "..." or '...' */
    LITAVIS_T_WS,              /* whitespace run */
    LITAVIS_T_EOF
} LitavisTokenType;

/* ── Token ────────────────────────────────────────────────── */

typedef struct {
    LitavisTokenType  type;
    const char    *start;   /* pointer into source buffer (no copy) */
    int            length;  /* byte length */
    int            line;    /* 1-based line number */
    int            col;     /* 1-based column */
} LitavisToken;

/* ── Token list ───────────────────────────────────────────── */

typedef struct {
    LitavisToken *tokens;
    int        count;
    int        capacity;
} LitavisTokenList;

/* ── Token list operations ────────────────────────────────── */

static LitavisTokenList* litavis_token_list_new(int initial_cap) {
    LitavisTokenList *list = (LitavisTokenList*)malloc(sizeof(LitavisTokenList));
    if (!list) LITAVIS_FATAL("out of memory");
    if (initial_cap < 64) initial_cap = 64;
    list->tokens = (LitavisToken*)malloc(sizeof(LitavisToken) * (size_t)initial_cap);
    if (!list->tokens) LITAVIS_FATAL("out of memory");
    list->count = 0;
    list->capacity = initial_cap;
    return list;
}

static void litavis_token_list_free(LitavisTokenList *list) {
    if (!list) return;
    if (list->tokens) free(list->tokens);
    free(list);
}

static void litavis_token_push(LitavisTokenList *list, LitavisTokenType type,
                            const char *start, int length, int line, int col) {
    if (list->count >= list->capacity) {
        int new_cap = list->capacity * 2;
        LitavisToken *new_tokens = (LitavisToken*)realloc(list->tokens, sizeof(LitavisToken) * (size_t)new_cap);
        if (!new_tokens) LITAVIS_FATAL("out of memory");
        list->tokens = new_tokens;
        list->capacity = new_cap;
    }
    list->tokens[list->count].type   = type;
    list->tokens[list->count].start  = start;
    list->tokens[list->count].length = length;
    list->tokens[list->count].line   = line;
    list->tokens[list->count].col    = col;
    list->count++;
}

/* ── Internal helpers ─────────────────────────────────────── */

static int litavis_is_ident_char(char c) {
    return isalnum((unsigned char)c) || c == '-' || c == '_';
}

static int litavis_is_selector_char(char c) {
    return c != '{' && c != '}' && c != ';' && c != '\0';
}

/* Skip whitespace, updating line/col */
static void litavis_skip_ws(const char *input, int len, int *pos, int *line, int *col) {
    while (*pos < len) {
        char c = input[*pos];
        if (c == '\n') {
            (*pos)++;
            (*line)++;
            *col = 1;
        } else if (c == ' ' || c == '\t' || c == '\r' || c == '\f') {
            (*pos)++;
            (*col)++;
        } else {
            break;
        }
    }
}

/* Advance pos by n, updating col */
static void litavis_advance(int *pos, int *col, int n) {
    *pos += n;
    *col += n;
}

/* Scan a quoted string (handles escape sequences) */
static int litavis_scan_string(const char *input, int len, int pos) {
    char quote = input[pos];
    pos++;
    while (pos < len) {
        if (input[pos] == '\\' && pos + 1 < len) {
            pos += 2; /* skip escape */
        } else if (input[pos] == quote) {
            return pos + 1; /* past closing quote */
        } else {
            pos++;
        }
    }
    return pos; /* unterminated string — return what we have */
}

/* Scan balanced parentheses */
static int litavis_scan_parens(const char *input, int len, int pos) {
    int depth = 0;
    while (pos < len) {
        char c = input[pos];
        if (c == '(') {
            depth++;
        } else if (c == ')') {
            depth--;
            if (depth <= 0) return pos + 1;
        } else if (c == '"' || c == '\'') {
            pos = litavis_scan_string(input, len, pos);
            continue;
        }
        pos++;
    }
    return pos;
}

/* Scan an identifier (letters, digits, hyphens, underscores) */
static int litavis_scan_ident(const char *input, int len, int pos) {
    while (pos < len && litavis_is_ident_char(input[pos]))
        pos++;
    return pos;
}

/* ── Main tokeniser ───────────────────────────────────────── */

static LitavisTokenList* litavis_tokenise(const char *input, int len) {
    LitavisTokenList *list = litavis_token_list_new(128);
    int pos = 0, line = 1, col = 1;
    int brace_depth = 0;
    int expecting_value = 0; /* 1 after seeing PROPERTY + COLON */

    while (pos < len) {
        /* Skip whitespace */
        int ws_start = pos;
        litavis_skip_ws(input, len, &pos, &line, &col);
        if (pos >= len) break;

        char c = input[pos];

        /* ── Block comments ── */
        if (c == '/' && pos + 1 < len && input[pos + 1] == '*') {
            int start = pos;
            int start_line = line, start_col = col;
            pos += 2; col += 2;
            while (pos + 1 < len && !(input[pos] == '*' && input[pos + 1] == '/')) {
                if (input[pos] == '\n') { line++; col = 1; }
                else { col++; }
                pos++;
            }
            if (pos + 1 < len) { pos += 2; col += 2; }
            /* Skip comments — don't emit */
            continue;
        }

        /* ── Line comments ── */
        if (c == '/' && pos + 1 < len && input[pos + 1] == '/') {
            int start = pos;
            int start_line = line, start_col = col;
            while (pos < len && input[pos] != '\n')
                pos++;
            /* Skip line comments — don't emit */
            col = 1;
            continue;
        }

        /* ── Braces ── */
        if (c == '{') {
            litavis_token_push(list, LITAVIS_T_LBRACE, &input[pos], 1, line, col);
            litavis_advance(&pos, &col, 1);
            brace_depth++;
            expecting_value = 0;
            continue;
        }
        if (c == '}') {
            litavis_token_push(list, LITAVIS_T_RBRACE, &input[pos], 1, line, col);
            litavis_advance(&pos, &col, 1);
            brace_depth--;
            expecting_value = 0;
            continue;
        }

        /* ── Semicolons ── */
        if (c == ';') {
            litavis_token_push(list, LITAVIS_T_SEMICOLON, &input[pos], 1, line, col);
            litavis_advance(&pos, &col, 1);
            expecting_value = 0;
            continue;
        }

        /* ── Commas ── */
        if (c == ',') {
            litavis_token_push(list, LITAVIS_T_COMMA, &input[pos], 1, line, col);
            litavis_advance(&pos, &col, 1);
            continue;
        }

        /* ── @-rules ── */
        if (c == '@') {
            int start = pos;
            int start_col = col;
            litavis_advance(&pos, &col, 1); /* skip @ */
            int kw_end = litavis_scan_ident(input, len, pos);
            int kw_len = kw_end - start;
            litavis_token_push(list, LITAVIS_T_AT_KEYWORD, &input[start], kw_len, line, start_col);
            pos = kw_end;
            col = start_col + kw_len;

            /* Scan prelude — everything up to { or ; */
            litavis_skip_ws(input, len, &pos, &line, &col);
            if (pos < len && input[pos] != '{' && input[pos] != ';') {
                int pl_start = pos;
                int pl_line = line, pl_col = col;
                while (pos < len && input[pos] != '{' && input[pos] != ';') {
                    if (input[pos] == '(') {
                        pos = litavis_scan_parens(input, len, pos);
                        col = pl_col + (pos - pl_start);
                    } else if (input[pos] == '"' || input[pos] == '\'') {
                        pos = litavis_scan_string(input, len, pos);
                        col = pl_col + (pos - pl_start);
                    } else if (input[pos] == '\n') {
                        pos++; line++; col = 1;
                    } else {
                        pos++; col++;
                    }
                }
                /* Trim trailing whitespace from prelude */
                int pl_end = pos;
                while (pl_end > pl_start && (input[pl_end - 1] == ' ' || input[pl_end - 1] == '\t'
                       || input[pl_end - 1] == '\r' || input[pl_end - 1] == '\n'))
                    pl_end--;
                if (pl_end > pl_start)
                    litavis_token_push(list, LITAVIS_T_AT_PRELUDE, &input[pl_start], pl_end - pl_start, pl_line, pl_col);
            }
            continue;
        }

        /* ── Preprocessor variables ($var) ── */
        if (c == '$' && !expecting_value) {
            int start = pos;
            int start_col = col;
            litavis_advance(&pos, &col, 1); /* skip $ */
            int name_end = litavis_scan_ident(input, len, pos);
            if (name_end == pos) {
                /* lone $ — treat as part of selector */
                goto parse_selector;
            }
            pos = name_end;
            col = start_col + (pos - start);

            /* Check if this is a definition ($var: value;) or a map ref ($var{key}) */
            int saved_pos = pos, saved_line = line, saved_col = col;
            litavis_skip_ws(input, len, &pos, &line, &col);
            if (pos < len && input[pos] == ':') {
                /* $var: value; — definition */
                litavis_advance(&pos, &col, 1); /* skip : */
                litavis_skip_ws(input, len, &pos, &line, &col);
                int val_start = pos;
                int val_line = line, val_col = col;
                /* Scan value up to ; */
                while (pos < len && input[pos] != ';') {
                    if (input[pos] == '(') {
                        pos = litavis_scan_parens(input, len, pos);
                    } else if (input[pos] == '"' || input[pos] == '\'') {
                        pos = litavis_scan_string(input, len, pos);
                    } else if (input[pos] == '\n') {
                        pos++; line++; col = 1;
                    } else {
                        pos++; col++;
                    }
                }
                int val_end = pos;
                /* Trim trailing ws */
                while (val_end > val_start && (input[val_end - 1] == ' ' || input[val_end - 1] == '\t'))
                    val_end--;
                /* Emit: var name token (includes $), then value */
                litavis_token_push(list, LITAVIS_T_PREPROC_VAR_DEF, &input[start], name_end - start, line, start_col);
                if (val_end > val_start)
                    litavis_token_push(list, LITAVIS_T_VALUE, &input[val_start], val_end - val_start, val_line, val_col);
                if (pos < len && input[pos] == ';') {
                    litavis_token_push(list, LITAVIS_T_SEMICOLON, &input[pos], 1, line, col);
                    litavis_advance(&pos, &col, 1);
                }
            } else {
                /* $var reference in value or selector */
                pos = saved_pos;
                line = saved_line;
                col = saved_col;
                litavis_token_push(list, LITAVIS_T_PREPROC_VAR_REF, &input[start], name_end - start, line, start_col);
            }
            expecting_value = 0;
            continue;
        }

        /* ── Mixin syntax (%name) ── */
        if (c == '%' && !expecting_value) {
            int start = pos;
            int start_col = col;
            litavis_advance(&pos, &col, 1); /* skip % */
            int name_end = litavis_scan_ident(input, len, pos);
            if (name_end == pos) {
                goto parse_selector;
            }
            pos = name_end;
            col = start_col + (pos - start);

            int saved_pos = pos, saved_line = line, saved_col = col;
            litavis_skip_ws(input, len, &pos, &line, &col);
            if (pos < len && input[pos] == ':') {
                /* %name: (...); — mixin definition */
                litavis_advance(&pos, &col, 1); /* skip : */
                litavis_skip_ws(input, len, &pos, &line, &col);
                if (pos < len && input[pos] == '(') {
                    int body_start = pos;
                    int body_line = line, body_col = col;
                    pos = litavis_scan_parens(input, len, pos);
                    col = body_col + (pos - body_start);
                    litavis_token_push(list, LITAVIS_T_MIXIN_DEF, &input[start], name_end - start, body_line, start_col);
                    /* Emit the body content (inside parens) as VALUE */
                    if (pos - body_start - 2 > 0)
                        litavis_token_push(list, LITAVIS_T_VALUE, &input[body_start + 1], pos - body_start - 2, body_line, body_col + 1);
                    litavis_skip_ws(input, len, &pos, &line, &col);
                    if (pos < len && input[pos] == ';') {
                        litavis_token_push(list, LITAVIS_T_SEMICOLON, &input[pos], 1, line, col);
                        litavis_advance(&pos, &col, 1);
                    }
                } else {
                    /* %name: value; — treat as mixin def with inline value */
                    int val_start = pos;
                    int val_col = col;
                    while (pos < len && input[pos] != ';' && input[pos] != '}') {
                        if (input[pos] == '\n') { pos++; line++; col = 1; }
                        else { pos++; col++; }
                    }
                    litavis_token_push(list, LITAVIS_T_MIXIN_DEF, &input[start], name_end - start, line, start_col);
                    if (pos > val_start)
                        litavis_token_push(list, LITAVIS_T_VALUE, &input[val_start], pos - val_start, line, val_col);
                    if (pos < len && input[pos] == ';') {
                        litavis_token_push(list, LITAVIS_T_SEMICOLON, &input[pos], 1, line, col);
                        litavis_advance(&pos, &col, 1);
                    }
                }
            } else {
                /* %name — mixin reference */
                pos = saved_pos;
                line = saved_line;
                col = saved_col;
                litavis_token_push(list, LITAVIS_T_MIXIN_REF, &input[start], name_end - start, line, start_col);
            }
            expecting_value = 0;
            continue;
        }

        /* ── Ampersand (parent reference) ── */
        if (c == '&') {
            /* Scan & plus any attached selector suffix (&:hover, &.class, &-mod)
               then the rest up to { as a combined selector */
            int start = pos;
            int start_col = col;
            /* Jump to selector parsing which will capture & and everything up to { */
            goto parse_selector;
        }

        /* ── Strings (only in selector context, not when expecting a value) ── */
        if ((c == '"' || c == '\'') && !expecting_value) {
            int start = pos;
            int start_col = col;
            int end = litavis_scan_string(input, len, pos);
            litavis_token_push(list, LITAVIS_T_STRING, &input[start], end - start, line, start_col);
            col += (end - start);
            pos = end;
            continue;
        }

        /* ── Inside a declaration block: parse property/value ── */
        if (brace_depth > 0 && !expecting_value) {
            /* Could be a nested selector or a property name */
            /* Look ahead to determine: if we see ':' before '{' or '}', it's a property */
            int scan = pos;
            int found_colon = 0, found_brace = 0;
            int paren_d = 0;
            while (scan < len) {
                char sc = input[scan];
                if (sc == '(') { paren_d++; scan++; continue; }
                if (sc == ')') { paren_d--; scan++; continue; }
                if (paren_d > 0) { scan++; continue; }
                if (sc == '"' || sc == '\'') {
                    scan = litavis_scan_string(input, len, scan);
                    continue;
                }
                if (sc == ':' && scan + 1 < len && input[scan + 1] == ':') {
                    /* :: is a pseudo-element, not property separator */
                    scan += 2;
                    continue;
                }
                if (sc == ':') {
                    /* Check if this is a pseudo-class/element: if preceded by ident chars
                       and followed by ident, it's :hover, :nth-child, etc. */
                    if (scan + 1 < len && (isalpha((unsigned char)input[scan + 1]) || input[scan + 1] == ':')) {
                        /* Could still be a property... check if there's a { or ; after */
                        /* Heuristic: if the thing before : contains selector-like chars (.#&*[>~+)
                           it's a selector pseudo-class, not a property */
                        int has_selector_chars = 0;
                        int k;
                        for (k = pos; k < scan; k++) {
                            if (input[k] == '.' || input[k] == '#' || input[k] == '&'
                                || input[k] == '*' || input[k] == '[' || input[k] == '>'
                                || input[k] == '~' || input[k] == '+') {
                                has_selector_chars = 1;
                                break;
                            }
                        }
                        if (has_selector_chars) {
                            scan++;
                            continue;
                        }
                    }
                    found_colon = 1;
                    break;
                }
                if (sc == '{' || sc == '}' || sc == ';') {
                    found_brace = 1;
                    break;
                }
                if (sc == '\n') { scan++; continue; }
                scan++;
            }

            if (found_colon && !found_brace) {
                /* It's a property: name */
                int prop_start = pos;
                int prop_col = col;
                /* Scan property name up to : */
                while (pos < len && input[pos] != ':') {
                    pos++; col++;
                }
                int prop_end = pos;
                /* Trim trailing ws from property name */
                while (prop_end > prop_start && (input[prop_end - 1] == ' ' || input[prop_end - 1] == '\t'))
                    prop_end--;

                /* Check for --custom-property */
                if (prop_end - prop_start >= 2 && input[prop_start] == '-' && input[prop_start + 1] == '-')
                    litavis_token_push(list, LITAVIS_T_CSS_VAR_DEF, &input[prop_start], prop_end - prop_start, line, prop_col);
                else
                    litavis_token_push(list, LITAVIS_T_PROPERTY, &input[prop_start], prop_end - prop_start, line, prop_col);

                /* Emit colon */
                if (pos < len && input[pos] == ':') {
                    litavis_token_push(list, LITAVIS_T_COLON, &input[pos], 1, line, col);
                    litavis_advance(&pos, &col, 1);
                }
                expecting_value = 1;
                continue;
            }

            /* Otherwise it's a nested selector — fall through to selector parsing */
        }

        if (expecting_value) {
            /* Scan value: up to ; or } */
            int val_start = pos;
            int val_col = col;
            int val_line = line;
            litavis_skip_ws(input, len, &pos, &line, &col);
            val_start = pos;
            val_col = col;
            val_line = line;

            {
                int val_brace_depth = 0;
                while (pos < len) {
                    if (input[pos] == ';' && val_brace_depth == 0) break;
                    if (input[pos] == '}' && val_brace_depth == 0) break;
                    if (input[pos] == '{') {
                        val_brace_depth++;
                        pos++; col++;
                    } else if (input[pos] == '}') {
                        val_brace_depth--;
                        pos++; col++;
                    } else if (input[pos] == '(') {
                        pos = litavis_scan_parens(input, len, pos);
                        col = val_col + (pos - val_start);
                    } else if (input[pos] == '"' || input[pos] == '\'') {
                        pos = litavis_scan_string(input, len, pos);
                        col = val_col + (pos - val_start);
                    } else if (input[pos] == '\n') {
                        pos++; line++; col = 1;
                    } else {
                        pos++; col++;
                    }
                }
            }
            int val_end = pos;
            /* Trim trailing ws */
            while (val_end > val_start && (input[val_end - 1] == ' ' || input[val_end - 1] == '\t'
                   || input[val_end - 1] == '\r' || input[val_end - 1] == '\n'))
                val_end--;
            if (val_end > val_start)
                litavis_token_push(list, LITAVIS_T_VALUE, &input[val_start], val_end - val_start, val_line, val_col);

            expecting_value = 0;
            continue;
        }

        /* ── Selector context ── */
        parse_selector: {
            int sel_start = pos;
            int sel_col = col;
            int sel_line = line;

            while (pos < len) {
                char sc = input[pos];
                if (sc == '{' || sc == ';' || sc == '}') break;
                if (sc == ',') break;
                if (sc == '/' && pos + 1 < len && (input[pos + 1] == '/' || input[pos + 1] == '*')) break;
                if (sc == '"' || sc == '\'') {
                    pos = litavis_scan_string(input, len, pos);
                    col = sel_col + (pos - sel_start);
                    continue;
                }
                if (sc == '(') {
                    pos = litavis_scan_parens(input, len, pos);
                    col = sel_col + (pos - sel_start);
                    continue;
                }
                if (sc == '\n') {
                    pos++; line++; col = 1;
                    continue;
                }
                pos++; col++;
            }

            int sel_end = pos;
            /* Trim trailing ws */
            while (sel_end > sel_start && (input[sel_end - 1] == ' ' || input[sel_end - 1] == '\t'
                   || input[sel_end - 1] == '\r' || input[sel_end - 1] == '\n'))
                sel_end--;

            if (sel_end > sel_start) {
                litavis_token_push(list, LITAVIS_T_SELECTOR, &input[sel_start], sel_end - sel_start, sel_line, sel_col);
            }
        }
    }

    litavis_token_push(list, LITAVIS_T_EOF, &input[pos > len ? len : pos], 0, line, col);
    return list;
}

#endif /* LITAVIS_TOKENISER_H */
