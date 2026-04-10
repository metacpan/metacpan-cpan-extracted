package JSON::YY;

use strict;
use warnings;
use Carp;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('JSON::YY', $VERSION);

our @EXPORT_OK = qw(encode_json decode_json decode_json_ro);

my @DOC_KEYWORDS = qw(jdoc jget jgetp jset jdel jhas jclone jencode
                       jstr jnum jbool jnull jarr jobj jtype jlen jkeys jdecode
                       jiter jnext jkey jpatch jmerge jfrom jvals jeq
                       jpp jraw jread jwrite jpaths jfind
                       jis_obj jis_arr jis_str jis_num jis_int jis_real jis_bool jis_null);

# functional API — fast XS path, always utf8
*encode_json    = \&_xs_encode_json;
*decode_json    = \&_xs_decode_json;
*decode_json_ro = \&_xs_decode_json_ro;

my %SETTERS = (
    utf8            => \&_set_utf8,
    pretty          => \&_set_pretty,
    canonical       => \&_set_canonical,
    allow_nonref    => \&_set_allow_nonref,
    allow_unknown   => \&_set_allow_unknown,
    allow_blessed   => \&_set_allow_blessed,
    convert_blessed => \&_set_convert_blessed,
    max_depth       => \&_set_max_depth,
);

sub import {
    my $class = shift;
    my @exports;
    my @flags;
    my $want_doc = 0;
    for my $arg (@_) {
        if ($arg eq ':doc') {
            $want_doc = 1;
        } elsif ($arg =~ /^-(.+)/) {
            push @flags, $1;
        } else {
            push @exports, $arg;
        }
    }
    my $caller = caller;

    # activate keywords via XS::Parse::Keyword hint keys
    if ($want_doc) {
        $^H{"JSON::YY/$_"} = 1 for @DOC_KEYWORDS;
    }
    if (@flags) {
        my $coder = $class->new;
        for my $f (@flags) {
            my $setter = $SETTERS{$f}
                or Carp::croak("unknown flag: -$f");
            $coder->$setter(1);
        }
        no strict 'refs';
        *{"${caller}::encode_json"} = sub { $coder->encode($_[0]) };
        *{"${caller}::decode_json"} = sub { $coder->decode($_[0]) };
    }
    if (@exports) {
        no strict 'refs';
        for my $e (@exports) {
            Carp::croak("'$e' is not exported by JSON::YY")
                unless grep { $_ eq $e } @EXPORT_OK;
            *{"${caller}::$e"} = \&{$e};
            # also enable keyword for exported functions
            $^H{"JSON::YY/$e"} = 1;
        }
    }
}

