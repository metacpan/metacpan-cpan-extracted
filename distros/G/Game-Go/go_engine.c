/* go_engine.c - the Go board, the chains, the liberties, and the zobrist hash.
 *
 * PERL-FREE. This file must never include perl.h, XSUB.h or stdio.h, and must
 * never call rand, time, printf or anything that touches a handle. t/24-no-io.t
 * scans this source for all of those after stripping comments, so a decimal
 * number is formatted by hand below rather than with sprintf.
 *
 * What this file owns is in include/go_abi.h under "what this header covers,
 * and what it does not": the board and only the board. Nothing here knows
 * whether a move was legal.
 */

#include <stdlib.h>
#include <string.h>

#include "go_abi.h"

#define M32(x) ((x) & 0xFFFFFFFFu)

/* ------------------------------------------------------------------ SHA-256 --
 *
 * Here for one reason: the zobrist table is derived from SHA-256 so that it is
 * identical on every platform and every build, and so that a test can verify
 * any entry from Perl with Digest::SHA. Deriving it from a PRNG would make the
 * hash values a build artifact and put an unverifiable number in the middle of
 * the legality path.
 *
 * Only ever called with a message shorter than 56 bytes (the longest label is
 * "go-zobrist:2:440", sixteen characters), so this is the single-block case
 * and needs no streaming state.
 */

static const unsigned int SHA_K[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u
};

#define ROR32(x, n) (M32(((x) >> (n)) | ((x) << (32 - (n)))))

static void sha256_short(const unsigned char *msg, int len, unsigned char out[32])
{
    unsigned int h[8];
    unsigned int w[64];
    unsigned char blk[64];
    int i;

    h[0] = 0x6a09e667u; h[1] = 0xbb67ae85u; h[2] = 0x3c6ef372u; h[3] = 0xa54ff53au;
    h[4] = 0x510e527fu; h[5] = 0x9b05688cu; h[6] = 0x1f83d9abu; h[7] = 0x5be0cd19u;

    memset(blk, 0, sizeof(blk));
    memcpy(blk, msg, (size_t)len);
    blk[len] = 0x80;
    /* the message is short, so the length in bits fits the last two bytes */
    blk[62] = (unsigned char)(((unsigned)len * 8u) >> 8);
    blk[63] = (unsigned char)(((unsigned)len * 8u) & 0xffu);

    for (i = 0; i < 16; i++)
        w[i] = ((unsigned int)blk[i * 4] << 24) | ((unsigned int)blk[i * 4 + 1] << 16)
             | ((unsigned int)blk[i * 4 + 2] << 8) | (unsigned int)blk[i * 4 + 3];
    for (i = 16; i < 64; i++) {
        unsigned int s0 = ROR32(w[i - 15], 7) ^ ROR32(w[i - 15], 18) ^ M32(w[i - 15] >> 3);
        unsigned int s1 = ROR32(w[i - 2], 17) ^ ROR32(w[i - 2], 19) ^ M32(w[i - 2] >> 10);
        w[i] = M32(w[i - 16] + s0 + w[i - 7] + s1);
    }

    {
        unsigned int a = h[0], b = h[1], c = h[2], d = h[3];
        unsigned int e = h[4], f = h[5], g = h[6], hh = h[7];
        for (i = 0; i < 64; i++) {
            unsigned int S1 = ROR32(e, 6) ^ ROR32(e, 11) ^ ROR32(e, 25);
            unsigned int ch = (e & f) ^ ((~e) & g);
            unsigned int t1 = M32(hh + S1 + ch + SHA_K[i] + w[i]);
            unsigned int S0 = ROR32(a, 2) ^ ROR32(a, 13) ^ ROR32(a, 22);
            unsigned int mj = (a & b) ^ (a & c) ^ (b & c);
            unsigned int t2 = M32(S0 + mj);
            hh = g; g = f; f = e; e = M32(d + t1);
            d = c; c = b; b = a; a = M32(t1 + t2);
        }
        h[0] = M32(h[0] + a); h[1] = M32(h[1] + b); h[2] = M32(h[2] + c);
        h[3] = M32(h[3] + d); h[4] = M32(h[4] + e); h[5] = M32(h[5] + f);
        h[6] = M32(h[6] + g); h[7] = M32(h[7] + hh);
    }

    for (i = 0; i < 8; i++) {
        out[i * 4]     = (unsigned char)((h[i] >> 24) & 0xffu);
        out[i * 4 + 1] = (unsigned char)((h[i] >> 16) & 0xffu);
        out[i * 4 + 2] = (unsigned char)((h[i] >> 8) & 0xffu);
        out[i * 4 + 3] = (unsigned char)(h[i] & 0xffu);
    }
}

/* ------------------------------------------------------------ the zobrist ---- */

static unsigned long long ZOB[4][GO_MAX_PTS];
static int ZOB_READY = 0;

/* Decimal by hand, because sprintf would mean stdio.h and t/24-no-io.t scans
 * for it. Returns the number of characters written. */
static int put_dec(unsigned char *at, int n)
{
    unsigned char tmp[12];
    int i = 0, j = 0;
    if (n == 0) { at[0] = '0'; return 1; }
    while (n > 0) { tmp[i++] = (unsigned char)('0' + (n % 10)); n /= 10; }
    while (i > 0) at[j++] = tmp[--i];
    return j;
}

/* The label whose SHA-256 is the entry:  go-zobrist:<colour>:<point>
 * A test asserts this exactly, so the spelling is part of the ABI. */
static int zob_label(unsigned char *buf, int colour, int pt)
{
    static const char pre[] = "go-zobrist:";
    int n = (int)(sizeof(pre) - 1);
    memcpy(buf, pre, (size_t)n);
    n += put_dec(buf + n, colour);
    buf[n++] = ':';
    n += put_dec(buf + n, pt);
    return n;
}

/* Deterministic, so the benign race of two threads building it at once writes
 * identical bytes. That is the whole reason it is derived rather than random. */
