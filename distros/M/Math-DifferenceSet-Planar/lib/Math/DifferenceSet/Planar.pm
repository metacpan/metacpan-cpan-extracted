package Math::DifferenceSet::Planar;

use strict;
use warnings;
use Carp qw(croak);
use Math::DifferenceSet::Planar::Data;
use Math::BigInt try => 'GMP';
use Math::Prime::Util qw(is_power is_prime_power euler_phi factor_exp gcd);

# Math::DifferenceSet::Planar=ARRAY(...)
# ........... index ...........     # ........... value ...........
use constant _F_ORDER     =>  0;
use constant _F_BASE      =>  1;
use constant _F_EXPONENT  =>  2;
use constant _F_MODULUS   =>  3;
use constant _F_N_PLANES  =>  4;    # number of distinct planes this size
use constant _F_ELEMENTS  =>  5;    # elements arrayref
use constant _F_ROTATORS  =>  6;    # rotators arrayref, initially empty
use constant _F_INDEX_MIN =>  7;    # index of smallest element
use constant _F_PEAK      =>  8;    # peak elements arrayref, initially undef
use constant _F_ETA       =>  9;    # "eta" value, initially undef
use constant _NFIELDS     => 10;

our $VERSION = '0.009';

our $_LOG_MAX_ORDER  = 22.1807;         # limit for integer exponentiation
our $_MAX_ENUM_COUNT = 32768;           # limit for stored rotator set size
our $_MAX_MEMO_COUNT = 4096;            # limit for memoized values
our $_DEFAULT_DEPTH  = 1024;            # default check_elements() depth

my $current_data = undef;               # current M::D::P::Data object

my %memo_n_planes = ();                 # memoized n_planes values

# ----- private subroutines -----

# calculate powers of p (mod m)
sub _multipliers {
    my ($base, $exponent, $modulus) = @_;
    my @mult = (1);
    my $n = 3 * $exponent;
    my $x = $base;
    while (@mult < $n && $x != 1) {
        push @mult, $x;
        $x = $x * $base % $modulus;
    }
    push @mult, q[...] if $x != 1;
    die "assertion failed: not $n elements: @mult" if @mult != $n;
    return @mult;
}

# return complete rotator base if small enough, otherwise undef
sub _rotators {
    my ($this) = @_;
    my (           $base,   $exponent,   $modulus,   $rotators) =
        @{$this}[_F_BASE, _F_EXPONENT, _F_MODULUS, _F_ROTATORS];
    return $rotators if @{$rotators};
    return undef if $this->[_F_N_PLANES] > $_MAX_ENUM_COUNT;
    my @mult = _multipliers($base, $exponent, $modulus);
    my @sieve = (1) x $modulus;
    @sieve[@mult] = ();
    @{$rotators} = (1);
    for (my $x = 2; $x < $modulus ; ++$x) {
        if ($sieve[$x]) {
            if (0 == $modulus % $x) {
                for (my $i = $x; $i < $modulus; $i += $x) {
                    undef $sieve[$i];
                }
                next;
            }
            @sieve[ map { $x * $_ % $modulus } @mult ] = ();
            push @{$rotators}, $x;
        }
    }
    return $rotators;
}

# iterative rotator base generator
sub _sequential_rotators {
    my ($this) = @_;
    my (          $base,  $exponent,  $modulus,  $n_planes) =
        @{$this}[_F_BASE, _F_EXPONENT, _F_MODULUS, _F_N_PLANES];
    my @mult = _multipliers($base, $exponent, $modulus);
    shift @mult;
    my @pf = map { $_->[0] } factor_exp($modulus);
    pop @pf if $pf[-1] == $modulus;
    my $mx = 0;
    my $x  = 0;
    return sub {
        return 0 if $mx >= $n_planes;
        ELEMENT:
        while (1) {
            ++$x;
            foreach my $p (@pf) {
                next ELEMENT if !($x % $p);
            }
            foreach my $e (@mult) {
                next ELEMENT if $x * $e % $modulus < $x;
            }
            ++$mx;
            return $x;
        }
    };
}

# integer exponentiation
sub _pow {
    my ($base, $exponent) = @_;
    return 0 if $base <= 0 || $exponent < 0;
    return Math::BigInt->new($base)->bpow($exponent)
        if log(0+$base) * $exponent > $_LOG_MAX_ORDER;
    my $power = 1;
    while ($exponent) {
        $power *= $base if 1 & $exponent;
        $exponent >>= 1 and $base *= $base;
    }
    return $power;
}

#      0  1  2  3  4  5  6  7  8  9  10
#      3  7 14 25 28 29 31 41 61 99 103
#      7  8  9 10  0  1  2  3  4  5   6
# re-arrange elements of a planar difference set in conventional order
sub _sort_elements {
    my $modulus  = shift;
    my @elements = sort { $a <=> $b || croak "duplicate element: $a" } @_;
    my $lo = $elements[-1] - $modulus;
    my $hi = $elements[0];
    my $mx = 0;
    while ($hi - $lo != 1 && ++$mx < @elements) {
        ($lo, $hi) = ($hi, $elements[$mx]);
    }
    croak "delta 1 elements missing" if $mx >= @elements;
    $mx += @elements if !$mx--;
    push @elements, splice @elements, 0, $mx if $mx;
    return (\@elements, $mx? @elements - $mx: 0);
}

