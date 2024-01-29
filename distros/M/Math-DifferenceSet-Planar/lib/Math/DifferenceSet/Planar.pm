package Math::DifferenceSet::Planar;

use strict;
use warnings;
use Carp qw(croak);
use Math::DifferenceSet::Planar::Data;
use Math::Prime::Util qw(
    is_prime is_power is_prime_power euler_phi factor_exp gcd
    mulmod addmod invmod powmod divmod logint
);

# Math::DifferenceSet::Planar=ARRAY(...)
# ............ index ............   # ........... value ...........
use constant _F_ORDER       =>  0;
use constant _F_BASE        =>  1;
use constant _F_EXPONENT    =>  2;
use constant _F_MODULUS     =>  3;
use constant _F_ZETA        =>  4;  # "zeta" value
use constant _F_ETA         =>  5;  # "eta" value, initially undef
use constant _F_THETA       =>  6;  # translation amount from canonical set
use constant _F_PRINC_ELEMS =>  7;  # principal elements arrayref
use constant _F_SUPPL_ELEMS =>  8;  # supplemental elements arrayref
use constant _F_LAMBDA      =>  9;  # plane logarithm value or undef
use constant _F_ELEMENTS    => 10;  # elements arrayref, initially undef
use constant _F_X_START     => 11;  # index of start element in elements
use constant _F_X_GAP       => 12;  # index of max gap element in elements
use constant _NFIELDS       => 13;

# usable native integer bits, typically 63 or 31
use constant _NATIVE_BITS     => logint(~0, 2);
# max order safe to use with native integer arithmetic
use constant _MAX_SMALL_ORDER => int( sqrt(2)*((1<<(_NATIVE_BITS>>1))-0.5) );

*canonize = \&lex_canonize;

our $VERSION = '1.001';

our $_MAX_ENUM_COUNT  = 32768;          # limit for stored rotator set size
our $_MAX_MEMO_COUNT  = 4096;           # limit for memoized values
our $_USE_SPACES_DB   = 1;              # enable looking up rotators

my $current_data = undef;               # current M::D::P::Data object

my %memo_n_planes  = ();                # memoized n_planes values
my @memo_np_orders = ();                # memoized orders FIFO
my %memo_rotators  = ();                # memoized rotators arrayrefs
my @memo_ro_orders = ();                # memoized orders FIFO

# ----- private subroutines -----

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
# Otherwise, return undef.
#
sub _rotators {
    my ($class, $order, $base, $exponent, $modulus) = @_;
    return $memo_rotators{$order} if exists $memo_rotators{$order};
    my $rotators = undef;
    my $space = $_USE_SPACES_DB && $class->_data->get_space($order);
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
        $rotators = [$radices, $depths, $inverses];
    }
    elsif (_n_planes($order, $exponent, $modulus) <= $_MAX_ENUM_COUNT) {
        my $mult = 3 * $exponent;
        my $sieve = '1' x $modulus;
        substr($sieve, 1, 1) = '0';
        my $e = 1;
        for (2 .. $mult) {
            $e = mulmod($e, $base, $modulus);
            substr($sieve, $e, 1) = '0';
        }
        my @rot = (1);
        for (my $x = 2; $x < $modulus ; ++$x) {
            if (substr $sieve, $x, 1) {
                if (0 == $modulus % $x) {
                    for (my $i = $x; $i < $modulus; $i += $x) {
                        substr($sieve, $i, 1) = '0';
                    }
                    next;
                }
                substr($sieve, $x, 1) = '0';
                my $e = $x;
                for (2 .. $mult) {
                    $e = mulmod($e, $base, $modulus);
                    substr($sieve, $e, 1) = '0';
                }
                push @rot, $x;
                last if $mult == @rot;
            }
        }
        $rotators = \@rot;
    }
    $memo_rotators{$order} = $rotators;
    push @memo_ro_orders, $order;
    delete $memo_rotators{shift @memo_ro_orders}
        while $_MAX_MEMO_COUNT < @memo_ro_orders;
    return $rotators;
}

# iterative rotator base generator, slow, but memory efficient
sub _sequential_rotators {
    my ($order, $base, $exponent, $modulus) = @_;
    my $n_planes = _n_planes($order, $exponent, $modulus);
    my $mult = 3 * $exponent;
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
            my $e = $x;
            for (2 .. $mult) {
                $e = mulmod($e, $base, $modulus);
                next ELEMENT if $e < $x;
            }
            ++$mx;
            return $x;
        }
    };
}

# structured rotator base iterator, time and space efficient
sub _structured_rotators {
    my ($modulus, $rotators) = @_;
    my ($radices, $depths, $inverses) = @{$rotators};
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

# format a planar difference set space description, like '7^3 [2^6 5^2]'
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
    return 0 if logint($base, 2) * $exponent >= _NATIVE_BITS;
    my $power = 1;
    while ($exponent) {
        $power *= $base if 1 & $exponent;
        $exponent >>= 1 and $base *= $base;
    }
    return $power;
}

# check whether order is small enough and calculate modulus
sub _modulus {
    my ($order) = @_;
    if ($order > _MAX_SMALL_ORDER) {
        croak "order $order too large for this platform\n";
    }
    return +($order + 1) * $order + 1;
}

# calculate minimal equivalent of a factor
sub _min_factor {
    my ($factor, $base, $modulus) = @_;
    my $f0 = $factor;
    my $f  = mulmod($f0, $base, $modulus);
    while ($f != $f0) {
        $factor = $f if $f < $factor;
        $f = mulmod($f, $base, $modulus);
    }
    return $factor;
}

# boolean whether an ordered strictly increasing list contains an element
sub _ol_contains {
    my ($haystack, $needle) = @_;
    my $lx = 0;
    my $hx = $#{$haystack};
    while ($lx <= $hx) {
        my $x = ($lx + $hx) >> 1;
        my $v = $haystack->[$x];
        my $cmp = $needle <=> $v;
        return !0 if !$cmp;
        if ($cmp < 0) {
            $hx = $x - 1;
        }
        else {
            $lx = $x + 1;
        }
    }
    return !1;
}

# calculate number of planes with memoization
sub _n_planes {
    my ($order, $exponent, $modulus) = @_;
    return $memo_n_planes{$order} if exists $memo_n_planes{$order};
    my $n_planes = $memo_n_planes{$order} =
        euler_phi($modulus) / (3 *$exponent);
    push @memo_np_orders, $order;
    delete $memo_n_planes{shift @memo_np_orders}
        while $_MAX_MEMO_COUNT < @memo_np_orders;
    return $n_planes;
}

# arrange elements of a planar difference set in numerical order
# return arrayref of sorted list, start index, gap index
sub _sort_elements {
    my $modulus  = shift;
    my @elements = sort { $a <=> $b } @_;
    my $xs = my $xl = $#elements;
    my $xg = my $xh = 0;
    my $lo = $elements[$xl] - $modulus;
    my $hi = $elements[0];
    my $mg = my $ml = my $d = $hi - $lo;
    while ($xh < $#elements) {
        $xl = $xh++;
        ($lo, $hi) = ($hi, $elements[$xh]);
        $d = $hi - $lo;
        $ml = $d, $xs = $xl if $d < $ml;
        $mg = $d, $xg = $xh if $d > $mg;
    }
    croak "duplicate element: $elements[$xs]" if !$ml;
    croak "delta 1 elements missing"          if $ml > 1;
    return (\@elements, $xs, $xg);
}

# generate fill elements (0, 1 or 2 values)
sub _fill_elements {
    my ($order, $modulus) = @_;
    my $type = $order % 3;
    return ()  if $type == 2;
    return (0) if $type == 0;
    my $m3 = $modulus / 3;
    return ($m3, $m3 << 1);
}

# recall elements or generate them, updating object attributes
sub _elements {
    my ($this) = @_;
    my $elements = $this->[_F_ELEMENTS];
    return $elements if $elements;
    my (           $order,   $base,   $exponent,   $modulus,   $theta) =
        @{$this}[_F_ORDER, _F_BASE, _F_EXPONENT, _F_MODULUS, _F_THETA];
    my $mult = 3 * $exponent;
    my @elem = ();
    foreach my $e0 (@{$this->[_F_PRINC_ELEMS]}) {
        my $e = $e0;
        push @elem, addmod($e0, $theta, $modulus);
        for (2 .. $mult) {
            $e = mulmod($e, $base, $modulus);
            push @elem, addmod($e, $theta, $modulus);
        }
    }
    foreach my $e0 (@{$this->[_F_SUPPL_ELEMS]}) {
        push @elem, addmod($e0, $theta, $modulus);
        my $e = mulmod($e0, $base, $modulus);
        while ($e != $e0) {
           push @elem, addmod($e, $theta, $modulus);
           $e = mulmod($e, $base, $modulus);
        }
    }
    foreach my $e0 (_fill_elements($order, $modulus)) {
        push @elem, addmod($e0, $theta, $modulus);
    }
    ($elements) = @{$this}[_F_ELEMENTS, _F_X_START, _F_X_GAP] =
        _sort_elements($modulus, @elem);
    return $elements;
}

