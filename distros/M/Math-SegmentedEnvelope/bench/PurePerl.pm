package Math::SegmentedEnvelope::PurePerl;
# Pure Perl version for benchmarking
use Moo;
use Clone 'clone';
use Carp;
use List::Util 'sum';
use constant PI => 4 * atan2(1, 1);

has def => ( is => 'ro', default => sub {
    my $size = int(rand(5)+3);
    [
        [0, map(rand, (0) x $size), 0],
        [normalize_sum(map rand() + 0.2, (0) x ($size + 1))],
        [map 3 * (rand) - 1.5, (0) x ($size + 1)]
    ]
});
has is_morph => ( is => 'rw' );
has morpher => (  is => 'rw', default => sub { sub { sin( $_[0] * PI / 2 ) ** 2 } } );
has is_hold => ( is => 'rw' );
has is_fold_over => ( is => 'rw' );
has is_wrap_neg => ( is => 'rw' );

has _duration => ( is => 'rw' );
has _segments => ( is => 'rw' );
has _current_segment => ( is => 'rw', default => sub { 0 } );
has _level_diff => ( is => 'rw' );
has _is_neg => ( is => 'rw' );
has _is_asc => ( is => 'rw' );
has _past_segment => ( is => 'rw', default => sub { -1 } );
has _passed_segments_duration => ( is => 'rw', default => sub { 0 } );

sub BUILDARGS {
    my ( $class, @args ) = @_;
    unshift @args, "def" if @args % 2 == 1;
    return { @args };
};

sub BUILD {
    my ($self) = @_;
    croak "size mismatch in envelope definition" if
        @{$self->def->[0]} != @{$self->def->[1]}  + 1
            || @{$self->def->[0]} != @{$self->def->[2]} + 1
                || @{$self->def->[1]} != @{$self->def->[2]};
    $self->_duration(sum(@{$self->def->[1]}));
    $self->_segments(scalar@{$self->def->[1]});
}

sub clean {
    my ($self) = @_;
    $self->_duration(sum(@{$self->def->[1]}));
    $self->_segments(scalar@{$self->def->[1]});
    $self->_current_segment(0);
    $self->_past_segment(-1);
}

sub evaluator {
    my ($self) = @_;
    sub { $self->at(@_) };
}

sub at {
    my ($self, $t) = @_;
    $t = $self->wrap_pos($t);
    my ($pd,$i,$d) = (
        $self->_passed_segments_duration,
        $self->_current_segment
    );
    while ($t < $pd && $i > 0) { $pd -= $self->def->[1]->[--$i] }
    $i == 0 ? $pd = 0 : $t -= $pd;
    while ($i < $self->_segments) {
        $d = $self->def->[1]->[$i];
        if ($t > $d && $i != $self->_segments - 1) {
            $t -= $d; $pd += $d; $i++; next;
        } else {
            $t = $d if $t > $d;
            $i = $self->update_current_segment($i) unless $i == $self->_past_segment; last;
        }
    }
    $self->_passed_segments_duration($pd) if $pd != $self->_passed_segments_duration;
    $self->_current_segment($i) if $i != $self->_current_segment;
    abs(
        $self->wrap_value(abs(( $self->_is_neg ? $d - $t : $t ) / $d))
        ** abs($self->def->[2]->[$i])
        * $self->_is_asc
        + $self->_is_neg
    ) * $self->_level_diff + $self->def->[0]->[$i];
}

sub wrap_value {
    my ($self) = @_;
    $self->is_morph ? $self->morpher->($_[1]) : $_[1];
}

sub wrap_pos {
    my ($self,$t) = @_;
    my $total = $self->_duration;
    if ($self->is_hold) {
        $t > 0 ? ( $t > $total ? $total : $t ) : 0
    } else {
        my $at = abs($t);
        if ($at > $total) {
            if  ($self->is_fold_over && int($at/$total) % 2 == ( $t < 0 && $self->is_wrap_neg ? 0 : 1 )) {
                ( 1 - ( ($at / $total) - int($at / $total) ) ) * $total;
            } else {
                ( ($at / $total) - int($at / $total) ) * $total;
            }
        } else { $at }
    };
}

sub update_current_segment {
    my ($self, $i) = @_;
    $i = $self->_current_segment(defined($i) ? $i : ());
    $self->_level_diff($self->level($i+1) - $self->level($i));
    $self->_is_neg($self->curve($i) < 0 ? 1 : 0);
    $self->_is_asc($self->_level_diff < 0 || $self->_is_neg ? -1 : 1);
    $self->_past_segment($i);
}

