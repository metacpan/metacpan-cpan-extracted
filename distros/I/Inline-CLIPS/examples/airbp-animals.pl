#!/usr/bin/env perl
use strict;
use warnings;

use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Inline::CLIPS;

my $clips = Inline::CLIPS->new;
my $result = $clips->run_program(
  q{
    (deftemplate animal (slot name) (slot class))
    (deffacts seed
      (animal (name "penguin") (class bird))
      (animal (name "salmon") (class fish)))
    (defrule describe-animal
      (animal (name ?n) (class ?c))
      =>
      (printout t ?n " is a " ?c crlf))
  },
  '(run)',
);

print $result->{stdout};
warn $result->{stderr} if $result->{stderr};
exit $result->{status};