static void zob_init(void)
{
    unsigned char msg[64], dig[32];
    int colour, pt, i;

    if (ZOB_READY) return;
    for (colour = GO_BLACK; colour <= GO_WHITE; colour++) {
        for (pt = 0; pt < GO_MAX_PTS; pt++) {
            unsigned long long v = 0;
            int len = zob_label(msg, colour, pt);
            sha256_short(msg, len, dig);
            for (i = 0; i < 8; i++)
                v = (v << 8) | (unsigned long long)dig[i];
            ZOB[colour][pt] = v;
        }
    }
    ZOB_READY = 1;
}

static unsigned long long zob(int colour, int pt)
{
    if (colour != GO_BLACK && colour != GO_WHITE) return 0;
    if (pt < 0 || pt >= GO_MAX_PTS) return 0;
    zob_init();
    return ZOB[colour][pt];
}

static unsigned long long go_zobrist(int colour, int pt) { return zob(colour, pt); }

/* ------------------------------------------------------------- the board ----- */

static struct go_board *go_board_new(int size)
{
    struct go_board *b;
    int r, c;

    if (size < GO_MIN_SIZE || size > GO_MAX_SIZE) return NULL;
    zob_init();

    b = (struct go_board *)calloc(1, sizeof(struct go_board));
    if (!b) return NULL;

    b->size   = size;
    b->stride = size + 2;
    b->pts    = b->stride * b->stride;
    b->nbr[0] = -1;
    b->nbr[1] = 1;
    b->nbr[2] = -b->stride;
    b->nbr[3] = b->stride;

    /* -1 and not 0: 0 is a real index into the padded array (the top left of
     * the ring), so 0 as "no ko" would forbid a point that exists. */
    b->ko_point = -1;
    b->ko_colour = GO_EMPTY;
    b->superko_on = 1;

    /* GO_EMPTY is 0 and calloc zeroed the interior, so only the ring is set.
     * The ring is the only thing making the neighbour arithmetic safe. */
    for (r = 0; r < b->stride; r++) {
        for (c = 0; c < b->stride; c++) {
            if (r == 0 || r == b->stride - 1 || c == 0 || c == b->stride - 1)
                b->colour[r * b->stride + c] = GO_BORDER;
        }
    }
    return b;
}

static void go_board_drop(struct go_board *b) { if (b) free(b); }

static struct go_board *go_board_copy(const struct go_board *b)
{
    struct go_board *n;
    if (!b) return NULL;
    n = (struct go_board *)malloc(sizeof(struct go_board));
    if (!n) return NULL;
    /* No pointers in the struct, so a copy is a flat byte copy and the two
     * boards share nothing at all. */
    memcpy(n, b, sizeof(struct go_board));
    return n;
}

/* ------------------------------------------------------------- the chains ---- */

/* A stamp rather than a clear, so the distinct-liberty count is O(chain).
 * The wrap is handled rather than ignored: a gate run does hundreds of
 * millions of counts and a wrapped stamp would silently collide with a stale
 * mark, undercounting a liberty in one position in a way nothing reports. */
static int next_stamp(struct go_board *b)
{
    if (b->mark_stamp >= 0x7ffffffe) {
        memset(b->mark, 0, sizeof(b->mark));
        b->mark_stamp = 0;
    }
    return ++b->mark_stamp;
}

/* EXACT, and distinctness is the whole point: an empty point adjacent to two
 * stones of the same chain is ONE liberty. Counting occurrences instead is the
 * bug the liberty-delta shortcut has, and phase 01 chose not to have it. */
static void recount(struct go_board *b, int root)
{
    int stamp, n = 0, pt;
    if (root < 0 || root >= b->pts) return;
    if (b->colour[root] != GO_BLACK && b->colour[root] != GO_WHITE) return;

    stamp = next_stamp(b);
    pt = root;
    do {
        int i;
        for (i = 0; i < 4; i++) {
            int q = pt + b->nbr[i];
            if (b->colour[q] == GO_EMPTY && b->mark[q] != stamp) {
                b->mark[q] = stamp;
                n++;
            }
        }
        pt = b->chain_next[pt];
    } while (pt != root);

    b->chain_libs[root] = n;
}

/* Relabel the SMALLER chain into the larger, which keeps chain_root a direct
 * answer rather than a tree needing path compression, and makes the work
 * O(smaller). Splicing two circular lists is two assignments. */
static int merge(struct go_board *b, int ra, int rb)
{
    int big, small, pt, tmp;

    if (ra == rb) return ra;
    if (b->chain_size[ra] >= b->chain_size[rb]) { big = ra; small = rb; }
    else                                        { big = rb; small = ra; }

    pt = small;
    do { b->chain_root[pt] = big; pt = b->chain_next[pt]; } while (pt != small);

    tmp = b->chain_next[big];
    b->chain_next[big] = b->chain_next[small];
    b->chain_next[small] = tmp;

    b->chain_size[big] += b->chain_size[small];
    b->chain_size[small] = 0;
    b->chain_libs[small] = 0;
    return big;
}

/* A STRUCTURE PRIMITIVE. It does not check legality, does not capture, and does
 * not know whose turn it is. An occupied or off-board point is a no-op rather
 * than a corruption, because the rules layer is what refuses those and it
 * should be the thing reporting the reason. */
static void go_put(struct go_board *b, int pt, int colour)
{
    int i, root;

    if (!b || pt < 0 || pt >= b->pts) return;
    if (colour != GO_BLACK && colour != GO_WHITE) return;
    if (b->colour[pt] != GO_EMPTY) return;   /* border is never empty, so this covers it */

    b->colour[pt] = (signed char)colour;
    b->hash ^= zob(colour, pt);
    b->stones[colour]++;

    b->chain_root[pt] = pt;
    b->chain_next[pt] = pt;
    b->chain_size[pt] = 1;
    b->chain_libs[pt] = 0;

    root = pt;
    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        if (b->colour[q] == colour) root = merge(b, root, b->chain_root[q]);
    }
    recount(b, root);

    /* every adjacent enemy chain just lost a liberty. Recounting the same root
     * twice is idempotent because the count is exact, so no bookkeeping. */
    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        if (b->colour[q] == GO_OTHER(colour)) recount(b, b->chain_root[q]);
    }
}

