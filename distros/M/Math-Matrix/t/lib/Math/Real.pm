#!perl

# The purpose of this class is to provide a numerical object that can be used
# as an element in Math::Matrix.
#
# See also Math::Matrix::Real, a subclass of Math::Matrix where each element is
# a Math::Real.
#
# Note that the overloading of "=", i.e., to return the same object, is a
# deliberate decision. It is done to catch the cases where Math::Matrix should
# have called clone(), but doesn't.

use strict;
use warnings;

package Math::Real;

use Carp 'croak';
use Scalar::Util 'blessed';

use overload

  # with_assign: + - * / % ** << >> x .

  '+' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $class -> new($x->{val} + $y->{val});
  },

  '-' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} - $x->{val}):
                     $class -> new($x->{val} - $y->{val});
  },

  '*' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $class -> new($x->{val} * $y->{val});
  },

  '/' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} / $x->{val}):
                     $class -> new($x->{val} / $y->{val});
  },

  '%' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} % $x->{val}):
                     $class -> new($x->{val} % $y->{val});
  },

  '**' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} ** $x->{val}):
                     $class -> new($x->{val} ** $y->{val});
  },

  '<<' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} << $x->{val}):
                     $class -> new($x->{val} << $y->{val});
  },

  '>>' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $swap ? $class -> new($y->{val} >> $x->{val}):
                     $class -> new($x->{val} >> $y->{val});
  },

  # assign: += -= *= /= %= **= <<= >>= x= .=

  '+=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} += $y->{val};
      return $x;
  },

  '-=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} -= $y->{val};
      return $x;
  },

  '*=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} *= $y->{val};
      return $x;
  },

  '/=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} /= $y->{val};
      return $x;
  },

  '%=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} %= $y->{val};
      return $x;
  },

  '**=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} **= $y->{val};
      return $x;
  },

  '<<=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} <<= $y->{val};
      return $x;
  },

  '>>=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} >>= $y->{val};
      return $x;
  },

  # num_comparison: < <= > >= == !=

  '<' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} < $y->{val};
  },

  '<=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} <= $y->{val};
  },

  '>' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} > $y->{val};
  },

  '>=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} >= $y->{val};
  },

  '==' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} == $y->{val};
  },

  '!=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} != $y->{val};
  },

  # 3way_comparison: <=> cmp

  '<=>' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);

      return $swap ? $y->{val} <=> $x->{val}
                   : $x->{val} <=> $y->{val};
  },

  'cmp' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);

      return $swap ? $y->{val} cmp $x->{val}
                   : $x->{val} cmp $y->{val};
  },

  # str_comparison: lt le gt ge eq ne

  'lt' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} lt $y->{val};
  },

  'le' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} le $y->{val};
  },

  'gt' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} gt $y->{val};
  },

  'ge' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} ge $y->{val};
  },

  'eq' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} eq $y->{val};
  },

  'ne' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} ne $y->{val};
  },

  # binary: & &= | |= ^ ^= &. &.= |. |.= ^. ^.=

  '&' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} & $y->{val};
  },

  '&=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} &= $y->{val};
      return $x;
  },

  '|' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} | $y->{val};
  },

  '|=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} |= $y->{val};
      return $x;
  },

  '^' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      return $x->{val} ^ $y->{val};
  },

  '^=' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
      $x->{val} ^= $y->{val};
      return $x;
  },

  # The following requires "use feature 'bitwise';":
  #
  # '&.' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     return $x->{val} &. $y->{val};
  # },
  #
  # '&.=' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     $x->{val} &.= $y->{val};
  #     return $x;
  # },
  #
  # '|.' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     return $x->{val} |. $y->{val};
  # },
  #
  # '|.=' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     $x->{val} |.= $y->{val};
  #     return $x;
  # },
  #
  # '^.' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     return $x->{val} ^. $y->{val};
  # },
  #
  # '^.=' => sub {
  #     my ($x, $y, $swap) = @_;
  #     my $class = ref $x;
  #     $y = $class -> new($y) unless blessed($y) && $y -> isa($class);
  #     $x->{val} ^.= $y->{val};
  #     return $x;
  # },

  # unary: neg ! ~ ~.

  'neg' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      return $class -> new(-$x->{val});
  },

  '!' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      return $class -> new(!$x->{val});
  },

  # mutators: ++ --

  '++' => sub {
      my ($x, $y, $swap) = @_;
      $x->{val}++;
      return $x;
  },

  '--' => sub {
      my ($x, $y, $swap) = @_;
      $x->{val}--;
      return $x;
  },

  # func: atan2 cos sin exp abs log sqrt int

  'atan2' => sub {
      my ($x, $y, $swap) = @_;
      my $class = ref $x;
      $y = $class -> new($y) unless blessed($y) && $y -> isa($class);

      return $swap ? $class -> new(atan2($y->{val}, $x->{val}))
                   : $class -> new(atan2($x->{val}, $y->{val}));
  },

  'cos' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(cos($x->{val}));
  },

  'sin' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(sin($x->{val}));
  },

  'exp' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(exp($x->{val}));
  },

  'abs' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(abs($x->{val}));
  },

  'log' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(log($x->{val}));
  },

  'sqrt' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(sqrt($x->{val}));
  },

  'int' => sub {
      my $x = shift;
      my $class = ref $x;
      return $class -> new(int($x->{val}));
  },

  # conversion: bool "" 0+ qr

  'bool' => sub {
      my $x = shift;
      $x->{val};
  },

  '""' => sub {
      my $x = shift;
      "" . $x->{val};
  },

  '0+' => sub {
      my $x = shift;
      0 + $x->{val};
  },

  # iterators: <>

  # filetest: -X

  # dereferencing: ${} @{} %{} &{} *{}

  # matching: ~~

  # special: nomethod fallback =

  'fallback' => "",     # no autogenerating of methods

  '=' => sub {
      my ($x, $y, $swap) = @_;
      return $x -> clone();
  },

  ;

sub new {
    croak "Too many arguments for ", (caller(0))[3]   if @_ > 2;
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if $selfref;

    my $val = shift;
    croak "Input must be a defined value in ", (caller(0))[3]
      unless defined $val;

    my $ref = ref $val;
    croak "Input must be a scalar, not a $ref in ", (caller(0))[3] if $ref;

    croak "Input argument doesn't look like a number in ", (caller(0))[3]
      unless $val =~ /^[+-]?(\d+(\.\d*)?|\.\d+)([Ee][+-]?\d+)?\z/;

    return bless { val => $val }, $class;
}

sub clone {
    croak "Too many arguments for ", (caller(0))[3]   if @_ > 1;
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    my $self    = shift;
    my $selfref = ref $self;
    my $class   = $selfref || $self;

    croak +(caller(0))[3], " is an instance method, not a class method"
      unless $selfref;

    return bless { val => $self->{val} }, $class;
}

1;
