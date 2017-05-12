
=head1 Terms

Symbolic Algebra in Pure Perl: terms.

A term represents a product of: variables, coefficents, divisors,
square roots, exponentials, and logs.

PhilipRBrenan@yahoo.com, 2004, Perl License.
PhilipRBrenan@gmail.com, 2016, Perl License. www.appaapps.com

=cut


package Math::Algebra::Symbols::Term;
use strict;
our $VERSION=1.27;
use Carp;
use Math::BigInt;
#HashUtil use Hash::Util qw(lock_hash);
use Scalar::Util qw(weaken);


=head2 Constructors


=head3 new

Constructor

=cut


sub new
 {bless {c=>1, d=>1, i=>0, v=>{}, sqrt=>undef, divide=>undef, exp=>undef, log=>undef};
 }


=head3 Finalization

Sign and lock terms

=cut

my $lock = 0;   # Hash locking
my $z = 0;      # Term counter
my %z;          # Terms finalized


=head3 constants

Useful constants

=cut


my $zero  = new()->c(0)->z;           sub zero () {$zero}
my $one   = new()->z;                 sub one  () {$one}
my $two   = new()->c(2)->z;           sub two  () {$two}
my $mOne  = new()->c(-1)->z;          sub mOne () {$mOne}
my $i     = new()->i(1)->z;           #sub pI   () {$pI}
my $mI    = new()->c(-1)->i(1)->z;    sub mI   () {$mI}
my $half  = new()->c( 1)->d(2)->z;    sub half () {$half}
my $mHalf = new()->c(-1)->d(2)->z;    sub mHalf() {$mHalf}
my $pi    = new()->vp('pi', 1)->z;    sub pi   () {$pi}


=head3 newFromString

New from String

=cut


sub newFromString($)
 {my ($a) = @_;
  return $zero unless $a;
  my $A = $a;

  for(;$A =~ /(\d+)\.(\d+)/;)
   {my $i = $1;
    my $j = $2;
    my $l = '0' x length($j);
#   carp "Replacing $i.$j with $i$j\/1$l in $A";
    $A =~ s/$i\.$j/$i$j\/1$l/;
   }

  if  ($A  =~ /^\s*([+-])?(\d+)?(?:\/(\d+))?(i)?(?:\*)?(.*)$/)
   {my $c  =  '';
       $c  =  '-'.$c if $1 and $1 eq '-';
       $c .=  $2     if $2;
       $c  = '1'     if $c eq '';
       $c  = '-1'    if $c eq '-';
    my $d  =  '';
       $d  =  $3     if $3;
       $d  =   1     if $d eq '';
    my $i  =   0;
       $i  =   1     if $4;

    my $z = new()->c($c)->d($d)->i($i);

    my $b = $5;
    for (;$b =~ /^(\pL+)(?:\*\*)?(\d+)?(?:\*)?(.*)$/i;)                         # 2016/01/20 21:02:35 unicode support
     {$b = $3;
      $z->{v}{$1} = $2 if     defined($2);
      $z->{v}{$1} = 1  unless defined($2);
     }

    croak "Cannot parse: $a" if $A eq $b;
    croak "Cannot parse: $b in $a" if $b;
    return $z->z;
   }
  croak "Unable to parse $a";
 }


=head3 n

Short name for L</newFromString>

=cut


sub n($)
 {newFromString($_[0]);
 }


=head3 newFromStrings

New from Strings

=cut


sub newFromStrings(@)
 {return $zero->clone() unless scalar(@_);
  map {newFromString($_)} @_;
 }


=head3 gcd

Greatest Common Divisor.

=cut


sub gcd($$)
 {my $x = abs($_[0]);
  my $y = abs($_[1]);

  return 1 if $x == 1 or $y == 1;

  my ($a, $b) = ($x, $y); $a = $y, $b = $x if $y < $a;

  for(my $r;;)
   {$r = $b % $a;
    return $a if $r == 0;
    ($a, $b) = ($r, $a);
   }
 }


=head3 lcm

Least common multiple.

=cut


sub lcm($$)
 {my $x = abs($_[0]);
  my $y = abs($_[1]);
  return $x*$y if $x == 1 or $y == 1;
  $x*$y / gcd($x, $y);
 }


=head3 isTerm

Confirm type

=cut


sub isTerm($) {1};


=head3 intCheck

Integer check

=cut


sub intCheck($$)
 {my ($i, $m) = @_;
  return $i if $i == 1;
  $i =~ /^[\+\-]?\d+/ or die "Integer required for $m not $i";
  return Math::BigInt->new($i) if $i > 10_000_000;
  $i;
 }


