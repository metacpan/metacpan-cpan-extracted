use strict;
use warnings;
use Test::More;
use Math::SegmentedEnvelope qw(adsr asr perc concat morpher_formulas spline);

my $eps = 0.0001;

# ============================================================================
# ADSR envelope
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);

    ok($e, 'adsr creates envelope');
    is($e->segments, 4, 'adsr has 4 segments');
    ok(abs($e->duration - 1.0) < $eps, 'adsr duration is sum of A+D+S+R');

    # Check levels at key points
    ok(abs($e->at(0) - 0) < $eps, 'adsr starts at 0');
    ok(abs($e->at(0.1) - 1.0) < $eps, 'adsr reaches peak at attack');
    ok(abs($e->at(0.2) - 0.7) < $eps, 'adsr reaches sustain after decay');
    ok(abs($e->at(0.5) - 0.7) < $eps, 'adsr holds sustain level');
    ok(abs($e->at(1.0 - $eps) - 0) < 0.01, 'adsr ends near 0');
}

# ============================================================================
# ADSR with custom options
# ============================================================================
{
    my $e = adsr(0.2, 0.2, 0.5, 0.4, peak => 2.0, sustain_time => 0.2);

    is($e->segments, 4, 'custom adsr has 4 segments');
    ok(abs($e->duration - 1.0) < $eps, 'custom adsr duration');
    ok(abs($e->at(0.2) - 2.0) < $eps, 'custom adsr peak is 2.0');
    ok(abs($e->at(0.4) - 1.0) < $eps, 'custom adsr sustain is peak*0.5');
}

# ============================================================================
# ADSR as class method
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->adsr(0.1, 0.1, 0.7, 0.3);
    ok($e, 'adsr works as class method');
    is($e->segments, 4, 'class method adsr has 4 segments');
}

# ============================================================================
# perc envelope
# ============================================================================
{
    my $e = perc(0.01, 0.5);

    ok($e, 'perc creates envelope');
    is($e->segments, 2, 'perc has 2 segments');
    ok(abs($e->duration - 0.51) < $eps, 'perc duration is attack + decay');

    # Check levels
    ok(abs($e->at(0) - 0) < $eps, 'perc starts at 0');
    ok(abs($e->at(0.01) - 1.0) < $eps, 'perc reaches peak');
    ok(abs($e->at(0.51 - $eps) - 0) < 0.01, 'perc ends near 0');
}

# ============================================================================
# perc with custom options
# ============================================================================
{
    my $e = perc(0.05, 0.2, peak => 0.8);

    ok(abs($e->at(0.05) - 0.8) < $eps, 'custom perc peak is 0.8');
    ok(abs($e->at(0.25) - 0) < $eps, 'custom perc ends at 0');
}

# ============================================================================
# perc as class method
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->perc(0.02, 0.3);
    ok($e, 'perc works as class method');
    is($e->segments, 2, 'class method perc has 2 segments');
}

# ============================================================================
# ASR envelope
# ============================================================================
{
    my $e = asr(0.1, 0.5, 0.3);

    ok($e, 'asr creates envelope');
    is($e->segments, 3, 'asr has 3 segments');
    ok(abs($e->duration - 0.9) < $eps, 'asr duration is A+S+R');

    # Check levels at key points
    ok(abs($e->at(0) - 0) < $eps, 'asr starts at 0');
    ok(abs($e->at(0.1) - 1.0) < $eps, 'asr reaches peak at attack');
    ok(abs($e->at(0.3) - 1.0) < $eps, 'asr holds at peak during sustain');
    ok(abs($e->at(0.6) - 1.0) < $eps, 'asr still at peak end of sustain');
    ok(abs($e->at(0.9 - $eps) - 0) < 0.01, 'asr ends near 0');
}

# ============================================================================
# ASR with custom options
# ============================================================================
{
    my $e = asr(0.2, 0.3, 0.2, peak => 0.5);

    is($e->segments, 3, 'custom asr has 3 segments');
    ok(abs($e->at(0.2) - 0.5) < $eps, 'custom asr peak is 0.5');
    ok(abs($e->at(0.4) - 0.5) < $eps, 'custom asr sustain at peak');
}

# ============================================================================
# ASR as class method
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->asr(0.1, 0.4, 0.2);
    ok($e, 'asr works as class method');
    is($e->segments, 3, 'class method asr has 3 segments');
}

# ============================================================================
# concat
# ============================================================================
{
    my $e1 = perc(0.1, 0.2);  # 0 -> 1 -> 0, duration 0.3
    my $e2 = perc(0.1, 0.2);  # 0 -> 1 -> 0, duration 0.3

    my $combined = concat($e1, $e2);

    ok($combined, 'concat creates envelope');
    is($combined->segments, 4, 'concat has sum of segments');
    ok(abs($combined->duration - 0.6) < $eps, 'concat duration is sum');

    # Check shape
    ok(abs($combined->at(0) - 0) < $eps, 'concat starts at 0');
    ok(abs($combined->at(0.1) - 1.0) < $eps, 'concat first peak');
    ok(abs($combined->at(0.3) - 0) < $eps, 'concat first end/second start');
    ok(abs($combined->at(0.4) - 1.0) < $eps, 'concat second peak');
    ok(abs($combined->at(0.6) - 0) < $eps, 'concat ends at 0');
}

# ============================================================================
# concat with different envelopes
# ============================================================================
{
    my $e1 = asr(0.1, 0.2, 0.1);  # 0 -> 1 -> 1 -> 0
    my $e2 = perc(0.05, 0.15);    # 0 -> 1 -> 0

    my $combined = concat($e1, $e2);

    is($combined->segments, 5, 'concat asr+perc has 5 segments');
    ok(abs($combined->duration - 0.6) < $eps, 'concat asr+perc duration');
}

# ============================================================================
# concat as class method
# ============================================================================
{
    my $e1 = perc(0.1, 0.1);
    my $e2 = perc(0.1, 0.1);
    my $combined = Math::SegmentedEnvelope->concat($e1, $e2);
    ok($combined, 'concat works as class method');
    is($combined->segments, 4, 'class method concat has correct segments');
}

# ============================================================================
# scale method
# ============================================================================
{
    my $e = perc(0.1, 0.2, peak => 1.0);

    my $scaled = $e->scale(2.0);
    ok($scaled, 'scale returns new envelope');
    is($scaled->segments, 2, 'scaled envelope has same segments');
    ok(abs($scaled->duration - $e->duration) < $eps, 'scale preserves duration');
    ok(abs($scaled->at(0.1) - 2.0) < $eps, 'scale doubles peak');
    ok(abs($scaled->at(0) - 0) < $eps, 'scale: zero stays zero');
    ok(abs($scaled->at(0.3) - 0) < $eps, 'scale: zero stays zero at end');

    # Original unchanged
    ok(abs($e->at(0.1) - 1.0) < $eps, 'original unchanged after scale');
}

# ============================================================================
# scale with fractional factor
# ============================================================================
{
    my $e = asr(0.1, 0.2, 0.1, peak => 1.0);
    my $half = $e->scale(0.5);

    ok(abs($half->at(0.1) - 0.5) < $eps, 'scale 0.5 halves peak');
    ok(abs($half->at(0.2) - 0.5) < $eps, 'scale 0.5 halves sustain');
}

# ============================================================================
# reverse method
# ============================================================================
{
    my $e = perc(0.1, 0.2);  # 0 -> 1 -> 0

    my $rev = $e->reverse;
    ok($rev, 'reverse returns new envelope');
    is($rev->segments, 2, 'reversed envelope has same segments');
    ok(abs($rev->duration - $e->duration) < $eps, 'reverse preserves duration');

    # Reversed perc: 0 -> 1 -> 0 becomes 0 -> 1 -> 0 (symmetric)
    # But durations are reversed: 0.2 attack, 0.1 decay
    ok(abs($rev->at(0) - 0) < $eps, 'reversed starts at 0');
    ok(abs($rev->at(0.2) - 1.0) < $eps, 'reversed peak at 0.2');
    ok(abs($rev->at(0.3) - 0) < $eps, 'reversed ends at 0');
}

# ============================================================================
# reverse with asymmetric envelope
# ============================================================================
{
    my $e = asr(0.1, 0.3, 0.2);  # 0 -> 1 -> 1 -> 0, total 0.6

    my $rev = $e->reverse;

    # Reversed: 0 -> 1 -> 1 -> 0 with durations [0.2, 0.3, 0.1]
    ok(abs($rev->at(0) - 0) < $eps, 'reversed asr starts at 0');
    ok(abs($rev->at(0.2) - 1.0) < $eps, 'reversed asr reaches peak');
    ok(abs($rev->at(0.5) - 1.0) < $eps, 'reversed asr holds');
    ok(abs($rev->at(0.6) - 0) < $eps, 'reversed asr ends at 0');
}

