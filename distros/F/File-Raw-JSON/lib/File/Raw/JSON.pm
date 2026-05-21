package File::Raw::JSON;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

use File::Raw;
use Tie::OrderedHash;

require XSLoader;
XSLoader::load('File::Raw::JSON', $VERSION);

1;

__END__

=head1 NAME

File::Raw::JSON - Fast JSON / JSONL plugin for File::Raw

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

Loading the module registers two plugins (C<json>, C<jsonl>) with
File::Raw at BOOT time. Use them via File::Raw's standard plugin tail:

    use File::Raw qw(slurp spew each_line);
    use File::Raw::JSON;     # registers json + jsonl plugins

    # Single JSON document
    my $config = file_slurp("config.json", plugin => 'json');

    # Pretty-printed write
    file_spew("out.json", $payload, plugin => 'json',
              pretty => 1, sort_keys => 1);

    # JSON Lines / NDJSON streaming (line-by-line, RSS bounded)
    file_each_line("events.jsonl",
        sub { my $event = $_[0]; ... },
        plugin => 'jsonl');

    # Whole-file JSONL into AoV
    my $events = file_slurp("events.jsonl", plugin => 'jsonl');

For in-memory bytes <-> structure work (no path, no syscalls), import
the direct codec:

    use File::Raw::JSON qw(file_json_decode file_json_encode);

    my $val   = file_json_decode($json_bytes);
    my $bytes = file_json_encode($val, pretty => 1, sort_keys => 1);

    # JSONL via the same entry points
    my $rows  = file_json_decode($jsonl_bytes, mode => 'lines');
    my $out   = file_json_encode(\@rows,       mode => 'lines');

=head1 DESCRIPTION

Fast JSON I/O integrated with the L<File::Raw> plugin pipeline. One
syscall path through File::Raw, then a direct call into
L<yyjson|https://github.com/ibireme/yyjson> (vendored, MIT).

Two plugins are registered:

=over 4

=item B<json>

One JSON value per file. C<slurp> returns the parsed structure
(hashref / arrayref / scalar / undef); C<spew> serialises any Perl
value back to JSON bytes. C<each_line> with this plugin croaks with
a "use 'jsonl'" message - single documents don't decompose into
records.

=item B<jsonl>

JSONL / NDJSON / concatenated JSON values. C<slurp> returns an AoV;
C<spew> takes an AoV and writes one record per line; C<each_line>
streams records via callback (memory-bounded).

JSONL parsing uses brace-balancing rather than newline-splitting,
mirroring L<JSON::Lines>'s C<$LINES> regex. This means:

=over 4

=item * Pretty-printed JSONL works (records can span multiple lines).

=item * Multiple records on one line work (C<{"a":1}{"b":2}> = 2 records).

=item * Braces inside string fields don't break parsing.

=item * Chunked input is buffered and re-assembled across reads.

=back

=back

=head1 DIRECT CODEC

For callers who already have JSON bytes in scalar form (or who want
JSON bytes back without round-tripping through a temp file), two
importable XSUBs:

=over 4

=item C<file_json_decode($bytes, ?key =E<gt> value, ...)>

Parses C<$bytes> and returns the decoded Perl value. Default mode is
C<document> (one value per buffer); pass C<mode =E<gt> 'lines'> to
parse a JSONL/NDJSON buffer and get back an arrayref of values.

    my $val   = file_json_decode($json_bytes);
    my $rows  = file_json_decode($jsonl_bytes, mode => 'lines');
    my $cfg   = file_json_decode($cfg_bytes,   ordered => 1, relaxed => 1);

Passing C<undef> returns C<undef>. Malformed input croaks with the
yyjson error message and byte offset.

=item C<file_json_encode($value, ?key =E<gt> value, ...)>

Serialises C<$value> and returns JSON bytes. Default mode is
C<document>; pass C<mode =E<gt> 'lines'> with an arrayref payload to
get back a JSONL buffer (one record per line, trailing C<\n>).

    my $bytes = file_json_encode($val);
    my $jsonl = file_json_encode(\@rows, mode => 'lines');
    my $diff  = file_json_encode($val,   pretty => 1, sort_keys => 1);

=back

The trailing key/value list accepts the same options as the plugin
path (see L</OPTIONS> below). Odd-count tails croak; unknown keys
croak.

