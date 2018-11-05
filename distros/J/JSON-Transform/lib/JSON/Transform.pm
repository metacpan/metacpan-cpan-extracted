package JSON::Transform;

use strict;
use warnings;
use Exporter 'import';
use JSON::Transform::Parser qw(parse);
use Storable qw(dclone);

use constant DEBUG => $ENV{JSON_TRANSFORM_DEBUG};

our $VERSION = '0.02';
our @EXPORT_OK = qw(
  parse_transform
);

my %QUOTED2LITERAL = (
  b => "\b",
  f => "\f",
  n => "\n",
  r => "\r",
  t => "\t",
  '\\' => "\\",
  '$' => "\$",
  '`' => "`",
  '"' => '"',
  '/' => "/",
);
my %IS_BACKSLASH_ENTITY = map {$_=>1} qw(
  jsonBackslashDouble
  jsonBackslashDollar
  jsonBackslashQuote
  jsonBackslashGrave
);

sub parse_transform {
  my ($input_text) = @_;
  my $transforms = parse $input_text;
  sub {
    my ($data) = @_;
    $data = dclone $data; # now can mutate away
    my $uservals = {};
    for (@{$transforms->{children}}) {
      my $name = $_->{nodename};
      my ($srcptr, $destptr, $mapping);
      if ($name eq 'transformImpliedDest') {
        ($srcptr, $mapping) = @{$_->{children}};
        $destptr = $srcptr;
      } elsif ($name eq 'transformCopy') {
        ($destptr, $srcptr, $mapping) = @{$_->{children}};
      } elsif ($name eq 'transformMove') {
        ($destptr, $srcptr) = @{$_->{children}};
        $srcptr = _eval_expr($data, $srcptr, _make_sysvals(), $uservals, 1);
        die "invalid src pointer '$srcptr'" if !_pointer(1, $data, $srcptr);
        my $srcdata = _pointer(0, $data, $srcptr, 1);
        _apply_destination($data, $destptr, $srcdata, $uservals);
        return $data;
      } else {
        die "Unknown transform type '$name'";
      }
      my $srcdata = _eval_expr($data, $srcptr, _make_sysvals(), $uservals);
      my $newdata;
      if ($mapping) {
        my $opFrom = $mapping->{attributes}{opFrom};
        die "Expected '$srcptr' to point to hash"
          if $opFrom eq '<%' and ref $srcdata ne 'HASH';
        die "Expected '$srcptr' to point to array"
          if $opFrom eq '<@' and ref $srcdata ne 'ARRAY';
        $newdata = _apply_mapping($data, $mapping->{children}[0], dclone $srcdata, $uservals);
      } else {
        $newdata = $srcdata;
      }
      _apply_destination($data, $destptr, $newdata, $uservals);
    }
    $data;
  };
}

sub _apply_destination {
  my ($topdata, $destptr, $newdata, $uservals) = @_;
  my $name = $destptr->{nodename};
  if ($name eq 'jsonPointer') {
    $destptr = _eval_expr($topdata, $destptr, _make_sysvals(), $uservals, 1);
    _pointer(0, $_[0], $destptr, 0, $newdata);
  } elsif ($name eq 'variableUser') {
    my $var = $destptr->{children}[0];
    $uservals->{$var} = $newdata;
  } else {
    die "unknown destination type '$name'";
  }
}

sub _apply_mapping {
  my ($topdata, $mapping, $thisdata, $uservals) = @_;
  my $name = $mapping->{nodename};
  my @pairs = _data2pairs($thisdata);
  if ($name eq 'exprObjectMapping') {
    my ($keyexpr, $valueexpr) = @{$mapping->{children}};
    my %data;
    for (@pairs) {
      my $sysvals = _make_sysvals($_, \@pairs);
      my $key = _eval_expr($topdata, $keyexpr, $sysvals, $uservals);
      my $value = _eval_expr($topdata, $valueexpr, $sysvals, $uservals);
      $data{$key} = $value;
    }
    return \%data;
  } elsif ($name eq 'exprArrayMapping') {
    my ($valueexpr) = @{$mapping->{children}};
    my @data;
    for (@pairs) {
      my $sysvals = _make_sysvals($_, \@pairs);
      my $value = _eval_expr($topdata, $valueexpr, $sysvals, $uservals);
      push @data, $value;
    }
    return \@data;
  } elsif ($name eq 'exprSingleValue') {
    my ($valueexpr) = $mapping;
    my $sysvals = _make_sysvals(undef, \@pairs);
    return _eval_expr($topdata, $valueexpr, $sysvals, $uservals);
  } else {
    die "Unknown mapping type '$name'";
  }
}

