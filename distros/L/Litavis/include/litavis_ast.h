#ifndef LITAVIS_AST_H
#define LITAVIS_AST_H

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* ── Error handling (overridable by XS layer) ──────────────── */

#ifndef LITAVIS_FATAL
#define LITAVIS_FATAL(msg) do { fprintf(stderr, "litavis: %s\n", (msg)); abort(); } while(0)
#endif

/* ── Forward declarations ─────────────────────────────────── */

typedef struct LitavisProp    LitavisProp;
typedef struct LitavisRule    LitavisRule;
typedef struct LitavisAST     LitavisAST;
typedef struct LitavisBucket  LitavisBucket;

/* ── Property (key-value pair, ordered) ───────────────────── */

struct LitavisProp {
    char *key;          /* property name, e.g. "color" */
    char *value;        /* property value, e.g. "red" */
};

/* ── Rule (selector + ordered properties + optional children) */

struct LitavisRule {
    char      *selector;    /* e.g. ".card", ".card:hover" */
    LitavisProp  *props;       /* ordered array of properties */
    int        prop_count;
    int        prop_cap;
    LitavisRule  *children;    /* nested rules (before flattening) */
    int        child_count;
    int        child_cap;
    int        is_at_rule;  /* 1 if @media, @keyframes, etc. */
    char      *at_prelude;  /* e.g. "(max-width: 768px)" */
    char      *source_file; /* origin file for error reporting */
    int        source_line;
};

/* ── Hash bucket for O(1) selector lookup ─────────────────── */

struct LitavisBucket {
    char        *key;
    int          index;     /* index into rules[] array */
    LitavisBucket  *next;      /* chaining for collisions */
};

/* ── AST (top-level ordered collection of rules) ──────────── */

struct LitavisAST {
    LitavisRule   *rules;      /* ordered array — insertion order */
    int         count;
    int         capacity;
    LitavisBucket **buckets;   /* hash table for lookup by selector */
    int          bucket_count;
};

/* ── Internal: hash function ──────────────────────────────── */

static unsigned int litavis_hash(const char *key, int bucket_count) {
    unsigned int h = 5381;
    while (*key)
        h = ((h << 5) + h) + (unsigned char)*key++;
    return h % (unsigned int)bucket_count;
}

/* ── Internal: strdup portable ────────────────────────────── */

static char* litavis_strdup(const char *s) {
    size_t len = strlen(s);
    char *dup = (char*)malloc(len + 1);
    if (!dup) LITAVIS_FATAL("out of memory");
    memcpy(dup, s, len + 1);
    return dup;
}

/* ── Internal: initialise a rule struct ───────────────────── */

static void litavis_rule_init(LitavisRule *rule) {
    rule->selector    = NULL;
    rule->props       = NULL;
    rule->prop_count  = 0;
    rule->prop_cap    = 0;
    rule->children    = NULL;
    rule->child_count = 0;
    rule->child_cap   = 0;
    rule->is_at_rule  = 0;
    rule->at_prelude  = NULL;
    rule->source_file = NULL;
    rule->source_line = 0;
}

/* ── Internal: free a rule's contents (not the rule itself) ── */

static void litavis_rule_cleanup(LitavisRule *rule) {
    int i;
    if (rule->selector)    free(rule->selector);
    if (rule->at_prelude)  free(rule->at_prelude);
    if (rule->source_file) free(rule->source_file);
    for (i = 0; i < rule->prop_count; i++) {
        free(rule->props[i].key);
        free(rule->props[i].value);
    }
    if (rule->props) free(rule->props);
    for (i = 0; i < rule->child_count; i++) {
        litavis_rule_cleanup(&rule->children[i]);
    }
    if (rule->children) free(rule->children);
}

/* ── Internal: free all hash buckets ─────────────────────── */

static void litavis_ast_free_buckets(LitavisAST *ast) {
    int i;
    for (i = 0; i < ast->bucket_count; i++) {
        LitavisBucket *b = ast->buckets[i];
        while (b) {
            LitavisBucket *next = b->next;
            free(b->key);
            free(b);
            b = next;
        }
    }
    free(ast->buckets);
    ast->buckets = NULL;
}

/* ── Internal: insert into hash table ────────────────────── */

static void litavis_ast_hash_insert(LitavisAST *ast, const char *key, int index) {
    unsigned int h = litavis_hash(key, ast->bucket_count);
    LitavisBucket *b = (LitavisBucket*)malloc(sizeof(LitavisBucket));
    if (!b) LITAVIS_FATAL("out of memory");
    b->key   = litavis_strdup(key);
    b->index = index;
    b->next  = ast->buckets[h];
    ast->buckets[h] = b;
}

/* ── Internal: rehash when load factor exceeds 0.75 ──────── */

