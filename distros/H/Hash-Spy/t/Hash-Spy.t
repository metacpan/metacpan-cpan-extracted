#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 65;

use Hash::Spy qw(spy_hash);

sub rand_str { join '', map chr(ord('a') + int rand 26), 0..4 + rand 7 }
my %master = map { rand_str() => int rand 100000 } 0..1000;

my ($store, $clear, $delete, $empty);

my %h0 = %master;
my %control = %master;
is_deeply(\%h0, \%master, "is_deeply works for hashes");
spy_hash %h0, store => sub { $store++ };
is_deeply(\%h0, \%master, "is_deeply works for hashes");

for (0..25) {
    my $key = rand_str();
    my $value = int rand 100000;

    $h0{$key} = $value;
    $control{$key} = $value;
    is_deeply(\%h0, \%control, "STORE - $_");
    is($store, 1 + $_, "store cb - $_");
}

my %h1 = %h0;
is_deeply(\%h1, \%control, "FETCH all");

spy_hash(%h0, delete => sub { $delete++ }, empty => sub { $empty++});
spy_hash(%h1, empty  => sub { $empty++  });
spy_hash(%h1, clear  => sub { $clear++  });

my $size = keys %control;
is (scalar(keys %h0), $size, "scalar keys");
is (scalar(keys %h1), $size, "scalar keys");

my $ok = 1;

while (my ($k) = each %h1) {
    my $v0 = delete $h0{$k};
    my $v1 = delete $h1{$k};
    my $v  = delete $control{$k};

    unless ($v0 == $v1 and $v1 == $v) {
        $ok = 0;
        last;
    }
}

ok($ok, "iterate over keys and delete");

is ($delete, $size, "delete cb");
is ($empty, 2, "empty cb");
is ($clear, undef, "clear cb");

delete $h0{FOO};

is ($delete, $size, "delete may be a nop");
is ($empty, 2, "call empty callaback once");

$store = 0;
$empty = 0;

spy_hash(%h0, store => undef);
spy_hash(%h1, store => sub { $store ++ });

%h0 = %master;
%h1 = %master;
%control = %master;

is ($clear, undef, "clear is a nop when the hash was empty");
is ($store, scalar(keys %control), "store cb 2");
