package Jmespath::Functions;
use strict;
use warnings;
use parent 'Exporter';
use JSON;
use Try::Tiny;
use POSIX qw(ceil floor);
use Jmespath::Expression;
use Jmespath::ValueException;
use Jmespath::JMESPathTypeException;
use Jmespath::String;
use Scalar::Util qw(looks_like_number isdual blessed);
use v5.12;

our @EXPORT_OK = qw( jp_abs
                     jp_avg
                     jp_contains
                     jp_ceil
                     jp_ends_with
                     jp_eq
                     jp_floor
                     jp_gt
                     jp_gte
                     jp_join
                     jp_keys
                     jp_length
                     jp_lt
                     jp_lte
                     jp_map
                     jp_max
                     jp_max_by
                     jp_merge
                     jp_min
                     jp_min_by
                     jp_ne
                     jp_not_null
                     jp_reverse
                     jp_sort
                     jp_sort_by
                     jp_starts_with
                     jp_sum
                     jp_to_array
                     jp_to_string
                     jp_to_number
                     jp_type
                     jp_values );

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

# jp_abs
#
# Absolute value of provided value.  Throws exception if value is not
# a signed integer.
sub jp_abs {
  my @args = @_;
  Jmespath::ValueException
      ->new({ message => 'abs() requires one argument' })
      ->throw
      if scalar @args < 1 or scalar @args > 1;
  my $arg = shift @args;
  Jmespath::ValueException
      ->new({ message => 'contains() illegal boolean value' })
      ->throw
      if JSON::is_bool($arg);

  Jmespath::ValueException
      ->new({ message => 'Not a number: [' . $arg  . ']'})
      ->throw
      if not looks_like_number($arg);
  return abs($arg);
}

sub jp_avg {
  my ($values) = @_;
  Jmespath::ValueException->new({ message => 'Required argument not array ref' })->throw
      if ref $values ne 'ARRAY';
  
  foreach (@$values) {
    Jmespath::ValueException->new({ message => 'Not a number: ' . $_ })->throw
        if not looks_like_number($_);
  }
  return jp_sum($values) / scalar(@$values);
}


sub jp_contains {
  my ( $subject, $search ) = @_;
  Jmespath::ValueException
      ->new({ message => 'contains() illegal boolean value' })
      ->throw
      if JSON::is_bool($subject);
  if ( ref $subject eq 'ARRAY' ) {
    foreach (@$subject) {
      return JSON::true if ( $_ eq $search ); #must be exact string match
    }
    return JSON::false;
  }
  elsif ( ref $subject eq '' ) { # straight string
    return JSON::true if $subject =~ /$search/;
  }
  return JSON::false;
}


sub jp_ceil {
  my ($value) = @_;
  Jmespath::ValueException
      ->new({ message => 'ceil() requires one argument' })
      ->throw
      if not defined $value;
  Jmespath::ValueException
      ->new({ message => 'ceil() requires one number' })
      ->throw
      if not looks_like_number($value);
  return ceil($value);
}

sub jp_ends_with {
  my ( $subject, $suffix ) = @_;
  Jmespath::ValueException
      ->new({ message => 'ends_with() allows strings only' })
      ->throw
      if looks_like_number($suffix);
  return JSON::true if $subject =~ /$suffix$/;
  return JSON::false;
}

sub jp_eq {
  my ($left, $right) = @_;
  return JSON::true  if not defined $left and not defined $right;
  return JSON::false if not defined $left or not defined $right;

  # If $left or $right is a boolean, they both must be boolean
  if (ref($left) eq 'JSON::PP::Boolean' or
      ref($right) eq 'JSON::PP::Boolean') {
    if (ref($left) eq 'JSON::PP::Boolean' and
        ref($right) eq 'JSON::PP::Boolean' ) {
      return JSON::true if $left == $right;
      return JSON::false;
    }
    return JSON::false;
  }

  #If $left or $right is a HASH or ARRAY reference, they need to be
  #compared because comparison of json objects must be handled.
  if (ref($left) eq 'HASH' or ref($right) eq 'HASH') {
    if (ref($left) eq 'HASH' and ref($right) eq 'HASH') {
      return JSON::true if hashes_equal($left, $right);
    }
    return JSON::false;
  }

  if (ref($left) eq 'ARRAY' or ref($right) eq 'ARRAY') {
    if (ref($left) eq 'ARRAY' and ref($right) eq 'ARRAY') {
      return JSON::true if arrays_equal($left, $right);
    }
    return JSON::false;
  }

  if (looks_like_number($left) and
      looks_like_number($right)) {
    return JSON::true if $left == $right;
  }
  elsif (not looks_like_number($left) and
         not looks_like_number($right)) {
    return JSON::true if $left eq $right;
  }
  return JSON::false;
}