/* The other structure primitive: take the chain at pt off the board. Says
 * nothing about why. Returns the number of stones removed. */
static int go_lift(struct go_board *b, int pt)
{
    int pts[GO_MAX_PTS];
    int roots[GO_MAX_PTS];
    int n = 0, nroots = 0, i, k, root, cur, colour;

    if (!b || pt < 0 || pt >= b->pts) return 0;
    colour = b->colour[pt];
    if (colour != GO_BLACK && colour != GO_WHITE) return 0;

    root = b->chain_root[pt];
    cur = root;
    do { pts[n++] = cur; cur = b->chain_next[cur]; } while (cur != root);

    /* Collect the distinct neighbouring enemy chains BEFORE the stones go,
     * because once they are empty the adjacency that named them is gone. */
    for (i = 0; i < n; i++) {
        for (k = 0; k < 4; k++) {
            int q = pts[i] + b->nbr[k];
            if (b->colour[q] == GO_OTHER(colour)) {
                int r = b->chain_root[q], j, seen = 0;
                for (j = 0; j < nroots; j++) if (roots[j] == r) { seen = 1; break; }
                if (!seen) roots[nroots++] = r;
            }
        }
    }

    for (i = 0; i < n; i++) {
        b->colour[pts[i]] = GO_EMPTY;
        b->hash ^= zob(colour, pts[i]);
        b->chain_root[pts[i]] = 0;
        b->chain_next[pts[i]] = 0;
        b->chain_size[pts[i]] = 0;
        b->chain_libs[pts[i]] = 0;
    }
    b->stones[colour] -= n;

    for (i = 0; i < nroots; i++) recount(b, roots[i]);
    return n;
}

/* ----------------------------------------------------------- reading it ------ */

static int go_at(const struct go_board *b, int pt)
{
    if (!b || pt < 0 || pt >= b->pts) return GO_BORDER;
    return b->colour[pt];
}

static int go_libs(const struct go_board *b, int pt)
{
    if (!b || pt < 0 || pt >= b->pts) return -1;
    if (b->colour[pt] != GO_BLACK && b->colour[pt] != GO_WHITE) return -1;
    return b->chain_libs[b->chain_root[pt]];
}

static int go_chain_size(const struct go_board *b, int pt)
{
    if (!b || pt < 0 || pt >= b->pts) return 0;
    if (b->colour[pt] != GO_BLACK && b->colour[pt] != GO_WHITE) return 0;
    return b->chain_size[b->chain_root[pt]];
}

static int go_chain_at(const struct go_board *b, int pt, int *out)
{
    int n = 0, root, cur;
    if (!b || pt < 0 || pt >= b->pts) return 0;
    if (b->colour[pt] != GO_BLACK && b->colour[pt] != GO_WHITE) return 0;
    root = b->chain_root[pt];
    cur = root;
    do { if (out) out[n] = cur; n++; cur = b->chain_next[cur]; } while (cur != root);
    return n;
}

/* One byte per REAL point, row by row from the top. This is what makes a
 * zobrist match into a certainty: on a hash hit the caller memcmps this. */
static int go_pack(const struct go_board *b, unsigned char *buf)
{
    int r, c, n = 0;
    if (!b || !buf) return 0;
    for (r = 0; r < b->size; r++)
        for (c = 0; c < b->size; c++)
            buf[n++] = (unsigned char)b->colour[(r + 1) * b->stride + (c + 1)];
    return n;
}

static unsigned long long go_hash(const struct go_board *b) { return b ? b->hash : 0; }

static int go_stones(const struct go_board *b, int colour)
{
    if (!b || colour < 0 || colour > 3) return 0;
    return b->stones[colour];
}

/* ---------------------------------------------------------------- points ----- */

static int go_point_of(const struct go_board *b, int col, int row)
{
    if (!b || col < 0 || row < 0 || col >= b->size || row >= b->size) return -1;
    return (row + 1) * b->stride + (col + 1);
}

static int go_col_of(const struct go_board *b, int pt)
{
    if (!b || pt < 0 || pt >= b->pts) return -1;
    return pt % b->stride - 1;
}

static int go_row_of(const struct go_board *b, int pt)
{
    if (!b || pt < 0 || pt >= b->pts) return -1;
    return pt / b->stride - 1;
}

static int go_size_of(const struct go_board *b)   { return b ? b->size : 0; }
static int go_stride_of(const struct go_board *b) { return b ? b->stride : 0; }

/* The index into a packed position of a padded point, or -1 for the ring. */
static int buf_index(const struct go_board *b, int pt)
{
    int row, col;
    if (!b || pt < 0 || pt >= b->pts) return -1;
    row = pt / b->stride - 1;
    col = pt % b->stride - 1;
    if (row < 0 || col < 0 || row >= b->size || col >= b->size) return -1;
    return row * b->size + col;
}

/* ==========================================================================
 * THE RULES OF PLAY. Everything above this line judges nothing.
 * ========================================================================== */

/* ------------------------------------------------- the superko history ------
 *
 * A separate object, not a member of the board, and include/go_abi.h says why:
 * a board carrying its own history would make every playout copy 110 KB.
 */

struct go_hist {
    int n;
    int cap;
    int pts;                        /* bytes per position: size * size */
    unsigned long long *hash;
    unsigned char *pos;
};

static struct go_hist *go_hist_new(int size)
{
    struct go_hist *h;
    if (size < GO_MIN_SIZE || size > GO_MAX_SIZE) return NULL;

    h = (struct go_hist *)calloc(1, sizeof(struct go_hist));
    if (!h) return NULL;

    h->pts = size * size;
    h->cap = 64;
    h->hash = (unsigned long long *)malloc(sizeof(unsigned long long) * (size_t)h->cap);
    h->pos  = (unsigned char *)malloc((size_t)h->cap * (size_t)h->pts);
    if (!h->hash || !h->pos) {
        if (h->hash) free(h->hash);
        if (h->pos)  free(h->pos);
        free(h);
        return NULL;
    }
    return h;
}

static void go_hist_drop(struct go_hist *h)
{
    if (!h) return;
    if (h->hash) free(h->hash);
    if (h->pos)  free(h->pos);
    free(h);
}

