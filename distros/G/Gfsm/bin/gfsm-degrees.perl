#!/usr/bin/perl -w

use Gfsm;

push(@ARGV,'-') if (!@ARGV);
our $fsm = Gfsm::Automaton->new();
my $fsmfile = shift;
$fsm->load($fsmfile) or die("$0: load failed for '$fsmfile': $!");

my @deg2n = qw();
my ($q);
for ($q=0; $q < $fsm->n_states; ++$q) {
  next if (!$fsm->has_state($q));
  my $deg = $fsm->out_degree($q);
  ++$deg2n[$deg];
}

##-- print histogram
foreach (0..$#deg2n) {
  next if (!defined($deg2n[$_]));
  print $_, "\t", $deg2n[$_], "\n";
}