sub jp_floor {
  my ($value) = @_;
  Jmespath::ValueException
      ->new({ message => 'floor() requires one argument' })
      ->throw
      if not defined $value;
  Jmespath::ValueException
      ->new({ message => 'floor() requires one number' })
      ->throw
      if not looks_like_number($value);
  return floor($value);
}


sub jp_gt {
  my ($left, $right) = @_;
  # According to the JMESPath Specification, this function returns
  # undef if the variants are not numbers.
  return if not looks_like_number($left);
  return if not looks_like_number($right);
  return JSON::true if $left > $right;
  return JSON::false;
}

sub jp_gte {
  my ($left, $right) = @_;
  # According to the JMESPath Specification, this function returns
  # undef if the variants are not numbers.
  return if not looks_like_number($left);
  return if not looks_like_number($right);
  return JSON::true if $left >= $right;
  return JSON::false;
}

sub jp_lt {
  my ($left, $right) = @_;
  # According to the JMESPath Specification, this function returns
  # undef if the variants are not numbers.
  return if not looks_like_number($left);
  return if not looks_like_number($right);
  return JSON::true if $left < $right;
  return JSON::false;
}

sub jp_lte {
  my ($left, $right) = @_;
  # According to the JMESPath Specification, this function returns
  # undef if the variants are not numbers.
  return if not looks_like_number($left);
  return if not looks_like_number($right);
  return JSON::true if $left <= $right;
  return JSON::false;
}

sub jp_join {
  my ( $glue, $array ) = @_;
  Jmespath::ValueException
      ->new({ message => 'Not an array: ' . $array })
      ->throw
      if ref $array ne 'ARRAY';
  Jmespath::ValueException
      ->new({ message => 'Glue not a string: ' . $glue })
      ->throw
      if jp_type($glue) ne 'string';

  foreach (@$array) {
    Jmespath::ValueException
        ->new({message => "Cannot join " . jp_type($_) . " $_"})
        ->throw
        if jp_type($_) ne 'string' and ref $_ ne 'Jmespath::String';
  }
  return  join ( $glue, @$array );
}


sub jp_keys {
  my ( $obj ) = @_;
  Jmespath::ValueException
      ->new({ message => 'array keys(object obj) argument illegal' })
      ->throw
      if ref $obj ne 'HASH';
  my @objkeys = keys %$obj;
  return \@objkeys;
}

sub jp_length {
  my ( $subject ) = @_;
  my ( $length ) = 0;

  Jmespath::ValueException
      ->new({ message => 'number length(string|array|object subject) argument illegal' })
      ->throw
      if JSON::is_bool($subject) or looks_like_number($subject);
  return scalar @$subject if ref $subject eq 'ARRAY';
  return scalar keys %$subject if ref $subject eq 'HASH';
  return length $subject;
}

sub jp_map {
  my ($expr, $elements) = @_;
#  return [] if ref $elements ne 'ARRAY';
  Jmespath::ValueException
      ->new({ message => 'array[any] map(expression->any->any expr, array[any] elements) undefined elements' })
      ->throw
      if not defined $elements;
  my $result = [];
  foreach my $element (@$elements) {
    use Data::Dumper;
  Jmespath::ValueException
      ->new({ message => 'array[any] map(expression->any->any expr, array[any] elements) undefined elements' })
      ->throw
      if not defined $element;
    my $res = $expr->visit($expr->{expression}, $element);
    push @$result, $res;
  }
  return $result;
}

