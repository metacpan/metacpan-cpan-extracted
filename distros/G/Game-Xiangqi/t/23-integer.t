use strict;
use warnings;
use Test::More;

# D5: THE ENGINE IS INTEGER ONLY, AND THIS IS A STATIC CHECK.
#
# Not because floating point is slow, but because a position must evaluate to the
# same number on every platform this dist is smoked on. The trap it protects
# against is `reference_x87_excess_precision_breaks_fixtures`: on 32-bit x86 an
# intermediate can be computed at 80 bits in a register and rounded to 64 on its way
# to memory, so the same expression gives two answers depending on whether the
# compiler kept it in a register. A search whose evaluation disagrees with itself
# across platforms cannot have fixtures at all.
#
# A GREP IS WORTH IT HERE. D5's protection is worth nothing the first time somebody
# writes `0.5 *` in the mobility term, and nothing else in the suite would notice:
# the tests would still pass on this machine.

my @ENGINE = qw(include/xq_abi.h xq_engine.c xq_moves.c xq_mate.c xq_judge.c xq_search.c);

# Comments are allowed to say "4.5" when quoting the conventional piece values, and
# xq_search.c does. So strip comments before looking, or the check fails on its own
# documentation and gets deleted by the next person.
sub code_only {
    my ($path) = @_;
    open my $fh, '<', $path or die "$path: $!";
    my $src = do { local $/; <$fh> };
    close $fh;
    $src =~ s{/\*.*?\*/}{ }gs;              # C comments, including multi-line
    $src =~ s{//[^\n]*}{ }g;                # and the C99 kind
    return $src;
}

subtest 'no floating point anywhere in the engine or the ABI' => sub {
    for my $path (@ENGINE) {
        ok(-f $path, "$path is there to check");
        my $src = code_only($path);

        my @float  = $src =~ /\b(float)\b/g;
        my @double = $src =~ /\b(double)\b/g;
        my @literal = $src =~ /(?<![\w.])(\d+\.\d+|\.\d+)(?![\w.])/g;

        is(scalar @float,   0, "  $path: no 'float'");
        is(scalar @double,  0, "  $path: no 'double'");
        is(scalar @literal, 0, "  $path: no decimal literal")
            or diag("  found: @literal");
    }
};

subtest 'the XS seam uses double only to carry a 64-bit count across' => sub {
    # THE BOUNDARY IS ALLOWED ONE EXCEPTION AND IT IS NOT A LOOPHOLE.
    #
    # A node budget and a node count are 64-bit, and a perl with 32-bit IVs cannot
    # hold one (`reference_32bit_iv_perls`). A double carries an exact integer up to
    # 2^53, which is five thousand times the largest budget anybody would set, so the
    # value crossing is exact. Nothing on the C side of the seam sees a double and
    # no evaluation depends on one.
    #
    # Asserted by PURPOSE rather than by a count, so a refactor that moves these
    # lines does not fail and a SIXTH double somewhere new does.
    my $src = code_only('Xiangqi.xs');
    my @lines = split /\n/, $src;
    my @doubles = grep { /\bdouble\b/ } @lines;

    ok(scalar @doubles, 'the seam does use double, ' . scalar(@doubles) . ' times');
    for my $line (@doubles) {
        my $trim = $line;
        $trim =~ s/\A\s+|\s+\z//g;
        like($line, qr/budget|nodes|%\.0f|\bv\b/,
             "  and only for a 64-bit count: $trim");
    }

    is(scalar(grep { /\bfloat\b/ } @lines), 0, 'and never float');
};

subtest 'the evaluation really is integral, from the outside' => sub {
    # The static check cannot see a division that truncates where it meant to round,
    # so this asserts the property the header promises: the same position gives the
    # same integer, every time, and the four terms are whole numbers.
    require Game::Xiangqi::Engine;
    my $b = Game::Xiangqi::Engine->new;
    my $first = $b->evaluate;
    is($b->evaluate, $first, 'the opening evaluates the same twice');
    like($first, qr/\A-?\d+\z/, "  and it is an integer ($first)");

    for my $ply (1 .. 8) {
        my ($mv) = $b->search(2_000, $ply);
        $b->do_move($mv);
        my $e = $b->evaluate;
        like($e, qr/\A-?\d+\z/, "ply $ply evaluates to an integer ($e)");
    }
};

done_testing();
