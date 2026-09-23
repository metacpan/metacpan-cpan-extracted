package Math::SegmentedEnvelope;
# ABSTRACT: create/manage/evaluate segmented (curved) envelope
use strict;
use warnings;

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Math::SegmentedEnvelope', $VERSION);

use overload
    '&{}' => sub {
        my $self = shift;
        sub { $self->at(@_) };
    },
    '+' => sub {
        my ($a, $b, $swap) = @_;
        eval { $b->isa(__PACKAGE__) } ? $a->add($b) : $a->offset($b + 0);
    },
    '-' => sub {
        my ($a, $b, $swap) = @_;
        $swap ? $a->scale(-1)->offset($b + 0)
              : (eval { $b->isa(__PACKAGE__) } ? $a->add($b->scale(-1)) : $a->offset(-($b + 0)));
    },
    '*' => sub {
        my ($a, $b, $swap) = @_;
        eval { $b->isa(__PACKAGE__) } ? $a->multiply($b) : $a->scale($b + 0);
    },
    'neg' => sub { $_[0]->scale(-1) },
    '""' => sub { sprintf("Math::SegmentedEnvelope(segments=%d, duration=%.4gs)", $_[0]->segments, $_[0]->duration) },
    fallback => 1;

*copy = \&clone;
*integral = \&area;

use Exporter 'import';
our @EXPORT_OK = qw(env adsr asr perc concat morpher_formulas spline from_samples);

sub env { __PACKAGE__->new(@_) }

sub adsr {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        my $inv = shift;
        $class = ref($inv) || $inv;
    }
    my ($attack, $decay, $sustain, $release, %opts) = @_;

    $attack  //= 0.1;
    $decay   //= 0.1;
    $sustain //= 0.7;
    $release //= 0.3;

    my $peak         = $opts{peak} // 1.0;
    my $sustain_time = $opts{sustain_time} // 0.5;
    my $attack_curve  = $opts{attack_curve} // 2;
    my $decay_curve   = $opts{decay_curve} // -2;
    my $release_curve = $opts{release_curve} // -2;

    my $sustain_level = $peak * $sustain;

    my $def = [
        [0, $peak, $sustain_level, $sustain_level, 0],
        [$attack, $decay, $sustain_time, $release],
        [$attack_curve, $decay_curve, 1, $release_curve],
    ];

    $class->new($def, %opts);
}

sub perc {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        my $inv = shift;
        $class = ref($inv) || $inv;
    }
    my ($attack, $decay, %opts) = @_;

    $attack //= 0.01;
    $decay  //= 0.5;

    my $peak         = $opts{peak} // 1.0;
    my $attack_curve = $opts{attack_curve} // 2;
    my $decay_curve  = $opts{decay_curve} // -3;

    my $def = [
        [0, $peak, 0],
        [$attack, $decay],
        [$attack_curve, $decay_curve],
    ];

    $class->new($def, %opts);
}

sub asr {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        my $inv = shift;
        $class = ref($inv) || $inv;
    }
    my ($attack, $sustain_time, $release, %opts) = @_;

    $attack       //= 0.1;
    $sustain_time //= 0.5;
    $release      //= 0.3;

    my $peak          = $opts{peak} // 1.0;
    my $attack_curve  = $opts{attack_curve} // 2;
    my $release_curve = $opts{release_curve} // -2;

    my $def = [
        [0, $peak, $peak, 0],
        [$attack, $sustain_time, $release],
        [$attack_curve, 1, $release_curve],
    ];

    $class->new($def, %opts);
}

sub concat {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        if (!ref($_[0])) {
            $class = shift;
        } else {
            $class = ref($_[0]);
        }
    }
    my @envelopes = @_;

    return $class->new() unless @envelopes;
    return $envelopes[0] if @envelopes == 1;

    my (@levels, @durs, @curves);

    for my $i (0 .. $#envelopes) {
        my $e = $envelopes[$i];
        my $def = $e->def;

        my @e_levels = @{$def->[0]};
        my @e_durs   = @{$def->[1]};
        my @e_curves = @{$def->[2]};

        if ($i == 0) {
            # First envelope: take all levels
            push @levels, @e_levels;
        } else {
            # Subsequent envelopes: skip first level (use last from previous)
            push @levels, @e_levels[1 .. $#e_levels];
        }

        push @durs,   @e_durs;
        push @curves, @e_curves;
    }

    my %opts = eval { %{$envelopes[0]->_options} };
    $class->new([[@levels], [@durs], [@curves]], %opts);
}

