#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/04_overload.t'
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

# Test overload
{
    package Num;
    use Carp;
    use Data::Dumper;

    my $compares = 0;
    use overload 
        ">"  => sub { $compares++; return $_[0][0] > $_[1][0] },
        "eq" => sub { return $_[0][0] eq $_[1][0] },
        '""' => sub { return "Num $_[0][0]" };
    
    
    sub new {
        my ($class, $val) = @_;
        return bless [$val], $class;
    }

    sub compares {
        my $old = $compares;
        $compares = 0;
        return $old;
    }
}

my $heap = Heap::Simple->new(order => ">", elements => [Hash => "foo"]);
my $a = Num->new(4);
my $b = Num->new(8);
$heap->insert({foo => $a});
is(Num->compares, 0);
$heap->insert({foo => $b});
is(Num->compares, 1);
is_deeply([$heap->extract_upto(Num->new(0))], [{foo => $b}, {foo => $a}]);
is(Num->compares, 2);
