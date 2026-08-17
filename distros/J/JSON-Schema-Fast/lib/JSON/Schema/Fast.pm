package JSON::Schema::Fast;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.09';

require XSLoader;
XSLoader::load('JSON::Schema::Fast', $VERSION);

use JSON::Schema::Fast::Compiled;
use Fetch;
use File::Raw::JSON;   # JSON-text schema input is decoded in XS via this

1;

__END__

=head1 NAME

JSON::Schema::Fast - a fast JSON Schema (draft 2020-12) validator

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    use JSON::Schema::Fast;

    # compile a schema once (a hashref, a boolean, or JSON text)
    my $v = JSON::Schema::Fast->compile({
        type       => 'object',
        required   => ['name'],
        properties => {
            name => { type => 'string', minLength => 1 },
            age  => { type => 'integer', minimum => 0 },
        },
    });

    # then validate live Perl data as often as you like
    if ($v->is_valid($data)) { ... }                 # fast boolean

    my ($ok, $errors) = $v->validate($data);         # collect all errors
    for my $e (@$errors) {
        warn "$e->{instanceLocation}: $e->{keyword}\n";
    }

=head1 DESCRIPTION

C<JSON::Schema::Fast> compiles a JSON Schema once into a compact arena
intermediate representation and validates live Perl data through a tight,
threaded C interpreter. A compiled schema walks a packed IR with bitmask type
checks and pre-hashed property lookups, and allocates nothing on the valid path.

=head1 CONSTRUCTOR

=head2 compile

    my $v = JSON::Schema::Fast->compile($schema, %options);

Compiles C<$schema> into a L<JSON::Schema::Fast::Compiled> object. C<$schema> may
be:

=over 4

=item * a Perl hashref (the usual form),

=item * a boolean schema - the JSON booleans C<true>/C<false>, C<1>/C<0>, or an
empty hashref C<{}> (equivalent to C<true>), or

=item * a string of JSON text, which is decoded with L<File::Raw::JSON>.

=back

A schema with an unresolvable C<$ref>, or that is malformed, throws an error.

=over 4

=item C<resolver> => sub { my $uri = shift; ... }

A coderef that returns the schema document (a hashref, or C<undef>) for a URI.
Called on demand to resolve remote or cross-document C<$ref>/C<$dynamicRef> and
to load a custom C<$schema> metaschema; the returned document is parsed into the
same compiled object, and any references it introduces are resolved the same
way.

B<Default:> when you do not pass C<resolver>, remote C<http>/C<https> documents
are fetched through L<Fetch>'s C ABI (in XS - no per-request Perl) and decoded as
JSON. Fetch and its ABI are resolved lazily, only the first time a remote
reference is actually followed, so purely local schemas never touch the network.
Because a schema is sometimes untrusted, note that this can issue outbound
requests to URLs the schema names; pass C<< resolver => undef >> to disable
remote resolution entirely (same-document references only), or supply your own
coderef to add a host allowlist, timeouts, or a different client.

=item C<coerce> => 0 | 1 (default 0)

When a C<type> check would fail because the value is a string, accept it if it
can stand in for a permitted type: a numeric string satisfies C<number> (and
C<integer> when integral), and C<"true">/C<"false"> satisfy C<boolean>. The
numeric keywords (C<minimum>, C<multipleOf>, ...) then apply to the numeric
value. Coercion never changes the caller's value. This is what lets OpenAPI
string parameters validate against a typed schema.

=item C<apply_defaults> => 0 | 1 (default 0)

Before validating an object, fill any missing property that declares a
C<default> into the callers data.

=back

=head1 ERRORS

C<validate> and C<errors> return errors as an arrayref of plain hashes, each
with the trimmed draft 2020-12 output fields:

=over 4

=item C<instanceLocation>

An RFC 6901 JSON Pointer into the data (C<"/items/3/age">, or C<""> for the
root). C<~> and C</> in property names are escaped as C<~0> and C<~1>.