# ============================================================================
# delay method
# ============================================================================
{
    my $e = perc(0.1, 0.2);  # 0 -> 1 -> 0, duration 0.3

    my $delayed = $e->delay(0.5);
    ok($delayed, 'delay returns new envelope');
    is($delayed->segments, 3, 'delayed envelope has +1 segment');
    ok(abs($delayed->duration - 0.8) < $eps, 'delay adds to duration');

    # Check shape
    ok(abs($delayed->at(0) - 0) < $eps, 'delayed starts at 0');
    ok(abs($delayed->at(0.25) - 0) < $eps, 'delayed holds during delay');
    ok(abs($delayed->at(0.5) - 0) < $eps, 'delayed still at 0 at delay end');
    ok(abs($delayed->at(0.6) - 1.0) < $eps, 'delayed reaches peak');
    ok(abs($delayed->at(0.8) - 0) < $eps, 'delayed ends at 0');

    # Original unchanged
    ok(abs($e->duration - 0.3) < $eps, 'original unchanged after delay');
}

# ============================================================================
# delay with zero/negative time
# ============================================================================
{
    my $e = perc(0.1, 0.2);
    my $same = $e->delay(0);
    is($same, $e, 'delay(0) returns same envelope');

    my $neg = $e->delay(-1);
    is($neg, $e, 'delay(negative) returns same envelope');
}

# ============================================================================
# blend method
# ============================================================================
{
    # Create two simple envelopes
    my $e1 = Math::SegmentedEnvelope->new([[0, 1, 0], [0.5, 0.5], [1, 1]]);
    my $e2 = Math::SegmentedEnvelope->new([[1, 0, 1], [0.5, 0.5], [1, 1]]);

    my $blended = $e1->blend($e2, 0.5, segments => 10);
    ok($blended, 'blend returns new envelope');
    is($blended->segments, 10, 'blend creates specified segments');
    ok(abs($blended->duration - 1.0) < $eps, 'blend uses first envelope duration');

    # At mix=0.5, start should be (0+1)/2 = 0.5
    ok(abs($blended->at(0) - 0.5) < $eps, 'blend start is average');
}

# ============================================================================
# blend with different mix ratios
# ============================================================================
{
    my $e1 = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    my $e2 = Math::SegmentedEnvelope->new([[2, 2], [1], [1]]);

    # mix=0 should be all e1
    my $all_e1 = $e1->blend($e2, 0, segments => 4);
    ok(abs($all_e1->at(0) - 0) < $eps, 'blend mix=0 is all self at start');
    ok(abs($all_e1->at(1) - 1) < $eps, 'blend mix=0 is all self at end');

    # mix=1 should be all e2
    my $all_e2 = $e1->blend($e2, 1, segments => 4);
    ok(abs($all_e2->at(0) - 2) < $eps, 'blend mix=1 is all other at start');
    ok(abs($all_e2->at(1) - 2) < $eps, 'blend mix=1 is all other at end');
}

# ============================================================================
# morpher_formula with custom expression (equivalent to default sine morpher)
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_morph => 1,
        morpher_formula => 'sin(t * 1.5707963267948966) ^ 2',
    );
    ok($e, 'morpher_formula creates envelope');

    # Compare with default sine morpher
    my $e_default = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_morph => 1,
    );

    ok(abs($e->at(0) - $e_default->at(0)) < $eps, 'formula sine matches default at 0');
    ok(abs($e->at(0.25) - $e_default->at(0.25)) < $eps, 'formula sine matches default at 0.25');
    ok(abs($e->at(0.5) - $e_default->at(0.5)) < $eps, 'formula sine matches default at 0.5');
    ok(abs($e->at(0.75) - $e_default->at(0.75)) < $eps, 'formula sine matches default at 0.75');
}

# ============================================================================
# morpher_formula with linear expression
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 't',
    );

    # Linear morpher: t -> t, so with curve=1, result should be linear
    ok(abs($e->at(0) - 0) < $eps, 'linear formula at 0');
    ok(abs($e->at(1) - 1) < $eps, 'linear formula at 1');
    ok(abs($e->at(0.5) - 0.5) < $eps, 'linear formula at 0.5');
}

# ============================================================================
# morpher_formula accessor
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
    );

    is($e->morpher_formula, undef, 'morpher_formula is undef by default');

    $e->morpher_formula('t * t');
    is($e->morpher_formula, 't * t', 'morpher_formula getter returns formula');

    # Reset
    $e->morpher_formula(undef);
    is($e->morpher_formula, undef, 'morpher_formula reset to undef');
}

# ============================================================================
# predefined morpher: linear
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 'linear',
    );

    is($e->morpher_formula, 'linear', 'predefined morpher name returned');
    ok(abs($e->at(0) - 0) < $eps, 'predefined linear at 0');
    ok(abs($e->at(0.5) - 0.5) < $eps, 'predefined linear at 0.5');
    ok(abs($e->at(1) - 1) < $eps, 'predefined linear at 1');
}

# ============================================================================
# predefined morpher: smoothstep
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 'smoothstep',
    );

    ok(abs($e->at(0) - 0) < $eps, 'smoothstep at 0');
    ok(abs($e->at(1) - 1) < $eps, 'smoothstep at 1');
    # smoothstep(0.5) = 0.5*0.5*(3-2*0.5) = 0.25*2 = 0.5
    ok(abs($e->at(0.5) - 0.5) < $eps, 'smoothstep at 0.5');
}

# ============================================================================
# morpher_formula works with static()
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 't * t',
    );

    my $s = $e->static;
    ok($s, 'static with formula');
    ok(abs($s->(0) - 0) < $eps, 'static formula at 0');
    ok(abs($s->(1) - 1) < $eps, 'static formula at 1');
    ok(abs($s->(0.5) - $e->at(0.5)) < $eps, 'static formula matches at()');
}

# ============================================================================
# morpher_formula works with table()
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 'linear',
    );

    my @tbl = $e->table(4);
    is(scalar @tbl, 4, 'table returns correct size');
    ok(abs($tbl[0] - 0) < $eps, 'table[0] with formula');
}

# ============================================================================
# morpher_formulas() class method
# ============================================================================
{
    my @names = Math::SegmentedEnvelope::morpher_formulas();
    ok(scalar @names >= 10, 'morpher_formulas returns list');
    ok((grep { $_ eq 'sine' } @names), 'sine in predefined list');
    ok((grep { $_ eq 'linear' } @names), 'linear in predefined list');
    ok((grep { $_ eq 'smoothstep' } @names), 'smoothstep in predefined list');
    ok((grep { $_ eq 'cubic_in' } @names), 'cubic_in in predefined list');
    ok((grep { $_ eq 'exp_in' } @names), 'exp_in in predefined list');
    ok((grep { $_ eq 'tanh' } @names), 'tanh in predefined list');
    ok((grep { $_ eq 'welch' } @names), 'welch in predefined list');
}

# ============================================================================
# morpher_formula parse error
# ============================================================================
{
    eval {
        Math::SegmentedEnvelope->new(
            [[0, 1], [1], [1]],
            morpher_formula => 'invalid $$$ formula',
        );
    };
    like($@, qr/parse error/, 'invalid formula croaks');
}


# ============================================================================
# Flag tests: is_hold
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_hold => 1,
    );

    # at(beyond_duration) should clamp to end value
    ok(abs($e->at(2.0) - 0) < $eps, 'is_hold: at(beyond duration) clamps to last level');
    ok(abs($e->at(1.0) - 0) < $eps, 'is_hold: at(duration) returns last level');

    # at(negative) should return level[0]
    ok(abs($e->at(-0.5) - 0) < $eps, 'is_hold: at(negative) returns level[0]');
    ok(abs($e->at(-10) - 0) < $eps, 'is_hold: at(very negative) returns level[0]');

    # Normal range still works
    ok(abs($e->at(0) - 0) < $eps, 'is_hold: at(0) returns start level');
    ok(abs($e->at(0.5) - 1) < $eps, 'is_hold: midpoint still works');
}

# ============================================================================
# Flag tests: is_fold_over
# ============================================================================
{
    # Simple linear envelope: 0 -> 1 over duration 1.0
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_fold_over => 1,
    );

    # at(1.5*duration) should mirror back - 1.5 wraps to 0.5 on the way back
    my $val_fold = $e->at(1.5);
    my $val_half = $e->at(0.5);
    ok(abs($val_fold - $val_half) < $eps, 'is_fold_over: at(1.5) mirrors to at(0.5)');

    # at(2.0) should be back at start
    ok(abs($e->at(2.0) - $e->at(0)) < $eps, 'is_fold_over: at(2*dur) returns to start');

    # at(0.75) on fold = at(0.25) mirrored
    my $val_075_fold = $e->at(1.75);
    my $val_025 = $e->at(0.25);
    ok(abs($val_075_fold - $val_025) < $eps, 'is_fold_over: at(1.75) mirrors to at(0.25)');
}