sub _make_sysvals {
  my ($pair, $pairs) = @_;
  my %vals = ();
  $vals{C} = scalar @$pairs if $pairs;
  @vals{qw(K V)} = @$pair if $pair;
  return \%vals;
}

sub _eval_expr {
  my ($topdata, $expr, $sysvals, $uservals, $as_location) = @_;
  my $name = $expr->{nodename};
  if ($name eq 'jsonPointer') {
    my $text = join '', '', map _eval_expr($topdata, $_, $sysvals, $uservals),
      @{$expr->{children} || []};
    return $text if $as_location;
    die "invalid src pointer '$text'" if !_pointer(1, $topdata, $text);
    return _pointer(0, $topdata, $text);
  } elsif ($name eq 'variableUser') {
    my $var = $expr->{children}[0];
    die "Unknown user variable '$var'" if !exists $uservals->{$var};
    return $uservals->{$var};
  } elsif ($name eq 'variableSystem') {
    my $var = $expr->{children}[0];
    die "Unknown system variable '$var'" if !exists $sysvals->{$var};
    return $sysvals->{$var};
  } elsif ($name eq 'jsonOtherNotDouble' or $name eq 'jsonOtherNotGrave') {
    return $expr->{children}[0];
  } elsif ($name eq 'exprStringQuoted') {
    my $text = join '', '', map _eval_expr($topdata, $_, $sysvals, $uservals),
      @{$expr->{children} || []};
    return $text;
  } elsif ($name eq 'exprSingleValue') {
    my ($mainexpr, @other) = @{$expr->{children}};
    my $value = _eval_expr($topdata, $mainexpr, $sysvals, $uservals);
    for (@other) {
      my $othername = $_->{nodename};
      if ($othername eq 'exprKeyRemove') {
        my ($keyexpr) = @{$_->{children}};
        my $whichkey = _eval_expr($topdata, $keyexpr, $sysvals, $uservals);
        delete $value->{$whichkey};
      } elsif ($othername eq 'exprKeyAdd') {
        my ($keyexpr, $valueexpr) = @{$_->{children}};
        my $key = _eval_expr($topdata, $keyexpr, $sysvals, $uservals);
        my $addvalue = _eval_expr($topdata, $valueexpr, $sysvals, $uservals);
        $value->{$key} = $addvalue;
      } elsif ($othername eq 'exprApplyJsonPointer') {
        my ($ptrexpr) = @{$_->{children}};
        return _eval_expr($value, $ptrexpr, $sysvals, $uservals);
      } else {
        die "Unknown expression modifier '$othername'";
      }
    }
    return $value;
  } elsif ($IS_BACKSLASH_ENTITY{$name}) {
    my ($what) = @{$expr->{children}};
    my $really = $QUOTED2LITERAL{$what};
    die "Unknown $name '$what'" if !defined $really;
    return $really;
  } elsif ($name eq 'jsonUnicode') {
    my ($what) = @{$expr->{children}};
    return chr hex $what;
  } elsif ($name eq 'exprArrayLiteral') {
    my @contents = @{$expr->{children} || []};
    my @data;
    for (@contents) {
      my $value = _eval_expr($topdata, $_, $sysvals, $uservals);
      push @data, $value;
    }
    return \@data;
  } elsif ($name eq 'exprObjectLiteral') {
    my @colonPairs = @{$expr->{children} || []};
    my %data;
    for (@colonPairs) {
      my ($keyexpr, $valueexpr) = @{$_->{children}};
      my $key = _eval_expr($topdata, $keyexpr, $sysvals, $uservals);
      my $value = _eval_expr($topdata, $valueexpr, $sysvals, $uservals);
      $data{$key} = $value;
    }
    return \%data;
  } else {
    die "Unknown expr type '$name'";
  }
}

sub _data2pairs {
  my ($data) = @_;
  if (ref $data eq 'HASH') {
    return map [ $_, $data->{$_} ], sort keys %$data;
  } elsif (ref $data eq 'ARRAY') {
    my $count = 0;
    return map [ $count++, $_ ], @$data;
  } else {
    die "Given data '$data' neither array nor hash";
  }
}

