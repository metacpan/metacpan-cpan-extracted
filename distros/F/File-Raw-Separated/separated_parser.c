/*
 * separated_parser.c - CSV/TSV state machine for File::Raw::Separated.
 *
 * See include/separated_parser.h for the public contract.
 */

#include "separated_parser.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------
 * Internal types
 * ------------------------------------------------------------ */

typedef enum {
    ST_START_FIELD = 0,
    ST_IN_UNQUOTED,
    ST_IN_QUOTED,
    ST_MAYBE_END_QUOTE
} parse_state_t;

struct separated_ctx {
    /* Resolved options (copied at init time). */
    separated_options_t opts;

    /* Caller. */
    separated_field_cb cb;
    void *ud;

    /* Field buffer (geometric growth). */
    char  *buf;
    size_t buf_len;
    size_t buf_cap;

    /* State. */
    parse_state_t state;
    int  field_was_quoted;     /* 1 if current field began with a quote */
    int  bom_checked;          /* 1 once we've decided about the BOM */
    int  any_field_in_row;     /* 1 if at least one field started in this row */

    /* Auto-detected / pinned EOL. */
    separated_eol_t detected_eol;
    int  pending_cr;           /* 1 if last byte was CR awaiting LF/data (CRLF detect) */

    /* Diagnostics. */
    size_t bytes_consumed;
    size_t rows_emitted;
    size_t err_offset;

    /* Sticky error: once non-zero, all _feed/_finish are no-ops. */
    separated_err_t  sticky_err;
};

/* Effective max-field cap (resolves opts.max_field_len == 0 to default). */
static size_t
effective_field_cap(const separated_options_t *opts)
{
    return opts->max_field_len ? opts->max_field_len
                               : SEPARATED_FIELD_DEFAULT_CAP;
}

/* ------------------------------------------------------------
 * Field buffer: geometric growth with hard cap
 * ------------------------------------------------------------ */

static separated_err_t
buf_putc(separated_ctx_t *ctx, char c)
{
    if (ctx->buf_len + 1 > ctx->buf_cap) {
        size_t new_cap = ctx->buf_cap ? ctx->buf_cap * 2 : 64;
        size_t cap_max = effective_field_cap(&ctx->opts);
        char *new_buf;
        if (new_cap > cap_max) new_cap = cap_max;
        if (new_cap <= ctx->buf_len) {
            return SEPARATED_ERR_FIELD_TOO_LONG;
        }
        new_buf = (char *)realloc(ctx->buf, new_cap);
        if (!new_buf) return SEPARATED_ERR_NOMEM;
        ctx->buf = new_buf;
        ctx->buf_cap = new_cap;
    }
    ctx->buf[ctx->buf_len++] = c;
    return SEPARATED_OK;
}

static void
buf_reset(separated_ctx_t *ctx)
{
    ctx->buf_len = 0;
}

/* ------------------------------------------------------------
 * Trim helper for unquoted fields when opts.trim is on.
 * Strips only ASCII space and tab. Quoted fields are never trimmed.
 * ------------------------------------------------------------ */

static void
trim_buf(char *buf, size_t *plen)
{
    size_t len = *plen;
    size_t start = 0;
    size_t end;
    while (start < len && (buf[start] == ' ' || buf[start] == '\t')) start++;
    end = len;
    while (end > start && (buf[end - 1] == ' ' || buf[end - 1] == '\t')) end--;
    if (start > 0) memmove(buf, buf + start, end - start);
    *plen = end - start;
}

/* ------------------------------------------------------------
 * Emit a field/row to the callback.
 * end_of_row=1 means "this field is the last in its row".
 * ------------------------------------------------------------ */

