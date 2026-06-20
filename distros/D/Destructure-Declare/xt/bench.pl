#!perl
use 5.014;
use strict;
use warnings;
use Benchmark qw(cmpthese);
use Destructure::Declare;

# `let` is parsed once at compile time and lowered to a plain optree - nothing
# of the parser remains at run time. Two lowerings:
#
#   * FAST PATH - a flat array/list pattern (plain scalars, holes, at most a
#     trailing slurpy; no defaults or nesting) becomes a single native
#     list-assignment, `my (...) = @{SRC // []}` (or `my (...) = LIST` for the
#     `( )` form). This is the same aassign hand-written native code uses, so it
#     runs at native speed.
#   * GENERAL PATH - hashes, defaults and nested patterns become a hidden temp
#     plus ordinary `my $x = $tmp->[i]` / `$tmp->{k}` assignments, i.e. the
#     element-by-element code you'd otherwise hand-write.
#
# Each race therefore pits `let` against (a) the element-by-element hand code and
# (b), where one exists, the faster built-in idiom (native list-assignment /
# hash slice). After the fast-path optimisation, flat shapes match the native
# idiom; hash/nested/default shapes match the element-by-element baseline.

# --- array destructure from an arrayref ----------------------------------

print "\n=== array: let [\$a,\$b,\$c] vs element-access vs native list ===\n";

my $aref = [10, 20, 30];

my $hand_arr = sub {                 # what `let` lowers to
    my $r = $_[0];
    my $a = $r->[0];
    my $b = $r->[1];
    my $c = $r->[2];
    $a + $b + $c;
};
my $native_arr = sub {               # idiomatic flat list-assignment
    my ($a, $b, $c) = @{$_[0]};
    $a + $b + $c;
};
my $let_arr = sub {
    let [$a, $b, $c] = $_[0];
    $a + $b + $c;
};

cmpthese(-2, {
    hand_elem  => sub { my $r = $hand_arr->($aref);   1 },
    native_list=> sub { my $r = $native_arr->($aref); 1 },
    let_array  => sub { my $r = $let_arr->($aref);    1 },
});

# --- hash destructure from a hashref -------------------------------------

print "\n=== hash: let {a=>\$a,...} vs element-access vs hash-slice ===\n";

my $href = { a => 1, b => 2, c => 3 };

my $hand_hash = sub {                 # what `let` lowers to
    my $r = $_[0];
    my $a = $r->{a};
    my $b = $r->{b};
    my $c = $r->{c};
    $a + $b + $c;
};
my $slice_hash = sub {               # idiomatic hash slice
    my ($a, $b, $c) = @{$_[0]}{qw/a b c/};
    $a + $b + $c;
};
my $let_hash = sub {
    let {a => $a, b => $b, c => $c} = $_[0];
    $a + $b + $c;
};

cmpthese(-2, {
    hand_elem  => sub { my $r = $hand_hash->($href);  1 },
    hash_slice => sub { my $r = $slice_hash->($href); 1 },
    let_hash   => sub { my $r = $let_hash->($href);   1 },
});

# --- nested destructure --------------------------------------------------

print "\n=== nested: {id=>\$id, pos=>[\$x,\$y]} vs element-access ===\n";

my $rec = { id => 7, pos => [3, 4] };

my $hand_nested = sub {
    my $r  = $_[0];
    my $id = $r->{id};
    my $p  = $r->{pos};
    my $x  = $p->[0];
    my $y  = $p->[1];
    $id + $x + $y;
};
my $let_nested = sub {
    let {id => $id, pos => [$x, $y]} = $_[0];
    $id + $x + $y;
};

cmpthese(-2, {
    hand_elem  => sub { my $r = $hand_nested->($rec); 1 },
    let_nested => sub { my $r = $let_nested->($rec);  1 },
});

# --- slurpy tail (arrayref) ----------------------------------------------

print "\n=== slurpy: let [\$head,\@rest] vs element+slice vs native list ===\n";

my $big = [1 .. 20];

my $hand_slurp = sub {               # what `let` lowers to (head + tail op)
    my $r    = $_[0];
    my $head = $r->[0];
    my @rest = @{$r}[1 .. $#$r];
    $head + @rest;
};
my $native_slurp = sub {             # idiomatic flat list-assignment
    my ($head, @rest) = @{$_[0]};
    $head + @rest;
};
my $let_slurp = sub {
    let [$head, @rest] = $_[0];
    $head + @rest;
};

cmpthese(-2, {
    hand_elem   => sub { my $r = $hand_slurp->($big);   1 },
    native_list => sub { my $r = $native_slurp->($big); 1 },
    let_slurp   => sub { my $r = $let_slurp->($big);    1 },
});

# --- hash %rest (remaining keys) -----------------------------------------

print "\n=== hash %rest: let {id=>\$id,%rest} vs hand copy+delete ===\n";

my $wide = { id => 1, map { ("k$_" => $_) } 1 .. 10 };

my $hand_hrest = sub {
    my %h  = %{ $_[0] };             # copy, then peel off the named key
    my $id = delete $h{id};
    $id + keys %h;
};
my $let_hrest = sub {
    let {id => $id, %rest} = $_[0];
    $id + keys %rest;
};

cmpthese(-2, {
    hand_delete => sub { my $r = $hand_hrest->($wide); 1 },
    let_hrest   => sub { my $r = $let_hrest->($wide);  1 },
});

# --- list form vs native my (...) = LIST ---------------------------------
# `let (...)` snapshots the list into an anon arrayref first, so it carries one
# extra array copy versus native list-assignment. Expect a visible gap; the
# pay-off is defaults / nesting / holes inside the list pattern.

print "\n=== list form: let (\$a,\$b,\@rest) vs native my(...)=LIST ===\n";

my @list = (1 .. 12);

my $native_list = sub {
    my ($a, $b, @rest) = @{$_[0]};
    $a + $b + @rest;
};
my $let_list = sub {
    let ($a, $b, @rest) = @{$_[0]};
    $a + $b + @rest;
};

cmpthese(-2, {
    native_list => sub { my $r = $native_list->(\@list); 1 },
    let_list    => sub { my $r = $let_list->(\@list);    1 },
});

# --- defaults (//) -------------------------------------------------------

print "\n=== defaults: let [\$a,\$b=99] vs // by hand ===\n";

my $short = [5];

my $hand_def = sub {
    my $r = $_[0];
    my $a = $r->[0];
    my $b = $r->[1] // 99;
    $a + $b;
};
my $let_def = sub {
    let [$a, $b = 99] = $_[0];
    $a + $b;
};

cmpthese(-2, {
    hand_elem   => sub { my $r = $hand_def->($short); 1 },
    let_default => sub { my $r = $let_def->($short);  1 },
});

print "\nDone.\n";