/* A cloned board must get its own history with the same contents. Sharing one
 * would mean a move explored down one line refusing a move in the other, and
 * truncating one to just the current position would silently turn superko off
 * for the clone. Both failures look like one inexplicable refusal much later. */
static struct go_hist *go_hist_copy(const struct go_hist *h)
{
    struct go_hist *n;
    if (!h) return NULL;

    n = (struct go_hist *)calloc(1, sizeof(struct go_hist));
    if (!n) return NULL;

    n->pts = h->pts;
    n->cap = h->cap;
    n->n   = h->n;
    n->hash = (unsigned long long *)malloc(sizeof(unsigned long long) * (size_t)n->cap);
    n->pos  = (unsigned char *)malloc((size_t)n->cap * (size_t)n->pts);
    if (!n->hash || !n->pos) {
        if (n->hash) free(n->hash);
        if (n->pos)  free(n->pos);
        free(n);
        return NULL;
    }
    memcpy(n->hash, h->hash, sizeof(unsigned long long) * (size_t)h->n);
    memcpy(n->pos,  h->pos,  (size_t)h->n * (size_t)h->pts);
    return n;
}

static int  go_hist_len(const struct go_hist *h) { return h ? h->n : 0; }
static void go_hist_clear(struct go_hist *h)     { if (h) h->n = 0; }

static int hist_grow(struct go_hist *h)
{
    unsigned long long *nh;
    unsigned char *np;
    int cap = h->cap * 2;

    nh = (unsigned long long *)realloc(h->hash, sizeof(unsigned long long) * (size_t)cap);
    if (!nh) return 0;
    h->hash = nh;

    np = (unsigned char *)realloc(h->pos, (size_t)cap * (size_t)h->pts);
    if (!np) return 0;
    h->pos = np;

    h->cap = cap;
    return 1;
}

static int go_hist_push(struct go_hist *h, const struct go_board *b)
{
    if (!h || !b) return 0;
    if (b->size * b->size != h->pts) return 0;   /* a history is for one size */
    if (h->n == h->cap && !hist_grow(h)) return 0;
    h->hash[h->n] = b->hash;
    (void)go_pack(b, h->pos + (size_t)h->n * (size_t)h->pts);
    h->n++;
    return 1;
}

/* THE HASH IS A FILTER AND THE COMPARE IS THE VERDICT.
 *
 * A 64-bit collision across the few hundred positions of one game is somewhere
 * around one in 10^14, and that is still not a reason to let a hash decide
 * whether a move is legal: the symptom would be a legal move refused, once, in
 * a game nobody can reproduce. So a hash match is followed by a memcmp of the
 * packed position, and only an exact match refuses. The memcmp costs at most
 * 361 bytes and happens only on a hit. */
static int hist_seen(const struct go_hist *h, unsigned long long hash,
                     const unsigned char *packed)
{
    int i;
    if (!h) return 0;
    for (i = 0; i < h->n; i++) {
        if (h->hash[i] != hash) continue;
        if (memcmp(h->pos + (size_t)i * (size_t)h->pts, packed, (size_t)h->pts) == 0)
            return 1;
    }
    return 0;
}

static int go_hist_has(const struct go_hist *h, const struct go_board *b)
{
    unsigned char packed[GO_MAX_PTS];
    if (!h || !b) return 0;
    (void)go_pack(b, packed);
    return hist_seen(h, b->hash, packed);
}

/* ------------------------------------------------------------ would it? -----
 *
 * An enemy chain adjacent to an empty point pt is captured by a play at pt if
 * and only if its liberty count is exactly 1. It needs no search for WHICH
 * liberty: pt is empty and adjacent to that chain, so pt is one of its
 * liberties, and if it has only one then pt is it.
 */
static int dies_to(const struct go_board *b, int q)
{
    return b->chain_libs[b->chain_root[q]] == 1;
}

/* The hash the position WOULD have, without touching the board. */
static unsigned long long go_hash_after(const struct go_board *b, int pt, int colour)
{
    unsigned long long hsh;
    int roots[4];
    int nroots = 0;
    int i, j, cur, them;

    if (!b || pt < 0 || pt >= b->pts) return 0;
    if (colour != GO_BLACK && colour != GO_WHITE) return 0;

    them = GO_OTHER(colour);
    hsh = b->hash ^ zob(colour, pt);

    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        int r, seen = 0;
        if (b->colour[q] != them) continue;
        if (!dies_to(b, q)) continue;
        r = b->chain_root[q];
        for (j = 0; j < nroots; j++) if (roots[j] == r) { seen = 1; break; }
        if (seen) continue;
        roots[nroots++] = r;
        cur = r;
        do { hsh ^= zob(them, cur); cur = b->chain_next[cur]; } while (cur != r);
    }
    return hsh;
}

/* The packed position the board WOULD have: pack what is there, then patch the
 * played point and the captured stones. Cheaper than copying the board, and
 * only ever reached on a hash hit. */
static void packed_after(const struct go_board *b, int pt, int colour, unsigned char *buf)
{
    int roots[4];
    int nroots = 0;
    int i, j, cur, them, ix;

    (void)go_pack(b, buf);
    ix = buf_index(b, pt);
    if (ix >= 0) buf[ix] = (unsigned char)colour;

    them = GO_OTHER(colour);
    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        int r, seen = 0;
        if (b->colour[q] != them) continue;
        if (!dies_to(b, q)) continue;
        r = b->chain_root[q];
        for (j = 0; j < nroots; j++) if (roots[j] == r) { seen = 1; break; }
        if (seen) continue;
        roots[nroots++] = r;
        cur = r;
        do {
            ix = buf_index(b, cur);
            if (ix >= 0) buf[ix] = GO_EMPTY;
            cur = b->chain_next[cur];
        } while (cur != r);
    }
}

/* ---------------------------------------------------------------- legal ----- */

