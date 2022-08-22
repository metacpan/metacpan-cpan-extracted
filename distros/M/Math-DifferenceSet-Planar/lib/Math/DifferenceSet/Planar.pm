package Math::DifferenceSet::Planar;

use strict;
use warnings;
use Carp qw(croak);
use Math::DifferenceSet::Planar::Data;
use Math::BigInt try => 'GMP';
use Math::Prime::Util qw(
    is_power is_prime_power euler_phi factor_exp gcd
    mulmod addmod invmod powmod divmod
);

# Math::DifferenceSet::Planar=ARRAY(...)
# ........... index ...........     # ........... value ...........
use constant _F_ORDER      =>  0;
use constant _F_BASE       =>  1;
use constant _F_EXPONENT   =>  2;
use constant _F_MODULUS    =>  3;
use constant _F_N_PLANES   =>  4;   # number of distinct planes this size
use constant _F_ELEMENTS   =>  5;   # elements arrayref
use constant _F_ROTATORS   =>  6;   # rotators arrayref, initially empty
use constant _F_INDEX_MIN  =>  7;   # index of smallest element
use constant _F_GENERATION =>  8;   # database generation
use constant _F_LOG        =>  9;   # plane logarithm value, may be undef
use constant _F_ZETA       => 10;   # "zeta" value, initially undef
use constant _F_ETA        => 11;   # "eta" value, initially undef
use constant _F_PEAK       => 12;   # peak elements arrayref, initially undef
use constant _NFIELDS      => 13;

our $VERSION = '0.017';

our $_LOG_MAX_ORDER  = 22.1807;         # limit for integer exponentiation
our $_MAX_ENUM_COUNT = 32768;           # limit for stored rotator set size
our $_MAX_MEMO_COUNT = 4096;            # limit for memoized values
our $_DEFAULT_DEPTH  = 1024;            # default check_elements() depth
our $_USE_SPACES_DB  = 1;               # enable looking up rotators
our $_MAX_FMT_COUNT  = 5;               # elements printed in messages

my $current_data = undef;               # current M::D::P::Data object
my $generation   = 0;                   # incremented on $current_data update

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
        $x = mulmod($x, $base, $modulus);
    }
    push @mult, q[...] if $x != 1;
    die "assertion failed: not $n elements: @mult" if @mult != $n;
    return @mult;
}

# return complete rotator base if known or small enough, otherwise undef
#
# If structure is known:
#
# rotators -> +-----------+
#             | radices ----------------------------> +-------+
#             +-----------+                           |  r_1  |
#             | depths  -----------------> +-------+  +-------+
#             +-----------+                |  d_1  |  |  r_2  |
#             | inverses -----> +-------+  +-------+  +-------+
#             +-----------+     |  i_1  |  |  d_2  |  |  ...  |
#                               +-------+  +-------+  +-------+
#                               |  i_2  |  |  ...  |  |  r_n  |
#                               +-------+  +-------+  +-------+
#                               |  ...  |  |  d_n  |
#                               +-------+  +-------+
#                               |  i_n  |
#                               +-------+
#
#                         n
#                        ___      j
#   R               _    | |   r   k             0  <  j   <  d
#    j j ...j       =    | |    k      (mod M),     =   k      k
#     1 2    n
#                       k = 1
#
#         d  - 1   _
#   i  r   k       =   1  (mod M),   d   >  d   >  ...  >  d   >  2
#    k  k                             1  =   2  =       =   n  =
#
#
# Otherwise, if number of rotators is small:
#
# rotators -> +-------+-------+--   --+-------+
#             |  R_1  |  R_2  |  ...  |  R_N  |
#             +-------+-------+--   --+-------+
#
sub _rotators {
    my ($this) = @_;
    my (           $base,   $exponent,   $order,   $modulus,   $rotators) =
        @{$this}[_F_BASE, _F_EXPONENT, _F_ORDER, _F_MODULUS, _F_ROTATORS];
    return $rotators if @{$rotators};
    my $space = $_USE_SPACES_DB && $this->_data->get_space($order);
    if ($space) {
        my ($radices, $depths) = $space->rotator_space;
        my $inverses = [
            map {
                invmod(
                    powmod($radices->[$_], $depths->[$_] - 1, $modulus),
                    $modulus
                )
            } 0 .. $#{$radices}
        ];
        $rotators = $this->[_F_ROTATORS] = [$radices, $depths, $inverses];
        return $rotators;
    }
    return undef if $this->[_F_N_PLANES] > $_MAX_ENUM_COUNT;
    my @mult = _multipliers($base, $exponent, $modulus);
    my $sieve = '1' x $modulus;
    substr($sieve, $_, 1) = '0' for @mult;
    @{$rotators} = (1);
    for (my $x = 2; $x < $modulus ; ++$x) {
        if (substr $sieve, $x, 1) {
            if (0 == $modulus % $x) {
                for (my $i = $x; $i < $modulus; $i += $x) {
                    substr($sieve, $i, 1) = '0';
                }
                next;
            }
            substr($sieve, $_, 1) = '0'
                for map { mulmod($_, $x, $modulus) } @mult;
            push @{$rotators}, $x;
        }
    }
    return $rotators;
}

# iterative rotator base generator, slow, but memory efficient
sub _sequential_rotators {
    my ($this) = @_;
    my (           $base,   $exponent,   $modulus,   $n_planes) =
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
                next ELEMENT if mulmod($x, $e, $modulus) < $x;
            }
            ++$mx;
            return $x;
        }
    };
}