sub level {
    my $self = shift;
    my $r = $self->def_part_value(0, @_);
    $self->update_current_segment if @_ > 1 && abs($self->_current_segment - ($_[0] >= 0 ? $_[0] : $self->_segments + $_[0])) <= 1;
    $r;
}

sub levels {
    my $self = shift;
    my @r = $self->def_part(0, @_);
    $self->update_current_segment if @_ > 0;
    @r;
}

sub dur {
    my $self = shift;
    my $r = $self->def_part_value(1, @_);
    $self->clean if @_ > 1;
    $r;
}

sub durs {
    my $self = shift;
    my @r = $self->def_part(1, @_);
    $self->clean if @_ > 1;
    @r;
}

sub duration { shift->_duration }
sub segments { shift->_segments }

sub curve {
    my $self = shift;
    my $r = $self->def_part_value(2, @_);
    $self->update_current_segment if @_ > 1 && $self->_current_segment == $_[0];
    $r;
}

sub curves {
    my $self = shift;
    my @r = $self->def_part(2, @_);
    $self->update_current_segment if @_ > 0;
    @r;
}

sub def_part {
    my ($self, $p, @values) = @_;
    (@values == @{$self->def->[$p]} ? $self->def->[$p] = [@values] : carp "size mismatch against initial definition") if @values;
    @{$self->def->[$p]};
}

sub def_part_value {
    my ($self, $p, $at, $value) = @_;
    croak "no such index '$at' in definition part '$p'" if !defined($at) || !exists($self->def->[$p]->[$at]);
    $self->def->[$p]->[$at] = $value if $value;
    $self->def->[$p]->[$at];
}

sub static {
    my ($self) = @_;
    my ($lev, $dur, $cur, $is_smooth, $is_hold, $is_fold_over, $is_wrap_neg, $total) = (
        [$self->levels], [$self->durs], [$self->curves], $self->is_morph && clone($self->morpher),
        $self->is_hold, $self->is_fold_over, $self->is_wrap_neg, $self->duration
    );
    my ($i, $pd, $cs, $level_diff, $is_asc, $is_neg, $d) = (0, 0, -1);
    my $segment_data = sub {
        $level_diff = $lev->[$i+1] - $lev->[$i];
        $is_neg = $cur->[$i] < 0 ? 1 : 0;
        $is_asc = $level_diff < 0 || $is_neg ? -1 : 1;
        $cs = $i;
    };
    my $wrap_value = $is_smooth ? ( ref($is_smooth) eq 'CODE' ? $is_smooth : sub { sin( PI / 2 * $_[0] ) ** 2 } ) : sub { $_[0] };
    my $wrap_pos = $is_hold ? sub {
        $_[0] > 0 ? ( $_[0] > $total ? $total : $_[0] ) : 0;
    } : sub {
        my $t = abs($_[0]);
        if ($t > $total) {
            if ($is_fold_over && int($t/$total) % 2 == ($_[0] < 0 && $is_wrap_neg ? 0 : 1)) {
                (1 - (($t / $total) - int( $t / $total ))) * $total;
            } else {
                (($t / $total) - int( $t / $total )) * $total;
            }
        } else { $t }
    };
    my $last_segment = @$dur - 1;
    sub {
        my $t = $wrap_pos->($_[0]);
        while ($t < $pd && $i > 0) { $pd -= $dur->[--$i] }
        $i == 0 ? $pd = 0 : $t -= $pd;
        while ($i <= $last_segment) {
            $d = $dur->[$i];
            if ($t > $d && $i != $last_segment) {
                $t -= $d; $pd += $d; $i++; next;
            } else {
                $t = $d if $t > $d;
                $segment_data->() unless $i == $cs; last;
            }
        }
        abs(
            $wrap_value->(( $is_neg ? ($d - $t) : $t ) / $d)
            ** abs($cur->[$i])
            * $is_asc
            + $is_neg
        ) * $level_diff + $lev->[$i];
    }
}

sub table {
    my ($self, $size) = @_;
    $size ||= 1024;
    croak "table size should be >= 1" if $size <= 0;
    my $s = $self->static;
    my $d = $self->duration;
    map { $s->($self->duration * $_ / $size) } (0..--$size);
}

sub normalize_duration {
    my ($self) = @_;
    $self->durs(normalize_sum($self->durs));
    $self;
}

sub normalize_sum {
    my $s = sum@_;
    map $_/$s, @_;
}

1;