/* THE FIVE STEPS, IN ORDER, AND THE ORDER IS THE RULE.
 *
 *   1. the point is on the board and empty     -> GO_ILL_OFF / GO_ILL_TAKEN
 *   2. it is not the ko point                  -> GO_ILL_KO
 *   3. the capture is accounted for FIRST
 *   4. only then, has the played chain a liberty -> GO_ILL_SUICIDE
 *   5. the resulting position is new           -> GO_ILL_REPEAT
 *
 * Article 5 puts 3 before 4: "the player must remove all these opposing
 * stones ... the move is completed when the stones have been removed." So A
 * MOVE THAT CAPTURES IS NEVER SUICIDE. Testing suicide before capture refuses
 * every capture of a surrounded group, and does it in the way that is hardest
 * to notice: a suite of capture-the-lone-stone tests still passes, because a
 * lone stone leaves an empty point behind it, and only captures into a filled
 * shape fail.
 *
 * NOTHING HERE MUTATES AND NOTHING HERE ALLOCATES, except a stack buffer on a
 * superko hash hit. Steps 3 and 4 are folded into one pass over the four
 * neighbours, which computes the same answer the place-then-clear-then-check
 * procedure would: the played chain has a liberty if any neighbour is empty, or
 * any adjacent enemy chain dies (freeing a point next to pt), or any adjacent
 * friendly chain has a liberty that is not pt. legal_moves calls this up to 361
 * times per node and a playout calls legal_moves per move, so a board copy here
 * would be the cost of the whole search.
 */
static int go_legal(const struct go_board *b, const struct go_hist *h, int pt, int colour)
{
    int i, breathes = 0;

    if (!b) return GO_ILL_OFF;
    if (colour != GO_BLACK && colour != GO_WHITE) return GO_ILL_COLOUR;
    if (pt < 0 || pt >= b->pts) return GO_ILL_OFF;
    if (b->colour[pt] == GO_BORDER) return GO_ILL_OFF;
    if (b->colour[pt] != GO_EMPTY) return GO_ILL_TAKEN;
    if (pt == b->ko_point && colour == b->ko_colour) return GO_ILL_KO;

    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        int c = b->colour[q];
        if (c == GO_EMPTY) {
            breathes = 1;
        } else if (c == GO_OTHER(colour)) {
            if (dies_to(b, q)) breathes = 1;          /* step 3, before step 4 */
        } else if (c == colour) {
            if (b->chain_libs[b->chain_root[q]] > 1) breathes = 1;
        }
    }
    if (!breathes) return GO_ILL_SUICIDE;

    if (h && b->superko_on) {
        unsigned char packed[GO_MAX_PTS];
        unsigned long long after = go_hash_after(b, pt, colour);
        int i2;
        for (i2 = 0; i2 < h->n; i2++) {
            if (h->hash[i2] != after) continue;
            packed_after(b, pt, colour, packed);
            if (hist_seen(h, after, packed)) return GO_ILL_REPEAT;
            break;
        }
    }
    return GO_OK;
}

static int go_legal_moves(const struct go_board *b, const struct go_hist *h,
                          int colour, int *out)
{
    int r, c, n = 0;
    if (!b) return 0;
    for (r = 0; r < b->size; r++) {
        for (c = 0; c < b->size; c++) {
            int pt = (r + 1) * b->stride + (c + 1);
            if (b->colour[pt] != GO_EMPTY) continue;      /* the cheap test first */
            if (go_legal(b, h, pt, colour) != GO_OK) continue;
            if (out) out[n] = pt;
            n++;
        }
    }
    return n;
}

/* ------------------------------------------------------------------ ko ------ */

/* ARTICLE 6'S SHAPE, AND ALL THREE CLAUSES ARE LOAD-BEARING.
 *
 * Article 6 describes a shape rather than a procedure: "A shape in which the
 * players can alternately capture and recapture one opposing stone is called a
 * 'ko'." So the test is whether THIS move created that shape, and it did only
 * if all three hold. Each comment says what breaks without its clause. */
static void ko_set(struct go_board *b, int pt, int ncaps, int captured, int colour)
{
    b->ko_point = -1;
    b->ko_colour = GO_EMPTY;

    /* Without this, a capture of two or more stones sets a phantom ko and the
     * opponent is refused a point Article 6 says nothing about. */
    if (ncaps != 1) return;

    /* Without this, a stone that joins a larger group AND captures one stone
     * sets a ko. Article 6 does not create one: the recapture would not be of
     * a single stone in a shape that can repeat. */
    if (b->chain_size[b->chain_root[pt]] != 1) return;

    /* Without this, a capture that leaves the capturing stone with room sets a
     * ko where no recapture was possible anyway. The symptom is the worst of
     * the three: a legal move refused somewhere apparently unrelated, three
     * moves later. */
    if (b->chain_libs[b->chain_root[pt]] != 1) return;

    b->ko_point = captured;

    /* AND THE COLOUR IT IS FORBIDDEN TO, which is the player whose stone was
     * just taken. Article 6 names one player: "A player whose stone has been
     * captured in a ko cannot recapture in that ko on the next move." The
     * capturer is not restricted, and on a filled board sometimes wants to
     * play the point to connect. Refusing both colours is the easy version and
     * it refuses a legal move. */
    b->ko_colour = GO_OTHER(colour);
}

static int  go_ko_point(const struct go_board *b)   { return b ? b->ko_point : -1; }
static int  go_ko_colour(const struct go_board *b)  { return b ? b->ko_colour : GO_EMPTY; }
static int  go_superko_on(const struct go_board *b) { return b ? b->superko_on : 0; }

static void go_set_superko(struct go_board *b, int on)
{
    if (b) b->superko_on = on ? 1 : 0;
}

/* ============================================================== the scorers ===
 *
 * Two of them over ONE flood fill, because both ask the same question of the
 * empty points and differ only in what they do with the answer.
 *
 *   Japanese territory: an empty region reaching only one colour is that
 *     colour's, a region reaching both is dame, and a region the players agreed
 *     is seki counts for nobody.
 *   Tromp-Taylor area:  the same classification, plus your stones on the board.
 *
 * The second is here for two reasons. It needs nobody's agreement, so it is
 * what a game whose players cannot agree falls through to; and the two must
 * agree under a published condition, which is the only differential test this
 * distribution can have, since the XS-only decision left one implementation of
 * everything else.
 */

