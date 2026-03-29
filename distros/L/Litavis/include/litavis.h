#ifndef LITAVIS_H
#define LITAVIS_H

/*
 * litavis.h - Perl XS wrapper for the Litavis CSS preprocessor
 *
 * This header sets up Perl-specific error handling, includes the
 * pure C engine headers, and defines the top-level context struct.
 *
 * For reuse from OTHER XS modules, include the individual headers
 * directly (litavis_ast.h, etc.) instead.
 */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

/* Route fatal errors through Perl's croak() */
#define LITAVIS_FATAL(msg) croak("litavis: %s", (msg))

/* Pull in the C engine — order-independent headers first */
#include "litavis_ast.h"
#include "litavis_tokeniser.h"
#include "litavis_cascade.h"
#include "litavis_vars.h"
#include "litavis_colour.h"

#define LITAVIS_VERSION "0.01"

/* ── Top-level context — holds all state for one Litavis instance ── */

typedef struct {
    LitavisAST        *ast;           /* accumulated parsed rules */
    LitavisVarScope   *global_scope;  /* preprocessor variable scope */
    LitavisMixinStore *mixins;        /* mixin definitions */
    LitavisMapStore   *maps;          /* map variable definitions */
    int      pretty;        /* 0 = minified, 1 = pretty */
    int      dedupe;        /* 0 = off, 1 = conservative, 2 = aggressive */
    char    *indent;        /* indent string for pretty mode */
    int      shorthand_hex; /* 1 = #fff, 0 = #ffffff */
    int      sort_props;    /* 1 = alphabetise properties */
} LitavisCtx;

/* Headers that depend on LitavisCtx */
#include "litavis_parser.h"
#include "litavis_emitter.h"

/* ── Context lifecycle ────────────────────────────────────────── */

static LitavisCtx* litavis_ctx_new(void) {
    LitavisCtx *ctx = (LitavisCtx*)malloc(sizeof(LitavisCtx));
    if (!ctx) LITAVIS_FATAL("out of memory");
    ctx->ast           = litavis_ast_new(16);
    ctx->global_scope  = litavis_scope_new(NULL);
    ctx->mixins        = litavis_mixin_store_new();
    ctx->maps          = litavis_map_store_new();
    ctx->pretty        = 0;
    ctx->dedupe        = 1;  /* conservative by default */
    ctx->indent        = litavis_strdup("  ");
    ctx->shorthand_hex = 1;
    ctx->sort_props    = 0;
    return ctx;
}

static void litavis_ctx_free(LitavisCtx *ctx) {
    if (!ctx) return;
    if (ctx->ast)          litavis_ast_free(ctx->ast);
    if (ctx->global_scope) litavis_scope_free(ctx->global_scope);
    if (ctx->mixins)       litavis_mixin_store_free(ctx->mixins);
    if (ctx->maps)         litavis_map_store_free(ctx->maps);
    if (ctx->indent)       free(ctx->indent);
    free(ctx);
}

static void litavis_ctx_reset(LitavisCtx *ctx) {
    if (!ctx) return;
    if (ctx->ast) litavis_ast_free(ctx->ast);
    ctx->ast = litavis_ast_new(16);
    if (ctx->global_scope) litavis_scope_free(ctx->global_scope);
    ctx->global_scope = litavis_scope_new(NULL);
    if (ctx->mixins) litavis_mixin_store_free(ctx->mixins);
    ctx->mixins = litavis_mixin_store_new();
    if (ctx->maps) litavis_map_store_free(ctx->maps);
    ctx->maps = litavis_map_store_new();
}

#endif /* LITAVIS_H */