static void litavis_ast_rehash(LitavisAST *ast) {
    int new_bc = ast->bucket_count * 2;
    LitavisBucket **new_buckets = (LitavisBucket**)calloc((size_t)new_bc, sizeof(LitavisBucket*));
    int i;
    if (!new_buckets) LITAVIS_FATAL("out of memory");

    /* Re-insert all existing entries */
    for (i = 0; i < ast->bucket_count; i++) {
        LitavisBucket *b = ast->buckets[i];
        while (b) {
            LitavisBucket *next = b->next;
            unsigned int h = litavis_hash(b->key, new_bc);
            b->next = new_buckets[h];
            new_buckets[h] = b;
            b = next;
        }
    }
    free(ast->buckets);
    ast->buckets = new_buckets;
    ast->bucket_count = new_bc;
}

/* ── AST lifecycle ────────────────────────────────────────── */

static LitavisAST* litavis_ast_new(int initial_capacity) {
    LitavisAST *ast = (LitavisAST*)malloc(sizeof(LitavisAST));
    if (!ast) LITAVIS_FATAL("out of memory");

    if (initial_capacity < 8) initial_capacity = 8;
    ast->rules    = (LitavisRule*)malloc(sizeof(LitavisRule) * (size_t)initial_capacity);
    ast->count    = 0;
    ast->capacity = initial_capacity;

    ast->bucket_count = initial_capacity * 2;
    ast->buckets = (LitavisBucket**)calloc((size_t)ast->bucket_count, sizeof(LitavisBucket*));

    if (!ast->rules || !ast->buckets) LITAVIS_FATAL("out of memory");
    return ast;
}

static void litavis_ast_free(LitavisAST *ast) {
    int i;
    if (!ast) return;
    for (i = 0; i < ast->count; i++) {
        litavis_rule_cleanup(&ast->rules[i]);
    }
    free(ast->rules);
    litavis_ast_free_buckets(ast);
    free(ast);
}

/* ── Deep clone ───────────────────────────────────────────── */

static void litavis_rule_clone_into(LitavisRule *dst, const LitavisRule *src);

static void litavis_rule_clone_into(LitavisRule *dst, const LitavisRule *src) {
    int i;
    litavis_rule_init(dst);
    if (src->selector)    dst->selector    = litavis_strdup(src->selector);
    if (src->at_prelude)  dst->at_prelude  = litavis_strdup(src->at_prelude);
    if (src->source_file) dst->source_file = litavis_strdup(src->source_file);
    dst->is_at_rule  = src->is_at_rule;
    dst->source_line = src->source_line;

    if (src->prop_count > 0) {
        dst->prop_cap   = src->prop_count;
        dst->prop_count = src->prop_count;
        dst->props = (LitavisProp*)malloc(sizeof(LitavisProp) * (size_t)dst->prop_cap);
        if (!dst->props) LITAVIS_FATAL("out of memory");
        for (i = 0; i < src->prop_count; i++) {
            dst->props[i].key   = litavis_strdup(src->props[i].key);
            dst->props[i].value = litavis_strdup(src->props[i].value);
        }
    }

    if (src->child_count > 0) {
        dst->child_cap   = src->child_count;
        dst->child_count = src->child_count;
        dst->children = (LitavisRule*)malloc(sizeof(LitavisRule) * (size_t)dst->child_cap);
        if (!dst->children) LITAVIS_FATAL("out of memory");
        for (i = 0; i < src->child_count; i++) {
            litavis_rule_clone_into(&dst->children[i], &src->children[i]);
        }
    }
}

static LitavisAST* litavis_ast_clone(LitavisAST *ast) {
    int i;
    LitavisAST *clone;
    if (!ast) return NULL;
    clone = litavis_ast_new(ast->capacity);
    for (i = 0; i < ast->count; i++) {
        litavis_rule_clone_into(&clone->rules[i], &ast->rules[i]);
        litavis_ast_hash_insert(clone, ast->rules[i].selector, i);
    }
    clone->count = ast->count;
    return clone;
}

/* ── Rule operations ──────────────────────────────────────── */

/* O(1) lookup by selector */
static LitavisRule* litavis_ast_get_rule(LitavisAST *ast, const char *selector) {
    unsigned int h = litavis_hash(selector, ast->bucket_count);
    LitavisBucket *b = ast->buckets[h];
    while (b) {
        if (strcmp(b->key, selector) == 0)
            return &ast->rules[b->index];
        b = b->next;
    }
    return NULL;
}

/* Check existence */
static int litavis_ast_has_rule(LitavisAST *ast, const char *selector) {
    return litavis_ast_get_rule(ast, selector) != NULL;
}

/* Append a new rule or return existing if selector matches */
static LitavisRule* litavis_ast_add_rule(LitavisAST *ast, const char *selector) {
    LitavisRule *existing = litavis_ast_get_rule(ast, selector);
    if (existing) return existing;

    /* Grow array if needed */
    if (ast->count >= ast->capacity) {
        int new_cap = ast->capacity * 2;
        LitavisRule *new_rules = (LitavisRule*)realloc(ast->rules, sizeof(LitavisRule) * (size_t)new_cap);
        if (!new_rules) LITAVIS_FATAL("out of memory");
        ast->rules    = new_rules;
        ast->capacity = new_cap;
    }

    /* Rehash if load factor > 0.75 */
    if (ast->count * 4 > ast->bucket_count * 3) {
        litavis_ast_rehash(ast);
    }

    /* Init new rule */
    litavis_rule_init(&ast->rules[ast->count]);
    ast->rules[ast->count].selector = litavis_strdup(selector);

    /* Insert into hash */
    litavis_ast_hash_insert(ast, selector, ast->count);

    return &ast->rules[ast->count++];
}

