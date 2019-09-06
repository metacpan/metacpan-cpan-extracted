package Math::DifferenceSet::Planar;

use strict;
use warnings;
use Carp qw(croak);
use Math::DifferenceSet::Planar::Data;
use Math::Prime::Util qw(is_prime_power euler_phi factor_exp gcd);

# Math::DifferenceSet::Planar=ARRAY(...)
# ........... index ...........     # ........... value ...........
use constant _F_ORDER     => 0;
use constant _F_BASE      => 1;
use constant _F_EXPONENT  => 2;
use constant _F_MODULUS   => 3;
use constant _F_N_PLANES  => 4;     # number of distinct planes this size
use constant _F_ELEMENTS  => 5;     # elements arrayref
use constant _F_ROTATORS  => 6;     # rotators arrayref, initially empty
use constant _NFIELDS     => 7;

our $VERSION = '0.007';

our $_MAX_ENUM_COUNT = 32768;
our $_LOG_MAX_ORDER = 21 * log(2);

my $DATA = undef;

my %memo_n_planes = ();

# ----- private subroutines -----

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

# small integer exponentiation
sub _pow {
    my ($base, $exponent) = @_;
    return 0 if !$base || log(0+$base) * $exponent >= $_LOG_MAX_ORDER;
    my $power = 1;
    while ($exponent) {
        $power *= $base if 1 & $exponent;
        $exponent >>= 1 and $base *= $base;
    }
    return $power;
}

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
    croak "elements of PDS expected" if $mx >= @elements;
    $mx += @elements if !$mx--;
    push @elements, splice @elements, 0, $mx if $mx;
    return \@elements;
}

sub _elements_from_deltas {
    my $sum = 0;
    my @elements = map { $sum += $_ } 0, 1, split / /, $_[0];
    return \@elements;
}

sub _data {
    if (!defined $DATA) {
        $DATA = Math::DifferenceSet::Planar::Data->new;
    }
    return $DATA;
}

# ----- class methods -----

sub list_databases {
    return Math::DifferenceSet::Planar::Data->list_databases;
}

sub set_database {
    my $class = shift;
    $DATA = Math::DifferenceSet::Planar::Data->new(@_);
    return $class->available_count;
}

# print "ok" if Math::DifferenceSet::Planar->available(9);
# print "ok" if Math::DifferenceSet::Planar->available(3, 2);
sub available {
    my ($class, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    my $pds = $order && $class->_data->get(
        $order, 'base'
    );
    return !!$pds && (!defined($exponent) || $base == $pds->base);
}

# $ds = Math::DifferenceSet::Planar->new(9);
# $ds = Math::DifferenceSet::Planar->new(3, 2);
sub new {
    my ($class, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    my $pds = $order && $class->_data->get($order);
    if (!$pds || defined($exponent) && $base != $pds->base) {
        my $key = defined($exponent)? "$base, $exponent": $order;
        croak "PDS($key) not available";
    }
    my $elements = _elements_from_deltas($pds->deltas);
    return bless [
        $pds->order,
        $pds->base,
        $pds->exponent,
        $pds->modulus,
        $pds->n_planes,
        $elements,
        [],
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
    my $elements = _sort_elements($modulus, @_);
    my $n_planes =
        $memo_n_planes{$order} ||= euler_phi($modulus) / (3 * $exponent);
    return bless [
        $order,
        $base,
        $exponent,
        $modulus,
        $n_planes,
        $elements,
        [],
    ], $class;
}

# $ds = Math::DifferenceSet::Planar->verify_elements(
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
        my $elements = _elements_from_deltas($pds->deltas);
        return bless [
            $pds->order,
            $pds->base,
            $pds->exponent,
            $pds->modulus,
            $pds->n_planes,
            $elements,
            [],
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

#      0  1  2  3  4  5  6  7
#     28 29 31 41  3  7 14 25 
#      L        X           H
#                  L  X     H
#                 LX  H
sub elements_sorted {
    my ($this) = @_;
    my $elements = $this->[_F_ELEMENTS];
    return @$elements if !wantarray;
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
    return @{$elements}[$hx .. $#$elements, 0 .. $hx - 1];
}

# $ds1 = $ds->translate(1);
sub translate {
    my ($this, $delta) = @_;
    my $modulus = $this->[_F_MODULUS];
    $delta %= $modulus;
    return $this if !$delta;
    my @elements = map { ($_ + $delta) % $modulus } @{$this->[_F_ELEMENTS]};
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS] = \@elements;
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
    my $elements = _sort_elements(
        $modulus,
        map { $_ * $factor % $modulus } @{$this->[_F_ELEMENTS]}
    );
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS] = $elements;
    return $that;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::DifferenceSet::Planar - object class for planar difference sets

=head1 VERSION

This documentation refers to version 0.007 of Math::DifferenceSet::Planar.

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
  $np = $ds->n_planes;
  $p  = $ds->order_base;
  $n  = $ds->order_exponent;

  $ds1 = $ds->translate(1);
  $ds2 = $ds->canonize;
  $ds2 = $ds->translate(- $ds->element(0));
  @pm  = $ds->multipliers;
  $it  = $ds->iterate_rotators;
  while (my $m = $it->()) {
    $ds3 = $ds->multiply($m)->canonize;
  }
  $it = $ds->iterate_planes;
  while (my $ds3 = $it->()) {
    # as above
  }

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

=head1 CLASS VARIABLE

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
false value.  Note that this check is somewhat expensive, but should
work regardless of the method the set was constructed by.  It may thus
be used to verify cyclic planar difference sets this module would not
be capable of generating itself.

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
translate by the negative of the first element.

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

=back

=head1 BUGS AND LIMITATIONS

As this library depends on a database with sample sets, it will not
generate arbitrarily large sets.  The database packaged with the base
module is good for sets with at most 4097 elements.  An extension
by factor 16 is in preparation.  For much larger sets, the API should
presumably be changed to use PDL vectors rather than plain perl arrays,
to improve efficiency.

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

Copyright (c) 2019 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
