#!/usr/bin/env perl
use 5.012;
use FindBin qw($RealBin);
use Term::ANSIColor qw(:constants);
use lib "$RealBin/../lib";
use FASTX::Reader;
use FASTX::ScriptHelper;
use Data::Dumper;
our $opt_verbose = 1;

my %opt = (
  verbose => $opt_verbose,
  logfile => "$RealBin/../demo.log",
  linesize => 10,
);
my $script = FASTX::ScriptHelper->new(\%opt);
my ($action) = @ARGV;

if (not defined $action) {
  main_action();
} elsif ($action eq 'seq') {
  seq_action();
} elsif ($action eq 'cmd') {
  cmd_action();
}

sub cmd_action {
  say GREEN 'cmd', RESET;
  say Dumper $script->run('echo $SHELL');
}
sub seq_action {
  say GREEN, 'rc', RESET;
  say $script->rc("AAA");
  say rc "ACGTTTTT";


  say GREEN, 'fu_printfasta', RESET;
  $script->fu_printfasta('Ciaociao', undef, 'aacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagc');
  fu_printfasta('ciao', undef, 'aacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagc');
}

sub main_action {
  say GREEN, 'verbose', RESET;
  $script->verbose("This is verbose from object");
  verbose "This is verbose: Non objective call";
  $script->verbose("options", \%opt);

  
}