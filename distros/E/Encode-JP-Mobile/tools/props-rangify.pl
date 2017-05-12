#!/usr/bin/perl
use strict;
use warnings;
use Number::Rangify qw( rangify );
use YAML;

my($dat, $key) = @ARGV;

my $r = YAML::LoadFile($dat);
my @code;
for my $row (@$r){
    my $hex = $row->{$key || 'unicode'};
    push @code, hex $hex;
}

for my $range (rangify @code) {
    printf "%X\\t%X\n", $range->Size;
}

