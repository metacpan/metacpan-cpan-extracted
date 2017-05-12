#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 111;

use constant N    =>  5;
use constant KEYS => 14;


BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('Scalar');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');


#
# Check whether methods were created (or not).
#

{
    no strict 'refs';
    for my $k (qw /default pr priv/) {
        ok (!defined &{"Scalar::s_${k}"},     "!defined &Scalar::s_${k}");
        ok (!defined &{"Scalar::set_s_${k}"}, "!defined &Scalar::set_s_${k}");
    }
    for my $k (qw /ro/) {
        ok ( defined &{"Scalar::s_${k}"},     " defined &Scalar::s_${k}");
        ok (!defined &{"Scalar::set_s_${k}"}, "!defined &Scalar::set_s_${k}");
    }
    for my $k (qw /rw/) {
        ok ( defined &{"Scalar::s_${k}"},     " defined &Scalar::s_${k}");
        ok ( defined &{"Scalar::set_s_${k}"}, " defined &Scalar::set_s_${k}");
    }
}
ok (!defined &Scalar::unused,      "!defined &Scalar::unused");
ok (!defined &Scalar::set_unused,  "!defined &Scalar::set_unused");


#
# Can we create objects?
#
my @obj;
for (0 .. N - 1) {
    $obj [$_] = Scalar -> new;
    isa_ok ($obj [$_], "Scalar");
}

for my $i (0 .. N - 2) {
    for my $j ($i + 1 .. N - 1) {
        ok $obj [$i] ne $obj [$j], "Different objects ($i, $j)";
    }
}


#
# Test rw functions.
#

for my $i (0 .. N - 1) {
    $obj [$i] -> set_s_rw ("val-rw $i");
}
for my $i (0 .. N - 1) {
    is ($obj [$i] -> s_rw, "val-rw $i", "s_rw value ($i)");
}


#
# Set ro values by other means.
#
for my $i (0 .. N - 1) {
    $obj [$i] -> my_set_s_ro ("val-ro $i");
}
for my $i (0 .. N - 1) {
    is ($obj [$i] -> s_ro, "val-ro $i", "s_ro value ($i)");
}


#
# Set _pr, _priv and _default values by other means.
#
for my $i (0 .. N - 1) {
    $obj [$i] -> my_set_s_pr      ("val-pr $i");
    $obj [$i] -> my_set_s_priv    ("val-priv $i");
    $obj [$i] -> my_set_s_default ("val-def $i");
}
for my $i (0 .. N - 1) {
    is ($obj [$i] -> my_get_s_pr,      "val-pr $i",     "s_pr value ($i)");
    is ($obj [$i] -> my_get_s_priv,    "val-priv $i", "s_priv value ($i)");
    is ($obj [$i] -> my_get_s_default, "val-def $i",   "s_def value ($i)");
}


#
# has (...) basic functionality.
#

my @coins = qw /euro dollar pound yen franc peso/;

for my $i (0 .. N - 1) {
    $obj [$i] -> set_key_rw1 ("$coins[0]-$i");
    $obj [$i] -> set_key_rw2 ("$coins[1]-$i");
    $obj [$i] -> set_key_rw3 ("$coins[2]-$i");
    $obj [$i] -> set_key_rw4 ("$coins[3]-$i");
    $obj [$i] -> loader (map {+"$_-$i"} @coins);
}
for my $i (0 .. N - 1) {
    is ($obj [$i] -> key_rw1,        "$coins[0]-$i", "get/set key_rw1");
    is ($obj [$i] -> key_rw2,        "$coins[1]-$i", "get/set key_rw2");
    is ($obj [$i] -> key_rw3,        "$coins[2]-$i", "get/set key_rw3");
    is ($obj [$i] -> key_rw4,        "$coins[3]-$i", "get/set key_rw4");
    is ($obj [$i] -> key_ro1,        "$coins[0]-$i", "get/set key_ro1");
    is ($obj [$i] -> key_ro2,        "$coins[1]-$i", "get/set key_ro2");
    is ($obj [$i] -> key_ro3,        "$coins[2]-$i", "get/set key_ro3");
    is ($obj [$i] -> my_get_key_pr1, "$coins[3]-$i", "get/set key_p1");
    is ($obj [$i] -> my_get_key_pr2, "$coins[4]-$i", "get/set key_p2");
    is ($obj [$i] -> my_get_key_pr3, "$coins[5]-$i", "get/set key_p3");
}


#
# How many entries?
#
my @a = Scalar -> give_status;
my @b = (0, (N) x KEYS);
is_deeply (\@a, \@b, "status (0)");


for my $i (0 .. N - 1) {
    undef $obj [$i];
    my @a = Scalar -> give_status;
    my @b = (0, (N - ($i + 1)) x KEYS);
    is_deeply (\@a, \@b, sprintf "status (%d)" => $i + 1);
}
@a = Scalar -> give_status;
@b = (0) x (KEYS + 1);
is_deeply (\@a, \@b, "final status");

__END__