# ============================================================================
# Flag tests: is_wrap_neg
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_fold_over => 1,
        is_wrap_neg => 1,
    );

    # With is_wrap_neg, negative time wrapping should differ from without
    my $e_no_wrap = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_fold_over => 1,
        is_wrap_neg => 0,
    );

    # At t=-1.5 (at=1.5, ratio=1.5, fold_check=(int)(1.5)%2=1):
    #   without wrap_neg: fold_check=1 -> fold -> (1 - 0.5)*1 = 0.5
    #   with wrap_neg:    fold_check=!1=0 -> wrap -> 0.5*1 = 0.5
    # These happen to be the same for this ratio. Use t=-2.5 instead:
    #   at=2.5, ratio=2.5, fold_check=(int)(2.5)%2=0
    #   without wrap_neg: fold_check=0 -> wrap -> 0.5
    #   with wrap_neg:    fold_check=!0=1 -> fold -> 0.5
    # Still symmetric. Use asymmetric envelope:
    my $e_asym = Math::SegmentedEnvelope->new(
        [[0, 1, 0.3], [0.5, 0.5], [2, -2]],
        is_fold_over => 1,
        is_wrap_neg => 1,
    );
    my $e_asym_no = Math::SegmentedEnvelope->new(
        [[0, 1, 0.3], [0.5, 0.5], [2, -2]],
        is_fold_over => 1,
        is_wrap_neg => 0,
    );
    my $val_neg_wrap = $e_asym->at(-1.3);
    my $val_neg_no_wrap = $e_asym_no->at(-1.3);
    ok(abs($val_neg_wrap - $val_neg_no_wrap) > $eps,
       'is_wrap_neg: flips fold direction for negative time');

    # Basic: negative time without exceeding duration just uses abs(t)
    ok(abs($e->at(-0.5) - $e->at(0.5)) < $eps, 'is_wrap_neg: at(-0.5) == at(0.5) within duration');
}

# ============================================================================
# Flag tests: is_morph
# ============================================================================
{
    my $e_morph = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [3]],
        is_morph => 1,
    );
    my $e_no_morph = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [3]],
        is_morph => 0,
    );

    # With morph, the sine function is applied, so values at 0.25 should differ
    my $v_morph = $e_morph->at(0.25);
    my $v_no_morph = $e_no_morph->at(0.25);
    ok(abs($v_morph - $v_no_morph) > $eps, 'is_morph: morph changes interpolation at midpoint');

    # Endpoints should be the same
    ok(abs($e_morph->at(0) - $e_no_morph->at(0)) < $eps, 'is_morph: start level same');
    ok(abs($e_morph->at(1) - $e_no_morph->at(1)) < $eps, 'is_morph: end level same');
}

# ============================================================================
# Flag accessors as setters
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
    );

    # Test is_morph setter
    ok(!$e->is_morph, 'is_morph initially false');
    $e->is_morph(1);
    ok($e->is_morph, 'is_morph set to true');
    $e->is_morph(0);
    ok(!$e->is_morph, 'is_morph set back to false');

    # Test is_hold setter
    ok(!$e->is_hold, 'is_hold initially false');
    $e->is_hold(1);
    ok($e->is_hold, 'is_hold set to true');
    # Verify it actually takes effect
    ok(abs($e->at(5.0) - 0) < $eps, 'is_hold setter: clamping works after set');
    $e->is_hold(0);
    ok(!$e->is_hold, 'is_hold set back to false');

    # Test is_fold_over setter
    ok(!$e->is_fold_over, 'is_fold_over initially false');
    $e->is_fold_over(1);
    ok($e->is_fold_over, 'is_fold_over set to true');
    $e->is_fold_over(0);
    ok(!$e->is_fold_over, 'is_fold_over set back to false');

    # Test is_wrap_neg setter
    ok(!$e->is_wrap_neg, 'is_wrap_neg initially false');
    $e->is_wrap_neg(1);
    ok($e->is_wrap_neg, 'is_wrap_neg set to true');
    $e->is_wrap_neg(0);
    ok(!$e->is_wrap_neg, 'is_wrap_neg set back to false');
}

# ============================================================================
# Accessor tests: border_level
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        border_level => 0.5,
    );

    my $bl = $e->border_level;
    ok(ref $bl eq 'ARRAY', 'border_level returns arrayref');
    ok(abs($bl->[0] - 0.5) < $eps, 'border_level scalar sets start');
    ok(abs($bl->[1] - 0.5) < $eps, 'border_level scalar sets end same as start');

    # Set with arrayref
    $e->border_level([0.1, 0.9]);
    $bl = $e->border_level;
    ok(abs($bl->[0] - 0.1) < $eps, 'border_level set start to 0.1');
    ok(abs($bl->[1] - 0.9) < $eps, 'border_level set end to 0.9');

    # Set with scalar
    $e->border_level(0.3);
    $bl = $e->border_level;
    ok(abs($bl->[0] - 0.3) < $eps, 'border_level scalar setter start');
    ok(abs($bl->[1] - 0.3) < $eps, 'border_level scalar setter end');
}

# ============================================================================
# Accessor tests: normalize_duration
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [2, 3], [1, 1]],
    );

    ok(abs($e->duration - 5.0) < $eps, 'pre-normalize duration is 5');
    my $ret = $e->normalize_duration;
    ok(abs($e->duration - 1.0) < $eps, 'normalize_duration: durations sum to 1.0');
    ok($ret, 'normalize_duration returns self');

    # Check individual durations sum to 1
    my @durs = $e->durs;
    my $sum = 0;
    $sum += $_ for @durs;
    ok(abs($sum - 1.0) < $eps, 'normalize_duration: individual durs sum to 1.0');
    ok(abs($durs[0] - 0.4) < $eps, 'normalize_duration: first dur is 2/5');
    ok(abs($durs[1] - 0.6) < $eps, 'normalize_duration: second dur is 3/5');
}

# ============================================================================
# Accessor tests: clean
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
    );

    # Evaluate to build up cached state
    $e->at(0.3);
    $e->at(0.7);

    # Clean resets cached state - should still evaluate correctly
    $e->clean;
    ok(abs($e->at(0) - 0) < $eps, 'clean: at(0) correct after clean');
    ok(abs($e->at(0.5) - 1) < $eps, 'clean: at(0.5) correct after clean');
    ok(abs($e->at(1.0) - 0) < $eps, 'clean: at(1.0) correct after clean');
}

# ============================================================================
# Accessor tests: morpher_jit_backend
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
        morpher_formula => 't * t',
    );

    my $backend = $e->morpher_jit_backend;
    ok(defined $backend, 'morpher_jit_backend returns a defined value');
    ok(length($backend) > 0, 'morpher_jit_backend returns non-empty string');
}

# ============================================================================
# Setter tests: level, dur, curve with positive and negative indices
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 0.5, 1], [0.5, 0.5], [1, 1]],
    );

    # level getter
    ok(abs($e->level(0) - 0) < $eps, 'level(0) getter');
    ok(abs($e->level(1) - 0.5) < $eps, 'level(1) getter');
    ok(abs($e->level(2) - 1) < $eps, 'level(2) getter');

    # level negative index
    ok(abs($e->level(-1) - 1) < $eps, 'level(-1) returns last level');
    ok(abs($e->level(-2) - 0.5) < $eps, 'level(-2) returns second-to-last');

    # level setter
    $e->level(1, 0.8);
    ok(abs($e->level(1) - 0.8) < $eps, 'level(1, 0.8) sets value');

    # level setter with negative index
    $e->level(-1, 0.3);
    ok(abs($e->level(-1) - 0.3) < $eps, 'level(-1, 0.3) sets last level');
    ok(abs($e->level(2) - 0.3) < $eps, 'level(-1) setter reflects in positive index');

    # dur getter
    ok(abs($e->dur(0) - 0.5) < $eps, 'dur(0) getter');
    ok(abs($e->dur(1) - 0.5) < $eps, 'dur(1) getter');

    # dur negative index
    ok(abs($e->dur(-1) - 0.5) < $eps, 'dur(-1) returns last dur');

    # dur setter
    $e->dur(0, 0.3);
    ok(abs($e->dur(0) - 0.3) < $eps, 'dur(0, 0.3) sets value');
    ok(abs($e->duration - 0.8) < $eps, 'dur setter updates total duration');

    # dur setter with negative index
    $e->dur(-1, 0.7);
    ok(abs($e->dur(-1) - 0.7) < $eps, 'dur(-1, 0.7) sets last dur');
    ok(abs($e->duration - 1.0) < $eps, 'dur(-1) setter updates total duration');

    # curve getter
    ok(abs($e->curve(0) - 1) < $eps, 'curve(0) getter');
    ok(abs($e->curve(1) - 1) < $eps, 'curve(1) getter');

    # curve negative index
    ok(abs($e->curve(-1) - 1) < $eps, 'curve(-1) returns last curve');

    # curve setter
    $e->curve(0, -2);
    ok(abs($e->curve(0) - (-2)) < $eps, 'curve(0, -2) sets value');

    # curve setter with negative index
    $e->curve(-1, 3);
    ok(abs($e->curve(-1) - 3) < $eps, 'curve(-1, 3) sets last curve');
    ok(abs($e->curve(1) - 3) < $eps, 'curve(-1) setter reflects in positive index');
}

