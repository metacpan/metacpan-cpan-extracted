package JQ::Lite;

use strict;
use warnings;

use JSON::PP;

use JQ::Lite::Filters;
use JQ::Lite::Parser;
use JQ::Lite::Util ();

our $VERSION = '1.15';

sub new {
    my ($class, %opts) = @_;
    my $self = {
        raw => $opts{raw} || 0,
        _vars => {},
    };
    return bless $self, $class;
}

sub run_query {
    my ($self, $json_text, $query) = @_;
    my $data = decode_json($json_text);

    return ($data) if !defined $query || $query =~ /^\s*\.\s*$/;

    my @parts = JQ::Lite::Parser::parse_query($query);

    my @results = ($data);
    for my $part (@parts) {
        my @next_results;

        if (JQ::Lite::Filters::apply($self, $part, \@results, \@next_results)) {
            @results = @next_results;
            next;
        }

        for my $item (@results) {
            push @next_results, JQ::Lite::Util::_traverse($item, $part);
        }
        @results = @next_results;
    }

    return @results;
}

1;
__END__

=encoding utf-8

=head1 NAME

JQ::Lite - A lightweight jq-like JSON query engine in Perl

=head1 VERSION

Version 1.15

=head1 SYNOPSIS

  use JQ::Lite;
  
  my $jq = JQ::Lite->new;
  my @results = $jq->run_query($json_text, '.users[].name');
  
  for my $r (@results) {
      print encode_json($r), "\n";
  }

=head1 DESCRIPTION

JQ::Lite is a lightweight, pure-Perl JSON query engine inspired by the
L<jq|https://stedolan.github.io/jq/> command-line tool.

It allows you to extract, traverse, and filter JSON data using a simplified
jq-like syntax — entirely within Perl, with no external binaries or XS modules.

=head1 FEATURES

=over 4

=item * Pure Perl (no XS, no external binaries required)

=item * Dot notation traversal (e.g. .users[].name)

=item * Optional key access using '?' (e.g. .nickname?)

=item * Array indexing and flattening (.users[0], .users[])

=item * Boolean filters via select(...) with ==, !=, <, >, and, or

=item * Pipe-style query chaining using | operator

=item * Built-in functions: length, keys, keys_unsorted, values, first, last, reverse, sort, sort_desc, sort_by, min_by, max_by, unique, unique_by, has, contains, test, any, all, not, group_by, group_count, join, split, explode, implode, count, empty, type, nth, del, delpaths, compact, upper, lower, titlecase, abs, ceil, floor, trim, ltrimstr, rtrimstr, substr, slice, startswith, endswith, add, sum, sum_by, avg_by, median_by, product, min, max, avg, median, mode, percentile, variance, stddev, drop, tail, chunks, range, enumerate, transpose, flatten_all, flatten_depth, clamp, tostring, tojson, fromjson, to_number, pick, merge_objects, to_entries, from_entries, with_entries, map_values, walk, paths, leaf_paths, getpath, setpath, index, rindex, indices, arrays, objects, scalars

=item * Supports map(...), map_values(...), walk(...), limit(n), drop(n), tail(n), chunks(n), range(...), and enumerate() style transformations

=item * Interactive mode for exploring queries line-by-line

=item * Command-line interface: C<jq-lite> (compatible with stdin or file)

=item * Decoder selection via C<--use> (JSON::PP, JSON::XS, etc.)

=item * Debug output via C<--debug>

=item * List all functions with C<--help-functions>

=back

=head1 CONSTRUCTOR

=head2 new

  my $jq = JQ::Lite->new;

Creates a new instance. Options may be added in future versions.

=head1 METHODS

=head2 run_query

  my @results = $jq->run_query($json_text, $query);

Runs a jq-like query against the given JSON string.
Returns a list of matched results. Each result is a Perl scalar
(string, number, arrayref, hashref, etc.) depending on the query.

=head1 SUPPORTED SYNTAX

=over 4

=item * .key.subkey

=item * .array[0] (index access)

