#!/usr/bin/perl
# vim:ft=perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Games::Sudoku::Lite;

my @problems  = glob("t/data/*.problem");
my @solutions = glob("t/data/*.solution");

plan tests => @problems * 2;

for my $i (0..@problems-1)
{
    local $/;
    open F, $problems[$i],  and my $problem  = <F> and close F or die $!;
    open F, $solutions[$i], and my $solution = <F> and close F or die $!;

    my $puzzle = Games::Sudoku::Lite->new($problem, {DEBUG => 0});
       $puzzle->solve;
    is ($puzzle->solution, $solution, "$problems[$i]...problem solved");
    is ($puzzle->validate, '', "$problems[$i]...solution is valid");
}