# based on heart of Mojo::JSON::Pointer
# could be more memory-efficient by shallow-copy/replacing data at each level
sub _pointer {
  my ($contains, $data, $pointer, $is_delete, $set_to) = @_;
  my $is_set = @_ > 4; # if 5th arg supplied, even if false
  return $_[1] = $set_to if $is_set and !length $pointer;
  return $contains ? 1 : $data unless $pointer =~ s!^/!!;
  my $lastptr;
  my @parts = length $pointer ? (split '/', $pointer, -1) : ($pointer);
  while (defined(my $p = shift @parts)) {
    $p =~ s!~1!/!g;
    $p =~ s/~0/~/g;
    if (ref $data eq 'HASH') {
      return undef if !exists $data->{$p} and !$is_set;
      $data = ${ $lastptr = \(
        @parts == 0 && $is_delete ? delete $data->{$p} : $data->{$p}
      )};
    }
    elsif (ref $data eq 'ARRAY') {
      return undef if !($p =~ /^\d+$/ || @$data > $p) and !$is_set;
      $data = ${ $lastptr = \(
        @parts == 0 && $is_delete ? delete $data->[$p] : $data->[$p]
      )};
    }
    else { return undef }
  }
  $$lastptr = $set_to if defined $lastptr and $is_set;
  return $contains ? 1 : $data;
}

=head1 NAME