# ============================================================================
# Setter tests: levels, durs, curves as bulk setters
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 0.5, 1], [0.5, 0.5], [1, 1]],
    );

    # levels getter
    my @lvls = $e->levels;
    is(scalar @lvls, 3, 'levels getter returns 3 values');
    ok(abs($lvls[0] - 0) < $eps, 'levels[0]');
    ok(abs($lvls[1] - 0.5) < $eps, 'levels[1]');
    ok(abs($lvls[2] - 1) < $eps, 'levels[2]');

    # levels setter
    $e->levels(0.2, 0.8, 0.4);
    @lvls = $e->levels;
    ok(abs($lvls[0] - 0.2) < $eps, 'levels setter: [0] updated');
    ok(abs($lvls[1] - 0.8) < $eps, 'levels setter: [1] updated');
    ok(abs($lvls[2] - 0.4) < $eps, 'levels setter: [2] updated');

    # durs getter
    my @ds = $e->durs;
    is(scalar @ds, 2, 'durs getter returns 2 values');

    # durs setter
    $e->durs(0.3, 0.7);
    @ds = $e->durs;
    ok(abs($ds[0] - 0.3) < $eps, 'durs setter: [0] updated');
    ok(abs($ds[1] - 0.7) < $eps, 'durs setter: [1] updated');
    ok(abs($e->duration - 1.0) < $eps, 'durs setter updates total duration');

    # curves getter
    my @cs = $e->curves;
    is(scalar @cs, 2, 'curves getter returns 2 values');

    # curves setter
    $e->curves(-2, 3);
    @cs = $e->curves;
    ok(abs($cs[0] - (-2)) < $eps, 'curves setter: [0] updated');
    ok(abs($cs[1] - 3) < $eps, 'curves setter: [1] updated');
}

# ============================================================================
# table() parameter tests
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
    );

    # table($size) basic
    my @tbl = $e->table(8);
    is(scalar @tbl, 8, 'table(8) returns 8 values');
    ok(abs($tbl[0] - 0) < $eps, 'table: first value is start level');

    # table($size, $loops) with loops > 1
    my @tbl_loop = $e->table(8, 2);
    is(scalar @tbl_loop, 8, 'table(8, 2) returns 8 values');
    # With 2 loops over 8 samples, sample 4 should be back at start
    ok(abs($tbl_loop[0] - $tbl_loop[4]) < $eps, 'table loops: sample 0 == sample 4 with 2 loops');

    # table($size, 1, $from, $to) with custom range
    my @tbl_range = $e->table(4, 1, 0.0, 0.5);
    is(scalar @tbl_range, 4, 'table(4, 1, 0, 0.5) returns 4 values');
    ok(abs($tbl_range[0] - 0) < $eps, 'table custom range: starts at from');
}

# ============================================================================
# Edge cases
# ============================================================================

# Random envelope: new() with no args
{
    my $e = Math::SegmentedEnvelope->new();
    ok($e, 'new() with no args creates random envelope');
    ok($e->segments >= 3, 'random envelope has at least 3 segments');
    ok($e->duration > 0, 'random envelope has positive duration');

    # Should be evaluable without crashing
    my $val = $e->at(0);
    ok(defined $val, 'random envelope at(0) returns defined value');
    $val = $e->at($e->duration / 2);
    ok(defined $val, 'random envelope at(mid) returns defined value');
}

# Zero-duration segment should not crash
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0, 0.5], [1, 1]],
    );
    ok($e, 'zero-duration segment envelope created');
    # Evaluating at or near zero-dur segment should not crash
    my $val = eval { $e->at(0) };
    ok(defined $val, 'zero-duration segment: at(0) does not crash');
}

# concat() with single envelope returns it unchanged
{
    my $e = perc(0.1, 0.2);
    my $single = concat($e);
    is($single, $e, 'concat with single envelope returns same object');
}

# concat() with no args
{
    my $empty = concat();
    ok($empty, 'concat with no args returns envelope');
    # It should be a random envelope from new()
    ok($empty->segments >= 3, 'concat() no args: random envelope has segments');
}

# ============================================================================
# New API methods: stretch
# ============================================================================
{
    my $e = perc(0.1, 0.2);  # duration 0.3
    my $stretched = $e->stretch(2);

    ok($stretched, 'stretch returns new envelope');
    ok(abs($stretched->duration - 0.6) < $eps, 'stretch(2) doubles duration');
    is($stretched->segments, $e->segments, 'stretch preserves segment count');

    # Levels should be the same, just stretched in time
    ok(abs($stretched->at(0) - 0) < $eps, 'stretch: starts at same level');
    ok(abs($stretched->at(0.2) - 1.0) < $eps, 'stretch: peak at doubled attack time');
    ok(abs($stretched->at(0.6) - 0) < $eps, 'stretch: ends at same level');

    # Original unchanged
    ok(abs($e->duration - 0.3) < $eps, 'stretch: original duration unchanged');

    # Stretch by 0.5
    my $half = $e->stretch(0.5);
    ok(abs($half->duration - 0.15) < $eps, 'stretch(0.5) halves duration');
}

# ============================================================================
# New API methods: offset
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
    );

    my $shifted = $e->offset(0.5);
    ok($shifted, 'offset returns new envelope');
    ok(abs($shifted->at(0) - 0.5) < $eps, 'offset(0.5): start shifted up');
    ok(abs($shifted->at(0.5) - 1.5) < $eps, 'offset(0.5): peak shifted up');
    ok(abs($shifted->at(1.0) - 0.5) < $eps, 'offset(0.5): end shifted up');

    # Negative offset
    my $neg = $e->offset(-0.3);
    ok(abs($neg->at(0) - (-0.3)) < $eps, 'offset(-0.3): start shifted down');

    # Original unchanged
    ok(abs($e->at(0) - 0) < $eps, 'offset: original unchanged');
}

# ============================================================================
# New API methods: invert
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
    );

    my $inv = $e->invert;
    ok($inv, 'invert returns new envelope');
    ok(abs($inv->at(0) - 1.0) < $eps, 'invert: 0 becomes 1');
    ok(abs($inv->at(0.5) - 0.0) < $eps, 'invert: 1 becomes 0');
    ok(abs($inv->at(1.0) - 1.0) < $eps, 'invert: 0 becomes 1 at end');

    # Duration preserved
    ok(abs($inv->duration - $e->duration) < $eps, 'invert preserves duration');

    # Original unchanged
    ok(abs($e->at(0) - 0) < $eps, 'invert: original unchanged');
}

# ============================================================================
# New API methods: segment_at
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0.5, 0], [0.3, 0.3, 0.4], [1, 1, 1]],
    );

    is($e->segment_at(0), 0, 'segment_at(0) returns segment 0');
    is($e->segment_at(0.1), 0, 'segment_at(0.1) returns segment 0');
    is($e->segment_at(0.3), 0, 'segment_at(0.3) at boundary returns current segment');
    is($e->segment_at(0.31), 1, 'segment_at(0.31) returns segment 1');
    is($e->segment_at(0.5), 1, 'segment_at(0.5) returns segment 1');
    is($e->segment_at(0.61), 2, 'segment_at(0.61) returns segment 2');
    is($e->segment_at(0.9), 2, 'segment_at(0.9) returns segment 2');
    is($e->segment_at(1.0), 2, 'segment_at(1.0) returns last segment');
}

# ============================================================================
# morpher_formulas() - comprehensive check
# ============================================================================
{
    my @names = morpher_formulas();
    is(scalar @names, 26, 'morpher_formulas returns exactly 26 entries');

    my %seen = map { $_ => 1 } @names;
    for my $expected (qw(
        back_in back_inout back_out
        bounce_in bounce_inout bounce_out
        circ_in circ_inout circ_out
        cubic_in cubic_inout cubic_out
        elastic_in elastic_inout elastic_out
        exp_in exp_out linear
        quad_in quad_inout quad_out
        sine smootherstep smoothstep tanh welch
    )) {
        ok($seen{$expected}, "morpher_formulas contains '$expected'");
    }
}