sub _options {
    my ($self) = @_;
    my %opts = (
        is_morph     => $self->is_morph ? 1 : 0,
        is_hold      => $self->is_hold ? 1 : 0,
        is_fold_over => $self->is_fold_over ? 1 : 0,
        is_wrap_neg  => $self->is_wrap_neg ? 1 : 0,
    );
    my $formula = $self->morpher_formula;
    $opts{morpher_formula} = $formula if defined $formula;
    my $cv = $self->morpher;
    $opts{morpher} = $cv if defined $cv;
    return \%opts;
}

sub scale {
    my ($self, $factor) = @_;
    $factor //= 1.0;

    my $def = $self->def;
    my @levels = map { $_ * $factor } @{$def->[0]};

    ref($self)->new([[@levels], [@{$def->[1]}], [@{$def->[2]}]], %{$self->_options});
}

sub reverse {
    my ($self) = @_;

    my $def = $self->def;
    my @levels = reverse @{$def->[0]};
    my @durs   = reverse @{$def->[1]};
    my @curves = map { -$_ } reverse @{$def->[2]};

    ref($self)->new([[@levels], [@durs], [@curves]], %{$self->_options});
}

sub delay {
    my ($self, $time) = @_;
    $time //= 0;
    return $self if $time <= 0;

    my $def = $self->def;
    my $start_level = $def->[0][0];

    my @levels = ($start_level, @{$def->[0]});
    my @durs   = ($time, @{$def->[1]});
    my @curves = (1, @{$def->[2]});

    ref($self)->new([[@levels], [@durs], [@curves]], %{$self->_options});
}

sub stretch {
    my ($self, $factor) = @_;
    $factor //= 1.0;

    my $def = $self->def;
    my @durs = map { $_ * $factor } @{$def->[1]};

    ref($self)->new([[@{$def->[0]}], [@durs], [@{$def->[2]}]], %{$self->_options});
}

sub with_duration {
    my ($self, $new_dur) = @_;
    die "with_duration: duration must be positive\n" unless defined $new_dur && $new_dur > 0;
    my $cur = $self->duration;
    return $self if $cur <= 0;
    return $self->stretch($new_dur / $cur);
}

sub offset {
    my ($self, $value) = @_;
    $value //= 0;

    my $def = $self->def;
    my @levels = map { $_ + $value } @{$def->[0]};

    ref($self)->new([[@levels], [@{$def->[1]}], [@{$def->[2]}]], %{$self->_options});
}

sub invert {
    my ($self) = @_;

    my $def = $self->def;
    my @levels = map { 1 - $_ } @{$def->[0]};

    ref($self)->new([[@levels], [@{$def->[1]}], [@{$def->[2]}]], %{$self->_options});
}

sub normalize {
    my ($self, $lo, $hi) = @_;
    $lo //= 0;
    $hi //= 1;

    my $min = $self->min_value;
    my $max = $self->max_value;
    my $range = $max - $min;
    return $self->scale(0)->offset($lo) if $range == 0;

    my $def = $self->def;
    my $target = $hi - $lo;
    my @levels = map { $lo + ($_ - $min) / $range * $target } @{$def->[0]};

    ref($self)->new([[@levels], [@{$def->[1]}], [@{$def->[2]}]], %{$self->_options});
}

sub loop {
    my ($self, $n) = @_;
    $n //= 2;
    $n = 1 if $n < 1;
    return $self if $n == 1;

    my $class = ref($self);
    my @copies = ($self) x $n;
    $class->concat(@copies);
}

sub map_levels {
    my ($self, $fn) = @_;

    my $def = $self->def;
    my @levels = map { $fn->($_) } @{$def->[0]};

    ref($self)->new([[@levels], [@{$def->[1]}], [@{$def->[2]}]], %{$self->_options});
}

sub add {
    my ($self, $other, %opts) = @_;
    $self->_combine($other, sub { $_[0] + $_[1] }, %opts);
}

sub multiply {
    my ($self, $other, %opts) = @_;
    $self->_combine($other, sub { $_[0] * $_[1] }, %opts);
}

sub min_value {
    my ($self, $samples) = @_;
    $samples //= 1024;
    my @tbl = $self->table($samples);
    my $min = $tbl[0];
    for (@tbl) { $min = $_ if $_ < $min }
    return $min;
}

sub max_value {
    my ($self, $samples) = @_;
    $samples //= 1024;
    my @tbl = $self->table($samples);
    my $max = $tbl[0];
    for (@tbl) { $max = $_ if $_ > $max }
    return $max;
}

