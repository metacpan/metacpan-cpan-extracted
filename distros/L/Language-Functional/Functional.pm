package Language::Functional;

use strict;
use warnings;
use Carp;
no strict 'refs';
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $INFINITE);
require Exporter;

@ISA = qw(Exporter);
$VERSION = '0.05';
$INFINITE = 8192;

my @methods = qw(show inc double square cons max min even odd 
	     rem quot gcd lcm Until
	     id const flip fst snd head Last tail init
	     null Map filter Length concat 
	     foldl foldl1 scanl scanl1
	     foldr foldr1 scanr scanr1
	     iterate repeat replicate
	     take drop splitAt takeWhile dropWhile span break
	     lines words unlines unwords Reverse
	     And Or any all elem notElem lookup maximum minimum
	     sum product zip zip3 unzip unzip3
	     integers factors prime
	     );

@EXPORT_OK = @methods;
%EXPORT_TAGS = ('all', => \@methods);


=head1 NAME

Language::Functional - a module which makes Perl slightly more functional

=head1 SYNOPSIS

  use Language::Functional ':all';
  print 'The first ten primes are: ', 
    show(take(10, filter { prime(shift) } integers)), "\n";

=head1 DESCRIPTION

Perl already contains some functional-like functions, such as
C<map> and C<grep>. The purpose of this module is to add other
functional-like functions to Perl, such as foldl and foldr, as
well as the use of infinite lists.

Think as to how you would express the first ten prime
numbers in a simple way in your favourite programming 
language? So the example in the synopsis is a killer app,
if you will (until I think up a better one ;-).

The idea is mostly based on Haskell, from which most of the
functions are taken. There are a couple of major omissions:
currying and types. Lists (and tuples) are simply Perl list
references, none of this 'cons' business, and strings are
simple strings, not lists of characters.

The idea is to make Perl slightly more functional, rather
than completely replace it. Hence, this slots in very well
with whatever else your program may be doing, and is very
Perl-ish. Other modules are expected to try a much more
functional approach.

=head1 FUNCTIONS

The following functions are available. (Note: these should not be
called as methods).

In each description, I shall give the Haskell definition
(if I think it would help) as well as a useful example.

=over 4

=cut

# Insert copious amounts of POD documentation here for each
# function... (test.pl will have to do for now)

sub show_old {
  join ", ",
    map {
      my $d = Data::Dumper->new([$_]);
      $d->Indent(0)->Terse(1);
      $d->Dump;
    } @_;
}


=item show

Show returns a string representation of an object.
It does not like infinite lists.

=cut

sub show {
  return join ", ", map {show_aux($_)} @_;
}

sub show_aux {
  my $x = shift;
  if (not defined $x) {
    return 'undef';
  } elsif ($x eq '') {
    return "''";
  } elsif (not ref $x) {
    if ($x =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) {
      return "$x";
    } elsif ($x =~ /^.$/) {
      return "'$x'";
    } else {
      $x =~ s|\n|\\n|g;
      return '"' . $x . '"';
    }
  } elsif (ref($x) eq 'ARRAY') {
    # Here we evaluate all values of the array. As this can
    # be lazy, and might resize the array, we have to do this
    # now.
    map { $x->[$_] if $_ < scalar @{$x}} (0..scalar @{$x});
#    return "(Array of size " . scalar @{$x} . ", " . ref($x) . ")" . "[" . show(@{$x}) . "]";
    return "[" . show(@{$x}) . "]";
  } else {
    return "[ref $x]";
  }
}


=item inc k

Increases the value passed by 1.

  $x = inc 2; # 3

In Haskell:

  inc          :: a -> a
  inc k         = 1 + k

=cut

sub inc($) {
  return shift() + 1;
}


=item double k

Doubles the passed value.

  $x = double 3; # 6

In Haskell:

  double         :: a -> a
  double k        = k * 2

=cut

sub double($) {
  return shift() * 2;
}


=item square k

Returns the square of the passed value. eg:

  $x = square 3; # 9

In Haskell:

  square          :: a -> a
  square k         = k * k

=cut

sub square($) {
  return shift() ** 2;
}

sub cons {
  unshift @{$_[1]}, $_[0];
  return ($_[1]);
}

sub min($$) {
  my($x, $y) = @_;
  return $x if $x < $y;
  return $y;
}

sub max($$) {
  my($x, $y) = @_;
  return $x if $x > $y;
  return $y;
}

sub even($) {
  my $x = shift;
  return not $x % 2;
}

sub odd($) {
  my $x = shift;
  return not even($x);
}

sub rem($$) {
  my($x, $y) = @_;
  return $x % $y;
}

sub quot($$) {
  my($x, $y) = @_;
  return int($x/$y);
}


=item gcd x y

Returns the greatest common denominator of two 
numbers. eg:

  $x = gcd(144, 1024); # 16

In Haskell:

  gcd :: Integral a => a -> a -> a
  gcd 0 0 = error "gcd 0 0 is undefined"
  gcd x y = gcd' (abs x) (abs y)
            where gcd' x 0 = x
            gcd' x y = gcd' y (x `rem` y)