=head3 c

Coefficient

=cut


sub c($;$)
 {my ($t) = @_;
  return $t->{c} unless @_ > 1;

  $t->{c} = ($_[1] == 1 ? $_[1] : intCheck($_[1], 'c'));
  $t;
 }


=head3 d

Divisor

=cut


sub d($;$)
 {my ($t) = @_;
  return $t->{d} unless @_ > 1;

  $t->{d} = ($_[1] == 1 ? $_[1] : intCheck($_[1], 'd'));
  $t;
 }


=head3 timesInt

Multiply term by integer

=cut


sub timesInt($$)
 {my ($t) = @_;
  my $m = ($_[1] ? $_[1] : intCheck($_[1], 'times'));

  $t->{c} *= $m;
  if ($t->{d} > 1)
   {my $g = gcd($t->{c}, $t->{d});
    if ($g > 1)
     {$t->{d} /= $g;
      $t->{c} /= $g;
     }
   }
  $t;
 }


=head3 divideInt

Divide term by integer

=cut


sub divideInt($$)
 {my ($t) = @_;
  my $d = ($_[1] == 1 ? $_[1] : intCheck($_[1], 'divide'));
  $d != 0  or die "Cannot divide by zero";

  $t->{d} *= abs($d);
  my $g = gcd($t->{d}, $t->{c});
  if ($g > 1)
   {$t->{d} /= $g;
    $t->{c} /= $g;
   }

  $t->{c} = - $t->{c} if $d < 0;
  $t;
 }


=head3 negate

Negate term

=cut


sub negate($)
 {my ($t) = @_;
  $t->{c} = -$t->{c};
  $t;
 }


=head3 isZero

Zero?

=cut


sub isZero($)
 {my ($t) = @_;
  exists $t->{z} or die "Testing unfinalized term";
  $t->{id} == $zero->{id};
 }


=head3 notZero

Not Zero?

=cut


sub notZero($) {return !isZero($_[0])}


=head3 isOne

One?

=cut


sub isOne($)
 {my ($t) = @_;
  exists $t->{z} or die "Testing unfinalized term";
  $t->{id} == $one->{id};
 }


=head3 notOne

Not One?

=cut


sub notOne($) {return !isOne($_[0])}


=head3 isMinusOne

Minus One?

=cut


sub isMinusOne($)
 {my ($t) = @_;
  exists $t->{z} or die "Testing unfinalized term";
  $t->{id} == $mOne->{id};
 }


=head3 notMinusOne

Not Minus One?

=cut


sub notMinusOne($) {return !isMinusOne($_[0])}


=head3 i

Get/Set i - sqrt(-1)

=cut


sub i($;$)
 {my ($t) = @_;

  return $t->{i} unless(@_) > 1;

  my $i = ($_[1] == 1 ? $_[1] : intCheck($_[1], 'i'));

  my $i4  = $i % 4;
  $t->{i} = $i % 2;
  $t->{c} = -$t->{c} if $i4 == 2 or $i4 == 3;
  $t;
 }


=head3 iby

i by power: multiply a term by a power of i

=cut


sub iby($$)
 {my ($t, $p) = @_;

  $t->i($p+$t->{i});
  $t;
 }


=head3 Divide

Get/Set divide by.

=cut


sub Divide($;$)
 {my ($t, $d) = @_;
  return $t->{divide} unless @_ > 1;
  $t->{divide} = $d;
  $t;
 }


=head3 removeDivide

Remove divide

=cut


sub removeDivide($)
 {my ($t) = @_;
  my $z = $t->clone;
  delete $z->{divide};
  $z->z;
 }


=head3 Sqrt

Get/Set square root.

=cut


sub Sqrt($;$)
 {my ($t, $s) = @_;
  return $t->{sqrt} unless @_ > 1;
  $t->{sqrt} = $s;
  $t;
 }


=head3 removeSqrt

Remove square root.

=cut


sub removeSqrt($)
 {my ($t) = @_;
  my $z = $t->clone;
  delete $z->{sqrt};
  $z->z;
 }


=head3 Exp

Get/Set exp

=cut


sub Exp($;$)
 {my ($t, $e) = @_;
  return $t->{exp} unless @_ > 1;
  $t->{exp} = $e;
  $t;
 }


=head3 Log

# Get/Set log

=cut


sub Log($$)
 {my ($t, $l) = @_;
  return $t->{log} unless @_ > 1;
  $t->{log} = $l;
  $t;
 }


=head3 vp

Get/Set variable power.