# return data connection, creating it if not yet open
sub _data {
    if (!defined $current_data) {
        $current_data = Math::DifferenceSet::Planar::Data->new;
    }
    return $current_data;
}

# identify a plane by its rotator value with respect to a given plane
# (setting its lambda value if possible)
sub _log {
    my ($this, $ref) = @_;
    my $modulus    =  $this->[_F_MODULUS];
    my $delta      = -$this->[_F_THETA];
    my $ref_lambda =   $ref->[_F_LAMBDA];
    my $factor = 0;
    my %this_e = ();
    my $this_elements = $this->_elements;
    foreach my $e (@{$this_elements}) {
        $this_e{$delta? addmod($e, $delta, $modulus): $e} = 1;
    }
    if (@{$ref->[_F_PRINC_ELEMS]}) {
        my $inv_r = invmod($ref->[_F_PRINC_ELEMS]->[0], $modulus);
        ELEM:
        foreach my $o (@{$this->[_F_PRINC_ELEMS]}) {
            my $ro = mulmod($inv_r, $o, $modulus);
            foreach my $e (@{$ref->[_F_PRINC_ELEMS]}) {
                next ELEM if !exists $this_e{ mulmod($e, $ro, $modulus) };
            }
            $factor = $ro;
            last;
        }
    }
    else {
        my $ri = $this->iterate_rotators;
        ROT:
        while (my $ro = $ri->()) {
            foreach my $e (@{$ref->[_F_SUPPL_ELEMS]}) {
                next ROT if !exists $this_e{ mulmod($e, $ro, $modulus) };
            }
            $factor = $ro;
            last;
        }
    }
    croak 'unaligned sets' if !$factor;
    my $base = $this->[_F_BASE];
    if ($ref_lambda) {
        $this->[_F_LAMBDA] =
            _min_factor(
                mulmod($ref_lambda, $factor, $modulus), $base, $modulus
            );
    }
    return $factor;
}

# $factor = _find_factor($ds1, $ds2);
sub _find_factor {
    my ($this, $that) = @_;
    return 1 if $this == $that;
    my $order = $this->order;
    croak 'sets of same size expected' if $order != $that->order;
    my $log_this = $this->[_F_LAMBDA];
    my $log_that = $that->[_F_LAMBDA];
    if (!$log_that) {
        $log_that = _log($that, $this);
    }
    elsif (!$log_this) {
        $log_this = _log($this, $that);
    }
    return $log_this? divmod($log_that, $log_this, $this->modulus): $log_that;
}

# translation amount between a multiple of a set and another set
sub _delta_f {
    my ($this, $factor, $that) = @_;
    my $modulus  = $this->modulus;
    my ($x)      = $this->find_delta( invmod($factor, $modulus) );
    my $elements = $that->_elements;
    my $s        = $elements->[$that->[_F_X_START]];
    return addmod($s, -mulmod($x, $factor, $modulus), $modulus);
}

# $bool = _is_mult($factor, $base, $mult, $modulus);
sub _is_mult {
    my ($factor, $base, $mult, $modulus) = @_;
    return !0 if $factor == $base;
    my $p = $base;
    for (2 .. $mult-1) {
        $p = mulmod($p, $base, $modulus);
        return !0 if $factor == $p;
    }
    return !1;
}

# ($order, $base, $exponent, $key) = _order_from_params(@_);
sub _order_from_params {
    my ($order, $exponent) = @_;
    my $base = undef;
    my $key  = $order;
    if (defined $exponent) {
        $base  = $order;
        $key   = "$base, $exponent";
        croak "order base $base is not a prime" if !is_prime($base);
        $order = _pow($base, $exponent);
        croak "order $base ** $exponent too large for this platform"
            if !$order || $order > _MAX_SMALL_ORDER;
    }
    else {
        croak "order $order too large for this platform"
            if $order > _MAX_SMALL_ORDER;
        $exponent = is_prime_power($order, \$base);
        croak "order $order is not a prime power" if !$exponent;
    }
    return ($order, $base, $exponent, $key);
}

# ($this, $order, $base, $exponent, $modulus) = _full_params(@_);
sub _full_params {
    my $this = shift;
    my ($order, $base, $exponent, $modulus);
    if (@_) {
        ($order, $base, $exponent) = _order_from_params(@_);
        $modulus = _modulus($order);
    }
    else {
        croak 'parameters expected if called as a class method' if !ref $this;
        (              $order,   $base,   $exponent,   $modulus) =
            @{$this}[_F_ORDER, _F_BASE, _F_EXPONENT, _F_MODULUS];
    }
    return ($this, $order, $base, $exponent, $modulus);
}

# $bool = $class->_known_ref('ref_std', $base, $exponent);
sub _known_ref {
    my ($class, $attribute, $base, $exponent) = @_;
    my $order = defined($exponent)? _pow($base, $exponent): $base;
    return !1 if !$order || $order > $class->_data->max_order;
    my $pds   = $class->_data->get($order, 'base', $attribute);
    return
        $pds && (!defined($exponent) || $base == $pds->base) &&
        $pds->$attribute != 0;
}

# identity transformation
sub _no_change { $_[0] }

# $it = $class->_iterate_refs('ref_std', 'zeta_canonize', 10, 20);
sub _iterate_refs {
    my ($class, $attribute, $transform, @minmax) = @_;
    my $dit = $class->_data->iterate_refs($attribute, @minmax);
    return sub {
        my $pds = $dit->();
        return undef if !$pds;
        my $this = eval { $class->_from_pds($pds->order, $pds) };
        return $this && $this->multiply($pds->$attribute)->$transform;
    };
}

# $ds = Math::DifferenceSet::Planar->_from_pds($order, $pds);
sub _from_pds {
    my ($class, $order, $pds) = @_;
    my $modulus  = _modulus($order);
    my $base     = $pds->base;
    my $exponent = $base == $order? 1: logint($order, $base);
    my $main     = $pds->main_elements;
    my (@princ, @suppl) = ();
    foreach my $e (@{$main}) {
        if (gcd($modulus, $e) == 1) {
            push @princ, $e;
        }
        else {
            push @suppl, $e;
        }
    }
    my $lambda = undef;
    if (my $log = $pds->ref_std) {
        $lambda =
            $log == 1? 1: _min_factor(invmod($log, $modulus), $base, $modulus);
    }

    return bless [
        $order,
        $base,
        $exponent,
        $modulus,
        0,                      # zeta
        0,                      # eta
        0,                      # theta
        \@princ,
        \@suppl,
        $lambda,
        undef,                  # elements
        undef,                  # index_start
        undef,                  # index_gap
    ], $class;
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
    return !1 if !$order || $order > $class->_data->max_order;
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
    my $class = shift;
    my ($order, $base, $exponent, $key) = _order_from_params(@_);
    my $pds = $class->_data->get($order);
    if (!$pds) {
        croak "PDS($key) not available";
    }
    return $class->_from_pds($order, $pds);
}

sub lex_reference {
    my $class = shift;
    my ($order, $base, $exponent) = _order_from_params(@_);
    my $pds = $class->_data->get($order);
    if ($pds && (my $lambda = $pds->ref_lex)) {
        return $class->_from_pds($order, $pds)->multiply($lambda)->canonize;
    }
    return undef;
}

sub gap_reference {
    my $class = shift;
    my ($order, $base, $exponent) = _order_from_params(@_);
    my $pds = $class->_data->get($order);
    if ($pds && (my $lambda = $pds->ref_gap)) {
        return
            $class->_from_pds($order, $pds)->multiply($lambda)->gap_canonize;
    }
    return undef;
}