=cut

sub gcd($$) {
  my($x, $y) = @_;
  croak "gcd(0, 0) is undefined!" if ($x == 0 and $y == 0);
  return gcd_aux(abs $x, abs $y);
}

sub gcd_aux($$);
sub gcd_aux($$) {
  my($x, $y) = @_;
  return $x if $y == 0;
  return gcd_aux($y, rem($x, $y));
}


=item lcm x y

Returns the lowest common multiple of two numbers.
eg:

  $x = lcm(144, 1024); # 9216

In Haskell:

  lcm            :: (Integral a) => a -> a -> a
  lcm _ 0         = 0
  lcm 0 _         = 0
  lcm x y         = abs ((x `quot` gcd x y) * y)

=cut

sub lcm($$) {
  my($x, $y) = @_;
  return 0 if $x == 0;
  return 0 if $y == 0;
  return abs((quot($x,gcd($x, $y))) * $y);
}


=item id x

The identity function - simply returns the argument.
eg:

  $x = id([1..6]); # [1, 2, 3, 4, 5, 6].

In Haskell:

  id             :: a -> a
  id x            = x

=cut

sub id {
  my @values = @_;
  return @values;
}


=item const k _

Returns the first argument of 2 arguments. eg:

  $x = const(4, 5); # 4

In Haskell:

  const          :: a -> b -> a
  const k _       = k

=cut

sub const {
  my $x = shift;
  return $x;
}


=item flip f

Given a function, flips the two arguments it is passed.
Note that this returns a CODEREF, as currying does not yet
happen. eg: flip(sub { $_[0] ** $_[1] })->(2, 3) = 9.
In Haskell (ie this is what it should really do):

  flip           :: (a -> b -> c) -> b -> a -> c
  flip f x y      = f y x

=cut

sub flip {
  my $f = shift;
  return sub {
    $f->($_[1], $_[0]);
  }
}
# flip f x y -> f y x can't be done as
# this isn't yet lazy or curried!


=item Until p f x

Keep on applying f to x until p(x) is true, and
then return x at that point. eg:

  $x = Until { shift() % 10 == 0 } \&inc, 1; # 10

In Haskell:

  until          :: (a -> Bool) -> (a -> a) -> a -> a
  until p f x     = if p x then x else until p f (f x)

=cut

sub Until(&&$);
sub Until(&&$) {
  my($p, $f, $x) = @_;
  return $x if $p->($x);
  return Until(\&$p, \&$f, $f->($x));
}


=item fst x:xs

Returns the first element in a tuple. eg:

  $x = fst([1, 2]); # 1

In Haskell:

  fst            :: (a,b) -> a
  fst (x,_)       = x

=cut

sub fst($) {
  my $x = shift;
  return $x->[0];
}


=item snd x:y:xs

Returns the second element in a tuple. eg:

  $x = snd([1, 2]); # 2

In Haskell:

  snd            :: (a,b) -> a
  snd (_,y)       = y

=cut

sub snd($) {
  my $x = shift;
  return $x->[1];
}


=item head xs

Returns the head (first element) of a list. eg:

  $x = head([1..6]); # 1

In Haskell:

  head             :: [a] -> a
  head (x:_)        = x

=cut

sub head($) {
  my $xs = shift;
  return $xs->[0];
}


=item Last xs

Returns the last element of a list. Note the capital L, to make it
distinct from the Perl 'last' command. eg:

  $x = Last([1..6]); # 6

In Haskell:

  last             :: [a] -> a
  last [x]          = x
  last (_:xs)       = last xs

=cut

sub Last($) {
  my $xs = shift;
  return $xs->[-1];
}


=item tail xs

Returns a list minus the first element (head). eg:

  $x = tail([1..6]); # [2, 3, 4, 5, 6]

In Haskell:

  tail             :: [a] -> [a]
  tail (_:xs)       = xs

=cut

sub tail($) {
  my $xs = shift;
  my $len = scalar @{$xs};
  $len = $len == $INFINITE ? $len : $len - 1;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    return $xs->[$idx+1];
  }, $len;
  return \@a;
}


=item init xs

Returns a list minus its last element. eg:

  $x = init([1..6]); # [1, 2, 3, 4, 5]

In Haskell:

  init             :: [a] -> [a]
  init [x]          = []
  init (x:xs)       = x : init xs

=cut

sub init($) {
  my $xs = shift;
  pop(@{$xs});
  return $xs;
}


=item null xs

Returns whether or not the list is empty. eg: 

  $x = null([1, 2]); # False

In Haskell:

  null             :: [a] -> Bool
  null []           = True
  null (_:_)        = False

=cut

sub null($) {
  my $x = shift;
  return not @{$x};
}


=item Map f xs

Evaluates f for each element of the list xs and returns the list
composed of the results of each such evaluation. It is very similar to
the Perl command 'map', hence the capital M, but also copes with
infinite lists. eg:

  $x = Map { double(shift) } [1..6]; # [2, 4, 6, 8, 10, 12]

In Haskell:

  map              :: (a -> b) -> [a] -> [b]
  map f xs          = [ f x | x <- xs ]