=item C<keyword>

The failing keyword (C<type>, C<required>, C<minimum>, ...).

=item C<schemaLocation>

A JSON Pointer into the schema (C<"/properties/age/minimum">).

=item C<message>

A short human-readable string.

=back

All independent failures are collected, in a deterministic depth-first order.
The boolean C<is_valid> short-circuits on the first failure and does none of
this work.

=head1 KEYWORD COVERAGE

The complete draft 2020-12 dialect:

=over 4

=item * B<Core / references>: C<$ref>, C<$id> (base-URI scopes), C<$anchor>,
C<$defs>, C<$dynamicRef>/C<$dynamicAnchor>, and remote / cross-document
references (via C<resolver>). URI resolution follows RFC 3986; fragments may be
percent- and C<~>-escaped.

=item * B<Type>: C<type> (string or array), C<enum>, C<const>.

=item * B<Number>: C<minimum>, C<maximum>, C<exclusiveMinimum>,
C<exclusiveMaximum>, C<multipleOf>.

=item * B<String>: C<minLength>, C<maxLength> (counted in codepoints),
C<pattern> (compiled once, cached), C<format> (annotation).

=item * B<Array>: C<items>, C<prefixItems>, C<minItems>, C<maxItems>,
C<uniqueItems>, C<contains> (with C<minContains>/C<maxContains>),
C<unevaluatedItems>.

=item * B<Object>: C<properties>, C<patternProperties>,
C<additionalProperties>, C<required>, C<minProperties>, C<maxProperties>,
C<propertyNames>, C<dependentRequired>, C<dependentSchemas>,
C<unevaluatedProperties>.

=item * B<Applicators>: C<allOf>, C<anyOf>, C<oneOf>, C<not>,
C<if>/C<then>/C<else>.

=item * B<Vocabulary>: a custom C<$schema> metaschema whose C<$vocabulary>
omits the validation vocabulary turns the validation keywords into annotations.

=back

JSON Schema types follow the JSON value's type, not Perl's DWIM: a numeric
string is a string unless C<coerce> is set.

=head1 CONFORMANCE

Passes 100% of the mandatory JSON-Schema-Test-Suite for draft 2020-12 (the
suite, including the remote documents and the 2020-12 meta-schemas, is vendored
under C<t/> and run by C<t/70-conformance.t>).

=head1 PERFORMANCE

A compiled schema is validated by walking a packed arena with no re-reading of
the schema document and no allocation on the valid path (errors, C<pattern>
compilation and C<uniqueItems> are the only things that allocate, and only when
present).

=head1 C ABI

JSON::Schema::Fast exposes a small C ABI so that B<other XS modules> can compile
a schema once and validate against it entirely in C, with no Perl method
dispatch per call. The motivating consumer is an OpenAPI layer: it compiles each
parameter, header and body schema once at startup, then validates every request
and response through the ABI on the hot path.

This is the same pattern JSON::Schema::Fast itself uses to consume L<Fetch>'s C
ABI for remote references: a versioned table of function pointers, resolved at
runtime, with B<no link-time coupling> between the two distributions. Each
builds and upgrades independently; a consumer vendors the header and checks the
version at boot, so a mismatch means "fall back", never a crash.

This is an integration surface for XS authors, not part of the Perl API. Perl
callers should use L</compile> and the L<JSON::Schema::Fast::Compiled> methods.

=head2 The table

The contract lives in F<include/jsf_abi.h> (shipped in the distribution; a
consumer vendors a copy at a pinned version):

    #define JSF_ABI_VERSION 1

    typedef struct jsf_abi {
        int abi_version;                 /* == JSF_ABI_VERSION */

        SV *(*compile)(pTHX_ SV *schema, SV *resolver,
                       int coerce, int apply_defaults);
        int (*is_valid)(pTHX_ SV *compiled, SV *data);
        int (*validate)(pTHX_ SV *compiled, SV *data, AV *errors);
    } jsf_abi;