static separated_err_t
emit_field(separated_ctx_t *ctx, int end_of_row)
{
    int call_rc;

    /* Trim only on unquoted fields. */
    if (ctx->opts.trim && !ctx->field_was_quoted) {
        trim_buf(ctx->buf, &ctx->buf_len);
    }

    if (ctx->opts.empty_is_undef
        && !ctx->field_was_quoted
        && ctx->buf_len == 0) {
        call_rc = ctx->cb(NULL, SEPARATED_FIELD_NULL_LEN,
                          end_of_row, ctx->ud);
    } else {
        /* Pass even an empty quoted field as a real "" field. */
        const char *p = ctx->buf_len ? ctx->buf : "";
        call_rc = ctx->cb(p, ctx->buf_len, end_of_row, ctx->ud);
    }
    if (call_rc != 0) return SEPARATED_ERR_ABORTED;

    buf_reset(ctx);
    ctx->field_was_quoted = 0;
    ctx->any_field_in_row = 1;
    if (end_of_row) {
        ctx->rows_emitted++;
        ctx->any_field_in_row = 0;
    }
    return SEPARATED_OK;
}

/* ------------------------------------------------------------
 * BOM stripping (UTF-8 only, when binary=0).
 * Called once before any byte is interpreted. Caller passes the
 * incoming buffer pointer + length pair through bom_skip; on return
 * any leading 3-byte BOM has been advanced past.
 * ------------------------------------------------------------ */

static void
bom_check(separated_ctx_t *ctx, const char **pp, size_t *plen)
{
    if (ctx->bom_checked) return;
    ctx->bom_checked = 1;

    if (ctx->opts.binary) return;

    if (*plen >= 3) {
        const unsigned char *u = (const unsigned char *)*pp;
        if (u[0] == 0xEF && u[1] == 0xBB && u[2] == 0xBF) {
            *pp += 3;
            *plen -= 3;
            ctx->bytes_consumed += 3;
        }
    }
}

/* ------------------------------------------------------------
 * EOL helpers
 *
 * detect_or_match returns 1 if the byte at `c` (with the parser's
 * pending_cr flag) is a row terminator under the active EOL mode,
 * 0 if it's a normal byte, or a negative error code on a pinned
 * mismatch under strict mode.
 *
 * On a successful match the function may consume the byte (we always
 * do — the caller treats the return-1 case as "row ended here") and
 * also flips pending_cr or detected_eol as appropriate.
 *
 * NOTE: CRLF handling needs lookahead-of-1. We model it with the
 *       pending_cr bit:
 *         see CR  => set pending_cr=1, do NOT emit row yet.
 *         next byte:
 *           if LF => CRLF row terminator, clear pending_cr.
 *           else  => emit deferred CR-row terminator (CR mode), then
 *                    re-process current byte from scratch.
 *
 * Keeping that in a tiny helper keeps the main loop legible.
 * ------------------------------------------------------------ */

/* Return 1 if c is a terminator after the active EOL mode considers it. */
static int
is_lf(int c) { return c == '\n'; }
static int
is_cr(int c) { return c == '\r'; }

/* ------------------------------------------------------------
 * Core feed loop.
 *
 * Drives the state machine over [buf, buf+len). Returns OK or the
 * first error encountered; on error err_offset is set to the byte
 * offset within the original input (ctx->bytes_consumed at the
 * point of failure).
 * ------------------------------------------------------------ */

#define FAIL(code) do { \
    ctx->sticky_err = (code); \
    ctx->err_offset = ctx->bytes_consumed; \
    return (code); \
} while (0)

#define PUTC(c) do { \
    separated_err_t _e = buf_putc(ctx, (char)(c)); \
    if (_e != SEPARATED_OK) FAIL(_e); \
} while (0)

#define EMIT(end_of_row) do { \
    separated_err_t _e = emit_field(ctx, (end_of_row)); \
    if (_e != SEPARATED_OK) FAIL(_e); \
} while (0)

/* End-of-row from a CR or LF or CRLF. Clears pending_cr. */
static separated_err_t
handle_row_end(separated_ctx_t *ctx)
{
    ctx->pending_cr = 0;
    return emit_field(ctx, 1);
}

/* Decide whether `c` should terminate the current row, given the
 * current EOL mode. Returns:
 *   1  - row ended (caller must NOT process c further)
 *   0  - byte is data; caller continues with state-machine handling
 *  -ve - error code (only in strict + EOL_PINNED mismatch)
 *
 * Side-effect: may toggle pending_cr / detected_eol. */
