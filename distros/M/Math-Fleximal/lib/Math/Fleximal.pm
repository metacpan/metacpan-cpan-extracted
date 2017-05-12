package Math::Fleximal;
$VERSION = 0.06;
use Carp;
use integer;
use strict;

sub abs {
  my $self = (shift)->dup();
  $self->{sign} = 1;
  return $self;
}

# Only do with positive result!  (Else normalize bombs.)
sub abs_sub_from {
  my $values = (shift)->{values};
  my $decs = (shift)->{values};
  
  foreach my $i (0..$#$decs) {
    $values->[$i] -= $decs->[$i];
  }
}

sub abs_add_to {
  my $values = (shift)->{values};
  my $incs = (shift)->{values};

  foreach my $i (0..$#$incs) {
    $values->[$i] += $incs->[$i];
  }
}

sub add {
  my $self = shift;
  my $sum = $self->dup();
  foreach (@_) {
    $sum = $sum->plus($_);
  }
  return $sum;
}

sub array2hash {
  my %pos;
  $pos{$_[$_]} = $_ foreach 0..$#_;
  return wantarray ? %pos : \%pos;
}

sub base_10 {
  my $self = shift;
  my $proto = __PACKAGE__->new(0);
  return $proto->dup($self)->to_str();
}

sub change_flex {
  my $self = shift;
  my $new_flex = shift;
  my $proto = __PACKAGE__->new($new_flex->[0], $new_flex);
  $proto->dup($self);
}

sub cmp {
  my $self = shift;
  my $other = $self->dup(shift);
  if ($self->{sign} != $other->{sign}) {
    return $self->{sign};
  }
  else {
    return (
      cmp_vec($self->{values}, $other->{values})
        * $self->{sign}
    );
  }
}

sub cmp_vec {
  my $first = shift;
  my $second = shift;
  
  my $cmp = @$first <=> @$second;
  my $i = @$first;
  
  while ($i and not $cmp) {
    $i--;
    $cmp = $first->[$i] <=> $second->[$i];
  }

  return $cmp;
}

sub div {
  my $self = shift;
  my @remain;
  foreach (@_) {
    ($self, my $rem) = $self->divide($_);
    push @remain, $rem;
  }
  wantarray ? ($self, @remain) : $self;
}

sub divide {
  my $self = shift;
  my $denom = $self->dup(shift);

  unless (@{$denom->{values}}) {
    croak("Cannot divide by zero!");
  }

  # Base 2 is convenient...
  my @doubles = $denom->abs();
  my $remain = $self->abs();
  while ($doubles[-1]->cmp($remain) < 0) {
    push @doubles, $doubles[-1]->plus($doubles[-1]);
  }
  
  my $ans = '';
  while (@doubles) {
    my $double = pop (@doubles);
    if ($double->cmp($remain) <= 0) {
      $ans .= "1";
      $remain = $remain->minus($double);
    }
    else {
      $ans .= "0";
    }
  }
  
  # Convert answer
  $ans = __PACKAGE__->new($ans, [0, 1]);
  # Handle differing sign without exact division...
  if (
    $remain->cmp(0) and
      $self->{sign} == -1
  ) {
    $remain = $denom->abs->minus($remain);
    $ans = $ans->plus(1);
  }
  $ans->{sign} = $self->{sign} * $denom->{sign};
  return ($self->dup($ans), $remain)
}

sub dup {
  my $self = shift;
  my $copy = bless +{ %$self }, ref($self);
  my $val = @_ ? shift : $self;
  return $copy->set_value($val);
}

sub gcd {
  my $self = shift;
  my $zero = $self->zero();

  foreach (@_) {
    my $other = $self->dup($_);
    while ($other->cmp($zero)) {
      ($self, $other) = ($other, $self->mod($other));
    }
  }

  return $self;
}

sub make_mybase {
  my $self = shift;
  return map $self->dup($_), @_;
}

sub minus {
  my $self = shift;
  my $other = $self->dup(shift);
  $other->{sign} = - $other->{sign};
  return $self->add($other);
}

sub mod {
  my @remain = div(@_);
  shift @remain;
  wantarray ? @remain : $remain[-1];
}