=item * .array[] (flattening arrays)

=item * .key? (optional key access)

=item * select(.key > 1 and .key2 == "foo") (boolean filters)

=item * group_by(.field) (group array items by key)

=item * reduce expr as $var (init; update) (accumulate values with lexical bindings)

=item * foreach expr as $var (init; update [; extract]) (stream results while folding values)

=item * if CONDITION then FILTER [elif CONDITION then FILTER ...] [else FILTER] end (conditional branching)

Evaluates jq-style conditional expressions. Conditions are treated as filters
executed against the current input; the first branch whose condition produces a
truthy result has its filter evaluated and emitted. Optional C<elif> clauses
cascade additional tests, and the optional C<else> filter runs only when no
prior branch matched. When no C<else> clause is supplied and every condition is
falsey the expression yields no output.

Example:

  if .score >= 90 then "A"
  elif .score >= 80 then "B"
  else "C"
  end

=item * group_count(.field) (tally items by key)

=item * sum_by(.field) (sum numeric values projected from each array item)

=item * avg_by(.field) (average numeric values projected from each array item)

=item * median_by(.field) (median of numeric values projected from each array item)

=item * percentile(p) (return the requested percentile for numeric array values)

=item * min_by(.field) / max_by(.field) (select array element with smallest/largest projected value)

=item * sort_desc()

Sort array elements in descending order using smart numeric/string comparison.

Example:

  .scores | sort_desc

Returns:

  [100, 75, 42, 12]

=item * sort_by(.key) (sort array of objects by key)

=item * unique_by(.key) (remove duplicates based on a projected key)

=item * .key | count (count items or fields)

=item * .[] | select(...) | count (combine flattening + filter + count)

=item * .array | map(.field) | join(", ")

Concatenates array elements with a custom separator string.
Example:

  .users | map(.name) | join(", ")

Results in:

  "Alice, Bob, Carol"

=item * split(separator)

Split string values (and arrays of strings) using a literal separator.
Example:

  .users[0].name | split("")

Results in:

  ["A", "l", "i", "c", "e"]

=item * explode()

Convert strings into arrays of Unicode code points. When applied to arrays the
conversion happens element-wise, while non-string values (including hashes) are
passed through untouched. This mirrors jq's C<explode> helper and pairs with
C<implode> for round-trip transformations.

Example:

  .title | explode

Returns:

  [67, 79, 68, 69]

=item * implode()

Perform the inverse of C<explode> by turning arrays of Unicode code points back
into strings. Nested arrays are processed recursively so pipelines like
C<explode | implode> work over heterogeneous structures. Non-array inputs pass
through unchanged.

Example:

  .codes | implode

Returns:

  "CODE"


=item * keys_unsorted()

Returns the keys of an object without sorting them, mirroring jq's
C<keys_unsorted> helper. Arrays yield their zero-based indices, while
non-object/array inputs return C<undef> to match the behaviour of C<keys>.

Example:

  .profile | keys_unsorted

=item * values()

Returns all values of a hash as an array.
Example:

  .profile | values

=item * paths()

Enumerates every path within the current value, mirroring jq's C<paths>
helper. Each path is emitted as an array of keys and/or indices leading to
objects, arrays, and their nested scalars. Scalars (including booleans and
null) yield a single empty path, while empty arrays and objects contribute only
their immediate location.

Example:

  .user | paths

Returns:

  [ ["name"], ["tags"], ["tags",0], ["tags",1], ["active"] ]

=item * leaf_paths()

Enumerates only the paths that terminate in non-container values, mirroring
jq's C<leaf_paths> helper. This is equivalent to C<paths(scalars)> in jq.

Example:

  .user | leaf_paths

Returns:

  [ ["name"], ["tags",0], ["tags",1], ["active"] ]

=item * getpath(path)

Retrieves the value referenced by the supplied path array (or filter producing
path arrays), mirroring jq's C<getpath/1>. Literal JSON arrays can be passed
directly while expressions such as C<paths()> are evaluated against the current
input to collect candidate paths. When multiple paths are returned the helper
yields an array of values in the same order.

