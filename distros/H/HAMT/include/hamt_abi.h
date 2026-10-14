#ifndef HAMT_ABI_H
#define HAMT_ABI_H

/* Public C ABI for HAMT: everything HAMT::Map, HAMT::Set and HAMT::Vector do
 * from Perl, callable from another extension's C with no Perl call in
 * between.
 *
 * It is resolved at RUNTIME through HAMT::_abi_ptr - a versioned table of
 * function pointers - so there is no link-time coupling: each dist builds
 * and upgrades by itself. A consumer reaches this header through
 * ExtUtils::Depends, or vendors a copy pinned at HAMT_ABI_VERSION, and
 * checks abi_version once when it loads.
 *
 * The table only ever grows at the end. HAMT_ABI_VERSION bumps on any
 * append, and a consumer requires abi_version >= the version it was written
 * against, treating a later table as a superset it uses a prefix of. NOT ==:
 * an equality check turns every release of this dist into a breaking change
 * for every consumer.
 *
 * ---- THIS HEADER NEEDS PERL -------------------------------------------
 *
 * Every entry takes pTHX_ and most take or return an SV, an HV or an AV:
 * the containers hold Perl scalars, and letting go of one has to reach the
 * interpreter. Include perl's headers first.
 *
 * ---- resolving the table ----------------------------------------------
 *
 * At BOOT, once, never per call:
 *
 *     static const hamt_abi *HAMT = NULL;
 *
 *     BOOT:
 *     {
 *         SV *err;
 *         SV *sv = eval_pv("require HAMT; HAMT::_abi_ptr()", 0);
 *         err = get_sv("@", 0);
 *         if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *             const hamt_abi *t = INT2PTR(const hamt_abi *, SvUV(sv));
 *             if (t && t->abi_version >= HAMT_ABI_VERSION) HAMT = t;
 *         }
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack: eval_pv has already
 * popped what it evaluated. And if the BOOT captured SP with dSP before the
 * call and uses it afterwards, SPAGAIN first.
 *
 * A NULL table means HAMT is absent or too old, and the consumer falls back
 * to whatever it did before. It does not croak.
 *
 * Calls are written (HAMT->map_fetch)(aTHX_ m, key, len, 0). The
 * parentheses cost nothing and keep a member's name from ever being read as
 * a function-like macro, which is how XSUB.h redefines a number of ordinary
 * names on a perl built with PERL_IMPLICIT_SYS.
 *
 * ---- WHAT A CONTAINER IS HERE -----------------------------------------
 *
 * A `hamt_map *` or a `hamt_vec *` from this table is a small struct that
 * the CALLER OWNS, onto a tree of shared nodes. It is made by a `_new`, a
 * `_copy` or an operation that returns one, and given up exactly once, to
 * `_release` or to a `_to_sv`.
 *
 * The updating entries - map_store, map_remove, set_add, vec_push, vec_store,
 * vec_pop - CHANGE THE STRUCT THEY ARE GIVEN. That is safe, and it is how
 * persistence works here: a `_copy` is a second struct onto the same nodes
 * and costs one small allocation, and the first update through either
 * struct copies the few nodes it touches and leaves the other struct
 * exactly as it was. So:
 *
 *     to change a container and keep the old one    copy it, change the copy
 *     to build one up in many steps                  change the one struct
 *
 * The second is what a Perl transient is, and the first is what every Perl
 * method that "returns a new map" does.
 *
 * A struct belongs to one interpreter. Nothing here is safe to call from
 * two threads on the same nodes.
 *
 * ---- containers that belong to Perl objects ---------------------------
 *
 * `map_from_sv`, `set_from_sv` and `vec_from_sv` hand back the struct INSIDE
 * a Perl object, borrowed and const. It is valid while the object is alive.
 * It must not be passed to an updating entry: the object promises its
 * holders that it never changes. To update, `_copy` it and change the copy.
 *
 * The `_txn_from_sv` entries hand back the struct inside an open transient
 * object, borrowed and NOT const: changing it in place is what a transient
 * is for, and the Perl code holding the transient sees the change.
 *
 * `_to_sv` and `_to_txn_sv` make a new Perl object and TAKE OVER the struct:
 * the caller does not release it and must not use it again.
 *
 * ---- keys -------------------------------------------------------------
 *
 * A key is bytes, a length and a flag saying whether the bytes are UTF-8,
 * exactly as SvPV, the length and SvUTF8 give them. The table applies the
 * rule a Perl hash applies: a key that is flagged but holds only characters
 * below 256 is the same key as its unflagged spelling. A consumer does not
 * have to normalise anything.
 *
 * A callback is handed a key the same way. Its bytes are valid for the
 * length of that call.
 *
 * ---- values -----------------------------------------------------------
 *
 * A value is COPIED when it is stored, and the copy is read-only. The
 * caller's scalar is not kept, not changed, and may be a temporary.
 *
 * A value that comes back - from a fetch, or handed to a callback - is the
 * stored scalar itself, BORROWED: it is valid while the caller holds a
 * container that holds it, and it must not be written to. To keep it
 * longer, SvREFCNT_inc it; to change it, copy it.
 *
 * A set's entries have no value. Where a map entry or callback would have
 * an SV, a set has NULL.
 *
 * ---- results and failure ----------------------------------------------
 *
 * An entry that returns int returns HAMT_ABI_OK or one of the negative
 * codes below, unless its comment says it returns a truth value or a count.
 * An entry that returns a pointer returns NULL when there is no memory;
 * those that can fail another way take an `int *status`, which may be NULL.
 *
 * NO ENTRY CROAKS for want of memory, and a failed entry leaves every
 * container holding exactly what it held.
 *
 * A callback may stop the walk it is called from, by its return value. A
 * callback handed to map_walk, set_walk, vec_walk, map_equal, vec_equal or
 * map_diff may also croak: nothing is built across those calls. A callback
 * handed to map_merge or map_update MUST NOT croak or longjmp: those are
 * building nodes when they call, and what they had built would be leaked.
 * Return the stop value instead. */

