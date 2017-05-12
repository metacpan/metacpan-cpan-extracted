#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/03_magic.t'
# use warnings;	# Remove this for production. Assumes perl 5.6
use strict;

BEGIN { $^W = 1 };
use Test::More "no_plan";
use lib "t";
use Ties;

my $wanted_implementor;
BEGIN {
    $wanted_implementor = "Perl";
    @Heap::Simple::implementors = ("Heap::Simple::$wanted_implementor") unless
        @Heap::Simple::implementors;
    use_ok("Heap::Simple");
};
my $class = Heap::Simple->implementation;
if ($class ne "Heap::Simple::$wanted_implementor") {
    diag("Was supposed to test Heap::Simple::$wanted_implementor but loaded $class");
    fail("Wrong heap library got loaded");
    exit 1;
}

# Magic access on new
my ($heap, $val, $scalar, @array, @elements, %hash, $fun);
tie @elements, "Atie", Hash => "foo";
tie(@array, "Atie", "Heap::Simple",
    order     => ">",
    elements  => \@elements,
    infinity  => 3,
    user_data => 4,
    dirty     => 0,
    can_die   => 1,
    max_count => 12);
$fun = Heap::Simple->can("new") || die "new is not implemented for Heap::Simple";
Atie->fetches;
$heap = $fun->(@array);
if ($class eq "Heap::Simple::Perl") {
    is(Atie->fetches, 15+3+2,
       "1 fetch for the class, 14 fetches for the options, 2 fetches for the elements plus 3 extra because we didn't make a copy");
} else {
    is(Atie->fetches, 15+2,
       "1 fetch for the class, 14 fetches for the options, 2 fetches for the elements");
}
is($heap->order, ">", "Magic options access");
is_deeply([$heap->elements], [Hash => "foo"], "Deep magic options access");
is($heap->infinity,  3);
is($heap->user_data, 4);

# Magic access on user_data
$fun = $heap->can("user_data") || 
    die "user_data is not implemented for Heap::Simple";
tie @array, "Atie", $heap, \@elements;
Atie->fetches;
$fun->(@array);
is(Atie->fetches, 2);
is_deeply($heap->user_data, [Hash => "foo"]);
tie $scalar, "Stie", 5;
Stie->fetches;
$heap->user_data($scalar);
is(Stie->fetches, 1);
is($heap->user_data, 5);
is(Stie->fetches, 0);
tie @array, "Atie", 6;
Atie->fetches;
$heap->user_data(@array);
is(Atie->fetches, 1);
is($heap->user_data, 6);
is(Atie->fetches, 0);

# Magic access on infinity
$fun = $heap->can("infinity") || 
    die "infinity is not implemented for Heap::Simple";
tie @array, "Atie", $heap, \@elements;
Atie->fetches;
$fun->(@array);
is(Atie->fetches, 2);
is_deeply($heap->infinity, [Hash => "foo"]);
tie $scalar, "Stie", 8;
Stie->fetches;
$heap->infinity($scalar);
is(Stie->fetches, 1);
is($heap->infinity, 8);
is(Stie->fetches, 0);
tie @array, "Atie", 7;
Atie->fetches;
$heap->infinity(@array);
is(Atie->fetches, 1);
is($heap->infinity, 7);
is(Atie->fetches, 0);

# Magic access on insert
$fun = $heap->can("insert") || die "insert is not implemented for Heap::Simple";
tie %hash, "Htie", foo => "bar";
tie @array, "Atie", $heap, \%hash;
Atie->fetches;
Htie->fetches;
$fun->(@array);
is(Atie->fetches, $class eq "Heap::Simple::Perl" ? 3 : 2);
if ($class eq "Heap::Simple::Perl") {
    is(Htie->fetches, 1, "Access the key even for empty insert");
    for ($heap->top_key) {
        is(Htie->fetches, 1, "Immediately activate magic");
        is($_, "bar");
        is(Htie->fetches, 0, "No double activation");
    }
} else {
    is(Htie->fetches, 0);
    for ($heap->top_key) {
        # Magic not activated yet !
        is(Htie->fetches, 0);
        is($_, "bar");
        is(Htie->fetches, 1);
    }
}
$val = $heap->extract_top;
is(Htie->fetches, 0);
is_deeply($val, {foo => "bar" });
ok(Htie->fetches);
is(Atie->fetches, 0);
# No access needed for extract_upto on an empty heap
$heap->extract_upto(\@array);
is(Atie->fetches, 0);
is(Htie->fetches, 0);

tie %hash, "Htie", foo => "8";
is(Htie->fetches, 0);
$heap->insert(\%hash);
if ($class eq "Heap::Simple::Perl") {
    is(Htie->fetches, 1, "Key fetch even on empty heap");
} else {
    is(Htie->fetches, 0, "Optimize away the key fetch for an empty heap");
}
$heap->insert(\%hash);
# Two fetches, one compare
is(Htie->fetches, 2);
is($heap->count, 2);
$heap->extract_top;
# No fetches needed
is(Htie->fetches, 0);
$heap->insert(\%hash);
is(Htie->fetches, 2);
$heap->insert(\%hash);
is(Htie->fetches, 2);
$heap->extract_top;
is(Htie->fetches, 2);
$fun = $heap->can("extract_upto") || 
    die "extract_upto is not implemented for Heap::Simple";
tie @array, "Atie", $heap, 8;
$fun->(@array);
is(Atie->fetches, 2);
is(Htie->fetches, 2);

$heap = Heap::Simple->new(order => ">", elements => "Any");
$fun = $heap->can("key_insert") || 
    die "key_insert is not implemented for $heap";
tie %hash, "Htie", foo => "bar";
tie @array, "Atie", $heap, 8, \%hash;
Atie->fetches;
Htie->fetches;
$fun->(@array);
is(Atie->fetches, 3);
is(Htie->fetches, 0);

tie @elements, "Atie", 8, \%hash;
tie @array, "Atie", $heap, \@elements;
$fun = $heap->can("_key_insert") || 
    die "_key_insert is not implemented for $heap";
$fun->(@array);
is(Atie->fetches, 4);
is(Htie->fetches, 0);
