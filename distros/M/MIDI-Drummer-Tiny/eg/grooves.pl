#!/usr/bin/perl
use strict;
use warnings;

# use Data::Dumper::Compact 'ddc';
use MIDI::Drummer::Tiny ();
use MIDI::Drummer::Tiny::Grooves ();

my $cat  = shift // 'house';
my $name = shift // 'deep';

my $d = MIDI::Drummer::Tiny->new(
    kick  => 36,
    snare => 40,
);
my $grooves = MIDI::Drummer::Tiny::Grooves->new(drummer => $d);

my $set = {};
# $set = $grooves->all_grooves;
# $set = $grooves->search($set, { cat => $cat, name => $name }); # boolean OR
$set = $grooves->search({ cat => $cat }) if $cat;    # boolean AND
$set = $grooves->search({ name => $name }, $set) if $name; # "

for my $n (sort keys %$set) {
    my $groove = $set->{$n};
    print $groove->{name}, "\n";
    $groove->{groove}->() for 1 .. 4;
}

$d->write;