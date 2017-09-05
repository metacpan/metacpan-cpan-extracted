package Math::Vector::Real;

our $VERSION = '0.18';

use strict;
use warnings;
use Carp;
use POSIX ();

use Exporter qw(import);
our @EXPORT = qw(V);

our $dont_use_XS;
unless ($dont_use_XS) {
    my $xs_version = do {
	local ($@, $!, $SIG{__DIE__});
	eval {
	    require Math::Vector::Real::XS;
	    $Math::Vector::Real::XS::VERSION;
	}
    };

    if (defined $xs_version and $xs_version < 0.07) {
	croak "Old and buggy version of Math::Vector::Real::XS detected, update it!";
    }
}


our %op = (add => '+',
	   neg => 'neg',
	   sub => '-',
	   mul => '*',
	   div => '/',
	   cross => 'x',
	   add_me => '+=',
	   sub_me => '-=',
	   mul_me => '*=',
	   div_me => '/=',
	   abs => 'abs',
	   atan2 => 'atan2',
	   equal => '==',
	   nequal => '!=',
	   clone => '=',
	   as_string => '""');

our %ol;
$ol{$op{$_}} = \&{${Math::Vector::Real::}{$_}} for keys %op;

require overload;
overload->import(%ol);

sub V { bless [@_] }

sub new {
    my $class = shift;
    bless [@_], $class
}

sub new_ref {
    my $class = shift;
    bless [@{shift()}], $class;
}

sub zero {
    my ($class, $dim) = @_;
    $dim >= 0 or croak "negative dimension";
    bless [(0) x $dim], $class
}

sub is_zero {
    $_ and return 0 for @$_[0];
    return 1
}

sub cube {
    my ($class, $dim, $size) = @_;
    bless [($size) x $dim], $class;
}

sub axis_versor {
    my ($class, $dim, $ix);
    if (ref $_[0]) {
        my ($self, $ix) = @_;
        $class = ref $self;
        $dim = @$self;
    }
    else {
        ($class, $dim, $ix) = @_;
        $dim >= 0 or croak "negative dimension";
    }
    ($ix >= 0 and $ix < $dim) or croak "axis index out of range";
    my $self = [(0) x $dim];
    $self->[$ix] = 1;
    bless $self, $class
}

sub _caller_op {
    my $level = (shift||1) + 1;
    my $sub = (caller $level)[3];
    $sub =~ s/.*:://;
    my $op = $op{$sub};
    (defined $op ? $op : $sub);
}

sub _check_dim {
    local ($@, $SIG{__DIE__});
    eval { @{$_[0]} == @{$_[1]} } and return;
    my $op = _caller_op(1);
    my $loc = ($_[2] ? 'first' : 'second');
    UNIVERSAL::isa($_[1], 'ARRAY') or croak "$loc argument to vector operator '$op' is not a vector";
    croak "vector dimensions do not match";
}

sub clone { bless [@{$_[0]}] }

sub set {
    &_check_dim;
    my ($v0, $v1) = @_;
    $v0->[$_] = $v1->[$_] for 0..$#$v1;
}