# structured rotator base iterator, time and space efficient
sub _structured_rotators {
    my ($this) = @_;
    my $modulus = $this->[_F_MODULUS];
    my ($radices, $depths, $inverses) = @{ $this->[_F_ROTATORS] };
    my @index = (0) x @{$radices};
    my $next = 1;
    return sub {
        return 0 if !$next;
        my $element = $next;
        my $i = 0;
        while ($i < @index) {
            if (++$index[$i] < $depths->[$i]) {
                $next = mulmod($next, $radices->[$i], $modulus);
                return $element;
            }
        }
        continue {
            $index[$i] = 0;
            $next = mulmod($next, $inverses->[$i], $modulus);
            ++$i;
        }
        $next = 0;
        return $element;
    };
}

sub _space_description {
    my ($spc) = @_;
    my $order       = $spc->order;
    my $mul_radix   = $spc->mul_radix;
    my $mul_depth   = $spc->mul_depth;
    my ($radices, $depths) = $spc->rotator_space;
    my @space = map {; "$radices->[$_]^$depths->[$_]"} 0 .. $#{$radices};
    return "$order: $mul_radix^$mul_depth [@space]";
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
# get index of smallest element (using bisection)
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
        ++$generation;
        $current_data = Math::DifferenceSet::Planar::Data->new;
    }
    return $current_data;
}

# compose a printable abbreviated description of a set
sub _fmt_set {
    my ($this) = @_;
    my @e = $this->[_F_ORDER] < $_MAX_FMT_COUNT?
        @{$this->[_F_ELEMENTS]}:
        (@{$this->[_F_ELEMENTS]}[0 .. $_MAX_FMT_COUNT-1], q[...]);
    return '{' . join(q[,], @e) . '}';
}

# identify a plane by its rotator value with respect to a given plane
# (both arguments zeta-canonized, second argument with known log)
sub _log {
    my ($this, $that) = @_;
    my $modulus = $this->[_F_MODULUS];
    my %t = ();
    foreach my $e (@{$this->[_F_ELEMENTS]}) {
        $t{$e} = 1;
    }
    my $r = 0;
    foreach my $e (@{$that->[_F_ELEMENTS]}) {
        $r = invmod($e, $modulus);
        last if $r;
    }
    my $factor = 0;
    if ($r) {
        ELEM:
        foreach my $o (@{$this->[_F_ELEMENTS]}) {
            next if !$o;
            my $ro = mulmod($r, $o, $modulus);
            foreach my $e (@{$that->[_F_ELEMENTS]}) {
                next ELEM if !exists $t{ mulmod($e, $ro, $modulus) };
            }
            $factor = $ro;
            last;
        }
    }
    else {
        my $ri = $this->iterate_rotators;
        ROT:
        while (my $ro = $ri->()) {
            foreach my $e (@{$that->[_F_ELEMENTS]}) {
                next ROT if !exists $t{ mulmod($e, $ro, $modulus) };
            }
            $factor = $ro;
            last;
        }
    }
    if ($factor) {
        my $log = $this->[_F_LOG] =
            mulmod($that->[_F_LOG], $factor, $modulus);
        return $log;
    }
    croak 'unaligned sets: ', _fmt_set($this), ' versus ', _fmt_set($that);
}

# $factor = _find_factor($ds1, $ds2);
sub _find_factor {
    my ($this, $that) = @_;
    my $order = $this->order;
    croak 'sets of same size expected' if $order != $that->order;
    my $log_this = $this->[_F_GENERATION] == $generation && $this->[_F_LOG];
    my $log_that = $this->[_F_GENERATION] == $generation && $that->[_F_LOG];
    $this->[_F_GENERATION] = $that->[_F_GENERATION] = $generation;
    if (!$log_this) {
        my $r1 = $this->zeta_canonize;
        my $r2 = $that->zeta_canonize;
        if (!$log_that) {
            my $r3 = Math::DifferenceSet::Planar->new($order)->zeta_canonize;
            $log_that = $that->[_F_LOG] = _log($r2, $r3);
        }
        $log_this = $this->[_F_LOG] =
            $this == $that? $log_that: _log($r1, $r2);
    }
    elsif (!$log_that) {
        my $r1 = $this->zeta_canonize;
        my $r2 = $that->zeta_canonize;
        $log_that = $that->[_F_LOG] = _log($r2, $r1);
    }
    return divmod($log_that, $log_this, $this->modulus);
}

# translation amount between a multiple of a set and another set
sub _delta_f {
    my ($this, $factor, $that) = @_;
    my $modulus = $this->modulus;
    my ($x)     = $this->find_delta( invmod($factor, $modulus) );
    my $s       = $that->[_F_ELEMENTS]->[0];
    return addmod($s, -mulmod($x, $factor, $modulus), $modulus);
}

# ----- class methods -----

sub list_databases {
    return Math::DifferenceSet::Planar::Data->list_databases;
}

sub set_database {
    my $class = shift;
    ++$generation;
    $current_data = Math::DifferenceSet::Planar::Data->new(@_);
    return $class->available_count;
}