static int
classify_eol(separated_ctx_t *ctx, int c)
{
    /* Resolve any deferred CR from previous byte. */
    if (ctx->pending_cr) {
        if (is_lf(c)) {
            /* CRLF terminator. Lock detection if AUTO. */
            if (ctx->opts.eol_mode == SEPARATED_EOL_AUTO) {
                ctx->detected_eol = SEPARATED_EOL_CRLF;
            } else if (ctx->opts.eol_mode != SEPARATED_EOL_CRLF
                    && ctx->opts.strict) {
                FAIL(SEPARATED_ERR_EOL_PINNED);
            }
            return 1;  /* row already ended at the CR; consume LF as well */
        } else {
            /* CR alone => row ended at the CR. The current byte is data,
             * but we have a pending row-end to flush first. We do that
             * by returning a "deferred" signal: the caller flushes the
             * row, clears pending_cr, then re-enters with the current
             * byte. We model that here by emitting now and reporting
             * "row ended" — caller must remember NOT to consume c. */
            if (ctx->opts.eol_mode == SEPARATED_EOL_AUTO) {
                ctx->detected_eol = SEPARATED_EOL_CR;
            } else if (ctx->opts.eol_mode != SEPARATED_EOL_CR
                    && ctx->opts.strict) {
                FAIL(SEPARATED_ERR_EOL_PINNED);
            }
            return 2;  /* row ended on previous CR; do not consume c */
        }
    }

    /* No pending CR. Look at this byte. */
    if (is_cr(c)) {
        ctx->pending_cr = 1;
        return -1;  /* tentative; need lookahead. byte consumed. */
    }
    if (is_lf(c)) {
        if (ctx->opts.eol_mode == SEPARATED_EOL_AUTO) {
            ctx->detected_eol = SEPARATED_EOL_LF;
        } else if (ctx->opts.eol_mode != SEPARATED_EOL_LF
                && ctx->opts.strict) {
            FAIL(SEPARATED_ERR_EOL_PINNED);
        }
        return 1;
    }
    return 0;
}