sub mul {
  my $prod = (shift)->dup();
  foreach (@_) {
    $prod = $prod->times($_);
  }
  return $prod;
}

sub new {
  my %default = (
    '+' => '+',
    '-' => '-',
    'show_+' => 0,
    strip => qr/[\s\.,_]/,
  );

  my $self = bless {sign => 1, value => [], %default}, shift;
  my $value = shift;
  my $flex = $self->{flex} = shift || [0..9];
  my $args = shift || {};
  
  $self->{base} = @$flex;
  $self->{match_fleck} = ret_match_any(@$flex);
  $self->{fleck_lookup} = array2hash(@$flex);
  
  foreach my $key (keys %$args) {
    if (exists $default{$key}) {
      $self->{$key} = $args->{$key};
    }
    else {
      my $valid = join ", ", map "'$_'", sort keys %default;
      croak("Unknown parameter '$valid'.  Allowed: ($valid)");
    }
  } 
  
  return $self->set_value($value);
}

# values assumed to work out nonnegative
sub normalize {
  my $self = shift;
  my $base = $self->{base};
  my $values = $self->{values};
  
  # We need to have a valid base rep
  my $i = 0;
  my $carry = 0;
  while ($carry or $i < @$values) {
    $carry += $values->[$i] if ($values->[$i]);
    while ($carry < 0) {
      $carry += $base;
      $values->[$i + 1]--;
    }
    $values->[$i] = $carry % $base;
    
    $carry /= $base;
    ++$i;
  }
  
  # Deal with leading 0's and 0...
  pop(@$values) while @$values and not $values->[-1];
  $self->{sign} = 1 if not @$values;
  return $self;
}

sub one {
  my $num = (shift)->dup();
  $num->{sign} = 1;
  $num->{values} = [1];
  return $num;
}

sub parse_rep {
  my $self = shift;
  my $str = shift;
  
  $str =~ s/$self->{strip}//g;
  my $sign = 1;
  if ($str =~ /^\Q$self->{"-"}\E/g) {
    $sign = -1;
  }
  else {
    $str =~ /^\Q$self->{"+"}\E/g;
  }
  
  my @values;
  my $match_fleck = $self->{match_fleck};
  my $fleck_lookup = $self->{fleck_lookup};
  my $last_pos = pos($str);
  
  while ($str =~ /\G($match_fleck)/g) {
    push @values, $fleck_lookup->{$1};
    $last_pos = pos($str);
  }
  
  croak(
    "Cannot find any digits in $str.\n" .
    "Current flex: (@{$self->{flex}})\n"
  ) unless @values;
  
  carp("'$str' truncated in parse")
    unless $last_pos == length($str);
  
  return ($sign, [reverse @values]);
}

sub plus {
  my $self = shift;
  my $other = $self->dup(shift);
  my $sum;
  if ($self->{sign} == $other->{sign}) {
    $sum = $self->dup();
    abs_add_to($sum, $other);
  }
  elsif (0 < cmp_vec($self->{values}, $other->{values})) {
    $sum = $self->dup();
    $sum->abs_sub_from($other);
  }
  else {
    $sum = $other->dup();
    $sum->abs_sub_from($self);
  }
  return $sum->normalize();
}

sub pow {
  my $cur_base = shift;
  {
    my $exp = $cur_base->dup(shift);
    unless (1 == $exp->{sign}) {
      $exp = $exp->to_str();
      croak("Cannot handle negative exponent: '$exp'");
    }

    my $res = $cur_base->one();
    # Base 2 is easier
    $exp = $exp->change_flex([0, 1]);
    foreach my $term (@{$exp->{values}}) {
      if ($term) {
        $res = $res->times($cur_base);
      }
      $cur_base = $cur_base->times($cur_base);
    }
    if (@_) {
      $cur_base = $res;
      redo;
    }
    else {
      return $res;
    }
  }
}

sub ret_match_any {
  # Hack to match longest token possible
  my @toks = reverse sort @_;
  my $str = join "|", map quotemeta($_), @_;
  return qr/$str/;
}