These are XSUBs in the C<File::Raw::JSON> package; importable on
request via C<use File::Raw::JSON qw(file_json_decode file_json_encode)>
or C<use File::Raw::JSON qw(:codec)>. They share the same yyjson
codec body as the plugin path, so output is byte-identical to a
C<File::Raw::spew(... plugin =E<gt> 'json', ...)> for the same input.

=head1 OPTIONS

The standard plugin tail accepts these keys.

=over 4

=item C<mode>

C<document> (default for the C<json> plugin) or C<lines> (default
for C<jsonl>). Override the plugin's default per call.

=item C<pretty>

Encode: pretty-print with newlines and indent. Default false.

=item C<indent>

Encode: spaces per indent level when C<pretty> is on. Must be 2 or
4 (yyjson constraint). Arbitrary indent strings planned for v0.02.

=item C<sort_keys>

Encode: emit object keys in sorted order. Off by default for speed;
on for diff-friendly output.

=item C<canonical>

Encode: shorthand for C<sort_keys =E<gt> 1> + minimal whitespace.

=item C<utf8>

Treat bytes as UTF-8. Default true.

=item C<relaxed>

Decode: tolerate C<//> and C</* */> comments and trailing commas.

=item C<allow_nonref>

Decode: accept top-level scalars (C<42>, C<"hi">, C<true>). Default
true.

=item C<allow_nan_inf>

Round-trip C<NaN>, C<Infinity>, C<-Infinity>. Non-standard JSON;
default false.

=item C<ordered>

Decode JSON objects as L<Tie::OrderedHash>-tied hashes so insertion
order is preserved on the Perl side. yyjson already preserves source
order on parse; the regular Perl HV randomises iteration since 5.18,
which is what this option works around.

    my $config = file_slurp("config.json", plugin => 'json', ordered => 1);
    # keys(%$config) returns in document order

    my $events = file_slurp("trace.jsonl", plugin => 'jsonl', ordered => 1);
    # each $events->[$i] preserves its original key order

Decode-only flag. The encoder detects the tied storage automatically
and emits keys in insertion order, so a parsed-then-re-encoded ordered
structure round-trips byte-for-byte without any extra flag.

Cost: ordered mode is slower than the default HV path because
maintaining insertion order requires bookkeeping the encoder/decoder
otherwise wouldn't do.  Indicative numbers on a 10k-record JSONL
fixture (10 fields each):

  decode default  vs  decode ordered:   ~4x slower
  encode default  vs  encode ordered:   ~1.25x slower (C ABI iterator)
  round-trip      vs  round-trip:        ~3x slower

The encode side is essentially free; the decode side pays the
AV/HV bookkeeping that maintains the insertion-ordered key list.
Use the option only when order actually matters; the default is
the fast path.

=item C<boolean_class>

Class to bless decoded JSON true/false into. Default
C<File::Raw::JSON::Boolean>. The encoder also recognises
C<JSON::PP::Boolean>, C<Types::Serialiser::Boolean>,
C<Cpanel::JSON::XS::Boolean>, C<JSON::XS::Boolean>, and the
C<boolean> module by name string.

=item C<max_depth>

Decode: croak on nesting deeper than this. Default 512.

=item C<eol>

JSONL only: line terminator on encode. 1-3 bytes, default C<\n>.

=back

=head1 VALUE MAPPING

  JSON                Perl                    Encoded back as
  ----                ----                    ---------------
  null                undef                   null
  true / false        blessed sentinel        matching literal
  integer (IV)        IV                      integer
  integer (UV)        UV                      integer
  float               NV                      float (shortest round-trip)
  string              utf8-decoded SV         JSON string
  array               AV ref                  [ ... ]
  object              HV ref                  { ... }

=head1 STREAMING

C<each_line($path, $cb, plugin =E<gt> 'jsonl')> opens the file via
File::Raw's STREAM dispatch, reads in 64 KiB chunks, accumulates
bytes in a per-call buffer, and uses a brace-balancing state machine
to slice off complete top-level values. Each value is parsed and
passed to your callback. RSS is bounded by the read buffer + the
largest single JSON value in the stream.

To abort mid-stream, C<die> from the callback. The exception
propagates and the buffer is freed.

=head1 SEE ALSO

L<File::Raw>, L<JSON::Lines>, L<https://jsonlines.org/>,
L<https://github.com/ibireme/yyjson>.

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0
(GPL Compatible).

The bundled yyjson library is Copyright (c) 2020 YaoYuan, MIT
licensed - see C<LICENSE.yyjson>.

=cut