sub add {
    &_check_dim;
    my ($v0, $v1) = @_;
    bless [map $v0->[$_] + $v1->[$_], 0..$#$v0]
}

sub add_me {
    &_check_dim;
    my ($v0, $v1) = @_;
    $v0->[$_] += $v1->[$_] for 0..$#$v0;
    $v0;
}

sub neg { bless [map -$_, @{$_[0]}] }

sub sub {
    &_check_dim;
    my ($v0, $v1) = ($_[2] ? @_[1, 0] : @_);
    bless [map $v0->[$_] - $v1->[$_], 0..$#$v0]
}

sub sub_me {
    &_check_dim;
    my ($v0, $v1) = @_;
    $v0->[$_] -= $v1->[$_] for 0..$#$v0;
    $v0;
}

sub mul {
    if (ref $_[1]) {
	&_check_dim;
	my ($v0, $v1) = @_;
	my $acu = 0;
	$acu += $v0->[$_] * $v1->[$_] for 0..$#$v0;
	$acu;
    }
    else {
	my ($v, $s) = @_;
	bless [map $s * $_, @$v];
    }
}

sub mul_me {
    ref $_[1] and croak "can not multiply by a vector in place as the result is not a vector";
    my ($v, $s) = @_;
    $_ *= $s for @$v;
    $v
}

sub div {
    croak "can't use vector as dividend"
	if ($_[2] or ref $_[1]);
    my ($v, $div) = @_;
    $div == 0 and croak "illegal division by zero";
    my $i = 1 / $div;
    bless [map $i * $_, @$v]
}

sub div_me {
    croak "can't use vector as dividend" if ref $_[1];
    my $v = shift;
    my $i = 1.0 / shift;
    $_ *= $i for @$v;
    $v;
}

sub equal {
    &_check_dim;
    my ($v0, $v1) = @_;
    $v0->[$_] == $v1->[$_] || return 0 for 0..$#$v0;
    1;
}

sub nequal {
    &_check_dim;
    my ($v0, $v1) = @_;
    $v0->[$_] == $v1->[$_] || return 1 for 0..$#$v0;
    0;
}

sub cross {
    &_check_dim;
    my ($v0, $v1) = ($_[2] ? @_[1, 0] : @_);
    my $dim = @$v0;
    if ($dim == 3) {
	return bless [$v0->[1] * $v1->[2] - $v0->[2] * $v1->[1],
		      $v0->[2] * $v1->[0] - $v0->[0] * $v1->[2],
		      $v0->[0] * $v1->[1] - $v0->[1] * $v1->[0]]
    }
    if ($dim == 7) {
	croak "cross product for dimension 7 not implemented yet, patches welcome!";
    }
    else {
	croak "cross product not defined for dimension $dim"
    }
}

sub as_string { "{" . join(", ", @{$_[0]}). "}" }

sub abs {
    my $acu = 0;
    $acu += $_ * $_ for @{$_[0]};
    sqrt $acu;
}

sub abs2 {
    my $acu = 0;
    $acu += $_ * $_ for @{$_[0]};
    $acu;
}

sub dist {
    &_check_dim;
    my ($v0, $v1) = @_;
    my $d2 = 0;
    for (0..$#$v0) {
	my $d = $v0->[$_] - $v1->[$_];
	$d2 += $d * $d;
    }
    sqrt($d2);
}

sub dist2 {
    &_check_dim;
    my ($v0, $v1) = @_;
    my $d2 = 0;
    for (0..$#$v0) {
	my $d = $v0->[$_] - $v1->[$_];
	$d2 += $d * $d;
    }
    $d2;
}

sub max_component {
    my $max = 0;
    for (@{shift()}) {
	my $abs = CORE::abs($_);
	$abs > $max and $max = $abs;
    }
    $max
}

sub min_component {
    my $self = shift; 
    my $min = CORE::abs($self->[0]);
    for (@$self) {
	my $abs = CORE::abs($_);
	$abs < $min and $min = $abs;
    }
    $min
}

sub manhattan_norm {
    my $n = 0;
    $n += CORE::abs($_) for @{$_[0]};
    return $n;
}

sub manhattan_dist {
    &_check_dim;
    my ($v0, $v1) = @_;
    my $d = 0;
    $d += CORE::abs($v0->[$_] - $v1->[$_]) for 0..$#$v0;
    return $d;
}

sub chebyshev_dist {
    &_check_dim;
    my ($v0, $v1) = @_;
    my $max = 0;
    for (0..$#$v0) {
        my $d = CORE::abs($v0->[$_] - $v1->[$_]);
        $max = $d if $d > $max;
    }
    $max;
}

sub _upgrade {
    my $dim;
    map {
	my $d = eval { @{$_} };
	defined $d or croak "argument is not a vector or array";
	if (defined $dim) {
	    $d == $dim or croak "dimensions do not match";
	}
	else {
	    $dim = $d;
	}
	UNIVERSAL::isa($_, __PACKAGE__) ? $_ : clone($_);
    } @_;
}

sub atan2 {
    my ($v0, $v1) = @_;
    if (@$v0 == 2) {
        my $dot = $v0->[0] * $v1->[0] + $v0->[1] * $v1->[1];
        my $cross = $v0->[0] * $v1->[1] - $v0->[1] * $v1->[0];
        return CORE::atan2($cross, $dot);
    }
    else {
        my $a0 = &abs($v0);
        return 0 unless $a0;
        my $u0 = $v0 / $a0;
        my $p = $v1 * $u0;
        CORE::atan2(&abs($v1 - $p * $u0), $p);
    }
}

sub versor {
    my $self = shift;
    my $f = 0;
    $f += $_ * $_ for @$self;
    $f == 0 and croak "Illegal division by zero";
    $f = 1/sqrt $f;
    bless [map $f * $_, @$self]
}

sub wrap {
    my ($self, $v) = @_;
    &_check_dim;

    bless [map  { my $s = $self->[$_];
		  my $c = $v->[$_];
		  $c - $s * POSIX::floor($c/$s) } (0..$#$self)];
}

sub first_orthant_reflection {
    my $self = shift;
    bless [map CORE::abs, @$self];
}

sub sum {
    ref $_[0] or shift; # works both as a class and as an instance method
    my $sum;
    if (@_) {
        $sum = V(@{shift()});
        $sum += $_ for @_;
    }
    return $sum;
}

sub box {
    shift;
    return unless @_;
    my $min = clone(shift);
    my $max = clone($min);
    my $dim = $#$min;
    for (@_) {
        for my $ix (0..$dim) {
            my $c = $_->[$ix];
            if ($max->[$ix] < $c) {
                $max->[$ix] = $c;
            }
            elsif ($min->[$ix] > $c) {
                $min->[$ix] = $c
            }
        }
    }
    wantarray ? ($min, $max) : $max - $min;
}

sub nearest_in_box {
    my $p = shift->clone;
    my ($min, $max) = Math::Vector::Real->box(@_);
    for (0..$#$p) {
        if ($p->[$_] < $min->[$_]) {
            $p->[$_] = $min->[$_];
        }
        elsif ($p->[$_] > $max->[$_]) {
            $p->[$_] = $max->[$_];
        }
    }
    $p
}

sub dist2_to_box {
    @_ > 1 or croak 'Usage: $v->dist2_to_box($w0, ...)';
    my $p = shift;
    my $d2 = 0;
    my ($min, $max) = Math::Vector::Real->box(@_);
    for (0..$#$p) {
        if ($p->[$_] < $min->[$_]) {
            my $d = $p->[$_] - $min->[$_];
            $d2 += $d * $d;
        }
        elsif ($p->[$_] > $max->[$_]) {
            my $d = $p->[$_] - $max->[$_];
            $d2 += $d * $d;
        }
    }
    $d2;
}

sub chebyshev_dist_to_box {
    @_ > 1 or croak 'Usage $v->chebyshev_dist_to_box($w0, ...)';
    my $p = shift;
    my $d = 0;
    my ($min, $max) = Math::Vector::Real->box(@_);
    for (0..$#$p) {
        if ($p->[$_] < $min->[$_]) {
            my $delta = CORE::abs($p->[$_] - $min->[$_]);
            $d = $delta if $delta > $d;
        }
        elsif ($p->[$_] > $max->[$_]) {
            my $delta = CORE::abs($p->[$_] - $min->[$_]);
            $d = $delta if $delta > $d;
        }
    }
    $d;
}

sub chebyshev_cut_box {
    @_ > 2 or croak 'Usage $v->chebyshev_cut_box($cd, $w0, ...)';
    my $p = shift;
    my $cd = shift;
    my ($min, $max) = Math::Vector::Real->box(@_);
    for (0..$#$p) {
        my $a = $p->[$_];
        my $a_min = $a - $cd;
        my $a_max = $a + $cd;
        my $b_min = $min->[$_];
        my $b_max = $max->[$_];
        return if $b_min > $a_max or $b_max < $a_min;
        $min->[$_] = $a_min if $b_min < $a_min;
        $max->[$_] = $a_max if $b_min > $a_max;
    }
    ($min, $max);
}

sub nearest_in_box_border {
    # TODO: this method can be optimized
    my $p = shift->clone;
    my ($b0, $b1) = Math::Vector::Real->box(@_);
    my $in = 0;
    for (0..$#$p) {
        if ($p->[$_] < $b0->[$_]) {
            $p->[$_] = $b0->[$_];
        }
        elsif ($p->[$_] > $b1->[$_]) {
            $p->[$_] = $b1->[$_];
        }
        else {
            $in++;
        }
    }
    if ($in == @$p) {
        # vector was inside the box
        my $min_d = 'inf';
        my ($comp, $comp_ix);
        for my $q ($b0, $b1) {
            for (0..$#$p) {
                my $d = CORE::abs($p->[$_] - $q->[$_]);
                if ($min_d > $d) {
                    $min_d = $d;
                    $comp = $q->[$_];
                    $comp_ix = $_;
                }
            }
        }
        $p->[$comp_ix] = $comp;
    }
    $p;
}

sub max_dist2_to_box {
    @_ > 1 or croak 'Usage: $v->max_dist2_to_box($w0, ...)';
    my $p = shift;
    my ($c0, $c1) = Math::Vector::Real->box(@_);
    my $d2 = 0;
    for (0..$#$p) {
        my $d0 = CORE::abs($c0->[$_] - $p->[$_]);
        my $d1 = CORE::abs($c1->[$_] - $p->[$_]);
        $d2 += ($d0 >= $d1 ? $d0 * $d0 : $d1 * $d1);
    }
    return $d2;
}

sub dist2_between_boxes {
    my ($class, $a0, $a1, $b0, $b1) = @_;
    my ($c0, $c1) = $class->box($a0, $a1);
    my ($d0, $d1) = $class->box($b0, $b1);
    my $d2 = 0;
    for (0..$#$c0) {
        my $e0 = $d0->[$_] - $c1->[$_];
        if ($e0 >= 0) {
            $d2 += $e0 * $e0;
        }
        else {
            my $e1 = $c0->[$_] - $d1->[$_];
            if ($e1 > 0) {
                $d2 += $e1 * $e1;
            }
        }
    }
    $d2;
}

*min_dist2_between_boxes = \&dist2_between_boxes;

sub max_dist2_between_boxes {
    my ($class, $a0, $a1, $b0, $b1) = @_;
    my ($c0, $c1) = $class->box($a0, $a1);
    my ($d0, $d1) = $class->box($b0, $b1);
    my $d2 = 0;
    for (0..$#$c0) {
        my $e0 = $d1->[$_] - $c0->[$_];
        my $e1 = $d0->[$_] - $c1->[$_];
        $e0 *= $e0;
        $e1 *= $e1;
        $d2 += ($e0 > $e1 ? $e0 : $e1);
    }
    $d2;
}

sub max_component_index {
    my $self = shift;
    return unless @$self;
    my $max = 0;
    my $max_ix = 0;
    for my $ix (0..$#$self) {
        my $c = CORE::abs($self->[$ix]);
        if ($c > $max) {
            $max = $c;
            $max_ix = $ix;
        }
    }
    $max_ix;
}

sub min_component_index {
    my $self = shift;
    return unless @$self;
    my $min = CORE::abs($self->[0]);
    my $min_ix = 0;
    for my $ix (1..$#$self) {
        my $c = CORE::abs($self->[$ix]);
        if ($c < $min) {
            $min = $c;
            $min_ix = $ix
        }
    }
    $min_ix;
}

sub decompose {
    my ($u, $v) = @_;
    my $p = $u * ($u * $v)/abs2($u);
    my $n = $v - $p;
    wantarray ? ($p, $n) : $n;
}

sub canonical_base {
    my ($class, $dim) = @_;
    my @base = map { bless [(0) x $dim], $class } 1..$dim;
    $base[$_][$_] = 1 for 0..$#base;
    return @base;
}

sub rotation_base_3d {
    my $v = shift;
    @$v == 3 or croak "rotation_base_3d requires a vector with three dimensions";
    $v = $v->versor;
    my $n = [0, 0, 0];
    for (0..2) {
        if (CORE::abs($v->[$_]) > 0.57) {
            $n->[($_ + 1) % 3] = 1;
            $n = $v->decompose($n)->versor;
            return ($v, $n, $v x $n);
        }
    }
    die "internal error, all the components where smaller than 0.57!";
}

sub rotate_3d {
    my $v = shift;
    my $angle = shift;
    my $c = cos($angle); my $s = sin($angle);
    my ($i, $j, $k) = $v->rotation_base_3d;
    my $rj = $c * $j + $s * $k;
    my $rk = $c * $k - $s * $j;
    if (wantarray) {
        return map { ($_ * $i) * $i + ($_ * $j) * $rj + ($_ * $k) * $rk } @_;
    }
    else {
        my $a = shift;
        return (($a * $i) * $i + ($a * $j) * $rj + ($a * $k) * $rk);
    }
}

sub normal_base { __PACKAGE__->complementary_base(@_) }

sub complementary_base {
    shift;
    @_ or croak "complementaty_base requires at least one argument in order to determine the dimension";
    my $dim = @{$_[0]};
    if ($dim == 2 and @_ == 1) {
        my $u = versor($_[0]);
        @$u = ($u->[1], -$u->[0]);
        return $u;
    }

    my @v = map clone($_), @_;
    my @base = Math::Vector::Real->canonical_base($dim);
    for my $i (0..$#v) {
        my $u = versor($v[$i]);
        $_ = decompose($u, $_) for @v[$i+1 .. $#v];
        $_ = decompose($u, $_) for @base;
    }

    my $last = $#base - @v;
    return if $last < 0;
    for my $i (0 .. $last) {
        my $max = abs2($base[$i]);
        if ($max < 0.3) {
            for my $j ($i+1 .. $#base) {
                my $d2 = abs2($base[$j]);
                if ($d2 > $max) {
                    @base[$i, $j] = @base[$j, $i];
                    last unless $d2 < 0.3;
                    $max = $d2;
                }
            }
        }
        my $versor = $base[$i] = versor($base[$i]);
        $_ = decompose($versor, $_) for @base[$i+1..$#base];
    }
    wantarray ? @base[0..$last] : $base[0];
}

sub select_in_ball {
    my $v = shift;
    my $r = shift;
    my $r2 = $r * $r;
    grep $v->dist2($_) <= $r2, @_;
}

sub select_in_ball_ref2bitmap {
    my $v = shift;
    my $r = shift;
    my $p = shift;
    my $r2 = $r * $r;
    my $bm = "\0" x int((@$p + 7) / 8);
    for my $ix (0..$#$p) {
        vec($bm, $ix, 1) = 1 if $v->dist2($p->[$ix]) <= $r2;
    }
    return $bm;
}

sub dist2_to_segment {
    my ($p, $a, $b) = @_;
    my $ab = $a - $b;
    my $ap = $a - $p;
    my $ap_ab = $ap * $ab;
    return norm2($ap) if $ap_ab <= 0;
    my $x = $ap * $ab / ($ab * $ab);
    return dist2($ap, $ab) if $x >= 1;
    return dist2($ap, $x * $ab);
}

sub dist_to_segment { sqrt(&dist_to_segment) }

sub dist2_between_segments {
    my ($class, $a, $b, $c, $d) = @_;

    my $ab = $a - $b;
    my $cd = $c - $d;
    my $bd = $b - $d;

    if (@$a > 2) {
        my $ab_ab = $ab * $ab;
        my $ab_cd = $ab * $cd;
        my $cd_cd = $cd * $cd;

        if (CORE::abs(1.0 - ($ab_cd * $ab_cd) / ($ab_ab * $cd_cd)) > 1e-10) {
            # This method works for non-parallel segments
            my $ab_bd = $ab * $bd;
            my $bd_cd = $bd * $cd;

            my $D01 = $ab_cd * $ab_cd - $ab_ab * $cd_cd;
            my $D21 = $cd_cd * $ab_bd - $bd_cd * $ab_cd;
            my $x = $D21 / $D01;
            return dist2_to_segment($b, $c, $d) if $x < 0;
            return dist2_to_segment($a, $c, $d) if $x > 1;

            my $D02 = $ab_cd * $ab_bd - $bd_cd * $ab_ab;
            my $y = $D02 / $D01;
            return dist2_to_segment($d, $a, $b) if $y < 0;
            return dist2_to_segment($c, $a, $b) if $y > 1;

            my $p = $b + $ab * $x;
            my $q = $d + $cd * $y;

            return $p->dist2($q);
        }
    }

    # We are in 2D or lines are parallel, we consider the distance
    # between one segment to the vertices of the other one and
    # viceverse and return the minimum.
    my $min_d2 = dist2_to_segment($a, $c, $d);
    my $d2 = dist2_to_segment($b, $c, $d);
    $d2 = dist2_to_segment($c, $a, $b);
    $min_d2 = $d2 if $d2 < $min_d2;
    $d2 = dist2_to_segment($d, $a, $b);
    $min_d2 = $d2 if $d2 < $min_d2;
    return $min_d2;
}

sub dist_between_segments { sqrt(&dist2_between_segments) }

# This is run *after* Math::Vector::Real::XS is loaded!
*norm = \&abs;
*norm2 = \&abs2;
*max = \&max_component;
*min = \&min_component;
*chebyshev_norm = \&max_component;

1;
__END__

=head1 NAME

Math::Vector::Real - Real vector arithmetic in Perl

=head1 SYNOPSIS

  use Math::Vector::Real;

  my $v = V(1.1, 2.0, 3.1, -4.0, -12.0);
  my $u = V(2.0, 0.0, 0.0,  1.0,   0.3);

  printf "abs(%s) = %d\n", $v, abs($b);
  my $dot = $u * $v;
  my $sub = $u - $v;
  # etc...

=head1 DESCRIPTION

A simple pure perl module to manipulate vectors of any dimension.

The function C<V>, always exported by the module, allows one to create
new vectors:

  my $v = V(0, 1, 3, -1);

Vectors are represented as blessed array references. It is allowed to
manipulate the arrays directly as far as only real numbers are
inserted (well, actually, integers are also allowed because from a
mathematical point of view, integers are a subset of the real
numbers).

Example:

  my $v = V(0.0, 1.0);

  # extending the 2D vector to 3D:
  push @$v, 0.0;

  # setting some component value:
  $v->[0] = 23;

Vectors can be used in mathematical expressions:

  my $u = V(3, 3, 0);
  $p = $u * $v;       # dot product
  $f = 1.4 * $u + $v; # scalar product and vector addition
  $c = $u x $v;       # cross product, only defined for 3D vectors
  # etc.

The currently supported operations are:

  + * /
  - (both unary and binary)
  x (cross product for 3D vectors)
  += -= *= /= x=
  == !=
  "" (stringfication)
  abs (returns the norm)
  atan2 (returns the angle between two vectors)

That, AFAIK, are all the operations that can be applied to vectors.

When an array reference is used in an operation involving a vector, it
is automatically upgraded to a vector. For instance:

  my $v = V(1, 2);
  $v += [0, 2];

=head2 Extra methods

Besides the common mathematical operations described above, the
following methods are available from the package.

Note that all these methods are non destructive returning new objects
with the result.

=over 4

=item $v = Math::Vector::Real->new(@components)

Equivalent to C<V(@components)>.

=item $zero = Math::Vector::Real->zero($dim)

Returns the zero vector of the given dimension.

=item $v = Math::Vector::Real->cube($dim, $size)

Returns a vector of the given dimension with all its components set to
C<$size>.

=item $u = Math::Vector::Real->axis_versor($dim, $ix)

Returns a unitary vector of the given dimension parallel to the axis
with index C<$ix> (0-based).

For instance:

  Math::Vector::Real->axis_versor(5, 3); # V(0, 0, 0, 1, 0)
  Math::Vector::Real->axis_versor(2, 0); # V(1, 0)

=item @b = Math::Vector::Real->canonical_base($dim)

Returns the canonical base for the vector space of the given
dimension.

=item $u = $v->versor

Returns the versor for the given vector.

It is equivalent to:

  $u = $v / abs($v);

=item $wrapped = $w->wrap($v)

Returns the result of wrapping the given vector in the box
(hyper-cube) defined by C<$w>.

Long description:

Given the vector C<W> and the canonical base C<U1, U2, ...Un> such
that C<W = w1*U1 + w2*U2 +...+ wn*Un>. For every component C<wi> we
can consider the infinite set of affine hyperplanes perpendicular to
C<Ui> such that they contain the point C<j * wi * Ui> being C<j> an
integer number.

The combination of all the hyperplanes defined by every component
define a grid that divides the space into an infinite set of affine
hypercubes. Every hypercube can be identified by its lower corner
indexes C<j1, j2, ..., jN> or its lower corner point C<j1*w1*U1 +
j2*w2*U2 +...+ jn*wn*Un>.

Given the vector C<V>, wrapping it by C<W> is equivalent to finding
where it lays relative to the lower corner point of the hypercube
inside the grid containing it:

  Wrapped = V - (j1*w1*U1 + j2*w2*U2 +...+ jn*wn*Un)

  such that ji*wi <= vi <  (ji+1)*wi

=item $max = $v->max_component

Returns the maximum of the absolute values of the vector components.

=item $min = $v->min_component

Returns the minimum of the absolute values of the vector components.

=item $d2 = $b->norm2

Returns the norm of the vector squared.

=item $d = $v->dist($u)

Returns the distance between the two vectors.

=item $d = $v->dist2($u)

Returns the distance between the two vectors squared.

=item $d = $v->manhattan_norm

Returns the norm of the vector calculated using the Manhattan metric.

=item $d = $v->manhattan_dist($u)

Returns the distance between the two vectors using the Manhattan metric.

=item $d = $v->chebyshev_norm

Returns the norm of the vector calculated using the Chebyshev metric
(note that this method is an alias for C<max_component>.

=item $d = $v->chebyshev_dist($u)

Returns the distance between the two vectors using the Chebyshev metric.

=item ($bottom, $top) = Math::Vector::Real->box($v0, $v1, $v2, ...)

Returns the two corners of the L<axis-aligned minimum bounding
box|http://en.wikipedia.org/wiki/Minimum_bounding_box#Axis-aligned_minimum_bounding_box>
(or L<hyperrectangle|http://en.wikipedia.org/wiki/Hyperrectangle>) for
the given vectors.

In scalar context returns the difference between the two corners (the
box diagonal vector).

=item $p = $v->nearest_in_box($w0, $w1, ...)

Returns the vector nearest to C<$v> from the axis-aligned minimum box
bounding the given set of vectors.

For instance, given a point C<$v> and an axis-aligned rectangle
defined by two opposite corners (C<$c0> and C<$c1>), this method can be
used to find the point nearest to C<$v> from inside the rectangle:

  my $n = $v->nearest_in_box($c0, $c1);

Note that if C<$v> lays inside the box, the nearest point is C<$v>
itself. Otherwise it will be a point from the box hyper-surface.

=item $d2 = $v->dist2_to_box($w0, $w1, ...)

Calculates the square of the minimal distance between the vector C<$v>
and the minimal axis-aligned box containing all the vectors C<($w0,
$w1, ...)>.

=item $d2 = $v->max_dist2_to_box($w0, $w1, ...)

Calculates the square of the maximum distance between the vector C<$v>
and the minimal axis-aligned box containing all the vectors C<($w0,
$w1, ...)>.

=item $d = $v->chebyshev_dist_to_box($w0, $w1, ...)

Calculates the minimal distance between the vector C<$v> and the
minimal axis-aligned box containing all the vectors C<($w0, $w1, ...)>
using the Chebyshev metric.

=item $d2 = Math::Vector::Real->dist2_between_boxes($a0, $a1, $b0, $b1)

Returns the square of the minimum distance between any two points
belonging to the boxes defined by C<($a0, $a1)> and
C<($b0, $b1)> respectively.

=item $d2 = Math::Vector::Real->max_dist2_between_boxes($a0, $a1, $b0, $b1)

Returns the square of the maximum distance between any two points
belonging respectively to the boxes defined by C<($a0, $a1)> and
C<($b0, $b1)>.

=item $d2 = $v->dist2_to_segment($a0, $a1)

Returns the square of the minimum distance between the given point
C<$v> and the line segment defined by the vertices C<$a0> and C<$a1>.

=item $d2 = Math::Vector::Real->dist2_between_segments($a0, $a1, $b0, $b1)

Returns the square of the distance between the line segment defined by
the vertices C<$a0> and C<$a1> and the one defined by the vertices
C<$b0> and C<$b1>.

Degenerated cases where the length of any segment is (too close to) 0
are not supported.

=item $v->set($u)

Equivalent to C<$v = $u> but without allocating a new object.

Note that this method is destructive.

=item $d = $v->max_component_index

Returns the index of the vector component with the maximum size.

=item $r = $v->first_orthant_reflection

Given the set of vectors formed by C<$v> and all its reflections
around the axis-aligned hyperplanes, this method returns the one lying
on the first orthant.

See also
[http://en.wikipedia.org/wiki/Reflection_%28mathematics%29|reflection]
and [http://en.wikipedia.org/wiki/Orthant|orthant].

=item ($p, $n) = $v->decompose($u)

Decompose the given vector C<$u> in two vectors: one parallel to C<$v>
and another normal.

In scalar context returns the normal vector.

=item $v = Math::Vector::Real->sum(@v)

Returns the sum of all the given vectors.

=item @b = Math::Vector::Real->complementary_base(@v)

Returns a base for the subspace complementary to the one defined by
the base @v.

The vectors on @v must be linearly independent. Otherwise a division
by zero error may pop up or probably due to rounding errors, just a
wrong result may be generated.

=item @b = $v->normal_base

Returns a set of vectors forming an orthonormal base for the hyperplane
normal to $v.

In scalar context returns just some unitary vector normal to $v.

Note that this two expressions are equivalent:

  @b = $v->normal_base;
  @b = Math::Vector::Real->complementary_base($v);

=item ($i, $j, $k) = $v->rotation_base_3d

Given a 3D vector, returns a list of 3 vectors forming an orthonormal
base where $i has the same direction as the given vector C<$v> and
C<$k = $i x $j>.

=item @r = $v->rotate_3d($angle, @s)

Returns the vectors C<@u> rotated around the vector C<$v> an
angle C<$angle> in radians in anticlockwise direction.

See L<http://en.wikipedia.org/wiki/Rotation_operator_(vector_space)>.

=item @s = $center->select_in_ball($radius, $v1, $v2, $v3, ...)

Selects from the list of given vectors those that lay inside the
n-ball determined by the given radius and center (C<$radius> and
C<$center> respectively).

=back

=head2 Zero vector handling

Passing the zero vector to some methods (i.e. C<versor>, C<decompose>,
C<normal_base>, etc.) is not acceptable. In those cases, the module
will croak with an "Illegal division by zero" error.

C<atan2> is an exceptional case that will return 0 when any of its
arguments is the zero vector (for consistency with the C<atan2> builtin
operating over real numbers).

In any case note that, in practice, rounding errors frequently cause
the check for the zero vector to fail resulting in numerical
instabilities.

The correct way to handle this problem is to introduce in your code
checks of this kind:

  if ($v->norm2 < $epsilon2) {
    croak "$v is too small";
  }

Or even better, reorder the operations to minimize the chance of
instabilities if the algorithm allows it.

=head2 Math::Vector::Real::XS

The module L<Math::Vector::Real::XS> reimplements most of the methods
available from this module in XS. C<Math::Vector::Real> automatically
loads and uses it when it is available.

=head1 SEE ALSO

L<Math::Vector::Real::Random> extends this module with random vector
generation methods.

L<Math::GSL::Vector>, L<PDL>.

There are other vector manipulation packages in CPAN (L<Math::Vec>,
L<Math::VectorReal>, L<Math::Vector>), but they can only handle 3
dimensional vectors.

=head1 SUPPORT

In order to report bugs you can send me and email to the address that
appears below or use the CPAN RT bug-tracking system available at
L<http://rt.cpan.org>.

The source for the development version of the module is hosted at
GitHub: L<https://github.com/salva/p5-Math-Vector-Real>.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
wishlist: L<http://amzn.com/w/1WU1P6IR5QZ42>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012, 2014-2017 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
