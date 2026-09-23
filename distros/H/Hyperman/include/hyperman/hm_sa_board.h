/* hm_sa_board.h - what the arena makes possible off the hot path: a
 * scoreboard with one row per worker, and an opt-in distinct-client count.
 *
 * Perl-free; the includer defines `HM_SA` and `hm_sa_region` (hm_sa.h in the
 * server, the benchmark harness with no interpreter).
 *
 * THE RULE: nothing here runs per request. The scoreboard row is MIRRORED
 * from the loop's own counters by a one-second timer, one seqlock bracket per
 * worker per second, so the request path never touches it. The one thing
 * that may touch the accept path, the HyperLogLog of distinct clients, is
 * opt-in and its cost is measured and documented rather than hidden; with it
 * off the accept path pays one load of a NULL.
 */

#ifndef HM_SA_BOARD_H
#define HM_SA_BOARD_H

#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

#include "sa_abi.h"

/* The seven gauges, in row order. `h3` is the HTTP/3 request count; the
 * other h3 counters have no column, a board's eight gauges being what they
 * are. */
#define HM_SA_BOARD_FIELDS 7
static const char *const hm_sa_board_fields[HM_SA_BOARD_FIELDS] = {
    "requests", "accepts", "denied", "conns", "bytes_out", "datagrams", "h3"
};
enum { HM_SB_REQUESTS, HM_SB_ACCEPTS, HM_SB_DENIED, HM_SB_CONNS,
       HM_SB_BYTES_OUT, HM_SB_DATAGRAMS, HM_SB_H3 };

/* The aggregate a reader wants: every live row summed. The same shape the
 * ABI's pool_stats hands a C consumer. */
typedef struct hm_sa_pool_stats {
    uint64_t workers;       /* rows that read coherently */
    uint64_t alive;         /* ... whose writer is running */
    uint64_t requests, accepts, denied, conns, bytes_out, datagrams, h3;
} hm_sa_pool_stats;

static sa_sb  *hm_sa_board  = NULL;   /* NULL = no board: fail open */
static int     hm_sa_board_row = -1;  /* this process's row, or -1   */
static sa_hll *hm_sa_hll    = NULL;   /* the distinct-client sketch, opt-in */

static int hm_sa_board_live(void) { return hm_sa_board != NULL; }

/* ---- lifecycle ------------------------------------------------------------- */

/* Open the board before the fork, `slots` rows (workers + 1). Idempotent;
 * -1 with *err on refusal, in which case there is no board and every door
 * answers "none". */
static int hm_sa_board_open(uint32_t slots, int *err) {
    int e = 0;
    if (err) *err = 0;
    if (!HM_SA || !hm_sa_region || hm_sa_board) return 0;
    if (!slots) slots = 2;
    hm_sa_board = HM_SA->sb_open(hm_sa_region, "workers", 7,
                                 hm_sa_board_fields, HM_SA_BOARD_FIELDS,
                                 slots, &e);
    if (!hm_sa_board) { if (err) *err = e; return -1; }
    return 0;
}

/* Take a row for this process, after the fork. -1 when the board is full,
 * which costs this worker its row and nothing else. */
static int hm_sa_board_take(void) {
    if (!hm_sa_board) return -1;
    hm_sa_board_row = HM_SA->sb_take(hm_sa_board);
    return hm_sa_board_row;
}

/* Copy the counters into this worker's row, coherently, and set the status.
 * Called from the timer, never from a request. */
static void hm_sa_board_mirror(uint64_t requests, uint64_t accepts,
                               uint64_t denied, int conns,
                               uint64_t bytes_out, uint64_t datagrams,
                               uint64_t h3) {
    void *row;
    char st[24];
    int n;
    if (!hm_sa_board || hm_sa_board_row < 0) return;
    row = HM_SA->sb_begin(hm_sa_board);
    if (!row) return;
    HM_SA->sb_set_gauge(row, HM_SB_REQUESTS,  requests);
    HM_SA->sb_set_gauge(row, HM_SB_ACCEPTS,   accepts);
    HM_SA->sb_set_gauge(row, HM_SB_DENIED,    denied);
    HM_SA->sb_set_gauge(row, HM_SB_CONNS,     (uint64_t)(conns < 0 ? 0 : conns));
    HM_SA->sb_set_gauge(row, HM_SB_BYTES_OUT, bytes_out);
    HM_SA->sb_set_gauge(row, HM_SB_DATAGRAMS, datagrams);
    HM_SA->sb_set_gauge(row, HM_SB_H3,        h3);
    n = conns > 0 ? snprintf(st, sizeof st, "busy %d", conns)
                  : snprintf(st, sizeof st, "idle");
    HM_SA->sb_set_status(row, st, (uint32_t)n);
    HM_SA->sb_end(hm_sa_board, row);
}

/* ---- reading --------------------------------------------------------------- */

/* Row `i`, coherently, into *out. 0 for an empty row or one whose writer
 * died mid-update. */
static int hm_sa_board_read(uint32_t i, sa_sb_reading *out) {
    if (!hm_sa_board) return 0;
    return HM_SA->sb_read(hm_sa_board, i, out);
}

static uint64_t hm_sa_board_slots(void) {
    return hm_sa_board ? HM_SA->sb_slots(hm_sa_board) : 0;
}

