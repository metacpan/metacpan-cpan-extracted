#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use Language::RAM;

my $input = '';
my @args = ();

our($opt_i, $opt_l, $opt_v, $opt_a);

sub VERSION_MESSAGE {
  print "ram.pl using Language::RAM v$Language::RAM::VERSION\n";
}

sub HELP_MESSAGE {
  print(
  "Usage:\n",
  "\tram.pl -i INPUT [-l LIMIT] [-v] -a ARGUMENTS\n\n",
  "\tINPUT Input file\n",
  "\tLIMIT Abort machine after LIMIT steps\n",
  "\t-v Print memory snapshot of each step\n",
  "\tARGUMENTS String of arguments (numbers separated by whitespace).\n"
  );
}

getopts('l:i:va:');

unless(defined $opt_i) {
  die "No input file given";
}

unless(defined $opt_l) {
  $opt_l = 1000;
}

unless(open INPUT, '<', $opt_i) {
  die "Could not open input file $opt_i: $!";
}
while(<INPUT>) {
  $input .= $_;
}
close INPUT;

if(defined $opt_a) {
  @args = split /\s+/, $opt_a;
}

my %machine = Language::RAM::asl($input);
die "$machine{'error'}" if ($machine{'error'} ne '');
my $ret = Language::RAM::run(\%machine, \@args, $opt_l, $opt_v);
if($ret) {
  print STDERR "Error from machine: $machine{'error'}\n";
}

my %output = Language::RAM::get_output(\%machine);
print "OUTPUT FROM MACHINE:\n";
foreach (sort { $a <=> $b } keys %output) {
  printf "%4d=%d\n", $_, (defined $output{$_}) ? $output{$_} : 0;
}

my %codes = Language::RAM::get_code_stats(\%machine);
print "CODE STATS:\n";
my $total = 0;
foreach (sort {$a <=> $b} keys %codes) {
  $total += $codes{$_};
  printf "%4d=%4d %s\n", $_, $codes{$_}, Language::RAM::get_line(\%machine, $_);
}
print "TOTAL CODE STEPS:$total\n";

my %regs = qw(a -4 i1 -3 i2 -2 i3 -1);
my %mems = Language::RAM::get_mem_stats(\%machine);
print "MEM STATS:\n";
my @total = qw(0 0);
foreach (sort { (exists $regs{$a} ? $regs{$a} : $a) <=> (exists $regs{$b} ? $regs{$b} : $b)} keys %mems) {
  $total[0] += ${$mems{$_}}[0];
  $total[1] += ${$mems{$_}}[1];
  printf "%4" . (exists $regs{$_} ? 's' : 'd') . "=%4d reads, %4d writes\n", $_, ${$mems{$_}}[0], ${$mems{$_}}[1];
}
print "TOTAL MEM READS/WRITES:@total\n";

if ($ret eq '' && $opt_v) {
  my %snapshots = %{Language::RAM::get_snapshots(\%machine)};
  my %snapshot = Language::RAM::get_first_memory_snapshot(\%machine);
  my @slots  = sort { (exists $regs{$a} ? $regs{$a} : $a) <=> (exists $regs{$b} ? $regs{$b} : $b)} keys %snapshot;
  my @snapshot_ids = sort { $a <=> $b } keys %snapshots;

  printf "MEMORY SNAPSHOTS:\n";

  printf 'step ' . '%4s ' x (scalar @slots) . "addr command\n", @slots;

  printf '%4s ', '-';
  foreach (@slots) {
    printf '%4d ', $snapshot{$_};
  }
  print "   - \n";

  foreach (@snapshot_ids) {
    Language::RAM::replay_snapshot(\%machine, \%snapshot, $_, $_);
    printf '%4d ', $_;
    foreach (@slots) {
      printf '%4d ', $snapshot{$_};
    }
    printf '%4d ', $snapshots{$_}->[0];
    print Language::RAM::get_line(\%machine, $snapshots{$_}->[0]), "\n";
  }
}
