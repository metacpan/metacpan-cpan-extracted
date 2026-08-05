#ifndef JSF_ABI_H
#define JSF_ABI_H

/* Shared C ABI between JSON::Schema::Fast (the provider) and consumers such as
 * OpenAPI::Fast. It is resolved at RUNTIME via JSON::Schema::Fast::_abi_ptr - a
 * DBI-style versioned function-pointer table - so there is no link-time symbol
 * coupling and each dist builds and upgrades independently. A consumer vendors
 * a copy of this header at a pinned JSF_ABI_VERSION and checks abi_version at
 * boot; a mismatch means "fall back", never a crash.
 *
 * The point: an OpenAPI layer compiles each parameter/body schema once and then
 * validates per request entirely in C - no per-request Perl method dispatch.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, AV and pTHX are defined. */

#define JSF_ABI_VERSION 1

typedef struct jsf_abi {
    int abi_version;                 /* == JSF_ABI_VERSION */

    /* Compile a schema into a reusable validator. `schema` is a Perl hashref /
     * arrayref / boolean, or a JSON-text scalar (decoded here). `resolver` is
     * an optional coderef for remote $ref (NULL or undef => auto-fetch via
     * Fetch's ABI). `coerce` enables string<->number/boolean coercion and
     * `apply_defaults` fills missing properties from `default`. Returns a
     * blessed JSON::Schema::Fast::Compiled SV (+1 owned by the caller); croaks
     * on a bad schema. Keep the handle and reuse it across many validations. */
    SV *(*compile)(pTHX_ SV *schema, SV *resolver, int coerce, int apply_defaults);

    /* Fast boolean validation: 1 = valid, 0 = invalid. `compiled` is a handle
     * from compile(); `data` is the Perl value to check. No error collection,
     * so this is the cheapest path (a hot request validator). */
    int (*is_valid)(pTHX_ SV *compiled, SV *data);

    /* Validate and collect errors: returns 1 valid / 0 invalid, and when
     * invalid pushes error hashrefs onto `errors` (a borrowed AV the caller
     * owns and mortalises). Pass NULL for errors to skip collection (then this
     * is exactly is_valid). */
    int (*validate)(pTHX_ SV *compiled, SV *data, AV *errors);
} jsf_abi;

#endif /* JSF_ABI_H */
