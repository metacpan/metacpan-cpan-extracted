/* sth_rules.c - a game: whose turn, who is home, in what places, and the end.
 *
 * PERL-FREE by design: see include/sth_abi.h.
 *
 * THIS FILE'S SCOPE, version 4. Only "every piece home" is the rule of the
 * game (W). Everything else here is this dist's house rule, because W and D
 * say nothing: the parked piece (a home full of pieces, one of them the seat's
 * own, is home), the pass of a seat with no move, the end when nobody can
 * move, the ply cap, and where a resigning seat is placed.
 */

#include <string.h>
#include "sth_internal.h"

void sth_game_init(struct sth_board *b)
{
    int i;
    b->ply = 0;
    b->cap = STH_PLY_CAP_PER_SEAT * b->seats;
    b->pass_run = 0;
    b->finished_n = 0;
    b->resigned_n = 0;
    for (i = 0; i < STH_SEATS_MAX; i++) { b->finished[i] = -1; b->resigned[i] = -1; }
    b->over = 0;
    b->how = STH_ONGOING;
}

static int seat_ok(const struct sth_board *b, int seat)
{
    return b && seat >= 0 && seat < b->seats;
}

static int home_point(const struct sth_board *b, int seat)
{
    return (STH_LAYOUT[b->seats][seat] + 3) % STH_POINTS;
}

static int in_list(const int *list, int n, int seat)
{
    int i;
    for (i = 0; i < n; i++) if (list[i] == seat) return 1;
    return 0;
}

static int is_finished(const struct sth_board *b, int seat)
{
    return in_list(b->finished, b->finished_n, seat);
}

static int is_resigned(const struct sth_board *b, int seat)
{
    return in_list(b->resigned, b->resigned_n, seat);
}

/* Still racing: not home and not resigned. */
static int active(const struct sth_board *b, int seat)
{
    return !is_finished(b, seat) && !is_resigned(b, seat);
}

static int active_count(const struct sth_board *b)
{
    int s, n = 0;
    for (s = 0; s < b->seats; s++) n += active(b, s);
    return n;
}

/* THE PARKED PIECE (G2). Every hole of the home holds a piece, and at least
 * one of them is the seat's own. A rival who never moves a piece out of its
 * start, which is this seat's home, cannot keep this seat from finishing. */
int sth_home_complete(const struct sth_board *b, int seat)
{
    int p, i, c, own = 0;
    if (!seat_ok(b, seat)) return 0;
    p = home_point(b, seat);
    for (i = 0; i < STH_POINT_HOLES; i++) {
        c = b->cell[STH_SQ_OF[STH_POINT_LIST[p][i]]];
        if (!STH_IS_PIECE(c)) return 0;
        own += c == seat;
    }
    if (b->pieces == STH_PIECES_MAX) {
        for (i = 0; i < STH_FRONT_HOLES; i++) {
            c = b->cell[STH_SQ_OF[STH_FRONT[p][i]]];
            if (!STH_IS_PIECE(c)) return 0;
            own += c == seat;
        }
    }
    return own > 0;
}

int sth_finished(const struct sth_board *b, int seat)
{
    return seat_ok(b, seat) && is_finished(b, seat);
}

static int hex_distance(int a, int b)
{
    int dx = STH_HX[a] - STH_HX[b], dy = STH_HY[a] - STH_HY[b], dz = -dx - dy;
    if (dx < 0) dx = -dx;
    if (dy < 0) dy = -dy;
    if (dz < 0) dz = -dz;
    return (dx + dy + dz) / 2;
}

/* DISTANCE LEFT: for each of the seat's pieces, how far it is from the tip of
 * its home, added up, less what a full home of its own pieces adds up to. A
 * home full of the seat's own pieces is 0, and every piece out of place adds
 * to it. It is what a capped or stuck game is placed by. */
int sth_distance_left(const struct sth_board *b, int seat)
{
    int p, tip, h, i, sum = 0, floor = 0;
    if (!seat_ok(b, seat)) return -1;
    p = home_point(b, seat);
    tip = STH_POINT_LIST[p][0];
    for (i = 0; i < STH_POINT_HOLES; i++) {
        int k, n = 0;
        for (k = 0; k < STH_DIRS; k++)
            n += STH_HOLE_AT[STH_SQ_OF[STH_POINT_LIST[p][i]] + STH_STEP[k]] >= 0;
        if (n == 2) tip = STH_POINT_LIST[p][i];
    }
    for (h = 0; h < STH_HOLES; h++)
        if (b->cell[STH_SQ_OF[h]] == seat) sum += hex_distance(h, tip);
    for (i = 0; i < STH_POINT_HOLES; i++) floor += hex_distance(STH_POINT_LIST[p][i], tip);
    if (b->pieces == STH_PIECES_MAX)
        for (i = 0; i < STH_FRONT_HOLES; i++) floor += hex_distance(STH_FRONT[p][i], tip);
    return sum - floor;
}