sub to_hash {
    my ($self) = @_;
    my $def = $self->def;
    my %h = (
        def => $def,
        is_morph     => $self->is_morph ? 1 : 0,
        is_hold      => $self->is_hold ? 1 : 0,
        is_fold_over => $self->is_fold_over ? 1 : 0,
        is_wrap_neg  => $self->is_wrap_neg ? 1 : 0,
    );
    my $formula = $self->morpher_formula;
    $h{morpher_formula} = $formula if defined $formula;
    return \%h;
}

sub from_hash {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        my $inv = shift;
        $class = ref($inv) || $inv;
    }
    my ($h) = @_;
    die "from_hash: expected a hash reference\n" unless ref($h) eq 'HASH';
    my %opts;
    for my $k (qw(is_morph is_hold is_fold_over is_wrap_neg morpher_formula)) {
        $opts{$k} = $h->{$k} if exists $h->{$k};
    }
    $class->new($h->{def}, %opts);
}

sub STORABLE_freeze {
    my ($self, $cloning) = @_;
    require Storable;
    return Storable::freeze($self->to_hash);
}

sub STORABLE_thaw {
    my ($self, $cloning, $data) = @_;
    require Storable;
    my $h = Storable::thaw($data);
    my $obj = Math::SegmentedEnvelope->from_hash($h);
    ${$self} = ${$obj};
    ${$obj} = 0;
    return $self;
}

sub to_svg {
    my ($self, %opts) = @_;
    my $w      = $opts{width}  // 400;
    my $h      = $opts{height} // 150;
    my $pad    = $opts{padding} // 10;
    my $stroke = $opts{stroke}  // '#2563eb';
    my $fill   = $opts{fill}    // '#2563eb22';
    my $samples = $opts{samples} // ($w - 2 * $pad);
    $samples = 2 if $samples < 2;

    my @vals = $self->table($samples);
    my ($min, $max) = ($vals[0], $vals[0]);
    for (@vals) { $min = $_ if $_ < $min; $max = $_ if $_ > $max }
    my $range = $max - $min || 1;

    my $pw = ($w - 2 * $pad) / ($samples - 1);
    my @points;
    for my $i (0 .. $#vals) {
        my $x = $pad + $i * $pw;
        my $y = $pad + (1 - ($vals[$i] - $min) / $range) * ($h - 2 * $pad);
        push @points, sprintf("%.1f,%.1f", $x, $y);
    }

    my $polyline = join(' ', @points);
    my $fill_points = join(' ', @points,
        sprintf("%.1f,%.1f", $pad + ($samples - 1) * $pw, $h - $pad),
        sprintf("%.1f,%.1f", $pad, $h - $pad));

    return qq{<svg xmlns="http://www.w3.org/2000/svg" width="$w" height="$h" viewBox="0 0 $w $h">}
         . qq{<polygon points="$fill_points" fill="$fill" stroke="none"/>}
         . qq{<polyline points="$polyline" fill="none" stroke="$stroke" stroke-width="1.5"/>}
         . qq{</svg>\n};
}

sub to_supercollider {
    my ($self, %opts) = @_;
    my $varname = $opts{name} // 'env';
    my $def = $self->def;
    my @levels = @{$def->[0]};
    my @durs   = @{$def->[1]};
    my @curves = @{$def->[2]};

    # SuperCollider Env format: Env([levels], [times], [curves])
    my $l = join(', ', map { sprintf '%.4g', $_ } @levels);
    my $t = join(', ', map { sprintf '%.4g', $_ } @durs);
    my $c = join(', ', map { sprintf '%.4g', $_ } @curves);

    return "var $varname = Env([$l], [$t], [$c]);\n";
}

sub to_csound {
    my ($self, %opts) = @_;
    my $def = $self->def;
    my @levels = @{$def->[0]};
    my @durs   = @{$def->[1]};

    # Csound linseg/expseg format: p-fields
    # linseg istart, idur1, ival1, idur2, ival2, ...
    my @args = (sprintf('%.4g', $levels[0]));
    for my $i (0 .. $#durs) {
        push @args, sprintf('%.4g', $durs[$i]);
        push @args, sprintf('%.4g', $levels[$i + 1]);
    }

    return "linseg " . join(', ', @args) . "\n";
}

sub to_glsl {
    my ($self, %opts) = @_;
    my $name = $opts{name} // 'envelope';
    my $samples = $opts{samples} // 64;
    $samples = 2 if $samples < 2;

    my @vals = $self->table($samples);
    my $dur = $self->duration;

    my $code = "float ${name}(float t) {\n";
    $code .= "    float dur = " . sprintf('%.6f', $dur) . ";\n";
    $code .= "    float n = clamp(t / dur, 0.0, 1.0) * " . ($samples - 1) . ".0;\n";
    $code .= "    int i = int(n);\n";
    $code .= "    float f = fract(n);\n";
    $code .= "    float data[$samples] = float[$samples](";
    $code .= join(', ', map { sprintf '%.5f', $_ } @vals);
    $code .= ");\n";
    $code .= "    if (i >= " . ($samples - 1) . ") return data[" . ($samples - 1) . "];\n";
    $code .= "    return mix(data[i], data[i + 1], f);\n";
    $code .= "}\n";

    return $code;
}