#define HAMT_ABI_VERSION 1

#define HAMT_ABI_OK        0
#define HAMT_ABI_NOMEM   (-1)   /* no memory; nothing was changed */
#define HAMT_ABI_RANGE   (-2)   /* an index or a length outside the vector */
#define HAMT_ABI_STOPPED (-3)   /* a callback asked for it to stop */

/* What map_diff reports. */
#define HAMT_ABI_ADD    1       /* in the second map only: `was` is NULL */
#define HAMT_ABI_REMOVE 2       /* in the first map only: `now` is NULL  */
#define HAMT_ABI_CHANGE 3       /* in both, with values that are not equal */

#ifndef HAMT_MAP_FWD
#define HAMT_MAP_FWD
typedef struct hamt_map hamt_map;       /* a map, or a set */
#endif
#ifndef HAMT_VEC_FWD
#define HAMT_VEC_FWD
typedef struct hamt_vec hamt_vec;
#endif

/* ---- callbacks ---------------------------------------------------------- */

/* One entry of a map or a set. `value` is NULL for a set. Return 0 to carry
 * on, anything else to stop. */
typedef int (*hamt_abi_pair_fn)(pTHX_ void *ud, const char *key, STRLEN klen,
                                int utf8, SV *value);

/* One element of a vector. Return 0 to carry on, anything else to stop. */
typedef int (*hamt_abi_item_fn)(pTHX_ void *ud, size_t index, SV *value);

/* Are two values equal? 1 yes, 0 no, negative to stop the comparison. */
typedef int (*hamt_abi_equal_fn)(pTHX_ void *ud, SV *a, SV *b);

/* A key is in both maps being merged, with different values. Return the
 * value the result should hold: `mine`, `theirs`, or any other scalar, which
 * is copied. Return NULL to stop the merge. MUST NOT croak. */
typedef SV *(*hamt_abi_merge_fn)(pTHX_ void *ud, const char *key, STRLEN klen,
                                 int utf8, SV *mine, SV *theirs);