/* ---- places ------------------------------------------------------------------
 *
 * Seats home, in the order they got there; then the seats still racing when
 * the game ended, the one left alone or, at the cap or a deadlock, by distance
 * left, fewest first, equal distances sharing a place; then the seats that
 * resigned, the last to resign first. While the game runs, only a seat home
 * has a place.
 */

int sth_place_of(const struct sth_board *b, int seat)
{
    int i, s, place, mine, ahead;
    if (!seat_ok(b, seat)) return 0;
    for (i = 0; i < b->finished_n; i++)
        if (b->finished[i] == seat) return i + 1;
    if (!b->over) return 0;
    place = b->finished_n + 1;
    if (active(b, seat)) {
        mine = sth_distance_left(b, seat);
        ahead = 0;
        for (s = 0; s < b->seats; s++)
            if (s != seat && active(b, s) && sth_distance_left(b, s) < mine) ahead++;
        return place + ahead;
    }
    place += active_count(b);
    for (i = b->resigned_n - 1; i >= 0; i--, place++)
        if (b->resigned[i] == seat) return place;
    return 0;
}

/* ---- the turn ---------------------------------------------------------------- */

static void next_turn(struct sth_board *b)
{
    int s, k;
    for (k = 1; k <= b->seats; k++) {
        s = (b->to_move + k) % b->seats;
        if (active(b, s)) {
            if (s != b->to_move) {
                b->key ^= STH_ZOB_MOVE[b->to_move] ^ STH_ZOB_MOVE[s];
                b->to_move = s;
            }
            return;
        }
    }
}

static void end_game(struct sth_board *b, int how)
{
    b->over = 1;
    b->how = how;
}

/* After a move: the mover first, then every other seat still racing,
 * clockwise from it. A rival can complete this seat's home by moving into the
 * last hole of it, and then it is home on the rival's move. */
static void check_home(struct sth_board *b)
{
    int k, s;
    for (k = 0; k < b->seats; k++) {
        s = (b->to_move + k) % b->seats;
        if (active(b, s) && sth_home_complete(b, s))
            b->finished[b->finished_n++] = s;
    }
}

/* THE RACE IS OVER when nobody is left to race against: one seat still racing
 * among several, or none. A seat crossing alone races until it is home. */
static int race_over(const struct sth_board *b)
{
    int n = active_count(b);
    return n == 0 || (b->seats > 1 && n == 1);
}

static void after(struct sth_board *b, int how_if_over)
{
    if (race_over(b)) { end_game(b, how_if_over); return; }
    if (b->pass_run >= active_count(b)) { end_game(b, STH_BY_DEADLOCK); return; }
    if (b->ply >= b->cap) { end_game(b, STH_BY_CAP); return; }
    next_turn(b);
}

static void remember(const struct sth_board *b, struct sth_undo *u, int kind, int from, int to, int seat)
{
    int i;
    if (!u) return;
    u->kind = kind;
    u->from = from;
    u->to = to;
    u->seat = seat;
    u->to_move = b->to_move;
    u->ply = b->ply;
    u->pass_run = b->pass_run;
    u->finished_n = b->finished_n;
    u->resigned_n = b->resigned_n;
    u->over = b->over;
    u->how = b->how;
    for (i = 0; i < 8; i++) u->reserved[i] = 0;
}

int sth_play(struct sth_board *b, int from, int to, struct sth_undo *undo)
{
    int reach[STH_REACH_MAX], n, i, ok = 0, c;
    if (!b) return STH_WHY_NOT_A_HOLE;
    if (b->over) return STH_WHY_OVER;
    if (!STH_IS_HOLE(from) || !STH_IS_HOLE(to)) return STH_WHY_NOT_A_HOLE;
    c = b->cell[STH_SQ_OF[from]];
    if (!STH_IS_PIECE(c)) return STH_WHY_NO_PIECE;
    if (c != b->to_move) return STH_WHY_NOT_YOURS;
    n = sth_reach(b, from, reach, STH_REACH_MAX);
    for (i = 0; i < n; i++) if (reach[i] == to) ok = 1;
    if (!ok) return STH_WHY_UNREACHABLE;
    remember(b, undo, STH_DID_MOVE, from, to, c);
    sth_do_move(b, from, to);
    b->ply++;
    b->pass_run = 0;
    check_home(b);
    after(b, STH_BY_HOME);
    return STH_PLAY_OK;
}