=cut

sub Map(&$) {
  my($f, $xs) = @_;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    return $f->($xs->[$idx]);
  }, scalar @{$xs};
  return \@a;
}


=item filter p xs

Returns the list of the elements in xs for which
p(xs) returns true. It is similar to the Perl command
'grep', but it also copes with infinite lists. eg:

  $x = filter(\&even, [1..6]); # [2, 4, 6]

In Haskell:

  filter           :: (a -> Bool) -> [a] -> [a]
  filter p xs       = [ x | x <- xs, p x ]

=cut

# Ha! Before infinite lists simply consisted of:
#  return [grep { $f->($_) } @{$xs}];

sub filter(&$) {
  my($f, $xs) = @_;
  my $pointer = -1;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    my $debug = 0;
    print "$idx: in (done $pointer)\n" if $debug;
    if ($pointer eq $INFINITE) {
      die "Fetching an infinite amount of values in filter()!\n";
    }
    if ($idx - 1 > $pointer) {
      print "$idx: doing $array->FETCH for $pointer..", $idx - 1, "\n" if $debug;
      map { $array->FETCH($_) if $_ < $array->FETCHSIZE} ($pointer..$idx-1);
    }
    if ($idx > $array->FETCHSIZE) {
      print "$idx: in: silly, getting out\n" if $debug;
      return undef;
    }
    while (1) {
      $pointer++;
      print "$idx: loop: $idx (done $pointer/", $array->FETCHSIZE, ") = ", $f->($xs->[$pointer]), "\n" if $debug;
      if ($pointer >= $array->FETCHSIZE) {
	print "$idx: Size *was* ", $array->FETCHSIZE, "!\n" if $debug;
	$array->STORESIZE($idx);
	print "$idx: Set size to ", $array->FETCHSIZE, "!\n" if $debug;
	last;
      }
      if ($f->($xs->[$pointer])) {
	print "$idx: oooh (elt $pointer: '", $xs->[$pointer], "' was true)\n" if $debug;
	last;
      }
    }
    print "$idx: loop: out\n" if $debug;

    return $xs->[$pointer];
  }, scalar @{$xs};
  return \@a;
}


=item concat

Concatenates lists together into one list. eg:

  concat([[1..3], [4..6]]); # [1, 2, 3, 4, 5, 6]

In Haskell:

  concat           :: [[a]] -> [a]
  concat            = foldr (++) []

TODO: Make sure this works with infinite lists!

=cut

sub concat($) {
  my($xxs) = shift;
  return foldr(sub { [@{shift()}, @{shift()}]; }, [], $xxs);
}


=item Length

Returns the length of a list - only do this with
finite lists! eg:

  $x = Length([1..6]); # 6

In Haskell:

  length           :: [a] -> Int
  length            = foldl' (\n _ -> n + 1) 0

TODO Make sure this works!

=cut #'

sub Length($) {
  my $xs = shift;
  my $len = scalar @{$xs};
  confess "Fetching the length of an infinite list!"
    if $len == $INFINITE;
  return $len;
}


=item foldl f z xs