# print "ok" if Math::DifferenceSet::Planar->available(9);
# print "ok" if Math::DifferenceSet::Planar->available(3, 2);
sub available {
    my ($class, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    return undef if !$order || $order > $class->_data->max_order;
    my $pds   = $class->_data->get($order, 'base');
    return !!$pds && (!defined($exponent) || $base == $pds->base);
}

# print "ok" if Math::DifferenceSet::Planar->known_space(9);
sub known_space {
    my ($class, $order) = @_;
    return 0 if $order <= 0 || $order > $class->_data->sp_max_order;
    my $spc = $class->_data->get_space($order);
    return 0 if !$spc;
    my ($rad) = $spc->rotator_space;
    return 0 + @{$rad};
}

# $desc = Math::DifferenceSet::Planar->known_space_desc(9);
sub known_space_desc {
    my ($class, $order) = @_;
    return undef if $order <= 0 || $order > $class->_data->sp_max_order;
    my $spc = $class->_data->get_space($order);
    return undef if !$spc;
    return _space_description($spc);
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
        [],                     # rotators
        0,                      # index_min
        $generation,
        1,                      # log
    ], $class;
}

# $ds = Math::DifferenceSet::Planar->from_elements_fast(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub from_elements_fast {
    my $class    = shift;
    my $order    = $#_;
    my ($base, $exponent);
    $exponent    = is_prime_power($order, \$base)
        or croak "this implementation cannot handle order $order";
    my $modulus  = ($order + 1) * $order + 1;
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
        [],                     # rotators
        $index_min,
        $generation,
    ], $class;
}

# $ds = Math::DifferenceSet::Planar->from_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub from_elements {
    my ($class, @elements) = @_;
    my $this = $class->from_elements_fast(@elements);
    my $ref  = $class->new(@elements - 1);
    eval { _find_factor($ref, $this) } or
        croak "apparently not a planar difference set: ", _fmt_set($this);
    return $this;
}

# $bool = Math::DifferenceSet::Planar->verify_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub verify_elements {
    my ($class, @elements) = @_;
    my $order   = $#elements;
    return undef if $order <= 1;
    my $modulus = ($order + 1) * $order + 1;
    my $median  = ($modulus - 1) / 2;
    my $seen    = '0' x $median;
    foreach my $r1 (@elements) {
        return undef if $r1 < 0 || $modulus <= $r1 || $r1 != int $r1;
        foreach my $r2 (@elements) {
            last if $r1 == $r2;
            my $d = $r1 < $r2? $r2 - $r1: $modulus + $r2 - $r1;
            $d = $modulus - $d if $d > $median;
            return !1 if substr($seen, $d-1, 1)++;
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
    my $modulus      = ($order + 1) * $order + 1;
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
            map { mulmod($_, $factor, $modulus) } @elements
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
            [],                 # rotators
            0,                  # index_min
            $generation,
            1,                  # log
        ], $class;
    };
}

# $min = Math::DifferenceSet::Planar->available_min_order;
sub available_min_order   { $_[0]->_data->min_order }

# $max = Math::DifferenceSet::Planar->available_max_order;
sub available_max_order   { $_[0]->_data->max_order }

# $count = Math::DifferenceSet::Planar->available_count;
sub available_count       { $_[0]->_data->count }

# $min = Math::DifferenceSet::Planar->known_space_min_order;
sub known_space_min_order { $_[0]->_data->sp_min_order }

# $max = Math::DifferenceSet::Planar->known_space_max_order;
sub known_space_max_order { $_[0]->_data->sp_max_order }

# $count = Math::DifferenceSet::Planar->known_space_count;
sub known_space_count     { $_[0]->_data->sp_count }

# $it3 = Math::DifferenceSet::Planar->iterate_known_spaces;
# $it3 = Math::DifferenceSet::Planar->iterate_known_spaces(10,20);
# while (my $spc = $it3->()) {
#   print "$spc\n";
# }
sub iterate_known_spaces {
    my ($class, @minmax) = @_;
    my $dit = $class->_data->iterate_spaces(@minmax);
    return sub {
        my $spc = $dit->();
        return undef if !$spc;
        return _space_description($spc);
    };
}

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
    $delta %= $modulus unless -$modulus < $delta && $delta < $modulus;
    return $this if !$delta;
    my @elements =
        map { addmod($_, $delta, $modulus) } @{$this->[_F_ELEMENTS]};
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS]  = \@elements;
    $that->[_F_INDEX_MIN] =
        $elements[0] < $elements[-1]? 0: _index_min(\@elements);
    if (defined (my $z = $that->[_F_ZETA])) {
        $that->[_F_ZETA] = addmod($z,
            mulmod($delta, $this->[_F_ORDER]-1, $modulus), $modulus);
    }
    if (defined (my $e = $that->[_F_ETA])) {
        $that->[_F_ETA] = addmod($e,
            mulmod($delta, $this->[_F_BASE]-1, $modulus), $modulus);
    }
    return $that;
}

# $ds2 = $ds->canonize;
sub canonize { $_[0]->translate(- $_[0]->[_F_ELEMENTS]->[0]) }

# $ds2 = $ds->gap_canonize;
sub gap_canonize {
    my ($this) = @_;
    my $delta = ($this->largest_gap)[1];
    return $this->translate(-$delta);
}

# $ds2 = $ds->zeta_canonize;
sub zeta_canonize {
    my ($this) = @_;
    my $zeta    = $this->zeta;
    my $order   = $this->order;
    my $modulus = $this->modulus;
    if ( ($order - 1) % 3 ) {
        return $this if !$zeta;
        my $delta = divmod($zeta, $order - 1, $modulus);
        return $this->translate(-$delta);
    }
    return $this if !$zeta && !$this->contains(0);
    $modulus /= 3;
    my $delta = divmod($zeta, $order - 1, $modulus);
    $delta += $modulus while $this->contains($delta);   # 0..2 iterations
    return $this->translate(-$delta);
}

