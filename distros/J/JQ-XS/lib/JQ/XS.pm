package JQ::XS;

use 5.026003;
use strict;
use warnings;

require XSLoader;
use Exporter 'import';

# Loads the overloads (boolification, stringification, ...) for the
# JSON::PP::Boolean objects returned by process().
use JSON::PP::Boolean ();

our $VERSION = '1.01';

XSLoader::load('JQ::XS', $VERSION);

# Constants
sub JQ_DEBUG_TRACE ()       { 1 }
sub JQ_DEBUG_TRACE_DETAIL () { 2 }
sub JQ_DEBUG_TRACE_ALL ()    { 3 }

our @EXPORT_OK = qw(
  JQ_DEBUG_TRACE
  JQ_DEBUG_TRACE_DETAIL
  JQ_DEBUG_TRACE_ALL
);

=head1 NAME

JQ::XS - Perl wrapper for libjq

=head1 SYNOPSIS

  use JQ::XS;

  my $jq = JQ::XS->new('.foo[] | select(. > 2)');

  # Perl data interface
  my @results = $jq->process({ foo => [1, 3, 5] });
  # Returns: (3, 5)

  # JSON text interface
  my @out = $jq->process_json('{"foo":[1,3,5]}');
  # Returns: ('3', '5')

  # Get the program source
  my $prog = $jq->program;

=head1 DESCRIPTION

JQ::XS provides a clean object-oriented wrapper around libjq, the C library
behind the jq command-line tool. It allows you to:

- Compile and execute jq filter programs
- Process Perl data structures (hashes, arrays, numbers, strings)
- Process JSON text
- Handle errors gracefully with Perl exceptions (croak)

=head1 METHODS

=head2 new($program)

Creates a new JQ::XS object by compiling the given jq filter program.

  my $jq = JQ::XS->new('.foo');

Croaks with an error message if the program fails to compile.

=head2 process($data)

Processes Perl data through the compiled jq filter. Takes a Perl scalar
(which can be a reference to a hash or array) and returns a list of
results. Each result is a Perl data structure.

  my @results = $jq->process({ name => 'Alice' });

In scalar context, returns an arrayref of results.

  my $results_ref = scalar($jq->process($data));

Croaks if the jq filter produces a runtime error or if the processing fails.

=head2 Boolean handling

JSON booleans returned by a filter become L<JSON::PP::Boolean> objects,
which behave as true/false in boolean context and stringify to C<1> and
C<0>. They compare equal to the C<JSON::PP::true> and C<JSON::PP::false>
constants.

  my ($is_big) = JQ::XS->new('. > 2')->process(5);   # JSON::PP::true

On input, the following are converted to JSON C<true>/C<false>:

=over 4

=item * L<JSON::PP::Boolean>, C<Types::Serialiser::Boolean>, or L<boolean>
objects (by their truth value)

=item * unblessed references to a plain scalar, e.g. C<\1> and C<\0>

=item * Perl's native boolean values, i.e. the results of comparison and
logical operators and of C<builtin::true>/C<builtin::false>

  $jq->process($x > $y);   # jq sees true or false, not 1 or ""

On perls before 5.36 this only works for a boolean passed directly to
C<process()>; a copy (e.g. stored in a hash or array first) loses its
boolean identity and is treated as an ordinary number/string. On perl
5.36 and later, copies keep their boolean flag and are recognized
anywhere in the structure.

=back

=head2 process_json($json_text)

Like process, but takes JSON text as input and returns a list of JSON
strings (one for each output).

  my @json_out = $jq->process_json('{"name":"Alice"}');

Croaks if the JSON input is invalid or if the jq filter produces a runtime error.

=head2 program()

Returns the source code of the compiled jq filter program.

  my $src = $jq->program;

=head1 CONSTANTS

The following constants are available via @EXPORT_OK:

  JQ_DEBUG_TRACE       - value 1
  JQ_DEBUG_TRACE_DETAIL - value 2
  JQ_DEBUG_TRACE_ALL    - value 3

=head1 AUTHOR

James Rouzier E<lt>rouzier@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 James Rouzier

This library is free software; you can redistribute it and/or modify
it under the terms of the MIT license. See the LICENSE file included
with this distribution.

=cut

# new(), program(), and DESTROY are implemented in XS; the object is a
# blessed pointer to a C struct (T_PTROBJ), not a hashref.

# Pass $_[0] through unaliased: copying it (my $data = ...) would strip
# the identity of Perl's native boolean SVs on perls before 5.36.
sub process {
  my $self = shift;
  my $results = _xs_process($self, $_[0], 0);
  return wantarray ? @$results : $results;
}

sub process_json {
  my $self = shift;
  my $results = _xs_process($self, $_[0], 1);
  return wantarray ? @$results : $results;
}

# Don't clone the underlying C struct into new ithreads.
sub CLONE_SKIP { 1 }

1;