# must be all numbers or strings in order to work
# perhaps consider List::Util max()
sub jp_max {
  my ( $collection ) = @_;
  Jmespath::ValueException->new({message=>'max(string|number array) argument not an array'})->throw
      if ref $collection ne 'ARRAY';
  my ($current_type, $current_max);
  foreach my $arg (@$collection) {

    my $type = jp_type($arg);
    $current_type = $type if not defined $current_type;
    $current_max = $arg if not defined $current_max;

    Jmespath::ValueException
        ->new({message=>"max(string|number array) mixed types not allowed"})
        ->throw
        if $type ne $current_type;

    Jmespath::ValueException
        ->new({message=>"max(string|number array) $type not allowed"})
        ->throw
        if $type ne 'number' and $type ne 'string';

    if (looks_like_number($arg) and $arg > $current_max) { $current_max = $arg; }
    if (not looks_like_number($arg) and $arg gt $current_max) { $current_max = $arg; }
    $current_type = $type;
  }
  return $current_max;
}

sub jp_max_by {
  my ($array, $expref) = @_;
  my $values = {};
  foreach my $item (@$array) {
    my $result = $expref->visit($expref->{expression}, $item);
    Jmespath::ValueException
        ->new({message=>"min(string|number array) mixed types not allowed"})
        ->throw
        if not defined $result or JSON::is_bool($result);
    $values->{ $result } = $item;
  }
  my @keyed_on = keys %$values;
  return $values->{ jp_max( \@keyed_on ) };
}

# this needs to be a comparison function based on the "type" that is
# being sorted so the correct min/max will be taken by type.

sub jp_keyed_max {
  my ($array, $keyfunc) = @_;
  return $array;
}

sub _create_key_func {
  my ($expref, $allowed_types, $function_name) = @_;
  my $keyfunc = sub {
    my $result = $expref->visit($expref->{expression}, shift);
  };
  return $keyfunc;
}

sub jp_merge {
  my @objects = @_;
  my $merged = {};
  foreach my $object (@objects) {
    Jmespath::ValueException
        ->new({message=>"object merge([object *argument, [, object $...]])"})
        ->throw
        if ref $object ne 'HASH';
    foreach my $key (keys %$object) {
      $merged->{$key} = $object->{$key};
    }
  }
  return $merged;
}

sub jp_min {
  my ($collection) = @_;
  Jmespath::ValueException->new({message=>'min(string|number array) argument not an array'})->throw
      if ref $collection ne 'ARRAY';
  my ($current_type, $current_min);
  foreach my $arg (@$collection) {

    my $type = jp_type($arg);
    $current_type = $type if not defined $current_type;
    $current_min = $arg if not defined $current_min;

    Jmespath::ValueException->new({message=>"min(string|number array) mixed types not allowed"})->throw
        if $type ne $current_type;

    Jmespath::ValueException->new({message=>"min(string|number array) $type not allowed"})->throw
        if $type ne 'number' and $type ne 'string';

    if (looks_like_number($arg) and $arg < $current_min) { $current_min = $arg; }
    if (not looks_like_number($arg) and $arg lt $current_min) { $current_min = $arg; }
    $current_type = $type;
  }
  return $current_min;
}

sub jp_min_by {
  my ($array, $expref) = @_;
  my $values = {};
  foreach my $item (@$array) {
    my $result = $expref->visit($expref->{expression}, $item);
    Jmespath::ValueException
        ->new({message=>"min(string|number array) mixed types not allowed"})
        ->throw
        if not defined $result or JSON::is_bool($result);
    $values->{ $result } = $item;
  }
  my @keyed_on = keys %$values;
  return $values->{ jp_min( \@keyed_on ) };
}

