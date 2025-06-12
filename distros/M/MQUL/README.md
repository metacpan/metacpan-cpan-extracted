# NAME

MQUL - General purpose, MongoDB-style query and update language

# SYNOPSIS

        use MQUL qw/doc_matches update_doc/;

        my $doc = {
                title => 'Freaks and Geeks',
                genres => [qw/comedy drama/],
                imdb_score => 9.4,
                seasons => 1,
                starring => ['Linda Cardellini', 'James Franco', 'Jason Segel'],
                likes => { up => 45, down => 11 }
        };

        if (doc_matches($doc, {
                title => qr/geeks/i,
                genres => 'comedy',
                imdb_score => { '$gte' => 5, '$lte' => 9.5 },
                starring => { '$type' => 'array', '$size' => 3 },
                'likes.up' => { '$gt' => 40 }
        })) {
                # will be true in this example
        }

        update_doc($doc, {
                '$set' => { title => 'Greeks and Feaks' },
                '$pop' => { genres => 1 },
                '$inc' => { imdb_score => 0.6 },
                '$unset' => { seasons => 1 },
                '$push' => { starring => 'John Francis Daley' },
        });

        # $doc will now be:
        {
                title => 'Greeks and Feaks',
                genres => ['comedy'],
                imdb_score => 10,
                starring => ['Linda Cardellini', 'James Franco', 'Jason Segel', 'John Francis Daley'],
                likes => { up => 45, down => 11 }
        }

# DESCRIPTION

MQUL (for **M**ongoDB-style **Q**uery & **U**pdate **L**anguage; pronounced
_"umm, cool"_; yeah, I know, that's the dumbest thing ever), is a general
purpose implementation of [MongoDB](https://metacpan.org/pod/MongoDB)'s query and update language. The
implementation is not 100% compatible, but it only slightly deviates from
MongoDB's behavior, actually extending it a bit.

The module exports two subroutines: `doc_matches()` and `update_doc()`.
The first subroutine takes a document, which is really just a hash-ref (of
whatever complexity), and a query hash-ref built in the MQUL query language.
It returns a true value if the document matches the query, and a
false value otherwise. The second subroutine takes a document and an update
hash-ref built in the MQUL update language. The subroutine modifies the document
(in-place) according to the update hash-ref.

You can use this module for whatever purpose you see fit. It was actually
written for [Giddy](https://metacpan.org/pod/Giddy), my Git-database, and was extracted from its
original code. Outside of the database world, I plan to use it in an application
that performs tests (such as process monitoring for example), and uses the
query language to determine whether the results are valid or not (in our
monitoring example, that could be CPU usage above a certain threshold and
stuff like that). It is also used by [MorboDB](https://metacpan.org/pod/MorboDB), an in-memory clone of
MongoDB.

## UPGRADE NOTES

My distributions follow the [semantic versioning scheme](http://semver.org/),
so whenever the major version changes, that means that API changes incompatible
with previous versions have been made. Always read the Changes file before upgrading.

## THE LANGUAGE

The language itself is described in [MQUL::Reference](https://metacpan.org/pod/MQUL%3A%3AReference). This document
only describes the interface of this module.

The reference document also details MQUL's current differences from the
original MongoDB language.

# INTERFACE

## doc\_matches( \\%document, \[ \\%query, \\@defs \] )

Receives a document hash-ref and possibly a query hash-ref, and returns
true if the document matches the query, false otherwise. If no query
is given (or an empty hash-ref is given), true will be returned (every
document will match an empty query - in accordance with MongoDB).

See ["QUERY STRUCTURE" in MQUL::Reference](https://metacpan.org/pod/MQUL%3A%3AReference#QUERY-STRUCTURE) to learn about the structure of
query hash-refs.

Optionally, an even-numbered array reference of dynamically calculated
attribute definitions can be provided. For example:

        [ min_val => { '$min' => ['attr1', 'attr2', 'attr3' ] },
          max_val => { '$max' => ['attr1', 'attr2', 'attr3' ] },
          difference => { '$diff' => ['max_val', 'min_val'] } ]

This defines three dynamic attributes: `min_val`, `max_val` and
`difference`, which is made up of the first two.

See ["DYNAMICALLY CALCULATED ATTRIBUTES" in MQUL::Reference](https://metacpan.org/pod/MQUL%3A%3AReference#DYNAMICALLY-CALCULATED-ATTRIBUTES) for more information
about dynamic attributes.

## update\_doc( \\%document, \\%update )

Receives a document hash-ref and an update hash-ref, and updates the
document in-place according to the update hash-ref. Also returns the document
after the update. If the update hash-ref doesn't have any of the update
modifiers described by the language, then the update hash-ref is considered
as what the document should now be, and so will simply replace the document
hash-ref (once again, in accordance with MongoDB).

See ["UPDATE STRUCTURE" in MQUL::Reference](https://metacpan.org/pod/MQUL%3A%3AReference#UPDATE-STRUCTURE) to learn about the structure of
update hash-refs.

# DIAGNOSTICS

- `MQUL::doc_matches() requires a document hash-ref.`

    This error means that you've either haven't passed the `doc_matches()`
    subroutine any parameters, or given it a non-hash-ref document.

- `MQUL::doc_matches() expects a query hash-ref.`

    This error means that you've passed the `doc_matches()` attribute a
    non-hash-ref query variable. While you don't actually have to pass a
    query variable, if you do, it has to be a hash-ref.

- `MQUL::update_doc() requires a document hash-ref.`

    This error means that you've either haven't passed the `update_doc()`
    subroutine any parameters, or given it a non-hash-ref document.

- `MQUL::update_doc() requires an update hash-ref.`

    This error means that you've passed the `update_doc()` subroutine a
    non-hash-ref update variable.

- `The %s attribute is not an array in the doc.`

    This error means that your update hash-ref tries to modify an array attribute
    (with `$push`, `$pushAll`, `$addToSet`, `$pull`, `$pullAll`,
    `$pop`, `$shift` and `$splice`), but the attribute in the document
    provided to the `update_doc()` subroutine is not an array.

# CONFIGURATION AND ENVIRONMENT

MQUL requires no configuration files or environment variables.

# DEPENDENCIES

MQUL depends on the following modules:

- [Data::Compare](https://metacpan.org/pod/Data%3A%3ACompare)
- [Data::Types](https://metacpan.org/pod/Data%3A%3ATypes)
- [DateTime::Format::W3CDTF](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AW3CDTF)
- [Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil)
- [Try::Tiny](https://metacpan.org/pod/Try%3A%3ATiny)

# INCOMPATIBILITIES

None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
`bug-MQUL@rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MQUL](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MQUL).

# AUTHOR

Ido Perlmuter &lt;ido at ido50 dot net>

# LICENSE AND COPYRIGHT

Copyright (c) 2011-2025, Ido Perlmuter `ido at ido50 dot net`.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
The full License is included in the LICENSE file. You may also
obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