Applies function f to the pairs (z, xs[0]), (f(z, xs[0], xs[1]),
(f(f(z, xs[0], xs[1])), xs[2]) and so on. ie it folds from the left
and returns the last value.  Note that foldl should not be done to
infinite lists. eg: the following returns the sum of 1..6:

  $x = foldl { shift() + shift() } 0, [1..6]; # 21

In Haskell:

  foldl            :: (a -> b -> a) -> a -> [b] -> a
  foldl f z []      = z
  foldl f z (x:xs)  = foldl f (f z x) xs

=cut

sub foldl(&$$) {
  my($f, $z, $xs) = @_;
  map { $z = $f->($z, $_) } @{$xs};
  return $z;
}


=item foldl1 f xs

This is a variant of foldl where the first value of
xs is taken as z. Applies function f to the pairs (xs[0], xs[1]),
(f(xs[0], xs[1], xs[2]), (f(f(xs[0], xs[1], xs[2])), xs[3]) and
so on. ie it folds from the left and returns the last value.
Note that foldl should not be
done to infinite lists. eg: the following returns the sum
of 1..6:

  $x = foldl1 { shift() + shift() } [1..6]; # 21

In Haskell:

  foldl1           :: (a -> a -> a) -> [a] -> a
  foldl1 f (x:xs)   = foldl f x xs

=cut

sub foldl1(&$) {
  my($f, $xs) = @_;
  my $z = shift @{$xs};
  return foldl(\&$f, $z, $xs);
}


=item scanl f q xs

Returns a list of all the intermedia values that foldl would compute.
ie returns the list z, f(z, xs[0]), f(f(z, xs[0]), xs[1]), f(f(f(z,
xs[0]), xs[1]), xs[2]) and so on. eg:

  $x = scanl { shift() + shift() }, 0, [1..6]; # [0, 1, 3, 6, 10, 15, 21]

In Haskell:

  scanl        :: (a -> b -> a) -> a -> [b] -> [a]
  scanl f q xs  = q : (case xs of
                       []   -> []
                       x:xs -> scanl f (f q x) xs)

=cut

sub scanl(&$$) {
  my($f, $q, $xs) = @_;
# Ha! Before infinite lists simply consisted of the elegant:
#  my @return = $q;
#  map { $q = $f->($q, $_); push @return, $q } @{$xs};
#  return [@return];
  my $pointer = -1;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    my $debug = 0;
    print "$idx: in (done $pointer)\n" if $debug;
    if ($idx == 0) {
      print "$idx: zero, easy = $q!\n" if $debug;
      return $q;
    }
    if ($pointer eq $INFINITE) {
      die "Fetching an infinite amount of values in filter()!\n";
    }
    if ($idx - 1 > $pointer) {
      print "$idx: doing $array->FETCH for $pointer..", $idx - 1, "\n" if $debug;
      map { $array->FETCH($_) if $_ < $array->FETCHSIZE} ($pointer..$idx-1);
    }
    if ($idx > $array->FETCHSIZE) {
      print "$idx: in: silly, getting out\n" if $debug;
      return undef;
    }
    $pointer++;
    print "$idx: getting f(idx $idx-1, ", $xs->[$idx-1], "\n" if $debug;
    my $return = $f->($array->FETCH($idx-1), $xs->[$idx-1]);
    print "$idx: out with $return\n" if $debug;
    return $return;
  }, scalar @{$xs} + 1;
  return \@a;
}


=item scanl1 f xs

This is a variant of scanl where the first value of xs is taken as
q. Returns a list of all the intermedia values that foldl would
compute.  ie returns the list f(xs[0], xs[1]), f(f(xs[0], xs[1]),
xs[2]), f(f(f(xs[0], xs[1]), xs[2]), xs[3]) and so on. eg:

  $x = scanl1 { shift() + shift() } [1..6]; # [1, 3, 6, 10, 15, 21]

In Haskell:

  scanl1           :: (a -> a -> a) -> [a] -> [a]
  scanl1 f (x:xs)   = scanl f x xs

=cut

sub scanl1(&$) {
  my($f, $xs) = @_;
  my $z = shift @{$xs};
  return scanl(\&$f, $z, $xs);
}


=item foldr f z xs

This is similar to foldl but is folding from the right instead of the
left.  Note that foldr should not be done to infinite lists.  eg: the
following returns the sum of 1..6

  $x = foldr { shift() + shift() } 0, [1..6] ; # 21

In Haskell:

  foldr            :: (a -> b -> b) -> b -> [a] -> b
  foldr f z []      = z
  foldr f z (x:xs)  = f x (foldr f z xs)

=cut

sub foldr(&$$) {
  my($f, $z, $xs) = @_;
  map { $z = $f->($_, $z) } reverse @{$xs};
  return $z;
}


=item foldr1 f xs

This is similar to foldr1 but is folding from the right instead of the
left. Note that foldr1 should not be done on infinite lists. eg:

  $x = foldr1 { shift() + shift() } [1..6]; # 21

In Haskell:

  foldr1           :: (a -> a -> a) -> [a] -> a
  foldr1 f [x]      = x
  foldr1 f (x:xs)   = f x (foldr1 f xs)

=cut

sub foldr1(&$) {
  my($f, $xs) = @_;
  my $z = pop @{$xs};
  return foldr(\&$f, $z, $xs);
}


=item scanr f z xs

This is similar to scanl but is scanning and folding
from the right instead of the left. Note that scanr should
not be done on infinite lists. eg: 

  $x = scanr { shift() + shift() } 0, [1..6];
  # [0, 6, 11, 15, 18, 20, 21]

In Haskell:

  scanr            :: (a -> b -> b) -> b -> [a] -> [b]
  scanr f q0 []     = [q0]
  scanr f q0 (x:xs) = f x q : qs
                      where qs@(q:_) = scanr f q0 xs

=cut

sub scanr(&$$) {
  my($f, $z, $xs) = @_;
  my @return = $z;
  map { $z = $f->($_, $z); push @return, $z; } reverse @{$xs};
  return [@return];
}


=item scanr1 f xs

This is similar to scanl1 but is scanning and folding
from the right instead of the left. Note that scanr1 should
not be done on infinite lists. eg:

  $x = scanr1 { shift() + shift() } [1..6];
  # [6, 11, 15, 18, 20, 21]

In Haskell:

  scanr1           :: (a -> a -> a) -> [a] -> [a]
  scanr1 f [x]      = [x]
  scanr1 f (x:xs)   = f x q : qs
                      where qs@(q:_) = scanr1 f xs

=cut

sub scanr1(&$) {
  my($f, $xs) = @_;
  my $z = pop @{$xs};
  return scanr(\&$f, $z, $xs);
}


=item iterate f x

This returns the infinite list (x, f(x), f(f(x)), f(f(f(x)))...) and
so on. eg:

  $x = take(8, iterate { shift() * 2 } 1);
  # [1, 2, 4, 8, 16, 32, 64, 128]

In Haskell:

  iterate          :: (a -> a) -> a -> [a]
  iterate f x       = x : iterate f (f x)

=cut

sub iterate(&$) {
  my($f, $x) = @_;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    return $x if $idx == 0;
    return $f->($array->FETCH($idx-1));
  };
  return \@a;
}


