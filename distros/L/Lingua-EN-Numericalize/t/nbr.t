#!/usr/bin/perl -w

use strict;
use Test;

use Lingua::EN::Numericalize;

our @tests = tests();
plan tests => scalar @tests;

for (@tests) {
	my ($num, $text) = split '\s*=\s*';
	ok(str2nbr($text) == $num) || print STDERR " > $text\n";
    }

sub tests {
    my $f = $0; $f =~ s/\.t$//;
    open(F, "$f.list") || die "$f.list: $!";
    my @ret = grep { chomp; ! /^#/ && ! /^\s*$/ } <F>;
    close F;
    @ret;
    }