On get: returns the power of a variable, or zero if the variable is not
present in the term.

On set: Sets the power of a variable. If the power is zero, removes the
variable from the term. =cut

=cut


sub vp($$;$)
 {my ($t, $v) = @_;
# $v =~ /^[a-z]+$/i or die "Bad variable name $v";

  return exists($t->{v}{$v}) ? $t->{v}{$v} : 0 if @_ == 2;

  my $p = ($_[2] == 1 ? $_[2] : intCheck($_[2], 'vp'));
  $t->{v}{$v} = $p   if $p;
  delete $t->{v}{$v} unless $p;
  $t;
 }


=head3 v

Get all variables mentioned in the term.  Variables to power zero
should have been removed by L</vp>.

=cut


sub v($)
 {my ($t) = @_;
  return keys %{$t->{v}};
 }


=head3 clone

Clone a term. The existing term must be finalized, see L</z>: the new
term will not be finalized, allowing modifications to be made to it.

=cut


sub clone($)
 {my ($t) = @_;
  $t->{z} or die "Attempt to clone unfinalized  term";
  my $c   = bless {%$t};
  $c->{v} = {%{$t->{v}}};
  delete @$c{qw(id s z)};
  $c;
 }


=head3 split

Split a term into its components

=cut


sub split($)
 {my ($t) = @_;
  my $c = $t->clone;
  my @c = @$c{qw(sqrt divide exp log)};
          @$c{qw(sqrt divide exp log)} = ((undef()) x 4);
 (t=>$c, s=>$c[0], d=>$c[1], e=>$c[2], l=>$c[3]);
 }


=head3 signature

Sign the term. Used to optimize addition.
Fix the problem of adding different logs

=cut


sub signature($)
 {my ($t) = @_;
  my $s = '';
  $s .= sprintf("%010d", $t->{v}{$_}) . $_ for sort keys %{$t->{v}};
  $s .= '(divide'. $t->{divide} .')' if defined($t->{divide});
  $s .= '(sqrt'.   $t->{sqrt}   .')' if defined($t->{sqrt});
  $s .= '(exp'.    $t->{exp}    .')' if defined($t->{exp});
  $s .= '(log'.    $t->{log}    .')' if defined($t->{log});
  $s .= 'i' if $t->{i} == 1;
  $s  = '1' if $s eq '';
  $s;
 }


=head3 getSignature

Get the signature of a term

=cut


sub getSignature($)
 {my ($t) = @_;
  exists $t->{z} ? $t->{z} : die "Attempt to get signature of unfinalized term";
 }


=head3 add

Add two finalized terms, return result in new term or undef.

=cut


sub add($$)
 {my ($a, $b) = @_;

  $a->{z} and $b->{z} or
    die "Attempt to add unfinalized terms";

  return undef unless $a->{z} eq $b->{z};
  return $a->clone->timesInt(2)->z if $a == $b;

  my $z = $a->clone;
  my $c = $a->{c} * $b->{d}
        + $b->{c} * $a->{d};
  my $d = $a->{d} * $b->{d};
  return $zero if $c == 0;

  $z->c($c)->d(1)->divideInt($d)->z;
 }


=head3 subtract

Subtract two finalized terms, return result in new term or undef.

=cut


sub subtract($$)
 {my ($a, $b) = @_;

  $a->{z} and $b->{z} or
    die "Attempt to subtract unfinalized terms";

  return $zero                if $a == $b;
  return $a                   if $b == $zero;
  return $b->clone->negate->z if $a == $zero;
  return undef unless $a->{z} eq $b->{z};

  my $z = $a->clone;
  my $c = $a->{c} * $b->{d}
        - $b->{c} * $a->{d};
  my $d = $a->{d} * $b->{d};

  $z->c($c)->d(1)->divideInt($d)->z;
 }


=head3 multiply

Multiply two finalized terms, return the result in a new term or undef

=cut