=item repeat x

This returns the infinite list where all
elements are x. eg:

  $x = take(4, repeat(42)); # [42, 42, 42, 42].

In Haskell:

  repeat           :: a -> [a]
  repeat x          = xs where xs = x:xs

=cut

sub repeat($) {
  my $x = shift;
  tie my @a, 'InfiniteList', sub {
    return $x;
  };
  return \@a;
}


=item replicate n x

Returns a list containing n times the element x. eg:

  $x = replicate(5, 1); # [1, 1, 1, 1, 1]

In Haskell:

  replicate        :: Int -> a -> [a]
  replicate n x     = take n (repeat x)

=cut

sub replicate($$) {
  my($n, $x) = @_;
  return take($n, repeat($x));
}

# TODO
# cycle            :: [a] -> [a]
# cycle []          = error "Prelude.cycle: empty list"
# cycle xs          = xs' where xs'=xs++xs'


=item take n xs

Returns a list containing the first n elements from the list xs. eg:

  $x = take(2, [1..6]); # [1, 2]

In Haskell:

  take                :: Int -> [a] -> [a]
  take 0 _             = []
  take _ []            = []
  take n (x:xs) | n>0  = x : take (n-1) xs
  take _ _             = error "Prelude.take: negative argument"

=cut

sub take($$) {
  my($n, $xs) = @_;
  my @return;
  foreach my $i (0..$n-1) {
    push @return, $xs->[$i];
  }
  return \@return;
}


=item drop n xs

Returns a list containing xs with the first n elements missing. eg:

  $x = drop(2, [1..6]); # [3, 4, 5, 6]

In Haskell:

  drop                :: Int -> [a] -> [a]
  drop 0 xs            = xs
  drop _ []            = []
  drop n (_:xs) | n>0  = drop (n-1) xs
  drop _ _             = error "Prelude.drop: negative argument"

=cut

sub drop($$) {
  my($n, $xs) = @_;
# Ha! Before infinite lists simply consisted of:
#  return [splice @{$xs}, $n];
  my $len = scalar @{$xs};
  $len = $len == $INFINITE ? $len : $len - $n;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    return $xs->[$idx+$n];
  }, $len;
  return \@a;
}


=item splitAt n xs

Splits the list xs into two lists at element n. eg:

  $x = splitAt(2, [1..6]);# [[1, 2], [3, 4, 5, 6]]

In Haskell:

  splitAt               :: Int -> [a] -> ([a], [a])
  splitAt 0 xs           = ([],xs)
  splitAt _ []           = ([],[])
  splitAt n (x:xs) | n>0 = (x:xs',xs'') where (xs',xs'') = splitAt (n-1) xs
  splitAt _ _            = error "Prelude.splitAt: negative argument"

=cut

sub splitAt($$) {
  my($n, $xs) = @_;
  return [take($n, $xs), drop($n, $xs)];
}


=item takeWhile p xs

Takes elements from xs while p(that element) is
true. Returns the list. eg: 

  $x = takeWhile { shift() <= 4 } [1..6]; # [1, 2, 3, 4]

In Haskell:

  takeWhile           :: (a -> Bool) -> [a] -> [a]
  takeWhile p []       = []
  takeWhile p (x:xs)
           | p x       = x : takeWhile p xs
           | otherwise = []

=cut

sub takeWhile(&$) {
  my($p, $xs) = @_;
# Ha! Before infinite lists simply consisted of:
#  my @return;
#  push @return, $_ while($_ = shift @{$xs} and $p->($_));
#  return [@return];
  my $pointer = -1;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    my $debug = 0;
    print "$idx: in (done $pointer)\n" if $debug;
    if ($pointer eq $INFINITE) {
      die "Fetching an infinite amount of values in filter()!\n";
    }
    if ($idx - 1 > $pointer) {
      print "$idx: doing $array->FETCH for $pointer..", $idx - 1, "\n" if $debug;
      map { $array->FETCH($_) if $_ < $array->FETCHSIZE} ($pointer..$idx-1);
    }
    if ($idx > $array->FETCHSIZE) {
      print "$idx: in: silly, getting out\n" if $debug;
      return undef;
    }
    $pointer++;
    if ($p->($xs->[$pointer])) {
      print "$idx: p true for index $pointer\n" if $debug;
      return $xs->[$pointer];
    } else {
      print "$idx: p NOT true for index - resizing to $pointer\n" if $debug;
      $array->STORESIZE($pointer);
      return undef;
    }
  }, scalar @{$xs};
  return \@a;
}


=item dropWhile p xs

Drops elements from the head of xs while p(that element) is
true. Returns the list. eg:

  $x = dropWhile { shift() <= 4 } [1..6]; # [5, 6]