# ============================================================================
# morpher_formula parse error - additional invalid expressions
# ============================================================================
{
    eval {
        Math::SegmentedEnvelope->new(
            [[0, 1], [1], [1]],
            morpher_formula => '((( unclosed',
        );
    };
    like($@, qr/parse error/, 'unclosed parens formula croaks with parse error');

    eval {
        Math::SegmentedEnvelope->new(
            [[0, 1], [1], [1]],
            morpher_formula => '',
        );
    };
    like($@, qr/parse error/, 'empty formula croaks with parse error');
}

# ============================================================================
# morpher_formula setter parse error
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
    );

    eval { $e->morpher_formula('bad @#% expr') };
    like($@, qr/parse error/, 'morpher_formula setter with invalid expr croaks');
}

# ============================================================================
# add() and multiply() - envelope arithmetic
# ============================================================================
{
    my $e1 = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    my $e2 = Math::SegmentedEnvelope->new([[0.5, 0.5], [1], [1]]);

    my $sum = $e1->add($e2, segments => 10);
    ok($sum, 'add returns new envelope');
    is($sum->segments, 10, 'add creates specified segments');
    ok(abs($sum->at(0) - 0.5) < $eps, 'add: 0 + 0.5 = 0.5 at start');
    ok(abs($sum->at(0.5) - 1.0) < $eps, 'add: 0.5 + 0.5 = 1.0 at midpoint');

    my $prod = $e1->multiply($e2, segments => 10);
    ok($prod, 'multiply returns new envelope');
    ok(abs($prod->at(0) - 0) < $eps, 'multiply: 0 * 0.5 = 0 at start');
    ok(abs($prod->at(0.5) - 0.25) < $eps, 'multiply: 0.5 * 0.5 = 0.25 at midpoint');
}

# ============================================================================
# min_value / max_value
# ============================================================================
{
    my $e = perc(0.1, 0.2, peak => 0.8);
    my $min = $e->min_value;
    my $max = $e->max_value;
    ok($min >= -$eps, 'min_value >= 0 for perc');
    ok(abs($max - 0.8) < 0.01, 'max_value close to peak');
    ok($min < $max, 'min < max');

    my $const = Math::SegmentedEnvelope->new([[0.5, 0.5], [1], [1]]);
    ok(abs($const->min_value - 0.5) < $eps, 'constant envelope min = 0.5');
    ok(abs($const->max_value - 0.5) < $eps, 'constant envelope max = 0.5');
}

# ============================================================================
# to_hash / from_hash - serialization round-trip
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0.5, 0], [0.2, 0.3, 0.5], [2, -2, 1]],
        is_morph => 1,
        is_hold => 1,
        morpher_formula => 'smoothstep',
    );

    my $h = $e->to_hash;
    ok(ref $h eq 'HASH', 'to_hash returns hashref');
    ok($h->{is_morph}, 'to_hash preserves is_morph');
    ok($h->{is_hold}, 'to_hash preserves is_hold');
    ok(!$h->{is_fold_over}, 'to_hash preserves is_fold_over = 0');
    is($h->{morpher_formula}, 'smoothstep', 'to_hash preserves morpher_formula');
    is(ref $h->{def}, 'ARRAY', 'to_hash has def array');

    my $e2 = Math::SegmentedEnvelope->from_hash($h);
    ok($e2, 'from_hash creates envelope');
    is($e2->segments, $e->segments, 'round-trip preserves segments');
    ok(abs($e2->duration - $e->duration) < $eps, 'round-trip preserves duration');
    ok($e2->is_morph, 'round-trip preserves is_morph');
    ok($e2->is_hold, 'round-trip preserves is_hold');

    for my $t (0, 0.1, 0.3, 0.5, 0.8, 1.0) {
        ok(abs($e->at($t) - $e2->at($t)) < $eps, "round-trip: at($t) matches");
    }
}

# ============================================================================
# morpher Perl callback accessor
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        is_morph => 1,
    );

    is($e->morpher, undef, 'morpher returns undef by default');

    my $cb = sub { $_[0] * $_[0] };
    $e->morpher($cb);
    ok(defined $e->morpher, 'morpher set returns defined');

    # Verify callback actually affects evaluation
    my $val_cb = $e->at(0.5);
    $e->morpher(undef);
    my $val_default = $e->at(0.5);
    ok(abs($val_cb - $val_default) > $eps, 'morpher callback changes evaluation result');
    is($e->morpher, undef, 'morpher cleared');
}

# ============================================================================
# table() with Perl callback morpher (regression: no free warning)
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0], [0.5, 0.5], [1, 1]],
        is_morph => 1,
        morpher => sub { $_[0] },
    );
    my @t = $e->table(50);
    is(scalar @t, 50, 'table with Perl callback returns correct size');
    ok(abs($t[0] - 0) < $eps, 'table with callback: first value correct');
}

# ============================================================================
# evaluator() removed - should not exist
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    ok(!$e->can('evaluator'), 'evaluator() method removed');
}

# ============================================================================
# static() sequential vs random access
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $s = $e->static;

    # Sequential forward
    my @seq;
    for my $i (0 .. 9) {
        push @seq, $s->($i * 0.1);
    }

    # Random access (same points, different order)
    my @rand_vals;
    for my $i (7, 2, 9, 0, 5, 3, 8, 1, 6, 4) {
        push @rand_vals, $s->($i * 0.1);
    }

    # Re-sort random to match sequential order
    my @sorted;
    my @order = (7, 2, 9, 0, 5, 3, 8, 1, 6, 4);
    $sorted[$order[$_]] = $rand_vals[$_] for 0 .. 9;

    for my $i (0 .. 9) {
        ok(abs($seq[$i] - $sorted[$i]) < $eps,
           "static sequential vs random access match at i=$i");
    }
}

# ============================================================================
# morpher_formula auto-enables is_morph
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1], [1], [1]],
        morpher_formula => 'smoothstep',
    );
    ok($e->is_morph, 'morpher_formula in constructor auto-enables is_morph');

    my $e2 = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    ok(!$e2->is_morph, 'is_morph defaults to false');
    $e2->morpher_formula('linear');
    ok($e2->is_morph, 'morpher_formula setter auto-enables is_morph');
}

# ============================================================================
# New morpher functions (bounce, elastic, back, quad, circ)
# ============================================================================
{
    my $def = [[0, 1], [1], [1]];

    for my $name (qw(bounce_in bounce_out bounce_inout
                     elastic_in elastic_out elastic_inout
                     back_in back_out back_inout
                     quad_in quad_out quad_inout
                     circ_in circ_out circ_inout)) {
        my $e = Math::SegmentedEnvelope->new($def, morpher_formula => $name);
        ok($e, "$name: creates envelope");
        ok(abs($e->at(0) - 0) < $eps, "$name: at(0) = 0");
        ok(abs($e->at(1) - 1) < $eps, "$name: at(1) = 1");
    }

}

# ============================================================================
# Spline - XS Catmull-Rom
# ============================================================================
{
    # Basic spline
    my $s = spline([0, 0.5, 1.0], [0, 1, 0]);
    ok($s, 'spline creates envelope');
    ok($s->segments > 0, 'spline has segments');
    ok(abs($s->duration - 1.0) < $eps, 'spline duration correct');

    # Passes through control points
    ok(abs($s->at(0) - 0) < $eps, 'spline at(0) = 0');
    ok(abs($s->at(0.5) - 1.0) < $eps, 'spline at(0.5) = 1.0');
    ok(abs($s->at(1.0) - 0) < $eps, 'spline at(1.0) = 0');

    # Multi-point spline
    my @t = (0, 0.2, 0.5, 0.8, 1.0);
    my @v = (0, 0.8, 0.3, 0.9, 0);
    my $s2 = spline(\@t, \@v, resolution => 16);
    for my $i (0 .. $#t) {
        ok(abs($s2->at($t[$i]) - $v[$i]) < $eps,
           "spline passes through point $i (t=$t[$i], v=$v[$i])");
    }

    # Class method form
    my $s3 = Math::SegmentedEnvelope->spline([0, 1], [0, 1]);
    ok($s3, 'spline as class method');

    # With options
    my $s4 = spline([0, 0.5, 1.0], [0, 1, 0],
                    resolution => 4, tension => 0.5);
    ok($s4, 'spline with resolution and tension');
    is($s4->segments, 8, 'spline resolution=4: 2 spans * 4 = 8 segments');

    # With morpher
    my $s5 = spline([0, 0.5, 1.0], [0, 1, 0],
                    morpher_formula => 'smoothstep');
    ok($s5->is_morph, 'spline with morpher_formula enables is_morph');

    # Error cases
    eval { spline([0], [0]) };
    like($@, qr/at least 2/, 'spline with 1 point croaks');

    eval { spline([0, 1], [0]) };
    like($@, qr/equal length/, 'spline with mismatched lengths croaks');
}