/* One pass over the empty points. Fills the eye counts, the dame count, the
 * stone counts and the area scores; the caller applies prisoners and komi. */
static void analyse_map(const struct go_board *b, const int *seki, int nseki,
                        struct go_score *out, signed char *owner);

static void analyse(const struct go_board *b, const int *seki, int nseki,
                    struct go_score *out)
{
    analyse_map(b, seki, nseki, out, NULL);
}

/* The one classification. `owner`, when given, gets one value per padded point:
 * the colour whose territory it is, or GO_EMPTY for dame, for an agreed seki,
 * and for anything holding a stone.
 *
 * It is the same walk that produces the score because a SECOND implementation
 * of this is a second thing to get wrong, and the way it goes wrong is subtle:
 * territory is a property of a REGION, so an empty point beside one black stone
 * on an otherwise open board belongs to NOBODY. A per-point version of this
 * gave a nearly empty board eight points of territory where the scorer, quite
 * rightly, gave it none. */
static void analyse_map(const struct go_board *b, const int *seki, int nseki,
                        struct go_score *out, signed char *owner)
{
    int seen[GO_MAX_PTS];
    int stack[GO_MAX_PTS];
    int region[GO_MAX_PTS];
    int r, c, i, k, sp, n;

    out->eyes_b = out->eyes_w = 0;
    out->territory_b = out->territory_w = 0;
    out->dame = 0;
    out->area_b = out->area_w = 0;
    out->stones_b = b->stones[GO_BLACK];
    out->stones_w = b->stones[GO_WHITE];

    for (i = 0; i < b->pts; i++) seen[i] = 0;

    for (r = 0; r < b->size; r++) {
        for (c = 0; c < b->size; c++) {
            int p = (r + 1) * b->stride + (c + 1);
            int touches_b = 0, touches_w = 0, is_seki = 0;

            if (b->colour[p] != GO_EMPTY || seen[p]) continue;

            /* the region, and which colours it reaches */
            n = 0;
            sp = 0;
            stack[sp++] = p;
            seen[p] = 1;
            while (sp > 0) {
                int cur = stack[--sp];
                region[n++] = cur;
                for (k = 0; k < 4; k++) {
                    int q = cur + b->nbr[k];
                    if (b->colour[q] == GO_BLACK) { touches_b = 1; continue; }
                    if (b->colour[q] == GO_WHITE) { touches_w = 1; continue; }
                    if (b->colour[q] != GO_EMPTY) continue;      /* the ring */
                    if (seen[q]) continue;
                    seen[q] = 1;
                    stack[sp++] = q;
                }
            }

            /* agreed seki: any listed point taints the whole region it is in */
            for (i = 0; i < nseki && !is_seki; i++)
                for (k = 0; k < n; k++)
                    if (region[k] == seki[i]) { is_seki = 1; break; }

            if (touches_b && !touches_w) {
                out->eyes_b += n;
                out->area_b += n;
                if (!is_seki) out->territory_b += n;
                if (owner && !is_seki)
                    for (k = 0; k < n; k++) owner[region[k]] = GO_BLACK;
            } else if (touches_w && !touches_b) {
                out->eyes_w += n;
                out->area_w += n;
                if (!is_seki) out->territory_w += n;
                if (owner && !is_seki)
                    for (k = 0; k < n; k++) owner[region[k]] = GO_WHITE;
            } else {
                /* reaching both colours, or neither on an empty board */
                out->dame += n;
            }
        }
    }

    out->area_b += out->stones_b;
    out->area_w += out->stones_w;
}

/* The same five steps score_jp takes, stopping after the classification. Dead
 * stones come off on a copy first, because a point a dead stone was standing on
 * is territory once it is gone. */
static void go_territory(const struct go_board *b,
                         const int *dead, int ndead,
                         const int *seki, int nseki,
                         signed char *out)
{
    struct go_board *work;
    struct go_score s;
    int i;

    if (!b || !out) return;
    for (i = 0; i < b->pts; i++) out[i] = GO_EMPTY;

    work = go_board_copy(b);
    if (!work) return;

    for (i = 0; i < ndead; i++) {
        int pt = dead[i];
        if (pt < 0 || pt >= work->pts) continue;
        if (work->colour[pt] != GO_BLACK && work->colour[pt] != GO_WHITE) continue;
        (void)go_lift(work, pt);
    }

    analyse_map(work, seki, nseki, &s, out);
    go_board_drop(work);
}

static void go_score_area(const struct go_board *b, struct go_score *out)
{
    if (!b || !out) return;
    analyse(b, NULL, 0, out);
    out->prisoners_b = out->prisoners_w = 0;
    out->score_b = out->score_w = 0;
}

static void go_score_jp(const struct go_board *b,
                        const int *dead, int ndead,
                        const int *seki, int nseki,
                        int prisoners_b, int prisoners_w,
                        int komi_tenths,
                        struct go_score *out)
{
    struct go_board *work;
    int i;

    if (!b || !out) return;

    /* Step 1. The dead come off, and each stone goes to the player who did NOT
     * own it. Done on a COPY, because scoring a position must not change it:
     * the site scores a game and then goes on serving the same board to a
     * spectator. */
    work = go_board_copy(b);
    if (!work) return;

    for (i = 0; i < ndead; i++) {
        int pt = dead[i];
        int colour, gone;
        if (pt < 0 || pt >= work->pts) continue;
        colour = work->colour[pt];
        if (colour != GO_BLACK && colour != GO_WHITE) continue;
        gone = go_lift(work, pt);
        if (colour == GO_BLACK) prisoners_w += gone;   /* black stones, white holds them */
        else                    prisoners_b += gone;
    }

    /* Steps 2 to 4. */
    analyse(work, seki, nseki, out);

    out->prisoners_b = prisoners_b;
    out->prisoners_w = prisoners_w;

    /* Step 5, and the direction of it is the rule. Article 10.2 fills each
     * player's prisoners INTO THE OPPONENT'S TERRITORY, so they come off the
     * opponent rather than going on to your own. */
    out->score_b = (out->territory_b - prisoners_w) * 10;
    out->score_w = (out->territory_w - prisoners_b) * 10 + komi_tenths;

