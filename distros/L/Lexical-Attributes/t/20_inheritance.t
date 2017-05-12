#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 26;


BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('LA_Base');
    use_ok ('Lowest');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');

#
# Check whether methods were created (or not).
#
ok ( defined &Super::name,      "Super::name");
ok ( defined &Super::colour,    "Super::colour");
ok (!defined &LA_Base::name,    "LA_Base::name");
ok (!defined &LA_Base::colour,  "LA_Base::colour");
ok ( defined &LA_Base::age,     "LA_Base::age");
ok ( defined &LA_Base::key1,    "LA_Base::key1");
ok ( defined &LA_Base::key2,    "LA_Base::key2");
ok ( defined &Lowest::key1,     "Lowest::key1");
ok ( defined &Lowest::key2,     "Lowest::key2");

my $obj = LA_Base -> new;
my $low = Lowest -> new;
isa_ok ($obj, "LA_Base");
isa_ok ($low, "Lowest");

$obj -> set_name ("fnord");
$obj -> set_colour ("yellow");
$obj -> set_address ("Europe");
$obj -> set_base_name ("womble");
$obj -> set_base_colour ("purple");
$obj -> set_age (25);

is ($obj ->  name,        "fnord",  "->  name");
is ($obj -> {name},       "fnord",  "-> {name}");
is ($obj ->  colour,      "yellow", "->  colour");
is ($obj -> {colour},     "yellow", "-> {colour}");
is ($obj ->  base_name,   "womble", "-> base_name");
is ($obj ->  base_colour, "purple", "-> base_colour");
is ($obj ->  age,          25,      "-> age");
is ($obj ->  address,     "eporuE", "->  address");
is ($obj -> {address},    "Europe", "-> {address}");

$low -> set_key1 ("hello");
$low -> set_key2 ("world");
is ($low -> key1, "hello", "-> key1");
is ($low -> key2, "dlrow", "-> key2");

$low -> my_set_key2 ("earth");
is ($low -> key2, "htrae", "-> key2");


__END__
