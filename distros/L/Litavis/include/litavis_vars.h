#ifndef LITAVIS_VARS_H
#define LITAVIS_VARS_H

/* ── Variable scope ───────────────────────────────────────── */

typedef struct LitavisVar {
    char *name;     /* variable name (without $) */
    char *value;    /* resolved string value */
} LitavisVar;

typedef struct LitavisVarScope {
    LitavisVar             *vars;
    int                  count;
    int                  capacity;
    struct LitavisVarScope *parent;   /* lexical parent scope */
} LitavisVarScope;

/* ── Map variable (named key-value store) ────────────────── */

typedef struct LitavisMapEntry {
    char *key;
    char *value;
} LitavisMapEntry;

typedef struct LitavisMapVar {
    char          *name;       /* map name (without %) */
    LitavisMapEntry  *entries;
    int            count;
    int            capacity;
} LitavisMapVar;

typedef struct LitavisMapStore {
    LitavisMapVar *maps;
    int         count;
    int         capacity;
} LitavisMapStore;

/* ── Mixin (named property set) ───────────────────────────── */

typedef struct LitavisMixin {
    char      *name;        /* mixin name (without %) */
    LitavisProp  *props;       /* ordered properties */
    int        prop_count;
    int        prop_cap;
} LitavisMixin;

typedef struct LitavisMixinStore {
    LitavisMixin *mixins;
    int        count;
    int        capacity;
} LitavisMixinStore;

/* ── Scope lifecycle ──────────────────────────────────────── */

static LitavisVarScope* litavis_scope_new(LitavisVarScope *parent) {
    LitavisVarScope *s = (LitavisVarScope*)malloc(sizeof(LitavisVarScope));
    if (!s) LITAVIS_FATAL("out of memory");
    s->vars     = NULL;
    s->count    = 0;
    s->capacity = 0;
    s->parent   = parent;
    return s;
}

static void litavis_scope_free(LitavisVarScope *scope) {
    int i;
    if (!scope) return;
    for (i = 0; i < scope->count; i++) {
        free(scope->vars[i].name);
        free(scope->vars[i].value);
    }
    if (scope->vars) free(scope->vars);
    free(scope);
}

/* ── Scope set/get ────────────────────────────────────────── */

static void litavis_scope_set(LitavisVarScope *scope, const char *name, const char *value) {
    int i;
    /* Update if already exists in this scope */
    for (i = 0; i < scope->count; i++) {
        if (strcmp(scope->vars[i].name, name) == 0) {
            free(scope->vars[i].value);
            scope->vars[i].value = litavis_strdup(value);
            return;
        }
    }
    /* Add new */
    if (scope->count >= scope->capacity) {
        int new_cap = scope->capacity < 8 ? 8 : scope->capacity * 2;
        LitavisVar *nv = (LitavisVar*)realloc(scope->vars, sizeof(LitavisVar) * (size_t)new_cap);
        if (!nv) LITAVIS_FATAL("out of memory");
        scope->vars = nv;
        scope->capacity = new_cap;
    }
    scope->vars[scope->count].name  = litavis_strdup(name);
    scope->vars[scope->count].value = litavis_strdup(value);
    scope->count++;
}

/* Walk parent chain to find variable */
static char* litavis_scope_get(LitavisVarScope *scope, const char *name) {
    int i;
    LitavisVarScope *s = scope;
    while (s) {
        for (i = 0; i < s->count; i++) {
            if (strcmp(s->vars[i].name, name) == 0)
                return s->vars[i].value;
        }
        s = s->parent;
    }
    return NULL;
}

/* ── Mixin store ──────────────────────────────────────────── */

static LitavisMixinStore* litavis_mixin_store_new(void) {
    LitavisMixinStore *s = (LitavisMixinStore*)malloc(sizeof(LitavisMixinStore));
    if (!s) LITAVIS_FATAL("out of memory");
    s->mixins   = NULL;
    s->count    = 0;
    s->capacity = 0;
    return s;
}

