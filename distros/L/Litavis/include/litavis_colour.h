#ifndef LITAVIS_COLOUR_H
#define LITAVIS_COLOUR_H

#include "colouring.h"

/* ── Colour function names ────────────────────────────────── */

static int litavis_is_colour_func(const char *name) {
    return (strcmp(name, "lighten") == 0 ||
            strcmp(name, "darken") == 0 ||
            strcmp(name, "saturate") == 0 ||
            strcmp(name, "desaturate") == 0 ||
            strcmp(name, "fade") == 0 ||
            strcmp(name, "fadein") == 0 ||
            strcmp(name, "fadeout") == 0 ||
            strcmp(name, "mix") == 0 ||
            strcmp(name, "tint") == 0 ||
            strcmp(name, "shade") == 0 ||
            strcmp(name, "greyscale") == 0);
}

/* ── Argument parsing ─────────────────────────────────────── */

typedef struct {
    char **args;
    int    count;
} LitavisColourArgs;

/* Split comma-separated args, handling nested parens */
static LitavisColourArgs litavis_parse_colour_args(const char *args_str) {
    LitavisColourArgs result;
    result.args = (char**)malloc(sizeof(char*) * 8);
    if (!result.args) LITAVIS_FATAL("out of memory");
    result.count = 0;

    const char *p = args_str;
    while (*p) {
        /* Skip leading whitespace */
        while (*p == ' ' || *p == '\t') p++;
        if (!*p) break;

        const char *start = p;
        int paren_depth = 0;
        while (*p) {
            if (*p == '(') paren_depth++;
            else if (*p == ')') paren_depth--;
            else if (*p == ',' && paren_depth == 0) break;
            p++;
        }

        /* Trim trailing whitespace */
        const char *end = p;
        while (end > start && (end[-1] == ' ' || end[-1] == '\t'))
            end--;

        if (end > start && result.count < 8) {
            int len = (int)(end - start);
            char *arg = (char*)malloc((size_t)(len + 1));
            if (!arg) LITAVIS_FATAL("out of memory");
            memcpy(arg, start, (size_t)len);
            arg[len] = '\0';
            result.args[result.count++] = arg;
        }

        if (*p == ',') p++;
    }
    return result;
}

static void litavis_colour_args_free(LitavisColourArgs *args) {
    int i;
    for (i = 0; i < args->count; i++)
        free(args->args[i]);
    free(args->args);
    args->args = NULL;
    args->count = 0;
}

/* ── Forward declaration for recursion ────────────────────── */

static char* litavis_eval_colour_value(const char *value);

/* ── Evaluate a single colour function call ───────────────── */

static char* litavis_eval_colour_func(const char *func_name, const char *args_str) {
    LitavisColourArgs parsed = litavis_parse_colour_args(args_str);
    colouring_rgba_t result;
    int ok = 0;
    char buf[32];

    /* Recursively resolve any nested colour functions in arguments */
    int i;
    for (i = 0; i < parsed.count; i++) {
        if (strchr(parsed.args[i], '(')) {
            char *resolved = litavis_eval_colour_value(parsed.args[i]);
            free(parsed.args[i]);
            parsed.args[i] = resolved;
        }
    }

    if (strcmp(func_name, "lighten") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_lighten(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "darken") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_darken(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "saturate") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_saturate(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "desaturate") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_desaturate(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "fade") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_fade(c.r, c.g, c.b, c.a, amount);
            ok = 1;
        }
    } else if (strcmp(func_name, "fadein") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_fadein(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "fadeout") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            double amount = colouring_depercent(parsed.args[1]);
            result = colouring_fadeout(c.r, c.g, c.b, c.a, amount, 0);
            ok = 1;
        }
    } else if (strcmp(func_name, "greyscale") == 0 && parsed.count >= 1) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            result = colouring_greyscale(c.r, c.g, c.b, c.a);
            ok = 1;
        }
    } else if (strcmp(func_name, "mix") == 0 && parsed.count >= 2) {
        colouring_rgba_t c1, c2;
        if (colouring_parse(parsed.args[0], &c1) && colouring_parse(parsed.args[1], &c2)) {
            int weight = parsed.count >= 3 ? atoi(parsed.args[2]) : 50;
            result = colouring_mix(c1, c2, weight);
            ok = 1;
        }
    } else if (strcmp(func_name, "tint") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            int weight = atoi(parsed.args[1]);
            result = colouring_tint(c, weight);
            ok = 1;
        }
    } else if (strcmp(func_name, "shade") == 0 && parsed.count >= 2) {
        colouring_rgba_t c;
        if (colouring_parse(parsed.args[0], &c)) {
            int weight = atoi(parsed.args[1]);
            result = colouring_shade(c, weight);
            ok = 1;
        }
    }

    litavis_colour_args_free(&parsed);

    if (ok) {
        if (result.a < 1.0) {
            colouring_fmt_rgba(result, buf, sizeof(buf));
        } else {
            colouring_fmt_hex(result, buf, sizeof(buf), 0);
        }
        return litavis_strdup(buf);
    }

    /* Not a valid colour function call — return original as-is */
    return NULL;
}