    go_board_drop(work);
}

/* ====================================================== Benson's algorithm ===
 *
 * D. B. Benson, "Life in the Game of Go", Information Sciences 10 (1976).
 *
 * The chains that are UNCONDITIONALLY ALIVE: alive even if their owner never
 * answers another move, whatever the opponent does. It is the only part of life
 * and death that is decidable without search, and this engine claims to know
 * nothing else about it.
 *
 * The algorithm, so the code below can be read against it:
 *
 *   X = every chain of the colour
 *   R = every region: a maximal connected set of points NOT of the colour
 *
 *   repeat until nothing is removed:
 *     remove from X every chain with fewer than TWO VITAL regions in R,
 *       where a region is vital to a chain when EVERY EMPTY POINT in it is
 *       adjacent to that chain
 *     remove from R every region that touches a chain no longer in X
 *
 *   what remains in X is unconditionally alive
 *
 * TWO VITAL REGIONS, NOT TWO EYE POINTS, and the difference is the thing this
 * gets right that a count of eyes does not. A group around a single two-point
 * eye has two eye points and ONE vital region, and it is not unconditionally
 * alive. t/10-benson.t has that position.
 */

/* Every empty point of the region is a liberty of the chain. */
static int region_is_vital(const struct go_board *b, int root,
                           const int *pts, int from, int len)
{
    int i, k;
    for (i = from; i < from + len; i++) {
        int p = pts[i];
        int touches = 0;
        if (b->colour[p] != GO_EMPTY) continue;      /* opponent stones do not count */
        for (k = 0; k < 4; k++) {
            int q = p + b->nbr[k];
            if (b->chain_root[q] == root && b->colour[q] != GO_EMPTY) { touches = 1; break; }
        }
        if (!touches) return 0;
    }
    return 1;
}

static int go_alive(const struct go_board *b, int colour, int *out)
{
    int region_of[GO_MAX_PTS];      /* which region a point is in, or -1 */
    int pts[GO_MAX_PTS];            /* every region's points, laid end to end */
    int rstart[GO_MAX_PTS];
    int rlen[GO_MAX_PTS];
    int stack[GO_MAX_PTS];
    int live[GO_MAX_PTS];           /* by chain ROOT: is it still a candidate */
    int rlive[GO_MAX_PTS];          /* by region: is it still a candidate */
    int nregions = 0, npts = 0, n = 0;
    int r, c, i, k, sp, changed;

    if (!b || (colour != GO_BLACK && colour != GO_WHITE)) return 0;

    for (i = 0; i < b->pts; i++) { region_of[i] = -1; live[i] = 0; }

    /* X starts as every chain of the colour. `live` is indexed by root, so a
     * point that is not a root simply never gets looked at. */
    for (r = 0; r < b->size; r++)
        for (c = 0; c < b->size; c++) {
            int p = (r + 1) * b->stride + (c + 1);
            if (b->colour[p] == colour) live[b->chain_root[p]] = 1;
        }

    /* R starts as every maximal connected set of points that are NOT the
     * colour. The sentinel ring is not a point, so it bounds the fill. */
    for (r = 0; r < b->size; r++) {
        for (c = 0; c < b->size; c++) {
            int p = (r + 1) * b->stride + (c + 1);
            if (b->colour[p] == colour || region_of[p] >= 0) continue;

            rstart[nregions] = npts;
            sp = 0;
            stack[sp++] = p;
            region_of[p] = nregions;
            while (sp > 0) {
                int cur = stack[--sp];
                pts[npts++] = cur;
                for (k = 0; k < 4; k++) {
                    int q = cur + b->nbr[k];
                    if (b->colour[q] == GO_BORDER) continue;
                    if (b->colour[q] == colour) continue;
                    if (region_of[q] >= 0) continue;
                    region_of[q] = nregions;
                    stack[sp++] = q;
                }
            }
            rlen[nregions] = npts - rstart[nregions];
            rlive[nregions] = 1;
            nregions++;
        }
    }

    /* The two removals, alternating until neither fires. */
    do {
        changed = 0;

        /* a chain with fewer than two vital candidate regions goes */
        for (r = 0; r < b->size; r++) {
            for (c = 0; c < b->size; c++) {
                int p = (r + 1) * b->stride + (c + 1);
                int root, vital = 0, seen[4], nseen = 0;
                if (b->colour[p] != colour) continue;
                root = b->chain_root[p];
                if (p != root || !live[root]) continue;

                /* count the distinct candidate regions adjacent to this chain
                 * that are vital to it. Walk the chain's stones; a region can
                 * touch a chain at many points and counts once. */
                {
                    int cur = root;
                    do {
                        for (k = 0; k < 4; k++) {
                            int q = cur + b->nbr[k];
                            int reg, j, dup = 0;
                            if (b->colour[q] == GO_BORDER) continue;
                            reg = region_of[q];
                            if (reg < 0 || !rlive[reg]) continue;
                            for (j = 0; j < nseen; j++) if (seen[j] == reg) { dup = 1; break; }
                            if (dup) continue;
                            if (nseen < 4) seen[nseen++] = reg;   /* two is all we need */
                            if (region_is_vital(b, root, pts, rstart[reg], rlen[reg]))
                                vital++;
                        }
                        cur = b->chain_next[cur];
                    } while (cur != root && vital < 2);
                }

                if (vital < 2) { live[root] = 0; changed = 1; }
            }
        }

        /* a region touching a chain that has gone goes too */
        for (i = 0; i < nregions; i++) {
            int j;
            if (!rlive[i]) continue;
            for (j = rstart[i]; j < rstart[i] + rlen[i]; j++) {
                int p = pts[j];
                for (k = 0; k < 4; k++) {
                    int q = p + b->nbr[k];
                    if (b->colour[q] != colour) continue;
                    if (!live[b->chain_root[q]]) { rlive[i] = 0; changed = 1; break; }
                }
                if (!rlive[i]) break;
            }
        }
    } while (changed);

    /* what survived, as points */
    for (r = 0; r < b->size; r++)
        for (c = 0; c < b->size; c++) {
            int p = (r + 1) * b->stride + (c + 1);
            if (b->colour[p] != colour) continue;
            if (!live[b->chain_root[p]]) continue;
            if (out) out[n] = p;
            n++;
        }

    return n;
}

