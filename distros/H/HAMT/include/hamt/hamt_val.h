#ifndef HAMT_VAL_H
#define HAMT_VAL_H

/* What the core knows about a value: nothing. It is a void pointer that can
 * be retained, released and compared, through three macros the includer
 * defines BEFORE the core. Every core function that might release one takes
 * an opaque `void *cx` first and hands it to the macro; under XS it is the
 * interpreter, in the C harness it is whatever the harness likes.
 *
 * A NULL value is legal and means "no value" (a set member). The core guards
 * every use, so a macro never sees NULL.
 *
 * HAMT_VAL_RELEASE may run arbitrary code, including code that calls back
 * into this library: releasing an SV can run a DESTROY. So the rule for every
 * caller is the same everywhere - take the pointer out of the structure, free
 * the structure, and only then release the value. */

#if !defined(HAMT_VAL_RETAIN) || !defined(HAMT_VAL_RELEASE) || !defined(HAMT_VAL_EQ)
#  error "define HAMT_VAL_RETAIN(cx, v), HAMT_VAL_RELEASE(cx, v) and HAMT_VAL_EQ(cx, a, b) before including the core"
#endif

/* Something that cannot be recovered from: a reference count about to wrap.
 * The includer may define it to report through its own channel. It must not
 * return. */
#ifndef HAMT_FATAL
#  define HAMT_FATAL(msg) abort()
#endif

#endif