#      0  1  2  3  4  5  6  7
#     28 29 31 41  3  7 14 25 
#      L        X           H
#                  L  X     H
#                 LX  H
sub _index_min {
    my ($elements) = @_;
    my ($lx, $hx) = (0, $#$elements);
    my $he = $elements->[$hx];
    while ($lx < $hx) {
        my $x = ($lx + $hx) >> 1;
        my $e = $elements->[$x];
        if ($e < $he) {
            $hx = $x;
            $he = $e;
        }
        else {
            $lx = $x + 1;
        }
    }
    return $hx;
}

# return data connection, creating it if not yet open
sub _data {
    if (!defined $current_data) {
        $current_data = Math::DifferenceSet::Planar::Data->new;
    }
    return $current_data;
}

# ----- class methods -----

sub list_databases {
    return Math::DifferenceSet::Planar::Data->list_databases;
}

sub set_database {
    my $class = shift;
    $current_data = Math::DifferenceSet::Planar::Data->new(@_);
    return $class->available_count;
}

# print "ok" if Math::DifferenceSet::Planar->available(9);
# print "ok" if Math::DifferenceSet::Planar->available(3, 2);
sub available {
    my ($class, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    my $pds   = $order && $class->_data->get($order, 'base');
    return !!$pds && (!defined($exponent) || $base == $pds->base);
}

# $ds = Math::DifferenceSet::Planar->new(9);
# $ds = Math::DifferenceSet::Planar->new(3, 2);
sub new {
    my ($class, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    my $pds   = $order && $class->_data->get($order);
    if (!$pds || defined($exponent) && $base != $pds->base) {
        my $key = defined($exponent)? "$base, $exponent": $order;
        croak "PDS($key) not available";
    }
    return bless [
        $pds->order,
        $pds->base,
        $pds->exponent,
        $pds->modulus,
        $pds->n_planes,
        $pds->elements,
        [],
        0,
    ], $class;
}

# $ds = Math::DifferenceSet::Planar->from_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub from_elements {
    my $class    = shift;
    my $order    = $#_;
    my ($base, $exponent);
    $exponent    = is_prime_power($order, \$base)
        or croak "this implementation cannot handle order $order";
    my $modulus  = $order * ($order + 1) + 1;
    if (grep { $_ < 0 || $modulus <= $_ } @_) {
        my $max = $modulus - 1;
        croak "element values inside range 0..$max expected";
    }
    my ($elements, $index_min) = _sort_elements($modulus, @_);
    my $n_planes;
    if (!exists $memo_n_planes{$order}) {
        $n_planes = $memo_n_planes{$order} =
            euler_phi($modulus) / (3 * $exponent);
        %memo_n_planes = ($order => $n_planes)
            if $_MAX_MEMO_COUNT < keys %memo_n_planes;
    }
    else {
        $n_planes = $memo_n_planes{$order};
    }
    return bless [
        $order,
        $base,
        $exponent,
        $modulus,
        $n_planes,
        $elements,
        [],
        $index_min,
    ], $class;
}

# $bool = Math::DifferenceSet::Planar->verify_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub verify_elements {
    my ($class, @elements) = @_;
    my $order   = $#elements;
    return undef if $order <= 1;
    my $modulus = $order * ($order + 1) + 1;
    my $median  = ($modulus - 1) / 2;
    my $seen    = '0' x $median;
    foreach my $r1 (@elements) {
        return undef if $r1 < 0 || $modulus <= $r1 || $r1 != int $r1;
        foreach my $r2 (@elements) {
            last if $r1 == $r2;
            my $d = $r1 < $r2? $r2 - $r1: $modulus + $r2 - $r1;
            $d = $modulus - $d if $d > $median;
            return q[] if substr($seen, $d-1, 1)++;
        }
    }
    return $median == $seen =~ tr/1//;
}

# $bool = Math::DifferenceSet::Planar->check_elements(
#   [0, 1, 3, 9, 27, 49, 56, 61, 77, 81], 999
# );
sub check_elements {
    my ($class, $elem_listref, $depth, $factor) = @_;
    my $order        = $#{$elem_listref};
    return undef if $order <= 1;
    my $modulus      = $order * ($order + 1) + 1;
    my $median       = ($modulus - 1) / 2;
    $depth           = $median <= $_DEFAULT_DEPTH? $median: $_DEFAULT_DEPTH
        if !$depth;
    my $limit        = $median <= $depth? $median: $depth;
    my $seen         = '1' . ('0' x $limit);
    foreach my $e (@{$elem_listref}) {
        return undef if $e < 0 || $modulus <= $e || $e != int $e;
    }
    my @elements  = sort { $a <=> $b } @{$elem_listref};
    I1:
    foreach my $i1 (0 .. $order) {
        my $r1 = $elements[$i1];
        my $i2 = $i1 - 1;
        while ($i2 >= 0) {
            my $r2 = $elements[$i2];
            my $d = $r1 - $r2;
            next I1 if $d > $limit;
            return !1 if substr($seen, $d, 1)++;
            --$i2;
        }
        $i2 = $order;
        while ($i2 > $i1) {
            my $r2 = $elements[$i2];
            my $d = $modulus + $r1 - $r2;
            next I1 if $d > $limit;
            return !1 if substr($seen, $d, 1)++;
            --$i2;
        }
    }
    return !1 if 0 <= index $seen, '0';
    return 2 if $median <= $depth;
    if (!defined $factor) {
        $factor = $order if !is_power($order, 0, \$factor);
    }
    if (1 < $factor) {
        my $mx = $order;
        for (my $i = 0; $i < $order; ++$i) {
            $mx = $i, last if 1 == $elements[$i+1] - $elements[$i];
        }
        push @elements, splice @elements, 0, $mx if $mx;
        my ($multiple) = eval { _sort_elements(
            $modulus,
            map { $_ * $factor % $modulus } @elements
        )};
        return 0 if !defined $multiple;
        my $d1 = $elements[0] - $multiple->[0];
        my $d2 = $d1 >= 0? $d1 - $modulus: $d1 + $modulus;
        ($d1, $d2) = ($d2, $d1) if abs($d2) > abs($d1);         # optimization
        for (my $i = 1; $i <= $order; ++$i) {
            my $d = $elements[$i] - $multiple->[$i];
            return 0 if $d != $d1 && $d != $d2;
        }
    }
    return 1;
}

# $it1 = Math::DifferenceSet::Planar->iterate_available_sets;
# $it2 = Math::DifferenceSet::Planar->iterate_available_sets(10, 20);
# while (my $ds = $it2->()) {
#   ...
# }
sub iterate_available_sets {
    my ($class, @minmax) = @_;
    my $dit = $class->_data->iterate(@minmax);
    return sub {
        my $pds = $dit->();
        return undef if !$pds;
        return bless [
            $pds->order,
            $pds->base,
            $pds->exponent,
            $pds->modulus,
            $pds->n_planes,
            $pds->elements,
            [],
            0,
        ], $class;
    };
}

# $om = Math::DifferenceSet::Planar->available_max_order;
sub available_max_order { __PACKAGE__->_data->max_order }

# $om = Math::DifferenceSet::Planar->available_count;
sub available_count { __PACKAGE__->_data->count }

# ----- object methods -----

# $o  = $ds->order;
# $p  = $ds->order_base;
# $n  = $ds->order_exponent;
# $m  = $ds->modulus;
# $np = $ds->n_planes;
# @e  = $ds->elements;
# $e0 = $ds->element(0);
sub order          {    $_[0]->[_F_ORDER   ]            }
sub order_base     {    $_[0]->[_F_BASE    ]            }
sub order_exponent {    $_[0]->[_F_EXPONENT]            }
sub modulus        {    $_[0]->[_F_MODULUS ]            }
sub n_planes       {    $_[0]->[_F_N_PLANES]            }
sub elements       { @{ $_[0]->[_F_ELEMENTS]          } }
sub element        {    $_[0]->[_F_ELEMENTS]->[$_[1]]   }
sub start_element  {    $_[0]->[_F_ELEMENTS]->[   0 ]   }

# @e  = $ds->elements_sorted;
sub elements_sorted {
    my ($this) = @_;
    my $elements = $this->[_F_ELEMENTS];
    return @$elements if !wantarray;
    my $index_min = $this->[_F_INDEX_MIN];
    return @{$elements}[$index_min .. $#$elements, 0 .. $index_min - 1];
}

# $ds1 = $ds->translate(1);
sub translate {
    my ($this, $delta) = @_;
    my $modulus = $this->[_F_MODULUS];
    $delta %= $modulus;
    return $this if !$delta;
    my @elements = map { ($_ + $delta) % $modulus } @{$this->[_F_ELEMENTS]};
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS]  = \@elements;
    $that->[_F_INDEX_MIN] =
        $elements[0] < $elements[-1]? 0: _index_min(\@elements);
    return $that;
}

# $ds2 = $ds->canonize;
sub canonize { $_[0]->translate(- $_[0]->[_F_ELEMENTS]->[0]) }

# $it  = $ds->iterate_rotators;
# while (my $m = $it->()) {
#   ...
# }
sub iterate_rotators {
    my ($this) = @_;
    my $rotators = $this->_rotators;
    return $this->_sequential_rotators if !$rotators;
    my $mx = 0;
    return sub { $mx < @{$rotators}? $rotators->[$mx++]: 0 };
}

# $it = $ds->iterate_planes;
# while (my $ds = $it->()) {
#   ...
# }
sub iterate_planes {
    my ($this) = @_;
    my $r_it = $this->iterate_rotators;
    return sub {
        my $r = $r_it->();
        return $r? $this->multiply($r)->canonize: undef;
    };
}

# @pm = $ds->multipliers;
sub multipliers {
    my ($this) = @_;
    my (          $base,  $exponent,  $modulus) =
        @{$this}[_F_BASE, _F_EXPONENT, _F_MODULUS];
    return 3 * $exponent if !wantarray;
    return _multipliers($base, $exponent, $modulus);
}

# $ds3 = $ds->multiply($m);
sub multiply {
    my ($this, $factor) = @_;
    my $modulus = $this->[_F_MODULUS];
    $factor %= $modulus;
    croak "$_[1]: factor is not coprime to modulus"
        if gcd($modulus, $factor) != 1;
    return $this if 1 == $factor;
    my ($elements, $index_min) = _sort_elements(
        $modulus,
        map { $_ * $factor % $modulus } @{$this->[_F_ELEMENTS]}
    );
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS ] = $elements;
    $that->[_F_INDEX_MIN] = $index_min;
    return $that;
}