/* Remove rule, shift remaining to preserve order */
static void litavis_ast_remove_rule(LitavisAST *ast, int index) {
    int i;
    if (index < 0 || index >= ast->count) return;

    /* Clean up the rule being removed */
    litavis_rule_cleanup(&ast->rules[index]);

    /* Shift remaining rules down */
    for (i = index; i < ast->count - 1; i++) {
        ast->rules[i] = ast->rules[i + 1];
    }
    ast->count--;

    /* Rebuild hash table (indices changed) */
    litavis_ast_free_buckets(ast);
    ast->bucket_count = (ast->capacity > 8 ? ast->capacity : 8) * 2;
    ast->buckets = (LitavisBucket**)calloc((size_t)ast->bucket_count, sizeof(LitavisBucket*));
    if (!ast->buckets) LITAVIS_FATAL("out of memory");
    for (i = 0; i < ast->count; i++) {
        litavis_ast_hash_insert(ast, ast->rules[i].selector, i);
    }
}

/* Rename a rule's selector (for dedup merging) */
static void litavis_ast_rename_rule(LitavisAST *ast, int index, const char *new_selector) {
    int i;
    if (index < 0 || index >= ast->count) return;

    free(ast->rules[index].selector);
    ast->rules[index].selector = litavis_strdup(new_selector);

    /* Rebuild hash table */
    litavis_ast_free_buckets(ast);
    ast->bucket_count = (ast->capacity > 8 ? ast->capacity : 8) * 2;
    ast->buckets = (LitavisBucket**)calloc((size_t)ast->bucket_count, sizeof(LitavisBucket*));
    if (!ast->buckets) LITAVIS_FATAL("out of memory");
    for (i = 0; i < ast->count; i++) {
        litavis_ast_hash_insert(ast, ast->rules[i].selector, i);
    }
}

/* ── Property operations on a rule ────────────────────────── */

static void litavis_rule_add_prop(LitavisRule *rule, const char *key, const char *value) {
    int i;

    /* Update existing property if key matches */
    for (i = 0; i < rule->prop_count; i++) {
        if (strcmp(rule->props[i].key, key) == 0) {
            free(rule->props[i].value);
            rule->props[i].value = litavis_strdup(value);
            return;
        }
    }

    /* Grow array if needed */
    if (rule->prop_count >= rule->prop_cap) {
        int new_cap = rule->prop_cap < 4 ? 4 : rule->prop_cap * 2;
        LitavisProp *new_props = (LitavisProp*)realloc(rule->props, sizeof(LitavisProp) * (size_t)new_cap);
        if (!new_props) LITAVIS_FATAL("out of memory");
        rule->props    = new_props;
        rule->prop_cap = new_cap;
    }

    rule->props[rule->prop_count].key   = litavis_strdup(key);
    rule->props[rule->prop_count].value = litavis_strdup(value);
    rule->prop_count++;
}

static char* litavis_rule_get_prop(LitavisRule *rule, const char *key) {
    int i;
    for (i = 0; i < rule->prop_count; i++) {
        if (strcmp(rule->props[i].key, key) == 0)
            return rule->props[i].value;
    }
    return NULL;
}

static int litavis_rule_has_prop(LitavisRule *rule, const char *key) {
    return litavis_rule_get_prop(rule, key) != NULL;
}

/* ── Child rule operations ────────────────────────────────── */

static LitavisRule* litavis_rule_add_child(LitavisRule *rule, const char *selector) {
    if (rule->child_count >= rule->child_cap) {
        int new_cap = rule->child_cap < 4 ? 4 : rule->child_cap * 2;
        LitavisRule *new_children = (LitavisRule*)realloc(rule->children, sizeof(LitavisRule) * (size_t)new_cap);
        if (!new_children) LITAVIS_FATAL("out of memory");
        rule->children = new_children;
        rule->child_cap = new_cap;
    }

    litavis_rule_init(&rule->children[rule->child_count]);
    rule->children[rule->child_count].selector = litavis_strdup(selector);
    return &rule->children[rule->child_count++];
}

/* ── Utility ──────────────────────────────────────────────── */

/* Deep compare two rules' properties (same keys, same values, same order) */
static int litavis_rules_props_equal(LitavisRule *a, LitavisRule *b) {
    int i;
    if (a->prop_count != b->prop_count) return 0;
    for (i = 0; i < a->prop_count; i++) {
        if (strcmp(a->props[i].key, b->props[i].key) != 0) return 0;
        if (strcmp(a->props[i].value, b->props[i].value) != 0) return 0;
    }
    return 1;
}

/* Merge properties from src into dst (src wins on conflict) */
static void litavis_rule_merge_props(LitavisRule *dst, LitavisRule *src) {
    int i;
    for (i = 0; i < src->prop_count; i++) {
        litavis_rule_add_prop(dst, src->props[i].key, src->props[i].value);
    }
}

#endif /* LITAVIS_AST_H */
