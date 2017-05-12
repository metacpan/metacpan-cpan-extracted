#!/usr/bin/perl

use strict;
use warnings;

use Math::Int64 qw(uint64 int64);

package Thing;

sub new {
    my ($class, $n) = @_;
    my $self = { n => $n };
    bless $self, $class;
}

sub as_int64 {
    my $self = shift;
    $self->{n} * 2;
}

sub as_uint64 {
    my $self = shift;
    $self->{n} * 3;
}

package main;



use Test::More 0.88;

my $t = Thing->new(4);

my $u = uint64(2);
my $i = int64(2);

ok($u * $t == 24);
ok($i * $t == 16);

$t = Thing->new($u);

ok($u * $t == 12);
ok($i * $t == 8);

done_testing();
