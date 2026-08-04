package JSON::Schema::Fast;

use 5.008003;
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('JSON::Schema::Fast', $VERSION);

require JSON::Schema::Fast::Compiled;
require File::Raw::JSON;   # JSON-text schema input is decoded in XS via this

1;

__END__

=head1 NAME

JSON::Schema::Fast - a fast JSON Schema (draft 2020-12) validator

=head1 VERSION

Version 0.03

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
threaded C interpreter. A compiled schema walks a
packed IR with bitmask type checks and pre-hashed property lookups, and
allocates nothing on the valid path.

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

A schema that uses a remote or otherwise unresolvable C<$ref>, or that is
malformed, throws an error.

=over 4

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

=head1 KEYWORD COVERAGE (v0.03)

The supported draft 2020-12 subset:

=over 4

=item * B<Core>: C<$ref> (same-document JSON Pointer, including percent- and
C<~>-escaped fragments), C<$defs>, C<$id> (parsed, local only).

=item * B<Type>: C<type> (string or array), C<enum>, C<const>.

=item * B<Number>: C<minimum>, C<maximum>, C<exclusiveMinimum>,
C<exclusiveMaximum>, C<multipleOf>.

=item * B<String>: C<minLength>, C<maxLength> (counted in codepoints),
C<pattern> (compiled once, cached), C<format> (annotation only).

=item * B<Array>: C<items>, C<prefixItems>, C<minItems>, C<maxItems>,
C<uniqueItems>, C<contains> (with C<minContains>/C<maxContains>).

=item * B<Object>: C<properties>, C<patternProperties>,
C<additionalProperties>, C<required>, C<minProperties>, C<maxProperties>,
C<propertyNames>, C<dependentRequired>, C<dependentSchemas>.

=item * B<Applicators>: C<allOf>, C<anyOf>, C<oneOf>, C<not>,
C<if>/C<then>/C<else>.

=back

A keyword outside this set is parsed and ignored, and recorded so a schema that
relies on it can be identified rather than silently mis-validated.

JSON Schema types follow the JSON value's type, not Perl's DWIM: a numeric
string is a string unless C<coerce> is set.

=head1 FUTURE

Deferred to a later release: remote / cross-document C<$ref> and C<$anchor> /
C<$id>-relative resolution; C<unevaluatedProperties> / C<unevaluatedItems>;
C<$dynamicRef> and custom C<$vocabulary>.

=head1 PERFORMANCE

A compiled schema is validated by walking a packed arena with no re-reading of
the schema document and no allocation on the valid path (errors, C<pattern>
compilation and C<uniqueItems> are the only things that allocate, and only when
present).

=head1 SEE ALSO

L<JSON::Schema::Fast::Compiled> (the compiled-object methods), L<File::Raw::JSON>
(JSON parsing), L<JSON::Schema::Modern>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under the Artistic License 2.0 (GPL Compatible).

=cut