# chaining setters
sub utf8            { $_[0]->_set_utf8($_[1] // 1);            $_[0] }
sub pretty          { $_[0]->_set_pretty($_[1] // 1);          $_[0] }
sub canonical       { $_[0]->_set_canonical($_[1] // 1);       $_[0] }
sub allow_nonref    { $_[0]->_set_allow_nonref($_[1] // 1);    $_[0] }
sub allow_unknown   { $_[0]->_set_allow_unknown($_[1] // 1);   $_[0] }
sub allow_blessed   { $_[0]->_set_allow_blessed($_[1] // 1);   $_[0] }
sub convert_blessed { $_[0]->_set_convert_blessed($_[1] // 1); $_[0] }
sub max_depth       { $_[0]->_set_max_depth($_[1] // 512);     $_[0] }

# wrap XS new to accept keyword args
{
    my $orig_new = JSON::YY->can('new');
    no warnings 'redefine';
    *new = sub {
        my ($class, %args) = @_;
        my $self = $orig_new->($class);
        for my $k (keys %args) {
            my $setter = $SETTERS{$k}
                or Carp::croak("unknown option: $k");
            $self->$setter($args{$k});
        }
        $self;
    };
}

# Doc overloading: stringify to JSON, boolean always true, eq/ne deep compare
package JSON::YY::Doc;
use overload
    '""'     => sub { JSON::YY::_doc_stringify($_[0]) },
    'bool'   => sub { 1 },
    'eq'     => sub { JSON::YY::_doc_eq($_[0], $_[1]) },
    'ne'     => sub { !JSON::YY::_doc_eq($_[0], $_[1]) },
    fallback => 1;

package JSON::YY;
1;

__END__

=head1 NAME

JSON::YY - Fast JSON encoder/decoder with document manipulation API, backed by yyjson

=head1 SYNOPSIS

    # functional API (fastest for simple encode/decode)
    use JSON::YY qw(encode_json decode_json);
    my $json = encode_json { foo => 1, bar => [1, 2, 3] };
    my $data = decode_json '{"foo":1}';

    # OO API (configurable)
    my $coder = JSON::YY->new(utf8 => 1, pretty => 1);
    my $json  = $coder->encode($data);
    my $data  = $coder->decode($json);

    # zero-copy readonly decode (fastest for read-only access)
    use JSON::YY qw(decode_json_ro);
    my $data = decode_json_ro $json;  # readonly, zero-copy strings

    # Doc API (manipulate JSON without full Perl materialization)
    use JSON::YY ':doc';
    my $doc = jdoc '{"users":[{"name":"Alice","age":30}]}';
    jset $doc, "/users/0/age", 31;
    my $name = jgetp $doc, "/users/0/name";   # "Alice"
    print jencode $doc, "";                    # serialize

=head1 DESCRIPTION

JSON::YY is a JSON module backed by yyjson 0.12.0, a high-performance
JSON library written in ANSI C. It provides three API layers:

=over 4

=item Functional/Keyword API - C<encode_json>/C<decode_json> compiled as
custom Perl ops via L<XS::Parse::Keyword>, eliminating function call overhead.

=item OO API - JSON::XS-compatible interface with chaining setters.

=item Doc API - Operate directly on yyjson's mutable document tree using
path-based keywords. Avoids full Perl materialization for surgical JSON edits.

=back

=head1 FUNCTIONAL API

    use JSON::YY qw(encode_json decode_json decode_json_ro);

=over 4

=item encode_json $perl_value

Encode a Perl value to a UTF-8 JSON string. Equivalent to
C<< JSON::YY->new->utf8->encode($value) >> but faster (no object overhead).

=item decode_json $json_string

Decode a UTF-8 JSON string to a Perl value.

=item decode_json_ro $json_string

Decode to a deeply readonly structure with zero-copy strings. String SVs
point directly into yyjson's parsed buffer. Faster than C<decode_json>
for medium/large documents. Modification attempts croak.

=back

When imported via C<qw()>, these compile to custom ops via
L<XS::Parse::Keyword>, bypassing normal function dispatch. Keywords
are lexically scoped. The C<-flag> import style installs pre-configured
closures instead (not compiled as keywords).

=head1 OO API

    my $coder = JSON::YY->new(utf8 => 1, pretty => 1);
    my $coder = JSON::YY->new->utf8->pretty;  # chaining style

=over 4

=item new(%options)

Create a new encoder/decoder. Options: C<utf8>, C<pretty>, C<allow_nonref>,
C<allow_unknown>, C<allow_blessed>, C<convert_blessed>, C<max_depth>.

=item encode($perl_value)

Encode to JSON string.

=item decode($json_string)

Decode from JSON string.

=item decode_doc($json_string)

Decode to a C<JSON::YY::Doc> handle (mutable document, no Perl
materialization). Can then use Doc API keywords on the result.

=item utf8, pretty, allow_nonref, allow_unknown, allow_blessed, convert_blessed

Boolean setters, return C<$self> for chaining.

=item max_depth($n)

Set maximum nesting depth (default 512).

=back

=head1 DOC API

    use JSON::YY ':doc';

The Doc API operates on yyjson's internal mutable document tree, using
JSON Pointer (RFC 6901) paths for addressing. All keywords compile to
custom ops for maximum performance.

=head2 Document creation

=over 4

=item jdoc $json_string

Parse JSON into a mutable document handle (C<JSON::YY::Doc>).

=item jfrom $perl_value

Create a document from a Perl value (hash, array, scalar).

=back

=head2 Value constructors

Create typed JSON values for use with C<jset>:

=over 4

=item jstr $value - JSON string (ensures string type, e.g. C<jstr "007">)

=item jnum $value - JSON number

=item jbool $value - JSON true/false

=item jnull - JSON null

=item jarr - empty JSON array

=item jobj - empty JSON object

=back

=head2 Path operations

All path arguments use JSON Pointer syntax: C</key/0/nested>.
Use C<""> for root. Use C</arr/-> to append to an array.

=over 4

=item jget $doc, $path

Get a subtree reference (returns a Doc that shares the parent's tree).
Croaks if path not found. Use C<jhas> to check first, or C<jgetp> for
undef-on-missing behavior.

=item jgetp $doc, $path

Get value materialized to Perl (string, number, hashref, arrayref, etc.).
Alias: C<jdecode>.

=item jset $doc, $path, $value

Set value at path. C<$value> can be a scalar (auto-typed), Perl ref
(recursively converted), or another Doc (deep-copied). Returns C<$doc>.

=item jdel $doc, $path

Delete value at path. Returns the removed subtree as an independent Doc,
or C<undef> if path not found.

=item jhas $doc, $path

Check if path exists. Returns boolean.

=item jclone $doc, $path

Deep copy subtree into a new independent document.

=back

=head2 Serialization

=over 4

=item jencode $doc, $path

Serialize document or subtree to compact JSON bytes.

=item jpp $doc, $path

Serialize to pretty-printed JSON (indented with 4 spaces).

=item jraw $doc, $path, $json_fragment

Insert a raw JSON string at path without Perl roundtrip. The fragment
is parsed by yyjson and inserted directly into the document tree.

=back

=head2 Inspection

=over 4

=item jtype $doc, $path

Returns type string: C<"object">, C<"array">, C<"string">, C<"number">,
C<"boolean">, C<"null">.

=item jlen $doc, $path

Array length, object key count, or string byte length.

=item jkeys $doc, $path

Object keys as a list of strings.

=item jvals $doc, $path

Object values as a list of Doc handles.

=back

=head2 Iteration

Pull-style iterators for arrays and objects:

    my $it = jiter $doc, "/users";
    while (defined(my $elem = jnext $it)) {
        my $name = jgetp $elem, "/name";
        my $key  = jkey $it;  # for objects: current key
    }

=over 4

=item jiter $doc, $path - create iterator

=item jnext $iter - advance, returns Doc or undef

=item jkey $iter - current key (objects only)

=back

=head2 File I/O

=over 4

=item jread $filename

Read a JSON file and return a Doc handle.

=item jwrite $doc, $filename

Write a Doc to a file (pretty-printed).

=back

=head2 Path enumeration

=over 4

=item jpaths $doc, $path

Enumerate all leaf paths under the given path. Returns a list of
JSON Pointer strings. Keys containing C<~> or C</> are escaped
per RFC 6901.

=back

=head2 Search

=over 4

=item jfind $doc, $array_path, $key_path, $match_value

Find the first element in an array where the value at C<$key_path>
equals C<$match_value>. Returns the matching element as a Doc,
or C<undef> if not found.

    my $bob = jfind $doc, "/users", "/name", "Bob";

=back

=head2 Patching

=over 4

=item jpatch $doc, $patch_doc

Apply RFC 6902 JSON Patch. C<$patch_doc> must be a Doc containing
a patch array. Modifies C<$doc> in-place.

=item jmerge $doc, $patch_doc

Apply RFC 7386 JSON Merge Patch. Modifies C<$doc> in-place.

=back

=head2 Comparison

=over 4

=item jeq $doc_a, $doc_b

Deep equality comparison. Returns boolean.

=back

=head2 Type predicates

All return boolean. Return false for missing paths.

=over 4

=item jis_obj $doc, $path

=item jis_arr $doc, $path

=item jis_str $doc, $path

=item jis_num $doc, $path

=item jis_int $doc, $path

=item jis_real $doc, $path

=item jis_bool $doc, $path

=item jis_null $doc, $path

=back

=head2 Overloading

C<JSON::YY::Doc> objects support:

    "$doc"          # stringify to JSON
    if ($doc)       # always true
    $a eq $b        # deep equality
    $a ne $b        # deep inequality

=head1 IMPORT FLAGS

    use JSON::YY -utf8, -pretty;

Imports C<encode_json>/C<decode_json> with the specified flags
pre-configured.

=head1 JSON POINTER (RFC 6901)

Paths use JSON Pointer syntax:

    ""            root value
    /key          object key
    /0            array index 0
    /a/b/0/c      nested path
    /arr/-        append to array (jset/jraw only)
    /k~0ey        key containing ~ (escaped as ~0)
    /k~1ey        key containing / (escaped as ~1)

=head1 EXAMPLES

    # surgical edit of large document
    use JSON::YY ':doc';
    my $doc = jdoc $large_json;
    jset $doc, "/config/timeout", 30;
    my $json = jencode $doc, "";

    # extract fields without full decode
    my $doc = jdoc $api_response;
    my $status = jgetp $doc, "/status";
    my $count  = jlen  $doc, "/data/items";

    # type-safe value insertion
    jset $doc, "/active", jbool 1;     # true, not 1
    jset $doc, "/id",     jstr "007";  # "007", not 7

    # iterate without materializing
    my $it = jiter $doc, "/users";
    while (defined(my $u = jnext $it)) {
        say jgetp $u, "/name" if jis_str $u, "/name";
    }

    # apply RFC 6902 patch
    my $patch = jdoc '[{"op":"replace","path":"/v","value":2}]';
    jpatch $doc, $patch;

    # apply RFC 7386 merge patch
    jmerge $doc, jdoc '{"debug":null,"version":"2.0"}';

    # OO decode directly to Doc
    my $coder = JSON::YY->new(utf8 => 1);
    my $doc = $coder->decode_doc($json);

    # insert raw JSON without Perl roundtrip
    jraw $doc, "/blob", '[1,2,{"nested":true}]';

    # deep compare
    say "equal" if jeq $doc_a, $doc_b;
    say "equal" if $doc_a eq $doc_b;   # overloaded

=head1 PERFORMANCE

=head2 Encode (ops/sec, higher is better)

                    JSON::XS    JSON::YY     delta
    small  (38B)    6.4M        6.7M         +4%
    medium (11KB)   26.8K       27.3K        +2%
    large  (806KB)  153         234         +53%

=head2 Decode (ops/sec, higher is better)

                    JSON::XS    JSON::YY     delta
    small  (38B)    4.2M        3.5M        -17%
    medium (11KB)   16.9K       14.1K       -16%
    large  (806KB)  249         267          +8%

Encode is consistently faster, especially on large payloads where
yyjson's optimized serializer dominates. Decode is slightly slower
on small/medium payloads due to Perl SV allocation overhead.

=head2 Doc API vs decode-modify-encode cycle

                            Perl        Doc         speedup
    read one value          3.0M/s      3.1M/s      ~equal
    modify + serialize      1.6M/s      2.2M/s      +42%
    read from large doc     14.6K/s     73.7K/s     +405%
    modify large + encode   7.4K/s      47.3K/s     +536%
    clone subtree           15.0K/s     75.2K/s     +400%
    type/length check       14.4K/s     74.6K/s     +418%

The Doc API avoids full Perl materialization, providing 4-5x speedup
for surgical operations on medium/large documents.

=head1 LIMITATIONS

=over 4

=item * C<canonical> mode is accepted but not yet implemented (yyjson
has no sorted-key writer).

=item * NaN and Infinity values cannot be encoded (croaks).

=back

=head1 COOKBOOK

=head2 Read config, modify, write back

    use JSON::YY ':doc';
    my $config = jread "config.json";
    jset $config, "/database/host", "newhost";
    jwrite $config, "config.json";

=head2 Extract fields from large API response

    my $doc = jdoc $response_body;
    my $status = jgetp $doc, "/status";
    my $count  = jlen  $doc, "/data/items";
    my $first  = jgetp $doc, "/data/items/0/name";

=head2 Find user by name in array

    my $user = jfind $doc, "/users", "/name", "Alice";
    say jgetp $user, "/email" if defined $user;

=head2 Build document from scratch

    my $doc = jfrom {};
    jset $doc, "/name", "My App";
    jset $doc, "/version", jnum 1;
    jset $doc, "/features", jarr;
    jset $doc, "/features/-", "auth";
    jset $doc, "/features/-", "logging";
    jset $doc, "/debug", jbool 0;
    jwrite $doc, "output.json";

=head2 Apply incremental updates (merge patch)

    my $doc = jread "state.json";
    jmerge $doc, jdoc $incoming_patch_json;
    jwrite $doc, "state.json";

=head2 Debug: show all paths

    my @paths = jpaths $doc, "";
    say "$_ = ", jencode $doc, $_ for @paths;

=head2 Type-safe assertions

    die "expected array" unless jis_arr $doc, "/items";
    die "expected string" unless jis_str $doc, "/name";

=head2 Compare two documents

    die "configs differ" if $prod ne $staging;  # overloaded
    # or explicitly:
    die "differ" unless jeq $prod, $staging;

=head1 CHEATSHEET

    # --- Import ---
    use JSON::YY qw(encode_json decode_json);    # functional
    use JSON::YY ':doc';                          # Doc API keywords

    # --- Encode/Decode ---
    encode_json $data          decode_json $json
    $coder->encode($data)      $coder->decode($json)
    decode_json_ro $json       # zero-copy readonly

    # --- Doc lifecycle ---
    jdoc $json                 # parse JSON string -> Doc
    jfrom $perl_data           # Perl data -> Doc
    jread $file                # read JSON file -> Doc
    jwrite $doc, $file         # Doc -> write JSON file
    jencode $doc, $path        # Doc -> JSON string
    jpp $doc, $path            # Doc -> pretty JSON string
    jgetp $doc, $path          # Doc -> Perl value
    $coder->decode_doc($json)  # OO: JSON -> Doc

    # --- Read ---
    jget $doc, $path           # -> Doc subtree ref (shared)
    jgetp $doc, $path          # -> Perl value (materialized)
    jhas $doc, $path           # -> bool
    jfind $doc, $arr, $k, $v   # -> Doc (first match) or undef

    # --- Write ---
    jset $doc, $path, $val     # set (scalar/ref/Doc)
    jdel $doc, $path           # delete -> Doc (removed)
    jraw $doc, $path, $json    # insert raw JSON fragment

    # --- Copy ---
    jclone $doc, $path         # deep copy -> independent Doc

    # --- Inspect ---
    jtype $doc, $path          # "object"|"array"|"string"|...
    jlen $doc, $path           # array/object/string length
    jkeys $doc, $path          # object keys (list)
    jvals $doc, $path          # object values (list of Doc)
    jpaths $doc, $path         # all leaf paths (list)

    # --- Type predicates ---
    jis_obj jis_arr jis_str jis_num jis_int jis_real jis_bool jis_null

    # --- Value constructors ---
    jstr $v    jnum $v    jbool $v    jnull    jarr    jobj

    # --- Iterate ---
    my $it = jiter $doc, $path;
    while (defined(my $v = jnext $it)) { jkey $it; ... }

    # --- Patch ---
    jpatch $doc, $patch        # RFC 6902
    jmerge $doc, $patch        # RFC 7386

    # --- Compare ---
    jeq $a, $b                 # deep equality
    $a eq $b                   # overloaded
    "$doc"                     # overloaded stringify

    # --- Path syntax (JSON Pointer RFC 6901) ---
    ""          root           /key        object key
    /0          array[0]       /arr/-      append to array
    /k~0ey      key with ~     /k~1ey      key with /

=head1 SEE ALSO

L<JSON::XS>, L<Cpanel::JSON::XS>, L<JSON::PP>

yyjson: L<https://github.com/ibireme/yyjson>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

yyjson is included under the MIT License.

=cut
