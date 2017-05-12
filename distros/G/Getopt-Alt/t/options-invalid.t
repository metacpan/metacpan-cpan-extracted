#!/usr/bin/perl -w

use strict;
use warnings;
use List::Util qw/sum/;
use Test::More;
use Test::Warnings;
use Getopt::Alt::Option;

my @invalid = qw(
    |test
    test=q
    test=q-
    test=i-
    a||b
);

for my $args (@invalid) {
    my $opt;
    eval {
        $opt = Getopt::Alt::Option->new( $args );
    };

    ok( $@ || !$opt, "'$args' should fail" );
    diag Dumper $opt if $opt;
}
done_testing();
