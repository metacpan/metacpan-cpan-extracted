#ifndef MDS_ABI_H
#define MDS_ABI_H

/* Shared C ABI between Markdown::Simple (the provider) and consumers such as
 * Punk, whose markdown mount renders a directory of documents at boot without
 * a Perl frame between the mount and the parser. It is resolved at RUNTIME via
 * Markdown::Simple::_abi_ptr - a DBI-style function-pointer table - so there is
 * no link-time symbol coupling and each dist builds and upgrades independently.
 * A consumer reaches the header through ExtUtils::Depends, or vendors a copy
 * pinned at MDS_ABI_VERSION, and checks abi_version at boot; a mismatch means
 * "fall back to the Perl-visible methods", never a crash.
 *
 * The table only ever grows at the end; MDS_ABI_VERSION bumps on any append,
 * and a consumer requires abi_version >= the version it was written against,
 * treating a later table as a superset it uses a prefix of.
 *
 * Version history:
 *   1 - flags_from_hv, session_of, session_render, render, strip
 *
 * Nothing here croaks. Errors come back through an SV **err out-parameter, so
 * a consumer can turn a bad document into its own 500 or boot diagnostic
 * rather than an exception it has to catch. Where err is NULL the message is
 * simply discarded.
 *
 * On encoding: every entry deals in raw bytes and none of them sets the UTF-8
 * flag on anything. The parser is byte-oriented and the caller is the one who
 * knows whether its input was characters or octets, so the flag is the
 * caller's to set. For a consumer writing an HTTP response body this is the
 * behaviour you want, since the body must be bytes and Content-Length counts
 * bytes.
 *
 * Perl headers (EXTERN.h / perl.h / XSUB.h) must be included before this file
 * so SV, HV, AV, STRLEN and pTHX are defined. */

#define MDS_ABI_VERSION 1

typedef struct mds_abi {
    int abi_version;                          /* == MDS_ABI_VERSION */

    /* Decode an options hashref into the MDS_FLAG_* bitmask, applying the
     * same defaults markdown_to_html does. A NULL hv yields the GFM preset.
     * Borrows the hash and never croaks. */
    unsigned (*flags_from_hv)(pTHX_ HV *opts);

    /* The opaque session behind a blessed Markdown::Simple object (what
     * Markdown::Simple->new returns). Returns NULL for anything that is not
     * one rather than croaking, so it is safe to probe with on a fall-back
     * path.
     *
     * The session belongs to the object: it stays valid while that SV is
     * alive and the caller does not free it. Hold a reference to the OBJECT
     * and call this per render rather than caching the pointer, so an object
     * that was replaced or cloned cannot leave you with a stale handle. The
     * lookup is a walk of the object's magic chain and is cheap enough to
     * mean that. */
    void *(*session_of)(pTHX_ SV *obj_sv);

    /* Render through a session, reusing its warm arena and scratch buffers.
     * `out` is caller-owned and is APPENDED to, so pass a fresh or emptied SV
     * unless you actually want accumulation.
     *
     * `toc`, when non-NULL, collects one { level, text, id } hashref per
     * heading in document order and turns heading anchors on for this render
     * whatever the session's own flags say. The AV is caller-owned and only
     * pushed to.
     *
     * Returns 0 on success and non-zero on failure, setting *err to a mortal
     * message SV when err is non-NULL. The only failure the parser reports is
     * malformed input under strict_utf8. */
    int (*session_render)(pTHX_ void *session, const char *in, STRLEN len,
                          SV *out, AV *toc, SV **err);

    /* The same with no session: a local arena, allocated and freed around the
     * call. `flags` is a bitmask from flags_from_hv or the MDS_FLAG_* macros
     * directly. Prefer session_render in a loop; this is for one-shot work
     * where keeping a session alive would be the more awkward thing. */
    int (*render)(pTHX_ const char *in, STRLEN len, unsigned flags,
                  SV *out, AV *toc, SV **err);

    /* strip_markdown: the document as plain text, with list markers and table
     * pipes preserved so the result stays scan-readable, and emphasis, code,
     * link and image delimiters removed while their text is kept. Appends to
     * `out`, which is caller-owned.
     *
     * This is here for search indexing and result snippets, where indexing
     * the HTML would mean indexing the tags. */
    int (*strip)(pTHX_ const char *in, STRLEN len, SV *out, SV **err);
} mds_abi;

#endif /* MDS_ABI_H */