static void litavis_mixin_store_free(LitavisMixinStore *store) {
    int i, j;
    if (!store) return;
    for (i = 0; i < store->count; i++) {
        free(store->mixins[i].name);
        for (j = 0; j < store->mixins[i].prop_count; j++) {
            free(store->mixins[i].props[j].key);
            free(store->mixins[i].props[j].value);
        }
        if (store->mixins[i].props) free(store->mixins[i].props);
    }
    if (store->mixins) free(store->mixins);
    free(store);
}

static void litavis_mixin_define(LitavisMixinStore *store, const char *name,
                              LitavisProp *props, int prop_count) {
    int i;
    if (store->count >= store->capacity) {
        int new_cap = store->capacity < 4 ? 4 : store->capacity * 2;
        LitavisMixin *nm = (LitavisMixin*)realloc(store->mixins, sizeof(LitavisMixin) * (size_t)new_cap);
        if (!nm) LITAVIS_FATAL("out of memory");
        store->mixins = nm;
        store->capacity = new_cap;
    }
    LitavisMixin *m = &store->mixins[store->count++];
    m->name = litavis_strdup(name);
    m->prop_count = prop_count;
    m->prop_cap   = prop_count;
    m->props = (LitavisProp*)malloc(sizeof(LitavisProp) * (size_t)(prop_count > 0 ? prop_count : 1));
    if (!m->props) LITAVIS_FATAL("out of memory");
    for (i = 0; i < prop_count; i++) {
        m->props[i].key   = litavis_strdup(props[i].key);
        m->props[i].value = litavis_strdup(props[i].value);
    }
}

static LitavisMixin* litavis_mixin_get(LitavisMixinStore *store, const char *name) {
    int i;
    for (i = 0; i < store->count; i++) {
        if (strcmp(store->mixins[i].name, name) == 0)
            return &store->mixins[i];
    }
    return NULL;
}

/* ── Map store ────────────────────────────────────────────── */

static LitavisMapStore* litavis_map_store_new(void) {
    LitavisMapStore *s = (LitavisMapStore*)malloc(sizeof(LitavisMapStore));
    if (!s) LITAVIS_FATAL("out of memory");
    s->maps     = NULL;
    s->count    = 0;
    s->capacity = 0;
    return s;
}

static void litavis_map_store_free(LitavisMapStore *store) {
    int i, j;
    if (!store) return;
    for (i = 0; i < store->count; i++) {
        free(store->maps[i].name);
        for (j = 0; j < store->maps[i].count; j++) {
            free(store->maps[i].entries[j].key);
            free(store->maps[i].entries[j].value);
        }
        if (store->maps[i].entries) free(store->maps[i].entries);
    }
    if (store->maps) free(store->maps);
    free(store);
}

static void litavis_map_define(LitavisMapStore *store, const char *name,
                            LitavisMapEntry *entries, int count) {
    int i;
    if (store->count >= store->capacity) {
        int new_cap = store->capacity < 4 ? 4 : store->capacity * 2;
        LitavisMapVar *nm = (LitavisMapVar*)realloc(store->maps, sizeof(LitavisMapVar) * (size_t)new_cap);
        if (!nm) LITAVIS_FATAL("out of memory");
        store->maps = nm;
        store->capacity = new_cap;
    }
    LitavisMapVar *m = &store->maps[store->count++];
    m->name     = litavis_strdup(name);
    m->count    = count;
    m->capacity = count;
    m->entries  = (LitavisMapEntry*)malloc(sizeof(LitavisMapEntry) * (size_t)(count > 0 ? count : 1));
    if (!m->entries) LITAVIS_FATAL("out of memory");
    for (i = 0; i < count; i++) {
        m->entries[i].key   = litavis_strdup(entries[i].key);
        m->entries[i].value = litavis_strdup(entries[i].value);
    }
}