/* Every row summed. 1 when there is a board, 0 when there is not. */
static int hm_sa_board_pool(hm_sa_pool_stats *out) {
    uint64_t i, n;
    if (!out) return 0;
    memset(out, 0, sizeof *out);
    if (!hm_sa_board) return 0;
    n = hm_sa_board_slots();
    for (i = 0; i < n; i++) {
        sa_sb_reading rd;
        if (!hm_sa_board_read((uint32_t)i, &rd)) continue;
        out->workers++;
        if (rd.alive) out->alive++;
        out->requests  += rd.gauges[HM_SB_REQUESTS];
        out->accepts   += rd.gauges[HM_SB_ACCEPTS];
        out->denied    += rd.gauges[HM_SB_DENIED];
        out->conns     += rd.gauges[HM_SB_CONNS];
        out->bytes_out += rd.gauges[HM_SB_BYTES_OUT];
        out->datagrams += rd.gauges[HM_SB_DATAGRAMS];
        out->h3        += rd.gauges[HM_SB_H3];
    }
    return 1;
}

/* The row a pid owns, or -1. For the supervisor's wedged check. */
static int hm_sa_board_row_of(uint64_t pid, sa_sb_reading *out) {
    uint64_t i, n = hm_sa_board_slots();
    for (i = 0; i < n; i++) {
        if (!hm_sa_board_read((uint32_t)i, out)) continue;
        if (out->pid == pid) return (int)i;
    }
    return -1;
}

/* One aggregate line and one line per row, for USR1.
 *
 * ONE WRITE, not one per line. A dump is read by somebody else - a log tail, a
 * test, another admin's USR1 - while it is being written, and a dump that
 * reaches the stream in three writes can be read as an aggregate line with no
 * rows behind it, which reads as a pool with no workers. So the lines are
 * formatted into a buffer and handed over in one go; a pool too large for the
 * buffer is flushed a bufferful at a time, always on a line boundary, so the
 * worst case is a dump split between whole lines rather than mid-line. */
static int hm_sa_board_row_line(char *b, size_t cap, const sa_sb_reading *rd) {
    return snprintf(b, cap,
                    "Hyperman worker %llu: requests=%llu accepts=%llu "
                    "denied=%llu conns=%llu bytes_out=%llu status=%.*s%s\n",
                    (unsigned long long)rd->pid,
                    (unsigned long long)rd->gauges[HM_SB_REQUESTS],
                    (unsigned long long)rd->gauges[HM_SB_ACCEPTS],
                    (unsigned long long)rd->gauges[HM_SB_DENIED],
                    (unsigned long long)rd->gauges[HM_SB_CONNS],
                    (unsigned long long)rd->gauges[HM_SB_BYTES_OUT],
                    (int)rd->statuslen, rd->status, rd->alive ? "" : " DEAD");
}

static void hm_sa_board_print(FILE *f) {
    hm_sa_pool_stats p;
    uint64_t i, n;
    char buf[4096];
    size_t off = 0;
    int w;

    if (!hm_sa_board_pool(&p)) return;
    w = snprintf(buf, sizeof buf,
                 "Hyperman pool: workers=%llu alive=%llu requests=%llu "
                 "accepts=%llu denied=%llu conns=%llu bytes_out=%llu "
                 "datagrams=%llu h3=%llu\n",
                 (unsigned long long)p.workers, (unsigned long long)p.alive,
                 (unsigned long long)p.requests, (unsigned long long)p.accepts,
                 (unsigned long long)p.denied, (unsigned long long)p.conns,
                 (unsigned long long)p.bytes_out,
                 (unsigned long long)p.datagrams, (unsigned long long)p.h3);
    if (w < 0) return;
    off = (size_t)w < sizeof buf ? (size_t)w : sizeof buf - 1;

    n = hm_sa_board_slots();
    for (i = 0; i < n; i++) {
        sa_sb_reading rd;
        if (!hm_sa_board_read((uint32_t)i, &rd)) continue;
        w = hm_sa_board_row_line(buf + off, sizeof buf - off, &rd);
        if (w < 0) continue;
        if ((size_t)w >= sizeof buf - off) {
            /* No room left: hand over the whole lines we have and format this
             * row into the empty buffer instead. */
            if (off) { fwrite(buf, 1, off, f); fflush(f); off = 0; }
            w = hm_sa_board_row_line(buf, sizeof buf, &rd);
            if (w < 0 || (size_t)w >= sizeof buf) continue;
        }
        off += (size_t)w;
    }
    if (off) { fwrite(buf, 1, off, f); fflush(f); }
}

/* ---- distinct clients: opt-in, on the accept path ----------------------------- */

/* The HyperLogLog of peers seen, at precision 14 (about 0.8% error, 16KB).
 * Opened only when asked for. */
static int hm_sa_hll_open(int *err) {
    int e = 0;
    if (err) *err = 0;
    if (!HM_SA || !hm_sa_region || hm_sa_hll) return 0;
    hm_sa_hll = HM_SA->hll_open(hm_sa_region, "clients", 7, 14, &e);
    if (!hm_sa_hll) { if (err) *err = e; return -1; }
    return 0;
}

/* One hash and one CAS-max, about 20ns. The caller tests hm_sa_hll first,
 * so the off path is a load of a NULL and nothing else. */
static void hm_sa_hll_add(const char *peer) {
    if (hm_sa_hll && peer) HM_SA->hll_add(hm_sa_hll, peer, strlen(peer));
}

/* The estimate, or -1.0 with the sketch off. */
static double hm_sa_hll_count(void) {
    return hm_sa_hll ? HM_SA->hll_count(hm_sa_hll) : -1.0;
}

#endif /* HM_SA_BOARD_H */
