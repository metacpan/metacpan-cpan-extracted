######################################################################
# 03_grouping.pl - GroupBy, ToLookup, GroupJoin
#
# Usage: perl eg/03_grouping.pl
#
# Demonstrates:
#   - GroupBy: group elements by a key selector
#   - ToLookup: build a hash of arrayrefs keyed by a selector
#   - GroupJoin: left outer join with grouped inner sequence
#   - SelectMany: flatten nested sequences
#   - Select, Sum, OrderBy, Distinct, ToArray
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

my @orders = (
    { id => 1, customer => 'Alice', item => 'Book',    price => 1200 },
    { id => 2, customer => 'Bob',   item => 'Pen',     price =>  150 },
    { id => 3, customer => 'Alice', item => 'Notebook', price => 300 },
    { id => 4, customer => 'Carol', item => 'Book',    price => 1200 },
    { id => 5, customer => 'Bob',   item => 'Ruler',   price =>  200 },
    { id => 6, customer => 'Alice', item => 'Pen',     price =>  150 },
);

my @customers = (
    { name => 'Alice', city => 'Tokyo'  },
    { name => 'Bob',   city => 'Osaka'  },
    { name => 'Carol', city => 'Nagoya' },
    { name => 'Dave',  city => 'Kyoto'  },  # no orders
);

######################################################################
# 1. GroupBy: total spending per customer
######################################################################
print "--- 1. Total spending per customer ---\n";
my @groups = LTSV::LINQ->From(\@orders)
    ->GroupBy(sub { $_[0]{customer} })
    ->ToArray();

for my $g (@groups) {
    my $total = LTSV::LINQ->From($g->{Elements})
        ->Sum(sub { $_[0]{price} });
    printf "  %-8s : %d yen\n", $g->{Key}, $total;
}

######################################################################
# 2. ToLookup: items per customer as a hash
######################################################################
print "\n--- 2. Items ordered per customer (ToLookup) ---\n";
my %by_customer = %{ LTSV::LINQ->From(\@orders)
    ->ToLookup(sub { $_[0]{customer} }) };

for my $cust (sort keys %by_customer) {
    my @items = LTSV::LINQ->From($by_customer{$cust})
        ->Select(sub { $_[0]{item} })
        ->ToArray();
    printf "  %-8s : %s\n", $cust, join(", ", @items);
}

######################################################################
# 3. GroupJoin: customers with their orders (left outer join)
######################################################################
print "\n--- 3. Customers with their orders (GroupJoin) ---\n";
my @result = LTSV::LINQ->From(\@customers)
    ->GroupJoin(
        LTSV::LINQ->From(\@orders),
        sub { $_[0]{name} },
        sub { $_[0]{customer} },
        sub {
            my ($cust, $order_group) = @_;
            my @items = $order_group
                ->Select(sub { $_[0]{item} })
                ->ToArray();
            my $item_str = @items ? join(", ", @items) : "(no orders)";
            "$cust->{name} [$cust->{city}]: $item_str";
        }
    )
    ->ToArray();

for my $r (@result) {
    print "  $r\n";
}

######################################################################
# 4. SelectMany: flatten nested items
######################################################################
print "\n--- 4. All unique items (SelectMany + Distinct) ---\n";
my @all_items = LTSV::LINQ->From(\@customers)
    ->SelectMany(
        sub {
            my $cust = $_[0];
            # SelectMany selector must return an ARRAY reference
            [ map  { $_->{item} }
              grep { $_->{customer} eq $cust->{name} } @orders ];
        }
    )
    ->Distinct()
    ->OrderBy(sub { $_[0] })
    ->ToArray();

print "  ", join(", ", @all_items), "\n";
