# NAME

Math::SegmentedEnvelope - create/manage/evaluate segmented (curved) envelope

[![CI](https://github.com/vividsnow/Math-SegmentedEnvelope/actions/workflows/ci.yml/badge.svg)](https://github.com/vividsnow/Math-SegmentedEnvelope/actions/workflows/ci.yml)

# SYNOPSIS

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

# DESCRIPTION

Math::SegmentedEnvelope creates and evaluates segmented envelopes with curved
segments. Useful for audio synthesis, animation, or any application requiring
smooth interpolation between control points.

Each envelope is defined by N+1 **levels** (breakpoint values), N **durations**
(time for each segment), and N **curves** controlling the interpolation shape.

## Curve values

The curve parameter controls the shape of interpolation within each segment:

- **Positive curves** (e.g. 2, 3) produce ease-in (slow start, fast end)
- **Negative curves** (e.g. -2, -3) produce ease-out (fast start, slow end)
- **Curve = 1 or -1** produces linear interpolation
- **Larger absolute values** produce more extreme curvature

# CONSTRUCTOR

## new

    my $e = Math::SegmentedEnvelope->new($def, %options);
    my $e = Math::SegmentedEnvelope->new(%options);
    my $e = Math::SegmentedEnvelope->new();  # random envelope

If no definition is provided, a random envelope is generated (respects Perl's
`srand` for reproducibility).

Options:

- def => \[$levels, $durations, $curves\]

    Envelope definition. Can also be passed as the first positional argument.

- is\_morph => $bool

    Apply a smoothing morpher function to the interpolation curve.
    Default morpher is `sin(t * PI/2)^2`. See ["morpher"](#morpher) and ["morpher\_formula"](#morpher_formula).

- is\_hold => $bool

    Clamp time to \[0, duration\]. Without this, time beyond the envelope duration
    wraps around. With it, the envelope holds at its final value.

- is\_fold\_over => $bool

    When time exceeds duration, mirror/fold instead of wrapping. Creates a
    ping-pong effect.

- is\_wrap\_neg => $bool

    Invert the fold direction for negative time values.

- morpher => $coderef

    Custom morpher function as a Perl code reference. Called with a single argument
    `t` in \[0,1\], must return a value in \[0,1\]. Has Perl callback overhead.

- morpher\_formula => $string

    A morpher specified as a math expression or predefined name. Compiled to native
    code via JIT (TCC or x86-64) or evaluated via tinyexpr -- much faster than a
    Perl callback. Automatically enables `is_morph`. See ["morpher\_formula"](#morpher_formula).

- border\_level => $scalar | \[$start, $end\]

    Default border levels for random envelope generation.

# EVALUATION METHODS

## at($t)

Evaluate envelope at time `$t`. Returns the interpolated value.
Maintains internal state for optimized sequential access.

## static

Returns a [Math::SegmentedEnvelope::Static](https://metacpan.org/pod/Math%3A%3ASegmentedEnvelope%3A%3AStatic) object that captures the current
envelope state. Callable as a code reference for performance-critical loops:

    my $s = $e->static;
    for my $i (0 .. 999) {
        push @samples, $s->($i / 1000 * $e->duration);
    }

## table($size, $cycles, $from, $to)

Generate a lookup table as a list of `$size` values.

- `$size` - Number of samples (required)
- `$cycles` - Number of envelope cycles to fit (default: 1)
- `$from` - Start time (default: 0)
- `$to` - End time (default: total duration)

    my @lfo = $e->table(1024, 4);       # 4 cycles in 1024 samples
    my @seg = $e->table(256, 1, 0, 0.5); # first half only

## segment\_at($t)

Returns the segment index (0-based) at time `$t`. Useful for triggering
events on segment boundaries.

    my $seg = $e->segment_at(0.15);  # which segment is active at t=0.15?

## area, integral

Returns the definite integral (total area under the envelope curve) as a scalar number.
Uses trapezoidal integration across segment breakpoints.

    my $total = $e->area;
    my $total = $e->integral;

# ACCESSOR METHODS

All accessors work as getters when called with no extra arguments, and as
setters when called with values.

## level($idx, \[$value\])

Get/set level at index. Supports negative indices (`-1` = last level).

## levels(\[@values\])

Get/set all levels.

## dur($idx, \[$value\])

Get/set duration at segment index. Supports negative indices.

## durs(\[@values\])

Get/set all durations.

## curve($idx, \[$value\])

Get/set curve at segment index. Supports negative indices.

## curves(\[@values\])

Get/set all curves.

## duration

Returns total duration (sum of all segment durations).

## segments

Returns number of segments (N).

## def

Returns the envelope definition as `[$levels, $durations, $curves]`.

## border\_level(\[$value\])

Get/set border levels for random generation. Returns `[$start, $end]`.

## is\_morph(\[$bool\]), is\_hold(\[$bool\]), is\_fold\_over(\[$bool\]), is\_wrap\_neg(\[$bool\])

Get/set flag values. See ["CONSTRUCTOR"](#constructor) for descriptions.

## morpher(\[$coderef\])

Get/set custom Perl morpher callback.

## morpher\_formula(\[$formula\])

Get/set the morpher formula. Accepts a predefined name or a math expression
string with variable `t`. Pass `undef` to reset to the default sine morpher.

    $env->morpher_formula('smoothstep');
    $env->morpher_formula('sin(t * 1.5708) ^ 2');
    $env->morpher_formula(undef);  # reset to default

Supported operators: `+ - * / ^ %`. Functions: `abs acos asin atan atan2
ceil cos cosh exp floor ln log log10 pow sin sinh sqrt tan tanh`.

Setting a formula automatically enables `is_morph`. The expression is
JIT-compiled to native code if possible (via TCC or a built-in x86-64
emitter), falling back to tinyexpr tree interpretation.

## morpher\_formulas()

Returns the list of predefined morpher names (26 functions):

    linear sine smoothstep smootherstep welch tanh
    quad_in quad_out quad_inout
    cubic_in cubic_out cubic_inout
    circ_in circ_out circ_inout
    exp_in exp_out
    back_in back_out back_inout
    elastic_in elastic_out elastic_inout
    bounce_in bounce_out bounce_inout

## morpher\_jit\_backend

Returns the morpher backend: `"tcc"` (TCC JIT), `"x86"` (hand-rolled JIT),
`"builtin"` (predefined C function), or `"none"` (default/tinyexpr).

# UTILITY METHODS

## normalize\_duration

Normalize durations so they sum to 1.0. Returns `$self`.

## clean

Reset internal cached state. Call this after modifying segment data via
setters if you plan to evaluate at non-sequential time values.

# TRANSFORMATION METHODS

All transformations return a new envelope, leaving the original unchanged.

## scale($factor)

Multiply all levels by `$factor` (default: 1.0).

    my $louder  = $e->scale(2.0);
    my $quieter = $e->scale(0.5);

## offset($value)

Add `$value` to all levels (default: 0).

    my $shifted = $e->offset(0.5);  # shift entire envelope up by 0.5

## invert

Flip all levels: `1 - level`. Useful for inverting an envelope shape.

    my $inv = $e->invert;

## stretch($factor)

Scale all durations by `$factor` (default: 1.0). Levels and curves are preserved.

    my $slow = $e->stretch(2.0);   # twice as long
    my $fast = $e->stretch(0.5);   # half duration

## with\_duration($duration)

Scale durations so the envelope has the specified total duration. Returns a new envelope.

    my $two_sec = $e->with_duration(2.0);

## clone, copy

Create a fast deep copy of the envelope in C.

    my $dup = $e->clone;

## reverse

Reverse the envelope direction. Durations are reversed and curve signs are
flipped.

## delay($time)

Prepend a hold at the initial level for `$time` seconds.

    my $delayed = $e->delay(0.5);

## add($other, %opts)

Add two envelopes sample-by-sample. Returns a resampled envelope.

    my $sum = $e1->add($e2, segments => 32);

## multiply($other, %opts)

Multiply two envelopes sample-by-sample (ring modulation, AM).

    my $am = $carrier->multiply($modulator, segments => 64);

## normalize($lo, $hi)

Scale levels to fit within `[$lo, $hi]` (default \[0, 1\]). Uses `min_value`
and `max_value` to determine current range.

    my $n = $e->normalize;           # [0, 1]
    my $n = $e->normalize(-1, 1);    # bipolar

## loop($n)

Repeat the envelope `$n` times end-to-end. Uses `concat` internally.

    my $lfo = $cycle->loop(16);      # 16 repetitions

## map\_levels($coderef)

Apply a function to every level. Durations and curves are preserved.

    my $gamma = $e->map_levels(sub { $_[0] ** 2.2 });
    my $clamp = $e->map_levels(sub { $_[0] > 0.5 ? 0.5 : $_[0] });

## quantize($steps)

Snap all levels to `$steps` discrete values. Returns a new envelope.
Implemented in XS.

    my $lofi = $e->quantize(4);   # levels snapped to 0, 0.25, 0.5, 0.75, 1.0

## trim($from, $to, %opts)

Extract a time slice as a new envelope by resampling. Implemented in XS.

    my $attack_only = $e->trim(0, 0.2);
    my $hires = $e->trim(0.1, 0.5, segments => 64);

## lerp($other, $mix)

Interpolate between two envelopes with the same segment count. Unlike
`blend`, this interpolates levels, durations, and curves directly without
resampling -- much cheaper. Implemented in XS.

    my $mid = $bright->lerp($soft, 0.5);

Croaks if segment counts differ (use `blend` for that case).

## resample($n)

Re-approximate the envelope with exactly `$n` segments by sampling.
Useful for simplifying high-segment-count results from `blend` or `spline`.
Implemented in XS.

    my $simple = $complex->resample(8);

## clamp($lo, $hi)

Clamp all levels to `[$lo, $hi]`. Implemented in XS.

    my $safe = $e->clamp(0, 1);

## smooth($passes)

Apply moving-average smoothing to levels. Endpoints are preserved.
`$passes` defaults to 1; higher values produce smoother results.
Implemented in XS.

    my $soft = $noisy->smooth(3);

## derivative

Returns a new envelope of the rate of change (slope) at each segment
boundary. Implemented in XS.

    my $slope = $e->derivative;

## integrate

Returns the cumulative integral (area under the curve) via trapezoidal
rule on the breakpoint levels. Starts at 0. Implemented in XS.

Note: the trapezoidal approximation is exact for linear segments (curve=1)
but approximate for curved segments. For better accuracy on curved envelopes,
`resample` to more segments first: `$e->resample(64)->integrate`.

    my $area = $e->integrate;

## from\_samples(\\@values, $duration)

Create an envelope from raw sample data (the inverse of `table`).
Each value becomes a level; segments are evenly spaced across `$duration`.
Implemented in XS. Works as class method or exported function.

    my $e = Math::SegmentedEnvelope->from_samples([0, 0.5, 1, 0.5, 0], 1.0);

## to\_svg(%opts)

Returns an SVG string of the envelope shape.

Options: `width` (400), `height` (150), `padding` (10),
`stroke` (color), `fill` (color), `samples` (width - 2\*padding).

    my $svg = $e->to_svg(width => 600, height => 200);

## to\_supercollider(%opts)

Returns a SuperCollider `Env()` definition string.
Option: `name` (variable name, default: `"env"`).

    print $e->to_supercollider(name => 'ampEnv');
    # var ampEnv = Env([0, 1, 0.7, 0], [0.1, 0.3, 0.5], [2, -2, 1]);

## to\_csound

Returns a Csound `linseg` statement string.

    print $e->to_csound;
    # linseg 0, 0.1, 1, 0.3, 0.7, 0.5, 0

## to\_glsl(%opts)

Returns a GLSL function that evaluates the envelope on the GPU.
Samples the envelope into a float array with linear interpolation.
Options: `name` (function name, default `"envelope"`), `samples` (default 64).

    print $e->to_glsl(name => 'ampEnv', samples => 32);

## as\_pdl

Returns the breakpoint levels as a [PDL](https://metacpan.org/pod/PDL) piddle (N+1 elements). No sampling
\-- direct binary copy from the internal C array. Requires PDL (loaded on demand).

    my $levels = $e->as_pdl;   # fast, no resampling

## to\_pdl($samples)

Returns `$samples` (default 1024) evenly-sampled envelope values as a PDL
piddle. Uses `_raw_table` internally to avoid Perl-level array intermediary.

    my $sig = $e->to_pdl(4096);

## from\_pdl($piddle, $duration)

Create an envelope from a PDL piddle. Class method.

    my $e = Math::SegmentedEnvelope->from_pdl($piddle, 2.0);

## blend($other, $mix, %opts)

Blend with another envelope by resampling both.

    my $blended = $e1->blend($e2, 0.3);  # 70% e1, 30% e2

Options: `segments` (default 32), `duration` (default: self's duration).

## concat(@envelopes)

Concatenate envelopes end-to-end. Works as function or class method.
The result inherits configuration options (such as `is_hold`, `is_fold_over`, etc.)
from the first envelope.

    my $chain = concat($e1, $e2, $e3);

## min\_value($samples)

Returns the minimum value of the envelope, estimated by sampling `$samples`
points (default 1024).

## max\_value($samples)

Returns the maximum value, estimated by sampling.

## to\_hash

Serialize the envelope to a hash reference containing `def`, flags, and
`morpher_formula`. Suitable for JSON encoding.

    my $h = $e->to_hash;
    # { def => [...], is_morph => 1, morpher_formula => 'smoothstep', ... }

## from\_hash

Reconstruct an envelope from a hash reference (as produced by ["to\_hash"](#to_hash)):

    my $e = Math::SegmentedEnvelope->from_hash($h);

# SERIALIZATION & STORABLE

`Math::SegmentedEnvelope` supports [Storable](https://metacpan.org/pod/Storable) serialization natively via
`STORABLE_freeze` and `STORABLE_thaw` hooks:

    use Storable qw(freeze thaw dclone);

    my $frozen = freeze($e);
    my $thawed = thaw($frozen);
    my $cloned = dclone($e);

For JSON or custom storage, use ["to\_hash"](#to_hash) and ["from\_hash"](#from_hash).

# EXPORTED FUNCTIONS

## env(...)

Shortcut for `Math::SegmentedEnvelope->new(...)`.

## adsr($attack, $decay, $sustain, $release, %opts)

ADSR envelope. `$sustain` is a fraction of peak (0-1). Options: `peak`,
`sustain_time`, `attack_curve`, `decay_curve`, `release_curve`, plus
standard envelope options.

## perc($attack, $decay, %opts)

Percussive envelope (attack to peak, decay to zero). Options: `peak`,
`attack_curve`, `decay_curve`.

## asr($attack, $sustain\_time, $release, %opts)

Attack-Sustain-Release envelope. Options: `peak`, `attack_curve`,
`release_curve`.

## concat(@envelopes)

Concatenate envelopes. See ["TRANSFORMATION METHODS"](#transformation-methods).

## morpher\_formulas()

Returns predefined morpher names. See ["ACCESSOR METHODS"](#accessor-methods).

## spline(\\@times, \\@values, %opts)

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

Also works as a class method: `Math::SegmentedEnvelope->spline(...)`.
Accepts standard envelope options (`is_morph`, `morpher_formula`, etc.).

# EXAMPLES

## Audio note envelope

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

## LFO wavetable

    use Math::SegmentedEnvelope 'env';

    my $lfo = env(
        [[0, 1, 0, -1, 0], [0.25, 0.25, 0.25, 0.25], [2, -2, 2, -2]],
        is_morph => 1,
    );
    my @wavetable = $lfo->table(1024, 1);  # one cycle, 1024 samples

## Ping-pong envelope

    use Math::SegmentedEnvelope qw(perc concat);

    my $up   = perc(0.01, 0.5);
    my $down = $up->reverse;
    my $pingpong = concat($up, $down);

## Custom morpher formula

    my $e = env(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_morph => 1,
        morpher_formula => 't * t * (3 - 2 * t)',  # smoothstep
    );
    printf "Backend: %s\n", $e->morpher_jit_backend;  # "tcc", "x86", or "builtin"

# Math::SegmentedEnvelope::Static

Returned by ["static"](#static). Overloads `&{}` so it can be called as a code reference.

    my $s = $e->static;
    my $val = $s->(0.5);          # via overload
    my $val = $s->call(0.5);      # explicit method

# OPERATOR OVERLOADING

`Math::SegmentedEnvelope` overloads the following operators:

- **&{}** - Callable as a code reference:

        my $val = $e->(0.5);   # equivalent to $e->at(0.5)

- **+** - Offset or addition:

        my $shifted = $e + 0.5;   # equivalent to $e->offset(0.5)
        my $sum     = $e1 + $e2;  # equivalent to $e1->add($e2)

- **-** - Subtraction or negation:

        my $shifted = $e - 0.2;   # equivalent to $e->offset(-0.2)
        my $diff    = $e1 - $e2;  # equivalent to $e1->add($e2->scale(-1))
        my $inv     = 1 - $e;     # invert envelope shape

- **\*** - Scaling or multiplication:

        my $louder  = $e * 1.5;   # equivalent to $e->scale(1.5)
        my $ringmod = $e1 * $e2;  # equivalent to $e1->multiply($e2)

- **neg** - Invert sign:

        my $neg = -$e;            # equivalent to $e->scale(-1)

- **""** - Stringification:

        print "$e\n";  # Math::SegmentedEnvelope(segments=4, duration=1.2s)

# AUTHOR

Yegor Korablev <egor@cpan.org>

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
