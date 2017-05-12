#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use List::EvenMoreUtils qw(repeatable_list_shuffler);

my $finished = 0;

END { ok($finished, 'finished') }

my ($timeinfo, @range);

my @list = qw(A B C D E F G H I J K L M N O P);

my $s1 = repeatable_list_shuffler("Abba");
my $s2 = repeatable_list_shuffler("Green Day");

my @l1 = $s1->(@list);
my @l2 = $s1->(@list);
my @l3 = $s2->(@list);

my $good = join('-', sort @list);

is(join('-',sort @l1), $good);
isnt(join('-',@l1),$good);

is(join('-',sort @l2), $good);
isnt(join('-',@l2),$good);

is(join('-',sort @l3), $good);
isnt(join('-',@l3),$good);

isnt(join('-',@l3),join('-',@l1));
isnt(join('-',@l2),join('-',@l1));
isnt(join('-',@l2),join('-',@l3));

$finished = 1;