sub set_value {
  my $self = shift;
  my $value = shift;
  if (ref($value)) {
    if ($self->{base} == $value->{base}) {
      $self->{values} = [ @{ $value->{values} } ];
    }
    else {
      my $factor = $value->{base};
      my $converted = $self->zero();
      my $scale = $self->one();

      foreach (@{ $value->{values} }) {
        $converted = $converted->plus($scale->times_const($_));
        $scale = $scale->times_const($factor);
      }
      $self->{values} = $converted->{values};
    }
    $self->{sign} = $value->{sign};
  }
  else {
    @$self{'sign', 'values'} = $self->parse_rep($value);
    $self->normalize();
  }
  return $self;
}

sub subtr {
  my $result = (shift)->dup();
  $result = $result->minus($_) foreach @_;
  return $result;
}

sub times {
  my $self = shift;
  my $other = $self->dup(shift);
  
  my $result = $self->zero();
  my @leading_zeros = ();
  
  # Prevents possible sign bug on 0
  unless (@{$self->{values}} and @{$other->{values}}) {
    return $result;
  }
  
  foreach (@{ $other->{values} }) {
    my $tmp = $self->times_const($_);
    unshift @{$tmp->{values}}, @leading_zeros;
    $result = $result->plus($tmp);
    push @leading_zeros, 0;
  }
  
  $result->{sign} = $self->{sign} * $other->{sign};

  $result;
}

sub times_const {
  my $result = (shift)->dup();
  my $const = shift;
  if ($const < 0) {
    $const *= -1;
    $result->{sign} = - $result->{sign};
  }
  foreach my $term (@{$result->{values}}) {
    $term *= $const;
  }
  $result->normalize();
  return $result;
}
    

sub to_str {
  my $self = shift;
  my $flex = $self->{flex};
  my @vals = @{$self->{values}};
  push @vals, 0 unless @vals;
  my $p = $self->{'show_+'} ? $self->{'+'} : "";
  return join "",
    (1 == $self->{sign} ? $p : $self->{'-'}),
    map $flex->[$_], reverse @vals;
}

sub zero {
  my $num = (shift)->dup();
  $num->{sign} = 1;
  $num->{values} = [];
  return $num;
}

1;

__END__

=head1 NAME

Math::Fleximal - Integers with flexible representations.

=head1 SYNOPSIS

  use Math::Fleximal;
  my $number = new Math::Fleximal($value, $flex);
  
  # Set the value
  $number = $number->set_value("- $fleck_4$fleck_3");
  $number = $number->set_value($another_number);

  # Get the object in a familiar form  
  my $string = $number->to_str();
  my $integer = $number->base_10();
  
  # Construct more numbers with same flex
  my $copy = $number->dup();
  my $other_number = $number->dup($value);
  my $absolute_value = $number->abs();

  # New representation anyone?
  my $in_new_base = $number->change_flex($new_flex);

  # Arithmetic - can be different flex.  Answers have
  # the flex of $number.
  $result = $number->add($other_number);
  $result = $number->mul($other_number);
  $result = $number->subtr($other_numer);
  $result = $number->div($other_number);

  # And integer-specific arithmetic works
  $result = $number->gcd($other_number);
  $result = $number->mod($other_number);
  
  my $comparison = $number->cmp($other_number);

=head1 DESCRIPTION

This is a package for doing integer arithmetic while
using a different base representation than normal.  In
base n arithmetic you have n symbols which have a
representation.  I was going to call them "glyphs",
but being text strings they are not really.  On Tye
McQueen's whimsical suggestion I settled on the name 
Math::Fleximal, the set of text representations is 
called a "flex", and the representation of individual 
digits are the "flecks".  These names are somewhat 
unofficial...

This allows you to do basic arithmetic using whatever
digits you want, and to convert from one to another.