Examples:

  .profile | getpath(["name"])          # => "Alice"
  .profile | getpath(["emails", 1])     # => "alice.work\@example.com"
  .profile | getpath(paths())

=item * setpath(path; value)

Sets or creates a value at the supplied path, following jq's C<setpath/2>
semantics. The first argument may be a literal JSON array or any filter that
emits path arrays. The second argument can be a literal (including JSON
objects/arrays) or another filter evaluated against the current input. Nested
hashes/arrays are automatically created as needed, and the original input is
never mutated.

Examples:

  .settings | setpath(["flags", "beta"]; true)
  .user     | setpath(["profile", "full_name"]; .name)

=item * pick(key1, key2, ...)

Builds a new object containing only the supplied keys. When applied to arrays
of objects, each element is reduced to the requested subset while non-object
values pass through unchanged.

Example:

  .users | pick("name", "email")

Returns:

  [ { "name": "Alice", "email": "alice\@example.com" },
    { "name": "Bob" } ]

=item * merge_objects()

Merges arrays of objects into a single hash reference using last-write-wins
semantics. Non-object values within the array are ignored. When no objects are
found, an empty hash reference is returned. Applying the helper directly to an
object returns a shallow copy of that object.

Example:

  .items | merge_objects()

Returns:

  { "name": "Widget", "value": 2, "active": true }

=item * to_entries()

Converts objects (and arrays) into an array of entry hashes, each consisting of
C<key> and C<value> fields in the jq style. Array entries use zero-based index
values for the key so they can be transformed uniformly.

Example:

  .profile | to_entries
  .tags    | to_entries

=item * from_entries()

Performs the inverse of C<to_entries>. Accepts arrays containing
C<{ key => ..., value => ... }> hashes or C<[key, value]> tuples and rebuilds a
hash from them. Later entries overwrite earlier ones when duplicate keys are
encountered.

Example:

  .pairs | from_entries

=item * with_entries(filter)

Transforms objects by mapping over their entries with the supplied filter,
mirroring jq's C<with_entries>. Each entry is exposed as a C<{ key, value }>
hash to the filter, and any entries filtered out are dropped prior to
reconstruction.

Example:

  .profile | with_entries(select(.key != "password"))

=item * map_values(filter)

Applies the supplied filter to every value within an object, mirroring jq's
C<map_values>. When the filter returns no results for a key the entry is
removed, allowing constructs such as C<map_values(select(. > 0))> to prune
falsy values. Arrays are processed element-wise, so arrays of objects can be
transformed in a single step.

Example:

  .profile | map_values(tostring)

Returns:

  { "name": "Alice", "age": "42" }

=item * walk(filter)

Recursively traverses arrays and objects, applying the supplied filter to each
value after its children have been transformed, matching jq's C<walk/1>
behaviour. Arrays and hashes are rebuilt so nested values can be updated in a
single pass, while scalars pass directly to the filter.

Example:

  .profile | walk(upper)

Returns:

  { "name": "ALICE", "note": "TEAM LEAD" }

=item * recurse([filter])

Performs a depth-first traversal mirroring jq's C<recurse>. Each invocation
emits the current value and then evaluates either the optional child filter or,
when omitted, the object's values and array elements. This makes it easy to
walk arbitrary tree structures:

Example:

  .users[0] | recurse(.children[]?) | .name

Returns:

  "Alice"
  "Bob"
  "Carol"

=item * empty()

Discards all output. Compatible with jq.
Useful when only side effects or filtering is needed without output.

Example:

  .users[] | select(.age > 25) | empty

=item * .[] as alias for flattening top-level arrays

=item * transpose()

Pivots an array of arrays from row-oriented to column-oriented form. When
rows have different lengths, the result truncates to the shortest row so that
every column contains the same number of elements.

Example:

  [[1, 2, 3], [4, 5, 6]] | transpose

Returns:

  [[1, 4], [2, 5], [3, 6]]

