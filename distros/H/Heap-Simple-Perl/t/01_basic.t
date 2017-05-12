#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/01_basic.t'
# use warnings;	# Remove this for production. Assumes perl 5.6
use strict;

BEGIN { $^W = 1 };
use Test::More "no_plan";
use lib "t";

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

# Same very basic checks
my $heap = Heap::Simple->new;
isa_ok($heap, "Heap::Simple", "We get the type we asked for");
isa_ok($heap, Heap::Simple->implementation, 
       "And it's also of the expected implementor type");
is($heap->count, 0);
my $val = 5;
$heap->insert($val);
$val = 29;
$heap->insert($_) for qw(8 -2 0 0);
is($heap->count, 5);
is($heap->top, -2);
my @order = qw(-2 0 0 5 8);
is_deeply([sort { $a <=> $b } $heap->values], \@order);
is_deeply([sort { $a <=> $b } $heap->keys],   \@order);
is($heap->extract_top, $_) for @order;
is($heap->count, 0);
eval { $heap->extract_top };
ok($@, "extract on empty fails");
eval { $heap->top };
ok($@, "extract on empty fails");
is($heap->max_count, 9**9**9);
is($heap->infinity, 9**9**9);
is($heap->user_data, undef);

# map is interesting because it does a late cleanup
my @in = reverse 1..5;
() = map $heap->insert($_), @in;
is_deeply([map $heap->extract_top, @in], [sort {$a <=> $b } @in]);

$heap = Heap::Simple->new(max_count => 3);
for (1..2) {
    $val = 5;
    $heap->insert($val);
    $val = 29;
    $heap->insert($_) for qw(8 -2 0 0);
    is($heap->count, 3);
    @order = qw(0 5 8);
    is_deeply([sort { $a <=> $b } $heap->values], \@order);
    is_deeply([sort { $a <=> $b } $heap->keys],   \@order);
    is($heap->extract_top, $_) for @order;
    is($heap->count, 0);
}

my $heap1 = Heap::Simple->new(order => "<");
$heap1->insert($_) for qw(5 9);
is_deeply([$heap1->values], [5, 9]);
my $heap2 = Heap::Simple->new(order => ">");
$heap2->insert($_) for qw(3 8 3 0);
is_deeply([$heap2->values], [8, 3, 3, 0]); # heap order has no choice
$heap1->absorb($heap2);
is($heap2->count, 0);
is($heap1->extract_top, $_) for qw(0 3 3 5 8 9);

$heap1 = Heap::Simple->new(order => "<", elements => "Any");
my $val1 = -5;
my $val2 =  5;
$heap1->key_insert($val1, $val2);
$val1 = $val2 = 31;
is_deeply([$heap1->keys],   [-5]);
is_deeply([$heap1->values], [ 5]);
$heap1->key_insert(-9, 9);
is_deeply([$heap1->values], [9, 5]);
$heap2 = Heap::Simple->new(order => ">", elements => "Any");
$heap2->key_insert(-$_, $_) for qw(3 8 3 0);
is_deeply([$heap2->values], [0, 3, 3, 8]); # heap order has no choice
$heap1->key_absorb($heap2);
is($heap2->count, 0);
is($heap1->extract_top, $_) for qw(9 8 5 3 3 0);
