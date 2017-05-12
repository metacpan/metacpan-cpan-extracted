#!usr/bin/perl

# testing script_files/pairtable2yaml

use lib qw/t lib/;

use strict;
use warnings;
use Test::More;
use YAML qw/LoadFile/;
use IO::All;

use Config;
my $secure_perl_path = $Config{perlpath};
if ($^O ne 'VMS')
{
	$secure_perl_path .= $Config{_exe}
		unless $secure_perl_path =~ m/$Config{_exe}$/i;
}

my $table=<<EOT;
                 Round 5 Pairing Groups
 ---------------------------------------------------------------------
 No  Opponents  Roles     Float Score
  1   6,4,2,5   WBWB      uD  3.5  
  2   7,3,1,4   BWBW      D   3.5  
  3   8,2,6,7   WBWB      d   2.5  
  6   1,5,3,9   BWBW          2.5  
EOT

$table > io('pairtable.txt');

system("$secure_perl_path ./script_files/pairtable2yaml pairtable.txt");

my $yaml = LoadFile './pairtable.yaml';

my @tests = (
[ $yaml->{opponents}, { 1 => [6,4,2,5],
			2 => [7,3,1,4],
			3 => [8,2,6,7],
			6 => [1,5,3,9], }, 'opponents'],
[ $yaml->{roles}, {
         1 => [qw/White Black White Black/],
         2 => [qw/Black White Black White/],
         3 => [qw/White Black White Black/],
         6 => [qw/Black White Black White/],
		}, 'roles'],
[ $yaml->{floats}, {
         1 => ['Up','Down'],
         2 => [undef,'Down'],
         3 => ['Down',undef],
         6 => [undef,undef],
		}, 'floats'],
[ $yaml->{score}, {
         1 => 3.5,
         2 => 3.5,
         3 => 2.5,
         6 => 2.5,
		}, 'scores']
);

unlink './pairtable.txt', './pairtable.yaml';

plan tests => $#tests + 1;

map { is_deeply( $_->[0], $_->[ 1, ], $_->[ 2, ] ) } @tests;