=item * flatten_all()

Recursively flattens nested arrays into a single-level array while preserving
non-array values.

Example:

  [[1, 2], [3, [4]]] | flatten_all

Returns:

  [1, 2, 3, 4]

=item * flatten_depth(n)

Flattens nested arrays up to C<n> levels deep while leaving deeper nesting
intact.

Example:

  [[1, [2]], [3, [4]]] | flatten_depth(1)

Returns:

  [1, [2], 3, [4]]


=item * arrays

Emits its input only when the value is an array reference, mirroring jq's
C<arrays> filter. Scalars and objects yield no output, making it convenient to
select array inputs prior to additional processing.

Example:

  .items[] | arrays

Returns only the array entries from C<.items>.

=item * objects

Emits its input only when the value is a hash reference, mirroring jq's
C<objects> filter. Scalars and arrays yield no output, letting you isolate
objects inside heterogeneous streams.

Example:

  .items[] | objects

Returns only the object entries from C<.items>.

=item * scalars

Emits its input only when the value is a scalar (including strings, numbers,
booleans, or null/undef), mirroring jq's C<scalars> helper. Arrays and objects
yield no output, making it easy to focus on terminal values within mixed
streams.

Example:

  .items[] | scalars

Returns only the scalar entries from C<.items>.

=item * type()

Returns the type of the value as a string:
"string", "number", "boolean", "array", "object", or "null".

Example:

  .name | type     # => "string"
  .tags | type     # => "array"
  .profile | type  # => "object"

=item * lhs // rhs

Implements jq's alternative operator. The left-hand side is returned when it
produces a defined value (including false or empty arrays); otherwise the
right-hand expression is evaluated as a fallback.