# $it  = $ds->iterate_rotators;
# while (my $m = $it->()) {
#   ...
# }
sub iterate_rotators {
    my ($this) = @_;
    my $rotators = $this->_rotators;
    return $this->_sequential_rotators if !$rotators;
    return $this->_structured_rotators if 'ARRAY' eq ref $rotators->[0];
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
    return $this if 1 == $factor;
    croak "$_[1]: factor is not coprime to modulus"
        if gcd($modulus, $factor) != 1;
    my ($elements, $index_min) = _sort_elements(
        $modulus,
        map { mulmod($_, $factor, $modulus) } @{$this->[_F_ELEMENTS]}
    );
    my $that = bless [@{$this}], ref $this;
    $that->[_F_ELEMENTS ] = $elements;
    $that->[_F_INDEX_MIN] = $index_min;
    if (defined(my $log = $that->[_F_LOG])) {
        $that->[_F_LOG] = mulmod($log, $factor, $modulus);
    }
    $that->[_F_ZETA] &&= mulmod($that->[_F_ZETA], $factor, $modulus);
    $that->[_F_ETA]  &&= mulmod($that->[_F_ETA],  $factor, $modulus);
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
    my $bogus = 0;
    while ($c != $de) {
        if ($c < $de) {
            if(++$ux > $order) {
                $ux = 0;
            }
            $ue = $elements->[$ux];
            $bogus = 1, last if $ux == $lx;
        }
        else {
            $bogus = 1, last if ++$lx > $order;
            $le = $elements->[$lx];
        }
        $c = $ue < $le? $modulus + $ue - $le: $ue - $le;
    }
    croak "bogus set: delta not found: $delta (mod $modulus)" if $bogus;
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

# ($e1, $e2, $delta) = $ds->largest_gap;
sub largest_gap {
    my ($this) = @_;
    my $modulus = $this->modulus;
    my $p_max;
    my $e_max;
    my $d_max = 0;
    my $e_pre = $this->element($this->order);
    foreach my $e ($this->elements) {
        my $d = $e - $e_pre;
        $d += $modulus if $d < 0;
        if ($d > $d_max) {
            $d_max = $d;
            $p_max = $e_pre;
            $e_max = $e;
        }
        $e_pre = $e;
    }
    return ($p_max, $e_max, $d_max);
}

# $e = $ds->zeta
sub zeta {
    my ($this) = @_;
    my $zeta = $this->[_F_ZETA];
    if (!defined $zeta) {
        my $order   = $this->[_F_ORDER];
        my $modulus = $this->[_F_MODULUS];
        my $start   = $this->[_F_ELEMENTS]->[0];
        (undef, my $x) = $this->find_delta($order + 1);
        $zeta = $this->[_F_ZETA] =
            addmod(mulmod($x, $order, $modulus), -$start, $modulus);
    }
    return $zeta;
}

# $e = $ds->eta
sub eta {
    my ($this) = @_;
    return $this->zeta if $this->[_F_EXPONENT] == 1;
    my $eta = $this->[_F_ETA];
    if (!defined $eta) {
        my $p   = $this->[_F_BASE];
        my $m   = $this->[_F_MODULUS];
        my $s   = $this->[_F_ELEMENTS]->[0];
        my ($x) = $this->find_delta( invmod($p, $m) );
        $eta = $this->[_F_ETA] = addmod(mulmod($x, $p, $m), -$s, $m);
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

# $cmp = $ds1->compare($ds2);
sub compare {
    my ($this, $that) = @_;
    my $order = $this->order;
    my $cmp   = $order <=> $that->order;
    return $cmp if $cmp;
    my $lx = $this->[_F_INDEX_MIN];
    my $rx = $that->[_F_INDEX_MIN];
    my $le = $this->[_F_ELEMENTS];
    my $re = $that->[_F_ELEMENTS];
    foreach my $i (0 .. $order) {
        $cmp = $le->[$lx] <=> $re->[$rx];
        return $cmp if $cmp;
        ++$lx <= $order or $lx = 0;
        ++$rx <= $order or $rx = 0;
    }
    return 0;
}

# $bool = $ds1->same_plane($ds2);
sub same_plane {
    my ($this, $that) = @_;
    my $order = $this->order;
    return !1 if $order != $that->order;
    my $le = $this->[_F_ELEMENTS];
    my $re = $that->[_F_ELEMENTS];
    my $delta0 = $re->[0] - $le->[0];
    if (!$delta0) {
        foreach my $x (1 .. $order) {
            return !1 if $re->[$x] != $le->[$x];
        }
        return !0;
    }
    my $modulus = $this->modulus;
    my $delta1  = $delta0 < 0? $delta0 + $modulus: $delta0 - $modulus;
    foreach my $x (1 .. $order) {
        my $delta = $re->[$x] - $le->[$x];
        return !1 if $delta != $delta0 && $delta != $delta1;
    }
    return !0;
}

# @e = $ds1->common_elements($ds2);
sub common_elements {
    my ($this, $that) = @_;
    my $order = $this->order;
    my @common = ();
    return @common if $order != $that->order;
    my $li = 0;
    my $ri = 0;
    my $lx = $this->[_F_INDEX_MIN];
    my $rx = $that->[_F_INDEX_MIN];
    my $le = $this->[_F_ELEMENTS];
    my $re = $that->[_F_ELEMENTS];
    my $lv = $le->[$lx];
    my $rv = $re->[$rx];
    while (1) {
        my $cmp = $lv <=> $rv;
        push @common, $lv if !$cmp;
        if ($cmp <= 0) {
            ++$lx <= $order or $lx = 0;
            last if ++$li > $order;
            $lv = $le->[$lx];
        }
        if ($cmp >= 0) {
            ++$rx <= $order or $rx = 0;
            last if ++$ri > $order;
            $rv = $re->[$rx];
        }
    }
    return @common;
}

# ($factor, $delta) = $ds1->find_linear_map($ds2);
sub find_linear_map {
    my ($this, $that) = @_;
    my $factor = _find_factor($this, $that);
    my $delta  = _delta_f($this, $factor, $that);
    return ($factor, $delta);
}

# @factor_delta_pairs = $ds1->find_all_linear_maps($ds2);
sub find_all_linear_maps {
    my ($this, $that) = @_;
    my $f1 = eval { _find_factor($this, $that) };
    return () if !defined $f1;
    my $modulus = $this->modulus;
    return
        sort { $a->[0] <=> $b->[0] }
        map {
            my $f = mulmod($f1, $_, $modulus);
            my $d = _delta_f($this, $f, $that);
            [$f, $d]
        } $this->multipliers;
}

1;
__END__

=encoding utf8

=head1 NAME

Math::DifferenceSet::Planar - object class for planar difference sets

=head1 VERSION

This documentation refers to version 0.017 of Math::DifferenceSet::Planar.

=head1 SYNOPSIS

  use Math::DifferenceSet::Planar;

  $ds = Math::DifferenceSet::Planar->new(9);
  $ds = Math::DifferenceSet::Planar->new(3, 2);
  $ds = Math::DifferenceSet::Planar->from_elements(
    0, 1, 3, 9, 27, 49, 56, 61, 77, 81
  );
  $ds = Math::DifferenceSet::Planar->from_elements_fast(
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

  ($e1, $e2)         = $ds->find_delta($delta);
  ($e1, $e2)         = $ds->peak_elements;
  ($e1, $e2)         = $ds->find_delta(($ds->modulus - 1) / 2);
  ($e1, $e2, $delta) = $ds->largest_gap;
  $eta               = $ds->eta;
  $zeta              = $ds->zeta;
  $bool              = $ds->contains($e1);

  $ds1 = $ds->translate(1);
  $ds2 = $ds->canonize;
  $ds2 = $ds->translate(- $ds->element(0)); # equivalent
  $ds2 = $ds->gap_canonize;
  $ds2 = $ds->zeta_canonize;
  @pm  = $ds->multipliers;
  $it  = $ds->iterate_rotators;
  while (my $m = $it->()) {
    $ds3 = $ds->multiply($m)->canonize;
  }
  $it = $ds->iterate_planes;
  while (my $ds3 = $it->()) {
    # as above
  }

  $cmp  = $ds1->compare($ds2);
  $bool = $ds1->same_plane($ds2);
  @e    = $ds1->common_elements($ds2);

  ($factor, $delta) = $ds1->find_linear_map($ds2);
  # $ds2 == $ds1->multiply($factor)->translate($delta)
  foreach my $fd ( $ds1->find_all_linear_maps($ds2) ) {
    my ($factor, $delta) = @{$fd};
    # as above
  }

  $r  = Math::DifferenceSet::Planar->check_elements(    # DEPRECATED
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
  $min   = Math::DifferenceSet::Planar->available_min_order;
  $max   = Math::DifferenceSet::Planar->available_max_order;
  $count = Math::DifferenceSet::Planar->available_count;

  print "ok" if Math::DifferenceSet::Planar->known_space(9);
  $desc = Math::DifferenceSet::Planar->known_space_desc(9);
  $min = Math::DifferenceSet::Planar->known_space_min_order;
  $max = Math::DifferenceSet::Planar->known_space_max_order;
  $count = Math::DifferenceSet::Planar->known_space_count;
  $it3 = Math::DifferenceSet::Planar->iterate_known_spaces;
  $it3 = Math::DifferenceSet::Planar->iterate_known_spaces(10,20);

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
set.  If S<D E<183> t> is a translate of D, t is called a multiplier
of D.  If t is coprime to n but either identical to 1 (mod n) or not a
multiplier, it is called a rotator.  Rotators of planar difference sets
are also rotators of planes as translates of a difference set are mapped
to translates of the rotated set.  We call a minimal set of rotators
spanning all plane rotations a rotator base.  A perhaps more commonly
used term would be complete residue system.

Math::DifferenceSet::Planar provides examples of small cyclic planar
difference sets constructed from finite fields.  It is primarily intended
as a helper module for algorithms employing such sets.  It also allows
to iterate over all sets of a given size via translations and rotations,
and to verify whether an arbitrary set of modular integers is a cyclic
planar difference set.

Currently, only sets with k E<8804> 4097, or moduli E<8804> 16,781,313,
are supported by the CPAN distribution of the module.  These limits can
be extended by installing a database with more samples.  Instructions on
where to obtain additional data will be included in an upcoming release.
The database with orders up to 2E<185>E<8311> requires 2 GB of storage
space, while the default database only occupies 2.5 MB.

We work with pre-computed data for lack of super-efficient generators.
Difference sets can be generated with O(I<kE<178>>) operations with order
3 polynomials in an order I<k> Galois field, which means only polynomial
complexity, but still more than would be practical to perform at runtime.
Getting rid of the databases will require better algorithms.

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

Each plane (i.e. complete set of translates of a planar difference set)
has a unique set containing the elements 0 and 1.  We call this set the
canonical representative of the plane.  The canonical representative is
also the lexically first set of its plane when sorted with priority on
small elements.

Each planar difference set has, for each nonzero element I<delta>
of its ring E<8484>_n, a unique pair of elements S<(I<e1>, I<e2>)>
satisfying S<I<e2> - I<e1> = I<delta>>.  For S<I<delta> = 1>, we call
I<e1> the start element.  For S<I<delta> = (I<n> - 1) / 2>, we call I<e1>
and I<e2> the peak elements.

Sets of a plane could also be sorted lexically with priority on
large elements.  The first set in that ordering is the one with
the largest gap between consecutive elements just left of zero.
We call this set gap-canonical.

As divisors of the order, like I<order_base> and I<order> itself, are
always multipliers, multiplying a planar difference set by I<order_base>
or I<order> will yield translations of the original set.  The translation
amount upon multiplying a set with its I<order_base> or with its I<order>
we call I<eta> or I<zeta>, respectively.

If I<eta> is zero, so is I<zeta>, and every plane has at least one
such set.  With some additional condition for uniqueness this yields
another kind of choice of a canonical representative.  This library
provides it by the name of I<zeta_canonize>.

Yet another conjecture asserts that for any two planar difference sets
of the same order there is a linear function mapping one of them to
the other.  This is relevant for some of the algorithms implemented here.
Notably, it gives rise to the notion of a "logarithm" identifying sets or
planes by their linear relationship with some reference set.  If there
was a consensus among researchers on the choice of a reference set and
of a particular solution from the solution space of the linear equation,
math libraries could identify any such set by only two uniquely chosen
numbers and be interoperable.

Such a convention would be an analogy for planar difference sets to what
Conway polynomials are for finite fields.  The choice, however, is not an
easy one.  A major disadvantage of Conway polynomials is that, for large
orders, they are computationally expensive (read: practically impossible)
to obtain.  All candidates for reference sets, so far, including some
actually based on Conway polynomials, seem to share this disadvantage.

Thus, this library makes use of linear mappings without exposing their
"logarithm" aspect.  We prefer to postpone any suggestion for this
standardization until we are confident it is economically preferable.
The library offers methods to find linear mappings between arbitrary sets,
so users can pick their own reference sets and treat linear mappings
relative to them as absolute.

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

The modulus itself is not a parameter, as it can be computed from the
number I<k> of arguments as S<I<m> = I<k>E<178> - I<k> + 1>.

Improper arguments, such as lists of numbers not actually defining a
planar difference set, will cause I<from_elements> to raise an exception
either immediately rejecting the arguments or from failing initial checks.
Note also that this method expects elements to be normalized, i.e. integer
values from zero to the modulus minus one.

=item I<from_elements_fast>

The method I<from_elements_fast> is an alternative to I<from_elements>
that may be used if the arguments are known to be correct.  Arguments not
verified to define a planar difference set may yield a broken object
with undefined behaviour, though.  You have been warned.

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

DEPRECATED.  OBSOLETE.  Since an efficient and conclusive check is
now integrated in the I<from_elements> method, checking elements with
incomplete evidence is now almost pointless.  This method will be removed
in release 1.0.

From the original documentation:

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
correct and undef if it is not even a set of distinct non-negative
integers of appropriate size.

An optional third argument I<$factor> controls the check whether the given
factor is a multiplier.  For planar difference sets this module generates,
I<order_base> is indeed a multiplier.  Thus this combined check should
give a good heuristic whether a given set is actually representing a
planar difference set related to a finite field like the ones generated
by this module.

If the factor is not specified, the check will be performed with a
suitable multiplier, i.e. the smallest base the order is a power of.
To skip the multiplier check, a factor of 1 can be specified.
This should be done to avoid using conjectural evidence.

Currently, the return value is an empty string if the small difference
uniqueness check failed and '0' if it succeeded but the multiplier
check failed.  This may be taken as a debugging aid, but productive code
should not rely on particular false values, as future releases may have
different checks and thus no longer support the same kind of distinction.

If the conjecture that all planar difference sets have order_base as
multiplier holds, the combined check will rather efficiently detect
most sets that aren't.  For a counterexample to the conjecture, the check
might return 2 with a high depth value and 0 with a low depth value.

End quote.

Before it was deprecated, the I<check_elements> method in general and
its parametrizations in particular were already flagged as experimental.

Progress has indeed been made by replacing the non-conclusive multiplier
check by the conclusive linear mapping check: The conjecture that any two
sets of same order can be mapped to each other with a linear function, and
an efficient way to find such a function, now constitute a very practical
verification of Singer type difference sets.  It is considered cheap
enough to run that it is now included in the I<from_elements> constructor.

The assumption that all planar difference sets are of this type, however,
which has lead to the initial scope of this library, should still not be
taken for granted.  This means the whole library may well be incomplete
in this regard and fail to handle valid sets.  The only exception is
the I<verify_elements> method, at the price of unpleasantly poor
performance.  To make progress here, some more research is needed.
Contributions are welcome.

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

=item I<available_min_order>

The class method C<Math::DifferenceSet::Planar-E<gt>available_min_order>
returns the order of the smallest sample planar difference set currently
known to the module.

=item I<available_max_order>

The class method C<Math::DifferenceSet::Planar-E<gt>available_max_order>
returns the order of the largest sample planar difference set currently
known to the module.

=item I<available_count>

The class method C<Math::DifferenceSet::Planar-E<gt>available_count>
returns the number of sample planar difference sets currently known to
the module.

=item I<known_space>

The class method C<Math::DifferenceSet::Planar-E<gt>known_space($order)>
returns a positive integer if pre-computed rotator space information for
order C<$order> is available to the module, otherwise zero.  Currently,
in case of availability, the integer number is the number of radices
used for difference set plane enumeration.  For sets with known space,
I<iterate_planes> and I<iterate_rotators> will be more efficient than
otherwise.

The precise meaning of non-zero values returned by I<known_space> is
implementation specific and should not be relied upon.

=item I<known_space_desc>

The class method
C<Math::DifferenceSet::Planar-E<gt>known_space_desc($order)> returns a
descriptive string if pre-computed rotator space information for order
C<$order> is available to the module, otherwise undef.

The precise meaning of strings returned by I<known_space_desc> is
implementation specific and should not be relied upon.  They are intended
for documentation rather than further processing.

=item I<iterate_known_spaces>

The class method C<Math::DifferenceSet::Planar-E<gt>iterate_known_spaces>
returns a code reference that, repeatedly called, returns descriptions
of all pre-computed rotator spaces known to the module, one by one.
The iterator returns a false value when it is exhausted.

C<Math::DifferenceSet::Planar-E<gt>iterate_known_spaces($lo, $hi)>
returns an iterator over all pre-computed spaces with orders between
C<$lo> and C<$hi> (inclusively), ordered by ascending size.  If C<$lo> is
not defined, it is taken as zero.  If C<$hi> is omitted or not defined,
it is taken as plus infinity.  If C<$lo> is greater than C<$hi>, they
are swapped and the sequence is reversed, so that it is ordered by
descending size.

The strings returned by the iterators are the same as if obtained by
I<known_space_desc>.

=item I<known_space_min_order>

The class method C<Math::DifferenceSet::Planar-E<gt>known_space_min_order>
returns the smallest order of pre-computed rotator space information
available to the module, if any, otherwise C<undef>.

=item I<known_space_max_order>

The class method C<Math::DifferenceSet::Planar-E<gt>known_space_max_order>
returns the maximum order of pre-computed rotator space information
available to the module, if any, otherwise zero.

=item I<known_space_count>

The class method C<Math::DifferenceSet::Planar-E<gt>known_space_count>
returns the number of records of pre-computed rotator space information
available to the module, for statistics.

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
translate of the set by C<$t>.

Translating by each element of the cyclic group in turn generates
all difference sets belonging to one plane.

=item I<multiply>

If C<$ds> is a planar difference set object and C<$t> is an integer
number coprime to the modulus, C<$ds-E<gt>multiply($t)> returns an object
representing the difference set generated by multiplying each element
by C<$t>.

=item I<canonize>

If C<$ds> is a planar difference set object, C<$ds-E<gt>canonize> returns
an object representing the canonical translate of the set.  All sets
of a plane yield the same set upon canonizing.  Using our enumeration
convention, an equivalent operation to canonizing is to translate by
the negative of the start element.  The canonical representative of a
plane is also its lexicographically first set when sets are compared
element-wise from smallest to largest element.

=item I<gap_canonize>

If C<$ds> is a planar difference set object, C<$ds-E<gt>gap_canonize>
returns an object representing the translate of the set with the
largest gap placed so that it is followed by zero.  This is also
the lexicographically first set of the plane when sets are compared
element-wise from largest to smallest element.

=item I<zeta_canonize>

If C<$ds> is a planar difference set object, C<$ds-E<gt>zeta_canonize>
returns an object representing the unique translate of the set defined
as follows: If the plane has only one set with I<zeta> equal to zero,
take this.  Otherwise, from the three sets with I<zeta> equal to zero,
take the set not containing the element zero.  Here, I<zeta> means the
translation amount when the set is multiplied by its order, which always
is a multiplier (see below).

=item I<iterate_planes>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_planes>
returns a code reference that, repeatedly called, returns all canonized
planar difference sets of the same size, generated using a rotator base,
one by one.  The first set returned will be on the same plane as the
invocant.  The iterator returns a false value when it is exhausted.

The succession of sets returned by I<iterate_planes>, after the first
set, may come in any implementation-specific order.  If I<iterate_planes>
is repeatedly called within one program run and while the rotator space
database is not changed, the same difference set will always yield the
same sequence of planes, however.  Multiple iterators will each have an
individual state and run independently, even if generated from the same
sample difference set.

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

The unique existence of such a pair is in fact the defining quality of
a planar difference set.  The algorithm has an I<O(n)> time complexity
if I<n> is the cardinality of the set.  It may fail if the set stored
in the object is not actually a difference set.  An exception will be
raised in that case.

=item I<peak_elements>

If C<$ds> is a planar difference set object with modulus C<$modulus>,
there is a unique pair of elements C<($e1, $e2)> of the set with
maximal distance: C<$dmax = ($modulus - 1) / 2>,
and C<($e2 - $e1) % $modulus == $dmax>,
and C<($e1 - $e2) % $modulus == $dmax + 1>.
C<$ds-E<gt>peak_elements> returns the pair C<($e1, $e2)>.

Equivalently, C<$e1> and C<$e2> can be computed as:
C<($e1, $e2) = $ds-E<gt>find_delta( ($ds-E<gt>modulus - 1) / 2 )>

=item I<largest_gap>

If C<$ds> is a planar difference set object with modulus C<$modulus>,
there is a unique pair of consecutive elements C<($e1, $e2)> of the set,
when sorted by residue value and repeated cyclically, with the largest
difference modulo the modulus.

For example, the set I<{3, 4, 6} (mod 7)> has increases of I<{1, 2, 4}>
with the largest increase I<4> between the elements I<6> and I<3>
(wrapping around).

C<$ds-E<gt>largest_gap> returns both elements C<($e1, $e2)> and the
increase amount C<($e2 - $e1) % $ds-E<gt>modulus> called C<$delta>.
The number of modular integers not in the set between two consecutive
elements of the set is called their gap.  This gap can be calculated as
C<$delta - 1>.

=item I<eta>

The sets provided by this module have prime power order and thus the prime
is a divisor of the order and a multiplier.  This means, multiplying
the set by the prime is equivalent to a translation.  The translation
amount is called I<eta> here and the method I<eta> returns its value.

=item I<zeta>

The translation amount from multiplying a set by its order is called
I<zeta> here, and the method I<zeta> returns its value.  For sets with
prime order, I<zeta> and I<eta> are of course equal.

=back

=head2 Binary Operators

=over 4

=item I<contains>

If C<$ds> is a planar difference set object and C<$e> an integer number,
C<$ds-E<gt>contains($e)> returns a boolean that is true if C<$e> is an
element of the set.

Note that C<$e> has to be in the range of zero to the modulus minus
one to be found, as modular integers are represented by their standard
residue values throughout this library.

=item I<compare>

If C<$ds1> and C<$ds2> are planar difference set objects,
C<$ds1-E<gt>compare($ds2)> returns a comparison value less than zero,
zero, or greater than zero, if C<$ds1> precedes, is equal, or follows
C<$ds2> according to this order relation: Smaller sets before larger sets,
sets of equal size in lexicographic order when written from smallest to
largest element and compared element-wise left to right.

Example: I<{0, 4, 5} E<lt> {1, 2, 4} E<lt> {1, 2, 6} E<lt> {0, 1, 3, 9}>.

=item I<same_plane>

If C<$ds1> and C<$ds2> are planar difference set objects,
C<$ds1-E<gt>same_plane($ds2)> returns a boolean value of true if C<$ds2>
is a translate of C<$ds1>, otherwise false.  If they do, they will have
either precisely one element or all elements in common and the translation
amount will be equal to the difference of their start elements.

=item I<common_elements>

If C<$ds1> and C<$ds2> are planar difference set objects of equal order,
C<$ds1-E<gt>common_elements($ds2)> returns a list of elements that are in
both sets.  For sets of different size, an empty list will be returned.
In scalar context, the length of the list will be returned.

=item I<find_linear_map>

If C<$ds1> and C<$ds2> are planar difference set objects
of equal order, C<$ds1-E<gt>find_linear_map($ds2)> returns
two values C<$factor> and C<$delta> with the property that
C<$ds1-E<gt>multiply($factor)-E<gt>translate($delta)> will be equal
to C<$ds2>.  It is conjectured that this is always possible.  For sets
of different size, or if the arguments constitute a counterexample to
the conjecture, exceptions will be raised.

Note that the solution will not be unique and may depend on circumstances
not easy to predict.

=item I<find_all_linear_maps>

If C<$ds1> and C<$ds2> are planar difference set objects of equal order,
C<$ds1-E<gt>find_all_linear_maps($ds2)> returns a list of arrayrefs
holding two values C<$factor> and C<$delta> each, with the property
that C<$ds1-E<gt>multiply($factor)-E<gt>translate($delta)> will be equal
to C<$ds2>.  It is conjectured that this is always possible.  For sets
of different size, or if the arguments constitute a counterexample to
the conjecture, an empty list will be returned.

The pairs in the result will be sorted in ascending order by their
first component.

Technically, the list will be created using I<find_linear_map> and
I<multipliers>.  The completeness of the solution space thus depends on
the I<3n multipliers> conjecture, asserting that each set has precisely
I<3E<183>n> multipliers.

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

=item apparently not a planar difference set: %s

The class method I<from_elements> was called with values that apparently
define no planar difference set.  Note that this verdict might be
incorrect if the linear mapping conjecture turned out to be wrong, when
verifying a counterexample, but it will be correct with all actually
wrong sets.

You can override the internal linear mapping check by using
I<from_elements_fast> in place of I<from_elements>.  Unverified sets
may yield broken objects with inconsistent behaviour, though.

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

=item sets of same size expected

One of the methods I<find_linear_map> or I<find_all_linear_maps> was
called with two sets of different size.  Linear map functions can only
exist for sets with equal size.

=item unaligned sets: %s versus %s

One of the methods I<find_linear_map> or I<find_all_linear_maps>
surprisingly did not succeed.  This would prove another conjecture wrong,
or, more likely, indicate one of the objects was created from elements not
actually representing a valid planar difference set.  Abbreviated element
lists of two difference sets are included in the message.  For technical
reasons, these may be translates of the original invocants.

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

Bug reports and suggestions are welcome.
Please submit them through the github issue tracker,
L<https://github.com/mhasch/perl-Math-DifferenceSet-Planar/issues>.

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

Copyright (c) 2019-2022 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
