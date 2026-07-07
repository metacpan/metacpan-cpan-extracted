#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Inline::CLIPS;

my $clips = Inline::CLIPS->new;
my $result = $clips->run_program(
  q{
    (deftemplate step (slot id) (slot state))
    (deffacts process
      (step (id gather_requirements) (state done))
      (step (id implement) (state done))
      (step (id test) (state blocked)))
    (defrule report-blocked-step
      (step (id ?id) (state blocked))
      =>
      (printout t "Process blocked at: " ?id crlf))
  },
  '(run)',
);

print $result->{stdout};
warn $result->{stderr} if $result->{stderr};
exit $result->{status};