Example:

  .users[] | (.nickname // .name)

Returns the nickname when present, otherwise the name field.

=item * default(value)

Provides a convenience helper to replace undefined or null pipeline values
with a literal fallback.

Example:

  .nickname | default("unknown")

Ensures the string C<"unknown"> is emitted when C<.nickname> is missing or
null.

=item * nth(n)

Returns the nth element (zero-based) from an array.

Example:

  .users | nth(0)   # first user
  .users | nth(2)   # third user

=item * del(key)

Deletes a specified key from a hash object and returns a new hash without that key.

Example:

  .profile | del("password")

If the key does not exist, returns the original hash unchanged.

If applied to a non-hash object, returns the object unchanged.

=item * delpaths(paths)

Removes multiple keys or indices identified by the supplied C<paths> expression.
The expression is evaluated against the current input (for example by using
C<paths()> or other jq-lite helpers) and should yield an array of path arrays,
mirroring jq's C<delpaths/1> behaviour.

Example:

  .profile | delpaths([["password"], ["tokens", 0]])

Paths can be generated dynamically using helpers such as C<paths()> before being
passed to C<delpaths>. When a referenced path is missing it is ignored.
Providing an empty path (C<[]> ) removes the entire input value, yielding C<null>.

=item * compact()

Removes undef and null values from an array.

Example:

  .data | compact()

Before: [1, null, 2, null, 3]

After:  [1, 2, 3]

=item * upper()

Converts strings to uppercase. When applied to arrays, each scalar element
is uppercased recursively, leaving nested hashes or booleans untouched.

Example:

  .title | upper      # => "HELLO WORLD"
  .tags  | upper      # => ["PERL", "JSON"]

=item * titlecase()

Converts strings to title case (first letter of each word uppercase). When
applied to arrays, each scalar element is transformed recursively, leaving
nested hashes or booleans untouched.

Example:

  .title | titlecase   # => "Hello World"
  .tags  | titlecase   # => ["Perl", "Json"]

=item * lower()

Converts strings to lowercase. When applied to arrays, each scalar element
is lowercased recursively, leaving nested hashes or booleans untouched.

Example:

  .title | lower      # => "hello world"
  .tags  | lower      # => ["perl", "json"]

=item * has(key)

Checks whether the current value exposes the supplied key or index.

* For hashes, returns true when the key is present.
* For arrays, returns true when the zero-based index exists.

Example:

  .meta  | has("version")   # => true
  .items | has(2)            # => true when at least 3 elements exist

=item * contains(value)

Checks whether the current value includes the supplied fragment.

* For strings, returns true when the substring exists.
* For arrays, returns true if any element equals the supplied value.
* For hashes, returns true when the key is present.

Example:

  .title | contains("perl")     # => true
  .tags  | contains("json")     # => true
  .meta  | contains("lang")     # => true

=item * test(pattern[, flags])

Evaluates whether the current string input matches a regular expression. The
pattern is interpreted as a Perl-compatible regex, and optional flag strings
support the common jq modifiers C<i>, C<m>, C<s>, and C<x>.

* Scalars are coerced to strings before matching (booleans become C<"true"> or
  C<"false">).
* Arrays are processed element-wise, returning arrays of JSON booleans.
* Non-string container values that cannot be coerced yield C<false>.

Examples:

  .title | test("^Hello")           # => true
  .title | test("world")            # => false (case-sensitive)
  .title | test("world"; "i")      # => true (case-insensitive)
  .tags  | test("^p")               # => [true, false, false]

=item * all([filter])

Evaluates whether every element (optionally projected through C<filter>) is
truthy, mirroring jq's C<all/1> helper.

=over 4

=item * For arrays without a filter, returns true when every element is truthy
  (empty arrays yield true).

=item * For arrays with a filter, applies the filter to each element and
  requires every produced value to be truthy.

=item * When the current input is a scalar, falls back to checking the value's
  truthiness (or the filter's results when supplied).

=back

Examples:

  .flags | all            # => true when every element is truthy (empty => true)
  .users | all(.active)   # => true when every user is active

=item * any([filter])

Returns true when at least one value in the input is truthy. When a filter is
provided, it is evaluated against each array element (or the current value when
not operating on an array) and the truthiness of the filter's results is used.

* For arrays without a filter, returns true if any element is truthy.
* For arrays with a filter, returns true when the filter yields a truthy value
  for any element.
* For scalars, hashes, and other values, evaluates the value (or filter results)
  directly.

Example:

  .flags | any            # => true when any element is truthy
  .users | any(.active)   # => true when any user is active

=item * not

Performs logical negation using jq's truthiness rules. Returns C<true> when the
current input is falsy (e.g. C<false>, C<null>, empty string, empty array, or
empty object) and C<false> otherwise. Arrays and objects are considered truthy
when they contain at least one element or key, respectively.

Examples:

  true  | not   # => false
  []    | not   # => true
  .ok   | not   # => negates the truthiness of .ok

=item * unique_by(".key")

Removes duplicate objects (or values) from an array by projecting each entry to
the supplied key path and keeping only the first occurrence of each signature.
Use C<.> to deduplicate by the entire value.

Example:

  .users | unique_by(.name)      # => keeps first record for each name
  .tags  | unique_by(.)          # => removes duplicate scalars

=item * startswith("prefix")

Returns true if the current string (or each string inside an array) begins with
the supplied prefix. Non-string values yield C<false>.

Example:

  .title | startswith("Hello")   # => true
  .tags  | startswith("j")       # => [false, true, false]

=item * endswith("suffix")

Returns true if the current string (or each string inside an array) ends with
the supplied suffix. Non-string values yield C<false>.

Example:

  .title | endswith("World")     # => true
  .tags  | endswith("n")         # => [false, true, false]

=item * substr(start[, length])

Extracts a substring from the current string using zero-based indexing.
When applied to arrays, each scalar element receives the same slicing
arguments recursively.

Examples:

  .title | substr(0, 5)       # => "Hello"
  .tags  | substr(-3)         # => ["erl", "SON"]

=item * slice(start[, length])

Returns a portion of the current array using zero-based indexing. Negative
start values count from the end of the array. When length is omitted, the
slice continues through the final element. Non-array inputs pass through
unchanged so pipelines can mix scalar and array values safely.

Examples:

  .users | slice(0, 2)        # => first two users
  .users | slice(-2)          # => last two users

=item * tail(n)

Returns the final C<n> elements of the current array. When C<n> is zero the
result is an empty array, and when C<n> exceeds the array length the entire
array is returned unchanged. Non-array inputs pass through untouched so the
helper composes cleanly inside pipelines that also yield scalars or objects.

Examples:

  .users | tail(2)            # => last two users
  .users | tail(10)           # => full array when shorter than 10

=item * range(start; end[, step])

Emits a numeric sequence that begins at C<start> (default C<0>) and advances
by C<step> (default C<1>) until reaching but not including C<end>. When the
step is negative the helper counts downward and stops once the value is less
than or equal to the exclusive bound. Non-numeric arguments result in the
input being passed through unchanged so pipelines remain resilient.

Examples:

  null | range(5)           # => 0,1,2,3,4
  null | range(2; 6; 2)     # => 2,4
  null | range(10; 2; -4)   # => 10,6

=item * enumerate()

Converts arrays into an array of objects pairing each element with its
zero-based index. Each object contains two keys: C<index> for the position and
C<value> for the original element. Non-array inputs are returned unchanged so
the helper composes inside pipelines that may yield scalars or hashes.

Examples:

  .users | enumerate()          # => [{"index":0,"value":...}, ...]
  .numbers | enumerate() | map(.index)

=item * index(value)

Returns the zero-based index of the first occurrence of the supplied value.
When the current result is an array, deep comparisons are used so nested
structures (hashes, arrays, booleans) work as expected. When the current value
is a string, the function returns the position of the substring, or null when
not found.

Example:

  .users | index("Alice")     # => 0
  .tags  | index("json")      # => 1

=item * rindex(value)

Returns the zero-based index of the final occurrence of the supplied value.
Array inputs are scanned from the end using deep comparisons, while string
inputs return the position of the last matching substring (or null when not
found).

Example:

  .users | rindex("Alice")    # => 3
  .tags  | rindex("perl")     # => 2
  "banana" | rindex("an")    # => 3

=item * indices(value)

Returns every zero-based index where the supplied value appears. For arrays,
deep comparisons are performed against each element and the matching indexes
are collected into an array. For strings, the helper searches for literal
substring matches (including overlapping ones) and emits each starting
position. When the fragment is empty, positions for every character boundary
are returned to mirror jq's behaviour.

Example:

  .users | indices("Alice")     # => [0, 3]
  "banana" | indices("an")      # => [1, 3]
  "perl"   | indices("")        # => [0, 1, 2, 3, 4]

=item * abs()

Returns absolute values for numbers. Scalars are converted directly, while
arrays are processed element-by-element with non-numeric entries preserved.

Example:

  .temperature | abs      # => 12
  .deltas      | abs      # => [3, 4, 5, "n/a"]

=item * ceil()

Rounds numbers up to the nearest integer. Scalars and array elements that look
like numbers are rounded upward, while other values pass through unchanged.

Example:

  .price   | ceil     # => 20
  .changes | ceil     # => [2, -1, "n/a"]

=item * floor()

Rounds numbers down to the nearest integer. Scalars and array elements that
look like numbers are rounded downward, leaving non-numeric values untouched.

Example:

  .price   | floor    # => 19
  .changes | floor    # => [1, -2, "n/a"]

=item * round()

Rounds numbers to the nearest integer using standard rounding (half up for
positive values, half down for negatives). Scalars and array elements that look
like numbers are adjusted, while other values pass through unchanged.

Example:

  .price   | round    # => 19
  .changes | round    # => [1, -2, "n/a"]

=item * clamp(min, max)

Constrains numeric values within the supplied inclusive range. Scalars and
array elements that look like numbers are coerced into numeric context and
clamped between the provided minimum and maximum. When a bound is omitted or
non-numeric, it is treated as unbounded on that side. Non-numeric values pass
through unchanged so pipelines remain lossless.

Example:

  .score  | clamp(0, 100)       # => 87
  .deltas | clamp(-5, 5)        # => [-5, 2, 5, "n/a"]

=item * tostring()

Converts the current value into a JSON string representation. Scalars are
stringified directly, booleans become C<"true">/C<"false">, and undefined
values are rendered as C<"null">. Arrays and objects are encoded to their JSON
text form so the output matches jq's behavior when applied to structured data.

Example:

  .score   | tostring   # => "42"
  .profile | tostring   # => "{\"name\":\"Alice\"}"

=item * tojson()

Encodes the current value as JSON text regardless of its original type,
mirroring jq's C<tojson>. Scalars, booleans, nulls, arrays, and objects all
produce a JSON string, allowing raw string inputs to be re-escaped safely for
embedding or subsequent decoding.

Example:

  .score   | tojson   # => "42"
  .name    | tojson   # => "\"Alice\""
  .profile | tojson   # => "{\"name\":\"Alice\"}"

=item * fromjson()

Parses JSON text back into native Perl data structures. Plain strings are
decoded directly, while arrays are processed element-by-element to mirror jq's
convenient broadcasting behaviour. Invalid JSON inputs are passed through
unchanged so pipelines remain lossless.

Example:

  .raw   | fromjson   # => {"name":"Bob"}
  .lines | fromjson   # => [1, true, null]

=item * to_number()

Coerces values that look like numbers into actual numeric scalars. Strings are
converted with Perl's numeric semantics, booleans become 1 or 0, and arrays are
processed element-by-element. Non-numeric strings, objects, and other references
are returned unchanged so pipelines remain lossless.

Example:

  .score    | to_number   # => 42
  .strings  | to_number   # => [10, "n/a", 3.5]

=item * trim()

Removes leading and trailing whitespace from strings. Arrays are processed
recursively, while hashes and other references are left untouched.

Example:

  .title | trim          # => "Hello World"
  .tags  | trim          # => ["perl", "json"]

=item * ltrimstr("prefix")

Removes C<prefix> from the start of strings when present. Arrays are processed
recursively so nested string values receive the same treatment. Inputs that do
not begin with the supplied prefix are returned unchanged.

Example:

  .title | ltrimstr("Hello ")  # => "World"
  .tags  | ltrimstr("#")       # => ["perl", "json"]

=item * rtrimstr("suffix")

Removes C<suffix> from the end of strings when present. Arrays are processed
recursively so nested string values are handled consistently. Inputs that do
not end with the supplied suffix are returned unchanged.

Example:

  .title | rtrimstr(" World")  # => "Hello"
  .tags  | rtrimstr("ing")     # => ["perl", "json"]

=back

=head1 COMMAND LINE USAGE

C<jq-lite> is a CLI wrapper for this module.

  cat data.json | jq-lite '.users[].name'
  jq-lite '.users[] | select(.age > 25)' data.json
  jq-lite -r '.users[].name' data.json
  jq-lite '.[] | select(.active == true) | .name' data.json
  jq-lite '.users[] | select(.age > 25) | count' data.json
  jq-lite '.users | map(.name) | join(", ")'
  jq-lite '.users[] | select(.age > 25) | empty'
  jq-lite '.profile | values'

=head2 Interactive Mode

Omit the query to enter interactive mode:

  jq-lite data.json

You can then type queries line-by-line against the same JSON input.

=head2 Decoder Selection and Debug

  jq-lite --use JSON::PP --debug '.users[0].name' data.json

=head2 Show Supported Functions

  jq-lite --help-functions

Displays all built-in functions and their descriptions.

=head1 REQUIREMENTS

Uses only core modules:

=over 4

=item * JSON::PP

=back

Optional: JSON::XS, Cpanel::JSON::XS, JSON::MaybeXS

=head1 SEE ALSO

L<JSON::PP>, L<jq|https://stedolan.github.io/jq/>

=head1 AUTHOR

Kawamura Shingo E<lt>pannakoota1@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