sub as_pdl {
    my ($self) = @_;
    require PDL::Core;
    my $n = $self->segments + 1;
    my $p = PDL::Core::zeroes(PDL::Core::double(), $n);
    my $ref = $p->get_dataref;
    $$ref = $self->_raw_levels;
    $p->upd_data;
    return $p;
}

sub to_pdl {
    my ($self, $samples) = @_;
    $samples //= 1024;
    require PDL::Core;
    my $p = PDL::Core::zeroes(PDL::Core::double(), $samples);
    my $ref = $p->get_dataref;
    $$ref = $self->_raw_table($samples);
    $p->upd_data;
    return $p;
}

sub from_pdl {
    my $class = __PACKAGE__;
    if (@_ && eval { $_[0]->isa(__PACKAGE__) }) {
        my $inv = shift;
        $class = ref($inv) || $inv;
    }
    my ($pdl, $duration) = @_;
    $duration //= 1.0;
    my @vals = $pdl->list;
    return $class->from_samples(\@vals, $duration);
}

sub _combine {
    my ($self, $other, $op, %opts) = @_;
    my $segments = delete $opts{segments} // 32;
    $segments = 32 if $segments < 1;
    my $duration = delete $opts{duration} // $self->duration;
    $duration = 1.0 if $duration <= 0;

    my $s1 = $self->static;
    my $s2 = $other->static;
    my $d1 = $self->duration;
    my $d2 = $other->duration;

    my (@levels, @durs, @curves);
    my $seg_dur = $duration / $segments;
    for my $i (0 .. $segments) {
        my $t = $i * $seg_dur;
        my $t1 = $d1 > 0 ? ($t / $duration) * $d1 : 0;
        my $t2 = $d2 > 0 ? ($t / $duration) * $d2 : 0;
        push @levels, $op->($s1->($t1), $s2->($t2));
    }
    push @durs, $seg_dur for 1 .. $segments;
    push @curves, 1 for 1 .. $segments;

    my %combined_opts = (%{$self->_options}, %opts);
    ref($self)->new([[@levels], [@durs], [@curves]], %combined_opts);
}

sub blend {
    my ($self, $other, $mix, %opts) = @_;
    $mix //= 0.5;
    $self->_combine($other, sub { $_[0] * (1 - $mix) + $_[1] * $mix }, %opts);
}

package Math::SegmentedEnvelope::Static;

use overload '&{}' => sub {
    my $self = shift;
    return sub { $self->call(@_) };
}, fallback => 1;

1;

__END__

=head1 NAME

Math::SegmentedEnvelope - create/manage/evaluate segmented (curved) envelope

=head1 SYNOPSIS

    use Math::SegmentedEnvelope qw(env adsr perc asr concat);

    # Create with explicit definition: [levels, durations, curves]
    my $e = env(
        [
            [0, 1, 0.8, 0.7, 0],      # N+1 level values
            [0.1, 0.2, 0.4, 0.3],     # N segment durations
            [2, -2, 1, -3]            # N curve values
        ],
        is_morph => 1,
    );

    # Evaluate at time t
    my $value = $e->at(0.5);

    # Static evaluator for tight loops (captures state, avoids method dispatch)
    my $s = $e->static;
    my $value = $s->(0.5);

    # Generate 1024-sample lookup table
    my @table = $e->table(1024);

    # Standard envelope constructors
    my $note   = adsr(0.01, 0.1, 0.7, 0.3);
    my $kick   = perc(0.001, 0.2);
    my $pad    = asr(0.5, 2.0, 1.0);
    my $chain  = concat($kick, $pad);

=head1 DESCRIPTION

Math::SegmentedEnvelope creates and evaluates segmented envelopes with curved
segments. Useful for audio synthesis, animation, or any application requiring
smooth interpolation between control points.

Each envelope is defined by N+1 B<levels> (breakpoint values), N B<durations>
(time for each segment), and N B<curves> controlling the interpolation shape.

=head2 Curve values

The curve parameter controls the shape of interpolation within each segment:

=over 4

=item * B<Positive curves> (e.g. 2, 3) produce ease-in (slow start, fast end)

=item * B<Negative curves> (e.g. -2, -3) produce ease-out (fast start, slow end)

