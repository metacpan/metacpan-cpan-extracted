#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 17;


BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('FloorWaxDessertTopping');
}

my @counts;

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');

my $o1 = FloorWaxDessertTopping -> new -> init ('red', 'blue');
my $o2 = FloorWaxDessertTopping -> new -> init ('green', 'orange');

isa_ok ($o1, 'FloorWaxDessertTopping');
isa_ok ($o2, 'FloorWaxDessertTopping');
isa_ok ($o1, 'FloorWax');
isa_ok ($o2, 'FloorWax');
isa_ok ($o1, 'DessertTopping');
isa_ok ($o2, 'DessertTopping');

my $c1 = $o1 -> colour;
my $c2 = $o2 -> colour;

is ($c1, 'red and blue');
is ($c2, 'green and orange');

is (FloorWaxDessertTopping -> count_floor_wax_keys, 2);
is (FloorWaxDessertTopping -> count_dessert_topping_keys, 2);

undef $o2;

is (FloorWaxDessertTopping -> count_floor_wax_keys, 1);
is (FloorWaxDessertTopping -> count_dessert_topping_keys, 1);

undef $o1;

is (FloorWaxDessertTopping -> count_floor_wax_keys, 0);
is (FloorWaxDessertTopping -> count_dessert_topping_keys, 0);

my @dead_colours = FloorWax -> dead_colours;

is_deeply (\@dead_colours, ['green', 'red']);

__END__

my $obj_d1 = Destroy     -> new; isa_ok ($obj_d1, 'Destroy');
my $obj_d2 = Destroy     -> new; isa_ok ($obj_d2, 'Destroy');
my $obj_n1 = NoDestroy   -> new; isa_ok ($obj_n1, 'NoDestroy');
my $obj_n2 = NoDestroy   -> new; isa_ok ($obj_n2, 'NoDestroy');
my $obj_b1 = BusyDestroy -> new; isa_ok ($obj_b1, 'BusyDestroy');
my $obj_b2 = BusyDestroy -> new; isa_ok ($obj_b2, 'BusyDestroy');

is_deeply ([Destroy     -> count_keys], [0, 0, 0], "Count");
is_deeply ([NoDestroy   -> count_keys], [0, 0, 0], "Count");
is_deeply ([BusyDestroy -> count_keys], [0, 0, 0], "Count");

$obj_d1 -> settable_key ("hello, world");
$obj_n1 -> settable_key ("hello, world");
$obj_b1 -> settable_key ("hello, world");

is_deeply ([Destroy     -> count_keys], [0, 0, 1], "Count");
is_deeply ([NoDestroy   -> count_keys], [0, 0, 1], "Count");
is_deeply ([BusyDestroy -> count_keys], [0, 0, 1], "Count");

$obj_d2 -> settable_key ("baz");
$obj_n2 -> settable_key ("baz");
$obj_b2 -> settable_key ("baz");
is_deeply ([Destroy     -> count_keys], [0, 0, 2], "Count");
is_deeply ([NoDestroy   -> count_keys], [0, 0, 2], "Count");
is_deeply ([BusyDestroy -> count_keys], [0, 0, 2], "Count");

{
    my $obj_d3 = Destroy     -> new; isa_ok ($obj_d3, 'Destroy');
    my $obj_n3 = NoDestroy   -> new; isa_ok ($obj_n3, 'NoDestroy');
    my $obj_b3 = BusyDestroy -> new; isa_ok ($obj_b3, 'BusyDestroy');
    is_deeply ([Destroy     -> count_keys], [0, 0, 2], "Count");
    is_deeply ([NoDestroy   -> count_keys], [0, 0, 2], "Count");
    is_deeply ([BusyDestroy -> count_keys], [0, 0, 2], "Count");

    $obj_d3 -> load_me ("foo", "bar");
    $obj_n3 -> load_me ("foo", "bar");
    $obj_b3 -> load_me ("foo", "bar");
    is_deeply ([Destroy     -> count_keys], [1, 1, 2], "Count");
    is_deeply ([NoDestroy   -> count_keys], [1, 1, 2], "Count");
    is_deeply ([BusyDestroy -> count_keys], [1, 1, 2], "Count");

    $obj_d3 -> settable_key ("quux");
    $obj_n3 -> settable_key ("quux");
    $obj_b3 -> settable_key ("quux");
    is_deeply ([Destroy     -> count_keys], [1, 1, 3], "Count");
    is_deeply ([NoDestroy   -> count_keys], [1, 1, 3], "Count");
    is_deeply ([BusyDestroy -> count_keys], [1, 1, 3], "Count");

    $obj_d2 -> load_me ("hello");
    $obj_n2 -> load_me ("hello");
    $obj_b2 -> load_me ("hello");
    is_deeply ([Destroy     -> count_keys], [1, 2, 3], "Count");
    is_deeply ([NoDestroy   -> count_keys], [1, 2, 3], "Count");
    is_deeply ([BusyDestroy -> count_keys], [1, 2, 3], "Count");
}

is_deeply ([Destroy     -> count_keys], [0, 1, 2], "Count");
is_deeply ([NoDestroy   -> count_keys], [0, 1, 2], "Count");
is_deeply ([BusyDestroy -> count_keys], [0, 1, 2], "Count");

__END__