/* Public-facing _feed implementation. */
separated_err_t
separated_feed(separated_ctx_t *ctx, const char *buf, size_t len)
{
    size_t i;

    if (ctx->sticky_err) return ctx->sticky_err;

    bom_check(ctx, &buf, &len);

    i = 0;
    while (i < len) {
        int c = (unsigned char)buf[i];
        int eol;

        /* ---- IN_QUOTED short-circuits EOL detection: newlines are data. */
        if (ctx->state == ST_IN_QUOTED) {
            if (ctx->opts.escape >= 0 && c == ctx->opts.escape) {
                /* Backslash-style escape: consume next byte literally. */
                if (i + 1 >= len) {
                    /* Defer: store nothing; the next feed sees this byte
                     * again. We do that by NOT advancing past the escape
                     * char and returning. */
                    /* Implementation: append a one-byte "escape pending"
                     * marker via a local flag. Cleanest: stuff it as the
                     * last byte of buf and remember we're mid-escape. */
                    /* Simpler model: require the next byte to be in the
                     * SAME chunk. For now we accept that limitation for
                     * v0.01 and document it: backslash escapes that
                     * straddle a chunk boundary are not supported. */
                    PUTC(c);  /* fall back to literal escape char */
                    ctx->bytes_consumed++;
                    i++;
                    continue;
                }
                PUTC(buf[i + 1]);
                ctx->bytes_consumed += 2;
                i += 2;
                continue;
            }
            if (c == ctx->opts.quote) {
                ctx->state = ST_MAYBE_END_QUOTE;
                ctx->bytes_consumed++;
                i++;
                continue;
            }
            PUTC(c);
            ctx->bytes_consumed++;
            i++;
            continue;
        }

        /* ---- All other states: consult EOL classifier first. */
        eol = classify_eol(ctx, c);
        if (eol < 0 && ctx->sticky_err) return ctx->sticky_err;

        if (eol == 1) {
            /* Current byte (or its LF partner) is end-of-row. Consume it
             * and emit the current field as end_of_row. */
            ctx->bytes_consumed++;
            i++;
            /* Skip empty-trailing-newline case: only emit if any field
             * has been started OR the buffer has content. */
            if (ctx->any_field_in_row || ctx->buf_len > 0
                || ctx->state != ST_START_FIELD) {
                separated_err_t e = handle_row_end(ctx);
                if (e != SEPARATED_OK) FAIL(e);
            }
            ctx->state = ST_START_FIELD;
            continue;
        }
        if (eol == 2) {
            /* Pending CR resolved as row-end; this byte is fresh data.
             * Flush the row but do NOT consume the current byte. */
            ctx->pending_cr = 0;  /* must clear unconditionally — handle_row_end
                                     does so but we may skip the call below
                                     when the row is empty (leading bare CR),
                                     and an unset pending_cr with un-advanced
                                     i would loop on the same byte forever. */
            if (ctx->any_field_in_row || ctx->buf_len > 0
                || ctx->state != ST_START_FIELD) {
                separated_err_t e = handle_row_end(ctx);
                if (e != SEPARATED_OK) FAIL(e);
            }
            ctx->state = ST_START_FIELD;
            /* Do not advance i: re-enter the loop on this byte. */
            continue;
        }
        if (eol == -1) {
            /* CR consumed, awaiting decision. */
            ctx->bytes_consumed++;
            i++;
            continue;
        }
        /* eol == 0: byte is regular data, fall through to state machine. */

        switch (ctx->state) {
        case ST_START_FIELD:
            if (c == ctx->opts.sep) {
                EMIT(0);  /* empty field, more to come on this row */
            } else if (ctx->opts.quote >= 0 && c == ctx->opts.quote) {
                ctx->field_was_quoted = 1;
                ctx->state = ST_IN_QUOTED;
            } else {
                PUTC(c);
                ctx->state = ST_IN_UNQUOTED;
            }
            break;

        case ST_IN_UNQUOTED:
            if (c == ctx->opts.sep) {
                EMIT(0);
                ctx->state = ST_START_FIELD;
            } else if (ctx->opts.quote >= 0 && c == ctx->opts.quote) {
                if (ctx->opts.strict) FAIL(SEPARATED_ERR_BAD_QUOTE);
                /* Lenient: keep the quote literally, stay in state. */
                PUTC(c);
            } else {
                PUTC(c);
            }
            break;

        case ST_MAYBE_END_QUOTE:
            if (c == ctx->opts.quote) {
                /* RFC 4180 doubled-quote escape. */
                PUTC(c);
                ctx->state = ST_IN_QUOTED;
            } else if (c == ctx->opts.sep) {
                EMIT(0);
                ctx->state = ST_START_FIELD;
            } else {
                if (ctx->opts.strict) FAIL(SEPARATED_ERR_BAD_QUOTE);
                /* Lenient: closing quote was real, but stray data after.
                 * Append the unexpected byte and continue as unquoted. */
                PUTC(c);
                ctx->state = ST_IN_UNQUOTED;
            }
            break;

        case ST_IN_QUOTED:
            /* unreachable; handled above */
            break;
        }

        ctx->bytes_consumed++;
        i++;
    }

    return SEPARATED_OK;
}

/* ------------------------------------------------------------
 * Finish: flush any half-built field/row at EOF.
 * ------------------------------------------------------------ */