sub multiply($$)
 {my ($a, $b) = @_;

  $a->{z} and $b->{z} or
    die "Attempt to multiply unfinalized terms";

# Check
  return undef if
   (defined($a->{divide}) and defined($b->{divide})) or
   (defined($a->{sqrt}  ) and defined($b->{sqrt}))   or
   (defined($a->{exp}   ) and defined($b->{exp}))    or
   (defined($a->{log}   ) and defined($b->{log}));

# cdi
  my $c = $a->{c} * $b->{c};
  my $d = $a->{d} * $b->{d};
  my $i = $a->{i} + $b->{i};
     $c = -$c, $i = 0 if $i == 2;
  my $z = $a->clone->c($c)->d(1)->divideInt($d)->i($i);

# v
# for my $v($b->v)
#  {$z->vp($v, $z->vp($v)+$b->vp($v));
#  }

  for my $v(keys(%{$b->{v}}))
   {$z->vp($v, (exists($z->{v}{$v}) ? $z->{v}{$v} : 0)+$b->{v}{$v});
   }

# Divide, sqrt, exp, log
  $z->{divide} = $b->{divide} unless defined($a->{divide});
  $z->{sqrt}   = $b->{sqrt}   unless defined($a->{sqrt});
  $z->{exp}    = $b->{exp}    unless defined($a->{exp});
  $z->{log}    = $b->{log}    unless defined($a->{log});

# Result
  $z->z;
 }


=head3 divide2

Divide two finalized terms, return the result in a new term or undef

=cut


sub divide2($$)
 {my ($a, $b) = @_;

  $a->{z} and $b->{z} or
    die "Attempt to divide unfinalized terms";

# Check
  return undef if
   (defined($b->{divide}) and (!defined($a->{divide}) or $a->{divide}->id != $b->{divide}->id));
  return undef if
   (defined($b->{sqrt}  ) and (!defined($a->{sqrt}  ) or $a->{sqrt}  ->id != $b->{sqrt}  ->id));
  return undef if
   (defined($b->{exp}   ) and (!defined($a->{exp}   ) or $a->{exp}   ->id != $b->{exp}   ->id));
  return undef if
   (defined($b->{log}   ) and (!defined($a->{log}   ) or $a->{log}   ->id != $b->{log}   ->id));

# cdi
  my $c = $a->{c} * $b->{d};
  my $d = $a->{d} * $b->{c};
  my $i = $a->{i} - $b->{i};
     $c = -$c, $i = 1 if $i == -1;
  my $g = gcd($c, $d);
  $c /= $g;
  $d /= $g;
  my $z = $a->clone->c($c)->d(1)->divideInt($d)->i($i);

# v
  for my $v($b->v)
   {$z->vp($v, $z->vp($v)-$b->vp($v));
   }

# Sqrt, divide, exp, log
  delete $z->{divide} if defined($a->{divide}) and defined($b->{divide});
  delete $z->{sqrt  } if defined($a->{sqrt  }) and defined($b->{sqrt  });
  delete $z->{exp   } if defined($a->{exp   }) and defined($b->{exp   });
  delete $z->{log   } if defined($a->{log   }) and defined($b->{log   });


# Result
  $z->z;
 }


=head3 invert

Invert a term

=cut


sub invert($)
 {my ($t) = @_;

  $t->{z} or die "Attempt to invert unfinalized term";

# Check
  return undef if
    $t->{divide} or
    $t->{sqrt}   or
    $t->{exp}    or
    $t->{log};

# cdi
  my ($c, $d, $i) = ($t->{c}, $t->{d}, $t->{i});
  $c = -$c if $i;
  my $z = clone($t)->c($d)->d(1)->divideInt($c)->i($i);

# v
  for my $v($z->v)
   {$z->vp($v, $z->vp($v));
   }

# Result
  $z->z;
 }


=head3 power

Take power of term

=cut


sub power($$)
 {my ($a, $b) = @_;

  $a->{z} and $b->{z} or die "Attempt to take power of unfinalized term";

# Check
  return $one if $a == $one or $b == $zero;
  return undef if
    $a->{divide} or
    $a->{sqrt}   or
    $a->{exp}    or
    $a->{log};

  return undef if
    $b->{d} != 1 or
    $b->{i} == 1 or
    $b->{divide} or
    $b->{sqrt}   or
    $b->{exp}    or
    $b->{log};

# cdi
  my ($c, $d, $i) = ($a->{c}, $a->{d}, $a->{i});

  my  $p = $b->{c};
  if ($p < 0)
   {$a = invert($a);
    return undef unless $a;
    $p = -$p;
    return $a if $p == 1;
   }

  my $z = $a->clone->z;
  $z = $z->multiply($a) for (2..$p);

  $i *= $p;
  $z = $z->clone->i($i);

# v
# for my $v($z->v)
#  {$z->vp($v, $p*$z->vp($v));
#  }

# Result
  $z->z;
 }


=head3 sqrt2

Square root of a term

=cut

# Return a square root guaranteed to be precise, or undef
# With thanks to: salvatore.bonaccorso@gmail.com

sub _safe_sqrt
 {my ($a) = @_;
  return undef if $a >= 65536 || $a < 0;
  my $s = int(sqrt($a)*256)/256; # $s now has at most 8+8 bits
  return undef if $s*$s != $a;
  return $s;
 }

