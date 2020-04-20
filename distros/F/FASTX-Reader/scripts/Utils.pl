#!/usr/bin/env perl
use 5.012;
use FindBin qw($RealBin);
use Term::ANSIColor qw(:constants);
use lib "$RealBin/../lib";
use FASTX::Reader;
use FASTX::ScriptHelper;
use Data::Dumper;
our $opt_verbose = 1;

my $script = FASTX::ScriptHelper->new({
  verbose => $opt_verbose,
  linesize => 10,
});

say GREEN, 'verbose', RESET;
$script->verbose("Ciao");
verbose "Non objective call";

say GREEN, 'rc', RESET;
say $script->rc("AAA");
say rc "ACGTTTTT";


say GREEN, 'fu_printfasta', RESET;
$script->fu_printfasta('Ciaociao', undef, 'aacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagc');
fu_printfasta('ciao', undef, 'aacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagcaacgtacgtacgtagc');
