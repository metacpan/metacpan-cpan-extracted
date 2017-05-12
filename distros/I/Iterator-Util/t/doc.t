use strict;
use Test::More tests => 33;
use Iterator::Util;

# Check that the documentation examples work.

my @vals;

## From the POD

# $evens (3);
{
    my $evens;

    @vals = ();
    eval
    {
        $evens   = imap { $_ * 2  }  irange (0);  # returns 0, 2, 4, ...
    };
    is ($@, q{}, q{$evens created fine});
    eval
    {
        push @vals, $evens->value  for (1..3);
    };
    is ($@, q{}, q{$evens executed fine});
    is_deeply(\@vals, [0, 2, 4], q{$evens returns what I said it would});
}

# $squares (3)
{
    my $squares;

    @vals = ();
    eval
    {
        $squares = imap { $_ * $_ }  irange (7);  # 49, 64, 81, 100, ...
    };
    is ($@, q{}, q{$squares created fine});
    eval
    {
        push @vals, $squares->value  for (1..4);
    };
    is ($@, q{}, q{$squares created fine});
    is_deeply(\@vals, [49, 64, 81, 100], q{$squares returns what I said it would});
}

# $fives (3)
{
    my $fives;

    @vals = ();
    eval
    {
        $fives = igrep { $_ % 5 == 0 } irange (0,10);   # returns 0, 5, 10
    };
    is ($@, q{}, q{$fives created fine});
    eval
    {
        push @vals, $fives->value  while $fives->isnt_exhausted;
    };
    is ($@, q{}, q{$fives created fine});
    is_deeply(\@vals, [0, 5, 10], q{$fives returns what I said it would});
}

# $small (3)
{
    my $small;

    @vals = ();
    eval
    {
        $small = igrep { $_ < 10 }  irange (8,12);      # returns 8, 9
    };
    is ($@, q{}, q{$small created fine});
    eval
    {
        push @vals, $small->value  while $small->isnt_exhausted;
    };
    is ($@, q{}, q{$small executed fine});
    is_deeply(\@vals, [8, 9], q{$small returns what I said it would});
}

# $iota5 (3)
{
    my $iota5;

    @vals = ();
    eval
    {
        $iota5 = ihead 5, irange 1;      # returns 1, 2, 3, 4, 5.
    };
    is ($@, q{}, q{$iota5 created fine});
    eval
    {
        push @vals, $iota5->value  while $iota5->isnt_exhausted;
    };
    is ($@, q{}, q{$iota5 executed fine});
    is_deeply(\@vals, [1, 2, 3, 4, 5], q{$iota5 returns what I said it would});
}

# ipairwise (3)
{
    my ($first, $second, $third);

    @vals = ();
    eval
    {
        no warnings 'once';
        $first  = irange 1;                              # 1,  2,  3,  4, ...
        $second = irange 4, undef, 2;                    # 4,  6,  8, 10, ...
        $third  = ipairwise {$a * $b} $first, $second;   # 4, 12, 24, 40, ...
    };
    is ($@, q{}, q{1, 2, 3 iterators created fine});
    eval
    {
        push @vals, $third->value for (1..4);
    };
    is ($@, q{}, q{$third executed fine});
    is_deeply(\@vals, [4, 12, 24, 40], q{$ithird returns what I said it would});
}

# $cdr (3)
{
    my ($cdr);

    @vals = ();
    eval
    {
        my $iter = ilist (24, -1, 7, 8);        # Bunch of random values
        $cdr  = iskip 1, $iter;              # "pop" the first value
    };
    is ($@, q{}, q{$cdr iterators created fine});
    eval
    {
        push @vals, $cdr->value while $cdr->isnt_exhausted;
    };
    is ($@, q{}, q{$cdr executed fine});
    is_deeply(\@vals, [-1, 7, 8], q{$cdr returns what I said it would});
}

# skip_until (3)
{
    my $iter;

    @vals = ();
    eval
    {
        $iter = iskip_until {$_ > 5}  irange 1;    # returns 6, 7, 8, 9, ...
    };
    is ($@, q{}, q{$iter iterators created fine});
    eval
    {
        push @vals, $iter->value for (1..4);
    };
    is ($@, q{}, q{$iter executed fine});
    is_deeply(\@vals, [6, 7, 8, 9], q{$iter returns what I said it would});
}

# imesh (3)
{
    my $iter;

    @vals = ();
    eval
    {
        my $i1 = ilist ('a', 'b', 'c');
        my $i2 = ilist (1, 2, 3);
        my $i3 = ilist ('rock', 'paper', 'scissors');
        $iter = imesh ($i1, $i2, $i3);
    };
    is ($@, q{}, q{imesh iterator created fine});
    eval
    {
        # $iter will return, in turn, 'a', 1, 'rock', 'b', 2, 'paper', 'c',...
        push @vals, $iter->value for (1..7);
    };
    is ($@, q{}, q{imesh executed fine});
    is_deeply(\@vals, ['a', 1, 'rock', 'b', 2, 'paper', 'c'], q{imesh returns what I said it would});
}

# izip (3)
{
    my $iter;

    @vals = ();
    eval
    {
        my $i1 = ilist ('a', 'b', 'c');
        my $i2 = ilist (1, 2, 3);
        my $i3 = ilist ('rock', 'paper', 'scissors');
        $iter = izip ($i1, $i2, $i3);
    };
    is ($@, q{}, q{izip iterator created fine});
    eval
    {
        # $iter will return, in turn, 'a', 1, 'rock', 'b', 2, 'paper', 'c',...
        push @vals, $iter->value for (1..7);
    };
    is ($@, q{}, q{izip executed fine});
    is_deeply(\@vals, ['a', 1, 'rock', 'b', 2, 'paper', 'c'], q{izip returns what I said it would});
}

# iuniq (3)
{
    my $uniq;

    @vals = ();
    eval
    {
        my $iter = ilist (1, 2, 2, 3, 1, 4);
        $uniq = iuniq ($iter);            # returns 1, 2, 3, 4.
    };
    is ($@, q{}, q{iuniq iterator created fine});
    eval
    {
        push @vals, $uniq->value while $uniq->isnt_exhausted;
    };
    is ($@, q{}, q{iuniq executed fine});
    is_deeply(\@vals, [1, 2, 3, 4], q{iuniq returns what I said it would});
}