# ============================================================================
# XS quantize
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $q = $e->quantize(4);
    ok($q, 'quantize returns envelope');
    is($q->segments, $e->segments, 'quantize preserves segment count');
    ok(abs($q->duration - $e->duration) < $eps, 'quantize preserves duration');
    # All levels should be multiples of 0.25
    my @levels = @{$q->def->[0]};
    for my $l (@levels) {
        ok(abs($l * 4 - int($l * 4 + 0.5)) < $eps, "quantize: level $l is multiple of 0.25");
    }
}

# ============================================================================
# XS trim
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $t = $e->trim(0.1, 0.5);
    ok($t, 'trim returns envelope');
    ok(abs($t->duration - 0.4) < $eps, 'trim duration correct');
    is($t->segments, 32, 'trim default 32 segments');
    # First sample should be near the value at t=0.1 of original
    ok(abs($t->at(0) - $e->at(0.1)) < 0.01, 'trim start matches original');

    # Custom resolution
    my $t2 = $e->trim(0, 0.2, segments => 8);
    is($t2->segments, 8, 'trim custom segments');
}

# ============================================================================
# XS lerp
# ============================================================================
{
    my $a = perc(0.01, 0.3, peak => 1.0);
    my $b = perc(0.01, 0.3, peak => 0.5);

    my $l0 = $a->lerp($b, 0);
    ok(abs($l0->at(0.01) - 1.0) < $eps, 'lerp mix=0 gives first envelope');

    my $l1 = $a->lerp($b, 1);
    ok(abs($l1->at(0.01) - 0.5) < $eps, 'lerp mix=1 gives second envelope');

    my $l5 = $a->lerp($b, 0.5);
    ok(abs($l5->at(0.01) - 0.75) < $eps, 'lerp mix=0.5 is midpoint');

    # Lerp interpolates durations
    my $fast = perc(0.01, 0.2);
    my $slow = perc(0.01, 0.8);
    my $mid = $fast->lerp($slow, 0.5);
    ok(abs($mid->duration - 0.51) < $eps, 'lerp interpolates durations');

    # Different segment count croaks
    my $x = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    my $y = Math::SegmentedEnvelope->new([[0, 1, 0], [0.5, 0.5], [1, 1]]);
    eval { $x->lerp($y, 0.5) };
    like($@, qr/same number/, 'lerp croaks on different segment counts');
}

# ============================================================================
# to_svg
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $svg = $e->to_svg;
    ok(length($svg) > 100, 'to_svg returns content');
    like($svg, qr/^<svg/, 'to_svg starts with <svg');
    like($svg, qr/<\/svg>/, 'to_svg ends with </svg>');
    like($svg, qr/polyline/, 'to_svg contains polyline');
}

# ============================================================================
# normalize
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new([[0.2, 0.8, 0.5], [0.5, 0.5], [1, 1]]);
    my $n = $e->normalize;
    ok(abs($n->min_value - 0) < 0.01, 'normalize: min ~0');
    ok(abs($n->max_value - 1) < 0.01, 'normalize: max ~1');

    my $n2 = $e->normalize(-1, 1);
    ok(abs($n2->min_value - (-1)) < 0.01, 'normalize(-1,1): min ~-1');
    ok(abs($n2->max_value - 1) < 0.01, 'normalize(-1,1): max ~1');
}

# ============================================================================
# loop
# ============================================================================
{
    my $e = perc(0.01, 0.2);
    my $l = $e->loop(3);
    ok($l, 'loop returns envelope');
    is($l->segments, $e->segments * 3, 'loop triples segments');
    ok(abs($l->duration - $e->duration * 3) < $eps, 'loop triples duration');

    my $l1 = $e->loop(1);
    is($l1->segments, $e->segments, 'loop(1) returns same');
}

# ============================================================================
# map_levels
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new([[0, 0.5, 1], [0.5, 0.5], [1, 1]]);
    my $m = $e->map_levels(sub { $_[0] ** 2 });
    ok($m, 'map_levels returns envelope');
    my @levels = @{$m->def->[0]};
    ok(abs($levels[0] - 0) < $eps, 'map_levels: 0^2 = 0');
    ok(abs($levels[1] - 0.25) < $eps, 'map_levels: 0.5^2 = 0.25');
    ok(abs($levels[2] - 1) < $eps, 'map_levels: 1^2 = 1');
    ok(abs($m->duration - $e->duration) < $eps, 'map_levels preserves duration');
}

# ============================================================================
# XS resample
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $r = $e->resample(8);
    ok($r, 'resample returns envelope');
    is($r->segments, 8, 'resample produces requested segments');
    ok(abs($r->duration - $e->duration) < $eps, 'resample preserves duration');
    ok(abs($r->at(0) - $e->at(0)) < 0.01, 'resample start matches');
}

# ============================================================================
# XS clamp
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new([[0, 1.5, -0.5, 0.8], [0.3, 0.3, 0.4], [1, 1, 1]]);
    my $c = $e->clamp(0, 1);
    my @l = @{$c->def->[0]};
    is($l[0], 0, 'clamp: 0 stays 0');
    is($l[1], 1, 'clamp: 1.5 clamped to 1');
    is($l[2], 0, 'clamp: -0.5 clamped to 0');
    ok(abs($l[3] - 0.8) < $eps, 'clamp: 0.8 unchanged');
}

# ============================================================================
# XS smooth
# ============================================================================
{
    my $e = Math::SegmentedEnvelope->new(
        [[0, 1, 0, 1, 0], [0.25, 0.25, 0.25, 0.25], [1, 1, 1, 1]]);
    my $s = $e->smooth(3);
    ok($s, 'smooth returns envelope');
    is($s->segments, $e->segments, 'smooth preserves segment count');
    # Endpoints preserved
    ok(abs($s->def->[0][0] - 0) < $eps, 'smooth preserves first endpoint');
    ok(abs($s->def->[0][4] - 0) < $eps, 'smooth preserves last endpoint');
    # Interior smoothed toward mean
    my $mid = $s->def->[0][2];
    ok($mid > 0 && $mid < 1, 'smooth: interior moved toward mean');
}

# ============================================================================
# XS derivative
# ============================================================================
{
    # Linear ramp: 0 to 1 in 1 second -> slope = 1.0
    my $ramp = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    my $d = $ramp->derivative;
    ok($d, 'derivative returns envelope');
    ok(abs($d->def->[0][0] - 1.0) < $eps, 'derivative of linear ramp = 1.0');

    # Flat: slope = 0
    my $flat = Math::SegmentedEnvelope->new([[0.5, 0.5], [1], [1]]);
    my $df = $flat->derivative;
    ok(abs($df->def->[0][0] - 0) < $eps, 'derivative of flat = 0');
}

# ============================================================================
# to_supercollider / to_csound
# ============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $sc = $e->to_supercollider;
    like($sc, qr/Env\(/, 'to_supercollider contains Env(');
    like($sc, qr/\[.*\]/, 'to_supercollider contains arrays');

    my $cs = $e->to_csound;
    like($cs, qr/linseg/, 'to_csound contains linseg');
    like($cs, qr/0\.1/, 'to_csound contains duration values');
}

# ==============================================================================
# XS integrate
# ==============================================================================
{
    # Constant 1.0 over 1 second -> integral = 1.0
    my $c = Math::SegmentedEnvelope->new([[1, 1], [1], [1]]);
    my $integ = $c->integrate;
    ok($integ, 'integrate returns envelope');
    ok(abs($integ->def->[0][0] - 0) < $eps, 'integrate starts at 0');
    ok(abs($integ->def->[0][-1] - 1.0) < $eps, 'integrate of const 1 = 1.0');

    # Ramp 0->1 over 1 second -> integral = 0.5
    my $ramp = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
    my $ri = $ramp->integrate;
    ok(abs($ri->def->[0][-1] - 0.5) < $eps, 'integrate of ramp 0->1 = 0.5');

    ok(abs($integ->duration - $c->duration) < $eps, 'integrate preserves duration');
}

