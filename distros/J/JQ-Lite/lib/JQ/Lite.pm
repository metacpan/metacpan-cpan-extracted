package JQ::Lite;

use strict;
use warnings;

use JSON::PP ();

use JQ::Lite::Filters;
use JQ::Lite::Parser;
use JQ::Lite::Util ();

our $VERSION = '1.32';

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
    my $data = JQ::Lite::Util::_decode_json($json_text);

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

Version 1.32

=head1 SYNOPSIS

  use JQ::Lite;

  my $jq = JQ::Lite->new;
  my @names = $jq->run_query($json_text, '.users[].name');

  say encode_json($_) for @names;

Command-line usage mirrors the library API:

  cat users.json | jq-lite '.users[].name'
  jq-lite -r '.users[] | .name' users.json

=head1 OVERVIEW

JQ::Lite is a lightweight, pure-Perl JSON query engine inspired by the
L<jq|https://stedolan.github.io/jq/> command-line tool. It gives you jq-style
queries without requiring any XS components or external binaries, so you can
embed powerful JSON exploration directly inside Perl scripts or run it from the
included command-line client.

=head1 GETTING STARTED

=over 4

=item 1. Decode or obtain a JSON string.

  my $json_text = do { local $/; <DATA> };

=item 2. Build a JQ::Lite instance (enable C<raw => 1> to receive raw scalars
instead of JSON-encoded structures).

  my $jq = JQ::Lite->new(raw => 1);

=item 3. Run a jq-style query and iterate over the returned Perl values.

  for my $value ($jq->run_query($json_text, '.users[] | select(.active)')) {
      say $value->{name};
  }

=back

Need a REPL-style experience? Run C<jq-lite> with no query to enter interactive
mode, then experiment with filters until you find the data you need.

=head1 FEATURES AT A GLANCE

=over 4

=item * Pure Perl implementation – no non-core dependencies or XS

=item * Familiar jq-inspired traversal syntax (C<.foo>, C<.foo[]>, C<.foo?>,
array slicing)

=item * Extensive library of filters for aggregations, reshaping, and string
manipulation

=item * Pipeline-friendly design that mirrors jq's mental model

=item * Command-line wrapper with colour output, YAML support, and decoder
selection

=item * Interactive shell for exploring queries line-by-line

=back

=head1 LIBRARY INTERFACE

=head2 new

  my $jq = JQ::Lite->new;

Creates a new instance. Pass C<raw => 1> to receive plain scalars (like jq's
C<-r>) instead of JSON-encoded structures. Additional options may be added in
future versions.

=head1 METHODS

=head2 run_query

  my @results = $jq->run_query($json_text, $query);

Runs a jq-like query against the given JSON string.
Returns a list of matched results. Each result is a Perl scalar
(string, number, arrayref, hashref, etc.) depending on the query.

In scalar context the first result is returned, mirroring jq's behaviour.

=head1 COMMAND-LINE CLIENT

The distribution ships with C<jq-lite>, a drop-in jq-style executable that reads
JSON from STDIN or files, honours common jq flags (C<-r>, C<-c>, C<-n>, C<-s>),
and supports coloured output. Run C<jq-lite --help> for the full option list, or
C<jq-lite --help-functions> to display every built-in helper.

=head1 SUPPORTED SYNTAX

=head2 Traversal and extraction

=over 4

=item * C<.key.subkey>

=item * C<.array[0]> (index access)

=item * C<.array[]> (flatten arrays)

=item * C<.key?> (optional key access without throwing errors)

=back

=head2 Filtering and control flow

=over 4

=item * C<select(.key > 1 and .key2 == "foo")>

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

=item * C<reduce expr as $var (init; update)> (accumulate values with lexical
bindings)

=item * C<foreach expr as $var (init; update [; extract])> (stream results while
folding values)

=back

=head2 Aggregation and grouping

=over 4

=item * C<group_by(.field)>

=item * C<group_count(.field)>