/* For the search, which plays only moves legal gave it: play without asking
 * the reach again. Nothing outside the engine may call it. */
int sth_play_trusted(struct sth_board *b, int from, int to, struct sth_undo *undo)
{
    int c = b->cell[STH_SQ_OF[from]];
    remember(b, undo, STH_DID_MOVE, from, to, c);
    sth_do_move(b, from, to);
    b->ply++;
    b->pass_run = 0;
    check_home(b);
    after(b, STH_BY_HOME);
    return STH_PLAY_OK;
}

int sth_can_pass(const struct sth_board *b)
{
    int from[1], to[1];
    return b && !b->over && sth_legal(b, from, to, 0) == 0;
}

int sth_pass(struct sth_board *b, struct sth_undo *undo)
{
    if (!b) return STH_WHY_NOT_A_HOLE;
    if (b->over) return STH_WHY_OVER;
    if (!sth_can_pass(b)) return STH_WHY_HAS_MOVE;
    remember(b, undo, STH_DID_PASS, -1, -1, b->to_move);
    b->ply++;
    b->pass_run++;
    after(b, STH_BY_HOME);
    return STH_PLAY_OK;
}

/* Any seat still racing may resign, on its turn or not. Its pieces stay where
 * they are: taking them away would change everyone else's ladders mid-game. */
int sth_resign(struct sth_board *b, int seat, struct sth_undo *undo)
{
    if (!b) return STH_WHY_NOT_A_SEAT;
    if (b->over) return STH_WHY_OVER;
    if (!seat_ok(b, seat)) return STH_WHY_NOT_A_SEAT;
    if (!active(b, seat)) return STH_WHY_SEAT_DONE;
    remember(b, undo, STH_DID_RESIGN, -1, -1, seat);
    b->resigned[b->resigned_n++] = seat;
    b->pass_run = 0;
    if (race_over(b)) { end_game(b, STH_BY_RESIGN); return STH_PLAY_OK; }
    if (seat == b->to_move) next_turn(b);
    return STH_PLAY_OK;
}

int sth_unplay(struct sth_board *b, const struct sth_undo *u)
{
    if (!b || !u) return 0;
    if (u->kind == STH_DID_MOVE && !sth_undo_move(b, u->from, u->to)) return 0;
    if (u->kind != STH_DID_MOVE && u->kind != STH_DID_PASS && u->kind != STH_DID_RESIGN) return 0;
    if (u->to_move != b->to_move) {
        b->key ^= STH_ZOB_MOVE[b->to_move] ^ STH_ZOB_MOVE[u->to_move];
        b->to_move = u->to_move;
    }
    b->ply = u->ply;
    b->pass_run = u->pass_run;
    b->finished_n = u->finished_n;
    b->resigned_n = u->resigned_n;
    b->over = u->over;
    b->how = u->how;
    return 1;
}

int  sth_game_over(const struct sth_board *b) { return b ? b->over : 0; }
int  sth_game_how(const struct sth_board *b)  { return b ? b->how : STH_ONGOING; }
int  sth_ply(const struct sth_board *b)   { return b ? b->ply : 0; }
int  sth_cap(const struct sth_board *b)   { return b ? b->cap : 0; }

void sth_set_cap(struct sth_board *b, int cap)
{
    if (b && cap > 0) b->cap = cap;
}

/* ---- the game in the position string (version 5) ---------------------------
 *
 * After the seat count and the piece count, a ';' and then, each only when it
 * is not the default and always in this order, space between them:
 *
 *   f=2,0     the seats home, in the order they got there
 *   r=1       the seats that resigned, in order
 *   p=37      the ply
 *   k=1       passes in a row, just now
 *   c=500     the cap, when it is not 1,000 a seat
 *   o=1       how the game ended, when it has
 *
 * A board fresh from its set-up writes no ';' at all, so every string version
 * 1 wrote still reads the same.
 */

static int put_dec(char *out, int n, int v)
{
    char digits[12];
    int k = 0;
    do { digits[k++] = (char) ('0' + v % 10); v /= 10; } while (v && k < 11);
    while (k) out[n++] = digits[--k];
    return n;
}

static int put_seats(char *out, int n, const int *list, int count)
{
    int i;
    for (i = 0; i < count; i++) {
        if (i) out[n++] = ',';
        out[n++] = (char) ('0' + list[i]);
    }
    return n;
}