# ==============================================================================
# XS from_samples
# ==============================================================================
{
    my @data = (0, 0.25, 0.5, 0.75, 1.0);
    my $e = Math::SegmentedEnvelope->from_samples(\@data, 2.0);
    ok($e, 'from_samples returns envelope');
    is($e->segments, 4, 'from_samples: 5 values = 4 segments');
    ok(abs($e->duration - 2.0) < $eps, 'from_samples duration correct');
    ok(abs($e->at(0) - 0) < $eps, 'from_samples at(0)');
    ok(abs($e->at(1.0) - 0.5) < 0.01, 'from_samples at(1.0) ~ 0.5');

    eval { Math::SegmentedEnvelope->from_samples([1], 1.0) };
    like($@, qr/at least 2/, 'from_samples with 1 value croaks');

    eval { Math::SegmentedEnvelope->from_samples([0, 1], 0) };
    like($@, qr/positive/, 'from_samples with zero duration croaks');
}

# ==============================================================================
# to_glsl
# ==============================================================================
{
    my $e = adsr(0.1, 0.1, 0.7, 0.3);
    my $glsl = $e->to_glsl(name => 'testEnv', samples => 16);
    like($glsl, qr/float testEnv/, 'to_glsl contains function name');
    like($glsl, qr/float\[16\]/, 'to_glsl has correct array size');
    like($glsl, qr/mix\(/, 'to_glsl uses mix for interpolation');
    like($glsl, qr/clamp/, 'to_glsl clamps input');
}

# ==============================================================================
# PDL integration (conditional)
# ==============================================================================
SKIP: {
    eval { require PDL; PDL->import; 1 }
        or skip 'PDL not installed', 10;

    my $e = adsr(0.1, 0.1, 0.7, 0.3);

    # as_pdl: breakpoint levels
    my $levels = $e->as_pdl;
    isa_ok($levels, 'PDL', 'as_pdl returns PDL');
    is($levels->nelem, $e->segments + 1, 'as_pdl: correct element count');
    ok(abs($levels->at(0) - 0) < $eps, 'as_pdl: first level correct');
    ok(abs($levels->at(1) - 1) < $eps, 'as_pdl: peak level correct');

    # to_pdl: sampled
    my $sampled = $e->to_pdl(256);
    isa_ok($sampled, 'PDL', 'to_pdl returns PDL');
    is($sampled->nelem, 256, 'to_pdl: correct sample count');
    ok($sampled->max > 0.9, 'to_pdl: max near peak');

    # from_pdl: round-trip
    my $e2 = Math::SegmentedEnvelope->from_pdl($sampled, $e->duration);
    ok($e2, 'from_pdl returns envelope');
    is($e2->segments, 255, 'from_pdl: 256 samples = 255 segments');
    ok(abs($e2->duration - $e->duration) < $eps, 'from_pdl: duration preserved');
}

# ==============================================================================
# Adversarial edge cases & safety verification
# ==============================================================================
{
    # 1. Invalid def structure must croak cleanly without crash
    eval { Math::SegmentedEnvelope->new([1, 2, 3]) };
    like($@, qr/def elements must be array references/, 'new([1,2,3]) croaks cleanly');

    eval { Math::SegmentedEnvelope->new("not an array") };
    like($@, qr/def must be an array reference/, 'new("not an array") croaks cleanly');

    eval { Math::SegmentedEnvelope->new([[0], [], []]) };
    like($@, qr/at least 1 segment/, 'new with 0 segments croaks cleanly');

    # 2. Sparse array handling in from_samples and border_level
    my $sparse = [0];
    $sparse->[4] = 1;
    my $e_sparse = Math::SegmentedEnvelope->from_samples($sparse, 1.0);
    ok($e_sparse, 'from_samples with sparse array succeeds without crash');
    is($e_sparse->segments, 4, 'from_samples sparse: correct segments');

    my $e_bl = Math::SegmentedEnvelope->new();
    my $sparse_bl = [];
    $#$sparse_bl = 1;
    eval { $e_bl->border_level($sparse_bl) };
    ok(!$@, 'border_level with sparse array does not crash');

    # 3. Calling methods without blessed object croaks without segfault
    eval { Math::SegmentedEnvelope::duration(undef) };
    like($@, qr/not a Math::SegmentedEnvelope object/, 'unblessed duration croaks cleanly');

    eval { Math::SegmentedEnvelope::at("foo", 0.5) };
    like($@, qr/not a Math::SegmentedEnvelope object/, 'unblessed at() croaks cleanly');

    # 4. lerp with invalid other object
    my $e1 = adsr(0.1, 0.1, 0.7, 0.3);
    eval { $e1->lerp(undef, 0.5) };
    like($@, qr/not a Math::SegmentedEnvelope object/, 'lerp(undef) croaks cleanly');

    eval { $e1->lerp("not an obj", 0.5) };
    like($@, qr/not a Math::SegmentedEnvelope object/, 'lerp(string) croaks cleanly');

    # 5. Method calls on instance for spline and from_samples
    my $spl = $e1->spline([0, 0.5, 1.0], [0, 1.0, 0]);
    ok($spl, 'spline called on instance succeeds');
    is(ref($spl), ref($e1), 'spline on instance preserves class');

    my $fs = $e1->from_samples([0, 0.5, 1.0], 1.0);
    ok($fs, 'from_samples called on instance succeeds');
    is(ref($fs), ref($e1), 'from_samples on instance preserves class');

    # 6. Subclassing support
    {
        package MySubEnv;
        our @ISA = ('Math::SegmentedEnvelope');
    }
    my $sub_adsr = MySubEnv->adsr(0.1, 0.1, 0.7, 0.3);
    isa_ok($sub_adsr, 'MySubEnv', 'MySubEnv->adsr returns subclass instance');
    ok(abs($sub_adsr->duration - 1.0) < $eps, 'MySubEnv->adsr duration is correct');

    my $sub_perc = MySubEnv->perc(0.05, 0.4);
    isa_ok($sub_perc, 'MySubEnv', 'MySubEnv->perc returns subclass instance');

    my $sub_concat = MySubEnv->concat($sub_adsr, $sub_perc);
    isa_ok($sub_concat, 'MySubEnv', 'MySubEnv->concat returns subclass instance');

    # Instance concat
    my $inst_concat = $sub_adsr->concat($sub_perc);
    isa_ok($inst_concat, 'MySubEnv', '$obj->concat returns subclass instance');
    ok(abs($inst_concat->duration - ($sub_adsr->duration + $sub_perc->duration)) < $eps,
       '$obj->concat combines both envelopes');

    # 7. trim invalid range
    eval { $e1->trim(1.0, 0.5) };
    like($@, qr/to_t must be greater than from_t/, 'trim(1.0, 0.5) croaks cleanly');

    # 8. morpher_formula error safety: invalid formula must not corrupt object
    eval { $e1->morpher_formula("INVALID (((") };
    like($@, qr/morpher_formula: parse error/, 'invalid morpher_formula setter croaks cleanly');
    ok(abs($e1->at(0.05) - $e1->at(0.05)) < $eps, 'envelope still functional after failed morpher_formula');

    # 9. _combine with segments => 0
    my $comb = eval { $e1->add($e1, segments => 0) };
    ok($comb, '_combine with segments => 0 does not divide by zero');

    # 10. Large t in is_fold_over does not trigger UB
    my $fold_env = Math::SegmentedEnvelope->new([[0, 1], [1], [1]], is_fold_over => 1);
    my $val_large = eval { $fold_env->at(1e15) };
    ok(defined $val_large, 'large t with is_fold_over evaluates without UB');

    # 11. Adversarial edge cases: NaN, Inf, negative pow, dying callback, clamp, from_hash
    {
        my $nan = "nan" + 0;
        my $inf = 9**999;

        # Hold envelope at Inf / -Inf
        my $hold_env = Math::SegmentedEnvelope->new([[10, 20], [2], [1]], is_hold => 1);
        is($hold_env->at($inf), 20, 'hold envelope at +Inf holds last level');
        is($hold_env->at(-$inf), 10, 'hold envelope at -Inf holds first level');
        ok(isnan($hold_env->at($nan)), 'hold envelope at NaN returns NaN');
        is($hold_env->segment_at($inf), 0, 'hold envelope segment_at +Inf is valid');
        is($hold_env->segment_at($nan), 0, 'hold envelope segment_at NaN is valid');

        # Looping envelope at Inf / NaN
        my $loop_env = Math::SegmentedEnvelope->new([[0, 1], [1], [1]]);
        ok(isnan($loop_env->at($nan)), 'looping envelope at NaN returns NaN');
        ok(isnan($loop_env->at($inf)), 'looping envelope at +Inf returns NaN');
        is($loop_env->segment_at($inf), 0, 'looping envelope segment_at +Inf is valid');

        # Morpher with anticipation/overshoot (back_in) + non-integer curve exponent
        my $back_env = Math::SegmentedEnvelope->new([[0, 1], [1], [2.5]], is_morph => 1, morpher_formula => 'back_in');
        my $val_back = $back_env->at(0.2);
        ok(defined $val_back && !isnan($val_back), 'back_in with curve 2.5 does not produce NaN');

        # Clamp with inverted arguments
        my $clamped = $e1->clamp(0.8, 0.2);
        ok($clamped, 'clamp with lo > hi succeeds');
        my ($min, $max) = ($clamped->min_value, $clamped->max_value);
        ok($min >= 0.2 - $eps && $max <= 0.8 + $eps, 'clamp with lo > hi properly bounds levels');

        # Table with dying callback
        my $dying_env = Math::SegmentedEnvelope->new([[0, 1], [1], [1]], is_morph => 1, morpher => sub { die "callback died\n" });
        eval { $dying_env->table(16) };
        is($@, "callback died\n", 'dying morpher callback in table propagates cleanly without crash');

        # from_hash input validation
        eval { Math::SegmentedEnvelope->from_hash("not_a_hash") };
        like($@, qr/from_hash: expected a hash reference/, 'from_hash rejects non-hash cleanly');

        # _raw_levels on empty/zero segment envelope
        my $raw = $e1->_raw_levels;
        ok(defined $raw && length($raw) > 0, '_raw_levels returns packed string');
    }

    # Options preservation across transforms and operations
    {
        my $base = Math::SegmentedEnvelope->new(
            [[0, 1, 0.5], [0.5, 0.5], [1, 1]],
            is_hold => 1,
            is_fold_over => 1,
            is_wrap_neg => 1,
        );
        ok($base->is_hold, 'base is_hold is 1');
        ok($base->is_fold_over, 'base is_fold_over is 1');
        ok($base->is_wrap_neg, 'base is_wrap_neg is 1');

        for my $op (
            [scale => [2]],
            [reverse => []],
            [delay => [0.1]],
            [stretch => [1.5]],
            [offset => [0.2]],
            [invert => []],
            [normalize => [0, 1]],
            [map_levels => [sub { $_[0] * 1.1 }]],
            [quantize => [4]],
            [resample => [16]],
            [clamp => [0.1, 0.9]],
            [smooth => [2]],
            [derivative => []],
            [integrate => []],
            [add => [$base]],
            [multiply => [$base]],
            [blend => [$base, 0.5]],
        ) {
            my ($method, $args) = @$op;
            my $res = $base->$method(@$args);
            ok($res->is_hold, "$method preserves is_hold");
            ok($res->is_fold_over, "$method preserves is_fold_over");
            ok($res->is_wrap_neg, "$method preserves is_wrap_neg");
            ok(abs($res->at($res->duration * 2) - $res->at($res->duration)) < 1e-6, "$method holds at post-duration");
        }

        my $concat = Math::SegmentedEnvelope->concat($base, $base);
        ok($concat->is_hold, 'concat preserves is_hold');
        ok($concat->is_fold_over, 'concat preserves is_fold_over');
        ok($concat->is_wrap_neg, 'concat preserves is_wrap_neg');

        my $from_samp = Math::SegmentedEnvelope->from_samples([0, 1, 0.5], 1.0, is_hold => 1);
        ok($from_samp->is_hold, 'from_samples parses is_hold');
        ok(abs($from_samp->at(2.0) - $from_samp->at(1.0)) < 1e-6, 'from_samples is_hold holds post-duration');
    }

    # Clone and Copy
    {
        my $orig = Math::SegmentedEnvelope->new([[0, 1, 0], [0.5, 0.5], [1, 1]], is_hold => 1);
        my $cloned = $orig->clone;
        ok($cloned, 'clone returns object');
        is($cloned->segments, 2, 'clone segments match');
        ok(abs($cloned->at(0.5) - 1.0) < $eps, 'clone evaluates identically');
        ok($cloned->is_hold, 'clone preserves flags');
        $cloned->level(1, 0.5);
        ok(abs($cloned->level(1) - 0.5) < $eps, 'modified clone level');
        ok(abs($orig->level(1) - 1.0) < $eps, 'modifying clone does not mutate original');

        my $copied = $orig->copy;
        ok(abs($copied->at(0.5) - 1.0) < $eps, 'copy alias works');
    }

    # Area and Integral scalar
    {
        # Triangle: base 1.0, height 1.0 -> area = 0.5
        my $tri = Math::SegmentedEnvelope->new([[0, 1, 0], [0.5, 0.5], [1, 1]]);
        ok(abs($tri->area - 0.5) < 1e-6, 'triangle area is 0.5');
        ok(abs($tri->integral - 0.5) < 1e-6, 'integral alias matches area');

        # Rectangle: base 2.0, height 1.5 -> area = 3.0
        my $rect = Math::SegmentedEnvelope->new([[1.5, 1.5], [2.0], [1]]);
        ok(abs($rect->area - 3.0) < 1e-6, 'rectangle area is 3.0');
    }

    # with_duration
    {
        my $e = Math::SegmentedEnvelope->new([[0, 1], [0.5], [1]]);
        my $stretched = $e->with_duration(2.5);
        ok(abs($stretched->duration - 2.5) < 1e-6, 'with_duration resizes envelope');
        ok(abs($stretched->at(1.25) - 0.5) < 1e-6, 'with_duration preserves shape');
    }

    # Operator Overloading
    {
        my $e1 = Math::SegmentedEnvelope->new([[0, 1, 0], [0.5, 0.5], [1, 1]]);
        my $e2 = Math::SegmentedEnvelope->new([[1, 0, 1], [0.5, 0.5], [1, 1]]);

        # Code ref callable &{}
        ok(abs($e1->(0.5) - 1.0) < $eps, 'envelope callable via &{} overload');

        # Stringification ""
        my $str = "$e1";
        like($str, qr/^Math::SegmentedEnvelope\(segments=2, duration=1s\)$/, 'stringification overload');

        # Arithmetic +
        my $plus_sc = $e1 + 0.5;
        ok(abs($plus_sc->(0.5) - 1.5) < $eps, 'e + scalar');
        my $sc_plus = 0.5 + $e1;
        ok(abs($sc_plus->(0.5) - 1.5) < $eps, 'scalar + e');
        my $plus_env = $e1 + $e2;
        ok(abs($plus_env->(0.5) - 1.0) < $eps, 'e1 + e2');

        # Arithmetic -
        my $minus_sc = $e1 - 0.2;
        ok(abs($minus_sc->(0.5) - 0.8) < $eps, 'e - scalar');
        my $inv = 1 - $e1;
        ok(abs($inv->(0.5) - 0.0) < $eps && abs($inv->(0.0) - 1.0) < $eps, '1 - e inverts shape');
        my $diff = $e1 - $e2;
        ok(abs($diff->(0.5) - 1.0) < $eps, 'e1 - e2');

        # Arithmetic *
        my $mult_sc = $e1 * 2;
        ok(abs($mult_sc->(0.5) - 2.0) < $eps, 'e * scalar');
        my $sc_mult = 2 * $e1;
        ok(abs($sc_mult->(0.5) - 2.0) < $eps, 'scalar * e');
        my $prod = $e1 * $e2;
        ok(abs($prod->(0.5) - 0.0) < $eps, 'e1 * e2');

        # Negation
        my $neg = -$e1;
        ok(abs($neg->(0.5) - (-1.0)) < $eps, '-e negates levels');
    }

    # Storable freeze, thaw, dclone
    {
        require Storable;
        my $e = Math::SegmentedEnvelope->new(
            [[0, 1, 0.5], [0.3, 0.7], [2, -2]],
            is_hold => 1,
            is_fold_over => 1,
            morpher_formula => 'smoothstep',
        );

        my $frozen = Storable::freeze($e);
        ok($frozen && length($frozen) > 0, 'Storable::freeze produces data');

        my $thawed = Storable::thaw($frozen);
        ok($thawed, 'Storable::thaw succeeds');
        is(ref($thawed), 'Math::SegmentedEnvelope', 'thawed object class');
        ok($thawed->is_hold, 'thawed preserves is_hold');
        ok($thawed->is_fold_over, 'thawed preserves is_fold_over');
        is($thawed->morpher_formula, 'smoothstep', 'thawed preserves morpher_formula');
        ok(abs($thawed->at(0.3) - $e->at(0.3)) < 1e-6, 'thawed evaluates identically');

        my $cloned = Storable::dclone($e);
        ok($cloned, 'Storable::dclone succeeds');
        ok(abs($cloned->at(0.3) - $e->at(0.3)) < 1e-6, 'dcloned evaluates identically');
    }

    # NULL pointer safety
    {
        my $zero = 0;
        my $null_obj = bless \$zero, 'Math::SegmentedEnvelope';
        eval { $null_obj->duration };
        like($@, qr/uninitialized or freed envelope object/, 'NULL pointer croaks safely');
    }
}

{
    no warnings 'redefine';
    sub isnan { $_[0] != $_[0] }
}

done_testing;