sub sqrt2($)
 {my ($t) = @_;

  $t->{z} or die "Attempt to sqrt unfinalized term";

# Check
  return undef if   $t->{i}      or
                    $t->{divide} or
                    $t->{sqrt}   or
                    $t->{exp}    or
                    $t->{log};

# cd
  my ($c, $d, $i) = ($t->{c}, $t->{d}, 0);
  $c = -$c, $i = 1 if $c < 0;

#  my $c2 = sqrt($c);  return undef unless $c2*$c2 == $c;
#  my $d2 = sqrt($d);  return undef unless $d2*$d2 == $d;
  my $c2 = _safe_sqrt($c); return undef if !defined $c2;
  my $d2 = _safe_sqrt($d); return undef if !defined $d2;

  my $z = clone($t)->c($c2)->d($d2)->i($i);

# v
  for my $v($t->v)
   {my $p = $z->vp($v);
    return undef unless $p % 2 == 0;
    $z->vp($v, $p/2);
   }

# Result
  $z->z;
 }


=head3 exp2

Exponential of a term

=cut


sub exp2($)
 {my ($t) = @_;

  $t->{z} or die "Attempt to use unfinalized term in exp";

  return $one  if     $t == $zero;
  return undef if     $t->{divide} or
                      $t->{sqrt}   or
                      $t->{exp}    or
                      $t->{log};
  return undef unless $t->{i} == 1;
  return undef unless $t->{d} == 1 or
                      $t->{d} == 2 or
                      $t->{d} == 4;
  return undef unless scalar(keys(%{$t->{v}})) == 1 and
                      exists($t->{v}{pi})           and
                             $t->{v}{pi}       == 1;

  my $c = $t->{c};
  my $d = $t->{d};
  $c *= 2 if $d == 1;
  $c %= 4;

  return $one  if $c == 0;
  return $i    if $c == 1;
  return $mOne if $c == 2;
  return $mI   if $c == 3;
 }


=head3 sin2

Sine of a term

=cut


sub sin2($)
 {my ($t) = @_;

  $t->{z} or die "Attempt to use unfinalized term in sin";

  return $zero if   $t == $zero;
  return undef if   $t->{divide} or
                    $t->{sqrt}   or
                    $t->{exp}    or
                    $t->{log};
  return undef unless $t->{i} == 0;
  return undef unless scalar(keys(%{$t->{v}})) == 1;
  return undef unless exists($t->{v}{pi});
  return undef unless $t->{v}{pi} == 1;

  my $c = $t->{c};
  my $d = $t->{d};
  return undef unless $d== 1 or $d == 2 or $d == 3 or $d == 6;
  $c *= 6 if $d == 1;
  $c *= 3 if $d == 2;
  $c *= 2 if $d == 3;
  $c = $c % 12;

  return $zero  if $c ==  0;
  return $half  if $c ==  1;
  return undef  if $c ==  2;
  return $one   if $c ==  3;
  return undef  if $c ==  4;
  return $half  if $c ==  5;
  return $zero  if $c ==  6;
  return $mHalf if $c ==  7;
  return undef  if $c ==  8;
  return $mOne  if $c ==  9;
  return undef  if $c == 10;
  return $mHalf if $c == 11;
  return $zero  if $c == 12;
 }


=head3 cos2

Cosine of a term

=cut


sub cos2($)
 {my ($t) = @_;

  $t->{z} or die "Attempt to use unfinalized term in cos";

  return $one  if   $t == $zero;
  return undef if   $t->{divide} or
                    $t->{sqrt}   or
                    $t->{exp}    or
                    $t->{log};
  return undef unless $t->{i} == 0;
  return undef unless scalar(keys(%{$t->{v}})) == 1;
  return undef unless exists($t->{v}{pi});
  return undef unless $t->{v}{pi} == 1;

  my $c = $t->{c};
  my $d = $t->{d};
  return undef unless $d== 1 or $d == 2 or $d == 3 or $d == 6;
  $c *= 6 if $d == 1;
  $c *= 3 if $d == 2;
  $c *= 2 if $d == 3;
  $c = $c % 12;

  return $half  if $c == 10;
  return undef  if $c == 11;
  return $one   if $c == 12;
  return $one   if $c ==  0;
  return undef  if $c ==  1;
  return $half  if $c ==  2;
  return $zero  if $c ==  3;
  return $mHalf if $c ==  4;
  return undef  if $c ==  5;
  return $mOne  if $c ==  6;
  return undef  if $c ==  7;
  return $mHalf if $c ==  8;
  return $zero  if $c ==  9;
 }