=item * B<Curve = 1 or -1> produces linear interpolation

=item * B<Larger absolute values> produce more extreme curvature

=back

=head1 CONSTRUCTOR

=head2 new

    my $e = Math::SegmentedEnvelope->new($def, %options);
    my $e = Math::SegmentedEnvelope->new(%options);
    my $e = Math::SegmentedEnvelope->new();  # random envelope

If no definition is provided, a random envelope is generated (respects Perl's
C<srand> for reproducibility).

Options:

=over 4

=item def => [$levels, $durations, $curves]

Envelope definition. Can also be passed as the first positional argument.

=item is_morph => $bool

Apply a smoothing morpher function to the interpolation curve.
Default morpher is C<sin(t * PI/2)^2>. See L</morpher> and L</morpher_formula>.

=item is_hold => $bool

Clamp time to [0, duration]. Without this, time beyond the envelope duration
wraps around. With it, the envelope holds at its final value.

=item is_fold_over => $bool

When time exceeds duration, mirror/fold instead of wrapping. Creates a
ping-pong effect.

=item is_wrap_neg => $bool

Invert the fold direction for negative time values.

=item morpher => $coderef

Custom morpher function as a Perl code reference. Called with a single argument
C<t> in [0,1], must return a value in [0,1]. Has Perl callback overhead.

=item morpher_formula => $string

A morpher specified as a math expression or predefined name. Compiled to native
code via JIT (TCC or x86-64) or evaluated via tinyexpr -- much faster than a
Perl callback. Automatically enables C<is_morph>. See L</morpher_formula>.

=item border_level => $scalar | [$start, $end]

Default border levels for random envelope generation.

=back

=head1 EVALUATION METHODS

=head2 at($t)

Evaluate envelope at time C<$t>. Returns the interpolated value.
Maintains internal state for optimized sequential access.

=head2 static

Returns a L<Math::SegmentedEnvelope::Static> object that captures the current
envelope state. Callable as a code reference for performance-critical loops:

    my $s = $e->static;
    for my $i (0 .. 999) {
        push @samples, $s->($i / 1000 * $e->duration);
    }

=head2 table($size, $cycles, $from, $to)

Generate a lookup table as a list of C<$size> values.

=over 4

=item * C<$size> - Number of samples (required)

=item * C<$cycles> - Number of envelope cycles to fit (default: 1)

=item * C<$from> - Start time (default: 0)

=item * C<$to> - End time (default: total duration)

=back

    my @lfo = $e->table(1024, 4);       # 4 cycles in 1024 samples
    my @seg = $e->table(256, 1, 0, 0.5); # first half only

=head2 segment_at($t)

Returns the segment index (0-based) at time C<$t>. Useful for triggering
events on segment boundaries.

    my $seg = $e->segment_at(0.15);  # which segment is active at t=0.15?

=head2 area, integral

Returns the definite integral (total area under the envelope curve) as a scalar number.
Uses trapezoidal integration across segment breakpoints.

    my $total = $e->area;
    my $total = $e->integral;

=head1 ACCESSOR METHODS

All accessors work as getters when called with no extra arguments, and as
setters when called with values.

=head2 level($idx, [$value])

Get/set level at index. Supports negative indices (C<-1> = last level).

=head2 levels([@values])

Get/set all levels.

=head2 dur($idx, [$value])

Get/set duration at segment index. Supports negative indices.

=head2 durs([@values])

Get/set all durations.

=head2 curve($idx, [$value])

Get/set curve at segment index. Supports negative indices.

=head2 curves([@values])

Get/set all curves.

=head2 duration

Returns total duration (sum of all segment durations).

=head2 segments

Returns number of segments (N).

=head2 def

Returns the envelope definition as C<[$levels, $durations, $curves]>.

=head2 border_level([$value])

Get/set border levels for random generation. Returns C<[$start, $end]>.

=head2 is_morph([$bool]), is_hold([$bool]), is_fold_over([$bool]), is_wrap_neg([$bool])

Get/set flag values. See L</CONSTRUCTOR> for descriptions.

=head2 morpher([$coderef])

Get/set custom Perl morpher callback.

=head2 morpher_formula([$formula])

Get/set the morpher formula. Accepts a predefined name or a math expression
string with variable C<t>. Pass C<undef> to reset to the default sine morpher.

    $env->morpher_formula('smoothstep');
    $env->morpher_formula('sin(t * 1.5708) ^ 2');
    $env->morpher_formula(undef);  # reset to default

Supported operators: C<+ - * / ^ %>. Functions: C<abs acos asin atan atan2
ceil cos cosh exp floor ln log log10 pow sin sinh sqrt tan tanh>.

