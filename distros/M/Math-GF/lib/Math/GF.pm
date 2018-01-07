package Math::GF;
use strict;
use warnings;
{ our $VERSION = '0.004'; }

use Moo;
use Ouch;
use Math::GF::Zn;

use constant MARGIN => 1.1;

has order          => (is => 'ro');
has p              => (is => 'ro');
has n              => (is => 'ro');
has order_is_prime => (is => 'ro');
has element_class  => (is => 'ro');

# The following are used only for extension fields
has sum_table      => (is => 'ro');
has prod_table     => (is => 'ro');

# neutral element for "+" operation
sub additive_neutral { return $_[0]->e(0) }

# factory method to create "all" elements in the field
sub all {
   my $self   = shift;
   my $eclass = $self->element_class;
   my $order  = $self->order;
   map { $eclass->new(field => $self, v => $_) } 0 .. ($order - 1);
} ## end sub all

# import a handy factory method into caller's package
sub import_builder {
   my ($package, $order) = splice @_, 0, 2;
   my %args = (@_ && ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

   my $field = $package->new(order => $order);
   my $builder = sub { return $field->e(@_) };
   my $callpkg = caller($args{level} // 0);
   my $name = $args{name} // (
      $field->order_is_prime
      ? "GF_$order"
      : join('_', 'GF', $field->p, $field->n)
   );
   no strict 'refs';
   *{$callpkg . '::' . $name} = $builder;
   return;
} ## end sub import_builder

# factory method to create "e"lements of the field
sub e {
   my $self = shift;
   my $ec = $self->element_class;
   return $ec->new(field => $self, v => $_[0]) unless wantarray;
   return map { $ec->new(field => $self, v => $_) } @_;
}

# neutral element for "*" operation
sub multiplicative_neutral { return $_[0]->e(1) }

sub BUILDARGS {
   my ($class, %args) = @_;

   ouch 500, 'missing order' unless exists $args{order};
   my $order = $args{order};
   ouch 500, 'undefined order' unless defined $order;
   ouch 500, 'order MUST be integer and greater than 1'
     unless $order =~ m{\A(?: [2-9] | [1-9]\d+)\z}mxs;

   my ($p, $n) = __prime_power_decomposition($order);
   ouch 500, 'order MUST be a power of a prime'
     unless defined $p;
   $args{p}              = $p;
   $args{n}              = $n;
   $args{order_is_prime} = ($n == 1);
   if ($n == 1) {
      $args{order_is_prime} = 1;
      $args{element_class} = 'Math::GF::Zn';
      delete @args{qw< sum_table prod_table >};
   }
   else {
      $args{order_is_prime} = 0;
      $args{element_class} = 'Math::GF::Extension';
      @args{qw< sum_table prod_table >} = __tables($order);
      require Math::GF::Extension;
   }

   return {%args};
} ## end sub BUILDARGS

sub __tables {
   my $order = shift;

   # Get the basic subfield
   my ($p, $n) = __prime_power_decomposition($order);
   my $Zp = Math::GF->new(order => $p);
   my @Zp_all = $Zp->all;
   my ($zero, $one) = ($Zp->additive_neutral, $Zp->multiplicative_neutral);

   my $pirr = __get_irreducible_polynomial($Zp, $n);
   my $polys = __generate_polynomials($Zp, $n);
   my %id_for = map {; "$polys->[$_]" => $_ } 0 .. $#$polys;

   my (@sum, @prod);
   for my $i (0 .. $#$polys) {
      my $I = $polys->[$i];
      push @sum, \my @ts;
      push @prod, \my @tp;
      for my $j (0 .. $i) {
         my $J = $polys->[$j];
         my $sum = ($I + $J);
         push @ts, $id_for{"$sum"};
         my $prod = ($I * $J) % $pirr;
         push @tp, $id_for{"$prod"};
      }
   }

   return (\@sum, \@prod);
}

sub __generate_polynomials {
   my ($field, $degree) = @_;
   ouch 500, 'irreducible polynomial search only over Zn field'
     unless $field->order_is_prime;
   my $zero = $field->additive_neutral;
   my $one  = $field->multiplicative_neutral;

   my @coeffs = ($zero) x ($degree + 1); # last one as a flag
   my @retval;
   while ($coeffs[-1] == $zero) {
      push @retval, Math::Polynomial->new(@coeffs);
      for (@coeffs) {
         $_ = $_ + $one;
         last unless $_ == $zero;
      }
   }
   return \@retval;
}

sub __get_irreducible_polynomial {
   my ($field, $degree) = @_;
   ouch 500, 'irreducible polynomial search only over Zn field'
     unless $field->order_is_prime;

   my $zero = $field->additive_neutral;
   my $one  = $field->multiplicative_neutral;
   require Math::Polynomial;
   my @coeffs = ($one, (($zero) x ($degree - 1)), $one);
   while ($coeffs[-1] == $one) {
      my $poly = Math::Polynomial->new(@coeffs);
      return $poly if __rabin_irreducibility_test($poly);
      for (@coeffs) {
         $_ = $_ + $one;
         last unless $_ == $zero; # wrapped up
      }
   }
   ouch 500, "no monic irreducibile polynomial!"; # never happens
}

sub __to_poly {
   my ($x, $n) = @_;
   my @coeffs;
   while ($x) {
      push @coeffs, $x % $n;
      $x = ($x - $coeffs[-1]) / $n;
   }
   push @coeffs, 0 unless @coeffs;
   return Z_poly($n, @coeffs);
}

sub __rabin_irreducibility_test {
   my $f    = shift;
   my $n    = $f->degree;
   my $one  = $f->coeff_one;
   my $pone = Math::Polynomial->monomial(0, $one);
   my $x    = Math::Polynomial->monomial(1, $one);
   my $q    = $one->n;
   my $ps   = __prime_divisors_of($n);

   for my $pi (@$ps) {
      my $ni  = $n / $pi;
      my $qni = $q**$ni;
      my $h = (Math::Polynomial->monomial($qni, $one) - $x) % $f;
      my $g = $h->gcd($f, 'mod');
      #return if $g != $pone;
      return if $g->degree > 1;
   } ## end for my $pi (@$ps)
   my $t = (Math::Polynomial->monomial($q**$n, $one) - $x) % $f;
   return $t->degree == -1;
} ## end sub rabin_irreducibility_test

sub __prime_power_decomposition {
   my $x = shift;
   return if $x < 2;
   return ($x, 1) if $x < 4;

   my $p = __prime_divisors_of($x, 'first only please');
   return ($x, 1) if $x == $p;    # $x is prime

   my $e = 0;
   while ($x > 1) {
      return if $x % $p;         # not the only divisor!
      $x /= $p;
      ++$e;
   }
   return ($p, $e);
} ## end sub __prime_power_decomposition

sub __prime_divisors_of {
   my ($n, $first_only) = @_;
   my @retval;

   return if $n < 2;

   for my $p (2, 3) { # handle cases for 2 and 3 first
      next if $n % $p;
      return $p if $first_only;
      push @retval, $p;
      $n /= $p until $n % $p;
   }

   my $p = 5; # tentative divisor, will increase through iterations
   my $top = int(sqrt($n) + MARGIN); # top attempt for divisor
   my $d = 2; # increase for $p, alternates between 4 and 2
   while ($p <= $top) {
      if ($n % $p == 0) {
         return $p if $first_only;
         unshift @retval, $p;
         $n /= $p until $n % $p;
         $top = int(sqrt($n) + MARGIN);
      }
      $p += $d;
      $d = ($d == 2) ? 4 : 2;
   } ## end while ($n > 1)

   # exited with $n left as a prime... maybe
   return $n if $first_only; # always in this case
   push @retval, $n if $n > 1;

   return \@retval;
} ## end sub prime_divisors_of

1;