sub std_reference {
    my $class = shift;
    my ($order, $base, $exponent) = _order_from_params(@_);
    my $pds = $class->_data->get($order);
    if ($pds && (my $lambda = $pds->ref_std)) {
        return
            $class->_from_pds($order, $pds)->zeta_canonize->multiply($lambda);
    }
    return undef;
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
    my $modulus  = _modulus($order);
    if (grep { $_ < 0 || $modulus <= $_ } @_) {
        my $max = $modulus - 1;
        croak "element values inside range 0..$max expected";
    }
    my ($elements, $index_start, $index_gap) = _sort_elements($modulus, @_);
    my $n_mult = 3 * $exponent;

    # find zeta and theta
    my ($lx, $ux, $c) = (0, 0, 0);
    my ($e0, $e2, $e3) = @{$elements}[$index_start, 0, 0];
    my $is_m3 = $order % 3 == 1;
    my $de    = $is_m3? $modulus/3: $order + 1;
    my $bogus = 0;
    while ($c != $de) {
        if ($c < $de) {
            $ux = 0 if ++$ux > $order;
            $e3 = $elements->[$ux];
            $bogus = 1, last if $ux == $lx;
        }
        else {
            $bogus = 1, last if ++$lx > $order;
            $e2 = $elements->[$lx];
        }
        $c = $e3 < $e2? $modulus + $e3 - $e2: $e3 - $e2;
    }
    croak "delta $de elements missing\n" if $bogus;
    my ($zeta, $theta);
    if ($is_m3) {
        $theta = addmod($e3, $de, $modulus);
        $zeta  = mulmod($theta, $order - 1, $modulus);
    }
    else {
        $zeta  = addmod(mulmod($e3, $order, $modulus), -$e0, $modulus);
        $theta = $zeta && divmod($zeta, $order - 1, $modulus);
    }

    my @elems =
        sort { $a <=> $b } map { addmod($_, -$theta, $modulus) } @{$elements};
    my @princ = ();
    my @suppl = ();
    my %todo  = map {($_ => 1)} @elems;
    foreach my $start (@elems) {
        next if !exists $todo{$start};
        delete $todo{$start};
        my $this  = mulmod($start, $base, $modulus);
        my $count = 1;
        while ($this != $start) {
            if (!defined delete $todo{$this}) {
                croak
                    "bogus set: prime divisor $base of order $order " .
                    "is not a multiplier";
            }
            ++$count;
            $this = mulmod($this, $base, $modulus);
        }
        if ($count == $n_mult) {
            if (gcd($start, $modulus) == 1) {
                push @princ, $start;
            }
            else {
                push @suppl, $start;
            }
        }
        elsif ($count >= 3) {
            push @suppl, $start;
        }
    }
    my $eta = $exponent == 1? $zeta: undef;

    return bless [
        $order,
        $base,
        $exponent,
        $modulus,
        $zeta,
        $eta,
        $theta,
        \@princ,
        \@suppl,
        undef,                  # lambda
        $elements,
        $index_start,
        $index_gap,
    ], $class;
}

# $ds = Math::DifferenceSet::Planar->from_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub from_elements {
    my $class = shift;
    my $this  = $class->from_elements_fast(@_);
    if(my $ref = eval { $class->new(@_ - 1) }) {
        eval {
            my ($factor, $delta) = $ref->find_linear_map($this);
            !$ref->multiply($factor)->translate($delta)->compare($this)
        } or
        croak 'apparently not a planar difference set';
    }
    return $this;
}

# $ds = Math::DifferenceSet::Planar->from_lambda($order, $lambda);
# $ds = Math::DifferenceSet::Planar->from_lambda($order, $lambda, $theta);
sub from_lambda {
    my ($class, $order, $lambda, $theta) = @_;
    my ($base, $exponent);
    $exponent = is_prime_power($order, \$base);
    croak "this implementation cannot handle order $order" if !$exponent;
    my $modulus = _modulus($order);
    croak "impossible lambda value $lambda" if gcd($modulus, $lambda) != 1;
    my $l = mulmod($lambda, $base, $modulus);
    while ($l != $lambda) {
        croak "non-canonical lambda value $lambda" if $l < $lambda;
        $l = mulmod($l, $base, $modulus);
    }
    croak "non-canonical theta value $theta"
        if $theta && ($theta < 0 || $modulus <= $theta);
    my $ref = $class->std_reference($order);
    croak "reference set of order $order not available" if !$ref;
    my $this = $ref->multiply($lambda);
    return $theta? $this->translate($theta): $this;
}

# $bool = Math::DifferenceSet::Planar->verify_elements(
#   0, 1, 3, 9, 27, 49, 56, 61, 77, 81
# );
sub verify_elements {
    my ($class, @elements) = @_;
    my $order   = $#elements;
    return undef if $order <= 1;
    my $modulus = _modulus($order);
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
        my $this = $class->_from_pds($pds->order, $pds);
        return $this;
    };
}

sub available_min_order { $_[0]->_data->min_order }
sub available_max_order { $_[0]->_data->max_order }
sub available_count     { $_[0]->_data->count     }

sub known_std_ref {
    my $class = shift;
    return $class->_known_ref('ref_std', @_);
}

sub known_lex_ref {
    my $class = shift;
    return $class->_known_ref('ref_lex', @_);
}

sub known_gap_ref {
    my $class = shift;
    return $class->_known_ref('ref_gap', @_);
}

sub iterate_known_std_refs {
    my ($class, @minmax) = @_;
    return $class->_iterate_refs('ref_std', '_no_change', @minmax);
}

sub iterate_known_lex_refs {
    my ($class, @minmax) = @_;
    return $class->_iterate_refs('ref_lex', 'canonize', @minmax);
}

sub iterate_known_gap_refs {
    my ($class, @minmax) = @_;
    return $class->_iterate_refs('ref_gap', 'gap_canonize', @minmax);
}

sub known_std_ref_min_order { $_[0]->_data->ref_min_order('ref_std') }
sub known_std_ref_max_order { $_[0]->_data->ref_max_order('ref_std') }
sub known_std_ref_count     { $_[0]->_data->ref_count(    'ref_std') }
sub known_lex_ref_min_order { $_[0]->_data->ref_min_order('ref_lex') }
sub known_lex_ref_max_order { $_[0]->_data->ref_max_order('ref_lex') }
sub known_lex_ref_count     { $_[0]->_data->ref_count(    'ref_lex') }
sub known_gap_ref_min_order { $_[0]->_data->ref_min_order('ref_gap') }
sub known_gap_ref_max_order { $_[0]->_data->ref_max_order('ref_gap') }
sub known_gap_ref_count     { $_[0]->_data->ref_count(    'ref_gap') }

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

# $o = $ds->order;
# $p = $ds->order_base;
# $n = $ds->order_exponent;
# $m = $ds->modulus;
# $z = $ds->zeta;
# $t = $ds->theta;
# $l = $ds->lambda;
sub order          { $_[0]->[_F_ORDER   ] }
sub order_base     { $_[0]->[_F_BASE    ] }
sub order_exponent { $_[0]->[_F_EXPONENT] }
sub modulus        { $_[0]->[_F_MODULUS ] }
sub zeta           { $_[0]->[_F_ZETA    ] }
sub theta          { $_[0]->[_F_THETA   ] }
sub lambda         { $_[0]->[_F_LAMBDA  ] }

sub min_element {
    my ($this) = @_;
    my $elements = $this->_elements;
    return $elements->[0];
}

sub max_element {
    my ($this) = @_;
    my $elements = $this->_elements;
    return $elements->[-1];
}

sub n_planes {
    my ($this, $order, $base, $exponent, $modulus) = _full_params(@_);
    return _n_planes($order, $exponent, $modulus)
}