/* ── Evaluate colour functions within a value string ──────── */

static char* litavis_eval_colour_value(const char *value) {
    char buf[8192];
    int bpos = 0;
    const char *p = value;

    while (*p && bpos < 8100) {
        /* Check for a colour function: identifier( */
        if (isalpha((unsigned char)*p)) {
            const char *name_start = p;
            while (*p && (isalpha((unsigned char)*p) || *p == '_'))
                p++;
            int name_len = (int)(p - name_start);

            if (*p == '(') {
                char func_name[64];
                if (name_len > 63) name_len = 63;
                memcpy(func_name, name_start, (size_t)name_len);
                func_name[name_len] = '\0';

                if (litavis_is_colour_func(func_name)) {
                    /* Find matching close paren */
                    const char *args_start = p + 1;
                    int depth = 1;
                    p++;
                    while (*p && depth > 0) {
                        if (*p == '(') depth++;
                        else if (*p == ')') depth--;
                        if (depth > 0) p++;
                    }
                    /* p points at closing ')' */
                    int args_len = (int)(p - args_start);
                    char *args_str = (char*)malloc((size_t)(args_len + 1));
                    if (!args_str) LITAVIS_FATAL("out of memory");
                    memcpy(args_str, args_start, (size_t)args_len);
                    args_str[args_len] = '\0';

                    char *result = litavis_eval_colour_func(func_name, args_str);
                    free(args_str);

                    if (result) {
                        int rlen = (int)strlen(result);
                        if (bpos + rlen < 8192) {
                            memcpy(buf + bpos, result, (size_t)rlen);
                            bpos += rlen;
                        }
                        free(result);
                        if (*p == ')') p++;
                        continue;
                    }
                    /* Not a valid colour call — copy original text */
                    if (bpos + name_len + 1 + args_len + 1 < 8192) {
                        memcpy(buf + bpos, name_start, (size_t)name_len);
                        bpos += name_len;
                        buf[bpos++] = '(';
                        memcpy(buf + bpos, args_start, (size_t)args_len);
                        bpos += args_len;
                        buf[bpos++] = ')';
                    }
                    if (*p == ')') p++;
                    continue;
                }
                /* Not a colour function — copy name + continue (don't consume parens) */
                if (bpos + name_len < 8192) {
                    memcpy(buf + bpos, name_start, (size_t)name_len);
                    bpos += name_len;
                }
                /* p still points at '(' — let it be copied normally */
                continue;
            }
            /* Bare identifier (no parens) — copy it */
            if (bpos + name_len < 8192) {
                memcpy(buf + bpos, name_start, (size_t)name_len);
                bpos += name_len;
            }
            continue;
        }
        buf[bpos++] = *p++;
    }
    buf[bpos] = '\0';
    return litavis_strdup(buf);
}

/* ── Main entry point: resolve all colour functions in AST ── */

static void litavis_resolve_colours(LitavisAST *ast) {
    int i, j;
    for (i = 0; i < ast->count; i++) {
        LitavisRule *rule = &ast->rules[i];
        for (j = 0; j < rule->prop_count; j++) {
            /* Only process values that might contain colour functions */
            if (strchr(rule->props[j].value, '(')) {
                char *resolved = litavis_eval_colour_value(rule->props[j].value);
                if (strcmp(resolved, rule->props[j].value) != 0) {
                    free(rule->props[j].value);
                    rule->props[j].value = resolved;
                } else {
                    free(resolved);
                }
            }
        }
    }
}

#endif /* LITAVIS_COLOUR_H */
