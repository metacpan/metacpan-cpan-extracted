######################################################################
#
# 04_sorting.pl - Sorting examples
#
# Demonstrates:
#   - OrderBy: ascending smart sort
#   - OrderByDescending: descending smart sort
#   - OrderByStr: string sort
#   - OrderByNum: numeric sort
#   - ThenBy: secondary key ascending
#   - ThenByNumDescending: secondary key numeric descending
#   - Reverse: reverse order
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;

print "=== Sorting Examples ===\n\n";

my @products = (
    {name => 'Widget',     category => 'Tools',       price => 9.99,  stock => 100},
    {name => 'Gadget',     category => 'Electronics', price => 99.0,  stock => 25},
    {name => 'Doohickey',  category => 'Tools',       price => 4.99,  stock => 200},
    {name => 'Thingamajig',category => 'Misc',        price => 19.99, stock => 50},
    {name => 'Gizmo',      category => 'Electronics', price => 49.5,  stock => 75},
    {name => 'Doodad',     category => 'Misc',        price => 2.99,  stock => 500},
);

# --- OrderBy (smart): ascending by price ---
print "[ Ordered by price ascending (smart) ]\n";
my @by_price = JSON::LINQ->From(\@products)
    ->OrderBy(sub { $_[0]{price} })
    ->ToArray();
for my $p (@by_price) {
    printf "  %-20s  \$%.2f\n", $p->{name}, $p->{price};
}

# --- OrderByDescending: top 3 by price ---
print "\n[ Top 3 by price descending (OrderByDescending) ]\n";
my @top3 = JSON::LINQ->From(\@products)
    ->OrderByDescending(sub { $_[0]{price} })
    ->Take(3)
    ->ToArray();
for my $p (@top3) {
    printf "  %-20s  \$%.2f\n", $p->{name}, $p->{price};
}

# --- ThenBy: category asc, then name asc ---
print "\n[ By category asc, then name asc (OrderByStr + ThenBy) ]\n";
my @multi = JSON::LINQ->From(\@products)
    ->OrderByStr(sub { $_[0]{category} })
    ->ThenBy(sub { $_[0]{name} })
    ->ToArray();
for my $p (@multi) {
    printf "  %-15s  %-20s  \$%.2f\n", $p->{category}, $p->{name}, $p->{price};
}

# --- ThenByNumDescending: category asc, then stock desc ---
print "\n[ By category asc, then stock desc (ThenByNumDescending) ]\n";
my @multi2 = JSON::LINQ->From(\@products)
    ->OrderByStr(sub { $_[0]{category} })
    ->ThenByNumDescending(sub { $_[0]{stock} })
    ->ToArray();
for my $p (@multi2) {
    printf "  %-15s  %-20s  stock=%d\n", $p->{category}, $p->{name}, $p->{stock};
}

# --- OrderByStr vs OrderByNum on version strings ---
print "\n[ OrderByStr vs OrderByNum on version-like strings ]\n";
my @versions = ('1.10', '1.9', '1.2', '1.20');
my @str_sorted = JSON::LINQ->From(\@versions)->OrderByStr(sub { $_[0] })->ToArray();
my @num_sorted = JSON::LINQ->From(\@versions)->OrderByNum(sub { $_[0] })->ToArray();
print "  OrderByStr: ", join(', ', @str_sorted), "\n";
print "  OrderByNum: ", join(', ', @num_sorted), "\n";

# --- Reverse ---
print "\n[ Reverse ]\n";
my @rev = JSON::LINQ->From(\@products)
    ->OrderByStr(sub { $_[0]{name} })
    ->Reverse()
    ->Select(sub { $_[0]{name} })
    ->ToArray();
print "  ", join(', ', @rev), "\n";

print "\nDone.\n";