=item * C<sort_by(.key)>, C<sort_desc()>

Sort array elements in descending order using smart numeric/string comparison.

Example:

  .scores | sort_desc

Returns:

  [100, 75, 42, 12]

=item * C<unique_by(.key)>

=item * C<.key | count> (count items or fields)

=item * C<.[] | select(...) | count> (combine flattening + filter + count)

=item * C<sum_by(.field)>, C<avg_by(.field)>, C<median_by(.field)>,
C<percentile(p)>, C<min_by(.field)>, C<max_by(.field)>

Project numeric values from each element and compute aggregated statistics
(sum, average, median, percentiles, min/max, etc.).

=back

=head2 String and array helpers

=over 4

=item * C<.array | map(.field) | join(", ")>

Concatenate array elements with a custom separator string.

Example:

  .users | map(.name) | join(", ")

Results in:

  "Alice, Bob, Carol"

=item * C<split(separator)>

Split string values (and arrays of strings) using a literal separator.

Example:

  .users[0].name | split("")

Results in:

  ["A", "l", "i", "c", "e"]

=item * C<explode()>

Convert strings into arrays of Unicode code points. When applied to arrays the
conversion happens element-wise, while non-string values (including hashes) are
passed through untouched. This mirrors jq's C<explode> helper and pairs with
C<implode> for round-trip transformations.

Example:

  .title | explode

Returns:

  [67, 79, 68, 69]

=item * C<implode()>

Perform the inverse of C<explode> by turning arrays of Unicode code points back
into strings. Nested arrays are processed recursively so pipelines like
C<explode | implode> work over heterogeneous structures. Non-array inputs pass
through unchanged.

Example:

  .codes | implode

Returns:

  "CODE"

=item * C<keys_unsorted()>

Returns the keys of an object without sorting them, mirroring jq's
C<keys_unsorted> helper. Arrays yield their zero-based indices, while
non-object/array inputs return C<undef> to match the behaviour of C<keys>.

Example:

  .profile | keys_unsorted

=item * C<values()>

Returns all values of a hash as an array.
Example:

  .profile | values

=item * C<paths()>

Enumerates every path within the current value, mirroring jq's C<paths>
helper. Each path is emitted as an array of keys and/or indices leading to
objects, arrays, and their nested scalars. Scalars (including booleans and
null) yield a single empty path, while empty arrays and objects contribute only
their immediate location.

Example:

  .user | paths

Returns:

  [["name"], ["tags"], ["tags",0], ["tags",1], ["active"]]

=item * C<leaf_paths()>

Enumerates only the paths that terminate in non-container values, mirroring
jq's C<leaf_paths> helper. This is equivalent to C<paths(scalars)> in jq.

Example:

  .user | leaf_paths

Returns:

  [["name"], ["tags",0], ["tags",1], ["active"]]

=item * C<getpath(path)>

Retrieves the value referenced by the supplied path array (or filter producing
path arrays), mirroring jq's C<getpath/1>. Literal JSON arrays can be passed
directly while expressions such as C<paths()> are evaluated against the current
input to collect candidate paths. When multiple paths are returned the helper
yields an array of values in the same order.

Examples:

  .profile | getpath(["name"])          # => "Alice"
  .profile | getpath(["emails", 1])     # => "alice.work\@example.com"
  .profile | getpath(paths())

=item * C<setpath(path; value)>

Sets or creates a value at the supplied path, following jq's C<setpath/2>
semantics. The first argument may be a literal JSON array or any filter that
emits path arrays. The second argument can be a literal (including JSON
objects/arrays) or another filter evaluated against the current input. Nested
hashes/arrays are automatically created as needed, and the original input is
never mutated.

Examples:

  .settings | setpath(["flags", "beta"]; true)
  .user     | setpath(["profile", "full_name"]; .name)


=item * C<pick(key1, key2, ...)>