Like C<Math::BigInt> it is able to handle very large
numbers, though performance is not very good.  (Which
is also like C<Math::BigInt>, for good performance
you should be using <Bit::Vector>.)  Instead use it as
a version of Math::BaseCalc without an upper limit on
the size of numbers.  A sample use would be to put an
MD5 hash into a convenient representation:

  use Math::Fleximal;
  use Digest::MD5 qw(md5_hex);
  my $digest = hex2alpha(md5_hex($data));
  
  # Converts a hex representation of a number into
  # one that uses more alphanumerics.  (ie base 62)
  sub hex2alpha {
    Math::Fleximal->new(
      lc(shift), [0..9, 'a'..'f']
    )->change_flex(
      [0..9,'a'..'z','A'..'Z']
    )->to_str();
  }


=over 4

=item C<new>

Construct a new number.  The arguments are the value,
the anonymous array of flecks that make up the flex,
followed by an anonymous hash of other arguments.
The flex will default to [0..9] and the other arguments
will default to an empty hash.

This can be used to calculations in bases other than 10
- the base is just the number of flecks in the flex.  So
you could construct a base 16 number with:

  my $base_16 = new Math::Fleximal("4d", [0..9, 'a'..'f']);

If a value is passed it can be an existing Math::Fleximal
or (as above) a string that can be parsed with the current
flex.

The possible keys to the optional arguments are:

=over 8

=item *

I<+> for the plus symbol to use.  This defaults to '+'.

=item *

I<-> for the minus symbol to use.  This defaults to '-'.

=item *

I<show_+> is a flag for whether to show the plus symbol
on positive numbers.  This defaults to a false value.

=item *

Whatever matches I<strip> will be stripped from the
string before parsing.  This defaults to qr/[\s\.,_]/
to cover most of the common ways that are used to group
digits in a long number.

=back

The parsing of a string into flecks is case sensitive.
Also possibly ambiguous parses are not handled very
well.

=item C<dup>

Copy an existing number.  This copy may be worked with
without changing the existing number.  If dup is passed
a value, the new instance will have that value instead.

=item C<set_value>

This sets the internal value and returns the object.

You can either pass the new value an existing instance
(which may be in another base) or a string.  When passed
a string it first strips whitespace.  After that it
accepts an optional +-, followed by a series of flecks
(there must be at least one) for the first to last
digits.  It will be confused if the leading fleck starts
with + or - and no sign is included.

=item C<to_str>

Returns the string representation of the current value
using the current flex.  This always includes a sign,
with no white space in front of the sign.

=item C<base_10>

Returns the internal value in a base 10 representation.
The numbers returned may be larger than Perl's usual
integer representation can handle.

=item C<change_flex>

Takes a new flex and converts the current to that.
Will implicitly change base if needed.

=item C<add>

Adds one or more numbers to the current one and returns
the answer in the current representation.  The numbers
may be objects in any base, or strings of the current
representation.

=item C<mul>

Multiplies one or more numbers to the current one and
returns the answer in the current representation.  The
numbers may be objects in any base, or strings of the
current representation.

=item C<subtr>

Subtracts one or more numbers from the current one and
returns the answer in the current representation.
The numbers may be objects in any base, or strings of
the current representation.

=item C<div>

Divides one or more numbers from the current one and
returns the answer in the current representation.
In list context it will return the answer and an
array of remainders in the current representation.
The remainders will be positive and less than the
absolute value of the denominator. The numbers may be
objects in any base, or strings of the current
representation.

=item C<gcd>

Takes one or more numbers and calculates the gcd of
this and the entire list.

=item C<mod>

Does the divisions as C<div> does and returns only the
remainders.  In scalar context only the last remainder
is returned.  Thus the following returns the
ten-thousands digit:

  my $digit = $number->mod(1000, 10);

=item C<cmp>

Pass another number, returns -1 if it is smaller than
the other number, 0 if they are equal, and 1 if it is
larger.  (Much like cmp does with strings.)

=item C<one>

Returns 1 in the current flex.

=item C<zero>

Returns 0 in the current flex.

=back

=head1 BUGS

This will fail if you are trying to work in bases of
size more than 30,000 or so.

Only a slight effort is made to resolve potential
ambiguities in the parsing of a string into flecks.

=head1 AUTHOR AND COPYRIGHT

Copyright 2000-2001, Ben Tilly (<btilly@gmail.com>)

Math::Fleximal may be copied and distributed on the
same terms as Perl itself.