sub jp_ne {
  my ($left, $right) = @_;
  return JSON::false if not defined $left and not defined $right;
  return JSON::true if not defined $left or not defined $right;

  if (ref($left) eq 'JSON::PP::Boolean' or
      ref($right) eq 'JSON::PP::Boolean') {
    if (ref($left) eq 'JSON::PP::Boolean' and
        ref($right) eq 'JSON::PP::Boolean' ) {
      return JSON::true if $left != $right;
      return JSON::false;
    }
#    else {
#      return JSON::false;
#    }
    return JSON::true;
  }

  if (ref($left) eq 'HASH' or ref($right) eq 'HASH') {
    if (ref($left) eq 'HASH' and ref($right) eq 'HASH') {
      return JSON::false if hashes_equal($left, $right);
    }
    return JSON::true;
  }

  if (ref($left) eq 'ARRAY' or ref($right) eq 'ARRAY') {
    if (ref($left) eq 'ARRAY' and ref($right) eq 'ARRAY') {
      return JSON::false if arrays_equal($left, $right);
    }
    return JSON::true;
  }

  
  if (looks_like_number($left) and
      looks_like_number($right)) {
    return JSON::true if $left != $right;
    return JSON::false;
  }

  return JSON::false;
}

#
#
sub jp_not_null {
  my @arguments = @_;
  Jmespath::ValueException
      ->new({ message => 'not_null() requires at least one argument' })
      ->throw
      if not @arguments;
  my $result = [];
  foreach my $argument (@arguments) {
    next if not defined $argument;
    return $argument if defined $argument;
  }
  return;
}

sub jp_reverse {
  my $arg = shift;
  
  if (ref $arg eq 'ARRAY') {
    my $result = [];
    for ( my $idx = scalar @$arg - 1; $idx >= 0; $idx--) {
      push @$result, @$arg[$idx];
    }
    return $result;
  }
  elsif (ref $arg eq '') {
    return reverse $arg;
  }
  return;
}

sub jp_sort {
  my $list = shift;
  Jmespath::ValueException
      ->new({ message=>'array sort(array[number]|array[string] $list) illegal argument' })
      ->throw
      if not defined $list or ref $list ne 'ARRAY';
  my $current_type;
  foreach (@$list) {
    Jmespath::ValueException
        ->new({ message=>'array sort(array[number]|array[string] $list) illegal argument' })
        ->throw
        if ref $_ ne '';
    $current_type = jp_type($_) if not defined $current_type;
    Jmespath::ValueException
        ->new({ message=>'array sort(array[number]|array[string] $list) illegal argument' })
        ->throw
        if $current_type ne 'string' and $current_type ne 'number';
    Jmespath::ValueException
        ->new({ message=>'array sort(array[number]|array[string] $list) mixed types' })
        ->throw
        if $current_type ne jp_type($_);
  }

  my @result = sort { $a cmp $b } @$list ;
  return \@result;
}

sub jp_sort_by {
  my ($array, $expref) = @_;
  my $values = {};
  my $keyed = [];
  my $current_type;
  # create "symbol map" for items
  Jmespath::ValueException
      ->new({message=>"sort_by(array elements, expression->number|expression->string expr) undefined expr not allowed"})
      ->throw
      if not defined $expref;
  for (my $idx = 0; $idx < scalar @$array; $idx++) {
    $values->{$idx} = @{$array}[$idx];
    my $evaled = $expref->visit($expref->{expression}, @{$array}[$idx]);
    $current_type = jp_type($evaled) if not defined $current_type;
    
    Jmespath::ValueException
        ->new({message=>"sort_by(array elements, expression->number|expression->string expr) undefined expr not allowed"})
        ->throw
        if jp_type($evaled) ne $current_type;
    Jmespath::ValueException
        ->new({message=>"min(string|number array) mixed types not allowed"})
        ->throw
        if not defined $evaled or JSON::is_bool($evaled);
    push @$keyed, [ $evaled, $idx ];
  }
  my @sorted = sort { $a->[0] cmp $b->[0] } @$keyed;
  my $res = [];
  foreach my $item (@sorted) {
    push @$res, $values->{$item->[1]};
  }
  return $res;
}

sub jp_starts_with {
  my ($subject, $prefix) = @_;
  Jmespath::ValueException->new({message=>'starts_with(subject, prefix) requires two arguments'})->throw
      if not defined $subject or not defined $prefix;
  Jmespath::ValueException->new({message=>'starts_with(subject, prefix) not a string'})->throw
      if looks_like_number($prefix);
  return JSON::true if $subject =~ /^$prefix/;
  return JSON::false;
}

sub jp_sum {
  my $data = shift;
  my $result = 0;
  foreach my $value (@$data) {
    Jmespath::ValueException
        ->new({message=>'sum(numbers) member not a number'})
        ->throw
        if not looks_like_number($value);
    $result += $value;
  }
  return $result;
}

