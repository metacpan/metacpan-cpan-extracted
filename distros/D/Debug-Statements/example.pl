#!/usr/bin/perl
##!/home/utils/perl-5.8.8/bin/perl
##!/home/utils/perl-5.8.6/bin/perl
##!/home/utils/perl-5.20/5.20.1-006/bin/perl
use warnings;
use strict;

#use lib '/home/ate/scripts/regression/';
use lib 'lib';
use Debug::Statements qw(d d0 d1 d2 d3 D ls);

my $myvar = 'some value';
my @list = ('zero', 1, 'two', "3");
my %hash = ('one' => 2, 'three' => 4);
my @nestedlist = ( [ 0, 1 ], [ 2, 3 ] );
my %nestedhash = (
    flintstones => {
        husband => "fred",
        pal     => "barney",
    },
);

# d0 and D are the same function.  They always print, regardless of $d
d0 '$myvar';
D '$myvar';

my $d = 1;

# These print because $d >= 1
d "Hello world";
d '$myvar';
d '@list %hash @nestedlist %nestedhash';

d2 '$myvar'; # does not print because $d < 2
$d = 2;
d2 '$myvar'; # prints


# Prints ls -l of file or directory
ls($0);
ls('.');

