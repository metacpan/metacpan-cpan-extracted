#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(:all);
use List::Search qw( list_contains );
use Perl6::Slurp;
use List::Util qw( shuffle );

my $dict_file = '/usr/share/dict/words';

my @array = sort slurp $dict_file;
my %hash  = map { $_ => 1 } @array;

my @words = shuffle @array;

cmpthese(
    -3,
    {
        'hash' => sub { exists $hash{$_} for @words; },
        'list_contains' => sub { list_contains( $_, \@array ) for @words; },
    }
);
