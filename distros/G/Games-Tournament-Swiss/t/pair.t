#!usr/bin/perl

# testing script_files/pair

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML qw/Load LoadFile DumpFile/;

use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS')
{
	$secure_perl_path .= $Config{_exe}
		unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

BEGIN {
    $Games::Tournament::Swiss::Config::firstround = 1;
    @Games::Tournament::Swiss::Config::roles      = qw/White Black/;
    %Games::Tournament::Swiss::Config::scores      = (
    Win => 1, Draw => 0.5, Loss => 0, Absence => 0, Bye => 1 );
    $Games::Tournament::Swiss::Config::algorithm  =
      'Games::Tournament::Swiss::Procedure::FIDE';
}
use Games::Tournament::Contestant::Swiss;
use Games::Tournament::Swiss;
use Games::Tournament::Swiss::Bracket;

my @members = Load(<<'...');
---
id: 1
name: Your New Nicks
rating: 12
title: Unknown
---
id: 2
name: LaLa Lakers
rating: 8
title: Unknown
---
id: 3
name: Jose Capablanca
rating: 4
title: Unknown
---
id: 4
name: Alexander Alekhine
rating: 2
title: Unknown
...

DumpFile './league.yaml', {member => \@members};
mkdir '1';
chdir '1';
system "$secure_perl_path ../script_files/pair";

my $round = LoadFile './round.yaml';
my @tests = (
[ $round->{round} == 1, 'round 1'],
[ ($round->{group}->{1}->{White} eq 'Your New Nicks' and
  $round->{group}->{1}->{Black} eq 'Jose Capablanca' or
  $round->{group}->{1}->{Black} eq 'Your New Nicks' and
  $round->{group}->{1}->{White} eq 'Jose Capablanca'), '$m1 is Nicks&Jose'],
[ ($round->{group}->{2}->{White} eq 'Alexander Alekhine' and
  $round->{group}->{2}->{Black} eq 'LaLa Lakers' or
  $round->{group}->{2}->{Black} eq 'Alexander Alekhine' and
  $round->{group}->{2}->{White} eq 'LaLa Lakers'), '$m2 is LaLa&Alex'],
[ ($round->{group}->{1}->{White} eq 'Your New Nicks' and
  $round->{group}->{2}->{Black} eq 'LaLa Lakers' or
  $round->{group}->{1}->{Black} eq 'Your New Nicks' and
  $round->{group}->{2}->{White} eq 'LaLa Lakers'), 'S1 players different roles']
);

my @files = glob './*';
unlink @files;
chdir '..';
rmdir '1';
unlink './league.yaml', './league.yaml.bak';

plan tests => $#tests + 1;

map { ok( $_->[0], $_->[ 1, ], ) } @tests;
