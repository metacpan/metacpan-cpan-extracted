/*
 * separated_parser.h - CSV/TSV parser core for File::Raw::Separated
 *
 * Plain C99, no Perl dependency. Same parser drives both CSV and TSV;
 * defaults differ only in `sep` and `quote`.
 *
 * Two ways to use:
 *
 *   1. One-shot: separated_parse(buf, len, opts, row_cb, ud)
 *      — runs the whole input through the state machine in one call.
 *
 *   2. Incremental: separated_init() + separated_feed()* + separated_finish()
 *      — for streaming parsers (mmap chunks, network, etc.).
 *
 * The callback receives borrowed pointers into the parser's field buffer;
 * if the caller needs to keep the field across calls it must copy.
 */

#ifndef SEPARATED_PARSER_H
#define SEPARATED_PARSER_H

#include <stddef.h>

/* ============================================================
 * Options
 * ============================================================ */

typedef enum {
    SEPARATED_EOL_AUTO = 0,
    SEPARATED_EOL_LF,
    SEPARATED_EOL_CRLF,
    SEPARATED_EOL_CR
} separated_eol_t;

typedef struct {
    /* Single-byte separator (e.g. ',' or '\t'). */
    int sep;
    /* Single-byte quote char (e.g. '"'); -1 = no quoting recognised. */
    int quote;
    /* Single-byte escape char (e.g. '\\'); -1 = doubled-quote escape only. */
    int escape;
    /* Strict mode: unrecoverable on malformed input.
     * Lenient mode (default): best-effort recovery. */
    int strict;
    /* Line ending mode. AUTO locks to first detected LF/CRLF/CR. */
    separated_eol_t eol_mode;
    /* Strip leading/trailing ASCII whitespace from unquoted fields only. */
    int trim;
    /* Empty unquoted field becomes the sentinel SEPARATED_FIELD_NULL
     * (length == SEPARATED_FIELD_NULL_LEN, ptr == NULL).
     * Quoted empty ("") stays a real zero-length field. */
    int empty_is_undef;
    /* Skip UTF-8 BOM detection / stripping. */
    int binary;
    /* Header mode: when set, the dispatcher (XS layer) consumes the
     * first emitted row as field names and emits subsequent rows as
     * hashrefs keyed by those names. The C parser itself is not
     * affected — it always emits fields the same way. */
    int header;
    /* Maximum field length. 0 = use SEPARATED_FIELD_DEFAULT_CAP. */
    size_t max_field_len;
} separated_options_t;

/* Default field cap (16 MiB) when opts.max_field_len == 0. */
#define SEPARATED_FIELD_DEFAULT_CAP   (16 * 1024 * 1024)

/* Sentinel returned to callbacks when empty_is_undef + empty unquoted field. */
#define SEPARATED_FIELD_NULL_LEN      ((size_t)-1)

/* Initialise an options struct with CSV defaults
 * (sep=',', quote='"', strict=0, all other flags 0). */
void separated_options_init_csv(separated_options_t *opts);

/* Initialise an options struct with TSV defaults
 * (sep='\t', quote=-1, strict=0, all other flags 0). */
void separated_options_init_tsv(separated_options_t *opts);

/* ============================================================
 * Callback signature
 * ============================================================
 *
 * Called once per emitted field (i.e. when the parser knows the field
 * is complete because it just saw a separator or row terminator).
 *
 *   field   - borrowed pointer into the parser's field buffer
 *             (NULL when len == SEPARATED_FIELD_NULL_LEN, see opts.empty_is_undef)
 *   len     - length in bytes, or SEPARATED_FIELD_NULL_LEN for "undef"
 *   end_of_row - 1 if this is the last field of a row, 0 otherwise
 *   ud      - user-data pointer passed to separated_parse / _init
 *
 * Return 0 to continue, non-zero to abort the parse early.
 */
typedef int (*separated_field_cb)(const char *field, size_t len,
                                  int end_of_row, void *ud);

/* ============================================================
 * Errors
 * ============================================================ */

typedef enum {
    SEPARATED_OK              = 0,
    SEPARATED_ERR_NOMEM       = -1,  /* allocation failed */
    SEPARATED_ERR_FIELD_TOO_LONG = -2,  /* exceeds max_field_len */
    SEPARATED_ERR_BAD_QUOTE   = -3,  /* strict: stray/unbalanced quote */
    SEPARATED_ERR_EOL_PINNED  = -4,  /* strict: eol mode set but mismatch */
    SEPARATED_ERR_ABORTED     = -5   /* callback returned non-zero */
} separated_err_t;

/* Get human-readable description for an error code. */
const char *separated_strerror(separated_err_t err);

/* ============================================================
 * One-shot parse
 * ============================================================
 *
 * Parses the entire buffer in one call.
 *
 * Returns:
 *   >= 0  number of rows emitted
 *   < 0   negative separated_err_t value
 *
 * On error, *err_offset (if non-NULL) is set to the byte offset within
 * `buf` where the error was detected. On success it is set to `len`.
 */
long separated_parse(const char *buf, size_t len,
                     const separated_options_t *opts,
                     separated_field_cb cb, void *ud,
                     size_t *err_offset);

/* ============================================================
 * Incremental parse
 * ============================================================
 *
 * For chunked / streaming parsers. Same parser core, just keeps state
 * between calls. Use:
 *
 *     separated_ctx_t *ctx = separated_init(opts, cb, ud);
 *     while (chunk = next chunk) {
 *         rc = separated_feed(ctx, chunk, chunk_len);
 *         if (rc < 0) { handle error; break; }
 *     }
 *     rc = separated_finish(ctx);    // flushes a trailing field/row
 *     separated_free(ctx);
 *
 * separated_init copies the options struct internally; the caller may
 * free / reuse `opts` after the call.
 */
typedef struct separated_ctx separated_ctx_t;

separated_ctx_t *separated_init(const separated_options_t *opts,
                                separated_field_cb cb, void *ud);
separated_err_t  separated_feed(separated_ctx_t *ctx,
                                const char *buf, size_t len);
separated_err_t  separated_finish(separated_ctx_t *ctx);
void             separated_free(separated_ctx_t *ctx);

/* Total bytes seen so far, for error reporting. */
size_t           separated_offset(const separated_ctx_t *ctx);

/* Total rows emitted so far. */
size_t           separated_rows(const separated_ctx_t *ctx);

#endif /* SEPARATED_PARSER_H */