JSON::Transform - arbitrary transformation of JSON-able data

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/json-transform.svg?branch=master)](https://travis-ci.org/mohawk2/json-transform) |

[![CPAN version](https://badge.fury.io/pl/JSON-Transform.svg)](https://metacpan.org/pod/JSON::Transform) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/json-transform/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/json-transform?branch=master)

=end markdown

=head1 SYNOPSIS

  use JSON::Transform qw(parse_transform);
  use JSON::MaybeXS;
  my $transformer = parse_transform(from_file($transformfile));
  to_file($outputfile, encode_json $transformer->(decode_json $json_input));

=head1 DESCRIPTION

Implements a language concisely describing a set of
transformations from an arbitrary JSON-able piece of data, to
another one. The description language uses L<JSON Pointer (RFC
6901)|https://tools.ietf.org/html/rfc6901> for addressing. JSON-able
means only strings, booleans, nulls (Perl C<undef>), numbers, array-refs,
hash-refs, with no circular references.

A transformation is made up of an output expression, which can be composed
of sub-expressions.

For instance, to transform an array of hashes that each have an C<id>
key, to a hash mapping each C<id> to its hash:

  # [ { "id": 1, "name": "Alice" }, { "id": 2, "name": "Bob" } ]
  # ->
  "" <@ { "/$K/id":$V#`id` }
  # ->
  # { "1": { "name": "Alice" }, "2": { "name": "Bob" } }

While to do the reverse transformation:

  "" <% [ $V@`id`:$K ]

The identity for an array:

  "" <@ [ $V ]

The identity for an object/hash:

  "" <% { $K:$V }

To get the keys of a hash:

  "" <% [ $K ]

To get how many keys in a hash:

  "" <% $C

To get how many items in an array:

  "" <@ $C

To move from one part of a structure to another:

  "/destination" << "/source"

To copy from one part of a structure to another:

  "/destination" <- "/source"

To do the same with a transformation (assumes C</source> is an array
of hashes):

  "/destination" <- "/source" <@ [ $V@`order`:$K ]

To bind a variable, then replace the whole data structure:

  $defs <- "/definitions"
  "" <- $defs

A slightly complex transformation, using the L<jt> script:

  $ cat <<EOF | jt '"" <- "/Time Series (Daily)" <% [ .{ `date`: $K, `close`: $V<"/4. close" } ]'
  {
    "Meta Data": {},
    "Time Series (Daily)": {
      "2018-10-26": { "1. open": "", "4. close": "106.9600" },
      "2018-10-25": { "1. open": "", "4. close": "108.3000" }
    }
  }
  EOF
  # produces:
  [
    {"date":"2018-10-25","close":"108.3000"},
    {"date":"2018-10-26","close":"106.9600"}
  ]

=head2 Expression types

=over

=item Object/hash

These terms are used here interchangeably.

=item Array

=item String

=item Integer

=item Float

=item Boolean

=item Null

=back

=head2 JSON pointers

JSON pointers are surrounded by C<"">. JSON pointer syntax gives special
meaning to the C<~> character, as well as to C</>. To quote a C<~>,
say C<~0>. To quote a C</>, say C<~1>. Since a C<$> has special meaning,
to use a literal one, quote it with a preceding C<\>.

The output type of a JSON pointer is whatever the pointed-at value is.

=head2 Transformations

A transformation has a destination, a transformation type operator, and
a source-value expression. The destination can be a variable to bind to,
or a JSON pointer.

If the source-value expression has a JSON-pointer source, then the
destination can be omitted and the JSON-pointer source will be used.

The output type of the source-value expression can be anything.

=head3 Transformation operators

=over

=item C<<< <- >>>

Copying (including assignment for variable bindings)

=item C<<< << >>>

Moving - error if the source-value is other than a bare JSON pointer

=back

=head2 Destination value expressions

These can be either a variable, or a JSON pointer.

=head3 Variables

These are expressed as C<$> followed by a lower-case letter, followed
by zero or more letters.

=head2 Source value expressions

These can be either a single value including variables, of any type,
or a mapping expression.

=head2 String value expressions

String value expressions can be surrounded by C<``>. They have the same
quoting rules as in JSON's C<">-surrounded strings, including quoting
of C<`> using C<\>. Any value inside, including variables, will be
concatenated in the obvious way, and numbers will be coerced into strings
(be careful of locale). Booleans and nulls will be stringified into
C<[true]>, C<[false]>, C<[null]>.

=head2 Literal arrays

These are a single value of type array, expressed as surrounded by C<.[]>,
with zero or more comma-separated single values.

=head2 Literal objects/hashes

These are a single value of type object/hash, expressed as surrounded
by C<.{}>, with zero or more comma-separated colon pairs (see "Mapping
to an object/hash", below).

=head2 Mapping expressions

A mapping expression has a source-value, a mapping operator, and a
mapping description.

The mapping operator is either C<<< <@ >>>, requiring the source-value
to be of type array, or C<<< <% >>>, requiring type object/hash. If the
input data pointed at by the source value expression is not the right
type, this is an error.

The mapping description must be surrounded by either C<[]> meaning return
type array, or C<{}> for object/hash.

The description will be evaluated once for each input value.
Within the brackets, C<$K> and C<$V> will have special meaning.

For an array input, each input will be each single array value, and C<$K>
will be the zero-based array index.

For an object/hash input, each input will be each pair. C<$K> will be
the object key being evaluated, of type string.

In either case, C<$V> will be the relevant value, of whatever type from
the input. C<$C> will be of type integer, being the number of inputs.

=head3 Mapping to an object/hash

The return value will be of type object/hash, composed of a set of pairs,
expressed within C<{}> as:

=over

=item a expression of type string

=item C<:>

=item an expression of any type

=back

=head3 Mapping to an array

Within C<[]>, the value expression will be an arbitrary value expression.

=head2 Single-value modifiers

A single value can have a modifier, followed by arguments.

=head3 C<@>

The operand value must be of type object/hash.
The argument must be a pair of string-value, C<:>, any-value.
The return value will be the object/hash with that additional key/value pair.

=head3 C<#>

The operand value must be of type object/hash.
The argument must be a string-value.
The return value will be the object/hash without that key.

=head3 C<< < >>

The operand value must be of type object/hash or array.
The argument must be a JSON pointer.
The return value will be the value, but having had the JSON pointer applied.

=head2 Available system variables

=head3 C<$K>

Available in mapping expressions. For each data pair, set to either the
zero-based index in an array, or the string key of an object/hash.

=head3 C<$V>

Available in mapping expressions. For each data pair, set to the value.

=head3 C<$C>

Available in mapping expressions. Set to the integer number of values.

=head2 Comments

Any C<--> sequence up to the end of that line will be a comment,
and ignored.

=head1 DEBUGGING

To debug, set environment variable C<JSON_TRANSFORM_DEBUG> to a true value.

=head1 EXPORT

=head2 parse_transform

On error, throws an exception. On success, returns a function that can
be called with JSON-able data, that will either throw an exception or
return the transformed data.

Takes arguments:

=over

=item $input_text

The text describing the transformation.

=back

=head1 SEE ALSO

L<Pegex>

L<RFC 6902 - JSON Patch|https://tools.ietf.org/html/rfc6902> - intended
to change an existing structure, leaving it (largely) the same shape

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests on
L<https://github.com/mohawk2/json-transform/issues>.

Or, if you prefer email and/or RT: to C<bug-json-transform
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-Transform>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2018 Ed J.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