Setting a formula automatically enables C<is_morph>. The expression is
JIT-compiled to native code if possible (via TCC or a built-in x86-64
emitter), falling back to tinyexpr tree interpretation.

=head2 morpher_formulas()

Returns the list of predefined morpher names (26 functions):

    linear sine smoothstep smootherstep welch tanh
    quad_in quad_out quad_inout
    cubic_in cubic_out cubic_inout
    circ_in circ_out circ_inout
    exp_in exp_out
    back_in back_out back_inout
    elastic_in elastic_out elastic_inout
    bounce_in bounce_out bounce_inout

=head2 morpher_jit_backend

Returns the morpher backend: C<"tcc"> (TCC JIT), C<"x86"> (hand-rolled JIT),
C<"builtin"> (predefined C function), or C<"none"> (default/tinyexpr).

=head1 UTILITY METHODS

=head2 normalize_duration

Normalize durations so they sum to 1.0. Returns C<$self>.

=head2 clean

Reset internal cached state. Call this after modifying segment data via
setters if you plan to evaluate at non-sequential time values.

=head1 TRANSFORMATION METHODS

All transformations return a new envelope, leaving the original unchanged.

=head2 scale($factor)

Multiply all levels by C<$factor> (default: 1.0).

    my $louder  = $e->scale(2.0);
    my $quieter = $e->scale(0.5);

=head2 offset($value)

Add C<$value> to all levels (default: 0).

    my $shifted = $e->offset(0.5);  # shift entire envelope up by 0.5

=head2 invert

Flip all levels: C<1 - level>. Useful for inverting an envelope shape.

    my $inv = $e->invert;

=head2 stretch($factor)

Scale all durations by C<$factor> (default: 1.0). Levels and curves are preserved.

    my $slow = $e->stretch(2.0);   # twice as long
    my $fast = $e->stretch(0.5);   # half duration

=head2 with_duration($duration)

Scale durations so the envelope has the specified total duration. Returns a new envelope.

    my $two_sec = $e->with_duration(2.0);

=head2 clone, copy

Create a fast deep copy of the envelope in C.

    my $dup = $e->clone;

=head2 reverse

Reverse the envelope direction. Durations are reversed and curve signs are
flipped.

=head2 delay($time)

Prepend a hold at the initial level for C<$time> seconds.

    my $delayed = $e->delay(0.5);

=head2 add($other, %opts)

Add two envelopes sample-by-sample. Returns a resampled envelope.

    my $sum = $e1->add($e2, segments => 32);

=head2 multiply($other, %opts)

Multiply two envelopes sample-by-sample (ring modulation, AM).

    my $am = $carrier->multiply($modulator, segments => 64);

=head2 normalize($lo, $hi)

Scale levels to fit within C<[$lo, $hi]> (default [0, 1]). Uses C<min_value>
and C<max_value> to determine current range.

    my $n = $e->normalize;           # [0, 1]
    my $n = $e->normalize(-1, 1);    # bipolar

=head2 loop($n)

Repeat the envelope C<$n> times end-to-end. Uses C<concat> internally.

    my $lfo = $cycle->loop(16);      # 16 repetitions

=head2 map_levels($coderef)

Apply a function to every level. Durations and curves are preserved.

    my $gamma = $e->map_levels(sub { $_[0] ** 2.2 });
    my $clamp = $e->map_levels(sub { $_[0] > 0.5 ? 0.5 : $_[0] });

=head2 quantize($steps)

Snap all levels to C<$steps> discrete values. Returns a new envelope.
Implemented in XS.

    my $lofi = $e->quantize(4);   # levels snapped to 0, 0.25, 0.5, 0.75, 1.0

=head2 trim($from, $to, %opts)

Extract a time slice as a new envelope by resampling. Implemented in XS.

    my $attack_only = $e->trim(0, 0.2);
    my $hires = $e->trim(0.1, 0.5, segments => 64);

=head2 lerp($other, $mix)

Interpolate between two envelopes with the same segment count. Unlike
C<blend>, this interpolates levels, durations, and curves directly without
resampling -- much cheaper. Implemented in XS.

    my $mid = $bright->lerp($soft, 0.5);

Croaks if segment counts differ (use C<blend> for that case).

=head2 resample($n)

Re-approximate the envelope with exactly C<$n> segments by sampling.
Useful for simplifying high-segment-count results from C<blend> or C<spline>.
Implemented in XS.

    my $simple = $complex->resample(8);

=head2 clamp($lo, $hi)

Clamp all levels to C<[$lo, $hi]>. Implemented in XS.

    my $safe = $e->clamp(0, 1);