int sth_game_suffix_write(const struct sth_board *b, char *out, int n)
{
    int any = 0;
    if (!b->ply && !b->finished_n && !b->resigned_n && !b->pass_run
        && b->cap == STH_PLY_CAP_PER_SEAT * b->seats && !b->over)
        return n;
    out[n++] = ';';
#define STH_SEP() do { if (any++) out[n++] = ' '; } while (0)
    if (b->finished_n) { STH_SEP(); out[n++] = 'f'; out[n++] = '='; n = put_seats(out, n, b->finished, b->finished_n); }
    if (b->resigned_n) { STH_SEP(); out[n++] = 'r'; out[n++] = '='; n = put_seats(out, n, b->resigned, b->resigned_n); }
    if (b->ply)        { STH_SEP(); out[n++] = 'p'; out[n++] = '='; n = put_dec(out, n, b->ply); }
    if (b->pass_run)   { STH_SEP(); out[n++] = 'k'; out[n++] = '='; n = put_dec(out, n, b->pass_run); }
    if (b->cap != STH_PLY_CAP_PER_SEAT * b->seats) { STH_SEP(); out[n++] = 'c'; out[n++] = '='; n = put_dec(out, n, b->cap); }
    if (b->over)       { STH_SEP(); out[n++] = 'o'; out[n++] = '='; out[n++] = (char) ('0' + b->how); }
#undef STH_SEP
    return n;
}

/* A decimal of one to nine digits, no leading zero unless it is 0. */
static int read_dec(const char **s)
{
    const char *p = *s;
    int v = 0, k = 0;
    if (*p < '0' || *p > '9') return -1;
    if (*p == '0' && p[1] >= '0' && p[1] <= '9') return -1;
    while (*p >= '0' && *p <= '9' && k < 9) { v = v * 10 + (*p++ - '0'); k++; }
    if (*p >= '0' && *p <= '9') return -1;
    *s = p;
    return v;
}

static int read_seats(const char **s, int seats, int *list, int *count, const int *other, int other_n)
{
    const char *p = *s;
    int seat;
    *count = 0;
    for (;;) {
        if (*p < '0' || *p > '9') return 0;
        seat = *p++ - '0';
        if (seat >= seats || in_list(list, *count, seat) || in_list(other, other_n, seat)) return 0;
        list[(*count)++] = seat;
        if (*p != ',') break;
        p++;
    }
    *s = p;
    return 1;
}

/* Reads the part after the ';' into a board whose pieces and seats are set,
 * and refuses with STH_POS_GAME a suffix that is malformed, out of order, or
 * that does not agree with itself: a game whose own state says it is over
 * must say how, and a stated end must be true of the state. */
int sth_game_suffix_read(struct sth_board *b, const char *s)
{
    static const char keys[] = "frpkco";
    int at = 0, v, any = 0, how = STH_ONGOING;
    while (*s) {
        const char *k;
        if (any++) { if (*s != ' ') return STH_POS_GAME; s++; }
        k = strchr(keys + at, *s);
        if (!*s || !k || s[1] != '=') return STH_POS_GAME;
        at = (int) (k - keys) + 1;
        s += 2;
        switch (*k) {
        case 'f':
            if (!read_seats(&s, b->seats, b->finished, &b->finished_n, b->resigned, b->resigned_n)) return STH_POS_GAME;
            break;
        case 'r':
            if (!read_seats(&s, b->seats, b->resigned, &b->resigned_n, b->finished, b->finished_n)) return STH_POS_GAME;
            break;
        case 'p': if ((v = read_dec(&s)) <= 0) return STH_POS_GAME; b->ply = v; break;
        case 'k': if ((v = read_dec(&s)) <= 0) return STH_POS_GAME; b->pass_run = v; break;
        case 'c': if ((v = read_dec(&s)) <= 0) return STH_POS_GAME; b->cap = v; break;
        case 'o':
            if (*s < '1' || *s > '4') return STH_POS_GAME;
            how = *s++ - '0';
            break;
        }
    }
    if (!any) return STH_POS_GAME;
    switch (how) {
    case STH_ONGOING:
        if (race_over(b) || b->pass_run >= active_count(b) || b->ply >= b->cap) return STH_POS_GAME;
        if (!active(b, b->to_move)) return STH_POS_GAME;
        break;
    case STH_BY_HOME:
    case STH_BY_RESIGN:
        if (!race_over(b)) return STH_POS_GAME;
        break;
    case STH_BY_CAP:
        if (race_over(b) || b->ply < b->cap) return STH_POS_GAME;
        break;
    case STH_BY_DEADLOCK:
        if (race_over(b) || b->pass_run < active_count(b)) return STH_POS_GAME;
        break;
    }
    b->over = how != STH_ONGOING;
    b->how = how;
    return STH_OK;
}
