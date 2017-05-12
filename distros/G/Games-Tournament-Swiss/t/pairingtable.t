#!usr/bin/perl

# testing script_files/pairingtable

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML qw/Load LoadFile DumpFile/;
use File::Spec;
use File::Basename;
use FindBin qw/$Bin/;

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

my $orig_dir = File::Spec->rel2abs( '.' );

my $test_dir = 'pairingtable_test_dir';
mkdir $test_dir;
chdir $test_dir;

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

DumpFile "./league.yaml", {member => \@members};

mkdir 'comp';
chdir 'comp';

mkdir '1';
chdir '1' or warn "No round 1 directory: $!";

my $round = Load(<<'...');
---
group:
  0:
    White: 1
    Black: 3
  1:
    White: 4
    Black: 2
...
DumpFile './round.yaml', $round;

my $scores = Load(<<'...');
---
0:
  'Your New Nicks': 1
  'Jose Capablanca': 0
1:
  'LaLa Lakers': 1
  'Alexander Alekhine': 0
...
DumpFile './scores.yaml', $scores;

chdir '../../' or warn "No tourney directory: $!";

my $table = qx{$secure_perl_path $Bin/../script_files/pairingtable 2};

my @tests = (
[ $table, qr/^		Round 2 Pairing Groups\n-------------------------------------------------------------------------\nPlace  No  Opponents     Roles     Float Score\n1-2\n      1   3\s+(W|B)\s+1\n      2   4\s+(W|B) +1\n3-4\n      3   1\s+(W|B)\s+0\n      4   2\s+(W|B)\s+0\n/m, 'round 1 table'],
);

chdir 'comp' or warn "No tourney directory: $!";
mkdir '2';
chdir '2';

$round = Load(<<'...');
---
group:
  0:
    White: 2
    Black: 1
  1:
    White: 3
    Black: 4
...
DumpFile './round.yaml', $round;

$scores = Load(<<'...');
---
0:
  'Your New Nicks': 1
  'LaLa Lakers': 0
1:
  'Jose Capablanca': 1
  'Alexander Alekhine': 0
...
DumpFile './scores.yaml', $scores;
chdir '../../' or warn "No tourney directory: $!";
$table = qx{$secure_perl_path $Bin/../script_files/pairingtable 3};
push @tests, (
[ $table, qr/^		Round 3 Pairing Groups\n-------------------------------------------------------------------------\nPlace  No  Opponents     Roles     Float Score\n1\n      1   3,2\s+(WB|BW)\s+2\n2-3\n      2   4,1\s+(WB|BW)\s+1\n      3   1,4\s+(WB|BW)\s+1\n4\n      4   2,3\s+(WB|BW)\s+0\n/m,
'round 2 table'],
);

chdir 'comp' or warn "No comp directory: $!";
my @rounds = ( 1..2 );
for my $dir ( @rounds )
{
	chdir "$dir" or die "Cannot change to $dir";
	my @files = glob '*';
	unlink @files;
	chdir '..';
	rmdir "./$dir";
	rmdir "./comp/$dir";
}
chdir '..' or warn "No tourney directory: $!";
rmdir 'comp';
unlink './league.yaml', './league.yaml.bak';
chdir '..' or warn "No original directory: $!";
rmdir $test_dir;

my $pwd = File::Spec->rel2abs( '.' );
die "The pwd, $pwd is not the original $orig_dir." unless $pwd eq $orig_dir;
plan tests => $#tests + 1;

map { like( $_->[0], $_->[ 1, ], $_->[ 2, ] ) } @tests;