separated_err_t
separated_finish(separated_ctx_t *ctx)
{
    if (ctx->sticky_err) return ctx->sticky_err;

    /* Resolve a dangling CR (CR-only row terminator). */
    if (ctx->pending_cr) {
        if (ctx->opts.eol_mode == SEPARATED_EOL_AUTO) {
            ctx->detected_eol = SEPARATED_EOL_CR;
        } else if (ctx->opts.eol_mode != SEPARATED_EOL_CR
                && ctx->opts.strict) {
            FAIL(SEPARATED_ERR_EOL_PINNED);
        }
        ctx->pending_cr = 0;
        if (ctx->any_field_in_row || ctx->buf_len > 0
            || ctx->state != ST_START_FIELD) {
            separated_err_t e = handle_row_end(ctx);
            if (e != SEPARATED_OK) FAIL(e);
        }
        ctx->state = ST_START_FIELD;
        return SEPARATED_OK;
    }

    /* Strict: open quote at EOF is a parse error. */
    if (ctx->state == ST_IN_QUOTED) {
        if (ctx->opts.strict) FAIL(SEPARATED_ERR_BAD_QUOTE);
        /* Lenient: emit whatever we have. */
    }

    /* Emit any buffered field (and end-of-row) if there's data or we
     * were mid-field. */
    if (ctx->any_field_in_row || ctx->buf_len > 0
        || ctx->state == ST_IN_UNQUOTED
        || ctx->state == ST_IN_QUOTED
        || ctx->state == ST_MAYBE_END_QUOTE) {
        separated_err_t e = emit_field(ctx, 1);
        if (e != SEPARATED_OK) FAIL(e);
    }
    ctx->state = ST_START_FIELD;
    return SEPARATED_OK;
}

/* ------------------------------------------------------------
 * Construction / destruction
 * ------------------------------------------------------------ */

void
separated_options_init_csv(separated_options_t *opts)
{
    memset(opts, 0, sizeof *opts);
    opts->sep    = ',';
    opts->quote  = '"';
    opts->escape = -1;
    opts->eol_mode = SEPARATED_EOL_AUTO;
}

void
separated_options_init_tsv(separated_options_t *opts)
{
    memset(opts, 0, sizeof *opts);
    opts->sep    = '\t';
    opts->quote  = -1;
    opts->escape = -1;
    opts->eol_mode = SEPARATED_EOL_AUTO;
}

separated_ctx_t *
separated_init(const separated_options_t *opts,
               separated_field_cb cb, void *ud)
{
    separated_ctx_t *ctx = (separated_ctx_t *)calloc(1, sizeof *ctx);
    if (!ctx) return NULL;
    ctx->opts = *opts;
    ctx->cb = cb;
    ctx->ud = ud;
    ctx->state = ST_START_FIELD;
    return ctx;
}

void
separated_free(separated_ctx_t *ctx)
{
    if (!ctx) return;
    free(ctx->buf);
    free(ctx);
}

size_t separated_offset(const separated_ctx_t *ctx) { return ctx->bytes_consumed; }
size_t separated_rows(const separated_ctx_t *ctx)   { return ctx->rows_emitted;   }

/* ------------------------------------------------------------
 * One-shot wrapper
 * ------------------------------------------------------------ */

long
separated_parse(const char *buf, size_t len,
                const separated_options_t *opts,
                separated_field_cb cb, void *ud,
                size_t *err_offset)
{
    separated_ctx_t *ctx = separated_init(opts, cb, ud);
    separated_err_t e;
    long ret;
    if (!ctx) {
        if (err_offset) *err_offset = 0;
        return SEPARATED_ERR_NOMEM;
    }

    e = separated_feed(ctx, buf, len);
    if (e == SEPARATED_OK) {
        e = separated_finish(ctx);
    }

    if (e != SEPARATED_OK) {
        if (err_offset) *err_offset = ctx->err_offset;
        ret = (long)e;
    } else {
        if (err_offset) *err_offset = len;
        ret = (long)ctx->rows_emitted;
    }

    separated_free(ctx);
    return ret;
}

/* ------------------------------------------------------------
 * strerror
 * ------------------------------------------------------------ */

const char *
separated_strerror(separated_err_t err)
{
    switch (err) {
    case SEPARATED_OK:                  return "ok";
    case SEPARATED_ERR_NOMEM:           return "out of memory";
    case SEPARATED_ERR_FIELD_TOO_LONG:  return "field exceeds max length";
    case SEPARATED_ERR_BAD_QUOTE:       return "malformed quoting";
    case SEPARATED_ERR_EOL_PINNED:      return "line ending does not match pinned eol mode";
    case SEPARATED_ERR_ABORTED:         return "parse aborted by callback";
    }
    return "unknown error";
}