=head2 JSON::Schema::Fast::_abi_ptr

    my $iv = JSON::Schema::Fast::_abi_ptr;

Returns the address of the process-wide C<jsf_abi> table as an integer (an
C<IV>). A consumer calls this once at C<BOOT>, C<INT2PTR>s it to a
C<< const jsf_abi * >>, and checks C<< ->abi_version == JSF_ABI_VERSION >>
before using it. It is not intended to be called from Perl for any other
purpose.

=head2 Functions

=over 4

=item C<< SV *compile(pTHX_ SV *schema, SV *resolver, int coerce, int apply_defaults) >>

Compile a schema into a reusable validator. C<schema> is a Perl hashref,
arrayref or boolean, or a JSON-text scalar (decoded here, as L</compile> does).
C<resolver> is an optional coderef for remote C<$ref> - pass C<NULL> or an undef
SV to get the default auto-fetch through Fetch's ABI, exactly like the Perl
constructor. C<coerce> and C<apply_defaults> are the options documented under
L</compile>.

Returns a blessed L<JSON::Schema::Fast::Compiled> SV with a reference count of
one, owned by the caller; it croaks on a malformed or unresolvable schema. Keep
the handle and reuse it across many validations; C<SvREFCNT_dec> it when done
(the underlying compiled state is freed by the object's C<DESTROY>).

=item C<< int is_valid(pTHX_ SV *compiled, SV *data) >>

Fast boolean validation: returns 1 if C<data> is valid against the compiled
schema, 0 otherwise. C<compiled> is a handle from C<compile>. No errors are
collected, so this is the cheapest path and allocates nothing on the valid path.

=item C<< int validate(pTHX_ SV *compiled, SV *data, AV *errors) >>

Validate and collect errors: returns 1 (valid) or 0 (invalid), and when invalid
pushes error hashrefs - the same structure documented under L</ERRORS> - onto
C<errors>, an AV the caller owns (typically a mortal). Pass C<NULL> for
C<errors> to skip collection, in which case this is exactly C<is_valid>.

=back

=head2 Example: an XS consumer

Vendor F<jsf_abi.h>, resolve the table at boot, then compile once and validate
per call:

    #include "jsf_abi.h"   /* vendored from JSON::Schema::Fast */

    static const jsf_abi *JSF = NULL;

    MODULE = My::Fast::Consumer   PACKAGE = My::Fast::Consumer

    BOOT:
    {
        IV p = 0; dSP;
        eval_pv("require JSON::Schema::Fast;", FALSE);
        PUSHMARK(SP); PUTBACK;
        if (call_pv("JSON::Schema::Fast::_abi_ptr", G_SCALAR|G_EVAL) > 0) {
            SPAGAIN; p = POPi; PUTBACK;
        }
        if (p) {
            const jsf_abi *a = INT2PTR(const jsf_abi *, p);
            if (a && a->abi_version == JSF_ABI_VERSION) JSF = a;
        }
        /* JSF == NULL here means the installed JSON::Schema::Fast is too old
         * or absent; fall back to your Perl path. */
    }

    # compile $schema once (e.g. store the returned SV on your object), then:
    #   int ok = JSF->is_valid(aTHX_ compiled_sv, data_sv);
    # or with errors:
    #   AV *errs = (AV *)sv_2mortal((SV *)newAV());
    #   int ok = JSF->validate(aTHX_ compiled_sv, data_sv, errs);
    # and SvREFCNT_dec(compiled_sv) when the validator is no longer needed.

The compiled SV is an ordinary refcounted Perl value: hold a reference for as
long as you validate, and it cleans itself up when the last reference goes away.

=head1 SEE ALSO

L<JSON::Schema::Fast::Compiled> (the compiled-object methods), L<File::Raw::JSON>
(JSON parsing), L<JSON::Schema::Modern>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0 (GPL Compatible).

=cut
