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
} elsif  ($action eq 'download') {
  wget_action();
}


sub wget_action {
  say GREEN, 'downloader', RESET;
  my $url_bad = 'https://4nsgs.com/ciao/mona';
  my $url_ok  = $ARGV[1] // 'https://raw.githubusercontent.com/quadram-institute-bioscience/dadaist2/master/bin/run_dada_single.R';

  for my $url ($url_ok, $url_bad) {
    say Dumper $script->download($url, '/tmp');
  }
}
sub cmd_action {
  say GREEN 'cmd1', RESET;
  say Dumper $script->run('echo $SHELL');
  say GREEN 'cmd_opt', RESET;
  
  say Dumper $script->run('ls -ld /not /var', { candie => 1});
  eval {
    say Dumper $script->run('ls -ld /not /var', { invented_attrib => 1});
  };
  my @i = split/\n/,$@;
  say STDERR RED @{i}[0], RESET;
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