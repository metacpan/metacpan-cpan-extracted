use strict;
use warnings;
use Test::More;

use Mail::DKIM2::MessageInstance;

# The capped Myers body diff (docs/superpowers/specs/
# 2026-10-09-capped-myers-body-diff-design.md). _body_diff(\@cur, \@prev,
# $max_literals) returns undef when the bodies are identical, the string
# 'too_big' when the recipe would need more than $max_literals literal lines
# (or the work budget ran out), else the Recipe arrayref.

*diff  = \&Mail::DKIM2::MessageInstance::_body_diff;
*apply = \&Mail::DKIM2::MessageInstance::_apply_recipe;

sub literals { scalar grep { !ref } @{ $_[0] } }

sub roundtrip {
    my ($name, $cur, $prev, $max) = @_;
    my $r = diff($cur, $prev, $max // 1000);
    ok(ref $r eq 'ARRAY', "$name: got a recipe") or return;
    is_deeply([apply('body', $r, $cur)], $prev, "$name: recipe rebuilds prev");
    return $r;
}

is(diff([qw(a b c)], [qw(a b c)], 1000), undef, 'identical bodies: no recipe');

is_deeply(diff([qw(x a b c)], [qw(a b c)], 1000), [[2, 4]],
    'line added at the top: one copy');
is_deeply(diff([qw(a b c)], [qw(a b c d)], 1000), [[1, 3], 'd'],
    'line removed at the end: copy + literal');
is_deeply(diff([qw(a B c)], [qw(a b c)], 1000), [[1, 1], 'b', [3, 3]],
    'changed middle line');
is_deeply(diff([], [qw(a b)], 1000), [qw(a b)], 'empty current body');
is_deeply(diff([qw(a b)], [], 1000), [], 'empty previous body');

# N lines removed from the front of prev, M different lines added: it must
# resynchronise on the identical tail, and only the N removed lines are
# literals.
{
    my @tail = map { "tail $_" } 1 .. 500;
    my @prev = ((map { "old $_" } 1 .. 40), @tail);
    my @cur  = ((map { "new $_" } 1 .. 70), @tail);
    $cur[300] = 'edited';    # a second change so trimming alone can't do it
    my $r = roundtrip('front replaced + mid edit', \@cur, \@prev);
    is(literals($r), 41, 'front replaced: 40 old lines + 1 edited line');
}

# Repeated lines shared by both sides: still minimal.
{
    my @prev = map { $_ % 3 ? '' : "p$_" } 1 .. 300;
    my @cur  = map { $_ % 3 ? '' : "c$_" } 1 .. 300;
    my $r = roundtrip('blank-heavy', \@cur, \@prev);
    is(literals($r), 100, 'blank-heavy: only the non-blank lines are literal');
}

# The literal cap is exact.
{
    my @cur  = map { "c$_" } 1 .. 10;
    my @prev = ((map { "p$_" } 1 .. 1000), @cur);
    my $r = roundtrip('exactly 1000 literals', \@cur, \@prev);
    is(literals($r), 1000, '1000 literals allowed');
    push @prev, 'one more';
    is(diff(\@cur, \@prev, 1000), 'too_big', '1001 literals: too_big');
    is(diff([qw(a b c)], [qw(a x y z c)], 2), 'too_big', 'small cap honoured');
    roundtrip('cap of 3', [qw(a b c)], [qw(a x y z c)], 3);
}

# The review's R2 probe: a,b,a,b... vs b,a,b,a... was 3.7s at 4000 lines.
{
    my $n = 4000;
    my @cur  = (('a', 'b') x ($n / 2));
    my @prev = (('b', 'a') x ($n / 2));
    my $r = roundtrip('alternating', \@cur, \@prev);
    cmp_ok(literals($r), '<=', 1, 'alternating: at most one literal');
}

# Two edits far apart in a big body.
{
    my @prev = map { "line $_" } 1 .. 100_000;
    my @cur  = @prev;
    $cur[10] = 'changed top';
    $cur[99_990] = 'changed bottom';
    my $r = roundtrip('100k lines, two edits', \@cur, \@prev);
    is(literals($r), 2, '100k lines: two literals');
}

# A huge one-sided insert between two edits: the inserted lines never occur
# in prev, so they are discarded before the search.
{
    my @prev = map { "line $_" } 1 .. 200;
    my @cur  = @prev;
    $cur[5] = 'edit one';
    splice @cur, 100, 0, map { "inserted $_" } 1 .. 50_000;
    $cur[-5] = 'edit two';
    my $r = roundtrip('huge insert', \@cur, \@prev);
    is(literals($r), 2, 'huge insert: two literals');
}

# Lines common to both sides that cannot be discarded, in an order Myers
# must explore deeply: the work budget gives up rather than spinning.
{
    my @cur  = map { $_ % 2 ? 'x' : 'y' } 1 .. 60_000;
    my @prev = ((map { $_ % 3 ? 'y' : 'x' } 1 .. 60_000));
    my $r = diff(\@cur, \@prev, 1000);
    is($r, 'too_big', 'more y lines in prev than cur: too_big');
}
{
    # Same line counts on both sides, so only the search itself can tell
    # the recipe would be 30000 literals.
    my @cur  = (('x') x 30_000, ('y') x 30_000);
    my @prev = (('y') x 30_000, ('x') x 30_000);
    my $r = diff(\@cur, \@prev, 1000);
    is($r, 'too_big', 'deep search: too_big');
}

# Deterministic tie-breaking (shared with the other implementations).
is_deeply(diff([qw(a b)], [qw(b a)], 1000), [[2, 2], 'a'],
    'swap: tie-break skips the current line first');

# calculate(): over the cap, the default (header-only) path declares the
# body unrecoverable; EpilogueThreshold stores it in the epilogue.
{
    my $old  = join '', map { "old line $_\r\n" } 1 .. 1200;
    my $prev = "From: a\@example.com\r\nSubject: hi\r\n\r\n$old";
    my $m1 = Mail::DKIM2::MessageInstance->calculate($prev);
    my $mi1 = "Message-Instance: " . $m1->as_string . "\r\n";
    $prev = $mi1 . $prev;
    my $small = $mi1 . "From: a\@example.com\r\nSubject: hi\r\n\r\n"
        . join('', map { "old line $_\r\n" } 201 .. 1200);
    my $big   = $mi1 . "From: a\@example.com\r\nSubject: hi\r\n\r\nreplaced\r\n";

    my $mi = Mail::DKIM2::MessageInstance->calculate($small, $prev);
    my $p = Mail::DKIM2::MessageInstance->parse($mi->as_string);
    ok(!$p->unrecoverable, '200 literals: a diff recipe');
    is(scalar(grep { !ref } @{ $p->{bits}{rb} }), 200, '200 literal lines');
    my ($ok, $err) = Mail::DKIM2::MessageInstance->chain_verifies(
        "Message-Instance: " . $mi->as_string . "\r\n" . $small);
    ok($ok, '200 literals: chain verifies') or diag $err;

    $mi = Mail::DKIM2::MessageInstance->calculate($big, $prev);
    ok(Mail::DKIM2::MessageInstance->parse($mi->as_string)->unrecoverable,
        '1200 literals, default: null body recipe');

    my $msg = Mail::DKIM2::Common::parse_mime($small);
    $mi = Mail::DKIM2::MessageInstance->calculate($msg, $prev,
        EpilogueThreshold => 100);
    $p = Mail::DKIM2::MessageInstance->parse($mi->as_string);
    is(scalar(@{ $p->{bits}{rb} }), 1, 'over EpilogueThreshold: one epilogue copy');
    ($ok, $err) = Mail::DKIM2::MessageInstance->chain_verifies(
        "Message-Instance: " . $mi->as_string . "\r\n" . $msg->as_string);
    ok($ok, 'epilogue chain verifies') or diag $err;

    # MaxRecipeLiterals moves the default path's cap either way.
    $mi = Mail::DKIM2::MessageInstance->calculate($small, $prev,
        MaxRecipeLiterals => 100);
    ok(Mail::DKIM2::MessageInstance->parse($mi->as_string)->unrecoverable,
        'MaxRecipeLiterals 100, 200 literals: null');
    my $big_old = $mi1 . "From: a\@example.com\r\nSubject: hi\r\n\r\nkept\r\n";
    $mi = Mail::DKIM2::MessageInstance->calculate($big_old, $prev,
        MaxRecipeLiterals => 2000);
    $p = Mail::DKIM2::MessageInstance->parse($mi->as_string);
    is(scalar(grep { !ref } @{ $p->{bits}{rb} }), 1200,
        'MaxRecipeLiterals 2000, 1200 literals: a diff recipe');

    # EpilogueThreshold is the cap on the epilogue path, as given.
    $msg = Mail::DKIM2::Common::parse_mime($big_old);
    $mi = Mail::DKIM2::MessageInstance->calculate($msg, $prev,
        EpilogueThreshold => 2000);
    $p = Mail::DKIM2::MessageInstance->parse($mi->as_string);
    is(scalar(grep { !ref } @{ $p->{bits}{rb} }), 1200,
        'EpilogueThreshold 2000, 1200 literals: a diff recipe');

    for my $bad (-1, 'x', undef) {
        eval { Mail::DKIM2::MessageInstance->calculate($small, $prev,
            MaxRecipeLiterals => $bad) };
        like($@, qr/MaxRecipeLiterals/, 'MaxRecipeLiterals '
            . ($bad // 'undef') . ' croaks');
    }
    eval { Mail::DKIM2::MessageInstance->calculate($small, $prev,
        MaxRecipeLiterals => 10, EpilogueThreshold => 10) };
    like($@, qr/MaxRecipeLiterals.*EpilogueThreshold|EpilogueThreshold.*MaxRecipeLiterals/,
        'MaxRecipeLiterals with EpilogueThreshold croaks');
}

done_testing;