# ($e1, $e2) = $ds->find_delta($delta);
sub find_delta {
    my ($this, $delta) = @_;
    my $order    = $this->order;
    my $modulus  = $this->modulus;
    my $elements = $this->[_F_ELEMENTS];
    my $de = $delta % $modulus;
    my $up = $de + $de < $modulus;
    $de = $modulus - $de if !$up;
    my ($lx, $ux, $c) = (0, 0, 0);
    my ($le, $ue) = @{$elements}[0, 0];
    while ($c != $de) {
        if ($c < $de) {
            if(++$ux > $order) {
                $ux = 0;
            }
            $ue = $elements->[$ux];
        }
        else {
            if (++$lx > $order) {
                croak "bogus set: delta not found: $delta (mod $modulus)";
            }
            $le = $elements->[$lx];
        }
        $c = $ue < $le? $modulus + $ue - $le: $ue - $le;
    }
    return $up? ($le, $ue): ($ue, $le);
}

# ($e1, $e2) = $ds->peak_elements
sub peak_elements {
    my ($this) = @_;
    my $peak = $this->[_F_PEAK];
    if (!defined $peak) {
        $peak = [$this->find_delta($this->modulus >> 1)];
        $this->[_F_PEAK] = $peak;
    }
    return @{$peak};
}