=head3 log2

Log of a term

=cut


sub log2($)
 {my ($a) = @_;

  $a->{z} or die "Attempt to use unfinalized term in log";

  return $zero if $a == $one;
  return undef;
 }


=head3 id

Get Id of a term

=cut


sub id($)
 {my ($t) = @_;
  $t->{id} or die "Term $t not yet finalized";
  $t->{id};
 }


=head3 zz

# Check term finalized

=cut


sub zz($)
 {my ($t) = @_;
  $t->{z} or die "Term $t not yet finalized";
  $t;
 }


=head3 z

Finalize creation of the term. Once a term has been finalized, it
becomes readonly, which allows optimization to be performed.

=cut


sub z($)
 {my ($t) = @_;
  !exists($t->{z}) or die "Already finalized this term";

  my $p  = $t->print;
  return $z{$p} if defined($z{$p});
  $z{$p} = $t;
  weaken($z{$p});                                                               # Greatly reduces memory usage

  $t->{s}  = $p;
  $t->{z}  = $t->signature;
  $t->{id} = ++$z;

#HashUtil   lock_hash(%{$t->{v}}) if $lock;
#HashUtil   lock_hash %$t         if $lock;
  $t;
 }

#sub DESTROY($)
# {my ($t) = @_;
#  delete $z{$t->{s}} if defined($t) and exists $t->{s};
# }

sub lockHashes()
 {my ($l) = @_;
#HashUtil   for my $t(values %z)
#HashUtil    {lock_hash(%{$t->{v}});
#HashUtil     lock_hash %$t;
#HashUtil    }
  $lock = 1;
 }


=head3 print

Print

=cut


sub print($)
 {my ($t) = @_;
  return $t->{s} if defined($t->{s});
  my @k = sort keys %{$t->{v}};                                                 # 2016/01/20 16:18:12 Added sort to make prints canonical
  my $v = $t->{v};
  my $s = '';
  $s .=     $t->{c};
  $s .= '/'.$t->{d}                   if $t->{d} != 1;
  $s .= '*&i'                         if $t->{i} == 1;                          # 2016/01/20 15:55:21 &i to stop ambiguous complaints
  $s .= '*$'.$_                       for grep {$v->{$_} ==  1} @k;
  $s .= '/$'.$_                       for grep {$v->{$_} == -1} @k;
  $s .= '*$'.$_.'**'. $v->{$_}        for grep {$v->{$_}  >  1} @k;
  $s .= '/$'.$_.'**'.-$v->{$_}        for grep {$v->{$_}  < -1} @k;
  $s .= '/('.       $t->{divide} .')' if defined $t->{divide};
  $s .= '*sqrt('.   $t->{sqrt}   .')' if defined $t->{sqrt};
  $s .= '*exp('.    $t->{exp}    .')' if defined $t->{exp};
  $s .= '*log('.    $t->{log}    .')' if defined $t->{log};
  $s;
 }


=head2 import

Export L</newFromStrings> to calling package with a name specifed by the
caller, or as B<term()> by default. =cut

=cut


sub import
 {my %P = (program=>@_);
  my %p; $p{lc()} = $P{$_} for(keys(%P));

#_______________________________________________________________________
# New symbols term constructor - export to calling package.
#_______________________________________________________________________

  my $s = "pack"."age XXXX;\n". <<'END';
no warnings 'redefine';
sub NNNN
 {return SSSSnewFromStrings(@_);
 }
use warnings 'redefine';
END

#_______________________________________________________________________
# Export to calling package.
#_______________________________________________________________________

  my $name   = 'term';
     $name   = $p{term} if exists($p{term});
  my ($main) = caller();
  my $pack   = __PACKAGE__.'::';

  $s=~ s/XXXX/$main/g;
  $s=~ s/NNNN/$name/g;
  $s=~ s/SSSS/$pack/g;
  eval($s);

#_______________________________________________________________________
# Check options supplied by user
#_______________________________________________________________________

  delete @p{qw(program terms)};

  croak "Unknown option(s) for ". __PACKAGE__ .": ". join(' ', keys(%p))."\n\n". <<'END' if keys(%p);

Valid options are:

  terms=>'name' Desired name of the constructor routine for creating
                new terms.  The default is 'term'.
END
 }


=head2 Operators


=head3 Operator Overloads

Operator Overloads

=cut


