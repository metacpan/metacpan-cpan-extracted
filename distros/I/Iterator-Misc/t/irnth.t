use strict;
use Test::More tests => 5, 'no_diag';
use Iterator::Misc;

my ($iter, @vals);

# irand_nth with invalid input
my $countval = 0;
my $count = Iterator->new(sub {$countval++});

eval
{
    $iter = irand_nth(0, $count);
};
ok (Iterator::X::Parameter_Error->caught(), q{Illegal parameter});

# Normal operation
@vals = ();
eval
{
    $iter = irand_nth(5, $count);
    push @vals, $iter->value() for 1..5;
};
is ($@, q{}, q{No error in normal operation});

# There's no way to do an exact test for results, since randomness is involved.
# However, it's highly likely that all numbers returned will be less than, say, 50.
# Also, no two of the same should be returned.
my %seen;
my $dups = 0;
my $range_good = 1;
my $monotonic = 1;
my $first = 1;
my $prev;
for (@vals)
{
    if ($seen{$_}++)
    {
        $dups = 1;
    }
    if ($_ < 0  ||  $_ > 50)
    {
        $range_good = 0;
    }
    if (!$first && $_ <= $prev)
    {
        $monotonic = 0;
    }
    $prev = $_;
    $first = 0;
}

is ($dups, 0, q{No duplicates found});
is ($monotonic, 1, q{Monotinically increasing});
is ($range_good, 1, q{All entries within a reasonable range});
diag ('random nth entries: [', join(', ', @vals) . ']');
