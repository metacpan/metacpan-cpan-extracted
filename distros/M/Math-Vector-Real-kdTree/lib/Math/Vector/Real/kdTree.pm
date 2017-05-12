package Math::Vector::Real::kdTree;

our $VERSION = '0.15';

use 5.010;
use strict;
use warnings;
use Carp;

use Math::Vector::Real;
use Sort::Key::Top qw(nkeypartref nhead ntail nkeyhead);
use Hash::Util::FieldHash qw(idhash);

our $max_per_pole = 12;
our $recommended_per_pole = 6;

use constant _n    => 0; # elements on subtree
use constant _c0   => 1; # corner 0
use constant _c1   => 2; # corner 1
use constant _sum  => 3; # centroid * n
use constant _s0   => 4; # subtree 0
use constant _s1   => 5; # subtree 1
use constant _axis => 6; # cut axis
use constant _cut  => 7; # cut point (mediam)

# on leaf nodes:
use constant _ixs   => 4;
use constant _leaf_size => _ixs + 1;

sub new {
    my $class = shift;
    my @v = map V(@$_), @_;
    my $self = { vs   => \@v,
                 tree => (@v ? _build(\@v, [0..$#v]) : undef) };
    bless $self, $class;
}

sub clone {
    my $self = shift;
    require Storable;
    my $clone = { vs   => [@{$self->{vs}}],
                  tree => Storable::dclone($self->{tree}) };
    $clone->{hidden} = { %{$self->{hidden}} } if $self->{hidden};
    bless $clone, ref $self;
}

sub _build {
    my ($v, $ixs) = @_;
    if (@$ixs > $recommended_per_pole) {
        my ($b, $t) = Math::Vector::Real->box(@$v[@$ixs]);
        my $axis = ($t - $b)->max_component_index;
        my $bstart = @$ixs >> 1;
        my ($p0, $p1) = nkeypartref { $v->[$_][$axis] } $bstart => @$ixs;
        my $s0 = _build($v, $p0);
        my $s1 = _build($v, $p1);
        my ($c0, $c1) = Math::Vector::Real->box(@{$s0}[_c0, _c1], @{$s1}[_c0, _c1]);
        my $cut = 0.5 * ($s0->[_c1][$axis] + $s1->[_c0][$axis]);
        # warn "b: $b, t: $t, axis: $axis, p0: $p0, p1: $p1, s0: $s0, s1: $s1, c0: $c0, c1: $c1, cut: $cut\n";
        # [n sum s0 s1 axis cut]
        [scalar(@$ixs), $c0, $c1, $s0->[_sum] + $s1->[_sum], $s0, $s1, $axis, $cut];
    }
    else {
        # [n, sum, ixs]
        my @vs = @{$v}[@$ixs];
        my ($c0, $c1) = Math::Vector::Real->box(@vs);
        [scalar(@$ixs), $c0, $c1, Math::Vector::Real->sum(@vs), $ixs];
    }
}

sub size { scalar @{shift->{vs}} }

sub at {
    my ($self, $ix) = @_;
    Math::Vector::Real::clone($self->{vs}[$ix]);
}

sub insert {
    my $self = shift;
    @_ or return;
    my $vs = $self->{vs};
    my $ix = @$vs;
    if (my $tree = $self->{tree}) {
        for (@_) {
            my $v = V(@$_);
            push @$vs, $v;
            _insert($vs, $self->{tree}, $#$vs)
        }
    }
    else {
        @$vs = map V(@$_), @_;
        $self->{tree} = _build($vs, [0..$#$vs]);
    }
    return $ix;
}

# _insert does not return anything but modifies its $t argument in
# place. This is really ugly but done to improve performance.

sub _insert {
    my ($vs, $t, $ix) = @_;
    my $v = $vs->[$ix];

    # update aggregated values
    my $n = $t->[_n]++;
    @{$t}[_c0, _c1] = Math::Vector::Real->box($v, @{$t}[_c0, _c1]);
    $t->[_sum] += $v;

    if (defined (my $axis = $t->[_axis])) {
        my $cut = $t->[_cut];
        my $c = $v->[$axis];

        my $n0 = $t->[_s0][_n];
        my $n1 = $t->[_s1][_n];

        if ($c <= $cut) {
            if (2 * $n1 + $max_per_pole >= $n0) {
                _insert($vs, $t->[_s0], $ix);
                return;
            }
        }
        else {
            if (2 * $n0 + $max_per_pole >= $n1) {
                _insert($vs, $t->[_s1], $ix);
                return;
            }
        }

        # tree needs rebalancing
        my @store;
        $#store = $n; # preallocate space
        @store = ($ix);
        _push_all($t, \@store);
        $_[1] = _build($vs, \@store);
    }
    else {
        my $ixs = $t->[_ixs];
        push @$ixs, $ix;
        if ($n > $max_per_pole) {
            $_[1] = _build($vs, $ixs);
        }
    }
}

sub move {
    my ($self, $ix, $v) = @_;
    my $vs = $self->{vs};
    ($ix >= 0 and $ix < @$vs) or croak "index out of range";
    _delete($vs, $self->{tree}, $ix);
    $vs->[$ix] = Math::Vector::Real::clone($v);
    _insert($vs, $self->{tree}, $ix);
}

sub _delete {
    my ($vs, $t, $ix) = @_;
    if (defined (my $axis = $t->[_axis])) {
        my $v = $vs->[$ix];
        my $c = $v->[$axis];
        my ($s0, $s1, $cut) = @{$t}[_s0, _s1, _cut];
        if ($c <= $cut and _delete($vs, $s0, $ix)) {
            if ($s0->[_n]) {
                $t->[_n]--;
                $t->[_sum] -= $v;
            }
            else {
                # when one subnode becomes empty, the other gets promoted up:
                @$t = @$s1;
            }
            return 1;
        }
        elsif ($c >= $cut and _delete($vs, $s1, $ix)) {
            if ($s1->[_n]) {
                $t->[_n]--;
                $t->[_sum] -= $v;
            }
            else {
                @$t = @$s0;
            }
            return 1;
        }
    }
    else {
        my $ixs = $t->[_ixs];
        for (0..$#$ixs) {
            if ($ixs->[$_] == $ix) {
                splice(@$ixs, $_, 1);
                $t->[_n]--;
                $t->[_sum] -= $vs->[$ix];
                return 1;
            }
        }
    }
    return 0;
}

sub hide {
    my ($self, $ix) = @_;
    my $vs = $self->{vs};
    ($ix >= 0 and $ix < @$vs) or croak "index out of range";
    _delete($vs, $self->{tree}, $ix);
    ($self->{hidden} //= {})->{$ix} = 1;
}

sub _push_all {
    my ($t, $store) = @_;
    my @q;
    while ($t) {
        if (defined $t->[_axis]) {
            push @q, $t->[_s1];
            $t = $t->[_s0];
        }
        else {
            push @$store, @{$t->[_ixs]};
            $t = pop @q;
        }
    }
}

sub path {
    my ($self, $ix) = @_;
    my $p = _path($self->{vs}, $self->{tree}, $ix);
    my $l = 1;
    $l = (($l << 1) | $_) for @$p;
    $l
}

sub _path {
    my ($vs, $t, $ix) = @_;
    if (defined (my $axis = $t->[_axis])) {
        my $v = $vs->[$ix];
        my $c = $v->[$axis];
        my $cut = $t->[_cut];
        my $p;
        if ($c <= $cut) {
            if ($p = _path($vs, $t->[_s0], $ix)) {
                unshift @$p, 0;
                return $p;
            }
        }
        if ($c >= $cut) {
            if ($p = _path($vs, $t->[_s1], $ix)) {
                unshift @$p, 1;
                return $p;
            }
        }
    }
    else {
        return [] if grep $_ == $ix, @{$t->[_ixs]}
    }
    ()
}

sub find {
    my ($self, $v) = @_;
    _find($self->{vs}, $self->{tree}, $v);
}

sub _find {
    my ($vs, $t, $v) = @_;
    while (defined (my $axis = $t->[_axis])) {
        my $cut = $t->[_cut];
        my $c = $v->[$axis];
        if ($c < $cut) {
            $t = $t->[_s0];
        }
        else {
            if ($c == $cut) {
                my $ix = _find($vs, $t->[_s0], $v);
                return $ix if defined $ix;
            }
            $t = $t->[_s1];
        }
    }

    for (@{$t->[_ixs]}) {
        return $_ if $vs->[$_] == $v;
    }
    ()
}

sub find_nearest_vector {
    my ($self, $v, $d, @but) = @_;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my $d2 = (defined $d ? $d * $d : 'inf');

    my $but;
    if (@but) {
        if (@but == 1 and ref $but[0] eq 'HASH') {
            $but = $but[0];
        }
        else {
            my %but = map { $_ => 1 } @but;
            $but = \%but;
        }
    }

    my ($rix, $rd2) = _find_nearest_vector($vs, $t, $v, $d2, undef, $but);
    $rix // return;
    wantarray ? ($rix, sqrt($rd2)) : $rix;
}

*find_nearest_neighbor = \&find_nearest_vector; # for backwards compatibility

sub find_nearest_vector_internal {
    my ($self, $ix, $d) = @_;
    $ix >= 0 or croak "index out of range";
    $self->find_nearest_vector($self->{vs}[$ix], $d, $ix);
}

*find_nearest_neighbor_internal = \&find_nearest_vector_internal; # for backwards compatibility

sub _find_nearest_vector {
    my ($vs, $t, $v, $best_d2, $best_ix, $but) = @_;

    my @queue;
    my @queue_d2;

    while (1) {
        if (defined (my $axis = $t->[_axis])) {
            # substitute the current one by the best subtree and queue
            # the worst for later
            ($t, my ($q)) = @{$t}[($v->[$axis] <= $t->[_cut]) ? (_s0, _s1) : (_s1, _s0)];
            my $q_d2 = $v->dist2_to_box(@{$q}[_c0, _c1]);
            if ($q_d2 <= $best_d2) {
                my $j;
                for ($j = $#queue_d2; $j >= 0; $j--) {
                    last if $queue_d2[$j] >= $q_d2;
                }
                splice @queue, ++$j, 0, $q;
                splice @queue_d2, $j, 0, $q_d2;
            }
        }
        else {
            for (@{$t->[_ixs]}) {
                next if $but and $but->{$_};
                my $d21 = $vs->[$_]->dist2($v);
                if ($d21 <= $best_d2) {
                    $best_d2 = $d21;
                    $best_ix = $_;
                }
            }

            if ($t = pop @queue) {
                if ($best_d2 >= pop @queue_d2) {
                    next;
                }
            }

            return ($best_ix, $best_d2);
        }
    }
}

sub find_nearest_vector_in_box {
    my ($self, $v, $a, $b, $d, @but) = @_;

    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my ($a1, $b1) = Math::Vector::Real->box($a, $b);
    my $d2 = (defined $d ? $d * $d : $v->max_dist2_to_box($a1, $b1));
    my $but;
    if (@but) {
        if (@but == 1 and ref $but[0] eq 'HASH') {
            $but = $but[0];
        }
        else {
            my %but = map { $_ => 1 } @but;
            $but = \%but;
        }
    }
    my ($rix, $rd2) = _find_nearest_vector_in_box($vs, $t, $v, $a1, $b1, $d2, $but);
    $rix // return;
    wantarray ? ($rix, sqrt($rd2)) : $rix;
}

sub _find_nearest_vector_in_box {
    my ($vs, $t, $v, $a, $b, $best_d2, $but) = @_;
    my $best_ix;
    my @queue = $t;
    my @queue_d2 = 0;

    while (my $t = pop @queue) {
        last if $best_d2 < pop @queue_d2;
        if (defined (my $axis = $t->[_axis])) {
            my @sides;
            push @sides, $t->[_s0] if $a->[$axis] <= $t->[_cut];
            push @sides, $t->[_s1] if $b->[$axis] >= $t->[_cut];
            for my $s (@sides) {
                my $d2 = $v->dist2_to_box(@$s[_c0, _c1]);
                if ($d2 <= $best_d2) {
                    my $j;
                    for ($j = $#queue_d2; $j >= 0; $j--) {
                        last if $queue_d2[$j] >= $d2;
                    }
                    splice @queue, ++$j, 0, $s;
                    splice @queue_d2, $j, 0, $d2;
                }
            }
        }
        else {
            for (@{$t->[_ixs]}) {
                next if $but and $but->{$_};
                my $v1 = $vs->[$_];
                my $d2 = $v1->dist2($v);
                if ($d2 <= $best_d2 and $v1->dist2_to_box($a, $b) == 0) {
                    $best_d2 = $d2;
                    $best_ix = $_;
                }
            }
        }
    }
    return ($best_ix, $best_d2);
}

sub find_nearest_vector_in_box_chebyshev {
    my ($self, $v, $a, $b, $d, @but) = @_;

    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my ($a1, $b1) = Math::Vector::Real->box($a, $b);
    my $d2 = (defined $d ? $d * $d : $v->max_dist2_to_box($a1, $b1));
    my $but;
    if (@but) {
        if (@but == 1 and ref $but[0] eq 'HASH') {
            $but = $but[0];
        }
        else {
            my %but = map { $_ => 1 } @but;
            $but = \%but;
        }
    }
    my ($rix, $rd2) = _find_nearest_vector_in_box($vs, $t, $v, $a1, $b1, $d2, $but);
    $rix // return;
    wantarray ? ($rix, sqrt($rd2)) : $rix;
}

sub _find_nearest_vector_in_box_chebyshev {
    my ($vs, $t, $v, $a, $b, $best_d, $but) = @_;
    my $best_ix;
    my @queue = $t;
    my @queue_d = 0;

    while (my $t = pop @queue) {
        last if $best_d < pop @queue_d;
        if (defined (my $axis = $t->[_axis])) {
            my @sides;
            push @sides, $t->[_s0] if $a->[$axis] <= $t->[_cut];
            push @sides, $t->[_s1] if $b->[$axis] >= $t->[_cut];
            for my $s (@sides) {
                my $d = $v->chebyshev_dist_to_box(@$s[_c0, _c1]);
                if ($d <= $best_d) {
                    my $j;
                    for ($j = $#queue_d; $j >= 0; $j--) {
                        last if $queue_d[$j] >= $d;
                    }
                    splice @queue, ++$j, 0, $s;
                    splice @queue_d, $j, 0, $d;
                }
            }
        }
        else {
            for (@{$t->[_ixs]}) {
                next if $but and $but->{$_};
                my $v1 = $vs->[$_];
                my $d = $v1->chebyshev_dist($v);
                if ($d <= $best_d and $v1->chebyshev_dist_to_box($a, $b) == 0) {
                    $best_d = $d;
                    $best_ix = $_;
                }
            }
        }
    }
    return ($best_ix, $best_d);
}

sub find_nearest_vector_all_internal {
    my ($self, $d) = @_;
    my $vs = $self->{vs};
    return unless @$vs > 1;
    my $d2 = (defined $d ? $d * $d : 'inf');

    my @best = ((undef) x @$vs);
    my @d2   = (($d2)   x @$vs);
    _find_nearest_vector_all_internal($vs, $self->{tree}, \@best, \@d2);
    return @best;
}

*find_nearest_neighbor_all_internal = \&find_nearest_vector_all_internal; # for backwards compatibility

sub _find_nearest_vector_all_internal {
    my ($vs, $t, $bests, $d2s) = @_;
    if (defined (my $axis = $t->[_axis])) {
        my @all_leafs;
        for my $side (0, 1) {
            my @leafs = _find_nearest_vector_all_internal($vs, $t->[_s0 + $side], $bests, $d2s);
            my $other = $t->[_s1 - $side];
            my ($c0, $c1) = @{$other}[_c0, _c1];
            for my $leaf (@leafs) {
                for my $ix (@{$leaf->[_ixs]}) {
                    my $v = $vs->[$ix];
                    if ($v->dist2_to_box($c0, $c1) < $d2s->[$ix]) {
                        ($bests->[$ix], $d2s->[$ix]) =
                            _find_nearest_vector($vs, $other, $v, $d2s->[$ix], $bests->[$ix]);
                    }
                }
            }
            push @all_leafs, @leafs;
        }
        return @all_leafs;
    }
    else {
        my $ixs = $t->[_ixs];
        for my $i (1 .. $#$ixs) {
            my $ix_i = $ixs->[$i];
            my $v_i = $vs->[$ix_i];
            for my $ix_j (@{$ixs}[0 .. $i - 1]) {
                my $d2 = $v_i->dist2($vs->[$ix_j]);
                if ($d2 < $d2s->[$ix_i]) {
                    $d2s->[$ix_i] = $d2;
                    $bests->[$ix_i] = $ix_j;
                }
                if ($d2 < $d2s->[$ix_j]) {
                    $d2s->[$ix_j] = $d2;
                    $bests->[$ix_j] = $ix_i;
                }
            }
        }
        return $t;
    }
}

sub find_two_nearest_vectors {
    my $self = shift;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    if (my ($rix0, $rix1, $rd2) = _find_two_nearest_vectors($vs, $t)) {
        return wantarray ? ($rix0, $rix1, sqrt($rd2)) : sqrt($rd2)
    }
    ()
}

sub _pole_id {
    my ($id, $deep) = __pole_id(@_);
    "$id/$deep";
}

sub __pole_id {
    my ($vs, $t) = @_;
    if (defined $t->[_axis]) {
        my ($id, $deep) = __pole_id($vs, $t->[_s0]);
        return ($id, $deep+1);
    }
    return ($t->[_ixs][0], 0)
}

sub _find_two_nearest_vectors {
    my ($vs, $t) = @_;

    my @best_ixs = (undef, undef);
    my $best_d2 = 'inf' + 0;

    my @inner;
    my @queue_t1;
    my @queue_t2;
    while ($t) {
        if (defined $t->[_axis]) {
            my ($s0, $s1) = @{$t}[_s0, _s1];
            push @inner, $s1;
            push @queue_t1, $s0;
            push @queue_t2, $s1;
            $t = $s0;
        }
        else {
            my $ixs = $t->[_ixs];
            for my $i (1 .. $#$ixs) {
                my $ix1 = $ixs->[$i];
                my $v1 = $vs->[$ix1];
                for my $j (0 .. $i - 1) {
                    my $ix2 = $ixs->[$j];
                    my $d2 = Math::Vector::Real::dist2($v1, $vs->[$ix2]);
                    if ($d2 < $best_d2) {
                        $best_d2 = $d2;
                        @best_ixs = ($ix1, $ix2);
                    }
                }
            }
            $t = pop @inner;
        }
    }

    my @queue_d2 = (0) x @queue_t1;
    while (my $t1 = pop @queue_t1) {
        my $t2 = pop @queue_t2;
        my $d2 = pop @queue_d2;
        if ($d2 < $best_d2) {
            unless (defined $t1->[_axis]) {
                unless (defined $t2->[_axis]) {
                    for my $ix1 (@{$t1->[_ixs]}) {
                        my $v1 = $vs->[$ix1];
                        for my $ix2 (@{$t2->[_ixs]}) {
                            my $d2 = Math::Vector::Real::dist2($v1, $vs->[$ix2]);
                            if ($d2 < $best_d2) {
                                $best_d2 = $d2;
                                @best_ixs = ($ix1, $ix2);
                            }
                        }
                    }
                    next;
                }
                ($t1, $t2) = ($t2, $t1);
            }
            for my $s (@{$t1}[_s0, _s1]) {
                my $d2 = Math::Vector::Real->dist2_between_boxes(@{$s}[_c0, _c1], @{$t2}[_c0, _c1]);
                if ($d2) {
                    if ($d2 < $best_d2) {
                        unshift @queue_t1, $t2;
                        unshift @queue_t2, $s;
                        unshift @queue_d2, $d2;
                    }
                }
                else {
                    push @queue_t1, $t2;
                    push @queue_t2, $s;
                    push @queue_d2, 0;
                }
            }
        }
    }
    (@best_ixs, $best_d2)
}

sub find_in_ball {
    my ($self, $z, $d, $but) = @_;
    if (defined $but and ref $but ne 'HASH') {
        $but = { $but => 1 };
    }
    _find_in_ball($self->{vs}, $self->{tree}, $z, $d * $d, $but);
}

sub _find_in_ball {
    my ($vs, $t, $z, $d2, $but) = @_;
    my (@queue, @r);
    my $r = 0;

    while (1) {
        if (defined (my $axis = $t->[_axis])) {
            my $c = $z->[$axis];
            my $cut = $t->[_cut];
            ($t, my ($q)) = @{$t}[$c <= $cut ? (_s0, _s1) : (_s1, _s0)];
            push @queue, $q if $z->dist2_to_box(@{$q}[_c0, _c1]) <= $d2;
        }
        else {
            my $ixs = $t->[_ixs];
            if (wantarray) {
                push @r, grep { $vs->[$_]->dist2($z) <= $d2 } @$ixs;
            }
            else {
                $r += ( $but
                        ? grep { !$but->{$_} and $vs->[$_]->dist2($z) <= $d2 } @$ixs
                        : grep { $vs->[$_]->dist2($z) <= $d2 } @$ixs );
            }

            $t = pop @queue or last;
        }
    }

    if (wantarray) {
        if ($but) {
            return grep !$but->{$_}, @r;
        }
        return @r;
    }
    return $r;
}

sub find_in_box {
    my ($self, $a, $b, $but) = @_;
    my ($a1, $b1) = Math::Vector::Real->box($a, $b);
    if (defined $but and ref $but ne 'HASH') {
        $but = { $but => 1 };
    }
    _find_in_box($self->{vs}, $self->{tree}, $a1, $b1, $but);
}

sub _find_in_box {
    my ($vs, $t, $a, $b, $but) = @_;
    my (@r, $r);
    my @queue;
    while (1) {
        if (defined (my $axis = $t->[_axis])) {
            my $cut = $t->[_cut];
            push @queue, $t->[_s0] if $cut >= $a->[$axis];
            push @queue, $t->[_s1] if $cut <= $b->[$axis];
        }
        else {
            my $ixs = $t->[_ixs];
            if (wantarray) {
                push @r, grep { $vs->[$_]->dist2_to_box($a, $b) <= 0 } @$ixs;
            }
            else {
                $r += ( $but
                        ? grep { !$but->{$_} and $vs->[$_]->dist2_to_box($a, $b) <= 0 } @$ixs
                        : grep { $vs->[$_]->dist2_to_box($a, $b) <= 0 } @$ixs );
            }
        }
        $t = pop @queue or last;
    }

    if (wantarray) {
        if ($but) {
            return grep !$but->{$_}, @r;
        }
        return @r;
    }
    return $r;
}

sub find_farthest_vector {
    my ($self, $v, $d, @but) = @_;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my $d2 = ($d ? $d * $d : -1);
    my $but;
    if (@but) {
        if (@but == 1 and ref $but[0] eq 'HASH') {
            $but = $but[0];
        }
        else {
            my %but = map { $_ => 1 } @but;
            $but = \%but;
        }
    }

    my ($rix, $rd2) = _find_farthest_vector($vs, $t, $v, $d2, undef, $but);
    $rix // return;
    wantarray ? ($rix, sqrt($d2)) : $rix;
}

sub find_farthest_vector_internal {
    my ($self, $ix, $d) = @_;
    $ix >= 0 or croak "index out of range";
    $self->find_farthest_vector($self->{vs}[$ix], $d, $ix);
}

sub _find_farthest_vector {
    my ($vs, $t, $v, $best_d2, $best_ix, $but) = @_;

    my @queue;
    my @queue_d2;

    while (1) {
        if (defined (my $axis = $t->[_axis])) {
            # substitute the current one by the best subtree and queue
            # the worst for later
            ($t, my ($q)) = @{$t}[($v->[$axis] >= $t->[_cut]) ? (_s0, _s1) : (_s1, _s0)];
            my $q_d2 = $v->max_dist2_to_box(@{$q}[_c0, _c1]);
            if ($q_d2 >= $best_d2) {
                my $j;
                for ($j = $#queue_d2; $j >= 0; $j--) {
                    last if $queue_d2[$j] <= $q_d2;
                }
                splice @queue, ++$j, 0, $q;
                splice @queue_d2, $j, 0, $q_d2;
            }
        }
        else {
            for (@{$t->[_ixs]}) {
                next if $but and $but->{$_};
                my $d21 = $vs->[$_]->dist2($v);
                if ($d21 >= $best_d2) {
                    $best_d2 = $d21;
                    $best_ix = $_;
                }
            }

            if ($t = pop @queue) {
                if ($best_d2 <= pop @queue_d2) {
                    next;
                }
            }
            return ($best_ix, $best_d2);
        }
    }
}

sub find_random_vector {
    my $self = shift;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my $hidden = $self->{hidden};
    if (not $hidden or @$vs > 20 * keys(%$hidden)) {
        # pick directly when the hidden elements are less than 5% of the total
        while (1) {
            my $ix = int rand @$vs;
            return $ix unless $hidden and $hidden->{$ix};
        }
    }
    _find_random_vector($vs, $t);
}

sub _find_random_vector {
    my ($vs, $t) = @_;
    while (defined $t->[_axis]) {
        $t = $t->[rand($t->[_n]) < $t->[_s0][_n] ? _s0 : _s1];
    }
    $t->[_ixs][rand $t->[_n]]
}

sub k_means_seed {
    my ($self, $n_req) = @_;
    $n_req = int($n_req) or return;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    _k_means_seed($vs, $t, $n_req);
}

*k_means_start = \&k_means_seed;

sub _k_means_seed {
    my ($vs, $t, $n_req) = @_;
    if ($n_req <= 1) {
        return if $n_req < 1;
        # print STDERR "returning centroid\n";
        return $t->[_sum] / $t->[_n];
    }
    else {
        my $n = $t->[_n];
        if (defined $t->[_axis]) {
            my ($s0, $s1) = @{$t}[_s0, _s1];
            my $n0 = $s0->[_n];
            my $n1 = $s1->[_n];
            my $n0_req = int(0.5 + $n_req * ($n0 / $n));
            $n0_req = $n0 if $n0_req > $n0;
            return (_k_means_seed($vs, $s0, $n0_req),
                    _k_means_seed($vs, $s1, $n_req - $n0_req));
        }
        else {
            my $ixs = $t->[_ixs];
            my @out;
            for (0..$#$ixs) {
                push @out, $vs->[$ixs->[$_]]
                    if rand($n - $_) < ($n_req - @out);
            }
            # print STDERR "asked for $n_req elements, returning ".scalar(@out)."\n";

            return @out;
        }
    }
}

our $k_means_seed_pp_test;

sub _k_means_seed_pp_test {
    my ($self, $err, $kms, $players, $weights) = @_;
    my @w;
    my $last = 0;
    for my $i (0..$#$players) {
        my $p = $players->[$i];
        my $w = $weights->[$i] - $last;
        $last = $weights->[$i];

        my @store;
        if (ref $p) {
            _push_all($p, \@store);
        }
        else {
            @store = $p
        }
        if (@store) {
            $w /= @store;
            $w[$_] = $w for @store;
        }
    }
    my $vs = $self->{vs};
    $w[$_] //= 0 for 0..$#$vs;

    $k_means_seed_pp_test->($self, $err, [map $self->{vs}[$_], @$kms], \@w);
}

sub k_means_seed_pp {
    my ($self, $n_req, $err) = @_;
    $n_req = int($n_req) or return;
    $err ||= 0.5;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};
    my $km = $self->find_random_vector;

    my (@km, @d2);
    idhash my %extra; # [$min_d2, $max_d2]

    # my (@player, @weight, @queue);
    # $#player = @$vs; # preallocate memory

    my (@weight, @queue);
    $#weight = @$vs; # preallocate memory

    while (1) {
        push @km, $km;
        last unless @km < $n_req;

        # update distances
        @queue = $t;
        while (my $p = pop @queue) {
            my $kmv = $vs->[$km];
            my ($c0, $c1) = @{$p}[_c0, _c1];
            my $extra = $extra{$p} //= ['inf', 'inf'];
            my ($min_d2, $max_d2) = @$extra;
            my $min_d2_to_box = $kmv->dist2_to_box($c0, $c1);
            if ($max_d2 > $min_d2_to_box) {
                if (defined $p->[_axis]) {
                    push @queue, @{$p}[_s0, _s1];
                }
                else {
                    for (@{$p->[_ixs]}) {
                        my $d2 = $kmv->dist2($vs->[$_]);
                        if ($d2 < ($d2[$_] //= $d2)) {
                            $d2[$_] = $d2;
                        }
                    }
                }

                if ($min_d2_to_box < $min_d2) {
                    $extra->[0] = $min_d2_to_box;
                }

                my $max_d2_to_box = $kmv->max_dist2_to_box($c0, $c1);
                if ($max_d2_to_box < $max_d2) {
                    $extra->[1] = $max_d2_to_box;
                }
            }
        }

        # find players and weight them
        my $weight = 0;
        # @player = ();
        @weight = ();

        # @queue = $t;
        # while (my $p = pop @queue) {
        #     my $extra = $extra{$p} or die "internal error: extra information missing for $p";
        #     my ($min_d2, $max_d2) = @$extra;

        #     if ($max_d2 * $err < $min_d2) {
        #         $weight += $p->[_n] * ($min_d2 + $max_d2) * 0.5;
        #         push @weight, $weight;
        #         push @player, $p;
        #     }
        #     else {
        #         if (defined $p->[_axis]) {
        #             push @queue, @{$p}[_s0, _s1];
        #         }
        #         else {
        #             for (@{$p->[_ixs]}) {
        #                 if (my $d2 = $d2[$_]) {
        #                     $weight += $d2;
        #                     push @weight, $weight;
        #                     push @player, $_;
        #                 }
        #             }
        #         }
        #     }
        # }

        for my $ix (0..@$vs) {
            $weight += $d2[$ix] // 0;
            $weight[$ix] += $weight;
        }

        # in order to check the algorithm we have to tap it here
        # $k_means_seed_pp_test and @km > 1 and
        #    $self->_k_means_seed_pp_test($err, \@km, \@player, \@weight);

        # to many k-means requested?
        # @player or last;

        # select a position on the weight queue:
        my $dice = rand($weight);

        # and use binary search to look for it:
        my $i = 0;
        my $j = @weight;
        while ($i < $j) {
            my $pivot = (($i + $j) >> 1);
            if ($weight[$pivot] < $dice) {
                $i = $pivot + 1;
            }
            else {
                $j = $pivot;
           }
        }
        #my $player = $player[$i];
        #$km = (ref $player ? _find_random_vector($vs, $player) : $player);
        $km = $i;
    }
    return @{$vs}[@km];
}

sub k_means_loop {
    my ($self, @k) = @_;
    @k or next;
    my $t = $self->{tree} or next;
    my $vs = $self->{vs};
    while (1) {
        my $diffs;
        my @n = ((0) x @k);
        my @sum = ((undef) x @k);

        _k_means_step($vs, $t, \@k, [0..$#k], \@n, \@sum);

        for (0..$#k) {
            if (my $n = $n[$_]) {
                my $k = $sum[$_] / $n;
                $diffs++ if $k != $k[$_];
                $k[$_] = $k;
            }
        }
        unless ($diffs) {
            return (wantarray ? @k : $k[0]);
        }
    }
}

sub k_means_step {
    my $self = shift;
    @_ or return;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};

    my @n = ((0) x @_);
    my @sum = ((undef) x @_);

   _k_means_step($vs, $t, \@_, [0..$#_], \@n, \@sum);

    for (0..$#n) {
        if (my $n = $n[$_]) {
            $sum[$_] /= $n;
        }
        else {
            # otherwise let the original value stay
            $sum[$_] = $_[$_];
        }
    }
    wantarray ? @sum : $sum[0];
}

sub _k_means_step {
    my ($vs, $t, $centers, $cixs, $ns, $sums) = @_;
    my ($n, $sum, $c0, $c1) = @{$t}[_n, _sum, _c0, _c1];
    if ($n) {
        my $centroid = $sum/$n;
        my $best = nkeyhead { $centroid->dist2($centers->[$_]) } @$cixs;
        my $max_d2 = Math::Vector::Real::max_dist2_to_box($centers->[$best], $c0, $c1);
        my @down = grep { Math::Vector::Real::dist2_to_box($centers->[$_], $c0, $c1) <= $max_d2 } @$cixs;
        if (@down <= 1) {
            $ns->[$best] += $n;
            # FIXME: M::V::R objects should support this undef + vector logic natively!
            if (defined $sums->[$best]) {
                $sums->[$best] += $sum;
            }
            else {
                $sums->[$best] = V(@$sum);
            }
        }
        else {
            if (defined (my $axis = $t->[_axis])) {
                my ($s0, $s1) = @{$t}[_s0, _s1];
                _k_means_step($vs, $t->[_s0], $centers, \@down, $ns, $sums);
                _k_means_step($vs, $t->[_s1], $centers, \@down, $ns, $sums);
            }
            else {
                for my $ix (@{$t->[_ixs]}) {
                    my $v = $vs->[$ix];
                    my $best = nkeyhead { $v->dist2($centers->[$_]) } @down;
                    $ns->[$best]++;
                    if (defined $sums->[$best]) {
                        $sums->[$best] += $v;
                    }
                    else {
                        $sums->[$best] = V(@$v);
                    }
                }
            }
        }
    }
}

sub k_means_assign {
    my $self = shift;
    @_ or return;
    my $t = $self->{tree} or return;
    my $vs = $self->{vs};

    my @out = ((undef) x @$vs);
   _k_means_assign($vs, $t, \@_, [0..$#_], \@out);
    @out;
}

sub _k_means_assign {
    my ($vs, $t, $centers, $cixs, $outs) = @_;
    my ($n, $sum, $c0, $c1) = @{$t}[_n, _sum, _c0, _c1];
        if ($n) {
        my $centroid = $sum/$n;
        my $best = nkeyhead { $centroid->dist2($centers->[$_]) } @$cixs;
        my $max_d2 = Math::Vector::Real::max_dist2_to_box($centers->[$best], $c0, $c1);
        my @down = grep { Math::Vector::Real::dist2_to_box($centers->[$_], $c0, $c1) <= $max_d2 } @$cixs;
        if (@down <= 1) {
            _k_means_assign_1($t, $best, $outs);
        }
        else {
            if (defined (my $axis = $t->[_axis])) {
                my ($s0, $s1) = @{$t}[_s0, _s1];
                _k_means_assign($vs, $t->[_s0], $centers, \@down, $outs);
                _k_means_assign($vs, $t->[_s1], $centers, \@down, $outs);
            }
            else {
                for my $ix (@{$t->[_ixs]}) {
                    my $v = $vs->[$ix];
                    my $best = nkeyhead { $v->dist2($centers->[$_]) } @down;
                    $outs->[$ix] = $best;
                }
            }
        }
    }
}

sub _k_means_assign_1 {
    my ($t, $best, $outs) = @_;
    if (defined (my $axis = $t->[_axis])) {
        _k_means_assign_1($t->[_s0], $best, $outs);
        _k_means_assign_1($t->[_s1], $best, $outs);
    }
    else {
        $outs->[$_] = $best for @{$t->[_ixs]};
    }
}

sub ordered_by_proximity {
    my $self = shift;
    my @r;
    $#r = $#{$self->{vs}}; $#r = -1; # preallocate
    _ordered_by_proximity($self->{tree}, \@r);
    return @r;
}

sub _ordered_by_proximity {
    my $t = shift;
    my $r = shift;
    if (defined $t->[_axis]) {
        _ordered_by_proximity($t->[_s0], $r);
        _ordered_by_proximity($t->[_s1], $r);
    }
    else {
        push @$r, @{$t->[_ixs]}
    }
}

sub _dump_to_string {
    my ($vs, $t, $indent, $opts) = @_;
    my ($n, $c0, $c1, $sum) = @{$t}[_n, _c0, _c1, _sum];
    my $id = ($opts->{pole_id} ? _pole_id($vs, $t)." " : '');
    if (defined (my $axis = $t->[_axis])) {
        my ($s0, $s1, $cut) = @{$t}[_s0, _s1, _cut];
        return ( "${indent}${id}n: $n, c0: $c0, c1: $c1, sum: $sum, axis: $axis, cut: $cut\n" .
                 _dump_to_string($vs, $s0, "$indent$opts->{tab}", $opts) .
                 _dump_to_string($vs, $s1, "$indent$opts->{tab}", $opts) );
    }
    else {
        my $remark = $opts->{remark} // [];
        my $o = ( "${indent}${id}n: $n, c0: $c0, c1: $c1, sum: $sum\n" .
                  "${indent}$opts->{tab}ixs: [" );
        my @str;
        for my $ix (@{$t->[_ixs]}) {
            my $colored_ix = (@$remark and grep($ix == $_, @$remark)
                              ? Term::ANSIColor::colored($ix, 'red')
                              : $ix);
            if ($opts->{dump_vectors} // 1) {
                push @str, "$colored_ix $vs->[$ix]";
            }
            else {
                push @str, $colored_ix;
            }
        }
        return $o . join(', ', @str) . "]\n";
    }
}

sub dump_to_string {
    my ($self, %opts) = @_;
    my $tab = $opts{tab} //= '    ';
    my $vs = $self->{vs};
    my $nvs = @$vs;
    my $hidden = join ", ", keys %{$self->{hidden} || {}};
    my $o = "tree: n: $nvs, hidden: {$hidden}\n";
    if (my $t = $self->{tree}) {
        require Term::ANSIColor if $opts{remark};
        return $o . _dump_to_string($vs, $t, $tab, \%opts);
    }
    else {
        return "$o${tab}(empty)\n";
    }
}

sub dump {
    my $self = shift;
    print $self->dump_to_string(@_);
}

1;
__END__

=head1 NAME

Math::Vector::Real::kdTree - kd-Tree implementation on top of Math::Vector::Real

=head1 SYNOPSIS

  use Math::Vector::Real::kdTree;

  use Math::Vector::Real;
  use Math::Vector::Real::Random;

  my @v = map Math::Vector::Real->random_normal(4), 1..1000;

  my $tree = Math::Vector::Real::kdTree->new(@v);

  my $ix = $tree->find_nearest_vector(V(0, 0, 0, 0));

  say "nearest vector is $ix, $v[$ix]";

=head1 DESCRIPTION

This module implements a kd-Tree data structure in Perl and common
algorithms on top of it.

=head2 Methods

The following methods are provided:

=over 4

=item $t = Math::Vector::Real::kdTree->new(@points)

Creates a new kd-Tree containing the given points.

=item $t2 = $t->clone

Creates a duplicate of the tree. The two trees will share internal
read only data so this method is more efficient in terms of memory
usage than others performing a deep copy.

=item my $ix = $t->insert($p0, $p1, ...)

Inserts the given points into the kd-Tree.

Returns the index assigned to the first point inserted.

=item $s = $t->size

Returns the number of points inside the tree.

=item $p = $t->at($ix)

Returns the point at the given index inside the tree.

=item $t->move($ix, $p)

Moves the point at index C<$ix> to the new given position readjusting
the tree structure accordingly.

=item ($ix, $d) = $t->find_nearest_vector($p, $max_d, @but_ix)

=item ($ix, $d) = $t->find_nearest_vector($p, $max_d, \%but_ix)

Find the nearest vector for the given point C<$p> and returns its
index and the distance between the two points (in scalar context the
index is returned).

If C<$max_d> is defined, the search is limited to the points within that distance

Optionally, a list of point indexes to be excluded from the search can be
passed or, alternatively, a reference to a hash containing the indexes
of the points to be excluded.

=item @ix = $t->find_nearest_vector_all_internal

Returns the index of the nearest vector from the tree.

It is equivalent to the following code (though, it uses a better
algorithm):

  @ix = map {
            scalar $t->nearest_vector($t->at($_), undef, $_)
        } 0..($t->size - 1);

=item $ix = $t->find_nearest_vector_in_box($p, $a, $b, $max_d, @but_ix)

=item $ix = $t->find_nearest_vector_in_box($p, $a, $b, $max_d, \%but_ix)

Returns the nearest vector for the given point from those that are
also inside the box defined by C<$a> and C<$b>.

The other arguments have the same meaning as for the method
C<find_nearest_vector>.

=item $ix = $t->find_nearest_vector_in_box_chebyshev($p, $a, $b, $max_d, @but_ix)

=item $ix = $t->find_nearest_vector_in_box_chebyshev($p, $a, $b, $max_d, \%but_ix)

This method is similar to C<find_nearest_vector_in_box> but using the
Chebyshev metric.

=item $ix = $t->find_farthest_vector($p, $min_d, @but_ix)

Find the point from the tree farthest from the given C<$p>.

The optional argument C<$min_d> specifies a minimal distance. Undef is
returned when not point farthest that it is found.

C<@but_ix> specifies points that should not be considered when looking
for the farthest point.

=item $ix = $t->find_farthest_vector_internal($ix, $min_d, @but_ix)

Given the index of a point on the tree this method returns the index
of the farthest vector also from the tree.

=item ($ix0, $ix1, $d) = $t->find_two_nearest_vectors

This method returns the indexes of two vectors from the three such
that the distance between them is minimal. The distance is returned as
the third output value.

In scalar context, just the distance is returned.

=item @k = $t->k_means_seed($n)

This method uses the internal tree structure to generate a set of
point that can be used as seeds for other C<k_means> methods.

There isn't any guarantee on the quality of the generated seeds, but
the used algorithm seems to perform well in practice.

=item @k = $t->k_means_step(@k)

Performs a step of the L<Lloyd's
algorithm|http://en.wikipedia.org/wiki/Lloyd%27s_algorithm> for
k-means calculation.

=item @k = $t->k_means_loop(@k)

Iterates until the Lloyd's algorithm converges and returns the final
means.

=item @ix = $t->k_means_assign(@k)

Returns for every point in the three the index of the cluster it
belongs to.

=item @ix = $t->find_in_ball($z, $d, $but)

=item $n = $t->find_in_ball($z, $d, $but)

Finds the points inside the tree contained in the hypersphere with
center C<$z> and radius C<$d>.

In scalar context returns the number of points found. In list context
returns the indexes of the points.

If the extra argument C<$but> is provided. The point with that index
is ignored.

=item @ix = $t->find_in_box($a, $b, $but)

=item $n = $t->find_in_box($a, $b, $but)

Finds the points inside the tree contained in the axis-aligned box
defined by two opposite vertices C<$a> and C<$b>.

In scalar context returns the number of points found. In list context
returns the indexes of the points.

If the extra argument C<$but> is provided. The point with that index
is ignored.

=item @ix = $t->ordered_by_proximity

Returns the indexes of the points in an ordered where is likely that
the indexes of near vectors are also in near positions in the list.

=back

=head2 k-means

The module can be used to calculate the k-means of a set of vectors as follows:

  # inputs
  my @v = ...; my $k = ...;
  
  # k-mean calculation
  my $t = Math::Vector::Real::kdTree->new(@v);
  my @means = $t->k_means_seed($k);
  @means = $t->k_means_loop(@means);
  @assign = $t->k_means_assign(@means);
  my @cluster = map [], 1..$k;
  for (0..$#assign) {
    my $cluster_ix = $assign[$_];
    my $cluster = $cluster[$cluster_ix];
    push @$cluster, $t->at($_);
  }
  
  use Data::Dumper;
  print Dumper \@cluster;

=head1 SEE ALSO

L<Wikipedia k-d Tree entry|http://en.wikipedia.org/wiki/K-d_tree>.

L<K-means filtering algorithm|https://www.cs.umd.edu/~mount/Projects/KMeans/pami02.pdf>.

L<Math::Vector::Real>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2015 by Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