Builds a new object containing only the supplied keys. When applied to arrays
of objects, each element is reduced to the requested subset while non-object
values pass through unchanged.

Example:

  .users | pick("name", "email")

Returns:

  [{ "name": "Alice", "email": "alice\@example.com" },
   { "name": "Bob" }]

=item * C<merge_objects()>

Merges arrays of objects into a single hash reference using last-write-wins
semantics. Non-object values within the array are ignored. When no objects are
found, an empty hash reference is returned. Applying the helper directly to an
object returns a shallow copy of that object.

Example:

  .items | merge_objects()

Returns:

  { "name": "Widget", "value": 2, "active": true }


=item * C<to_entries()>

Converts objects (and arrays) into an array of entry hashes, each consisting of
C<key> and C<value> fields in the jq style. Array entries use zero-based index
values for the key so they can be transformed uniformly.

Example:

  .profile | to_entries
  .tags    | to_entries


=item * C<from_entries()>

Performs the inverse of C<to_entries>. Accepts arrays containing
C<{ key => ..., value => ... }> hashes or C<[key, value]> tuples and rebuilds a
hash from them. Later entries overwrite earlier ones when duplicate keys are
encountered.

Example:

  .pairs | from_entries


=item * C<with_entries(filter)>

Transforms objects by mapping over their entries with the supplied filter,
mirroring jq's C<with_entries>. Each entry is exposed as a C<{ key, value }>
hash to the filter, and any entries filtered out are dropped prior to
reconstruction.

Example:

  .profile | with_entries(select(.key != "password"))


=item * C<map_values(filter)>

Applies the supplied filter to every value within an object, mirroring jq's
C<map_values>. When the filter returns no results for a key the entry is
removed, allowing constructs such as C<map_values(select(. > 0))> to prune
falsy values. Arrays are processed element-wise, so arrays of objects can be
transformed in a single step.

Example:

  .profile | map_values(tostring)

=back

=head1 BUILT-IN FILTER CATALOGUE

Beyond the helpers highlighted above, JQ::Lite ships with a wide set of jq
compatibility functions for arithmetic, statistics, type inspection, and data
manipulation. Highlights include:

=over 4

=item * Numeric helpers: C<add>, C<sum>, C<product>, C<min>, C<max>, C<avg>,
C<median>, C<percentile>, C<variance>, C<stddev>, C<clamp>

=item * Array utilities: C<first>, C<last>, C<reverse>, C<drop>, C<tail>,
C<chunks>, C<range>, C<transpose>, C<flatten_all>, C<flatten_depth>,
C<enumerate>

=item * Object introspection: C<keys>, C<keys_unsorted>, C<values>, C<has>,
C<contains>, C<to_entries>, C<from_entries>, C<with_entries>, C<map_values>,
C<pick>, C<merge_objects>, C<paths>, C<leaf_paths>, C<getpath>, C<setpath>,
C<del>, C<delpaths>

=item * Type and string tools: C<type>, C<tostring>, C<tojson>, C<fromjson>,
C<to_number>, C<upper>, C<lower>, C<titlecase>, C<trim>, C<ltrimstr>,
C<rtrimstr>, C<substr>, C<slice>, C<startswith>, C<endswith>, C<test>, C<split>,
C<join>, C<explode>, C<implode>

=item * Boolean logic and predicates: C<not>, C<any>, C<all>, C<walk>, C<map>,
C<select>, C<indices>, C<index>, C<rindex>, C<arrays>, C<objects>, C<scalars>

=back

Run C<jq-lite --help-functions> to view the exhaustive list directly from the
executable.

=head1 SEE ALSO

L<jq|https://stedolan.github.io/jq/>, L<JSON::PP>, L<JSON::XS>,
L<Cpanel::JSON::XS>, L<JSON::MaybeXS>

=head1 AUTHOR

Kawamura Shingo E<lt>pannakoota1\@gmail.comE<gt>

=head1 LICENSE

Same as Perl itself.

=cut