/* The current value under a key, or NULL when the key is not there. Return
 * the value to store, which is copied, or NULL to store nothing and stop.
 * MUST NOT croak. */
typedef SV *(*hamt_abi_update_fn)(pTHX_ void *ud, SV *current);

/* One difference between two maps. `kind` is HAMT_ABI_ADD, _REMOVE or
 * _CHANGE. Return 0 to carry on, anything else to stop. */
typedef int (*hamt_abi_diff_fn)(pTHX_ void *ud, int kind, const char *key,
                                STRLEN klen, int utf8, SV *was, SV *now);

typedef struct hamt_abi {
    int abi_version;

    /* ================================================================ *
     *  values
     * ================================================================ */

    /* Equal as `equals` means it when no comparison is given: the same
     * scalar; or two references to the same thing; or two non-references
     * that are the same string; or two undefs. 1 or 0. */
    int (*value_equal)(pTHX_ SV *a, SV *b);

    /* ================================================================ *
     *  maps
     * ================================================================ */

    /* An empty map. NULL for no memory. */
    hamt_map *(*map_new)(pTHX);
    /* A second struct onto the same map. One small allocation. */
    hamt_map *(*map_copy)(pTHX_ const hamt_map *m);
    /* Gives up a struct. The pointer is dead afterwards. */
    void      (*map_release)(pTHX_ hamt_map *m);

    /* The map inside a HAMT::Map object or a subclass of one: borrowed,
     * const, valid while the object lives. NULL if it is not one. */
    const hamt_map *(*map_from_sv)(pTHX_ SV *obj);
    /* The map inside an OPEN HAMT::Map::Transient object: borrowed, and the
     * caller may update it in place. NULL if it is not one, or is closed. */
    hamt_map *(*map_txn_from_sv)(pTHX_ SV *obj);
    /* A new HAMT::Map object, of class `klass` or of HAMT::Map when that is
     * NULL, with a reference count of one. TAKES OVER the struct. */
    SV       *(*map_to_sv)(pTHX_ hamt_map *m, const char *klass);
    /* A new, open HAMT::Map::Transient object, whose `persistent` will make
     * a `klass`. TAKES OVER the struct. */
    SV       *(*map_to_txn_sv)(pTHX_ hamt_map *m, const char *klass);

    /* A map of every pair in a Perl hash, values copied. NULL for no
     * memory. The hash is only read. */
    hamt_map *(*map_from_hv)(pTHX_ HV *hv);
    /* A new, ordinary, writable Perl hash holding a copy of every pair,
     * with a reference count of one. NULL for no memory. */
    HV       *(*map_to_hv)(pTHX_ const hamt_map *m);

    /* How many keys. */
    size_t    (*map_count)(pTHX_ const hamt_map *m);
    /* The value under a key, borrowed, or NULL when the key is not there.
     * A key holding undef returns the stored undef scalar, not NULL. */
    SV       *(*map_fetch)(pTHX_ const hamt_map *m, const char *key, STRLEN klen, int utf8);
    /* 1 when the key is there, whatever it holds; 0 when not. */
    int       (*map_has)(pTHX_ const hamt_map *m, const char *key, STRLEN klen, int utf8);

    /* Stores a copy of `value` under the key, in the struct given. */
    int       (*map_store)(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8, SV *value);
    /* Takes a key out of the struct given. Removing a key that is not there
     * is HAMT_ABI_OK. */
    int       (*map_remove)(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8);
    /* Replaces one key's value by what `fn` makes of it, in the struct
     * given. A result equal to the current value, as value_equal has it,
     * changes nothing. HAMT_ABI_STOPPED when `fn` returns NULL. */
    int       (*map_update)(pTHX_ hamt_map *m, const char *key, STRLEN klen, int utf8,
                            hamt_abi_update_fn fn, void *ud);

    /* Calls `fn` for every pair, in an order that is stable for one map in
     * one process. HAMT_ABI_OK, or HAMT_ABI_STOPPED. This is `keys`,
     * `values`, `pairs` and `each`. */
    int       (*map_walk)(pTHX_ const hamt_map *m, hamt_abi_pair_fn fn, void *ud);

    /* A new map holding every key of both. For a key in both, `b`'s value,
     * or what `fn` returns when `fn` is not NULL; `fn` is asked only about
     * keys in both whose two values are not the same stored scalar. Costs
     * what differs between the two, not what they hold. NULL on failure,
     * with *status saying why. */
    hamt_map *(*map_merge)(pTHX_ const hamt_map *a, const hamt_map *b,
                           hamt_abi_merge_fn fn, void *ud, int *status);
    /* 1 when the two hold the same keys with equal values, 0 when not,
     * HAMT_ABI_STOPPED when `fn` stopped it. `fn` may be NULL for the rule
     * value_equal applies. */
    int       (*map_equal)(pTHX_ const hamt_map *a, const hamt_map *b,
                           hamt_abi_equal_fn fn, void *ud);
    /* Calls `fn` for every key in one map and not the other, or in both
     * with values that value_equal does not call equal. `*count`, when not
     * NULL, gets how many that was. HAMT_ABI_OK or HAMT_ABI_STOPPED. */
    int       (*map_diff)(pTHX_ const hamt_map *a, const hamt_map *b,
                          hamt_abi_diff_fn fn, void *ud, size_t *count);

    /* A new set of the map's keys. NULL for no memory. */
    hamt_map *(*map_key_set)(pTHX_ const hamt_map *m);

    /* For tests: 0 when the trie is one this library could have built,
     * otherwise the number of the rule it breaks. Visits everything. */
    int       (*map_check)(pTHX_ const hamt_map *m);

    /* ================================================================ *
     *  sets
     *
     *  A set is a hamt_map whose entries have no value. These are the
     *  entries with a set's names; the first eight do exactly what the
     *  map's do.
     * ================================================================ */

    hamt_map *(*set_new)(pTHX);
    hamt_map *(*set_copy)(pTHX_ const hamt_map *s);
    void      (*set_release)(pTHX_ hamt_map *s);
    size_t    (*set_count)(pTHX_ const hamt_map *s);
    /* 1 when it is a member, 0 when not. */
    int       (*set_has)(pTHX_ const hamt_map *s, const char *key, STRLEN klen, int utf8);
    /* Takes a member out of the struct given. */
    int       (*set_remove)(pTHX_ hamt_map *s, const char *key, STRLEN klen, int utf8);
    /* Calls `fn` for every member, with a NULL value. */
    int       (*set_walk)(pTHX_ const hamt_map *s, hamt_abi_pair_fn fn, void *ud);
    /* For tests, as map_check. */
    int       (*set_check)(pTHX_ const hamt_map *s);

    /* The set inside a HAMT::Set object: borrowed, const. NULL if not one. */
    const hamt_map *(*set_from_sv)(pTHX_ SV *obj);
    /* The set inside an open HAMT::Set::Transient object: borrowed,
     * updatable. NULL if it is not one, or is closed. */
    hamt_map *(*set_txn_from_sv)(pTHX_ SV *obj);
    /* A new HAMT::Set object, or a `klass`. TAKES OVER the struct. */
    SV       *(*set_to_sv)(pTHX_ hamt_map *s, const char *klass);
    /* A new, open HAMT::Set::Transient object. TAKES OVER the struct. */
    SV       *(*set_to_txn_sv)(pTHX_ hamt_map *s, const char *klass);

    /* Adds a member to the struct given. */
    int       (*set_add)(pTHX_ hamt_map *s, const char *key, STRLEN klen, int utf8);

    /* New sets: everything in either, everything in both, everything in
     * `a` that is not in `b`. NULL for no memory. Each costs what differs
     * between the two. An empty result is an empty set, not NULL. */
    hamt_map *(*set_union)(pTHX_ const hamt_map *a, const hamt_map *b);
    hamt_map *(*set_intersect)(pTHX_ const hamt_map *a, const hamt_map *b);
    hamt_map *(*set_difference)(pTHX_ const hamt_map *a, const hamt_map *b);

    /* 1 or 0: every member of `a` is in `b`; the two share no member; the
     * two have the same members. */
    int       (*set_is_subset)(pTHX_ const hamt_map *a, const hamt_map *b);
    int       (*set_is_disjoint)(pTHX_ const hamt_map *a, const hamt_map *b);
    int       (*set_equal)(pTHX_ const hamt_map *a, const hamt_map *b);

    /* ================================================================ *
     *  vectors
     * ================================================================ */

    hamt_vec *(*vec_new)(pTHX);
    hamt_vec *(*vec_copy)(pTHX_ const hamt_vec *v);
    void      (*vec_release)(pTHX_ hamt_vec *v);

    /* The vector inside a HAMT::Vector object: borrowed, const. */
    const hamt_vec *(*vec_from_sv)(pTHX_ SV *obj);
    /* The vector inside an open HAMT::Vector::Transient object: borrowed,
     * updatable. */
    hamt_vec *(*vec_txn_from_sv)(pTHX_ SV *obj);
    /* A new HAMT::Vector object, or a `klass`. TAKES OVER the struct. */
    SV       *(*vec_to_sv)(pTHX_ hamt_vec *v, const char *klass);
    /* A new, open HAMT::Vector::Transient object. TAKES OVER the struct. */
    SV       *(*vec_to_txn_sv)(pTHX_ hamt_vec *v, const char *klass);

    /* A vector of every element of a Perl array, values copied; an element
     * that does not exist is undef. NULL for no memory. */
    hamt_vec *(*vec_from_av)(pTHX_ AV *av);
    /* A new, ordinary, writable Perl array holding a copy of every value,
     * with a reference count of one. NULL for no memory. */
    AV       *(*vec_to_av)(pTHX_ const hamt_vec *v);

    size_t    (*vec_count)(pTHX_ const hamt_vec *v);
    /* The value at an index, borrowed, or NULL when the index is not below
     * the count. `first` is index 0 and `last` is count - 1. */
    SV       *(*vec_fetch)(pTHX_ const hamt_vec *v, size_t index);

    /* Appends a copy of `value` to the struct given. */
    int       (*vec_push)(pTHX_ hamt_vec *v, SV *value);
    /* Replaces the value at an index, in the struct given. HAMT_ABI_RANGE
     * when the index is not below the count. */
    int       (*vec_store)(pTHX_ hamt_vec *v, size_t index, SV *value);
    /* Removes the last value from the struct given. Popping an empty vector
     * is HAMT_ABI_OK. */
    int       (*vec_pop)(pTHX_ hamt_vec *v);

    /* Calls `fn` for every element in order. This is `list` and `each`. */
    int       (*vec_walk)(pTHX_ const hamt_vec *v, hamt_abi_item_fn fn, void *ud);

    /* A new vector: everything in `a` followed by everything in `b`. Copies
     * the nodes along the join and shares the rest. */
    hamt_vec *(*vec_concat)(pTHX_ const hamt_vec *a, const hamt_vec *b);
    /* A new vector of the `len` values from `from`. HAMT_ABI_RANGE in
     * *status, and NULL, when that does not lie within the vector. A length
     * of zero is an empty vector. */
    hamt_vec *(*vec_slice)(pTHX_ const hamt_vec *v, size_t from, size_t len, int *status);
    /* A new vector: `v` with everything in `mid` put in before index `at`,
     * which may be anything up to the count. */
    hamt_vec *(*vec_insert)(pTHX_ const hamt_vec *v, size_t at, const hamt_vec *mid, int *status);
    /* A new vector: `v` without the `len` values from `at`. */
    hamt_vec *(*vec_remove)(pTHX_ const hamt_vec *v, size_t at, size_t len, int *status);

    /* 1 when the two hold equal values in the same order, 0 when not,
     * HAMT_ABI_STOPPED when `fn` stopped it. `fn` may be NULL. */
    int       (*vec_equal)(pTHX_ const hamt_vec *a, const hamt_vec *b,
                           hamt_abi_equal_fn fn, void *ud);

    /* For tests, as map_check. */
    int       (*vec_check)(pTHX_ const hamt_vec *v);
} hamt_abi;

#endif
