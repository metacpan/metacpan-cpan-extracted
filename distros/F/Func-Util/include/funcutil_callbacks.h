/*
 * util_callbacks.h - Public API for XS modules to register loop callbacks
 *
 * Include this header in your XS module to register C-level predicates,
 * mappers, or reducers that Func::Util's loop functions can call directly
 * without Perl callback overhead.
 *
 * Example usage in your XS BOOT section:
 *
 *   #include "util_callbacks.h"
 *
 *   static bool my_is_valid(pTHX_ SV *elem) {
 *       // your validation logic
 *       return SvOK(elem) && SvIV(elem) > 0;
 *   }
 *
 *   BOOT:
 *       funcutil_register_predicate_xs(aTHX_ "MyModule::is_valid", my_is_valid);
 *
 * Then in Perl:
 *   use MyModule;  # registers callback in BOOT
 *   use util;
 *   my @valid = util::grep_cb(\@items, 'MyModule::is_valid');
 */

#ifndef FUNCUTIL_CALLBACKS_H
#define FUNCUTIL_CALLBACKS_H

#include "EXTERN.h"
#include "perl.h"

/* ============================================
   Callback function signatures
   ============================================ */

/*
 * Predicate function: for any, all, none, first, grep, count, partition
 * Return true if element passes the test
 */
typedef bool (*UtilPredicateFunc)(pTHX_ SV *elem);

/*
 * Mapper function: for map operations
 * Return transformed value (may be mortal or new SV)
 */
typedef SV* (*UtilMapFunc)(pTHX_ SV *elem);

/*
 * Reducer function: for reduce/fold operations
 * Return new accumulator value
 */
typedef SV* (*UtilReduceFunc)(pTHX_ SV *accum, SV *elem);

/* ============================================
   Registration API
   ============================================ */

/*
 * Register a C predicate function for use in loop operations.
 * Call from your BOOT section. The name can then be used with
 * util::any_cb, util::all_cb, util::none_cb, util::first_cb,
 * util::grep_cb, util::count_cb.
 *
 * Parameters:
 *   name - Callback name (e.g., "MyModule::is_valid")
 *   func - C function to call for each element
 *
 * Note: Built-in predicates use ':' prefix (e.g., ":is_positive")
 */
PERL_CALLCONV void funcutil_register_predicate_xs(pTHX_ const char *name,
                                               UtilPredicateFunc func);

/*
 * Register a C mapper function for map operations.
 */
PERL_CALLCONV void funcutil_register_mapper_xs(pTHX_ const char *name,
                                            UtilMapFunc func);

/*
 * Register a C reducer function for reduce/fold operations.
 */
PERL_CALLCONV void funcutil_register_reducer_xs(pTHX_ const char *name,
                                             UtilReduceFunc func);

/* ============================================
   Available loop functions
   ============================================ */

/*
 * The following loop functions support named callbacks:
 *
 *   any_cb(\@list, $name)        - true if any element matches
 *   all_cb(\@list, $name)        - true if all elements match
 *   none_cb(\@list, $name)       - true if no element matches
 *   first_cb(\@list, $name)      - first matching element
 *   final_cb(\@list, $name)      - last matching element
 *   grep_cb(\@list, $name)       - all matching elements
 *   count_cb(\@list, $name)      - count of matching elements
 *   partition_cb(\@list, $name)  - split into [matches], [non-matches]
 */

/* ============================================
   Performance notes
   ============================================ */

/*
 * Callback overhead comparison:
 *
 *   Built-in C predicate (:is_positive)  ~5-10 cycles per element
 *   Registered C predicate               ~5-10 cycles per element
 *   Perl callback via register_callback  ~100+ cycles per element
 *   Block callback via any { ... }       ~20-30 cycles (MULTICALL)
 *                                        ~100+ cycles (call_sv fallback)
 *
 * For hot loops processing millions of elements, C predicates provide
 * 10-20x speedup over Perl callbacks.
 */

/* ============================================
   Built-in predicates reference
   ============================================ */

/*
 * The following built-in predicates are available:
 *
 * Type checks:
 *   :is_defined   - SvOK(elem)
 *   :is_ref       - SvROK(elem)
 *   :is_array     - arrayref
 *   :is_hash      - hashref
 *   :is_code      - coderef
 *   :is_string    - plain scalar (not ref, not number)
 *   :is_number    - numeric (IV, NV, or looks_like_number)
 *   :is_integer   - integer value (no fractional part)
 *
 * Boolean checks:
 *   :is_true      - SvTRUE(elem)
 *   :is_false     - !SvTRUE(elem)
 *
 * Numeric checks:
 *   :is_positive  - value > 0
 *   :is_negative  - value < 0
 *   :is_zero      - value == 0
 *   :is_even      - value % 2 == 0
 *   :is_odd       - value % 2 != 0
 *
 * Empty checks:
 *   :is_empty     - empty string, empty array/hash, or undef
 *   :is_nonempty  - not empty
 */

#endif /* FUNCUTIL_CALLBACKS_H */