# @e  = $ds->elements;
sub elements {
    my ($this) = @_;
    my $elements = $this->_elements;
    return 0+@{$elements} if !wantarray;
    my $x_start = $this->[_F_X_START];
    return @{$elements}[$x_start .. $#$elements, 0 .. $x_start-1];
}

# $e0 = $ds->element(0);
sub element {
    my ($this, $index) = @_;
    my $n_elems  = $this->[_F_ORDER] + 1;
    return undef if $index < -$n_elems || $n_elems <= $index;
    my $elements = $this->_elements;
    my $x_eff    = $this->[_F_X_START] + $index;
    $x_eff -= $n_elems if $x_eff >= $n_elems;
    return $elements->[$x_eff];
}

# @e  = $ds->elements_sorted;
sub elements_sorted {
    my ($this) = @_;
    my $elements = $this->_elements;
    return @{$elements};
}

# $e0 = $ds->element_sorted(0);
sub element_sorted {
    my ($this, $index) = @_;
    my $elements = $this->_elements;
    return $elements->[$index];
}

# $ds1 = $ds->translate(1);
sub translate {
    my ($this, $delta) = @_;
    my $modulus = $this->[_F_MODULUS];
    $delta %= $modulus;
    return $this if !$delta;
    my $that = bless [@{$this}], ref $this;
    my $elements = $this->[_F_ELEMENTS];
    if ($elements) {
        my $lim = $modulus - $delta;
        my @elems = my @wrap = ();
        foreach my $e (@{$elements}) {
            if ($e < $lim) {
                push @wrap, $e + $delta;
            }
            else {
                push @elems, $e - $lim;
            }
        }
        my $dx = @elems;
        push @elems, @wrap;
        my $x_start = addmod($this->[_F_X_START], $dx, 0+@elems);
        my $x_gap   = addmod($this->[_F_X_GAP],   $dx, 0+@elems);
        $that->[_F_ELEMENTS] = \@elems;
        $that->[_F_X_START]  = $x_start;
        $that->[_F_X_GAP]    = $x_gap;
    }
    my ($order, $zeta, $theta) = @{$this}[_F_ORDER, _F_ZETA, _F_THETA];
    $that->[_F_ZETA] =
        addmod($zeta, mulmod($delta, $order-1, $modulus), $modulus);
    $that->[_F_THETA] = addmod($theta, $delta, $modulus);
    if (defined (my $e = $that->[_F_ETA])) {
        my $base = $this->[_F_BASE];
        $that->[_F_ETA] =
            addmod($e, mulmod($delta, $base-1, $modulus), $modulus);
    }
    return $that;
}

# $ds2 = $ds->canonize;
# $ds2 = $ds->lex_canonize;
sub lex_canonize {
    my ($this) = @_;
    my $elements = $this->_elements;
    return $this->translate(- $elements->[$this->[_F_X_START]]);
}

# $ds2 = $ds->gap_canonize;
sub gap_canonize {
    my ($this) = @_;
    my $elements = $this->_elements;
    return $this->translate(- $elements->[$this->[_F_X_GAP]]);
}

# $ds2 = $ds->zeta_canonize;
sub zeta_canonize {
    my ($this) = @_;
    return $this->translate(- $this->[_F_THETA]);
}

# $it  = $ds->iterate_rotators;
# while (my $m = $it->()) {
#   ...
# }
sub iterate_rotators {
    my ($this, $order, $base, $exponent, $modulus) = _full_params(@_);
    my $rotators = $this->_rotators($order, $base, $exponent, $modulus);
    return _sequential_rotators($order, $base, $exponent, $modulus)
        if !$rotators;
    return _structured_rotators($modulus, $rotators)
        if 'ARRAY' eq ref $rotators->[0];
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

sub iterate_planes_zc {
    my ($this) = @_;
    my $ref  = $this->zeta_canonize;
    my $r_it = $ref->iterate_rotators;
    return sub {
        my $r = $r_it->();
        return $r? $ref->multiply($r): undef;
    };
}

# @pm = $ds->multipliers;
sub multipliers {
    my ($this, $order, $base, $exponent, $modulus) = _full_params(@_);
    my $n_mult = 3 * $exponent;
    return $n_mult if !wantarray;
    my @mult = (1, $base);
    my $x = $base;
    while (@mult < $n_mult) {
        $x = mulmod($x, $base, $modulus);
        push @mult, $x;
    }
    return @mult;
}

# $ds3 = $ds->multiply($m);
sub multiply {
    my ($this, $factor) = @_;
    my (           $order,   $base,   $exponent,   $modulus) =
        @{$this}[_F_ORDER, _F_BASE, _F_EXPONENT, _F_MODULUS];
    $factor %= $modulus;
    return $this if 1 == $factor;
    croak "factor $factor is not coprime to modulus"
        if gcd($modulus, $factor) != 1;
    my $theta1 = $this->[_F_THETA];
    my $theta  = $theta1 && mulmod($theta1, $factor, $modulus);
    my $mult = 3 * $exponent;
    return $this->translate($theta - $theta1) if
        _is_mult($factor, $base, $mult, $modulus);
    my (           $zeta,   $eta,   $lambda) =
        @{$this}[_F_ZETA, _F_ETA, _F_LAMBDA];
    $zeta &&= mulmod($zeta, $factor, $modulus);
    $eta  &&= mulmod($eta,  $factor, $modulus);
    my @princ = ();
    my @suppl = ();
    foreach my $e (@{$this->[_F_PRINC_ELEMS]}) {
        my $p0 = my $p = mulmod($e, $factor, $modulus);
        for (2 .. $mult) {
            $p = mulmod($p, $base, $modulus);
            $p0 = $p if $p0 > $p;
        }
        push @princ,
            _min_factor(mulmod($e, $factor, $modulus), $base, $modulus);
    }
    @princ = sort { $a <=> $b } @princ;
    foreach my $e (@{$this->[_F_SUPPL_ELEMS]}) {
        push @suppl,
            _min_factor(mulmod($e, $factor, $modulus), $base, $modulus);
    }
    @suppl = sort { $a <=> $b } @suppl;
    if ($lambda) {
        $lambda =
            _min_factor(mulmod($lambda, $factor, $modulus), $base, $modulus);
    }
    return bless [
        $order,
        $base,
        $exponent,
        $modulus,
        $zeta,
        $eta,
        $theta,
        \@princ,
        \@suppl,
        $lambda,
        undef,                          # elements
        undef,                          # index_start
        undef,                          # index_gap
    ], ref $this;
}

# ($e1, $e2) = $ds->find_delta($delta);
sub find_delta {
    my ($this, $delta) = @_;
    my $order    = $this->order;
    my $modulus  = $this->modulus;
    my $elements = $this->_elements;
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

# $e0 = $ds->start_element;
sub start_element {
    my ($this) = @_;
    my $elements = $this->_elements;
    return $elements->[$this->[_F_X_START]];
}

# ($e1, $e2) = $ds->peak_elements
sub peak_elements {
    my ($this) = @_;
    return $this->find_delta($this->modulus >> 1);
}

# ($e1, $e2, $delta) = $ds->largest_gap;
sub largest_gap {
    my ($this) = @_;
    my $elements = $this->_elements;
    my $x2 = $this->[_F_X_GAP];
    my ($e1, $e2) = @{$elements}[$x2 - 1, $x2];
    my $delta = $x2? $e2 - $e1: $this->modulus + $e2 - $e1;
    return ($e1, $e2, $delta);
}

# $e = $ds->eta
sub eta {
    my ($this) = @_;
    return $this->zeta if $this->[_F_EXPONENT] == 1;
    my $eta = $this->[_F_ETA];
    if (!defined $eta) {
        my $p   = $this->[_F_BASE];
        my $m   = $this->[_F_MODULUS];
        my ($x) = $this->find_delta( invmod($p, $m) );
        my $s   = $this->[_F_ELEMENTS]->[$this->[_F_X_START]];
        $eta = $this->[_F_ETA] = addmod(mulmod($x, $p, $m), -$s, $m);
    }
    return $eta;
}

sub plane_principal_elements    { @{$_[0]->[_F_PRINC_ELEMS]} }
sub plane_supplemental_elements { @{$_[0]->[_F_SUPPL_ELEMS]} }

sub plane_fill_elements {
    my ($this) = @_;
    my @fe = _fill_elements(@{$this}[_F_ORDER, _F_MODULUS]);
    return @fe;
}

sub plane_derived_elements_of {
    my ($this, @elem) = @_;
    my ($base, $modulus) = @{$this}[_F_BASE, _F_MODULUS];
    my @de = ();
    foreach my $e0 (@elem) {
        my $e = mulmod($e0, $base, $modulus);
        while ($e != $e0) {
            push @de, $e;
            $e = mulmod($e, $base, $modulus);
        }
    }
    return @de;
}

# $bool = $ds->contains($e)
sub contains {
    my ($this, $elem) = @_;
    my $elements  = $this->_elements;
    return _ol_contains($elements, $elem);
}

# $cmp = $ds1->compare($ds2);
sub compare {
    my ($this, $that) = @_;
    my $order = $this->order;
    my $cmp   = $order <=> $that->order;
    return $cmp if $cmp;
    my $le = $this->_elements;
    my $re = $that->_elements;
    foreach my $x (0 .. $order) {
        $cmp = $le->[$x] <=> $re->[$x];
        return $cmp if $cmp;
    }
    return 0;
}

# $cmp = $ds1->compare_topdown($ds2);
sub compare_topdown {
    my ($this, $that) = @_;
    my $order = $this->order;
    my $cmp   = $order <=> $that->order;
    return $cmp if $cmp;
    my $le = $this->_elements;
    my $re = $that->_elements;
    my $x = $order;
    while ($x >= 0) {
        $cmp = $le->[$x] <=> $re->[$x];
        return $cmp if $cmp;
        --$x;
    }
    return 0;
}

# $bool = $ds1->same_plane($ds2);
sub same_plane {
    my ($this, $that) = @_;
    my $order = $this->order;
    return !1 if $order != $that->order;
    my $l1 = $this->[_F_LAMBDA];
    my $l2 = $that->[_F_LAMBDA];
    return $l1 == $l2 if $l1 && $l2;
    my $le = $this->[_F_PRINC_ELEMS];
    my $re;
    if (@{$le}) {
        $re = $that->[_F_PRINC_ELEMS];
    }
    else {
        $le = $this->[_F_SUPPL_ELEMS];
        $re = $that->[_F_SUPPL_ELEMS];
    }
    foreach my $x (0 .. $#{$le}) {
        return !1 if $re->[$x] != $le->[$x];
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
    my $le = $this->_elements;
    my $re = $that->_elements;
    my $lv = $le->[0];
    my $rv = $re->[0];
    while (1) {
        my $cmp = $lv <=> $rv;
        push @common, $lv if !$cmp;
        if ($cmp <= 0) {
            last if ++$li > $order;
            $lv = $le->[$li];
        }
        if ($cmp >= 0) {
            last if ++$ri > $order;
            $rv = $re->[$ri];
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

This documentation refers to version 1.001 of Math::DifferenceSet::Planar.

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
  $ds = Math::DifferenceSet::Planar->from_lambda(9, 1);
  $ds = Math::DifferenceSet::Planar->from_lambda(9, 1, 0);
  $ds = Math::DifferenceSet::Planar->lex_reference(9);
  $ds = Math::DifferenceSet::Planar->gap_reference(9);
  $ds = Math::DifferenceSet::Planar->std_reference(9);
  print "ok" if Math::DifferenceSet::Planar->verify_elements(
    0, 1, 3, 9, 27, 49, 56, 61, 77, 81
  );
  $o  = $ds->order;
  $m  = $ds->modulus;
  @e  = $ds->elements;
  $e0 = $ds->element(0);
  $e0 = $ds->start_element;             # equivalent
  @e  = $ds->elements_sorted;
  $e0 = $ds->element_sorted(0);
  $e0 = $ds->min_element;               # equivalent
  $e0 = $ds->max_element;
  $np = $ds->n_planes;
  $p  = $ds->order_base;
  $n  = $ds->order_exponent;

  ($e1, $e2)         = $ds->find_delta($delta);
  ($e1, $e2)         = $ds->peak_elements;
  ($e1, $e2)         = $ds->find_delta(($ds->modulus - 1) / 2);
  ($e1, $e2, $delta) = $ds->largest_gap;
  $eta               = $ds->eta;
  $zeta              = $ds->zeta;
  $theta             = $ds->theta;
  $lambda            = $ds->lambda;
  $bool              = $ds->contains($e1);

  @ep = $ds->plane_principal_elements;
  @es = $ds->plane_supplemental_elements;
  @ef = $ds->plane_fill_elements;
  @ed = $ds->plane_derived_elements_of(@ep, @es);

  $ds1 = $ds->translate(1);
  $ds2 = $ds->canonize;
  $ds2 = $ds->lex_canonize;                     # equivalent
  $ds2 = $ds->translate(- $ds->start_element);  # equivalent
  $ds2 = $ds->gap_canonize;
  $ds2 = $ds->translate(- ($ds->largest_gap)[1]);   # eqv.
  $ds2 = $ds->zeta_canonize;
  $ds2 = $ds->translate(- $ds->theta);          # equivalent
  @pm  = $ds->multipliers;
  $it  = $ds->iterate_rotators;
  while (my $m = $it->()) {
    $ds3 = $ds->multiply($m)->canonize;
  }
  $it = $ds->iterate_planes;
  while (my $ds3 = $it->()) {
    # as above, yielding canonical sets
  }
  $it = $ds->iterate_planes_zc;
  while (my $ds3 = $it->()) {
    # similar, but yielding zeta-canonical sets
  }

  $cmp  = $ds1->compare($ds2);
  $cmp  = $ds1->compare_topdown($ds2);
  $bool = $ds1->same_plane($ds2);
  @e    = $ds1->common_elements($ds2);

  ($factor, $delta) = $ds1->find_linear_map($ds2);
  # $ds2 == $ds1->multiply($factor)->translate($delta)
  foreach my $fd ( $ds1->find_all_linear_maps($ds2) ) {
    my ($factor, $delta) = @{$fd};
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
  $min   = Math::DifferenceSet::Planar->available_min_order;
  $max   = Math::DifferenceSet::Planar->available_max_order;
  $count = Math::DifferenceSet::Planar->available_count;

  $bool  = Math::DifferenceSet::Planar->known_std_ref(9);
  $it    = Math::DifferenceSet::Planar->iterate_known_std_refs(10, 20);
  $min   = Math::DifferenceSet::Planar->known_std_ref_min_order;
  $max   = Math::DifferenceSet::Planar->known_std_ref_max_order;
  $count = Math::DifferenceSet::Planar->known_std_ref_count;

  $bool  = Math::DifferenceSet::Planar->known_lex_ref(9);
  $it    = Math::DifferenceSet::Planar->iterate_known_lex_refs(10, 20);
  $min   = Math::DifferenceSet::Planar->known_lex_ref_min_order;
  $max   = Math::DifferenceSet::Planar->known_lex_ref_max_order;
  $count = Math::DifferenceSet::Planar->known_lex_ref_count;

  $bool  = Math::DifferenceSet::Planar->known_gap_ref(9);
  $it    = Math::DifferenceSet::Planar->iterate_known_gap_refs(10, 20);
  $min   = Math::DifferenceSet::Planar->known_gap_ref_min_order;
  $max   = Math::DifferenceSet::Planar->known_gap_ref_max_order;
  $count = Math::DifferenceSet::Planar->known_gap_ref_count;

  $bool  = Math::DifferenceSet::Planar->known_space(9);
  $desc  = Math::DifferenceSet::Planar->known_space_desc(9);
  $min   = Math::DifferenceSet::Planar->known_space_min_order;
  $max   = Math::DifferenceSet::Planar->known_space_max_order;
  $count = Math::DifferenceSet::Planar->known_space_count;
  $it3   = Math::DifferenceSet::Planar->iterate_known_spaces;
  $it3   = Math::DifferenceSet::Planar->iterate_known_spaces(10, 20);

=head1 DESCRIPTION

A planar difference set in a modular integer ring E<8484>_n, or cyclic
planar difference set, is a subset D = {d_1, d_2, ..., d_k} of E<8484>_n
such that each nonzero element of E<8484>_n can be represented as a
difference (d_i - d_j) in exactly one way.  By convention, only sets
with at least three elements are considered.

Sometimes, the two-element sets {0, 1}, {0, 2}, and {1, 2}, describing
a simple triangle geometry, are also included in this class, but not here.

Necessarily, for such a set to exist, the modulus n has to be equal
to S<(k - 1) E<183> k + 1>.  If S<(k - 1)> is a prime power, planar
difference sets can be constructed from a finite field of order
S<(k - 1)>.  It is conjectured that no other cyclic planar difference
sets exist.  Planar difference sets on other than cyclic groups do exist,
though.  We intend to cover them in a future extension of this library.

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
spanning all plane rotations a rotator base.  Another terminology calls
such a set a reduced residue system.

Math::DifferenceSet::Planar provides examples of small cyclic planar
difference sets constructed from finite fields.  It is primarily intended
as a helper module for algorithms employing such sets.  It also allows
to iterate over all sets of a given size via translations and rotations,
and to verify whether an arbitrary set of modular integers is a cyclic
planar difference set.

Currently, only sets with k E<8804> 4097, or moduli E<8804> 16,781,313,
are supported by the CPAN distribution of the module.  These limits can
be extended by installing a database with more samples.  Instructions
on where to obtain additional data can be found in the L</"SEE ALSO">
section below.  The database with orders up to 2E<185>E<8311> requires
700 MB of storage space, while the default database only occupies 1 MB.

We work with pre-computed data for lack of super-efficient generators.
Difference sets of order I<k> can be generated with O(I<kE<178>>)
operations with order 3 polynomials over an order I<k> Galois field,
which means only polynomial complexity, but still more than would be
practical to perform at runtime.  Getting rid of the databases will
require better algorithms.

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
would be enumerated as S<(10, 11, 14, 3, 5)>.  But accessing elements
in strictly ascending numeric succession is possible as well.

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

Sets of a plane can also be sorted lexically with priority on large
elements.  The first set in that ordering is the one with the largest
gap between consecutive elements just left of zero.  We call this set
gap-canonical.

As divisors of the order, like I<order_base> and I<order> itself, are
always multipliers, multiplying a planar difference set by I<order_base>
or I<order> will yield translations of the original set.  The translation
amount upon multiplying a set with its I<order_base> or with its I<order>
we call I<eta> or I<zeta>, respectively.

If I<eta> is zero, so is I<zeta>, and every plane has at least one
such set.  With some additional condition for uniqueness this yields
another kind of choice of a canonical representative.  This library
provides it by the name of I<zeta_canonize>.

Another conjecture asserts that for any two cyclic planar difference
sets of the same order there is a linear function mapping one of them to
the other.  This is relevant for some of the algorithms implemented here.
Notably, it gives rise to the notion of an identification of sets or
planes by their linear relationship with some reference set.

If there was a consensus among researchers on the choice of a reference
set and of a particular solution from the solution space of the linear
equation, different math libraries could identify any such set by its
order and only two uniquely chosen numbers and be interoperable.

Such a convention would be an analogy for cyclic planar difference sets
to what Conway polynomials are for finite fields.  What makes the choice
difficult is that each has its advantages and disadvantages.  A major
disadvantage of Conway polynomials is that, for large orders, they are
computationally expensive (read: practically impossible) to obtain.
Many candidates for reference difference sets, so far, including some
actually based on Conway polynomials, seem to share this disadvantage.

Nevertheless, we do suggest a particular representative set for each
set size here, which can be computed considerably faster than, say,
the overall lexically minimal set.  Our set of choice is the lexically
minimal zeta-canonical set.  We provide an algorithm that has to consider
at most I<k/3> of the I<O(kE<8308>)> possible sets of order I<k> to
find it.  From the linear mappings taking this reference set to a given
set we choose the one with the smallest linear factor, yielding unique
values I<lambda> and I<theta> for the factor and translation amount.
Together with the order, these two values define a unique fingerprint
of each set.  Linear mappings between sets can be computed from their
I<lambda, theta> value pairs and vice versa.  Both directions of the
mapping between complete sets and I<lambda, theta> pairs can also be
computed efficiently once the reference set is given.

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

=item I<lex_reference>

If C<$q> or C<$p ** $j> is a prime power, I<lex_reference> is a
replacement for I<new> returning the lexicographically lowest difference
set of that order, compared from smallest to largest element.  If that
set is not known, C<undef> is returned.

For example, C<Math::DifferenceSet::Planar-E<gt>lex_reference(3)>
returns an object representing the set I<{0, 1, 3, 9}>.

If C<$q> is not a prime power, or C<$p> is not a prime, or the modulus
of the set would exceed the size of a perl integer value, an exception
is raised.

=item I<gap_reference>

If C<$q> or C<$p ** $j> is a prime power, I<gap_reference> is a
replacement for I<new> returning the lexicographically lowest difference
set of that order, compared from largest to smallest element.  If that
set is not known, C<undef> is returned.

For example, C<Math::DifferenceSet::Planar-E<gt>gap_reference(3)>
returns an object representing the set I<{0, 1, 4, 6}>.

If C<$q> is not a prime power, or C<$p> is not a prime, or the modulus
of the set would exceed the size of a perl integer value, an exception
is raised.

=item I<std_reference>

If C<$q> or C<$p ** $j> is a prime power, I<std_reference> is
a replacement for I<new> returning the lexicographically lowest
zeta-canonical difference set of that order, compared from smallest to
largest element.  If that set is not known, C<undef> is returned.

For example, C<Math::DifferenceSet::Planar-E<gt>std_reference(2)>
returns an object representing the set I<{1, 2, 4}>.

If C<$q> is not a prime power, or C<$p> is not a prime, or the modulus
of the set would exceed the size of a perl integer value, an exception
is raised.

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

Sets with sizes beyond those of stored sample sets can not be strictly
validated.  Only together with a true value of I<available(order)>
may success of I<from_elements> be regarded as proof of correctness.

=item I<from_elements_fast>

The method I<from_elements_fast> is an alternative to I<from_elements>
that may be used if the arguments are known to be correct.  Arguments not
verified to define a planar difference set may yield a broken object
with undefined behaviour, though.  To be used with caution.

=item I<from_lambda>

The method I<from_lambda> creates a planar difference set from its
I<order>, I<lambda>, and optional I<theta> values.  These values uniquely
identify a set like a fingerprint.  Reconstructing sets from their
fingerprints is possible for orders with stored standard reference sets.
Otherwise, or for invalid values, an exception is raised.  If I<theta>
is not specified it is taken as zero, so that the result will be
zeta-canonical.

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

=item I<multipliers>

The class method
C<Math::DifferenceSet::Planar-E<gt>multipliers(@args)> is equivalent
to the object method I<multipliers>, called with the same arguments.
See below.

=item I<n_planes>

The class method C<Math::DifferenceSet::Planar-E<gt>n_planes(@args)>
is equivalent to the object method I<n_planes>, called with the same
arguments.  See below.

=item I<iterate_rotators>

The class method
C<Math::DifferenceSet::Planar-E<gt>iterate_rotators(@args)> is equivalent
to the object method I<iterate_rotators>, called with the same arguments.
See below.

=item I<available>

The class method C<Math::DifferenceSet::Planar-E<gt>available(@params)>
checks whether I<new> can be successfully called with the same parameters.
This means either an order C<$q> or a prime C<$p> and an exponent C<$j>
specifies a prime power order, and a sample set of that order is available
from the database of planar difference set samples.  It returns a true
value if sample sets with the given parameters are present, otherwise
false.

=item I<iterate_available_sets>

The class method
C<Math::DifferenceSet::Planar-E<gt>iterate_available_sets> returns
a code reference that, repeatedly called, returns one stored sample
planar difference set for each order known to the module, one by one.
The iterator returns a false value when it is exhausted.

C<Math::DifferenceSet::Planar-E<gt>iterate_available_sets($lo, $hi)>
returns an iterator over samples with orders between C<$lo> and C<$hi>
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
returns the number of sample planar difference sets with distinct orders
currently known to the module.

=item I<known_std_ref>

=item I<known_lex_ref>

=item I<known_gap_ref>

The class methods
C<Math::DifferenceSet::Planar-E<gt>known_I<E<lt>typeE<gt>>_ref($order)>
with I<E<lt>typeE<gt>> one of C<std>, C<lex>, or C<gap>, returns a
boolean value of true if the current difference set samples database
contains the reference set of the respective type, otherwise false.
With the default database, this will be the true for all available sets,
but data extension modules might provide large sample sets without
accompanying reference sets of all kinds.

=item I<iterate_known_std_refs>

=item I<iterate_known_lex_refs>

=item I<iterate_known_gap_refs>

The class methods
C<Math::DifferenceSet::Planar-E<gt>iterate_known_I<E<lt>typeE<gt>>_refs(@args)>
with I<E<lt>typeE<gt>> one of C<std>, C<lex>, or C<gap>, provide
iterators analogous to I<iterate>, but iterating over the reference
sets of the respective type rather than unspecified samples.  Note that
these iterations may terminate sooner than I<iterate> and may even skip
some orders.

=item I<known_std_ref_min_order>

=item I<known_std_ref_max_order>

=item I<known_std_ref_count>

=item I<known_lex_ref_min_order>

=item I<known_lex_ref_max_order>

=item I<known_lex_ref_count>

=item I<known_gap_ref_min_order>

=item I<known_gap_ref_max_order>

=item I<known_gap_ref_count>

The class methods C<Math::DifferenceSet::Planar>
C<-E<gt>known_I<E<lt>typeE<gt>>_ref_I<E<lt>propertyE<gt>>> with
I<E<lt>typeE<gt>> one of C<std>, C<lex>, or C<gap>, and with
I<E<lt>propertyE<gt>> one of C<min_order>, C<max_order>, or C<count>,
return the smallest and largest order and the number of known reference
sets of the respective kind.

In the unusual case of a database not containing any reference sets of the
desired type, minimum and maximum will be C<undef> and count will be zero.

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
available to the module, if any, otherwise C<undef>.

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
share directory (as returned by I<list_databases>).

=item I<list_databases>

C<Math::DifferenceSet::Planar-E<gt>list_databases> returns a list of
available databases from the distribution-specific share directory,
ordered by decreasing priority.  Priority is highest for file names
beginning with "pds", and for large files.  Files with other suffixes
than ".db" will be ignored.  Normal installations will have a single
database named "pds.db".  Installing data extensions will result in
additional databases.  By virtue of the naming scheme, extensions can
provide larger default databases or special-case data not intended to
replace the main data source.  It should be safe to call I<set_database>
with each of the database names returned by I<list_databases>.

=back

=head1 OBJECT METHODS

=head2 Constructors

=over 4

=item I<translate>

If C<$ds> is a planar difference set object and C<$t> is an integer
number, C<$ds-E<gt>translate($t)> returns an object representing the
translate of the set by C<$t>.

Translating by each number from zero to the modulus minus one (i.e. all
elements of the cyclic group) in turn generates all difference sets
belonging to one plane.

=item I<multiply>

If C<$ds> is a planar difference set object and C<$t> is an integer
number coprime to the modulus, C<$ds-E<gt>multiply($t)> returns an object
representing the difference set generated by multiplying each element
by C<$t>.

If C<$t> and the modulus have a common divisor greater than one, an
exception is raised, as such a multiplication would not generate another
planar difference set.

=item I<lex_canonize>

If C<$ds> is a planar difference set object, C<$ds-E<gt>lex_canonize> returns
an object representing the lexically canonical translate of the set.  All sets
of a plane yield the same set upon canonizing.  Using our enumeration
convention, an equivalent operation to canonizing is to translate by
the negative of the start element.  The canonical representative of a
plane is also its lexicographically first set when sets are compared
element-wise from smallest to largest element.

=item I<canonize>

This method is an alias for I<lex_canonize>.  We keep it for historical
reasons and because this kind of canonizing seems to be the most common
one in the literature.

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
translation amount when the set is multiplied by its order.  The order
is always a multiplier (see below).

=item I<iterate_planes>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_planes>
returns a code reference that, repeatedly called, returns all canonical
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

=item I<iterate_planes_zc>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_planes_zc>
is similar to C<$ds-E<gt>iterate_planes>, but returns zeta-canonical
rather than lexically canonical sets.  This currently is the most
efficient way to iterate over difference set planes.

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

=item I<element>

C<$ds-E<gt>element($index)> is equivalent to
C<($ds-E<gt>elements)[$index]>, only more efficient.

=item I<elements_sorted>

C<$ds-E<gt>elements_sorted> returns all elements of the difference set
as a list, ordered by ascending numerical value.  In scalar context,
it returns the number of elements.

=item I<element_sorted>

C<$ds-E<gt>element_sorted($index)> is equivalent to
C<($ds-E<gt>elements_sorted)[$index]>, only more efficient.

=item I<start_element>

C<$ds-E<gt>start_element> is equivalent to C<$ds-E<gt>element(0)>.

=item I<min_element>

C<$ds-E<gt>min_element> returns the smallest element of the set
and is thus equivalent to C<$ds-E<gt>element_sorted(0)>.

=item I<max_element>

C<$ds-E<gt>max_element> returns the largest element of the set.

=item I<order_base>

If C<$ds> is a planar difference set object with prime power order,
C<$ds-E<gt>order_base> returns the prime.

=item I<order_exponent>

If C<$ds> is a planar difference set object with prime power order,
C<$ds-E<gt>order_exponent> returns the exponent of the prime power.

=item I<multipliers>

If C<$ds> is a planar difference set object, C<$ds-E<gt>multipliers>
returns the set of its multipliers as a list of integer residues,
in the order they are generated as powers of C<$ds-E<gt>order_base>.
In scalar context, the number of multipliers is returned.

If C<$order> is a prime power, or C<$p> is a prime and C<$n> is a positive
integer, and C<$ds> is a planar difference set object or its class,
C<$ds-E<gt>multipliers($order)> or C<$ds-E<gt>multipliers($p, $n)> returns
the set of multipliers for planes of order C<$order> or C<$p ** $n>,
respectively.  The class method call can be used to generate multipliers
without creating a difference set first.  For invalid arguments, an
exception will be raised.

=item I<iterate_rotators>

If C<$ds> is a planar difference set object, C<$ds-E<gt>iterate_rotators>
returns a code reference that, repeatedly called, returns the elements
of a rotator base of the set.  The iterator returns a zero value when
it is exhausted.

If C<$order> is a prime power, or C<$p> is a prime and C<$n>
is a positive integer, and C<$ds> is a planar difference set
object or its class, C<$ds-E<gt>iterate_rotators($order)> or
C<$ds-E<gt>iterate_rotators($p, $n)> returns an iterator generating
rotators for planes of order C<$order> or C<$p ** $n>, respectively.
The class method call can be used to generate rotators without creating a
difference set first.  For invalid arguments, an exception will be raised.

=item I<n_planes>

If C<$ds> is a planar difference set object, C<$ds-E<gt>n_planes>
returns the number of distinct planes that can be generated from the
planar difference set C<$ds> or, equivalently, the number of elements
in a rotator base of order C<$ds-E<gt>order>.

If C<$order> is a prime power, or C<$p> is a prime and C<$n> is a
positive integer, and C<$ds> is a planar difference set object or its
class, C<$ds-E<gt>n_planes($order)> or C<$ds-E<gt>n_planes($p, $n)>
returns the number of distinct planes of order C<$order> or C<$p ** $n>,
respectively.  The class method call can be used to calculate this
number without creating a difference set first.  For invalid arguments,
an exception will be raised.

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

=item I<theta>

The translation amount that takes the zeta-canonical representative of a
set's plane to the set itself is called I<theta>.  Thus, zeta-canonizing
is equivalent to translating by minus I<theta>.

=item I<lambda>

Starting with version 1.000, the library contains data of pre-computed
reference sets, uniquely defined as outlined in the L</Conventions>
section above.  The I<lambda, theta> pair of values then identifies
each individual set, and I<lambda> in particular the plane of the set.
This method returns the I<lambda> value if the reference set is known,
otherwise C<undef>.

Note that, while I<lambda> may be unknown for some sets, I<theta> will
always be defined even in the absence of the reference set.

=item I<plane_principal_elements>

Each plane of I<k>-element cyclic planar difference sets can be
constructed from a set of at most I<floor(k/3)> main elements and
additional elements derived from these by an arithmetic progression.
The main elements that are coprime to the modulus are called principal
elements, the others are called supplemental elements.  Principal
elements are sufficient to determine linear mappings between planes,
while supplemental elements are sufficient to determine subplanes.
Main elements, derived elements and at most two fill elements build a
complete zeta-canonical set.

The method I<plane_principal_elements> returns the principal elements
of the plane of a set in list context, or their number in scalar context.

=item I<plane_supplemental_elements>

The method I<plane_supplemental_elements> returns the supplemental
elements of the plane of a set in list context, or their number in
scalar context.

=item I<plane_fill_elements>

The method I<plane_fill_elements> returns the fill elements of the plane
of a set in list context, or their number in scalar context.

=item I<plane_derived_elements_of>

The method I<plane_derived_elements_of>, called with a single
principal or supplemental element as argument, returns the elements
derived from that element.  This will be I<3 * order_exponent - 1>
elements for a principal element, and I<3 * n - 1> elements, with
I<1 E<8804> n E<8804> order_exponent>, for a supplemental element,
in any order.

Called with a list of elements, the method will return a collected list
of all derived elements of these elements.

Calling I<plane_derived_elements_of> with other elements than principal
or supplemental elements will yield some list with no meaningful relation
to the plane at hand.

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
zero, or greater than zero, if C<$ds1> precedes, is equal to, or follows
C<$ds2> according to this order relation: Smaller sets before larger sets,
sets of equal size in lexicographic order when written from smallest to
largest element and compared element-wise left to right.

Examples: I<{0, 4, 5} E<lt> {1, 2, 4} E<lt> {1, 2, 6} E<lt> {0, 1, 3, 9}>.

=item I<compare_topdown>

The method I<compare_topdown> is a drop-in replacement for I<compare>
with the property that larger elements take priority over smaller
elements on comparison.

Example: I<{0, 2, 3}> E<lt> I<{0, 1, 5}> when compared with this method,
since 3 E<lt> 5.

=item I<same_plane>

If C<$ds1> and C<$ds2> are planar difference set objects,
C<$ds1-E<gt>same_plane($ds2)> returns a boolean value of true if C<$ds2>
is a translate of C<$ds1>, otherwise false.  If they do, they will have
either precisely one element or all elements in common and the translation
amount will be equal to the difference of their start elements.

=item I<common_elements>

If C<$ds1> and C<$ds2> are planar difference set objects of equal order,
C<$ds1-E<gt>common_elements($ds2)> returns a list of elements that are in
both sets.  For sets of different order, an empty list will be returned.
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
I<multipliers>.  The completeness of the solution space thus depends
on the I<3n multipliers> conjecture, asserting that each set of order
I<p**n> has precisely I<3E<183>n> multipliers.

=back

=head1 EXAMPLES

The distribution contains an I<examples> directory with several
self-documenting command line tools for generating, manipulating, and
examining planar difference sets, and for displaying available databases.

To read the documentation of an example with filename I<file>, run:
C<perldoc -F I<file>>

=head1 OTHER FILES

The library is packaged together with a small SQLite version 3 database
named F<pds.db>.  This is installed in a distribution-specific F<share>
directory and accessed read-only at run-time.

The same directory can hold additional databases from extension projects.
Larger databases, as well as tools to create them, are distributed
separately.

=head1 DIAGNOSTICS

=over 4

=item PDS(%s) not available

The class method I<new> was called with parameters this implementation
does not cover.  The parameters are repeated in the message.  To avoid
this exception, verify the parameters using the I<available> method
before calling I<new>.

=item this implementation cannot handle order %d

A constructor method was called with an order not equal to a prime power.
The order (which is the number of elements minus one) is repeated
in the message.  The given arguments may or may not define a planar
difference set, but if they were (i.e. I<verify_elements> called with
all the elements returned true), the prime power conjecture would be
proven wrong.  Publishing this counter-example could earn you scientific
merit.  Alternatively, you may report a bug in this module's bug tracker.
Please include all arguments.

=item order %d too large for this platform

=item order %d ** %d too large for this platform

A constructor method was called with an order or base and exponent
pair defining an order too large for arithmetic with perl scalars.
On 32-bit platforms, only sets with orders E<8804> 46337 can be handled,
and on 64-bit platforms, only sets with orders E<8804> 3,037,000,493.
This restriction might be lifted in a future release.

=item order %d is not a prime power

=item order base %d is not a prime

A constructor method was called with an order that was not a prime power
or a base and power pair where the base was not a prime.  If unsure
about the factorization of the order, leave it to the module and call
the constructor with just an order value.  If the desired order is not
a prime power at all, there is no finite field with this order and this
module will not be able to generate a difference set.

=item element values inside range 0..%d expected

The class method I<from_elements> or I<from_elements_fast> was called with
elements that were not normalized, i.e. integer values from zero to the
modulus minus one, or some values were too large for a difference set of
the given size.  The range of values from zero to the modulus minus one,
matching the number of arguments, is indicated in the message.

=item impossible lambda value %d

The class method I<from_lambda> was called with a lambda value not
coprime to the modulus.  Such lambda values are not possible.

=item non-canonical lambda value %d

The class method I<from_lambda> was called with a lambda value not
conforming to the convention achieving unambiguity by allowing just
the smallest of equivalent values.

=item non-canonical theta value %d

The class method I<from_lambda> was called with a theta value less
than zero or greater than the modulus minus one.  Theta values must
be normalized.

=item reference set of order %d not available

The class method I<from_lambda> was called with an order value no
I<std_reference> set is available for.  To handle orders that large,
a data extension module would be necessary.

=item apparently not a planar difference set

A constructor method was called with values that apparently define no
planar difference set.  Note that this verdict might be incorrect if
the linear mapping conjecture turned out to be wrong, when verifying a
counterexample, but it will be correct with all actually wrong sets.

You can override the automatic linear mapping check by using
I<from_elements_fast> in place of I<from_elements>.  Unverified sets
may yield broken objects with inconsistent behaviour, though.

=item duplicate element: %d

The class method I<from_elements> or I<from_elements_fast> was called
with non-unique values.  One value occuring more than once is reported
in the message.

=item delta %d elements missing

The class method I<from_elements> or I<from_elements_fast> was called
with a set lacking elements with the specified difference.  This is not
a difference set.

=item factor %d is not coprime to modulus

The object method I<multiply> was called with an argument that was not an
integer coprime to the modulus.  The argument is repeated in the message.
Factors not coprime to the modulus would not yield a proper difference set.

=item bogus set: delta not found: %d (mod %d)

One of the methods I<find_delta> or I<peak_elements> or I<from_elements>
was called on an object of a set lacking the required I<delta> value.
This means that the set was not actually a difference set, which in
turn means that a constructor must have been called with unverified set
elements.  The delta value and the modulus are reported in the message.

=item bogus set: divisor %d of order %d is not a multiplier

The method I<from_elements> or I<from_elements_fast> was called with a set
with the property that a prime divisor of its order is not a multiplier.
The divisor and the order are reported in the message.  Sets with this
property may also be reported as "apparently not a planar difference set",
depending on other properties.

=item sets of same size expected

One of the methods I<find_linear_map> or I<find_all_linear_maps> was
called with two sets of different size.  Linear map functions can only
exist for sets with equal size.

=item unaligned sets

One of the methods I<find_linear_map> or I<find_all_linear_maps>
surprisingly did not succeed.  This would prove another conjecture wrong,
or, more likely, indicate one of the objects was created from elements not
actually representing a valid planar difference set.

=item parameters expected if called as a class method

One of the methods I<n_planes>, I<multipliers>, or I<iterate_rotators>
was called as a class method but without an I<order> parameter or an order
I<base> and I<exponent> parameter pair.  Methods describing properties
of spaces need a specific space to relate to.

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
module is good for sets with at most 4097 elements.  Extensions in various
sizes are available on GitHub, but not indended to be uploaded to CPAN,
to save storage space.  To improve efficiency for much larger sets,
the API should presumably be changed to use PDL vectors rather than
plain perl arrays.

Sets beyond the size of sets in the sample database can be handled but
will not be strictly verified upon instantiation.  There is also a size
limit imposed by the perl integer value size: Where it is 32 bit, only
orders up to 46,337 are accepted, while with 64 bit the highest possible
order is 3,037,000,493.  Note that sample sets available via extension
modules may very well exceed the 32 bit limit.

As our precomputed data is the result of computer programs running for
hours or even days, there is a small probability some values may be wrong
due to random malfunctions, especially for very large sets.  We intend
to double-check all of them and also hope for independent verification
and extensions.  Software to re-generate the data is included in the
git repository.

To handle difference sets on groups other than cyclic groups, some slight
API changes would be required.  It should accept group elements as well
as small integers as arguments.  This is intended to be dealt with in
a future release.

The literature on difference sets, connecting algebra, combinatorics,
and geometry, is quite rich in vocabulary.  Specialized libraries like
this one can only cover a selection of the concepts presented there, and
the nomenclature will be more consistent with some authors than others.
The topic is also abundant with unanswered questions.

This library is provided as a calculator tool, but not claiming to
prove any of its implicit or explicit assumptions.  If you do find
something wrong or inaccurate, however, the author will be glad to be
notified about it and address the issue.  The documentation points out
where conjectures play a part in the computations.  The library should
thus be safe to use for studying sample sets and their properties and
relationships, but not for nonexistence claims.

If, against popular expectations, the prime power conjecture for Singer
sets, the existence of linear mappings conjecture, or the conjecture
that all multipliers are divisors of the order should be proven wrong,
we will have to decide how this library should be improved to reflect
on the matter.  Conversely, if some of these conjectures are finally
confirmed, at least the documentation should be updated.

The verify_elements() method currently builds a complete operator table
in memory.  This does not scale very well in terms of either space or
time for larger sets.

The documentation should be reorganized to move detailed explanations
into separate POD files while keeping API descriptions in the modules
themselves.

Bug reports and suggestions are welcome.
Please submit them through the github issue tracker,
L<https://github.com/mhasch/perl-Math-DifferenceSet-Planar/issues>.

More information for potential contributors can be found in the file
named F<CONTRIBUTING> in this distribution.

=head1 ROADMAP

With version 1.000, a release series intended to be more stable than
previous versions has been established.  New functionality may yet be
introduced, but with backwards compatibility as an objective not to be
given up lightly.  There is of course room for improvements behind the
scenes, too, notably addressing time and space efficiency.

Other changes may of course reflect research progress, as we get along,
and also work towards other goals mentioned in the CONTRIBUTING agenda.
In particular, we intend to cover more geometric and algebraic aspects
of planar difference sets.  We will also look out for opportunities to
interface with more generic set types.

The inclusion of sets of order one has been considered to perhaps not
justify the extra work so far.  These three sets would satisfy difference
set definitions but not all projective plane properties.

Further extensions of the sample set database are a part
of the project but will only affect the collection of
extension modules Math::DifferenceSet::Planar::Data::M,
Math::DifferenceSet::Planar::Data::L,
Math::DifferenceSet::Planar::Data::XL, etc.

For most planes in the larger collections, lex and gap reference sets
are not yet computed.  At the time of the 1.000 release, we have computed
lex reference sets for 1394 planes and gap reference sets for 644 planes
only, while standard reference sets are available for all of the 12400
planes included in the XL database, and even for the sets with millions
of elements provided as an extra.  Lacking more efficient algorithms,
a substantial extension of lex and gap reference sets would require
massive computing power, but we expect to at least gradually increase
their number over time.

More important perhaps is double- and triple-checking the data that is
already present, before it can be regarded as scientifically acceptable.
For each order, we used Singer's construction to generate a sample
set, wich is provably valid, and iterated through its multiples
to find reference sets with their respective optimality properties.
As this was of course performed by computer programs and computers may
malfunction, repetitions or, even better, independent reiterations
will increase confidence in the results and weed out actual errors.

Verifying difference set properties using complete difference tables is
impractical for large sets.  Therefore, we are still looking for efficient
verification methods for orders exceeding those of the collected samples.

=head1 SEE ALSO

=over 4

=item *

L<Math::DifferenceSet::Planar::Data> - planar difference set storage.

=item *

L<Math::DifferenceSet::Planar::Examples> - overview of example scripts.

=item *

L<Math::DifferenceSet::Planar::Computation> - origins of pre-computed data.

=item *

L<Math::DifferenceSet::Planar::Data::M|https://github.com/mhasch/perl-Math-DifferenceSet-Planar-Data-M>,
L<Math::DifferenceSet::Planar::Data::L|https://github.com/mhasch/perl-Math-DifferenceSet-Planar-Data-L>,
and
L<Math::DifferenceSet::Planar::Data::XL|https://github.com/mhasch/perl-Math-DifferenceSet-Planar-Data-XL>
- data extension modules of various sizes, available on GitHub.  They just
contain data and no additional functionality.  We don't intend to upload
these modules to CPAN, where they would only be dead weight, while users
actually interested in them will have not much trouble to fetch them
from the sources referenced above.

=item *

L<Math::ModInt> - modular integer arithmetic.

=item *

L<PDL> - the Perl Data Language.

=item *

Moore, Emily H., Pollatsek, Harriet S., "Difference Sets", American
Mathematical Society, Providence, 2013, ISBN 978-0-8218-9176-6.

=item *

Dinitz, J.H., Stinson, D.R., "Contemporary Design Theory: A collection
of surveys", John Wiley and Sons, New York, 1992, ISBN 0-471-53141-3.

=item *

Gordon, Daniel M., "La Jolla Difference Set Repository".
L<https://www.dmgordon.org/diffset/>

=item *

The homepage of this project, L<https://vera.in-ulm.de/planar-diffsets/>.

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp I<at> cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2019-2023 by Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see the LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of merchantability
or fitness for a particular purpose.

=cut