sub jp_to_array {
  my ($arg) = shift;
  return [$arg] if JSON::is_bool($arg);
  return [$arg] if ref $arg eq 'HASH';
  return $arg   if ref $arg eq 'ARRAY';
  return [$arg];
}

sub jp_to_string {
  my ($arg) = @_;
  $arg = JSON->new->pretty(0)->allow_nonref->encode( $arg )
    if jp_type($arg) eq 'object'
    or jp_type($arg) eq 'array';
  $arg = do { bless \( my $dummy = $arg), "Jmespath::String" }
    if jp_type($arg) eq 'number';
  return $arg;
}

sub jp_to_number {
  my ($arg) = @_;

  return if not looks_like_number($arg);
  return if JSON::is_bool($arg);
  $arg += 0; # remove trailing 0's
  return $arg;
}

sub jp_type {
  my ($item) = @_;
  return 'null' if not defined $item;
  if (JSON::is_bool($item)) { return 'boolean'; }
  if (looks_like_number($item)) {
    return 'string' if ref $item eq 'Jmespath::String';
    return 'number';
  }
  if (ref($item) eq 'ARRAY') { return 'array';}
  if (ref($item) eq 'HASH' ) {return 'object';}
  return 'string';
}

sub jp_values {
  my $obj = shift;
  Jmespath::ValueException
      ->new({message =>'array values(object $obj): illegal argument'})
      ->throw
      if ref $obj ne 'HASH';
  my $result = [];
  foreach my $item (keys %$obj) {
    push @$result, $obj->{$item};
  }
  return $result;
}


sub arrays_equal {
  my ( $a, $b ) = @_;
  if ( scalar @$a != scalar @$b ) {
    return 0;
  }
  for my $i ( 0 .. $#{$a} ) {
    my $va = $a->[$i];
    my $vb = $b->[$i];
    if ( ref $va ne ref $vb ) {
      return 0;
    }
    elsif ( ref $va eq '' and ref $vb eq '' and $va ne $vb) {
      return 0;
    }
    elsif ( ref $va eq 'SCALAR' && $va ne $vb ) {
      return 0;
    }
    elsif ( ref $va eq 'ARRAY' && !arrays_equal( $va, $vb ) ) {
      return 0;
    }
    elsif ( ref $va eq 'HASH' && !hashes_equal( $va, $vb ) ) {
      return 0;
    }
  }
  return 1;
}

sub hashes_equal {
  my ( $a, $b ) = @_;
  if ( scalar( keys %$a ) != scalar( keys %$b ) ) {
    return 0;
  }
  for my $k ( keys %$a ) {
    if ( exists $b->{$k} ) {
      my $va = $a->{$k};
      my $vb = $b->{$k};
      if ( ref $va ne ref $vb ) {
        return 0;
      }
      elsif ( ref $va eq '' and ref $vb eq '' and $va ne $vb ) {
        return 0;
      }
      elsif ( ref $va eq 'SCALAR' && $va ne $vb ) {
        return 0;
      }
      elsif ( ref $va eq 'ARRAY' && !arrays_equal( $va, $vb ) ) {
        return 0;
      }
      elsif ( ref $va eq 'HASH' && !hashes_equal( $va, $vb ) ) {
        return 0;
      }
    }
    else {
      return 0;
    }
  }
  return 1;
}

1;

__END__

=head1 NAME

Functions.pm : JMESPath Built-In Functions

=head1 EXPORTED FUNCTIONS

=head2 jp_abs(value)

=head2 jp_avg(values)

=head2 jp_contains(subject, search)

=head2 jp_ceil(value)

=head2 jp_ends_with(subject, suffix)

=head2 jp_eq

=head2 jp_floor(value)

=head2 jp_gt(left, right)

=head2 jp_gte(left, right)

=head2 jp_lt(left, right)

=head2 jp_lte(left, right)

=head2 jp_map($expr, $elements)

Implements the L<JMESPath Built-In
Function|http://jmespath.org/specification.html#built-in-functions>
L<map()|http://jmespath.org/specification.html#map>