use overload
 '+'     =>\&add3,
 '-'     =>\&negate3,
 '*'     =>\&multiply3,
 '/'     =>\&divide3,
 '**'    =>\&power3,
 '=='    =>\&equals3,
 'sqrt'  =>\&sqrt3,
 'exp'   =>\&exp3,
 'log'   =>\&log3,
 'sin'   =>\&sin3,
 'cos'   =>\&cos3,
 '""'    =>\&print3,
 fallback=>1;


=head3 add3

Add operator.

=cut


sub add3
 {my ($a, $b) = @_;
  $b = newFromString("$b") unless ref($b) eq __PACKAGE__;
  $a->{z} and $b->{z} or die "Add using unfinalized terms";
  $a->add($b);
 }


=head3 negate3

Negate operator.

=cut


sub negate3
 {my ($a, $b, $c) = @_;

  if (defined($b))
   {$b = newFromString("$b") unless ref($b) eq __PACKAGE__;
    $a->{z} and $b->{z} or die "Negate using unfinalized terms";
    return $b->subtract($a) if     $c;
    return $a->subtract($b) unless $c;
   }
  else
   {$a->{z} or die "Negate single unfinalized terms";
    return $a->negate;
   }
 }


=head3 multiply3

Multiply operator.

=cut


sub multiply3
 {my ($a, $b) = @_;
  $b = newFromString("$b") unless ref($b) eq __PACKAGE__;
  $a->{z} and $b->{z} or die "Multiply using unfinalized terms";
  $a->multiply($b);
 }


=head3 divide3

Divide operator.

=cut


sub divide3
 {my ($a, $b, $c) = @_;
  $b = newFromString("$b") unless ref($b) eq __PACKAGE__;
  $a->{z} and $b->{z} or die "Divide using unfinalized terms";
  return $b->divide2($a) if     $c;
  return $a->divide2($b) unless $c;
 }


=head3 power3

Power operator.

=cut


sub power3
 {my ($a, $b) = @_;
  $b = newFromString("$b") unless ref($b) eq __PACKAGE__;
  $a->{z} and $b->{z} or die "Power using unfinalized terms";
  $a->power($b);
 }


=head3 equals3

Equals operator.

=cut


sub equals3
 {my ($a, $b) = @_;
  if (ref($b) eq __PACKAGE__)
   {$a->{z} and $b->{z} or die "Equals using unfinalized terms";
    return $a->{id} == $b->{id};
   }
  else
   {$a->{z} or die "Equals using unfinalized terms";
    return $a->print eq "$b";
   }
 }


=head3 print3

Print operator.

=cut


sub print3
 {my ($a) = @_;
  $a->{z} or die "Print of unfinalized term";
  $a->print();
 }


=head3 sqrt3

Square root operator.

=cut


sub sqrt3
 {my ($a) = @_;
  $a->{z} or die "Sqrt of unfinalized term";
  $a->sqrt2();
 }


=head3 exp3

Exponential operator.

=cut


sub exp3
 {my ($a) = @_;
  $a->{z} or die "Exp of unfinalized term";
  $a->exp2();
 }


=head3 sin3

Sine operator.

=cut


sub sin3
 {my ($a) = @_;
  $a->{z} or die "Sin of unfinalized term";
  $a->sin2();
 }


=head3 cos3

Cosine operator.

=cut


sub cos3
 {my ($a) = @_;
  $a->{z} or die "Cos of unfinalized term";
  $a->cos2();
 }


=head3 log3

Log operator.

=cut


sub log3
 {my ($a) = @_;
  $a->{z} or die "Log of unfinalized term";
  $a->log2();
 }


=head2 test

Tests

=cut


