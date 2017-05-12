#!/usr/bin/perl 

use strict;
use warnings;
use Cwd; use File::Basename;

use Grades;

my $script = Grades::Script->new_with_options;
my $id = $script->league || basename( getcwd );
my $exercise = $script->exercise;
my $two = $script->two;
my $one = $script->one;

use YAML qw/LoadFile Dump/;

my $l = League->new( id => $id );
my $g = Grades->new( league => $l );
my $members = $l->members;
my %m = map { $_->{id} => $_ } @$members;

my $standings = LoadFile '/var/www/cgi-bin/target/standings.yaml';

my $play = $standings->{$id};
for my $player ( keys %$play ) {
	warn "$player doing $exercise dictation not a member of $id league"
		unless $m{$player};
}
my %p = map { $_ => $standings->{$id}->{$_}->{$exercise} } keys %m;
$p{one} = $one;
$p{two} = $two;
$p{exercise} = $exercise;

my %g = map { $_ => $p{$_} >= $two? 2: $p{$_} > $one? 1: 0 } keys %m;

print Dump \%p;
print Dump \%g;