=head2 smooth($passes)

Apply moving-average smoothing to levels. Endpoints are preserved.
C<$passes> defaults to 1; higher values produce smoother results.
Implemented in XS.

    my $soft = $noisy->smooth(3);

=head2 derivative

Returns a new envelope of the rate of change (slope) at each segment
boundary. Implemented in XS.

    my $slope = $e->derivative;

=head2 integrate

Returns the cumulative integral (area under the curve) via trapezoidal
rule on the breakpoint levels. Starts at 0. Implemented in XS.

Note: the trapezoidal approximation is exact for linear segments (curve=1)
but approximate for curved segments. For better accuracy on curved envelopes,
C<resample> to more segments first: C<< $e->resample(64)->integrate >>.

    my $area = $e->integrate;

=head2 from_samples(\@values, $duration)

Create an envelope from raw sample data (the inverse of C<table>).
Each value becomes a level; segments are evenly spaced across C<$duration>.
Implemented in XS. Works as class method or exported function.

    my $e = Math::SegmentedEnvelope->from_samples([0, 0.5, 1, 0.5, 0], 1.0);

=head2 to_svg(%opts)

Returns an SVG string of the envelope shape.

Options: C<width> (400), C<height> (150), C<padding> (10),
C<stroke> (color), C<fill> (color), C<samples> (width - 2*padding).

    my $svg = $e->to_svg(width => 600, height => 200);

=head2 to_supercollider(%opts)

Returns a SuperCollider C<Env()> definition string.
Option: C<name> (variable name, default: C<"env">).

    print $e->to_supercollider(name => 'ampEnv');
    # var ampEnv = Env([0, 1, 0.7, 0], [0.1, 0.3, 0.5], [2, -2, 1]);

=head2 to_csound

Returns a Csound C<linseg> statement string.

    print $e->to_csound;
    # linseg 0, 0.1, 1, 0.3, 0.7, 0.5, 0

=head2 to_glsl(%opts)

Returns a GLSL function that evaluates the envelope on the GPU.
Samples the envelope into a float array with linear interpolation.
Options: C<name> (function name, default C<"envelope">), C<samples> (default 64).

    print $e->to_glsl(name => 'ampEnv', samples => 32);

=head2 as_pdl

Returns the breakpoint levels as a L<PDL> piddle (N+1 elements). No sampling
-- direct binary copy from the internal C array. Requires PDL (loaded on demand).

    my $levels = $e->as_pdl;   # fast, no resampling

=head2 to_pdl($samples)

Returns C<$samples> (default 1024) evenly-sampled envelope values as a PDL
piddle. Uses C<_raw_table> internally to avoid Perl-level array intermediary.

    my $sig = $e->to_pdl(4096);

=head2 from_pdl($piddle, $duration)

Create an envelope from a PDL piddle. Class method.

    my $e = Math::SegmentedEnvelope->from_pdl($piddle, 2.0);

=head2 blend($other, $mix, %opts)

Blend with another envelope by resampling both.

    my $blended = $e1->blend($e2, 0.3);  # 70% e1, 30% e2

