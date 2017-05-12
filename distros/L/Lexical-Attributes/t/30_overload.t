#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('LA_Overload');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');


my $obj1 = LA_Overload -> new; isa_ok ($obj1, "LA_Overload");
my $obj2 = LA_Overload -> new; isa_ok ($obj2, "LA_Overload");

$obj1 -> load_me ("red", "blue", "yellow");
$obj2 -> load_me ("green", "brown"); $obj2 -> set_key3 ("purple");

is ("$obj1", "key1 = red; key2 = blue; key3 = yellow", "Overload");
is ("$obj2", "key1 = green; key2 = brown; key3 = purple", "Overload");

__END__