static char* litavis_map_get(LitavisMapStore *store, const char *name, const char *key) {
    int i, j;
    for (i = 0; i < store->count; i++) {
        if (strcmp(store->maps[i].name, name) == 0) {
            for (j = 0; j < store->maps[i].count; j++) {
                if (strcmp(store->maps[i].entries[j].key, key) == 0)
                    return store->maps[i].entries[j].value;
            }
        }
    }
    return NULL;
}

/* ── Value resolution ─────────────────────────────────────── */

/*
 * Resolve $var and $map{key} references within a value string.
 * Returns a new allocated string. Caller must free.
 */
static char* litavis_resolve_value(const char *value, LitavisVarScope *scope,
                                LitavisMapStore *maps) {
    char buf[8192];
    int bpos = 0;
    const char *p = value;

    while (*p && bpos < 8100) {
        if (*p == '$') {
            /* Scan variable name */
            const char *name_start = p + 1;
            const char *name_end = name_start;
            while (*name_end && (isalnum((unsigned char)*name_end) || *name_end == '-' || *name_end == '_'))
                name_end++;

            if (name_end > name_start) {
                int name_len = (int)(name_end - name_start);
                char name[256];
                if (name_len > 255) name_len = 255;
                memcpy(name, name_start, (size_t)name_len);
                name[name_len] = '\0';

                /* Check for map access: $name{key} */
                if (*name_end == '{') {
                    const char *key_start = name_end + 1;
                    const char *key_end = key_start;
                    while (*key_end && *key_end != '}')
                        key_end++;
                    if (*key_end == '}') {
                        int key_len = (int)(key_end - key_start);
                        char key[256];
                        if (key_len > 255) key_len = 255;
                        memcpy(key, key_start, (size_t)key_len);
                        key[key_len] = '\0';

                        char *map_val = maps ? litavis_map_get(maps, name, key) : NULL;
                        if (map_val) {
                            int vlen = (int)strlen(map_val);
                            if (bpos + vlen < 8192) {
                                memcpy(buf + bpos, map_val, (size_t)vlen);
                                bpos += vlen;
                            }
                            p = key_end + 1;
                            continue;
                        }
                    }
                }

                /* Simple variable lookup */
                char *var_val = litavis_scope_get(scope, name);
                if (var_val) {
                    int vlen = (int)strlen(var_val);
                    if (bpos + vlen < 8192) {
                        memcpy(buf + bpos, var_val, (size_t)vlen);
                        bpos += vlen;
                    }
                    p = name_end;
                    continue;
                }
            }
            /* Not a recognized variable — copy $ literally */
            buf[bpos++] = *p++;
        } else {
            buf[bpos++] = *p++;
        }
    }
    buf[bpos] = '\0';
    return litavis_strdup(buf);
}

/* ── Parse mixin body into properties ─────────────────────── */

/*
 * Parse a mixin body string like "border-top: dotted 1px black; border-bottom: solid 2px black"
 * into LitavisProp array.
 */