sub test()
 {my ($a, $b, $c, $d);
# lockHashes();
  $a = n(0);                $a == $zero                 or die "100";
  $a = n(1);                $a == $one                  or die "101";
  $a = n(2);                $a == $two                  or die "102";
  $b = n(3);                $b == 3                     or die "103";
  $c = $a+$a;               $c == 4                     or die "104";
  $c = $a+$b;               $c == 5                     or die "105";
  $c = $a+$b+$a+$b;         $c == 10                    or die "106";
  $c = $a+1;                $c == 3                     or die "107";
  $c = $a+2;                $c == 4                     or die "108";
  $c = $b-1;                $c == 2                     or die "109";
  $c = $b-2;                $c == 1                     or die "110";
  $c = $b-9;                $c == -6                    or die "111";
  $c = $a/2;                $c == $one                  or die "112";
  $c = $a/4;                $c == '1/2'                 or die "113";
  $c = $a*2/2;              $c == $two                  or die "114";
  $c = $a*2/4;              $c == $one                  or die "115";
  $c = $a**2;               $c == 4                     or die "116";
  $c = $a**10;              $c == 1024                  or die "117";
  $c = sqrt($a**2);         $c == $a                    or die "118";
  $d = n(-1);               $d == -1                    or die "119";
  $c = sqrt($d);            $c == '1*i'                 or die "120";
  $d = n(4);                $d == 4                     or die "121";
  $c = sqrt($d);            $c == 2                     or die "122";
  $c = n('x*y2')/n('a*b2'); $c == '1*$x/$a*$y**2/$b**2' or die "122";

  $a = n('x');              $a == '1*$x'                or die "21";
  $b = n('2*x**2');         $b == '2*$x**2'             or die "22";
  $c = $a+$a;               $c == '2*$x'                or die "23";
  $c = $a+$a+$a;            $c == '3*$x'                or die "24";
  $c = $a-$a;               $c == $zero                 or die "25";
  $c = $a-$a-$a;            $c == '-1*$x'               or die "26";
  $c = $a*$b;               $c == '2*$x**3'             or die "27";
  $c = $a*$b*$a*$b;         $c == '4*$x**6'             or die "28";
  $c = $b/$a;               $c == '2*$x'                or die "29";
  $c = $a**2/$b;

            $c == '1/2'                 or die "29";
  $c = sqrt($a**4/($b/2));  $c == $a                    or die "29";

  $a = sin($zero);          $a == -0                    or die "301";
  $a = sin($pi/6);          $a ==  $half                or die "302";
  $a = sin($pi/2);          $a == 1                     or die "303";
  $a = sin(5*$pi/6);        $a ==  $half                or die "304";
  $a = sin(120*$pi/120);    $a ==  $zero                or die "305";
  $a = sin(7*$pi/6);        $a == -$half                or die "306";
  $a = sin(3*$pi/2);        $a == -1                    or die "307";
  $a = sin(110*$pi/ 60);    $a == '-1/2'                or die "308";
  $a = sin(2*$pi);          $a ==  $zero                or die "309";
  $a = sin(-$zero);         $a ==  $zero                or die "311";
  $a = sin(-$pi/6);         $a == -$half                or die "312";
  $a = sin(-$pi/2);         $a == -$one                 or die "313";
  $a = sin(-5*$pi/6);       $a == -$half                or die "314";
  $a = sin(-120*$pi/120);   $a == -$zero                or die "315";
  $a = sin(-7*$pi/6);       $a ==  $half                or die "316";
  $a = sin(-3*$pi/2);       $a ==  $one                 or die "317";
  $a = sin(-110*$pi/ 60);   $a ==  $half                or die "318";
  $a = sin(-2*$pi);         $a ==  $zero                or die "319";
  $a = cos($zero);          $a ==  $one                 or die "321";
  $a = cos($pi/3);          $a ==  $half                or die "322";
  $a = cos($pi/2);          $a ==  $zero                or die "323";
  $a = cos(4*$pi/6);        $a == -$half                or die "324";
  $a = cos(120*$pi/120);    $a == -$one                 or die "325";
  $a = cos(8*$pi/6);        $a == -$half                or die "326";
  $a = cos(3*$pi/2);        $a ==  $zero                or die "327";
  $a = cos(100*$pi/ 60);    $a ==  $half                or die "328";
  $a = cos(2*$pi);          $a ==  $one                 or die "329";
  $a = cos(-$zero);         $a ==  $one                 or die "331";
  $a = cos(-$pi/3);         $a == +$half                or die "332";
  $a = cos(-$pi/2);         $a ==  $zero                or die "333";
  $a = cos(-4*$pi/6);       $a == -$half                or die "334";
  $a = cos(-120*$pi/120);   $a == -$one                 or die "335";
  $a = cos(-8*$pi/6);       $a == -$half                or die "336";
  $a = cos(-3*$pi/2);       $a ==  $zero                or die "337";
  $a = cos(-100*$pi/ 60);   $a ==  $half                or die "338";
  $a = cos(-2*$pi);         $a ==  $one                 or die "339";
  $a = exp($zero);          $a ==  $one                 or die "340";
  $a = exp($i*$pi/2);       $a ==  $i                   or die "341";
  $a = exp($i*$pi);         $a == -$one                 or die "342";
  $a = exp(3*$i*$pi/2);     $a == -$i                   or die "343";
  $a = exp(4*$i*$pi/2);     $a ==  $one                 or die "344";
 }

test unless caller;

#_______________________________________________________________________
# Package installed successfully
#_______________________________________________________________________

1;