# $e = $ds->eta
sub eta {
    my ($this) = @_;
    my $eta = $this->[_F_ETA];
    if (!defined $eta) {
        my $that = $this->multiply($this->order_base);
        $eta = $this->[_F_ETA] =
            ($that->element(0) - $this->element(0)) % $this->modulus;
    }
    return $eta;
}

# $bool = $ds->contains($e)
sub contains {
    my ($this, $elem) = @_;
    my $elements  = $this->[_F_ELEMENTS];
    my $lx        = $this->[_F_INDEX_MIN];
    my $hx        = $#{$elements};
    ($lx, $hx) = (0, $lx - 1) if $lx && $elements->[0] <= $elem;
    while ($lx <= $hx) {
        my $x = ($lx + $hx) >> 1;
        my $e = $elements->[$x];
        if ($e <= $elem) {
            return !0 if $e == $elem;
            $lx = $x + 1;
        }
        else {
            $hx = $x - 1;
        }
    }
    return !1;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::DifferenceSet::Planar - object class for planar difference sets

=head1 VERSION

This documentation refers to version 0.009 of Math::DifferenceSet::Planar.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar;

  $ds = Math::DifferenceSet::Planar->new(9);
  $ds = Math::DifferenceSet::Planar->new(3, 2);
  $ds = Math::DifferenceSet::Planar->from_elements(
    0, 1, 3, 9, 27, 49, 56, 61, 77, 81
  );
  print "ok" if Math::DifferenceSet::Planar->verify_elements(
    0, 1, 3, 9, 27, 49, 56, 61, 77, 81
  );
  $o  = $ds->order;
  $m  = $ds->modulus;
  @e  = $ds->elements;
  @e  = $ds->elements_sorted;
  $e0 = $ds->element(0);
  $e0 = $ds->start_element;             # equivalent
  $np = $ds->n_planes;
  $p  = $ds->order_base;
  $n  = $ds->order_exponent;

  ($e1, $e2) = $ds->find_delta($delta);
  ($e1, $e2) = $ds->peak_elements;
  ($e1)      = $ds->find_delta(($ds->modulus - 1) / 2);
  $eta       = $ds->eta;
  $bool      = $ds->contains($e1);

  $ds1 = $ds->translate(1);
  $ds2 = $ds->canonize;
  $ds2 = $ds->translate(- $ds->element(0)); # equivalent
  @pm  = $ds->multipliers;
  $it  = $ds->iterate_rotators;
  while (my $m = $it->()) {
    $ds3 = $ds->multiply($m)->canonize;
  }
  $it = $ds->iterate_planes;
  while (my $ds3 = $it->()) {
    # as above
  }

  $r  = Math::DifferenceSet::Planar->check_elements(
    [0, 1, 3, 9, 27, 49, 56, 61, 77, 81], 10
  );
  print "not small non-negative integers"  if !defined $r;
  print "not a planar difference set"      if !$r;
  print "multiplier check failed"          if defined $r and 0 eq $r;
  print "probably a planar difference set" if defined $r and 1 == $r;
  print "verified planar difference set"   if defined $r and 2 == $r;

  @db = Math::DifferenceSet::Planar->list_databases;
  $count = Math::DifferenceSet::Planar->set_database($db[0]);

  print "ok" if Math::DifferenceSet::Planar->available(9);
  print "ok" if Math::DifferenceSet::Planar->available(3, 2);
  $it1 = Math::DifferenceSet::Planar->iterate_available_sets;
  $it2 = Math::DifferenceSet::Planar->iterate_available_sets(10, 20);
  while (my $ds = $it2->()) {
    $o = $ds->order;
    $m = $ds->modulus;
    print "$o\t$m\n";
  }
  $om = Math::DifferenceSet::Planar->available_max_order;
  $ns = Math::DifferenceSet::Planar->available_count;

=head1 DESCRIPTION

A planar difference set in a modular integer ring E<8484>_n, or cyclic
planar difference set, is a subset D = {d_1, d_2, ..., d_k} of E<8484>_n
such that each nonzero element of E<8484>_n can be represented as a
difference (d_i - d_j) in exactly one way.  By convention, only sets
with at least three elements are considered.

Necessarily, for such a set to exist, the modulus n has to be equal to
S<(k - 1) E<183> k + 1>.  If S<(k - 1)> is a prime power, planar difference
sets can be constructed from a finite field of order S<(k - 1)>.  It is
conjectured that no other planar difference sets exist.  If other families
of planar difference sets should be discovered, this library would be
due to be extended accordingly.

If S<D = {d_1, d_2, ..., d_k} E<8834> E<8484>_n> is a difference set and
a is an element of E<8484>_n, S<D + a = {d_1 + a, d_2 + a, ..., d_k + a}>
is also a difference set.  S<D + a> is called a translate of D.  The set
of all translates of a planar difference set as lines and the elements
of E<8484>_n as points make up a finite projective plane (hence the name).

If t is an element of E<8484>_n coprime to n, S<D E<183> t> =
S<{d_1 E<183> t, d_2 E<183> t, ..., d_k E<183> t}> is also a difference
set.  If S<D E<183> t> is a translate of D, t is called a multiplicator
of D.  If t is coprime to n but either identical to 1 (mod n) or not a
multiplicator, it is called a rotator.  Rotators of planar difference
sets are also rotators of planes as translates of a difference set
are mapped to translates of the rotated set.  We call a minimal set of
rotators spanning all plane rotations a rotator base.

Math::DifferenceSet::Planar provides examples of small cyclic planar
difference sets constructed from finite fields.  It is primarily intended
as a helper module for algorithms employing such sets.  It also allows
to iterate over all sets of a given size via translations and rotations,
and to verify whether an arbitrary set of modular integers is a cyclic
planar difference set.

Currently, only sets with k E<8804> 4097, or moduli E<8804> 16_781_313,
are supported by the CPAN distribution of the module.  These limits can
be extended by installing a database with more samples.  Instructions on
where to obtain additional data will be included in an upcoming release.

=head2 Conventions

For efficiency, all elements handled by this module are represented
as simple Perl integers rather than proper Math::ModInt objects.
All elements of a difference set share the same modulus, accessible
through the I<modulus> method.  Thus the integers can easily be converted
to modular integer objects if necessary.

By convention, the default order elements of a difference set are
enumerated in by this module starts with the unique elements I<s>
and S<I<s> + 1> that are both in the set, and continues by smallest
possible increments.  For example, S<{ 3, 5, 10, 11, 14 } (mod 21)>
would be enumerated as S<(10, 11, 14, 3, 5)>.

Each plane (i.e. complete set of translates of a planar difference
set) has a unique set containing the elements 0 and 1.  We call this
set the canonical representative of the plane.

Each planar difference set has, for each nonzero element I<delta>
of its ring E<8484>_n, a unique pair of elements S<(I<e1>, I<e2>)>
satisfying S<I<e2> - I<e1> = I<delta>>.  For S<I<delta> = 1>, we call
I<e1> the start element.  For S<I<delta> = (I<n> - 1) / 2>, we call I<e1>
and I<e2> the peak elements.

As I<order_base> is (conjecturally) always a multiplier, multiplying a
planar difference set by I<order_base> will yield a translation of the
original set.  We call the translation amount eta.

=head1 CLASS VARIABLES

=over 4

=item I<$VERSION>

C<$VERSION> is the version number of the module and of the distribution.

=back

=head1 CLASS METHODS

=head2 Constructors

=over 4

=item I<new>

If C<$q> is a prime power, C<Math::DifferenceSet::Planar-E<gt>new($q)>
returns a sample planar difference set object with C<$q + 1> elements,
unless C<$q> exceeds some implementation limitation (see below).

If C<$p> is a prime number and C<$j> is an integer E<gt> 0,
C<Math::DifferenceSet::Planar-E<gt>new($p, $j)> returns a sample planar
difference set object with C<$p ** $j + 1> elements, unless C<$p ** $j>
exceeds some implementation limitation.

If C<$q> is not a prime power, or C<$p> is not a prime, or the number
of elements would exceed the limitation, an exception is raised.

=item I<from_elements>

If C<@e> is a cyclic planar difference set, represented as
distinct non-negative integer numbers less than some modulus,
C<Math::DifferenceSet::Planar-E<gt>from_elements(@e)> returns a planar
difference set object with precisely these elements.

Note that arguments not verified to define a planar difference set may
yield a broken object with undefined behaviour.  Note also that this
method expects elements to be normalized, i.e. integer values from zero
to the modulus minus one.

The modulus itself is not a parameter, as it can be computed from the
number I<k> of arguments as S<I<m> = I<k>E<178> - I<k> + 1>.

=back

=head2 Other class methods

=over 4

=item I<verify_elements>

If C<@e> is an array of integer values,
C<Math::DifferenceSet::Planar-E<gt>verify_elements(@e)> returns a true
value if those values define a cyclic planar difference set and are
normalized, i.e. non-negative and less than the modulus, otherwise a
false value.  Note that this check is expensive, having quadratic space
and time complexity, but should work regardless of the method the set was
constructed by.  It may thus be used to verify cyclic planar difference
sets this module would not be capable of generating itself.

The return value is undef if the set is not a set of non-negative integers
of appropriate size, defined but false if it is, but not happens to
represent a cyclic planar difference set, and true on success.

=item I<check_elements>

If C<@e> is an array of integer values,
C<Math::DifferenceSet::Planar-E<gt>check_elements(\@e)> returns a true
value if those values probably define a cyclic planar difference set and
are normalized, i.e. non-negative and less than the modulus, otherwise
a false value.  Note that this check may wrongly return true in some
cases, but is less expensive than the exhaustive check I<verify_elements>
as it has only fixed space and linear time complexity.

An optional positive second argument C<$depth> governs the effort to be
taken, larger values meaning more work and higher accuracy.  A depth
value of half the modulus (rounded down) will make I<check_elements>
equivalent to I<verify_elements> in complexity and accuracy.

More precisely, the check looks for unique I<small> differences of
elements of the set.  Proper planar difference sets will of course
provide only uniqe differences and thus pass the test.

The return value is 2 if the set is proven to be correct, 1 if it is
probably correct, a false but defined value if it is proven to be not
correct and undef if it is not even a set of non-negative integers of
appropriate size.

An optional third argument I<$factor> controls the check whether the given
factor is a multiplicator.  For planar difference sets this module
generates, I<order_base> is indeed a multiplicator.  Thus this combined
check should give a good heuristic whether a given set is actually
representing a planar difference set related to a finite field like the
ones generated by this module.

If the factor is not specified, the check will be performed with a
suitable multiplicator, i.e. the smallest base the order is a power of.
To skip the multiplicator check, a factor of 1 can be specified.
This should be done to avoid using conjectural evidence.

Currently, the return value is an empty string if the small difference
uniqueness check failed and '0' if it succeeded but the multiplicator
check failed.  This may be taken as a debugging aid, but productive code
should not rely on particular false values, as future releases may have
different checks and thus no longer support the same kind of distinction.

If the conjecture that all planar difference sets have order_base as
multiplicator holds, the combined check will rather efficiently detect
most sets that aren't.  For a counterexample to the conjecture, the check
might return 2 with a high depth value and 0 with a low depth value.

Currently, the I<check_elements> method should be regarded as
experimental.  Future research might provide other, more useful check
types or parametrizations.

=item I<available>

The class method C<Math::DifferenceSet::Planar-E<gt>available(@params)>
checks whether I<new> can be called with the same parameters, i.e. either
an order C<$q> or a prime C<$p> and an exponent C<$j> indicating a
prime power order that are available from the database of PDS samples.
It returns a true value if sample sets with the given parameters are
present, otherwise false.

=item I<iterate_available_sets>

The class method
C<Math::DifferenceSet::Planar-E<gt>iterate_available_sets> returns a code
reference that, repeatedly called, returns all sample planar difference
sets known to the module, one by one.  The iterator returns a false
value when it is exhausted.

C<Math::DifferenceSet::Planar-E<gt>iterate_available_sets($lo, $hi)>
returns an iterator over all samples with orders between C<$lo> and C<$hi>
(inclusively), ordered by ascending size.  If C<$lo> is not defined,
it is taken as zero.  If C<$hi> is omitted or not defined, it is taken
as plus infinity.  If C<$lo> is greater than C<$hi>, they are swapped
and the sequence is reversed, so that it is ordered by descending size.

=item I<available_max_order>

The class method C<Math::DifferenceSet::Planar-E<gt>available_max_order>
returns the order of the largest sample planar difference set currently
known to the module.

=item I<available_count>

The class method C<Math::DifferenceSet::Planar-E<gt>available_count>
returns the number of sample planar difference sets currently known to
the module.

=item I<set_database>

Although normally set automatically behind the scenes, the database
of sample difference sets may be reset to a known alternative file
location.  C<Math::DifferenceSet::Planar-E<gt>set_database($filename)>
does this and tries to open the file for subsequent lookups.  On success,
it returns the number of available sets in the database.  On failure,
it raises an exception.

File names can be absolute paths or relative to the distribution-specific
share directory.

=item I<list_databases>

C<Math::DifferenceSet::Planar-E<gt>list_databases> returns a list of
available databases from the distribution-specific share directory,
ordered by decreasing priority.  Priority is highest for file names
beginning with "pds", and for large files.  Normal installations will
have a single database named 'pds.db'.  Installing data extensions will
result in additional databases.  It should be safe to call I<set_database>
with each of the database names returned by I<list_databases>.

=back

=head1 OBJECT METHODS

=head2 Constructors

=over 4

=item I<translate>

If C<$ds> is a planar difference set object and C<$t> is an integer
number, C<$ds-E<gt>translate($t)> returns an object representing the
translate of the set by C<$t % $ds-E<gt>modulus>.

Translating by each element of the cyclic group in turn generates
all difference sets belonging to one plane.

=item I<canonize>

If C<$ds> is a planar difference set object, C<$ds-E<gt>canonize>
returns an object representing the canonical translate of the set.
All sets of a plane yield the same set upon canonizing.  Using our
enumeration convention, an equivalent operation to canonizing is to
translate by the negative of the first or start element.

=item I<multiply>

If C<$ds> is a planar difference set object and C<$t> is an integer
number coprime to the modulus, C<$ds-E<gt>multiply($t)> returns an object
representing the difference set generated by multiplying each element
by C<$t>.

=item I<iterate_planes>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_planes>
returns a code reference that, repeatedly called, returns all canonized
planar difference sets of the same size, generated using a rotator base,
one by one.  The iterator returns a false value when it is exhausted.

=back

=head2 Property Accessors

=over 4

=item I<order>

C<$ds-E<gt>order> returns the order of the difference set C<$ds>.
This is one less than the number of its elements.

=item I<modulus>

C<$ds-E<gt>modulus> returns the size of the cyclic group the difference
set C<$ds> is a subset of.  If I<k> is the number of elements of a
planar difference set, its order is S<I<k> - 1>, and its modulus is
S<I<k>E<178> - I<k> + 1>.

=item I<elements>

C<$ds-E<gt>elements> returns all elements of the difference set as a
list, ordered as defined in L</Conventions>.  In scalar context, it
returns the number of elements.

=item I<elements_sorted>

C<$ds-E<gt>elements_sorted> returns all elements of the difference set
as a list, ordered by ascending numerical value.  In scalar context,
it returns the number of elements.

=item I<element>

C<$ds-E<gt>element($index)> is equivalent to
C<($ds-E<gt>elements)[$index]>, only more efficient.

=item I<start_element>

C<$ds-E<gt>start_element> is equivalent to C<$ds-E<gt>element(0)>.

=item I<n_planes>

C<$ds-E<gt>n_planes> returns the number of distinct planes that can
be generated from the planar difference set C<$ds> or, equivalently,
the number of elements in a rotator base of order C<$ds-E<gt>order>.

=item I<order_base>

If C<$ds> is a planar difference set object with prime power order,
C<$ds-E<gt>order_base> returns the prime.

=item I<order_exponent>

If C<$ds> is a planar difference set object with prime power order,
C<$ds-E<gt>order_exponent> returns the exponent of the prime power.

=item I<multipliers>

If C<$ds> is a planar difference set object, C<$ds-E<gt>multipliers>
returns the set of its multipliers as a list sorted by ascending numeric
value.  In scalar context, the number of multipliers is returned.

=item I<iterate_rotators>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_rotators>
returns a code reference that, repeatedly called, returns the elements
of a rotator base of the set.  The iterator returns a zero value when
it is exhausted.

=item I<find_delta>

If C<$ds> is a planar difference set object and C<$delta> is an integer
value, C<$ds-E<gt>find_delta($delta)> returns a pair of elements
C<($e1, $e2)> of the set with the property that C<$e2 - $e1 == $delta>
(modulo the modulus of the set).  If C<$delta> is not zero or a multiple
of the modulus this pair will be unique.

The unique existence of such a pair is in fact the defining quality of a
planar difference set.  The algorithm has an I<O(n)> time complexity if
I<n> is the cardinality of the set.  If it fails, the set stored in the
object is not actually a difference set.  An exception will be raised
in that case.

=item I<peak_elements>

If C<$ds> is a planar difference set object with modulus C<$modulus>,
there is a unique pair of elements C<($e1, $e2)> of the set with
maximal distance: C<$dmax = ($modulus - 1) / 2>,
and C<($e2 - $e1) % $modulus == $dmax>,
and C<($e1 - $e2) % $modulus == $dmax + 1>.
C<$ds-E<gt>peak_elements> returns the pair C<($e1, $e2)>.

Equivalently, C<$e1> and C<$e2> can be computed as:
C<($e1, $e2) = $ds-E<gt>find_delta( ($ds-E<gt>modulus - 1) / 2 )>

=item I<eta>

The prime power conjecture of planar difference sets states that any
such set has prime power order.  Another conjecture asserts that the
prime number is a multiplier of the set.  Thus multiplying the set by
the prime is equivalent to a translation.  The translation amount is
called I<eta> here and the method I<eta> returns its value.

Technically, C<$ds-E<gt>eta> is equivalent to
C<$ds-E<gt>multiply($ds-E<gt>order_base)-E<gt>element(0) >
C<- $ds-E<gt>element(0)>, wich would still be defined if one of the
conjectures was proven wrong, though not quite meaningful if the
multiplication result was on a different plane.

=item I<contains>

If C<$ds> is a planar difference set object and C<$e> an integer number,
C<$ds-E<gt>contains($e)> returns a boolean that is true if C<$e> is an
element of the set.

=back

=head1 EXAMPLES

The distribution contains an I<examples> directory with several
self-documenting command line tools for generating and manipulating
planar difference sets, and for displaying available databases.

=head1 OTHER FILES

The library is packaged together with a small SQLite version 3 database
named F<pds.db>.  This is installed in a distribution-specific F<share>
directory and accessed read-only at run-time.

The same directory can hold additional databases from extension projects.
Larger databases, as well as tools to create them, will be distributed
separately.

=head1 DIAGNOSTICS

=over 4

=item PDS(%s) not available

The class method I<new> was called with parameters this implementation
does not cover.  The parameters are repeated in the message.  To avoid
this exception, verify the parameters using the I<available> method
before calling I<new>.

=item this implementation cannot handle order %d

The class method I<from_elements> was called with a number of elements
not equal to a prime power plus one.  The number of arguments minus one
is repeated in the message.  The given arguments may or may not define a
planar difference set, but if they were (i.e. I<verify_elements> called
with the same arguments returned true), the prime power conjecture would
be proven wrong.  Many mathematical journals would certainly be keen to
publish this counter-example.  Alternatively, you may report a bug in
this module's bug tracker.  Please include all arguments.

=item element values inside range 0..%d expected

The class method I<from_elements> was called with elements that were
not normalized, i.e. integer values from zero to the modulus minus one,
or some values were too large for a difference set of the given size.
The modulus matching the number of arguments, minus one, is indicated
in the message.

=item elements of PDS expected

The class method I<from_elements> was called with values that obviously
define no planar difference set.  Note that not all cases of wrong values
will be detected this way.  Dubious values should always be verified
before they are turned into an object.

=item duplicate element: %d

The class method I<from_elements> was called with non-unique values.
One value occuring more than once is reported in the message.

=item %d: factor is not coprime to modulus

The object method I<multiply> was called with an argument that was not an
integer coprime to the modulus.  The argument is repeated in the message.
Factors not coprime to the modulus would not yield a proper difference set.

=item bogus set: delta not found: %d (mod %d)

One of the methods I<find_delta> or I<peak_elements> was called on an
object of a set lacking the required I<delta> value.  This means that
the set was not actually a difference set, which in turn means that
previously a constructor must have been called with unverified set
elements.  The delta value and the modulus are reported in the message.

=back

=head1 DEPENDENCIES

This library requires these other modules and libraries at run-time:

=over 4

=item *

L<Carp>,

=item *

L<DBD::SQLite> version 1.48 or later,

=item *

L<DBIx::Class>,

=item *

L<File::Share>,

=item *

L<File::Spec>,

=item *

L<Math::Prime::Util> version 0.59 or later.

=back

To build and install, it also needs:

=over 4

=item *

L<ExtUtils::MakeMaker> version 7.06 or later,

=item *

L<File::ShareDir::Install>,

=item *

L<File::Spec>,

=item *

L<Test::More>.

=back

The minimum required perl version is 5.10.  Some example scripts use
E<lt>E<lt>E<gt>E<gt> and thus require perl version 5.22 or later to run.

=head1 BUGS AND LIMITATIONS

As this library depends on a database with sample sets, it will not
generate arbitrarily large sets.  The database packaged with the base
module is good for sets with at most 4097 elements.  An extension by
several orders of magnitude is in preparation.  For much larger sets,
the API should presumably be changed to use PDL vectors rather than plain
perl arrays, to improve efficiency.  With 64 bit integer arithmetic it is
safe to handle sets with 21 bit order, or 42 bit modulus, or 2 million
elements.  On platforms with 32 bit perl integers, do not use sets with
more than 1290 elements.

To handle difference sets on groups other than cyclic groups, some slight
API changes would be required.  It should accept group elements as well
as small integers as arguments.  Although lacking practical examples,
this is intended to be dealt with in a future release.

The literature on difference sets, connecting algebra, combinatorics,
and geometry, is quite rich in vocabulary.  Specialized libraries like
this one can only cover a small selection of the concepts presented
there, and the nomenclature will be more consistent with some authors
than others.  The topic is also abundant with unanswered questions.

This library is provided as a calculator tool, but not claiming to prove
any of its implicit or explicit assumptions.  If you do find something
wrong or inaccurate, however, the author will be glad to be notified
about it and address the issue.

The verify_elements() method currently builds a complete operator table
in memory.  This does not scale very well in terms of either space or
time for larger sets.

Other methods for verifying difference sets are still under development.
The current version of check_elements() may be considered a first step.
As sets with multipliers are much rarer than sets with unique small
differences, multiplier checks could speed up verification considerably.
Note, however, that the multiplier check as implemented here is based
on conjectural matter and thus might inaccurately reject some sets.

Bug reports and suggestions are welcome.
Please submit them through the CPAN RT,
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-DifferenceSet-Planar>.

More information for potential contributors can be found in the file
named F<CONTRIBUTING> in this distribution.

=head1 SEE ALSO

=over 4

=item *

Math::DifferenceSet::Planar::Data - planar difference set storage.

=item *

Math::ModInt - modular integer arithmetic.

=item *

PDL - the Perl Data Language.

=item *

Moore, Emily H., Pollatsek, Harriet S., "Difference Sets", American
Mathematical Society, Providence, 2013, ISBN 978-0-8218-9176-6.

=item *

Dinitz, J.H., Stinson, D.R., "Contemporary Design Theory: A collection
of surveys", John Wiley and Sons, New York, 1992, ISBN 0-471-53141-3.

=item *

Gordon, Daniel M., "La Jolla Difference Set Repository".
https://www.dmgordon.org/diffset/

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2021 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