static int litavis_parse_mixin_body(const char *body, LitavisProp *out_props, int max_props) {
    int count = 0;
    const char *p = body;

    while (*p && count < max_props) {
        /* Skip whitespace */
        while (*p && (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r')) p++;
        if (!*p) break;

        /* Check for mixin reference: %name; (no colon) */
        if (*p == '%') {
            const char *ref_start = p;
            p++; /* skip % */
            while (*p && (isalnum((unsigned char)*p) || *p == '-' || *p == '_'))
                p++;
            int ref_len = (int)(p - ref_start);
            /* Skip trailing whitespace and semicolon */
            while (*p && (*p == ' ' || *p == '\t')) p++;
            if (*p == ';') p++;

            if (ref_len > 1 && count < max_props) {
                char *key = (char*)malloc((size_t)(ref_len + 1));
                if (!key) LITAVIS_FATAL("out of memory");
                memcpy(key, ref_start, (size_t)ref_len);
                key[ref_len] = '\0';
                out_props[count].key   = key;
                out_props[count].value = litavis_strdup("");
                count++;
            }
            continue;
        }

        /* Scan property name up to : */
        const char *key_start = p;
        while (*p && *p != ':' && *p != ';') p++;
        if (*p != ':') { if (*p == ';') p++; continue; }

        int key_len = (int)(p - key_start);
        /* Trim trailing ws from key */
        while (key_len > 0 && (key_start[key_len - 1] == ' ' || key_start[key_len - 1] == '\t'))
            key_len--;

        p++; /* skip : */
        /* Skip whitespace */
        while (*p && (*p == ' ' || *p == '\t')) p++;

        /* Scan value up to ; or end */
        const char *val_start = p;
        while (*p && *p != ';') p++;
        int val_len = (int)(p - val_start);
        /* Trim trailing ws from value */
        while (val_len > 0 && (val_start[val_len - 1] == ' ' || val_start[val_len - 1] == '\t'))
            val_len--;

        if (key_len > 0) {
            char *key = (char*)malloc((size_t)(key_len + 1));
            char *val = (char*)malloc((size_t)(val_len + 1));
            if (!key || !val) LITAVIS_FATAL("out of memory");
            memcpy(key, key_start, (size_t)key_len);
            key[key_len] = '\0';
            memcpy(val, val_start, (size_t)val_len);
            val[val_len] = '\0';
            out_props[count].key   = key;
            out_props[count].value = val;
            count++;
        }

        if (*p == ';') p++;
    }
    return count;
}

/* ── Main resolution ──────────────────────────────────────── */

/*
 * Two-pass resolution:
 * Pass 1: Collect all $var, %mixin, %map definitions (hoisted)
 * Pass 2: Resolve references in property values and expand mixins
 */
static void litavis_resolve_vars(LitavisAST *ast, LitavisVarScope *global_scope,
                              LitavisMixinStore *mixins, LitavisMapStore *maps) {
    int i, j, k;

    /* ── Pass 1: Collect definitions ──────────────────────── */
    i = 0;
    while (i < ast->count) {
        LitavisRule *rule = &ast->rules[i];

        /* Check if this rule is a $var definition (selector starts with $) */
        if (rule->selector[0] == '$') {
            /* $varname → value stored as prop */
            const char *var_name = rule->selector + 1; /* skip $ */
            if (rule->prop_count > 0) {
                litavis_scope_set(global_scope, var_name, rule->props[0].value);
            }
            litavis_ast_remove_rule(ast, i);
            continue; /* don't increment i */
        }

        /* Check if this rule is a %mixin or %map definition */
        if (rule->selector[0] == '%' && rule->is_at_rule) {
            const char *name = rule->selector + 1; /* skip % */
            if (rule->prop_count > 0) {
                /* Check if the value looks like map entries (key: value; ...) */
                char *body = rule->props[0].value;

                /* Parse body as properties for mixin */
                LitavisProp body_props[64];
                int body_count = litavis_parse_mixin_body(body, body_props, 64);

                if (body_count > 0) {
                    /* Could be a map or a mixin — if keys look like CSS properties, it's a mixin
                       For simplicity: store as both mixin (for %name; expansion) and map (for $name{key}) */
                    LitavisMapEntry entries[64];
                    for (j = 0; j < body_count; j++) {
                        entries[j].key   = body_props[j].key;
                        entries[j].value = body_props[j].value;
                    }
                    litavis_map_define(maps, name, entries, body_count);
                    litavis_mixin_define(mixins, name, body_props, body_count);

                    /* Free temp props */
                    for (j = 0; j < body_count; j++) {
                        free(body_props[j].key);
                        free(body_props[j].value);
                    }
                }
            }
            litavis_ast_remove_rule(ast, i);
            continue;
        }

        /* Scan properties within rules for $var definitions */
        j = 0;
        while (j < rule->prop_count) {
            if (rule->props[j].key[0] == '$') {
                /* $var: value inside a rule — collect but keep scope global for now */
                const char *vname = rule->props[j].key + 1;
                litavis_scope_set(global_scope, vname, rule->props[j].value);
                /* Remove this property */
                free(rule->props[j].key);
                free(rule->props[j].value);
                for (k = j; k < rule->prop_count - 1; k++) {
                    rule->props[k] = rule->props[k + 1];
                }
                rule->prop_count--;
                continue; /* don't increment j */
            }
            j++;
        }

        i++;
    }

    /* ── Pass 1b: Resolve chained variable values ──────────── */
    /* Variables may reference other variables ($primary: $base) */
    {
        int changed = 1;
        int max_passes = 10; /* prevent infinite loops */
        while (changed && max_passes-- > 0) {
            changed = 0;
            for (i = 0; i < global_scope->count; i++) {
                if (strchr(global_scope->vars[i].value, '$')) {
                    char *resolved = litavis_resolve_value(global_scope->vars[i].value, global_scope, maps);
                    if (strcmp(resolved, global_scope->vars[i].value) != 0) {
                        free(global_scope->vars[i].value);
                        global_scope->vars[i].value = resolved;
                        changed = 1;
                    } else {
                        free(resolved);
                    }
                }
            }
        }
    }

    /* ── Pass 2: Resolve references ───────────────────────── */
    for (i = 0; i < ast->count; i++) {
        LitavisRule *rule = &ast->rules[i];

        j = 0;
        while (j < rule->prop_count) {
            /* Check for mixin reference (%name) */
            if (rule->props[j].key[0] == '%') {
                const char *mixin_name = rule->props[j].key + 1;
                LitavisMixin *mixin = litavis_mixin_get(mixins, mixin_name);
                if (mixin && mixin->prop_count > 0) {
                    /* Remove the mixin ref property */
                    free(rule->props[j].key);
                    free(rule->props[j].value);
                    for (k = j; k < rule->prop_count - 1; k++) {
                        rule->props[k] = rule->props[k + 1];
                    }
                    rule->prop_count--;

                    /* Insert mixin properties at position j */
                    int need = rule->prop_count + mixin->prop_count;
                    if (need > rule->prop_cap) {
                        int new_cap = need * 2;
                        LitavisProp *np = (LitavisProp*)realloc(rule->props, sizeof(LitavisProp) * (size_t)new_cap);
                        if (!np) LITAVIS_FATAL("out of memory");
                        rule->props = np;
                        rule->prop_cap = new_cap;
                    }
                    /* Shift existing props after j to make room */
                    for (k = rule->prop_count - 1; k >= j; k--) {
                        rule->props[k + mixin->prop_count] = rule->props[k];
                    }
                    /* Insert mixin props */
                    for (k = 0; k < mixin->prop_count; k++) {
                        rule->props[j + k].key   = litavis_strdup(mixin->props[k].key);
                        rule->props[j + k].value = litavis_strdup(mixin->props[k].value);
                    }
                    rule->prop_count += mixin->prop_count;
                    /* Don't advance j — re-examine inserted props for
                       nested mixin refs and $var resolution */
                    continue;
                } else {
                    /* Unknown mixin — remove the reference */
                    free(rule->props[j].key);
                    free(rule->props[j].value);
                    for (k = j; k < rule->prop_count - 1; k++) {
                        rule->props[k] = rule->props[k + 1];
                    }
                    rule->prop_count--;
                    continue;
                }
            }

            /* Resolve $var references in property values */
            if (strchr(rule->props[j].value, '$')) {
                char *resolved = litavis_resolve_value(rule->props[j].value, global_scope, maps);
                free(rule->props[j].value);
                rule->props[j].value = resolved;
            }

            /* Also resolve $var in custom property values (--var: $something) */

            j++;
        }
    }
}

#endif /* LITAVIS_VARS_H */
