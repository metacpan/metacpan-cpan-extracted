#ifndef LITAVIS_CASCADE_H
#define LITAVIS_CASCADE_H

/* ── Dedup strategy enum ──────────────────────────────────── */

typedef enum {
    LITAVIS_DEDUPE_OFF          = 0,  /* no deduplication */
    LITAVIS_DEDUPE_CONSERVATIVE = 1,  /* merge only when provably safe */
    LITAVIS_DEDUPE_AGGRESSIVE   = 2   /* merge all identical, ignore cascade */
} LitavisDedupeStrategy;

/* ── Comparison helpers ───────────────────────────────────── */

/*
 * Deep compare two rules' properties.
 * Returns 1 if same keys and values in same order, 0 otherwise.
 */
static int litavis_props_equal(LitavisRule *a, LitavisRule *b) {
    int i;
    if (a->prop_count != b->prop_count) return 0;
    for (i = 0; i < a->prop_count; i++) {
        if (strcmp(a->props[i].key, b->props[i].key) != 0) return 0;
        if (strcmp(a->props[i].value, b->props[i].value) != 0) return 0;
    }
    return 1;
}

/*
 * Check if rule 'between' defines any property that also appears in 'target'.
 * Returns 1 if conflict found (NOT safe to merge across), 0 if safe.
 */
static int litavis_has_prop_conflict(LitavisRule *target, LitavisRule *between) {
    int i, j;
    for (i = 0; i < target->prop_count; i++) {
        for (j = 0; j < between->prop_count; j++) {
            if (strcmp(target->props[i].key, between->props[j].key) == 0) {
                return 1; /* conflict found */
            }
        }
    }
    return 0;
}

/*
 * Check if it is safe to merge rules at indices i and j.
 * Examines all rules between i and j for property conflicts.
 */
static int litavis_safe_to_merge(LitavisAST *ast, int i, int j) {
    int k;
    for (k = i + 1; k < j; k++) {
        if (litavis_has_prop_conflict(&ast->rules[i], &ast->rules[k])) {
            return 0;
        }
    }
    return 1;
}

/* ── Join two selectors with ", " ─────────────────────────── */

static char* litavis_join_selectors(const char *a, const char *b) {
    int alen = (int)strlen(a);
    int blen = (int)strlen(b);
    char *combined = (char*)malloc((size_t)(alen + 2 + blen + 1));
    if (!combined) LITAVIS_FATAL("out of memory");
    memcpy(combined, a, (size_t)alen);
    combined[alen] = ',';
    combined[alen + 1] = ' ';
    memcpy(combined + alen + 2, b, (size_t)blen);
    combined[alen + 2 + blen] = '\0';
    return combined;
}

/* ── Same-selector merging ────────────────────────────────── */

/*
 * Merge rules that share the same selector.
 * Later properties overwrite earlier ones (matches browser behaviour).
 * Always runs regardless of strategy — this is never wrong.
 */
static void litavis_merge_same_selectors(LitavisAST *ast) {
    int i, j;
    for (i = 0; i < ast->count; i++) {
        for (j = i + 1; j < ast->count; ) {
            if (strcmp(ast->rules[i].selector, ast->rules[j].selector) == 0) {
                /* Merge j's properties into i. For conflicts, j wins
                 * (later in cascade). Then remove j. */
                litavis_rule_merge_props(&ast->rules[i], &ast->rules[j]);
                litavis_ast_remove_rule(ast, j);
                /* Don't increment j — re-check this index */
            } else {
                j++;
            }
        }
    }
}

/* ── Conservative dedup ───────────────────────────────────── */

/*
 * Merge rules at positions i and j (i < j) with identical properties
 * ONLY when no intervening rule k (i < k < j) shares any property name.
 */
static void litavis_dedupe_conservative(LitavisAST *ast) {
    int i = 0;
    while (i < ast->count) {
        int j, merged;

        /* Skip @-rules — dedupe recursively within, never across */
        if (ast->rules[i].is_at_rule) {
            i++;
            continue;
        }

        merged = 0;
        for (j = i + 1; j < ast->count; j++) {
            if (ast->rules[j].is_at_rule) continue;

            if (litavis_props_equal(&ast->rules[i], &ast->rules[j])) {
                if (litavis_safe_to_merge(ast, i, j)) {
                    /* Combine selectors: ".a" + ".b" → ".a, .b" */
                    char *combined = litavis_join_selectors(
                        ast->rules[i].selector,
                        ast->rules[j].selector
                    );
                    litavis_ast_rename_rule(ast, i, combined);
                    litavis_ast_remove_rule(ast, j);
                    free(combined);
                    merged = 1;
                    break; /* re-check from same i */
                }
            }
        }

        if (!merged) i++;
    }
}

/* ── Aggressive dedup ─────────────────────────────────────── */

/*
 * Merge ALL rules with identical properties regardless of position.
 * User accepts cascade reordering. Good for atomic/utility CSS.
 */
static void litavis_dedupe_aggressive(LitavisAST *ast) {
    int i = 0;
    while (i < ast->count) {
        int j, merged;

        if (ast->rules[i].is_at_rule) {
            i++;
            continue;
        }

        merged = 0;
        for (j = i + 1; j < ast->count; j++) {
            if (ast->rules[j].is_at_rule) continue;

            if (litavis_props_equal(&ast->rules[i], &ast->rules[j])) {
                char *combined = litavis_join_selectors(
                    ast->rules[i].selector,
                    ast->rules[j].selector
                );
                litavis_ast_rename_rule(ast, i, combined);
                litavis_ast_remove_rule(ast, j);
                free(combined);
                merged = 1;
                break; /* re-check from same i */
            }
        }

        if (!merged) i++;
    }
}

/* ── Main entry point ─────────────────────────────────────── */

/*
 * Run deduplication on a flat AST.
 * Modifies ast in-place. Operates in insertion order.
 *
 * Phase 1: merge same-selector rules (always safe)
 * Phase 2: merge different-selector rules with identical properties
 */
static void litavis_dedupe(LitavisAST *ast, LitavisDedupeStrategy strategy) {
    if (strategy == LITAVIS_DEDUPE_OFF) return;

    /* Always merge same selectors first */
    litavis_merge_same_selectors(ast);

    /* Then apply cross-selector dedup based on strategy */
    if (strategy == LITAVIS_DEDUPE_CONSERVATIVE) {
        litavis_dedupe_conservative(ast);
    } else if (strategy == LITAVIS_DEDUPE_AGGRESSIVE) {
        litavis_dedupe_aggressive(ast);
    }
}

#endif /* LITAVIS_CASCADE_H */