/* ---------------------------------------------------------------- play ------ */

static void go_play(struct go_board *b, struct go_hist *h, int pt, int colour,
                    struct go_played *out)
{
    int i, j, code, nroots = 0;
    int roots[4];

    if (!out) return;
    out->code = GO_ILL_OFF;
    out->ncaps = 0;
    out->ko_point = -1;
    if (!b) return;

    /* Refuse BEFORE touching anything, so a refused play leaves the board
     * exactly as it was and a caller can offer the reason and try again. */
    code = go_legal(b, h, pt, colour);
    out->code = code;
    out->ko_point = b->ko_point;
    if (code != GO_OK) return;

    go_put(b, pt, colour);

    /* Article 5: the opposing stones come off, and the move is completed when
     * they have. An adjacent enemy chain is captured exactly when go_put's
     * recount has left it at zero. */
    for (i = 0; i < 4; i++) {
        int q = pt + b->nbr[i];
        int r, seen = 0, cur;
        if (b->colour[q] != GO_OTHER(colour)) continue;
        if (b->chain_libs[b->chain_root[q]] != 0) continue;
        r = b->chain_root[q];
        for (j = 0; j < nroots; j++) if (roots[j] == r) { seen = 1; break; }
        if (seen) continue;
        roots[nroots++] = r;

        /* record the stones before they go, because after go_lift the chain
         * that named them does not exist */
        cur = r;
        do { out->caps[out->ncaps++] = cur; cur = b->chain_next[cur]; } while (cur != r);
        (void)go_lift(b, r);
    }

    ko_set(b, pt, out->ncaps, out->ncaps == 1 ? out->caps[0] : -1, colour);
    out->ko_point = b->ko_point;

    if (h) (void)go_hist_push(h, b);
}

/* A pass clears the ko point, because Article 6 forbids the recapture on the
 * NEXT move only: after a pass, the recapture is the move after that.
 *
 * It pushes nothing onto the history. A pass changes no colouring, so the
 * colouring is already there from the move that made it, and pushing it again
 * would be a duplicate at best. The direction that actually bites is the other
 * one: an engine that treats a pass as a position-producing event and pushes
 * can end up refusing the next real move that returns to a colouring, for a
 * reason no player could ever see. */
static void go_pass(struct go_board *b, int colour)
{
    (void)colour;
    if (!b) return;
    b->ko_point = -1;
    b->ko_colour = GO_EMPTY;
}

/* ------------------------------------------------------------- the table ----- */

/* NAMED ASSIGNMENT, NOT A POSITIONAL INITIALISER, and not a designated one
 * either. A positional list silently binds the wrong function to a member the
 * day somebody reorders the struct, and the symptom is a call through a
 * plausible-looking pointer. A designated initialiser would fix that and would
 * also put a C99-only construct in a file that has to build under old MSVC.
 * So the table is filled in by name, once, here. The writes are identical on
 * every call, so the benign race costs nothing. */

static struct go_abi GO_TABLE;
static int GO_TABLE_READY = 0;

/* go_search.c fills in its own four members. Declared here rather than in
 * go_abi.h because it is not part of the published ABI: a consumer reaches the
 * search through the table like everything else.
 *
 * The two files call into each other, and it terminates: go_abi_table calls
 * this while building the table, and go_search.c only calls go_abi_table from
 * inside a search, which is long after the table is ready. */
void go_search_install(struct go_abi *t);

const struct go_abi *go_abi_table(void)
{
    if (!GO_TABLE_READY) {
        GO_TABLE.abi_version = GO_ABI_VERSION;

        GO_TABLE.board_new   = go_board_new;
        GO_TABLE.board_drop  = go_board_drop;
        GO_TABLE.board_copy  = go_board_copy;

        GO_TABLE.at          = go_at;
        GO_TABLE.libs        = go_libs;
        GO_TABLE.chain_at    = go_chain_at;
        GO_TABLE.chain_size  = go_chain_size;
        GO_TABLE.pack        = go_pack;
        GO_TABLE.hash        = go_hash;
        GO_TABLE.stones      = go_stones;

        GO_TABLE.point_of    = go_point_of;
        GO_TABLE.col_of      = go_col_of;
        GO_TABLE.row_of      = go_row_of;
        GO_TABLE.size_of     = go_size_of;
        GO_TABLE.stride_of   = go_stride_of;

        GO_TABLE.put         = go_put;
        GO_TABLE.lift        = go_lift;

        GO_TABLE.zobrist     = go_zobrist;

        /* appended at version 2. Nothing above this line moved. */
        GO_TABLE.hist_new    = go_hist_new;
        GO_TABLE.hist_drop   = go_hist_drop;
        GO_TABLE.hist_copy   = go_hist_copy;
        GO_TABLE.hist_len    = go_hist_len;
        GO_TABLE.hist_clear  = go_hist_clear;
        GO_TABLE.hist_push   = go_hist_push;
        GO_TABLE.hist_has    = go_hist_has;

        GO_TABLE.legal       = go_legal;
        GO_TABLE.legal_moves = go_legal_moves;
        GO_TABLE.play        = go_play;
        GO_TABLE.pass        = go_pass;

        GO_TABLE.ko_point    = go_ko_point;
        GO_TABLE.ko_colour   = go_ko_colour;
        GO_TABLE.set_superko = go_set_superko;
        GO_TABLE.superko_on  = go_superko_on;
        GO_TABLE.hash_after  = go_hash_after;

        /* appended at version 3 */
        GO_TABLE.alive       = go_alive;

        /* appended at version 4 */
        GO_TABLE.score_jp    = go_score_jp;
        GO_TABLE.score_area  = go_score_area;

        /* appended at version 5 */
        GO_TABLE.territory   = go_territory;

        /* appended at version 6, from go_search.c */
        go_search_install(&GO_TABLE);

        GO_TABLE_READY = 1;
    }
    return &GO_TABLE;
}