Options: C<segments> (default 32), C<duration> (default: self's duration).

=head2 concat(@envelopes)

Concatenate envelopes end-to-end. Works as function or class method.
The result inherits configuration options (such as C<is_hold>, C<is_fold_over>, etc.)
from the first envelope.

    my $chain = concat($e1, $e2, $e3);

=head2 min_value($samples)

Returns the minimum value of the envelope, estimated by sampling C<$samples>
points (default 1024).

=head2 max_value($samples)

Returns the maximum value, estimated by sampling.

=head2 to_hash

Serialize the envelope to a hash reference containing C<def>, flags, and
C<morpher_formula>. Suitable for JSON encoding.

    my $h = $e->to_hash;
    # { def => [...], is_morph => 1, morpher_formula => 'smoothstep', ... }

=head2 from_hash

Reconstruct an envelope from a hash reference (as produced by L</to_hash>):

    my $e = Math::SegmentedEnvelope->from_hash($h);

=head1 SERIALIZATION & STORABLE

C<Math::SegmentedEnvelope> supports L<Storable> serialization natively via
C<STORABLE_freeze> and C<STORABLE_thaw> hooks:

    use Storable qw(freeze thaw dclone);

    my $frozen = freeze($e);
    my $thawed = thaw($frozen);
    my $cloned = dclone($e);

For JSON or custom storage, use L</to_hash> and L</from_hash>.

=head2 STORABLE_freeze

Internal hook for L<Storable> serialization. Returns a frozen scalar representation of the envelope.

=head2 STORABLE_thaw

Internal hook for L<Storable> deserialization. Restores envelope state from frozen data.

=head1 EXPORTED FUNCTIONS

=head2 env(...)

Shortcut for C<< Math::SegmentedEnvelope->new(...) >>.

=head2 adsr($attack, $decay, $sustain, $release, %opts)

ADSR envelope. C<$sustain> is a fraction of peak (0-1). Options: C<peak>,
C<sustain_time>, C<attack_curve>, C<decay_curve>, C<release_curve>, plus
standard envelope options.

=head2 perc($attack, $decay, %opts)

Percussive envelope (attack to peak, decay to zero). Options: C<peak>,
C<attack_curve>, C<decay_curve>.

=head2 asr($attack, $sustain_time, $release, %opts)

Attack-Sustain-Release envelope. Options: C<peak>, C<attack_curve>,
C<release_curve>.

=head2 concat(@envelopes)

Concatenate envelopes. See L</TRANSFORMATION METHODS>.

=head2 morpher_formulas()

Returns predefined morpher names. See L</ACCESSOR METHODS>.

=head2 spline(\@times, \@values, %opts)

Create a smooth Catmull-Rom spline envelope through control points. Each
control point is a (time, value) pair. The spline passes exactly through
all control points. Implemented in XS.

    use Math::SegmentedEnvelope 'spline';

    my $e = spline(
        [0, 0.3, 0.7, 1.0],    # times
        [0, 1.0, 0.2, 0.8],    # values
        resolution => 16,        # segments per span (default: 8)
        tension    => 0.0,       # 0=Catmull-Rom, 1=linear (default: 0)
    );

Also works as a class method: C<< Math::SegmentedEnvelope->spline(...) >>.
Accepts standard envelope options (C<is_morph>, C<morpher_formula>, etc.).

=head1 EXAMPLES

=head2 Audio note envelope

    use Math::SegmentedEnvelope qw(adsr);

    my $env = adsr(0.01, 0.1, 0.7, 0.3, is_morph => 1);
    my $s = $env->static;

    # Generate amplitude envelope for 44100 Hz audio
    my $sr = 44100;
    my $dur = $env->duration;
    for my $i (0 .. int($dur * $sr) - 1) {
        my $amp = $s->($i / $sr);
        # ... apply $amp to audio sample ...
    }

=head2 LFO wavetable

    use Math::SegmentedEnvelope 'env';

    my $lfo = env(
        [[0, 1, 0, -1, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        is_morph => 1,
    );
    my @wavetable = $lfo->table(1024, 1);  # one cycle, 1024 samples

=head2 Ping-pong envelope

    use Math::SegmentedEnvelope qw(perc concat);

    my $up   = perc(0.01, 0.5);
    my $down = $up->reverse;
    my $pingpong = concat($up, $down);

=head2 Custom morpher formula

    my $e = env(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_morph => 1,
        morpher_formula => 't * t * (3 - 2 * t)',  # smoothstep
    );
    printf "Backend: %s\n", $e->morpher_jit_backend;  # "tcc", "x86", or "builtin"

=head1 Math::SegmentedEnvelope::Static

Returned by L</static>. Overloads C<&{}> so it can be called as a code reference.

    my $s = $e->static;
    my $val = $s->(0.5);          # via overload
    my $val = $s->call(0.5);      # explicit method

=head1 OPERATOR OVERLOADING

C<Math::SegmentedEnvelope> overloads the following operators:

=over 4

=item * B<< &{} >> - Callable as a code reference:

    my $val = $e->(0.5);   # equivalent to $e->at(0.5)

=item * B<< + >> - Offset or addition:

    my $shifted = $e + 0.5;   # equivalent to $e->offset(0.5)
    my $sum     = $e1 + $e2;  # equivalent to $e1->add($e2)

=item * B<< - >> - Subtraction or negation:

    my $shifted = $e - 0.2;   # equivalent to $e->offset(-0.2)
    my $diff    = $e1 - $e2;  # equivalent to $e1->add($e2->scale(-1))
    my $inv     = 1 - $e;     # invert envelope shape

=item * B<< * >> - Scaling or multiplication:

    my $louder  = $e * 1.5;   # equivalent to $e->scale(1.5)
    my $ringmod = $e1 * $e2;  # equivalent to $e1->multiply($e2)

=item * B<< neg >> - Invert sign:

    my $neg = -$e;            # equivalent to $e->scale(-1)

=item * B<< "" >> - Stringification:

    print "$e\n";  # Math::SegmentedEnvelope(segments=4, duration=1.2s)

=back

=head1 AUTHOR

Yegor Korablev E<lt>egor@cpan.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