In Haskell:

  dropWhile           :: (a -> Bool) -> [a] -> [a]
  dropWhile p []       = []
  dropWhile p xs@(x:xs')
           | p x       = dropWhile p xs'
           | otherwise = xs

=cut

sub dropWhile(&$) {
  my($p, $xs) = @_;
# Ha! Before infinite lists simply consisted of:
#  shift @{$xs} while($_ = @{$xs}[0] and $p->($_));
  my $pointer = 0;
  while (1) {
    last unless $p->($xs->[$pointer]);
    $pointer++;
  }
  print "Pointer = $pointer\n" if 0;
  my $len = scalar @{$xs};
  $len = $len == $INFINITE ? $len : $len - $pointer;
  tie my @a, 'InfiniteList', sub {
    my($array, $idx) = @_;
    return $xs->[$idx + $pointer];
  }, $len;
  return \@a;
}


=item span p xs

Splits xs into two lists, the first containing the first few elements
for which p(that element) is true. eg:

  $x = span { shift() <= 4 }, [1..6];
  # [[1, 2, 3, 4], [5, 6]]

In Haskell:

  span                :: (a -> Bool) -> [a] -> ([a],[a])
  span p []            = ([],[])
  span p xs@(x:xs')
           | p x       = (x:ys, zs)
           | otherwise = ([],xs)
                         where (ys,zs) = span p xs'

=cut

sub span(&$) {
  my($p, $xs) = @_;
  my @xs = @{$xs};
  return [takeWhile(\&$p, $xs), dropWhile(\&$p, \@xs)];
}


=item break p xs

Splits xs into two lists, the first containing the first few elements
for which p(that element) is false. eg:

  $x = break { shift() >= 4 }, [1..6]; # [[1, 2, 3], [4, 5, 6]]

In Haskell:

  break         :: (a -> Bool) -> [a] -> ([a],[a])
  break p        = span (not . p)

=cut

sub break(&$) {
  my($p, $xs) = @_;
  return span(sub { not $p->(@_) }, $xs);
}


=item lines s

Breaks the string s into multiple strings, split at line
boundaries. eg:

  $x = lines("A\nB\nC"); # ['A', 'B', 'C']

In Haskell:

  lines     :: String -> [String]
  lines ""   = []
  lines s    = let (l,s') = break ('\n'==) s
               in l : case s' of []      -> []
                                 (_:s'') -> lines s''

=cut

sub lines($) {
  my $s = shift;
  return [split /\n/, $s];
}


=item words s

Breaks the string s into multiple strings, split at whitespace
boundaries. eg:

  $x = words("hey how random"); # ['hey', 'how', 'random']

In Haskell:

  words     :: String -> [String]
  words s    = case dropWhile isSpace s of
                    "" -> []
                    s' -> w : words s''
                          where (w,s'') = break isSpace s'

=cut

sub words($) {
  my $s = shift;
  return [split /\s+/, $s];
}


=item unlines xs

Does the opposite of unlines, that is: joins multiple
strings into one, joined by newlines. eg:

  $x = unlines(['A', 'B', 'C']); # "A\nB\nC";

In Haskell:

  unlines   :: [String] -> String
  unlines    = concatMap (\l -> l ++ "\n")

(note that strings in Perl are not lists of characters,
so this approach will not actually work...)

=cut

sub unlines($) {
  my $xs = shift;
#  return concatMap(sub { return $_[0] . "\n"; }, $xs);
  return foldr1(sub { return $_[0] . "\n" . $_[1]; }, $xs);
}


=item unwords ws

Does the opposite of unwords, that is: joins multiple strings into
one, joined by a space. eg:

  $x = unwords(["hey","how","random"]); # 'hey how random'

In Haskell:

  unwords   :: [String] -> String
  unwords [] = []
  unwords ws = foldr1 (\w s -> w ++ ' ':s) ws

=cut

sub unwords($) {
  my $xs = shift;
  return foldr1(sub { return $_[0] . ' ' . $_[1]; }, $xs);
}


=item Reverse xs

Returns a list containing the elements of xs in reverse order. Note
the capital R, so as not to clash with the Perl command 'reverse'.
You should not try to Reverse an infinite list.  eg:

  $x = Reverse([1..6]); # [6, 5, 4, 3, 2, 1]

In Haskell:

  reverse   :: [a] -> [a]
  reverse    = foldl (flip (:)) []

=cut

sub Reverse($) {
  my $xs = shift;
  return [reverse @{$xs}];
}


=item And xs

Returns true if all the elements in xs are true. Returns false
otherwise. Note the capital A, so as not to clash with the Perl
command 'and'. You should not try to And an infinite list (unless you
expect it to fail, as it will short-circuit).  eg:

  $x = And([1, 1, 1]); # 1

In Haskell:

  and       :: [Bool] -> Bool
  and        = foldr (&&) True

=cut

sub And($) {
  my $xs = shift;
  map {
    return 0 if not $_;
  } @{$xs};
  return 1;
}


=item Or xs

Returns true if one of the elements in xs is true. Returns
false otherwise. Note the capital O, so as not to clash with
the Perl command 'or'. You may try to Or an infinite list
as it will short-circuit (unless you expect it to fail, that
is). eg:

  $x = Or([0, 0, 1]); # 1

In Haskell:

  or        :: [Bool] -> Bool
  or         = foldr (||) False

=cut

sub Or($) {
  my $xs = shift;
  map {
    return 1 if $_;
  } @{$xs};
  return 0;
}


=item any p xs

Returns true if one of p(each element of xs) are true. Returns
false otherwise. You should not try to And an infinite
list (unless you expect it to fail, as it will short-circuit).  
eg:

  $x = any { even(shift) } [1, 2, 3]; # 1

In Haskell:

  any       :: (a -> Bool) -> [a] -> Bool
  any p      = or  . map p

=cut

sub any(&$) {
  my($p, $xs) = @_;
  my $n = 0;
  my $size = $#{$xs};
  while ($n <= $size) {
    return 1 if $p->($xs->[$n]);
    $n++;
  }
  if ($size == $Language::Functional::INFINITE
      or $size == $Language::Functional::INFINITE - 1
  ) {
    confess "Evaluating predicate on inifinite number of elements " .
      "would never end!";
  }
  return 0;
}


=item all p xs

Returns true if all of the p(each element of xs) is true. Returns
false otherwise. You may try to Or an infinite list
as it will short-circuit (unless you expect it to fail, that
is). eg:

  $x = all { odd(shift) } [1, 1, 3]; # 1

In Haskell:

  all  :: (a -> Bool) -> [a] -> Bool
  all p      = and . map p

=cut

sub all(&$) {
  my($p, $xs) = @_;
  my $n = 0;
  my $size = $#{$xs};
  while ($n <= $size) {
    return 0 if not $p->($xs->[$n]);
    $n++;
  }
  if ($size == $Language::Functional::INFINITE
      or $size == $Language::Functional::INFINITE - 1
  ) {
    confess "Evaluating predicate on inifinite number of elements " .
      "would never end!";
  }
  return 1;
}


=item elem x xs

Returns true is x is present in xs.
You probably should not do this with infinite lists. 
Note that this assumes x and xs are numbers. 
eg:

  $x = elem(2, [1, 2, 3]); # 1

In Haskell:

  elem             :: Eq a => a -> [a] -> Bool
  elem              = any . (==)

=cut

sub elem($$) {
  my($x, $xs) = @_;
  return any(sub { $_[0] == $x }, $xs);
}


=item notElem x xs

Returns true if x is not present in x. You should not do this with
infinite lists. Note that this assumes that x and xs are numbers. eg:

  $x = notElem(2, [1, 1, 3]); # 1

In Haskell:

  notElem          :: Eq a => a -> [a] -> Bool
  notElem           = all . (/=)

=cut

sub notElem($$) {
  my($x, $xs) = @_;
  return all { shift() != $x } $xs;
}


=item lookup key xys

This returns the value of the key in xys, where xys is a list of key,
value pairs. It returns undef if the key was not found. You should not
do this with infinite lists. Note that this assumes that the keys are
strings. eg:

  $x = lookup(3, [1..6]); # 4

In Haskell:

  lookup           :: Eq a => a -> [(a,b)] -> Maybe b
  lookup k []       = Nothing
  lookup k ((x,y):xys)
        | k==x      = Just y
        | otherwise = lookup k xys

TODO: Make sure this works with infinite lists

=cut

sub lookup($$) {
  my($key, $xys) = @_;
  my %hash = @{$xys};
  return $hash{$key} if defined $hash{$key};
  return undef;
}


=item minimum xs

Returns the minimum value in xs. 
You should not do this with a infinite list.
eg:

  $x = minimum([1..6]); # 1

In Haskell:

  minimum          :: Ord a => [a] -> a
  minimum           = foldl1 min

=cut

sub minimum($) {
  my $xs = shift;
  return foldl1(\&min, $xs);
}


=item maximum xs

Returns the maximum value in xs. 
You should not do this with an infinite list.
eg: maximum([1..6]) = 6. In Haskell:

    maximum          :: Ord a => [a] -> a
    maximum           = foldl1 max

=cut

sub maximum($) {
  my $xs = shift;
  return foldl1(\&max, $xs);
}


=item sum xs

Returns the sum of the elements of xs.
You should not do this with an infinite list.
eg: sum([1..6]) = 21. In Haskell:

    sum          :: Num a => [a] -> a
    sum           = foldl' (+) 0

=cut #'

sub sum($) {
  my $xs = shift;
  return foldl(sub { $_[0] + $_[1] }, 0, $xs);
}


=item product xs

Returns the products of the elements of xs.
You should not do this with an infinite list.
eg: product([1..6]) = 720. In Haskell:

    product      :: Num a => [a] -> a
    product       = foldl' (*) 1

=cut #'

sub product($) {
  my $xs = shift;
  return foldl(sub { $_[0] * $_[1] }, 1,$xs);
}


=item zip as bs

Zips together two lists into one list. Should
not be done with infinite lists. 
eg: zip([1..6], [7..12]) = [1, 7, 2, 8, 3, 9, 4, 10, 5, 11, 6, 12].
In Haskell:

    zip              :: [a] -> [b] -> [(a,b)]
    zip               = zipWith  (\a b -> (a,b))

    zipWith                  :: (a->b->c) -> [a]->[b]->[c]
    zipWith z (a:as) (b:bs)   = z a b : zipWith z as bs
    zipWith _ _      _        = []

=cut

sub zip($$) {
  my($as, $bs) = @_;
  my @result;
  foreach (1..max(Length($as), Length($bs))) {
    push @result, shift @{$as};
    push @result, shift @{$bs};
  }
  return [@result];
}


=item zip3 as bs cs

Zips together three lists into one. Should not be
done with infinite lists. 
eg: zip3([1..2], [3..4], [5..6]) = [1, 3, 5, 2, 4, 6].
In Haskell:

    zip3             :: [a] -> [b] -> [c] -> [(a,b,c)]
    zip3              = zipWith3 (\a b c -> (a,b,c))

    zipWith3                 :: (a->b->c->d) -> [a]->[b]->[c]->[d]
    zipWith3 z (a:as) (b:bs) (c:cs)
                              = z a b c : zipWith3 z as bs cs
    zipWith3 _ _ _ _          = []

=cut

sub zip3($$$) {
  my($as, $bs, $cs) = @_;
  my @result;
  foreach (1..maximum([Length($as), Length($bs), Length($cs)])) {
    push @result, shift @{$as};
    push @result, shift @{$bs};
    push @result, shift @{$cs};
  }
  return [@result];
}


=item unzip abs

Unzips one list into two. Should not be done with infinite lists.
eg: unzip([1,7,2,8,3,9,4,10,5,11,6,12]) = ([1, 2, 3, 4, 5, 6], [7, 8, 9, 10, 11, 12]).

    unzip    :: [(a,b)] -> ([a],[b])
    unzip     = foldr (\(a,b) ~(as,bs) -> (a:as, b:bs)) ([], [])

=cut

sub unzip($) {
  my $abs = shift;
  my(@as, @bs);
  while (@{$abs}) {
    push @as, shift @{$abs};
    push @bs, shift @{$abs};
  }
  return [@as], [@bs];
}


=item unzip abcs

Unzips one list into three. Should not be done with infinite lists.
eg: unzip3([1,3,5,2,4,6]) = ([1, 2], [3, 4], [5, 6]).
In Haskell:

    unzip3   :: [(a,b,c)] -> ([a],[b],[c])
    unzip3    = foldr (\(a,b,c) ~(as,bs,cs) -> (a:as,b:bs,c:cs))
		      ([],[],[])

=cut

sub unzip3($) {
  my $abcs = shift;
  my(@as, @bs, @cs);
  while (@{$abcs}) {
    push @as, shift @{$abcs};
    push @bs, shift @{$abcs};
    push @cs, shift @{$abcs};
  }
  return [@as], [@bs], [@cs];
}


=item integers

A useful function that returns an infinite list containing
all the integers. eg: integers = (1, 2, 3, 4, 5, ...).

=cut

sub integers() {
  return iterate { shift() +1 } 1;
}


=item factors x

A useful function that returns the factors of x.
eg: factors(100) = [1, 2, 4, 5, 10, 20, 25, 50, 100].
In Haskell:

    factors x = [n | n <- [1..x], x `mod` n == 0]

=cut

sub factors($) {
  my $x = shift;
  return [grep { $x % $_ == 0 } (1..$x)];
}


=item prime x

A useful function that returns, rather unefficiently,
if x is a prime number or not. It is rather useful while
used as a filter,
eg: take(10, filter("prime", integers)) = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29].
In Haskell:

    primes = [n | n <- [2..], length (factors n) == 2]

=cut

sub prime($) {
  my $x = shift;
  return Length(factors($x)) == 2;
}

=back

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 1999-2008, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut




package InfiniteList;
use strict;
use Carp;
use Tie::Array;
use vars qw(@ISA);
@ISA = ('Tie::Array');

sub TIEARRAY {
  my $class = shift;
  my $closure = shift;
  my $size = shift || $Language::Functional::INFINITE;
  confess "usage: tie(\@ary, 'InfiniteList', &closure)"
    if @_ || ref($closure) ne 'CODE';
  return bless {
		CLOSURE => $closure,
		ARRAY => [],
		SIZE => $size,
	       }, $class;
}

sub FETCH {
  my($self,$idx) = @_;
  my $debug = 0;
  print ":fetch $idx... " if $debug;
  if ($idx == $Language::Functional::INFINITE or $idx == $Language::Functional::INFINITE-1) {
    confess "Fetching an infinite amount of values!";
  }
  if (not defined $self->{ARRAY}[$idx]) {
    print "MISS\n" if $debug;
    $self->{ARRAY}[$idx] = $self->{CLOSURE}->($self, $idx);
  } else {
    print "HIT\n" if $debug;
  }
  print ":so    $idx = ", $self->{ARRAY}[$idx], "\n" if $debug;
  return $self->{ARRAY}[$idx];
}

sub FETCHSIZE {
  my $self = shift;
  return $self->{SIZE};
}

sub STORE {
  my $self = shift;
  confess "Storing, this should never happen to an infinite list!";
}

sub STORESIZE {
  my($self, $size) = @_;
  $self->{SIZE} = $size;
}
  
